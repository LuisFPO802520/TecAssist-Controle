const estoqueService = require("../../services/estoqueService");
const estoqueRepository = require("../../repositories/estoqueRepository");

jest.mock("../../repositories/estoqueRepository");

describe("EstoqueService", () => {

afterEach(() => {
    jest.clearAllMocks();
});

test("Deve criar item de estoque", async () => {

    estoqueRepository.create.mockResolvedValue({
        id: 1,
        nome: "Resistor"
    });

    const resultado = await estoqueService.create({
        nome: "Resistor"
    });

    expect(resultado.id).toBe(1);

});

test("Deve listar itens", async () => {

    estoqueRepository.findAll.mockResolvedValue([
        { id: 1 }
    ]);

    const resultado =
        await estoqueService.findAll();

    expect(resultado.length).toBe(1);

});

test("Deve buscar item por id", async () => {

    estoqueRepository.findById.mockResolvedValue({
        id: 1
    });

    const resultado =
        await estoqueService.findById(1);

    expect(resultado.id).toBe(1);

});

test("Deve lançar erro quando item não existir", async () => {

    estoqueRepository.findById.mockResolvedValue(
        null
    );

    await expect(
        estoqueService.findById(999)
    ).rejects.toThrow(
        "Item não encontrado"
    );

});

test("Deve atualizar item", async () => {

    estoqueRepository.update.mockResolvedValue({
        id: 1,
        nome: "Capacitor"
    });

    const resultado =
        await estoqueService.update(
            1,
            {
                nome: "Capacitor"
            }
        );

    expect(resultado.nome)
        .toBe("Capacitor");

});

test("Deve remover item", async () => {

    estoqueRepository.remove.mockResolvedValue({
        id: 1
    });

    const resultado =
        await estoqueService.remove(1);

    expect(resultado.id).toBe(1);

});

});
