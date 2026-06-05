const express = require("express");

const router = express.Router();

const usuarioController = require("../controllers/usuarioController");

const authMiddleware = require("../middlewares/authMiddleware");

const roleMiddleware = require("../middlewares/roleMiddleware");

router.use(authMiddleware);

router.post("/", roleMiddleware("ADMIN"), usuarioController.create);

router.get("/", roleMiddleware("ADMIN"), usuarioController.findAll);

router.get("/:id", roleMiddleware("ADMIN"), usuarioController.findById);

router.put("/:id", roleMiddleware("ADMIN"), usuarioController.update);

router.delete("/:id", roleMiddleware("ADMIN"), usuarioController.remove);

module.exports = router;