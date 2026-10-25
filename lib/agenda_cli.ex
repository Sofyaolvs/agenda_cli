defmodule AgendaCli do
  @moduledoc """
  Ponto de entrada da agenda: loop interativo e parse de comandos.

  Fluxo de cada iteração:

      linha digitada -> parse_command/1 -> comando (tupla) -> execute/2 -> nova lista -> loop/1

  O estado (lista de contatos) não fica em variável global: ele é passado
  como argumento de uma chamada de `loop/1` para a próxima.
  """

  alias AgendaCli.{Contacts, Formatter, Store}

  @prompt "agenda> "

  @help """
  Comandos:
    add --name <nome> --company <empresa> --phone <telefone> --email <email>
    edit <id> [--name ..] [--company ..] [--phone ..] [--email ..]
    del <id>
    show <id>
    list
    search --name <texto> | --phone <texto> | --email <texto>
    help
    exit\
  """

  # ======================================================== entrada / loop

  @doc "Inicia a aplicação: carrega o arquivo e entra no loop."
  def main(_args \\ []) do
    IO.puts("Agenda de contatos. Digite 'help' para ver os comandos.")

    Store.load()
    |> loop()
  end

  # Recursão de cauda: a chamada `loop(new_contacts)` é a última coisa que
  # a função faz. A BEAM reaproveita o frame da pilha, então o loop pode
  # rodar indefinidamente sem estourar memória.
  defp loop(contacts) do
    case @prompt |> IO.gets() |> run(contacts) do
      :halt -> IO.puts("Até mais!")
      {:continue, new_contacts} -> loop(new_contacts)
    end
  end

  # :eof acontece com Ctrl+D / Ctrl+Z ou quando a entrada vem de um arquivo
  defp run(:eof, _contacts), do: :halt
  defp run({:error, _reason}, _contacts), do: :halt

  defp run(line, contacts) do
    line
    |> parse_command()
    |> execute(contacts)
  end

  # ======================================================== parse de comandos

  @doc """
  Converte a linha digitada em um comando:

      iex> AgendaCli.parse_command("show 123")
      {:show, 123}

      iex> AgendaCli.parse_command("search --name ana")
      {:search, :name, "ana"}
  """
  def parse_command(line) do
    line
    |> String.trim()
    |> String.split(~r/\s+/, parts: 2)
    |> parse_parts()
  end

  # Cada comando é uma cláusula: o pattern matching escolhe qual roda
  defp parse_parts([""]), do: :empty
  defp parse_parts(["exit" | _]), do: :exit
  defp parse_parts(["help" | _]), do: :help
  defp parse_parts(["list" | _]), do: :list

  # "add" e "search" sozinhos viram "add" e "search" com texto vazio
  defp parse_parts([cmd]) when cmd in ["add", "search"], do: parse_parts([cmd, ""])

  defp parse_parts(["add", rest]) do
    with {:ok, attrs} <- parse_flags(rest, Contacts.fields()) do
      {:add, attrs}
    end
  end

  defp parse_parts(["edit", rest]) do
    with [id_text | flags] <- String.split(rest, ~r/\s+/, parts: 2),
         {:ok, id} <- parse_id(id_text),
         {:ok, changes} <- parse_flags(Enum.join(flags), Contacts.fields()) do
      {:edit, id, changes}
    end
  end

  defp parse_parts(["del", rest]), do: with({:ok, id} <- parse_id(rest), do: {:del, id})
  defp parse_parts(["show", rest]), do: with({:ok, id} <- parse_id(rest), do: {:show, id})

  defp parse_parts(["search", rest]) do
    case parse_search(rest) do
      {:error, _} = error -> error
      {field, term} -> {:search, field, term}
    end
  end

  defp parse_parts([cmd]) when cmd in ["edit", "del", "show"],
    do: {:error, "Uso: #{cmd} <id>"}

  defp parse_parts([cmd | _]),
    do: {:error, "Comando desconhecido: #{cmd}. Digite 'help'."}

  @doc """
  Recebe o texto depois de "search" e devolve `{:name, valor}`,
  `{:phone, valor}` ou `{:email, valor}`. Só uma flag é aceita.

      iex> AgendaCli.parse_search("--phone 85")
      {:phone, "85"}
  """
  def parse_search(text) do
    with {:ok, flags} <- parse_flags(text, [:name, :phone, :email]) do
      flags
      |> Map.to_list()
      |> single_flag()
    end
  end

  defp single_flag([{field, value}]), do: {field, value}
  defp single_flag([]), do: {:error, "Informe uma flag: --name, --phone ou --email."}
  defp single_flag(_), do: {:error, "A busca aceita apenas uma flag por vez."}

  # ======================================================== parse de flags

  @doc """
  Transforma `"--name Ana Lima --phone 85912345678"` em
  `%{name: "Ana Lima", phone: "85912345678"}`.

  `allowed` é a lista de campos aceitos naquele comando.
  """
  def parse_flags(text, allowed) do
    text
    |> String.split(~r/\s+/, trim: true)
    |> collect_flags(%{}, allowed)
  end

  # Recursão sobre a lista de palavras, acumulando os pares em `acc`
  defp collect_flags([], acc, _allowed), do: {:ok, acc}

  defp collect_flags(["--" <> flag | rest], acc, allowed) do
    # O valor é tudo até a próxima palavra que começa com "--"
    {value_words, remaining} = Enum.split_while(rest, &(not flag?(&1)))

    with {:ok, field} <- flag_to_field(flag),
         :ok <- check_allowed(field, allowed),
         :ok <- check_not_repeated(field, acc),
         :ok <- check_has_value(field, value_words) do
      collect_flags(remaining, Map.put(acc, field, Enum.join(value_words, " ")), allowed)
    end
  end

  defp collect_flags([word | _], _acc, _allowed),
    do: {:error, "Valor '#{word}' sem flag. Use --name, --company, --phone ou --email."}

  defp flag?("--" <> _), do: true
  defp flag?(_), do: false

  defp flag_to_field("name"), do: {:ok, :name}
  defp flag_to_field("company"), do: {:ok, :company}
  defp flag_to_field("phone"), do: {:ok, :phone}
  defp flag_to_field("email"), do: {:ok, :email}
  defp flag_to_field(other), do: {:error, "Flag desconhecida: --#{other}"}

  defp check_allowed(field, allowed) do
    if field in allowed, do: :ok, else: {:error, "A flag --#{field} não é aceita neste comando."}
  end

  defp check_not_repeated(field, acc) do
    if Map.has_key?(acc, field), do: {:error, "A flag --#{field} foi repetida."}, else: :ok
  end

  defp check_has_value(field, []), do: {:error, "A flag --#{field} precisa de um valor."}
  defp check_has_value(_field, _words), do: :ok

  defp parse_id(text) do
    case text |> String.trim() |> Integer.parse() do
      {id, ""} -> {:ok, id}
      _ -> {:error, "ID inválido: '#{String.trim(text)}'. O ID é um número."}
    end
  end

  # ======================================================== execução

  # Cada execute/2 devolve {:continue, lista} ou :halt
  defp execute(:empty, contacts), do: {:continue, contacts}
  defp execute(:exit, _contacts), do: :halt

  defp execute(:help, contacts) do
    IO.puts(@help)
    {:continue, contacts}
  end

  defp execute(:list, contacts) do
    contacts |> Formatter.table() |> IO.puts()
    {:continue, contacts}
  end

  defp execute({:show, id}, contacts) do
    contacts
    |> Contacts.find(id)
    |> print_result(&Formatter.contact/1)

    {:continue, contacts}
  end

  defp execute({:search, field, term}, contacts) do
    contacts
    |> Contacts.search(field, term)
    |> Formatter.table()
    |> IO.puts()

    {:continue, contacts}
  end

  defp execute({:add, attrs}, contacts) do
    contacts
    |> Contacts.add(attrs, System.system_time(:millisecond))
    |> persist(contacts, &"Contato adicionado com ID #{&1.id}.")
  end

  defp execute({:edit, id, changes}, contacts) do
    contacts
    |> Contacts.edit(id, changes)
    |> persist(contacts, &"Contato #{&1.id} atualizado.")
  end

  defp execute({:del, id}, contacts) do
    contacts
    |> Contacts.delete(id)
    |> persist(contacts, &"Contato #{&1.id} (#{&1.name}) removido.")
  end

  defp execute({:error, message}, contacts) do
    IO.puts("Erro: " <> message)
    {:continue, contacts}
  end

  # Operações de escrita: salva no arquivo e só então adota a lista nova.
  # Se falhar, continua com a lista antiga (memória igual ao disco).
  defp persist({:ok, new_contacts, contact}, old_contacts, success_message) do
    case Store.save(new_contacts) do
      :ok ->
        IO.puts(success_message.(contact))
        {:continue, new_contacts}

      {:error, reason} ->
        IO.puts("Erro ao salvar contacts.json: #{inspect(reason)}")
        {:continue, old_contacts}
    end
  end

  defp persist({:error, message}, old_contacts, _success_message) do
    IO.puts("Erro: " <> message)
    {:continue, old_contacts}
  end

  defp print_result({:ok, value}, format), do: value |> format.() |> IO.puts()
  defp print_result({:error, message}, _format), do: IO.puts("Erro: " <> message)
end
