const prisma = require("../config/prisma");

async function create(data) {

    return prisma.estoque.create({
        data
    });

}

async function findAll() {

    return prisma.estoque.findMany({
        orderBy: {id: "desc"}
    });

}

async function findById(id) {

    return prisma.estoque.findUnique({
        where: {id}
    });

}

async function update(id, data) {

    return prisma.estoque.update({
        where: {id},
        data
    });

}

async function remove(id) {

    return prisma.estoque.delete({
        where: {id}
    });

}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove
};