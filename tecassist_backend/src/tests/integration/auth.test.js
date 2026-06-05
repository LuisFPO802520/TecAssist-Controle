const request = require("supertest");
const bcrypt = require("bcrypt");

const app = require("../../app");
const prisma = require("../../config/prisma");

describe("Auth", () => {

    beforeAll(async () => {

        const senhaHash = await bcrypt.hash("123456", 10);

        await prisma.usuario.upsert({
            where: {email: "teste@teste.com"},
            update: {},
            create: {
                nome: "Usuário Teste",
                email: "teste@teste.com",
                senha: senhaHash,
                tipo: "ADMIN"
            }
        });

    });

    afterAll(async () => {

        await prisma.$disconnect();

    });

    test("Login com sucesso", async () => {

            const response = await request(app)

                .post("/auth/login")
                .send({
                    email: "teste@teste.com",
                    senha: "123456"
                });

            expect(response.statusCode).toBe(200);

            expect(response.body).toHaveProperty("token");

        }

    );

    test("Senha inválida", async () => {

            const response = await request(app)

                .post("/auth/login")
                .send({
                    email: "teste@teste.com",
                    senha: "errada"
                });

            expect(response.statusCode).toBe(401);

        }

    );

    test("Usuário inexistente", async () => {

            const response = await request(app)

                .post("/auth/login")
                .send({
                    email: "naoexiste@email.com",
                    senha: "123456"
                });

            expect(response.statusCode).toBe(401);

        }

    );

});