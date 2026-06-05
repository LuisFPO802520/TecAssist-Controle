const clienteService = require("../services/clienteService");

async function create(req, res) {

    try {
        const cliente = await clienteService.create(
            req.body
        );

        res.status(201).json(cliente);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function findAll(req, res) {

    const clientes = await clienteService.findAll();

    res.json(clientes);

}

async function findById(req, res) {

    try {
        const cliente = await clienteService.findById(
            req.params.id
        );

        res.json(cliente);

    } catch (error) {
        res.status(404).json({error: error.message});
    }

}

async function update(req, res) {

    try {
        const cliente = await clienteService.update(
            req.params.id,
            req.body
        );

        res.json(cliente);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function remove(req, res) {

    try {
        await clienteService.remove(
            req.params.id
        );

        res.json({message: "Cliente removido"});

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove
};