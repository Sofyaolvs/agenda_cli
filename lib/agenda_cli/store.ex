defmodule AgendaCli.Store do
  @moduledoc """
  Persistência da agenda em `contacts.json`, no diretório onde a aplicação
  foi executada.

  É o único módulo que toca no disco. Os outros módulos só trabalham com
  listas de mapas em memória.
  """

  @file_name "contacts.json"

  @doc """
  Lê o arquivo e devolve a lista de contatos.

  Se o arquivo ainda não existir (primeira execução), devolve `[]`.
  Se existir mas estiver corrompido, avisa e também começa com `[]`.
  """
  @spec load() :: [map()]
  def load, do: load(path())

  @doc false
  def load(file_path) do
    file_path
    |> File.read()
    |> decode()
  end

  @doc """
  Grava a lista inteira no arquivo (sobrescreve) e devolve `:ok`
  ou `{:error, motivo}`.
  """
  @spec save([map()]) :: :ok | {:error, term()}
  def save(contacts), do: save(contacts, path())

  @doc false
  def save(contacts, file_path) do
    contacts
    |> Jason.encode!(pretty: true)
    |> then(&File.write(file_path, &1))
  end

  # Caminho absoluto a partir do diretório de execução (cwd)
  defp path, do: Path.join(File.cwd!(), @file_name)

  # Cada resultado possível de File.read/1 tem sua própria cláusula
  defp decode({:error, :enoent}), do: []

  defp decode({:error, reason}) do
    IO.puts("Aviso: não foi possível ler #{@file_name} (#{inspect(reason)}). Iniciando vazia.")
    []
  end

  defp decode({:ok, ""}), do: []

  defp decode({:ok, content}) do
    case Jason.decode(content) do
      {:ok, list} when is_list(list) ->
        Enum.map(list, &to_contact/1)

      _ ->
        IO.puts("Aviso: #{@file_name} está em formato inválido. Iniciando vazia.")
        []
    end
  end

  # O JSON volta com chaves string ("name"). Convertemos explicitamente para
  # átomos conhecidos, em vez de usar `keys: :atoms`, que criaria átomos a
  # partir de qualquer texto do arquivo.
  defp to_contact(map) do
    %{
      id: map["id"],
      name: map["name"],
      company: map["company"],
      phone: map["phone"],
      email: map["email"]
    }
  end
end
