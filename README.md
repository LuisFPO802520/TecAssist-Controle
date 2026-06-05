# TecAssist

Sistema de gestão para assistências técnicas desenvolvido como Trabalho de Conclusão de Curso (TCC).

## Sobre o Projeto

O TecAssist é uma plataforma voltada para o gerenciamento completo de assistências técnicas, permitindo o controle de clientes, agendamentos, ordens de serviço, estoque de peças, movimentações de estoque e usuários do sistema.

O objetivo é centralizar as operações da assistência técnica em um único ambiente, facilitando o acompanhamento dos serviços e a organização dos processos internos.

---

## Funcionalidades

### 👥 Clientes

- Cadastro de clientes
- Consulta de clientes
- Atualização de informações
- Exclusão de clientes

### 📅 Agendamentos

- Criação de agendamentos
- Controle de status
- Conversão de agendamentos em serviços

### 🔧 Serviços

- Cadastro de ordens de serviço
- Controle de status do serviço
- Associação de clientes e técnicos
- Adição de peças utilizadas

### 📦 Estoque

- Cadastro de produtos e peças
- Controle de quantidade disponível
- Atualização de estoque

### 📊 Movimentações

- Entrada de estoque
- Saída de estoque
- Histórico de movimentações

### 👨‍💼 Usuários

- Cadastro de usuários
- Autenticação via JWT
- Controle de permissões

---

## 🛠 Tecnologias Utilizadas

### Backend

- Node.js
- Express
- Prisma ORM
- PostgreSQL
- JWT Authentication
- Bcrypt
- Jest
- Supertest

### Mobile

- Flutter
- Dart
- Dio
- Shared Preferences

---

## ▶️ Executando o Projeto

### Backend

Instalar dependências:

```bash
Abrir terminal na pasta tecassist_backend
npm install
```

Executar migrações:

```bash
npx prisma migrate dev
```

Iniciar servidor:

```bash
npm start
```

Modo desenvolvimento:

```bash
npm run dev
```

---

### Testes

Executar todos os testes:

```bash
npm test
```

---

### Flutter

Instalar dependências:

```bash
flutter pub get
```

Executar aplicação:

```bash
flutter run
```

---

## 👨‍🎓 Trabalho de Conclusão de Curso

Projeto desenvolvido como Trabalho de Conclusão de Curso (TCC) para o curso de Sistemas de Informação.

**Autor:** Luis Felipe P. de Oliveira
**Projeto:** TecAssist Controle – Sistema de Gestão para Assistências Técnicas
