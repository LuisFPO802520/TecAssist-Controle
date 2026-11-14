const repository = require("../repositories/estoqueRepository");

async function create(data) {

    return repository.create(data);

}

async function findAll() {

    return repository.findAll();

}

async function findById(id) {
    const item = await repository.findById(Number(id));

    if (!item) {
        throw new Error("Item não encontrado");
    }

    return item;

}


async function update(id, data) {

    return repository.update(
        Number(id),
        data
    );

}

async function remove(id) {
    const numeroId = Number(id);

    if (!Number.isInteger(numeroId) || numeroId <= 0) {
        throw new Error("ID do item inválido");
    }

    return repository.remove(numeroId);
}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove
};