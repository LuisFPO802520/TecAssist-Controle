const clienteRepository = require("../../repositories/clienteRepository");
const clienteService = require("../../services/clienteService");

jest.mock("../../repositories/clienteRepository");

describe("ClienteService", () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    test("Deve criar cliente com sucesso", async () => {

        clienteRepository.findByTelefone.mockResolvedValue(null);
        clienteRepository.create.mockResolvedValue({
            id: 1,
            nome: "João",
            telefone: "67999999999"
        });

        const resultado = await clienteService.create({
            nome: "João",
            telefone: "67999999999"
        });

        expect(resultado.id).toBe(1);

    });

    test("Deve lançar erro quando nome não for informado", async () => {

        await expect(
            clienteService.create({
                telefone: "67999999999"
            })
        ).rejects.toThrow("Nome é obrigatório");

    });

    test("Deve lançar erro quando telefone não for informado", async () => {

        await expect(
            clienteService.create({
                nome: "João"
            })
        ).rejects.toThrow("Telefone é obrigatório");

    });

    test("Deve lançar erro para telefone inválido", async () => {

        await expect(
            clienteService.create({
                nome: "João",
                telefone: "123"
            })
        ).rejects.toThrow("Telefone inválido");

    });

    test("Deve lançar erro quando telefone já existir", async () => {

        clienteRepository.findByTelefone.mockResolvedValue({
            id: 1
        });

        await expect(
            clienteService.create({
                nome: "João",
                telefone: "67999999999"
            })
        ).rejects.toThrow("Telefone já cadastrado");

    });

    test("Deve lançar erro para e-mail inválido", async () => {

        clienteRepository.findByEmail.mockResolvedValue(null);
        clienteRepository.findByTelefone.mockResolvedValue(null);

        await expect(
            clienteService.create({
                nome: "João",
                telefone: "67999999999",
                email: "emailinvalido"
            })
        ).rejects.toThrow("E-mail inválido");

    });

    test("Deve lançar erro quando e-mail já existir", async () => {

        clienteRepository.findByEmail.mockResolvedValue({
            id: 1
        });

        await expect(
            clienteService.create({
                nome: "João",
                telefone: "67999999999",
                email: "teste@teste.com"
            })
        ).rejects.toThrow("E-mail já cadastrado");

    });

    test("Deve lançar erro para CPF inválido", async () => {

        clienteRepository.findByTelefone.mockResolvedValue(null);

        await expect(
            clienteService.create({
                nome: "João",
                telefone: "67999999999",
                cpf: "123"
            })
        ).rejects.toThrow("CPF inválido");

    });

    test("Deve lançar erro quando CPF já existir", async () => {

        clienteRepository.findByTelefone.mockResolvedValue(null);
        clienteRepository.findByCpf.mockResolvedValue({
            id: 1
        });

        await expect(
            clienteService.create({
                nome: "João",
                telefone: "67999999999",
                cpf: "12345678901"
            })
        ).rejects.toThrow("CPF já cadastrado");

    });

    test("Deve buscar cliente por id", async () => {

        clienteRepository.findById.mockResolvedValue({
            id: 1
        });

        const resultado = await clienteService.findById(1);

        expect(resultado.id).toBe(1);

    });

    test("Deve lançar erro quando cliente não existir", async () => {

        clienteRepository.findById.mockResolvedValue(null);

        await expect(
            clienteService.findById(999)
        ).rejects.toThrow("Cliente não encontrado");

    });

});
