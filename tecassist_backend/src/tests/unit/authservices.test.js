const prisma = require("../../config/prisma");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const authService = require("../../services/authService");

jest.mock("../../config/prisma", () => ({
    usuario: {
        findUnique: jest.fn()
    }
}));

jest.mock("bcrypt");
jest.mock("jsonwebtoken");

describe("AuthService", () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    test("Deve realizar login com sucesso", async () => {

        prisma.usuario.findUnique.mockResolvedValue({
            id: 1,
            nome: "Administrador",
            email: "admin@teste.com",
            senha: "hashSenha",
            tipo: "ADMIN"
        });

        bcrypt.compare.mockResolvedValue(true);

        jwt.sign.mockReturnValue("token_fake");

        const resultado = await authService.login(
            "admin@teste.com",
            "123456"
        );

        expect(resultado.usuario.id).toBe(1);
        expect(resultado.usuario.nome).toBe("Administrador");
        expect(resultado.token).toBe("token_fake");

    });

    test("Deve lançar erro quando usuário não existir", async () => {

        prisma.usuario.findUnique.mockResolvedValue(null);

        await expect(
            authService.login(
                "naoexiste@teste.com",
                "123456"
            )
        ).rejects.toThrow("Usuário não encontrado");

    });

    test("Deve lançar erro quando senha for inválida", async () => {

        prisma.usuario.findUnique.mockResolvedValue({
            id: 1,
            nome: "Administrador",
            email: "admin@teste.com",
            senha: "hashSenha",
            tipo: "ADMIN"
        });

        bcrypt.compare.mockResolvedValue(false);

        await expect(
            authService.login(
                "admin@teste.com",
                "senha_errada"
            )
        ).rejects.toThrow("Senha inválida");

    });

});