const prisma = require("../config/prisma");

async function create(data) {

    return prisma.agendamento.create({
        data,
        include: {cliente: true}
    });
}

async function findAll() {

    return prisma.agendamento.findMany({
        include: {
            cliente: true
        },
        orderBy: {
            data: "asc"
        }
    });

}

async function findById(id) {

    return prisma.agendamento.findUnique({
        where: { id },
        include: {cliente: true}
    });

}

async function update(id, data) {

    return prisma.agendamento.update({
        where: { id },
        data
    });

}

async function remove(id) {

    return prisma.agendamento.delete({
        where: { id }
    });
    
}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove
};