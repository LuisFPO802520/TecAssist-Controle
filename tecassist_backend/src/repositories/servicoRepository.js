const prisma = require("../config/prisma");

async function create(data) {

    return prisma.servico.create({
        data,
        include: {
            cliente: true,
            usuario: true,
            agendamento: true
        }
    });

}

async function findAll() {
    
    return prisma.servico.findMany({
        include: {
            cliente: true,
            usuario: true,
            agendamento: true,

            pecas: {
                include: {
                    estoque: true
                }
            }
        }
    });
}

async function findById(id) {

    return prisma.servico.findUnique({
        where: {id},
        include: {
            cliente: true,
            usuario: true,
            agendamento: true,

            pecas: {
                include: {
                    estoque: true
                }
            }
        }
    });

}

async function findByCodigo(codigo) {

    return prisma.servico.findUnique({
        where: {codigo}
    });

}

async function update(id, data) {

    return prisma.servico.update({
        where: {id},data
    });

}

async function remove(id) {

    return prisma.servico.delete({
        where: {id}
    });
    
}

module.exports = {
    create,
    findAll,
    findById,
    findByCodigo,
    update,
    remove
};