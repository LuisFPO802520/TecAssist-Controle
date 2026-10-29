const prisma = require("../config/prisma");

async function create(data) {
  return prisma.agendamento.create({
    data: {
      descricao: data.descricao,
      data: new Date(data.data),
      clienteId: Number(data.clienteId),
      status: data.status || "AGENDADO",
    },
    include: {
      cliente: true,
    },
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
        include: {cliente: true, servicos: true}
    });

}

async function update(id, data) {

    return prisma.agendamento.update({
        where: {
            id: Number(id)
        },
        data: {
            ...data,
            ...(data.data !== undefined
                ? { data: new Date(data.data) }
                : {})
        },
        include: {
            cliente: true
        }
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