const request = require("supertest");
const app = require("../../app");

describe("GET /", () => {

    test("Deve retornar API funcionando", async () => {

        const response = await request(app).get("/");

        expect(response.statusCode).toBe(200);

        expect(response.body.message).toBe("TecAssist API funcionando");

    });

});