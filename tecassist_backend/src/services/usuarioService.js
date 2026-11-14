const usuarioRepository = require("../repositories/usuarioRepository");
const bcrypt = require("bcrypt");
const fs = require("fs/promises");
const path = require("path");
const crypto = require("crypto");

const LIMITE_FOTO_BYTES = 4 * 1024 * 1024;
const DIRETORIO_FOTOS = path.join(__dirname, "..", "..", "uploads", "avatars");

function erroHttp(mensagem, statusCode = 400) {
    const error = new Error(mensagem);
    error.statusCode = statusCode;
    return error;
}

function validarEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function validarTelefone(telefone) {
    if (!telefone) return;
    if (!/^\d{10,11}$/.test(telefone)) {
        throw erroHttp("Telefone inválido");
    }
}

async function create(usuario) {
    if (!usuario.nome || !usuario.nome.trim()) {
        throw erroHttp("Nome é obrigatório");
    }

    if (!usuario.email || !usuario.email.trim()) {
        throw erroHttp("E-mail é obrigatório");
    }

    if (!usuario.senha) {
        throw erroHttp("Senha é obrigatória");
    }

    if (usuario.senha.length < 6) {
        throw erroHttp("Senha deve ter pelo menos 6 caracteres");
    }

    const email = usuario.email.trim().toLowerCase();

    if (!validarEmail(email)) {
        throw erroHttp("E-mail inválido");
    }

    const emailExiste = await usuarioRepository.findByEmail(email);
    if (emailExiste) {
        throw erroHttp("E-mail já cadastrado", 409);
    }

    const telefone = usuario.telefone?.trim() || null;
    validarTelefone(telefone);

    const senhaHash = await bcrypt.hash(usuario.senha, 10);

    return usuarioRepository.create({
        nome: usuario.nome.trim(),
        email,
        senha: senhaHash,
        tipo: usuario.tipo,
        telefone,
        ativo: usuario.ativo ?? true,
    });
}

async function findAll() {
    return usuarioRepository.findAll();
}

async function findById(id) {

    const usuario = await usuarioRepository.findById(
        Number(id)
    );

    if (!usuario) {
        throw erroHttp("Usuário não encontrado", 404);
    }

    return usuario;

}

async function update(id, data) {
    const usuarioId = Number(id);
    const usuario = await usuarioRepository.findById(usuarioId);

    if (!usuario) {
        throw erroHttp("Usuário não encontrado", 404);
    }

    const dadosAtualizados = {};

    if (data.nome !== undefined) {
        if (!String(data.nome).trim()) {
            throw erroHttp("Nome é obrigatório");
        }
        dadosAtualizados.nome = String(data.nome).trim();
    }

    if (data.email !== undefined) {
        const email = String(data.email).trim().toLowerCase();
        if (!validarEmail(email)) {
            throw erroHttp("E-mail inválido");
        }

        if (email !== usuario.email) {
            const emailExiste = await usuarioRepository.findByEmail(email);
            if (emailExiste && emailExiste.id !== usuarioId) {
                throw erroHttp("E-mail já cadastrado", 409);
            }
        }

        dadosAtualizados.email = email;
    }

    if (data.tipo !== undefined) {
        dadosAtualizados.tipo = data.tipo;
    }

    if (data.ativo !== undefined) {
        dadosAtualizados.ativo = Boolean(data.ativo);
    }

    if (data.telefone !== undefined) {
        const telefone = String(data.telefone || "").trim();
        validarTelefone(telefone);
        dadosAtualizados.telefone = telefone || null;
    }

    if (typeof data.senha === "string" && data.senha.trim() !== "") {
        if (data.senha.length < 6) {
            throw erroHttp("A senha deve possuir pelo menos 6 caracteres");
        }

        dadosAtualizados.senha = await bcrypt.hash(data.senha, 10);
    }

    let novaFoto = null;

    if (data.fotoBase64) {
        novaFoto = await salvarFotoPerfil(
            usuarioId,
            data.fotoBase64,
            data.fotoMimeType
        );
        dadosAtualizados.fotoPerfil = novaFoto.caminho;
    }

    try {
        const usuarioAtualizado = await usuarioRepository.update(
            usuarioId,
            dadosAtualizados
        );

        if (novaFoto && usuario.fotoPerfil) {
            await excluirFotoAntiga(usuario.fotoPerfil);
        }

        return usuarioAtualizado;

    } catch (error) {
        if (novaFoto) {
            try {
                await fs.unlink(novaFoto.absoluto);
            } catch (_) {}
        }

        if (error.code === "P2002") {
            throw erroHttp("E-mail já cadastrado", 409);
        }

        throw error;
    }
}

function validarAssinaturaImagem(buffer, mimeType) {
    if (mimeType === "image/jpeg") {
        return buffer.length >= 3 &&
            buffer[0] === 0xff &&
            buffer[1] === 0xd8 &&
            buffer[2] === 0xff;
    }

    if (mimeType === "image/png") {
        return buffer.length >= 8 &&
            buffer.subarray(0, 8).equals(
                Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
            );
    }

    if (mimeType === "image/webp") {
        return buffer.length >= 12 &&
            buffer.toString("ascii", 0, 4) === "RIFF" &&
            buffer.toString("ascii", 8, 12) === "WEBP";
    }

    return false;
}

async function salvarFotoPerfil(usuarioId, fotoBase64, fotoMimeType) {
    if (typeof fotoBase64 !== "string" || !fotoBase64.trim()) {
        return null;
    }

    const extensoes = {
        "image/jpeg": "jpg",
        "image/png": "png",
        "image/webp": "webp",
    };

    const extensao = extensoes[fotoMimeType];
    if (!extensao) {
        throw erroHttp("Formato de foto inválido. Use JPG, PNG ou WebP.");
    }

    const base64 = fotoBase64.includes(",")
        ? fotoBase64.substring(fotoBase64.indexOf(",") + 1)
        : fotoBase64;

    if (!/^[A-Za-z0-9+/]+={0,2}$/.test(base64)) {
        throw erroHttp("Arquivo de foto inválido.");
    }

    const buffer = Buffer.from(base64, "base64");

    if (buffer.length === 0) {
        throw erroHttp("A foto selecionada está vazia.");
    }

    if (buffer.length > LIMITE_FOTO_BYTES) {
        throw erroHttp("A foto deve ter no máximo 4 MB.");
    }

    if (!validarAssinaturaImagem(buffer, fotoMimeType)) {
        throw erroHttp("O conteúdo do arquivo não corresponde ao formato informado.");
    }

    await fs.mkdir(DIRETORIO_FOTOS, { recursive: true });

    const nomeArquivo = `usuario-${usuarioId}-${crypto.randomUUID()}.${extensao}`;
    const caminhoAbsoluto = path.join(DIRETORIO_FOTOS, nomeArquivo);

    await fs.writeFile(caminhoAbsoluto, buffer, { flag: "wx" });

    return {
        caminho: `/uploads/avatars/${nomeArquivo}`,
        absoluto: caminhoAbsoluto,
    };
}

async function excluirFotoAntiga(caminhoFoto) {
    if (typeof caminhoFoto !== "string" ||
        !caminhoFoto.startsWith("/uploads/avatars/")) {
        return;
    }

    const nomeArquivo = path.basename(caminhoFoto);
    if (!nomeArquivo) return;

    try {
        await fs.unlink(path.join(DIRETORIO_FOTOS, nomeArquivo));
    } catch (error) {
        if (error.code !== "ENOENT") {
            console.warn("Não foi possível remover a foto de perfil antiga:", error.message);
        }
    }
}

async function updateProfile(id, data) {
    const usuarioId = Number(id);
    const usuarioAtual = await usuarioRepository.findByIdComSenha(usuarioId);

    if (!usuarioAtual) {
        throw erroHttp("Usuário não encontrado", 404);
    }

    const nome = String(data.nome || "").trim();
    const email = String(data.email || "").trim().toLowerCase();
    const telefone = String(data.telefone || "").trim();

    if (!nome) {
        throw erroHttp("Nome é obrigatório");
    }

    if (!email || !validarEmail(email)) {
        throw erroHttp("Informe um e-mail válido.");
    }

    validarTelefone(telefone);

    if (email !== usuarioAtual.email) {
        const emailExiste = await usuarioRepository.findByEmail(email);
        if (emailExiste && emailExiste.id !== usuarioId) {
            throw erroHttp("Este e-mail já está sendo utilizado por outro usuário.", 409);
        }
    }

    const dadosAtualizados = {
        nome,
        email,
        telefone: telefone || null,
    };

    const novaSenha = typeof data.novaSenha === "string"
        ? data.novaSenha
        : "";

    if (novaSenha.trim()) {
        const senhaAtual = typeof data.senhaAtual === "string"
            ? data.senhaAtual
            : "";

        if (!senhaAtual) {
            throw erroHttp("Informe sua senha atual para definir uma nova senha.");
        }

        if (novaSenha.length < 6) {
            throw erroHttp("A nova senha deve possuir pelo menos 6 caracteres.");
        }

        const senhaAtualValida = await bcrypt.compare(
            senhaAtual,
            usuarioAtual.senha
        );

        if (!senhaAtualValida) {
            throw erroHttp("A senha atual está incorreta.", 401);
        }

        dadosAtualizados.senha = await bcrypt.hash(novaSenha, 10);
    }

    let novaFoto = null;

    if (data.fotoBase64) {
        novaFoto = await salvarFotoPerfil(
            usuarioId,
            data.fotoBase64,
            data.fotoMimeType
        );

        dadosAtualizados.fotoPerfil = novaFoto.caminho;
    }

    try {
        const usuarioAtualizado = await usuarioRepository.update(
            usuarioId,
            dadosAtualizados
        );

        if (novaFoto && usuarioAtual.fotoPerfil) {
            await excluirFotoAntiga(usuarioAtual.fotoPerfil);
        }

        return usuarioAtualizado;
    } catch (error) {
        if (novaFoto) {
            try {
                await fs.unlink(novaFoto.absoluto);
            } catch (_) {}
        }

        if (error.code === "P2002") {
            throw erroHttp("Este e-mail já está sendo utilizado por outro usuário.", 409);
        }

        throw error;
    }
}

async function remove(id) {
    const usuarioId = Number(id);

    if (!Number.isInteger(usuarioId) || usuarioId <= 0) {
        throw erroHttp("ID de usuário inválido");
    }

    const usuario = await usuarioRepository.findById(usuarioId);

    if (!usuario) {
        throw erroHttp("Usuário não encontrado", 404);
    }

    if (!usuario.ativo) {
        throw erroHttp("Este usuário já está desativado");
    }

    return usuarioRepository.remove(usuarioId);
}

module.exports = {
    create,
    findAll,
    findById,
    update,
    updateProfile,
    remove
};