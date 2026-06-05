const prisma = require("../config/prisma");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

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

module.exports = {
    login
};