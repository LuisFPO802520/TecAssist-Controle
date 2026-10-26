const agendamentoRepository = require("../repositories/agendamentoRepository");
const clienteRepository = require("../repositories/clienteRepository");

async function create(data) {

    if (!data.descricao) {
        throw new Error("Descrição é obrigatória");
    }

    if (!data.data) {
        throw new Error("Data é obrigatória");
    }

    if (new Date(data.data) < new Date()) {
        throw new Error("Não é possível agendar para uma data passada");
    }

    if (!data.clienteId) {
        throw new Error("Cliente é obrigatório");
    }

    const cliente = await clienteRepository.findById(
        Number(data.clienteId)
    );

    if (!cliente) {
        throw new Error("Cliente não encontrado");
    }

    data.status = "AGENDADO";

    return agendamentoRepository.create(data);

}

async function findAll() {

    return agendamentoRepository.findAll();

}

async function findById(id) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamento;

}

async function update(id, data) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamentoRepository.update(
        Number(id),
        data
    );

}

async function remove(id) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamentoRepository.remove(
        Number(id)
    );

}

async function atualizarStatus(id, status) {

    const statusValidos = [
        "AGENDADO",
        "CONVERTIDO",
        "CANCELADO",
        "RETIRADO"
    ];

    if (!statusValidos.includes(status)) {
        throw new Error("Status inválido");
    }

    return agendamentoRepository.update(
        Number(id),
        { status }
    );
}

async function converterEmServico(
  agendamentoId,
  usuarioId,
  dados
) {
  const id =
    Number(agendamentoId);

  const agendamento =
    await prisma.agendamento.findUnique({
      where: {
        id,
      },

      include: {
        cliente: true,
        servicos: true,
      },
    });

  if (!agendamento) {
    const error =
      new Error(
        "Agendamento não encontrado"
      );

    error.statusCode = 404;

    throw error;
  }

  if (
    agendamento.status ===
    "CONVERTIDO"
  ) {
    const error =
      new Error(
        "Este agendamento já foi convertido em serviço"
      );

    error.statusCode = 409;

    throw error;
  }

  if (
    agendamento.status ===
    "CANCELADO"
  ) {
    const error =
      new Error(
        "Um agendamento cancelado não pode ser convertido em serviço"
      );

    error.statusCode = 409;

    throw error;
  }

  if (
    agendamento.servicos.length >
    0
  ) {
    const error =
      new Error(
        "Este agendamento já possui um serviço vinculado"
      );

    error.statusCode = 409;

    throw error;
  }

  if (
    !dados.equipamento ||
    dados.equipamento
      .trim()
      .length === 0
  ) {
    const error =
      new Error(
        "Informe o equipamento"
      );

    error.statusCode = 400;

    throw error;
  }

  return prisma.$transaction(
    async (tx) => {
      const servico =
        await tx.servico.create({
          data: {
            equipamento:
              dados.equipamento.trim(),

            marca:
              dados.marca?.trim() ||
              null,

            modelo:
              dados.modelo?.trim() ||
              null,

            problema:
              dados.problema?.trim() ||
              null,

            status:
              "EM_ANDAMENTO",

            clienteId:
              agendamento.clienteId,

            usuarioId:
              Number(usuarioId),

            agendamentoId:
              agendamento.id,
          },

          include: {
            cliente: true,
            usuario: {
              select: {
                id: true,
                nome: true,
                email: true,
                tipo: true,
              },
            },
            agendamento: true,
          },
        });

      await tx.agendamento.update({
        where: {
          id: agendamento.id,
        },

        data: {
          status:
            "CONVERTIDO",
        },
      });

      return servico;
    }
  );
}

module.exports = {
    create,
    findAll,
    findById,
    update,
    converterEmServico,
    remove,
    atualizarStatus
};