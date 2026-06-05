function gerarCodigo(id) {

    const ano = new Date().getFullYear();

    return `TA${ano}.${String(id).padStart(4, "0")}`;

}

module.exports = gerarCodigo;