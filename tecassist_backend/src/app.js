require("dotenv").config();

const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const usuarioRoutes = require("./routes/usuarioRoutes");
const clienteRoutes = require("./routes/clienteRoutes");
const agendamentoRoutes = require("./routes/agendamentoRoutes");
const servicoRoutes = require("./routes/servicoRoutes");
const estoqueRoutes = require("./routes/estoqueRoutes");
const movimentacaoRoutes = require("./routes/movimentacaoRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/auth", authRoutes);
app.use("/usuarios", usuarioRoutes);
app.use("/clientes", clienteRoutes);
app.use("/agendamentos", agendamentoRoutes);
app.use("/servicos", servicoRoutes);
app.use("/estoque", estoqueRoutes);
app.use("/movimentacoes", movimentacaoRoutes);

app.get("/", (req, res) => {
    res.json({
        message: "TecAssist API funcionando"
    });
});

module.exports = app;