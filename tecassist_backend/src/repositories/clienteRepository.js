const prisma = require("../config/prisma");

async function create(data) {

    return prisma.cliente.create({
        data
    });

}

async function findAll() {

    return prisma.cliente.findMany({
        orderBy: {id: "desc"}
    });

}

async function findById(id) {

    return prisma.cliente.findUnique({
        where: {id}
    });

}

async function update(id, data) {

    return prisma.cliente.update({
        where: {id},
        data
    });

}

async function remove(id) {

    return prisma.cliente.delete({
        where: {id}
    });

}

async function findByTelefone(telefone) {

    return prisma.cliente.findFirst({
        where: {telefone}
    });

}

async function findByCpf(cpf) {

    return prisma.cliente.findUnique({
        where: {cpf}
    });

}

async function findByEmail(email) {

    return prisma.cliente.findUnique({
        where: {email}
    });

}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove,
    findByTelefone,
    findByCpf,
    findByEmail
};