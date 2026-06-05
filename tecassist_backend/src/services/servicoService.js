const prisma = require("../config/prisma");
const servicoRepository = require("../repositories/servicoRepository");
const gerarCodigo = require("../utils/createCodeServico");

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

    const agendamento = await prisma.agendamento.findUnique({
        where: {id: Number(agendamentoId)}
    });

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    const servico = await servicoRepository.create({
        ...dadosServico,
        status: "ABERTO",
        clienteId: agendamento.clienteId,
        agendamentoId: agendamento.id
    });

    const codigo = gerarCodigo(servico.id);

    await prisma.servico.update({
        where: {id: servico.id},
        data: {codigo}
    });

    await prisma.agendamento.update({
        where: {id: agendamento.id},
        data: {status: "CONVERTIDO"}
    });

    return servicoRepository.findById(
        servico.id
    );
    
}

async function adicionarPeca(servicoId, dados) {

    const servico = await prisma.servico.findUnique({
        where: {id: Number(servicoId)}
    });

    if (!servico) {
        throw new Error("Serviço não encontrado");
    }

    const estoque = await prisma.estoque.findUnique({
        where: {id: Number(dados.estoqueId)}
    });

    if (!estoque) {
        throw new Error("Peça não encontrada");
    }

    if (estoque.quantidade < dados.quantidade) {
        throw new Error("Estoque insuficiente");
    }

    const servicoPeca = await prisma.servicoPeca.create({
        data: {
            servicoId: Number(servicoId),
            estoqueId: Number(dados.estoqueId),
            quantidade: Number(dados.quantidade)
        }
    });

    await prisma.estoque.update({
        where: {id: estoque.id},
        data: {
            quantidade:
                estoque.quantidade - dados.quantidade
        }
    });

    await prisma.movimentacaoEstoque.create({
        data: {
            tipo: "SAIDA",
            quantidade: Number(dados.quantidade),
            estoqueId: estoque.id
        }
    });

    return servicoPeca;

}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove,
    atualizarStatus,
    converterAgendamento,
    adicionarPeca
};