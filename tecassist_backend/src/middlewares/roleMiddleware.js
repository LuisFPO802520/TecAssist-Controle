function roleMiddleware(...rolesPermitidas) {

    return (req, res, next) => {

        const tipo = req.usuario.tipo;

        if (!rolesPermitidas.includes(tipo)) {

            return res.status(403).json({
                error: "Sem permissão"
            });

        }

        next();

    };

}

module.exports = roleMiddleware;