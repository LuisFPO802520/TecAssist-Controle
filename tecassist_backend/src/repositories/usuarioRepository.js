const prisma = require("../config/prisma");

async function create(data) {

    return prisma.usuario.create({
        data
    });

}

async function findAll() {

    return prisma.usuario.findMany({
        select: {
            id: true,
            nome: true,
            email: true,
            tipo: true,
            createdAt: true
        }
    });

}

async function findById(id) {

    return prisma.usuario.findUnique({
        where: {id},
        select: {
            id: true,
            nome: true,
            email: true,
            tipo: true
        }
    });

}

async function update(id, data) {

    return prisma.usuario.update({
        where: {id},
        data
    });

}

async function remove(id) {

    return prisma.usuario.delete({
        where: {id}
    });

}

async function findByEmail(email) {

    return prisma.usuario.findUnique({
        where: {email}
    });

}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove,
    findByEmail
};