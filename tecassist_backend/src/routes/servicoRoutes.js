const express = require("express");

const router = express.Router();

const servicoController = require("../controllers/servicoController");

const authMiddleware = require("../middlewares/authMiddleware");

router.use(authMiddleware);

router.post("/", servicoController.create);

router.get("/", servicoController.findAll);

router.post("/converter/:agendamentoId",servicoController.converterAgendamento);

router.get("/:id", servicoController.findById);

router.put("/:id", servicoController.update);

router.delete("/:id", servicoController.remove);

router.patch("/:id/status", servicoController.atualizarStatus);

router.post("/:id/pecas", servicoController.adicionarPeca);

module.exports = router;