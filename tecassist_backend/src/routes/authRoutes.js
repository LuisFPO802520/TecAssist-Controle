const express = require("express");

const router = express.Router();

const authController = require("../controllers/authController");

const authMiddleware = require("../middlewares/authMiddleware");

const roleMiddleware = require("../middlewares/roleMiddleware");

router.post("/login", authController.login);

router.post(
  "/register",
  authController.cadastrarFuncionario
);

router.post(
  "/codigo-cadastro",
  authMiddleware,
  roleMiddleware("ADMIN"),
  authController.criarCodigoCadastro
);

router.get(
  "/codigo-cadastro",
  authMiddleware,
  roleMiddleware("ADMIN"),
  authController.consultarCodigoCadastro
);

module.exports = router;