const crypto = require("crypto");
 
let codigoAtual = null;

/**
 * Gera um novo código de cadastro.
 *
 * @param {number} limiteUsos Quantas contas podem usar o código.
 */
function gerarCodigoCadastro(limiteUsos = 1) {
   if (
    !Number.isInteger(limiteUsos) ||
    limiteUsos < 1 ||
    limiteUsos > 50
  ) {
    throw new Error(
      "O limite de usos deve estar entre 1 e 50"
    );
  }

   const codigo = crypto
    .randomInt(100000, 1000000)
    .toString();

  const agora = Date.now();

   const expiresAt = agora + 60 * 1000;

  codigoAtual = {
    codigo,

    limiteUsos,

    usos: 0,

    expiresAt,
  };

  return obterInfoCodigo();
}

 
function obterInfoCodigo() {
  if (!codigoAtual) {
    return null;
  }

  const agora = Date.now();

   if (agora >= codigoAtual.expiresAt) {
    codigoAtual = null;

    return null;
  }

  const segundosRestantes = Math.ceil(
    (codigoAtual.expiresAt - agora) / 1000
  );

  return {
    codigo: codigoAtual.codigo,

    limiteUsos: codigoAtual.limiteUsos,

    usos: codigoAtual.usos,

    usosRestantes:
      codigoAtual.limiteUsos -
      codigoAtual.usos,

    expiresAt:
      new Date(
        codigoAtual.expiresAt
      ).toISOString(),

    expiresInSeconds:
      segundosRestantes,
  };
}

 
function consumirCodigoCadastro(codigoRecebido) {
  if (!codigoAtual) {
    throw new Error(
      "Não existe código de cadastro ativo"
    );
  }

  const agora = Date.now();

   if (agora >= codigoAtual.expiresAt) {
    codigoAtual = null;

    throw new Error(
      "Código de cadastro expirado"
    );
  }

  const recebido =
    String(codigoRecebido).trim();

  const esperado =
    String(codigoAtual.codigo);

  if (recebido.length !== esperado.length) {
    throw new Error(
      "Código de cadastro inválido"
    );
  }

   const codigoValido =
    crypto.timingSafeEqual(
      Buffer.from(recebido),
      Buffer.from(esperado)
    );

  if (!codigoValido) {
    throw new Error(
      "Código de cadastro inválido"
    );
  }

   if (
    codigoAtual.usos >=
    codigoAtual.limiteUsos
  ) {
    throw new Error(
      "Este código já atingiu o limite de usos"
    );
  }

   codigoAtual.usos++;

  return obterInfoCodigo();
}

 
function devolverUsoCodigo(
  codigoConsumido
) {
  if (!codigoAtual) {
    return;
  }
 
  if (
    String(codigoAtual.codigo) !==
    String(codigoConsumido)
  ) {
    return;
  }

  if (codigoAtual.usos > 0) {
    codigoAtual.usos--;
  }
}


module.exports = {
  gerarCodigoCadastro,
  obterInfoCodigo,
  consumirCodigoCadastro,
  devolverUsoCodigo,
};