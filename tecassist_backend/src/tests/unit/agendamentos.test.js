const agendamentoService = require("../../services/agendamentoService");
const agendamentoRepository = require("../../repositories/agendamentoRepository");
const clienteRepository = require("../../repositories/clienteRepository");

jest.mock("../../repositories/agendamentoRepository");
jest.mock("../../repositories/clienteRepository");

describe("AgendamentoService", () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    test("Deve criar agendamento com sucesso", async () => {

        clienteRepository.findById.mockResolvedValue({
            id: 1
        });

        agendamentoRepository.create.mockResolvedValue({
            id: 1,
            status: "AGENDADO"
        });

        const resultado = await agendamentoService.create({
            descricao: "Troca de tela",
            data: "2030-12-10T10:00:00.000Z",
            clienteId: 1
        });

        expect(resultado.id).toBe(1);
        expect(resultado.status).toBe("AGENDADO");

    });

    test("Deve exigir descrição", async () => {

        await expect(
            agendamentoService.create({
                data: "2030-12-10T10:00:00.000Z",
                clienteId: 1
            })
        ).rejects.toThrow("Descrição é obrigatória");

    });

    test("Deve exigir data", async () => {

        await expect(
            agendamentoService.create({
                descricao: "Teste",
                clienteId: 1
            })
        ).rejects.toThrow("Data é obrigatória");

    });

    test("Deve impedir data passada", async () => {

        await expect(
            agendamentoService.create({
                descricao: "Teste",
                data: "2020-01-01T10:00:00.000Z",
                clienteId: 1
            })
        ).rejects.toThrow(
            "Não é possível agendar para uma data passada"
        );

    });

    test("Deve exigir cliente", async () => {

        await expect(
            agendamentoService.create({
                descricao: "Teste",
                data: "2030-12-10T10:00:00.000Z"
            })
        ).rejects.toThrow("Cliente é obrigatório");

    });

    test("Deve validar cliente existente", async () => {

        clienteRepository.findById.mockResolvedValue(null);

        await expect(
            agendamentoService.create({
                descricao: "Teste",
                data: "2030-12-10T10:00:00.000Z",
                clienteId: 999
            })
        ).rejects.toThrow("Cliente não encontrado");

    });

    test("Deve buscar agendamento por id", async () => {

        agendamentoRepository.findById.mockResolvedValue({
            id: 1
        });

        const resultado = await agendamentoService.findById(1);

        expect(resultado.id).toBe(1);

    });

    test("Deve lançar erro ao buscar agendamento inexistente", async () => {

        agendamentoRepository.findById.mockResolvedValue(null);

        await expect(
            agendamentoService.findById(999)
        ).rejects.toThrow("Agendamento não encontrado");

    });

    test("Deve atualizar agendamento", async () => {

        agendamentoRepository.findById.mockResolvedValue({
            id: 1
        });

        agendamentoRepository.update.mockResolvedValue({
            id: 1
        });

        const resultado = await agendamentoService.update(
            1,
            { descricao: "Nova descrição" }
        );

        expect(resultado.id).toBe(1);

    });

    test("Deve remover agendamento", async () => {

        agendamentoRepository.findById.mockResolvedValue({
            id: 1
        });

        agendamentoRepository.remove.mockResolvedValue({
            id: 1
        });

        const resultado = await agendamentoService.remove(1);

        expect(resultado.id).toBe(1);

    });

    test("Deve atualizar status", async () => {

        agendamentoRepository.update.mockResolvedValue({
            id: 1,
            status: "CONVERTIDO"
        });

        const resultado =
            await agendamentoService.atualizarStatus(
                1,
                "CONVERTIDO"
            );

        expect(resultado.status).toBe("CONVERTIDO");

    });

    test("Deve rejeitar status inválido", async () => {

        await expect(
            agendamentoService.atualizarStatus(
                1,
                "TESTE"
            )
        ).rejects.toThrow("Status inválido");

    });


});