const express = require("express");

const router = express.Router();

const estoqueController = require("../controllers/estoqueController");
const authMiddleware = require("../middlewares/authMiddleware");
const roleMiddleware = require("../middlewares/roleMiddleware");

router.use(authMiddleware);

router.post("/", roleMiddleware("ADMIN"), estoqueController.create);
router.get("/", estoqueController.findAll);
router.get("/:id", estoqueController.findById);
router.put("/:id", roleMiddleware("ADMIN"), estoqueController.update);
router.delete("/:id", roleMiddleware("ADMIN"), estoqueController.remove);

module.exports = router;