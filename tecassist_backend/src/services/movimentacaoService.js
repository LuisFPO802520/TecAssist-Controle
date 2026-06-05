const prisma = require("../config/prisma");
const movimentacaoRepository = require("../repositories/movimentacaoRepository");

async function entrada(estoqueId, quantidade) {

    const item = await prisma.estoque.findUnique({
        where: {id: Number(estoqueId)}
    });

    if (!item) {
        throw new Error("Item não encontrado");
    }

    await prisma.estoque.update({
        where: {id: item.id},
        data: {
            quantidade:
                item.quantidade + Number(quantidade)
        }
    });

    return movimentacaoRepository.create({
        tipo: "ENTRADA",
        quantidade: Number(quantidade),
        estoqueId: item.id
    });

}

async function saida(estoqueId, quantidade) {

    const item = await prisma.estoque.findUnique({
        where: {id: Number(estoqueId)}
    });

    if (!item) {
        throw new Error("Item não encontrado");
    }

    if (item.quantidade < Number(quantidade)) {
        throw new Error("Quantidade insuficiente");
    }

    await prisma.estoque.update({
        where: {id: item.id},
        data: {
            quantidade:
                item.quantidade - Number(quantidade)
        }
    });

    return movimentacaoRepository.create({
        tipo: "SAIDA",
        quantidade: Number(quantidade),
        estoqueId: item.id
    });
    
}

async function historico() {

    return movimentacaoRepository.findAll();

}

module.exports = {
    entrada,
    saida,
    historico
};