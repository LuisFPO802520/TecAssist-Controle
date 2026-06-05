const movimentacaoService = require("../../services/movimentacaoService");
const movimentacaoRepository = require("../../repositories/movimentacaoRepository");
const prisma = require("../../config/prisma");

jest.mock("../../repositories/movimentacaoRepository");

jest.mock("../../config/prisma", () => ({
    estoque: {
        findUnique: jest.fn(),
        update: jest.fn()
    }
}));

describe("movimentacaoService", () => {

    beforeEach(() => {
        jest.clearAllMocks();
    });

    test("deve realizar entrada de estoque", async () => {

        prisma.estoque.findUnique.mockResolvedValue({
            id: 1,
            quantidade: 10
        });

        prisma.estoque.update.mockResolvedValue({});

        movimentacaoRepository.create.mockResolvedValue({
            id: 1,
            tipo: "ENTRADA"
        });

        const resultado = await movimentacaoService.entrada(
            1,
            5
        );

        expect(prisma.estoque.update).toHaveBeenCalledWith({
            where: { id: 1 },
            data: {
                quantidade: 15
            }
        });

        expect(resultado.tipo).toBe("ENTRADA");

    });

    test("deve lançar erro ao fazer entrada em item inexistente", async () => {

        prisma.estoque.findUnique.mockResolvedValue(null);

        await expect(
            movimentacaoService.entrada(999, 5)
        ).rejects.toThrow("Item não encontrado");

    });

    test("deve realizar saída de estoque", async () => {

        prisma.estoque.findUnique.mockResolvedValue({
            id: 1,
            quantidade: 10
        });

        prisma.estoque.update.mockResolvedValue({});

        movimentacaoRepository.create.mockResolvedValue({
            id: 1,
            tipo: "SAIDA"
        });

        const resultado = await movimentacaoService.saida(
            1,
            3
        );

        expect(prisma.estoque.update).toHaveBeenCalledWith({
            where: { id: 1 },
            data: {
                quantidade: 7
            }
        });

        expect(resultado.tipo).toBe("SAIDA");

    });

    test("deve lançar erro ao fazer saída de item inexistente", async () => {

        prisma.estoque.findUnique.mockResolvedValue(null);

        await expect(
            movimentacaoService.saida(999, 1)
        ).rejects.toThrow("Item não encontrado");

    });

    test("deve lançar erro quando estoque for insuficiente", async () => {

        prisma.estoque.findUnique.mockResolvedValue({
            id: 1,
            quantidade: 2
        });

        await expect(
            movimentacaoService.saida(1, 5)
        ).rejects.toThrow("Quantidade insuficiente");

    });

    test("deve retornar histórico", async () => {

        movimentacaoRepository.findAll.mockResolvedValue([
            {
                id: 1,
                tipo: "ENTRADA"
            }
        ]);

        const resultado = await movimentacaoService.historico();

        expect(resultado.length).toBe(1);

        expect(movimentacaoRepository.findAll)
            .toHaveBeenCalled();

    });

});
