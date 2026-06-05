const express = require("express");

const router = express.Router();

const estoqueController = require("../controllers/estoqueController");

const authMiddleware = require("../middlewares/authMiddleware");

router.use(authMiddleware);

router.post("/", estoqueController.create);

router.get("/", estoqueController.findAll);

router.get("/:id", estoqueController.findById);

router.put("/:id", estoqueController.update);

router.delete("/:id", estoqueController.remove);

module.exports = router;