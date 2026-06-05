const agendamentoService = require("../services/agendamentoService");

async function create(req, res) {

    try {
        const agendamento = await agendamentoService.create(
            req.body
        );

        res.status(201).json(agendamento);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function findAll(req, res) {

    const agendamentos = await agendamentoService.findAll();

    res.json(agendamentos);

}

async function findById(req, res) {

    try {
        const agendamento = await agendamentoService.findById(
            req.params.id
        );

        res.json(agendamento);

    } catch (error) {
        res.status(404).json({error: error.message});
    }

}

async function update(req, res) {

    try {
        const agendamento = await agendamentoService.update(
            req.params.id,
            req.body
        );

        res.json(agendamento);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function remove(req, res) {

    try {
        await agendamentoService.remove(
            req.params.id
        );

        res.json({message: "Agendamento removido"});

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function atualizarStatus(req, res) {

    try {
        const agendamento = await agendamentoService.atualizarStatus(
                req.params.id,
                req.body.status
            );

        res.json(agendamento);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

module.exports = {
    create,
    findAll,
    findById,
    update,
    remove,
    atualizarStatus
};