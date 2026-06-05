const agendamentoRepository = require("../repositories/agendamentoRepository");
const clienteRepository = require("../repositories/clienteRepository");

async function create(data) {

    if (!data.descricao) {
        throw new Error("Descrição é obrigatória");
    }

    if (!data.data) {
        throw new Error("Data é obrigatória");
    }

    if (new Date(data.data) < new Date()) {
        throw new Error("Não é possível agendar para uma data passada");
    }

    if (!data.clienteId) {
        throw new Error("Cliente é obrigatório");
    }

    const cliente = await clienteRepository.findById(
        Number(data.clienteId)
    );

    if (!cliente) {
        throw new Error("Cliente não encontrado");
    }

    data.status = "AGENDADO";

    return agendamentoRepository.create(data);

}

async function findAll() {

    return agendamentoRepository.findAll();

}

async function findById(id) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamento;

}

async function update(id, data) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamentoRepository.update(
        Number(id),
        data
    );

}

async function remove(id) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamentoRepository.remove(
        Number(id)
    );

}

async function atualizarStatus(id, status) {

    const statusValidos = [
        "AGENDADO",
        "CONVERTIDO",
        "CANCELADO",
        "RETIRADO"
    ];

    if (!statusValidos.includes(status)) {
        throw new Error("Status inválido");
    }

    return agendamentoRepository.update(
        Number(id),
        { status }
    );
}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove,
    atualizarStatus
};