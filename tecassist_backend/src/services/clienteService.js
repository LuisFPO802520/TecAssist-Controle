const clienteRepository = require("../repositories/clienteRepository");

async function create(cliente) {

    if (!cliente.nome) {
        throw new Error("Nome é obrigatório");
    }

    if (!cliente.telefone) {
        throw new Error("Telefone é obrigatório");
    }

    if (!cliente.telefone.match(/^\d{10,11}$/)) {
        throw new Error("Telefone inválido");
    }

    if (cliente.email) {
        const emailExiste = await clienteRepository.findByEmail(
            cliente.email
        );

        if (emailExiste) {
            throw new Error("E-mail já cadastrado");
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!emailRegex.test(cliente.email)) {
            throw new Error("E-mail inválido");
        }

    }

    const telefoneExiste = await clienteRepository.findByTelefone(
        cliente.telefone
    );

    if (telefoneExiste) {
        throw new Error("Telefone já cadastrado");
    }

    if (cliente.cpf) {

        if (!/^\d{11}$/.test(cliente.cpf)) {
            throw new Error("CPF inválido");
        }

        const cpfExiste = await clienteRepository.findByCpf(
            cliente.cpf
        );

        if (cpfExiste) {
            throw new Error("CPF já cadastrado");
        }

    }

    return clienteRepository.create(cliente);

}

async function findAll() {
    return clienteRepository.findAll();
}

async function findById(id) {

    const cliente = await clienteRepository.findById(
        Number(id)
    );

    if (!cliente) {
        throw new Error("Cliente não encontrado");
    }

    return cliente;

}

async function update(id, data) {

    const cliente = await clienteRepository.findById(
        Number(id)
    );

    if (!cliente) {
        throw new Error("Cliente não encontrado");
    }

    return clienteRepository.update(
        Number(id),
        data
    );

}

async function remove(id) {

    const cliente = await clienteRepository.findById(
        Number(id)
    );

    if (!cliente) {
        throw new Error("Cliente não encontrado");
    }

    return clienteRepository.remove(
        Number(id)
    );

}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove
};