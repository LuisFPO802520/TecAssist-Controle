const estoqueService =
    require("../services/estoqueService");

async function create(req, res) {

    try {
        const item = await estoqueService.create(
                req.body
        );

        res.status(201).json(item);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function findAll(req, res) {

    const itens = await estoqueService.findAll();

    res.json(itens);

}

async function findById(req, res) {

    try {
        const item =await estoqueService.findById(
            req.params.id
        );

        res.json(item);

    } catch (error) {
        res.status(404).json({error: error.message});
    }

}

async function update(req, res) {

    try {
        const item = await estoqueService.update(
            req.params.id,
            req.body
        );

        res.json(item);

    } catch (error) {
        res.status(400).json({error: error.message});
    }

}

async function remove(req, res) {

    try {
        await estoqueService.remove(
            req.params.id
        );

        res.json({message: "Item removido"});

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