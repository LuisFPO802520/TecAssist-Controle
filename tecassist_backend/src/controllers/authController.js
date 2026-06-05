const authService = require("../services/authService");

async function login(req, res) {

    try {

        const { email, senha } = req.body;

        const resultado = await authService.login(email, senha);

        res.json(resultado);

    } catch (error) {
        res.status(401).json({error: error.message});
    }

}

module.exports = {
    login
};