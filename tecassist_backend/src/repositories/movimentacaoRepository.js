const prisma = require("../config/prisma");

async function create(data) {

    return prisma.movimentacaoEstoque.create({
        data,
        include: {estoque: true}
    });
    
}

async function findAll() {

    return prisma.movimentacaoEstoque.findMany({
        include: {estoque: true},
        orderBy: {createdAt: "desc"}
    });

}

module.exports = {
    create,
    findAll
};