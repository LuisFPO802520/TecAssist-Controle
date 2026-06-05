const bcrypt = require("bcrypt");
const prisma = require("../config/prisma");

async function createAdmin() {

    const adminExiste = await prisma.usuario.findFirst({
        where: {
            email: "admin@teste.com"
        }
    });

    if (adminExiste) {
        console.log("Administrador já existe.");
        return;
    }

    const senhaHash = await bcrypt.hash("123456", 10);

    const usuario = await prisma.usuario.create({
        data: {
            nome: "Administrador",
            email: "admin@teste.com",
            senha: senhaHash,
            tipo: "ADMIN"
        }
    });

    console.log("Administrador criado:");
    console.log(usuario);

}

module.exports = createAdmin;