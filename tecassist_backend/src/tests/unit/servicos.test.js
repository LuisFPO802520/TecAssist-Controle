const servicoService = require("../../services/servicoService");
const servicoRepository = require("../../repositories/servicoRepository");
const prisma = require("../../config/prisma");

jest.mock("../../repositories/servicoRepository");
jest.mock("../../config/prisma", () => ({
    cliente: {
        findUnique: jest.fn()
    },

    usuario: {
        findUnique: jest.fn()
    },

    servico: {
        update: jest.fn(),
        findUnique: jest.fn()
    },

    agendamento: {
        findUnique: jest.fn(),
        update: jest.fn()
    },

    estoque: {
        findUnique: jest.fn(),
        update: jest.fn()
    },

    servicoPeca: {
        create: jest.fn()
    },

    movimentacaoEstoque: {
        create: jest.fn()
    }

}));

describe("ServicoService", () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    test("Deve exigir equipamento", async () => {

        await expect(
            servicoService.create({})
        ).rejects.toThrow("Equipamento é obrigatório");

    });

    test("Deve exigir cliente", async () => {

        await expect(
            servicoService.create({
                equipamento: "TV"
            })
        ).rejects.toThrow("Cliente é obrigatório");

    });

    test("Deve exigir usuário", async () => {

        await expect(
            servicoService.create({
                equipamento: "TV",
                clienteId: 1
            })
        ).rejects.toThrow("Usuário responsável é obrigatório");

    });

    test("Deve validar cliente existente", async () => {

        prisma.cliente.findUnique.mockResolvedValue(null);

        await expect(
            servicoService.create({
                equipamento: "TV",
                clienteId: 1,
                usuarioId: 1
            })
        ).rejects.toThrow("Cliente não encontrado");

    });

    test("Deve validar usuário existente", async () => {

        prisma.cliente.findUnique.mockResolvedValue({
            id: 1
        });

        prisma.usuario.findUnique.mockResolvedValue(null);

        await expect(
            servicoService.create({
                equipamento: "TV",
                clienteId: 1,
                usuarioId: 1
            })
        ).rejects.toThrow("Usuário não encontrado");

    });

    test("Deve buscar serviço por id", async () => {

        servicoRepository.findById.mockResolvedValue({
            id: 1
        });

        const resultado =
            await servicoService.findById(1);

        expect(resultado.id).toBe(1);

    });

    test("Deve lançar erro quando serviço não existir", async () => {

        servicoRepository.findById.mockResolvedValue(null);

        await expect(
            servicoService.findById(999)
        ).rejects.toThrow("Serviço não encontrado");

    });

    test("Deve atualizar status", async () => {

        servicoRepository.update.mockResolvedValue({
            status: "PRONTO"
        });

        const resultado =
            await servicoService.atualizarStatus(
                1,
                "PRONTO"
            );

        expect(resultado.status).toBe("PRONTO");

    });

    test("Deve rejeitar status inválido", async () => {

        await expect(
            servicoService.atualizarStatus(
                1,
                "TESTE"
            )
        ).rejects.toThrow("Status inválido");

    });

    test("Deve validar agendamento existente", async () => {

        prisma.agendamento.findUnique.mockResolvedValue(
            null
        );

        await expect(
            servicoService.converterAgendamento(
                1,
                {}
            )
        ).rejects.toThrow(
            "Agendamento não encontrado"
        );

    });

    test("Deve validar serviço existente ao adicionar peça", async () => {

        prisma.servico.findUnique.mockResolvedValue(
            null
        );

        await expect(
            servicoService.adicionarPeca(
                1,
                {}
            )
        ).rejects.toThrow(
            "Serviço não encontrado"
        );

    });

    test("Deve validar peça existente", async () => {

        prisma.servico.findUnique.mockResolvedValue({
            id: 1
        });

        prisma.estoque.findUnique.mockResolvedValue(
            null
        );

        await expect(
            servicoService.adicionarPeca(
                1,
                {
                    estoqueId: 1,
                    quantidade: 1
                }
            )
        ).rejects.toThrow(
            "Peça não encontrada"
        );

    });

    test("Deve validar estoque insuficiente", async () => {

        prisma.servico.findUnique.mockResolvedValue({
            id: 1
        });

        prisma.estoque.findUnique.mockResolvedValue({
            id: 1,
            quantidade: 1
        });

        await expect(
            servicoService.adicionarPeca(
                1,
                {
                    estoqueId: 1,
                    quantidade: 5
                }
            )
        ).rejects.toThrow(
            "Estoque insuficiente"
        );

    });

    test("Deve adicionar peça com sucesso", async () => {

        prisma.servico.findUnique.mockResolvedValue({
            id: 1
        });

        prisma.estoque.findUnique.mockResolvedValue({
            id: 1,
            quantidade: 10
        });

        prisma.servicoPeca.create.mockResolvedValue({
            id: 1
        });

        const resultado =
            await servicoService.adicionarPeca(
                1,
                {
                    estoqueId: 1,
                    quantidade: 2
                }
            );

        expect(resultado.id).toBe(1);

    });

});
