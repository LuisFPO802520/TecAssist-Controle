const prisma = require("../config/prisma");

const camposPublicos = {
    id: true,
    nome: true,
    email: true,
    tipo: true,
    telefone: true,
    fotoPerfil: true,
    ativo: true,
    createdAt: true,
    updatedAt: true,
};

async function create(data) {

    return prisma.usuario.create({
        data,
        select: camposPublicos,
    });

}

async function findAll() {
    return prisma.usuario.findMany({
        where: {
            ativo: true,
        },
        select: camposPublicos,
    });
}

async function findById(id) {
    return prisma.usuario.findUnique({
        where: { id },
        select: camposPublicos,
    });
}


async function findByIdComSenha(id) {
    return prisma.usuario.findUnique({
        where: { id },
        select: {
            ...camposPublicos,
            senha: true,
        },
    });
}

async function update(id, data) {

    return prisma.usuario.update({
        where: { id },
        data,
        select: camposPublicos,
    });

}

async function remove(id) {
    return prisma.usuario.update({
        where: { id },
        data: {
            ativo: false,
        },
        select: camposPublicos,
    });
}

async function findByEmail(email) {

    return prisma.usuario.findUnique({
        where: { email },
    });

}

module.exports = {
    create,
    findAll,
    findById,
    findByIdComSenha,
    update,
    remove,
    findByEmail,
};
