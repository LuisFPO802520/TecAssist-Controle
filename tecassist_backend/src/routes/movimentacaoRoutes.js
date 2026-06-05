const express = require("express");

const router = express.Router();

const movimentacaoController = require("../controllers/movimentacaoController");

const authMiddleware = require("../middlewares/authMiddleware");

router.use(authMiddleware);

router.post("/entrada/:id", movimentacaoController.entrada);

router.post("/saida/:id", movimentacaoController.saida);

router.get("/historico", movimentacaoController.historico);

module.exports = router;