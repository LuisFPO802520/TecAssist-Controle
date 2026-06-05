const usuarioRepository = require("../repositories/usuarioRepository");
const bcrypt = require("bcrypt");

async function create(usuario) {

    if (!usuario.nome) {
        throw new Error("Nome é obrigatório");
    }

    if (!usuario.email) {
        throw new Error("E-mail é obrigatório");
    }

    if (!usuario.senha) {
        throw new Error("Senha é obrigatória");
    }

    if (usuario.senha.length < 6) {
        throw new Error("Senha deve ter pelo menos 6 caracteres");
    }

    const emailExiste = await usuarioRepository.findByEmail(
        usuario.email
    );

    if (emailExiste) {
        throw new Error("E-mail já cadastrado");
    }
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(usuario.email)) {
        throw new Error("E-mail inválido");
    }

    if (usuario.telefone) {

        if (!/^\d{10,11}$/.test(usuario.telefone)) {
            throw new Error("Telefone inválido");
        }

    }

    const senhaHash = await bcrypt.hash(usuario.senha, 10);

    usuario.senha = senhaHash;

    return usuarioRepository.create(usuario);
    
}

async function findAll() {
    return usuarioRepository.findAll();
}

async function findById(id) {

    const usuario = await usuarioRepository.findById(
        Number(id)
    );

    if (!usuario) {
        throw new Error("Usuário não encontrado");
    }

    return usuario;

}

async function update(id, data) {

    const usuario = await usuarioRepository.findById(Number(id));

    if (!usuario) {
        throw new Error("Usuário não encontrado");
    }

    return usuarioRepository.update(Number(id),data);

}

async function remove(id) {

    const usuario = await usuarioRepository.findById(
        Number(id)
    );

    if (!usuario) {
        throw new Error("Usuário não encontrado");
    }

    return usuarioRepository.remove(Number(id));

}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove
};