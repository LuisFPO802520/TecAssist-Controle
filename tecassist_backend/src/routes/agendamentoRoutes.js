const express = require("express");

const router = express.Router();

const controller = require("../controllers/agendamentoController");

const authMiddleware = require("../middlewares/authMiddleware");

router.use(authMiddleware);

router.post("/", controller.create);

router.get("/", controller.findAll);

router.get("/:id", controller.findById);

router.put("/:id", controller.update);

router.delete("/:id", controller.remove);

router.patch("/:id/status", controller.atualizarStatus);

module.exports = router;