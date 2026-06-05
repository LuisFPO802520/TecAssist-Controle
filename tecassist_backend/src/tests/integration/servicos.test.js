const request = require("supertest");
const bcrypt = require("bcrypt");

const app = require("../../app");
const prisma = require("../../config/prisma");

let token;
let clienteId;
let usuarioId;

describe("Fluxo Serviço", () => {

    beforeAll(async () => {

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

        await prisma.$disconnect();

    });

    test("Criar cliente", async () => {

        const random = Math.floor(
        100000000 + Math.random() * 900000000
        );
        const response = await request(app)
                .post("/clientes")
                .set("Authorization", `Bearer ${token}`)
                .send({
                    nome: "Cliente Teste",
                    telefone: `67${random}`
                });

        console.log(response.body);
        expect(response.statusCode).toBe(201);
        clienteId = response.body.id;

    });

    test("Criar serviço", async () => {

        const response = await request(app)
            .post("/servicos")
            .set("Authorization", `Bearer ${token}`)
            .send({
                equipamento: "TV Samsung",
                marca: "Samsung",
                modelo: "UN40",
                problema: "Não liga",
                clienteId,
                usuarioId
            });


        console.log(response.body);
        expect(response.statusCode).toBe(201);

        expect(response.body).toHaveProperty("codigo");

    });

});