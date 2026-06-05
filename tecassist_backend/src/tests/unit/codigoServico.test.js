const gerarCodigo = require("../../utils/createCodeServico");

describe("Gerador de Código",() => {

    test("Deve gerar código corretamente", () => {

            const codigo = gerarCodigo(1);

            expect(codigo).toMatch(/^TA\d{4}.0001$/);

    });

});