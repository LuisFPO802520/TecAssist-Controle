const authService = require("../services/authService");

const {gerarCodigoCadastro, obterInfoCodigo,} = require("../utils/registrationCode");


async function login(req, res) {

    try {

        const { email, senha } = req.body;

        const resultado = await authService.login(email, senha);

        res.json(resultado);

    } catch (error) {
        res.status(401).json({error: error.message});
    }

}

async function criarCodigoCadastro(
  req,
  res
) {
  try {
    const {
      limiteUsos,
    } = req.body;

    const codigo =
      gerarCodigoCadastro(
        Number(limiteUsos)
      );

    return res
      .status(200)
      .json(codigo);
  } catch (error) {
    return res
      .status(400)
      .json({
        mensagem: error.message,
      });
  }
}

async function consultarCodigoCadastro(
  req,
  res
) {
  try {
    const codigo =
      obterInfoCodigo();

    if (!codigo) {
      return res
        .status(404)
        .json({
          mensagem:
            "Não existe código ativo",
        });
    }

    return res
      .status(200)
      .json(codigo);
  } catch (error) {
    return res
      .status(500)
      .json({
        mensagem: error.message,
      });
  }
}

async function cadastrarFuncionario(req, res) {
  try {
    const usuario =
      await authService.cadastrarFuncionario(
        req.body
      );

    return res.status(201).json(usuario);
  } catch (error) {
    return res.status(400).json({
      error: error.message,
    });
  }
}

module.exports = {
  login,
  criarCodigoCadastro,
  consultarCodigoCadastro,
  cadastrarFuncionario
};