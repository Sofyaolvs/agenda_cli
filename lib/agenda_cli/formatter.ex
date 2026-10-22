defmodule AgendaCli.Formatter do
  @moduledoc """
  Transforma contatos em texto para exibir no terminal.

  As funções só montam e devolvem strings. Quem imprime é o `AgendaCli`.
  """

  @doc "Bloco com todos os dados de um contato (comando `show`)."
  def contact(c) do
    """
    ID:       #{c.id}
    Nome:     #{c.name}
    Empresa:  #{c.company}
    Telefone: #{c.phone}
    E-mail:   #{c.email}\
    """
  end

  @doc "Tabela com uma linha por contato (comandos `list` e `search`)."
  def table([]), do: "Nenhum contato encontrado."

  def table(contacts) do
    header = row(["ID", "NOME", "EMPRESA", "TELEFONE", "E-MAIL"])
    lines = Enum.map(contacts, &row([&1.id, &1.name, &1.company, &1.phone, &1.email]))

    [header | lines]
    |> Enum.join("\n")
    |> Kernel.<>("\n(#{length(contacts)} contato(s))")
  end

  # Larguras fixas de cada coluna
  @widths [15, 22, 16, 13, 0]

  defp row(values) do
    values
    |> Enum.zip(@widths)
    |> Enum.map(fn {value, width} -> value |> to_string() |> String.pad_trailing(width) end)
    |> Enum.join(" ")
    |> String.trim_trailing()
  end
end
