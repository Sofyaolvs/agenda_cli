defmodule AgendaCli.Contacts do
  @moduledoc """
  Funções puras de manipulação da lista de contatos.

  Nenhuma função aqui faz IO nem altera dados: todas recebem a lista atual
  e devolvem uma lista nova (ou uma tupla de erro). Isso é imutabilidade:
  a lista antiga continua existindo inalterada.

  Um contato é um mapa:

      %{id: 1713531600000, name: "Ana Lima", company: "Acme",
        phone: "85912345678", email: "ana.lima@acme.com"}
  """

  @fields [:name, :company, :phone, :email]
  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @phone_regex ~r/^\d{10,11}$/

  @type contact :: %{
          id: integer(),
          name: String.t(),
          company: String.t(),
          phone: String.t(),
          email: String.t()
        }

  @doc "Lista dos campos editáveis de um contato."
  def fields, do: @fields

  # ---------------------------------------------------------------- add

  @doc """
  Adiciona um contato novo. `attrs` precisa ter os quatro campos.

  O `id` é recebido como argumento (em vez de ser gerado aqui) para que a
  função continue pura e fácil de testar. Quem chama passa o timestamp.
  """
  @spec add([contact()], map(), integer()) :: {:ok, [contact()], contact()} | {:error, String.t()}
  def add(contacts, attrs, id) do
    with :ok <- require_all_fields(attrs),
         :ok <- validate(attrs) do
      contact =
        attrs
        |> Map.take(@fields)
        |> Map.put(:id, unique_id(contacts, id))

      {:ok, contacts ++ [contact], contact}
    end
  end

  # ---------------------------------------------------------------- delete

  @doc "Remove o contato com o `id` informado."
  @spec delete([contact()], integer()) :: {:ok, [contact()], contact()} | {:error, String.t()}
  def delete(contacts, id) do
    with {:ok, contact} <- find(contacts, id) do
      {:ok, Enum.reject(contacts, &(&1.id == id)), contact}
    end
  end

  # ---------------------------------------------------------------- find

  @doc "Busca um contato pelo `id`."
  @spec find([contact()], integer()) :: {:ok, contact()} | {:error, String.t()}
  def find(contacts, id) do
    contacts
    |> Enum.find(&(&1.id == id))
    |> found_or_error(id)
  end

  defp found_or_error(nil, id), do: {:error, "Contato #{id} não encontrado."}
  defp found_or_error(contact, _id), do: {:ok, contact}

  # ---------------------------------------------------------------- edit

  @doc """
  Altera só os campos presentes em `changes`. Os outros ficam como estavam.
  """
  @spec edit([contact()], integer(), map()) ::
          {:ok, [contact()], contact()} | {:error, String.t()}
  def edit(_contacts, _id, changes) when map_size(changes) == 0,
    do: {:error, "Informe ao menos um campo para alterar (--name, --company, --phone, --email)."}

  def edit(contacts, id, changes) do
    with {:ok, current} <- find(contacts, id),
         :ok <- validate(changes) do
      updated = Map.merge(current, Map.take(changes, @fields))
      {:ok, Enum.map(contacts, &replace_if_same_id(&1, updated)), updated}
    end
  end

  defp replace_if_same_id(%{id: id}, %{id: id} = updated), do: updated
  defp replace_if_same_id(contact, _updated), do: contact

  # ---------------------------------------------------------------- search

  @doc """
  Busca parcial (substring) e sem diferenciar maiúsculas/minúsculas
  no campo indicado.
  """
  @spec search([contact()], :name | :phone | :email, String.t()) :: [contact()]
  def search(contacts, field, term) when field in [:name, :phone, :email] do
    needle = normalize(term)

    Enum.filter(contacts, fn contact ->
      contact
      |> Map.get(field, "")
      |> normalize()
      |> String.contains?(needle)
    end)
  end

  defp normalize(nil), do: ""
  defp normalize(text), do: text |> to_string() |> String.downcase()

  # ---------------------------------------------------------------- validação

  defp require_all_fields(attrs) do
    case Enum.reject(@fields, &Map.has_key?(attrs, &1)) do
      [] -> :ok
      missing -> {:error, "Campos obrigatórios faltando: " <> format_flags(missing)}
    end
  end

  # Valida cada campo presente, parando no primeiro erro
  defp validate(attrs) do
    attrs
    |> Map.take(@fields)
    |> Enum.reduce_while(:ok, fn {field, value}, :ok ->
      case validate_field(field, value) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_field(field, value) when value in [nil, ""],
    do: {:error, "O campo --#{field} não pode ficar vazio."}

  defp validate_field(:phone, phone) do
    if Regex.match?(@phone_regex, phone),
      do: :ok,
      else: {:error, "Telefone inválido: use DDD + número, só dígitos (ex: 85912345678)."}
  end

  defp validate_field(:email, email) do
    if Regex.match?(@email_regex, email),
      do: :ok,
      else: {:error, "E-mail inválido: #{email}"}
  end

  defp validate_field(_field, _value), do: :ok

  defp format_flags(fields), do: fields |> Enum.map(&"--#{&1}") |> Enum.join(", ")

  # Timestamp em ms pode repetir se dois contatos forem criados no mesmo
  # milissegundo. Nesse caso, usamos o maior id existente + 1.
  defp unique_id(contacts, id) do
    if Enum.any?(contacts, &(&1.id == id)) do
      contacts |> Enum.map(& &1.id) |> Enum.max() |> Kernel.+(1)
    else
      id
    end
  end
end
