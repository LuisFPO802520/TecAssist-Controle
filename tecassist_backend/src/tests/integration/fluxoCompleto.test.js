const request = require("supertest");
const bcrypt = require("bcrypt");
const app = require("../../app");
const prisma = require("../../config/prisma");

describe("Fluxo Completo TecAssist", () => {

    let token;
    let clienteId;
    let agendamentoId;
    let servicoId;
    let estoqueId;

    beforeAll(async () => {

        const senhaHash = await bcrypt.hash("123456", 10);

        await prisma.usuario.upsert({
            where: {email: "admin@teste.com"},
            update: {},
            create: {
                nome: "Administrador",
                email: "admin@teste.com",
                senha: senhaHash,
                tipo: "ADMIN"
            }
        });

        const login = await request(app)
            .post("/auth/login")
            .send({
                email: "admin@teste.com",
                senha: "123456"
            });

        token = login.body.token;
    });

    afterAll(async () => {

        await prisma.movimentacaoEstoque.deleteMany({
            where: {estoqueId}
        });

        await prisma.servicoPeca.deleteMany({
            where: {servicoId}
        });

        await prisma.servico.deleteMany({
            where: {id: servicoId}
        });

        await prisma.agendamento.deleteMany({
            where: {id: agendamentoId}
        });

        await prisma.cliente.deleteMany({
            where: {id: clienteId}
        });

        await prisma.estoque.deleteMany({
            where: {id: estoqueId}
        });
    });

    test("Fluxo completo", async () => {

        const random = Math.floor(100000000 + Math.random() * 900000000);
        const clienteResponse = await request(app)
            .post("/clientes")
            .set("Authorization", `Bearer ${token}`)
            .send({
                nome: "Cliente Integração",
                telefone: `67${random}`
            });

        expect(clienteResponse.status).toBe(201);

        clienteId = clienteResponse.body.id;

        const agendamentoResponse = await request(app)
            .post("/agendamentos")
            .set("Authorization", `Bearer ${token}`)
            .send({
                descricao: "TV Samsung não liga",
                data: "2026-12-20T10:00:00.000Z",
                clienteId
            });


        expect(agendamentoResponse.status).toBe(201);

        agendamentoId = agendamentoResponse.body.id;

        const converterResponse = await request(app)
            .post(`/servicos/converter/${agendamentoId}`)
            .set("Authorization", `Bearer ${token}`)
            .send({
                equipamento: "TV Samsung",
                marca: "Samsung",
                modelo: "UN40",
                problema: "Não liga",
                usuarioId: 7
            });


        
        console.log(converterResponse.status);
        console.log(converterResponse.body);

        expect(converterResponse.status).toBe(201);

        servicoId = converterResponse.body.id;

        console.log(converterResponse.body);
        expect(converterResponse.body.status).toBe("ABERTO");

        const estoqueResponse = await request(app)
            .post("/estoque")
            .set("Authorization", `Bearer ${token}`)
            .send({
                nome: "Capacitor 2200uF",
                descricao: "Capacitor eletrolítico",
                quantidade: 10,
                valor: 2.5,
                fornecedor: "Fornecedor Teste"
            });

        expect(estoqueResponse.status).toBe(201);

        estoqueId = estoqueResponse.body.id;

        const pecaResponse = await request(app)
            .post(`/servicos/${servicoId}/pecas`)
            .set("Authorization", `Bearer ${token}`)
            .send({
                estoqueId,
                quantidade: 2
            });
        
        expect(pecaResponse.status).toBe(201);

        const estoqueBanco = await prisma.estoque.findUnique({
            where: {id: estoqueId}
        });

        expect(estoqueBanco.quantidade).toBe(8);

        const movimentacoes = await prisma.movimentacaoEstoque.findMany({
            where: {estoqueId}
        });

        expect(movimentacoes.length).toBeGreaterThan(0);

        expect(movimentacoes[0].tipo).toBe("SAIDA");

    });

});