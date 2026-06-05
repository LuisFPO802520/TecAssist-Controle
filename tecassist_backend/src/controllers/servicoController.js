const servicoService =
    require("../services/servicoService");

async function create(req, res) {

    try {
        const servico = await servicoService.create(
            req.body
        );

        res.status(201).json(servico);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function findAll(req, res) {

    try {
        const servicos = await servicoService.findAll();

        res.json(servicos);

    } catch (error) {
        res.status(500).json({error: error.message});
    }

}

async function findById(req, res) {

    try {
        const servico = await servicoService.findById(
            req.params.id
        );

        res.json(servico);

    } catch (error) {
        res.status(404).json({error: error.message});
    }

}

async function update(req, res) {

    try {
        const servico = await servicoService.update(
            req.params.id,
            req.body
        );

        res.json(servico);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function remove(req, res) {

    try {
        await servicoService.remove(
            req.params.id
        );

        res.json({message: "Serviço removido com sucesso"});

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function atualizarStatus(req, res) {

    try {
        const servico = await servicoService.atualizarStatus(
            req.params.id,
            req.body.status
        );

        res.json(servico);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function converterAgendamento(req, res) {

    try {
        const servico = await servicoService.converterAgendamento(
            req.params.agendamentoId,
            req.body
        );

        res.status(201).json(servico);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function adicionarPeca(req, res) {

    try {
        const resultado =await servicoService.adicionarPeca(
            req.params.id,
            req.body
        );

        res.status(201).json(resultado);

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
    atualizarStatus,
    converterAgendamento,
    adicionarPeca
};