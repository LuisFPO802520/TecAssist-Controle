const repository = require("../repositories/estoqueRepository");

async function create(data) {

    return repository.create(data);

}

async function findAll() {

    return repository.findAll();

}

async function findById(id) {

    const item =await repository.findById(
            Number(id)
        );

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

    return repository.remove(
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