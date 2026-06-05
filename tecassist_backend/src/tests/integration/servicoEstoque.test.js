const request = require("supertest");
const app = require("../../app");

let token;
let clienteId;
let servicoId;
let estoqueId;

describe("Serviço utilizando peças", () => {

    beforeAll(async () => {

        const login = await request(app)
            .post("/auth/login")
            .send({
                email: "admin@teste.com",
                senha: "123456"
            });

        token = login.body.token;

    });

    test("Criar cliente", async () => {

        const random = Math.floor(
        100000000 + Math.random() * 900000000
        );
        const response = await request(app)
            .post("/clientes")
            .set("Authorization", `Bearer ${token}`)
            .send({
                nome: "Cliente Serviço",
                telefone: `67${random}`
            });

        clienteId = response.body.id;

        console.log(response.body);
        expect(response.statusCode).toBe(201);

    });

    test("Criar item estoque", async () => {

        const response = await request(app)
            .post("/estoque")
            .set("Authorization", `Bearer ${token}`)
            .send({
                nome: "Resistor",
                descricao: "10k",
                quantidade: 20,
                valor: 2,
                fornecedor: "Fornecedor"
            });

        estoqueId = response.body.id;


        console.log(response.body);
        expect(response.statusCode).toBe(201);

    });

    test("Criar serviço", async () => {

        const response = await request(app)
            .post("/servicos")
            .set("Authorization", `Bearer ${token}`)
            .send({
                equipamento: "TV Samsung",
                clienteId: clienteId,
                usuarioId: 1
            });

        servicoId = response.body.id;

        console.log(response.body);
        expect(response.statusCode).toBe(201);

    });

    test("Adicionar peça ao serviço", async () => {

        const response = await request(app)
            .post(`/servicos/${servicoId}/pecas`)
            .set("Authorization", `Bearer ${token}`)
            .send({
                estoqueId: estoqueId,
                quantidade: 2
            });


        console.log(response.body);
        expect(response.statusCode).toBe(201);

    });

});