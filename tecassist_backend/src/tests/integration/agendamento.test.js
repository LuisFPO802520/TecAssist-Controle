const request = require("supertest");
const bcrypt = require("bcrypt");
const app = require("../../app");
const prisma = require("../../config/prisma");

describe("Agendamento", () => {

    let clienteId;
    let token;
    let agendamentoId;

    beforeAll(async () => {

        const random = Math.floor(100000000 + Math.random() * 900000000);
        
        const cliente = await prisma.cliente.create({
            data: {
                nome: "Cliente Teste",
                telefone: `67${random}`
            }
        });

        clienteId = cliente.id;

        const senhaHash = await bcrypt.hash("123456",10);

        const usuario = await prisma.usuario.upsert({
            where: { email: "admin@teste.com" },
            update: {},
            create: {
                nome: "Administrador",
                email: "admin@teste.com",
                senha: senhaHash,
                tipo: "ADMIN"
            }

        });

        usuarioId = usuario.id;

        const login = await request(app)
            .post("/auth/login")
            .send({
                email: "admin@teste.com",
                senha: "123456"
            });

        token = login.body.token;
    });

    afterAll(async () => {

        await prisma.agendamento.deleteMany({
            where: {id: agendamentoId}
        });

        await prisma.cliente.deleteMany({
            where: {id: clienteId}
        });
        
    });

    test("Deve criar um agendamento", async () => {

        const response = await request(app)
            .post("/agendamentos")
            .set("Authorization", `Bearer ${token}`)
            .send({
                descricao: "Troca de tela",
                data: "2026-12-10T14:00:00.000Z",
                clienteId
            });

        expect(response.status).toBe(201);

        agendamentoId = response.body.id;

        expect(response.body).toHaveProperty("id");
        expect(response.body.descricao).toBe("Troca de tela");
        expect(response.body.status).toBe("AGENDADO");
    });
});