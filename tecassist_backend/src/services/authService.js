const prisma = require("../config/prisma");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const {
  consumirCodigoCadastro,
  devolverUsoCodigo,
} = require(
  "../utils/registrationCode"
);

async function login(email, senha) {

    const usuario = await prisma.usuario.findUnique({
        where: {email}
    });

    if (!usuario) {
        throw new Error("Usuário não encontrado");
    }

    const senhaValida = await bcrypt.compare(
        senha, usuario.senha
    );

    if (!senhaValida) {
        throw new Error("Senha inválida");
    }

    const token = jwt.sign(
        {
            id: usuario.id,
            tipo: usuario.tipo
        },
        process.env.JWT_SECRET,
        {
            expiresIn: "1d"
        }
    );

    return {
        usuario: {
            id: usuario.id,
            nome: usuario.nome,
            email: usuario.email,
            tipo: usuario.tipo
        },
        token
    };

}

async function cadastrarFuncionario(data) {
  const {
    nome,
    email,
    senha,
    telefone,
    codigoCadastro,
  } = data;

  if (!nome || !email || !senha) {
    throw new Error(
      "Nome, e-mail e senha são obrigatórios"
    );
  }

  if (!codigoCadastro) {
    throw new Error(
      "Código de cadastro é obrigatório"
    );
  }

  if (senha.length < 6) {
    throw new Error(
      "A senha deve possuir pelo menos 6 caracteres"
    );
  } 

  const usuarioExistente =
    await prisma.usuario.findUnique({
      where: {
        email,
      },
    });

  if (usuarioExistente) {
    throw new Error(
      "Já existe um usuário com este e-mail"
    );
  }
 
  const reserva =
    consumirCodigoCadastro(
      codigoCadastro
    );


  try { 

    const senhaHash =
      await bcrypt.hash(
        senha,
        10
      );

    const usuario =
      await prisma.usuario.create({
        data: {
          nome,
          email,
          senha: senhaHash,

          tipo: "FUNCIONARIO",

          telefone:
            telefone?.trim() || null,

          ativo: true,
        },

        select: {
          id: true,
          nome: true,
          email: true,
          tipo: true,
          telefone: true,
          ativo: true,
          createdAt: true,
        },
      });

    return usuario;

  } catch (error) {

    devolverUsoCodigo(
      reserva.codigo
    );

    throw error;
  }
}

module.exports = {
    login,
    cadastrarFuncionario,
};