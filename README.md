# Agenda CLI

Aplicação de linha de comando em Elixir para gerenciar uma agenda de contatos
pessoais. Os dados ficam em `contacts.json`, no diretório onde a aplicação é
executada.

Projeto da disciplina T300 Programação Funcional (UNIFOR).

## Requisitos

- Elixir 1.14 ou superior (com Erlang/OTP)
- Mix (vem junto com o Elixir)

### Instalando o Elixir

- **Windows:** baixe o instalador em <https://elixir-lang.org/install.html#windows>
  ou use `winget install ElixirLang.Elixir` (o Erlang/OTP também é necessário).
- **Linux/macOS:** veja <https://elixir-lang.org/install.html>.

Confira a instalação com:

```bash
elixir --version
```

## Instalação

Dentro da pasta do projeto, baixe as dependências (só a biblioteca Jason):

```bash
mix deps.get
```

## Como executar

```bash
mix run -e "AgendaCli.main([])"
```

O alias definido no `mix.exs` faz a mesma coisa:

```bash
mix agenda
```

> **Windows:** se os acentos aparecerem quebrados no terminal, rode `chcp 65001`
> antes, para o console usar UTF-8.

### Sem Elixir instalado (via Docker)

```bash
docker run --rm -it -v "${PWD}:/app" -w /app elixir:1.18 sh -c "mix local.hex --force && mix deps.get && mix agenda"
```

## Comandos

| Comando | Exemplo | Descrição |
|---|---|---|
| `add` | `add --name Ana Lima --company Acme --phone 85912345678 --email ana.lima@acme.com` | Adiciona um contato (os 4 campos são obrigatórios) |
| `edit <id>` | `edit 123 --phone 85912341234` | Altera um ou mais campos de um contato |
| `del <id>` | `del 123` | Remove um contato |
| `show <id>` | `show 123` | Mostra todos os dados de um contato |
| `list` | `list` | Lista todos os contatos |
| `search` | `search --name ana` | Busca parcial e sem diferenciar maiúsculas/minúsculas por `--name`, `--phone` ou `--email` (uma flag por vez) |
| `help` | `help` | Mostra os comandos |
| `exit` | `exit` | Encerra a aplicação |

Validações:

- telefone: só dígitos, DDD + número (10 ou 11 dígitos);
- e-mail: formato `algo@dominio.ext`;
- nenhum campo pode ficar vazio.

### Exemplo de sessão

```
agenda> add --name Ana Lima --company Acme Ltda --phone 85912345678 --email ana.lima@acme.com
Contato adicionado com ID 1713531600000.
agenda> search --phone 85
ID              NOME                   EMPRESA          TELEFONE      E-MAIL
1713531600000   Ana Lima               Acme Ltda        85912345678   ana.lima@acme.com
(1 contato(s))
agenda> edit 1713531600000 --name Ana Silva --company Acme LTDA
Contato 1713531600000 atualizado.
agenda> exit
Até mais!
```

## Estrutura

```
agenda_cli/
├── mix.exs                     # projeto, dependência Jason e alias `mix agenda`
├── lib/
│   ├── agenda_cli.ex           # AgendaCli: main/1, loop recursivo e parse de comandos/flags
│   └── agenda_cli/
│       ├── contacts.ex         # AgendaCli.Contacts: funções puras (add, delete, edit, search, find)
│       ├── store.ex            # AgendaCli.Store: load/0 e save/1 do contacts.json
│       └── formatter.ex        # AgendaCli.Formatter: monta o texto de show/list
└── test/                       # testes ExUnit e doctests
```

| Módulo | Responsabilidade |
|---|---|
| `AgendaCli` | Ponto de entrada (`main/1`), loop interativo por recursão de cauda, parse de comandos com pattern matching |
| `AgendaCli.Contacts` | Funções puras que recebem a lista e devolvem uma lista nova |
| `AgendaCli.Store` | Leitura e escrita do arquivo JSON com Jason |
| `AgendaCli.Formatter` | Formatação para o terminal (sem IO) |

## Testes

```bash
mix test
```
