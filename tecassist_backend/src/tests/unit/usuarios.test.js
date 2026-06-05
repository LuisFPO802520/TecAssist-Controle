const usuarioService = require("../../services/usuarioService");
const usuarioRepository = require("../../repositories/usuarioRepository");
const bcrypt = require("bcrypt");

jest.mock("../../repositories/usuarioRepository");
jest.mock("bcrypt");

describe("usuarioService", () => {

    beforeEach(() => {
        jest.clearAllMocks();
    });

    test("deve exigir nome", async () => {

        await expect(
            usuarioService.create({
                email: "teste@teste.com",
                senha: "123456"
            })
        ).rejects.toThrow("Nome é obrigatório");

    });

    test("deve exigir email", async () => {

        await expect(
            usuarioService.create({
                nome: "João",
                senha: "123456"
            })
        ).rejects.toThrow("E-mail é obrigatório");

    });

    test("deve exigir senha", async () => {

        await expect(
            usuarioService.create({
                nome: "João",
                email: "teste@teste.com"
            })
        ).rejects.toThrow("Senha é obrigatória");

    });

    test("deve validar tamanho da senha", async () => {

        await expect(
            usuarioService.create({
                nome: "João",
                email: "teste@teste.com",
                senha: "123"
            })
        ).rejects.toThrow("Senha deve ter pelo menos 6 caracteres");

    });

    test("deve impedir email duplicado", async () => {

        usuarioRepository.findByEmail.mockResolvedValue({
            id: 1
        });

        await expect(
            usuarioService.create({
                nome: "João",
                email: "teste@teste.com",
                senha: "123456"
            })
        ).rejects.toThrow("E-mail já cadastrado");

    });

    test("deve validar email", async () => {

        usuarioRepository.findByEmail.mockResolvedValue(null);

        await expect(
            usuarioService.create({
                nome: "João",
                email: "email-invalido",
                senha: "123456"
            })
        ).rejects.toThrow("E-mail inválido");

    });

    test("deve validar telefone", async () => {

        usuarioRepository.findByEmail.mockResolvedValue(null);

        await expect(
            usuarioService.create({
                nome: "João",
                email: "teste@teste.com",
                senha: "123456",
                telefone: "123"
            })
        ).rejects.toThrow("Telefone inválido");

    });

    test("deve criar usuário", async () => {

        usuarioRepository.findByEmail.mockResolvedValue(null);

        bcrypt.hash.mockResolvedValue("senhaHash");

        usuarioRepository.create.mockResolvedValue({
            id: 1,
            nome: "João",
            email: "teste@teste.com"
        });

        const resultado = await usuarioService.create({
            nome: "João",
            email: "teste@teste.com",
            senha: "123456"
        });

        expect(bcrypt.hash).toHaveBeenCalledWith(
            "123456",
            10
        );

        expect(resultado.id).toBe(1);

    });

    test("deve buscar usuário por id", async () => {

        usuarioRepository.findById.mockResolvedValue({
            id: 1
        });

        const resultado = await usuarioService.findById(1);

        expect(resultado.id).toBe(1);

    });

    test("deve lançar erro ao buscar usuário inexistente", async () => {

        usuarioRepository.findById.mockResolvedValue(null);

        await expect(
            usuarioService.findById(999)
        ).rejects.toThrow("Usuário não encontrado");

    });

    test("deve atualizar usuário", async () => {

        usuarioRepository.findById.mockResolvedValue({
            id: 1
        });

        usuarioRepository.update.mockResolvedValue({
            id: 1,
            nome: "Novo Nome"
        });

        const resultado = await usuarioService.update(
            1,
            { nome: "Novo Nome" }
        );

        expect(resultado.nome).toBe("Novo Nome");

    });

    test("deve remover usuário", async () => {

        usuarioRepository.findById.mockResolvedValue({
            id: 1
        });

        usuarioRepository.remove.mockResolvedValue({
            id: 1
        });

        const resultado = await usuarioService.remove(1);

        expect(resultado.id).toBe(1);

    });

});
