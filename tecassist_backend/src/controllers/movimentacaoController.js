const movimentacaoService = require("../services/movimentacaoService");

async function entrada(req, res) {

    try {
        const movimentacao = await movimentacaoService.entrada(
            req.params.id,
            req.body.quantidade
        );

        res.status(201).json(movimentacao);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function saida(req, res) {

    try {
        const movimentacao = await movimentacaoService.saida(
            req.params.id,
            req.body.quantidade
        );

        res.status(201).json(movimentacao);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function historico(req, res) {

    const lista = await movimentacaoService.historico();

    res.json(lista);

}

module.exports = {
    entrada,
    saida,
    historico
};