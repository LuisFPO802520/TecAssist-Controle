const prisma = require("../config/prisma");

async function create(data) {

    return prisma.estoque.create({
        data: {
            ...data,
            ativo: true
        }
    });

}

async function findAll() {

    return prisma.estoque.findMany({
        where: {
            ativo: true
        },
        orderBy: {
            id: "desc"
        }
    });

}

async function findById(id) {
    return prisma.estoque.findFirst({
        where: {
            id,
            ativo: true
        }
    });

}

async function update(id, data) {
    const item = await findById(id);

    if (!item) {
        throw new Error("Item não encontrado ou já removido");
    }

    return prisma.estoque.update({
        where: { id },
        data
    });

}

async function remove(id) {
    const resultado = await prisma.estoque.updateMany({
        where: {
            id,
            ativo: true
        },
        data: {
            ativo: false
        }
    });

    if (resultado.count === 0) {
        throw new Error("Item não encontrado ou já removido");
    }

    return {
        id,
        ativo: false
    };
}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove
};
