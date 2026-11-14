const prisma = require("../config/prisma");
const servicoRepository = require("../repositories/servicoRepository");
const gerarCodigo = require("../utils/createCodeServico");

function erroHttp(mensagem, statusCode) {
    const error = new Error(mensagem);
    error.statusCode = statusCode;
    return error;
}

async function create(data) {

    if (!data.equipamento) {
        throw new Error("Equipamento é obrigatório");
    }

    if (!data.clienteId) {
        throw new Error("Cliente é obrigatório");
    }

    if (!data.usuarioId) {
        throw new Error("Usuário responsável é obrigatório");
    }

    const cliente = await prisma.cliente.findUnique({
        where: { id: Number(data.clienteId) }
    });

    if (!cliente) {
        throw new Error("Cliente não encontrado");
    }

    const usuario = await prisma.usuario.findUnique({
        where: { id: Number(data.usuarioId) }
    });

    if (!usuario) {
        throw new Error("Usuário não encontrado");
    }

    data.status = "ABERTO";

    const servico = await servicoRepository.create(data);

    const codigo = gerarCodigo(servico.id);

    await prisma.servico.update({
        where: { id: servico.id },
        data: { codigo }
    });

    return servicoRepository.findById(servico.id);

}

async function findAll() {

    return servicoRepository.findAll();
}

async function findById(id) {

    const servico = await servicoRepository.findById(
        Number(id)
    );

    if (!servico) {
        throw new Error("Serviço não encontrado");
    }

    return servico;
}

async function update(id, data) {

    return servicoRepository.update(
        Number(id),
        data
    );
}

async function remove(id) {

    return servicoRepository.remove(
        Number(id)
    );
}

async function atualizarStatus(id, status) {

    const statusValidos = [
        "ABERTO",
        "EM_ANALISE",
        "AGUARDANDO_PECA",
        "EM_MANUTENCAO",
        "PRONTO",
        "ENTREGUE",
        "CANCELADO"
    ];

    if (!statusValidos.includes(status)) {
        throw new Error("Status inválido");
    }

    return servicoRepository.update(
        Number(id),
        { status }
    );
}

async function converterAgendamento(agendamentoId, dadosServico) {
    if (!dadosServico.usuarioId) {
        throw new Error("Usuário responsável é obrigatório");
    }

    const agendamento = await prisma.agendamento.findUnique({
        where: { id: Number(agendamentoId) }
    });

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    const usuario = await prisma.usuario.findUnique({
        where: { id: Number(dadosServico.usuarioId) }
    });

    if (!usuario) {
        throw new Error("Usuário responsável não encontrado");
    }

    const servico = await servicoRepository.create({
        ...dadosServico,
        status: "ABERTO",
        clienteId: agendamento.clienteId,
        agendamentoId: agendamento.id
    });

    const codigo = gerarCodigo(servico.id);

    await prisma.servico.update({
        where: { id: servico.id },
        data: { codigo }
    });

    await prisma.agendamento.update({
        where: { id: agendamento.id },
        data: { status: "CONVERTIDO" }
    });

    return servicoRepository.findById(servico.id);
}

async function adicionarPeca(
    servicoId,
    estoqueId,
    quantidade
) {
    const idServico = Number(servicoId);
    const idEstoque = Number(estoqueId);
    const qtd = Number(quantidade);

    if (
        !Number.isInteger(idServico) ||
        idServico <= 0 ||
        !Number.isInteger(idEstoque) ||
        idEstoque <= 0 ||
        !Number.isInteger(qtd) ||
        qtd <= 0
    ) {
        throw erroHttp(
            "Serviço, peça e quantidade precisam ser válidos.",
            400
        );
    }

    return prisma.$transaction(async (tx) => {
        const servico = await tx.servico.findUnique({
            where: {
                id: idServico,
            },
            select: {
                id: true,
                status: true,
            },
        });

        if (!servico) {
            throw erroHttp(
                "Serviço não encontrado.",
                404
            );
        }

        const status = servico.status.toUpperCase();

        if (
            status === "CANCELADO" ||
            status === "ENTREGUE" ||
            status === "FINALIZADO"
        ) {
            throw erroHttp(
                "Não é possível adicionar peças a um serviço encerrado.",
                409
            );
        }

        const estoque = await tx.estoque.findUnique({
            where: {
                id: idEstoque,
            },
            select: {
                id: true,
                quantidade: true,
            },
        });

        if (!estoque) {
            throw erroHttp(
                "Peça não encontrada no estoque.",
                404
            );
        }

        const atualizacao = await tx.estoque.updateMany({
            where: {
                id: idEstoque,
                quantidade: {
                    gte: qtd,
                },
            },
            data: {
                quantidade: {
                    decrement: qtd,
                },
            },
        });

        if (atualizacao.count !== 1) {
            throw erroHttp(
                "Quantidade insuficiente no estoque.",
                409
            );
        }

        const vinculo = await tx.servicoPeca.create({
            data: {
                servicoId: idServico,
                estoqueId: idEstoque,
                quantidade: qtd,
            },
            include: {
                estoque: {
                    select: {
                        id: true,
                        nome: true,
                        descricao: true,
                        valor: true,
                        quantidade: true,
                    },
                },
            },
        });

        await tx.movimentacaoEstoque.create({
            data: {
                tipo: "SAIDA",
                quantidade: qtd,
                estoqueId: idEstoque,
            },
        });

        return vinculo;
    });
}

async function removerPeca(
    servicoId,
    servicoPecaId
) {
    const idServico = Number(servicoId);
    const idVinculo = Number(servicoPecaId);

    if (
        !Number.isInteger(idServico) ||
        idServico <= 0 ||
        !Number.isInteger(idVinculo) ||
        idVinculo <= 0
    ) {
        throw erroHttp(
            "Serviço ou vínculo de peça inválido.",
            400
        );
    }

    return prisma.$transaction(async (tx) => {
        const vinculo = await tx.servicoPeca.findFirst({
            where: {
                id: idVinculo,
                servicoId: idServico,
            },
            include: {
                servico: {
                    select: {
                        id: true,
                        status: true,
                    },
                },
            },
        });

        if (!vinculo) {
            throw erroHttp(
                "Peça não encontrada neste serviço.",
                404
            );
        }

        const status = vinculo.servico.status.toUpperCase();

        if (
            status === "CANCELADO" ||
            status === "ENTREGUE" ||
            status === "FINALIZADO"
        ) {
            throw erroHttp(
                "Não é possível alterar peças de um serviço encerrado.",
                409
            );
        }

        await tx.estoque.update({
            where: {
                id: vinculo.estoqueId,
            },
            data: {
                quantidade: {
                    increment: vinculo.quantidade,
                },
            },
        });

        await tx.movimentacaoEstoque.create({
            data: {
                tipo: "ENTRADA",
                quantidade: vinculo.quantidade,
                estoqueId: vinculo.estoqueId,
            },
        });

        await tx.servicoPeca.delete({
            where: {
                id: vinculo.id,
            },
        });

        return {
            message: "Peça devolvida ao estoque.",
            servicoId: idServico,
            estoqueId: vinculo.estoqueId,
            quantidade: vinculo.quantidade,
        };
    });
}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove,
    atualizarStatus,
    converterAgendamento,
    adicionarPeca,
    removerPeca
};