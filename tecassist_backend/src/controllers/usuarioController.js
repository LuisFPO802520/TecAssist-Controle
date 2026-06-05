const usuarioService = require("../services/usuarioService");

async function create(req, res) {

    try {
        const usuario = await usuarioService.create(
            req.body
        );

        res.status(201).json(usuario);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function findAll(req, res) {

    const usuarios = await usuarioService.findAll();

    res.json(usuarios);

}

async function findById(req, res) {

    try {
        const usuario = await usuarioService.findById(
            req.params.id
        );

        res.json(usuario);

    } catch (error) {
        res.status(404).json({error: error.message});
    }

}

async function update(req, res) {

    try {
        const usuario = await usuarioService.update(
            req.params.id,
            req.body
        );

        res.json(usuario);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function remove(req, res) {

    try {
        await usuarioService.remove(
            req.params.id
        );

        res.json({message: "Usuário removido"});

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