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

    try {
        const usuarios = await usuarioService.findAll();
        return res.json(usuarios);

    } catch (error) {
        return res.status(500).json({ error: "Erro ao listar usuários." });
    }

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

async function findProfile(req, res) {
    try {
        const usuario = await usuarioService.findById(req.usuario.id);
        return res.json(usuario);

    } catch (error) {
        return res.status(error.statusCode || 404).json({
            error: error.message,
        });
    }
}

async function updateProfile(req, res) {
    try {
        const usuario = await usuarioService.updateProfile(
            req.usuario.id,
            req.body
        );

        return res.json(usuario);
    } catch (error) {
        return res.status(error.statusCode || 400).json({
            error: error.message,
        });
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
    findProfile,
    updateProfile,
    remove,
};