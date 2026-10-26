const express = require("express");

const router = express.Router();

const movimentacaoController = require("../controllers/movimentacaoController");

const authMiddleware = require("../middlewares/authMiddleware");

const roleMiddleware = require("../middlewares/roleMiddleware");

router.use(authMiddleware);

router.post("/entrada/:id", roleMiddleware("ADMIN"), movimentacaoController.entrada);

router.post("/saida/:id", roleMiddleware("ADMIN"), movimentacaoController.saida);

router.get("/historico", movimentacaoController.historico);

module.exports = router;