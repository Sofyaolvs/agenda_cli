defmodule AgendaCli.StoreTest do
  use ExUnit.Case, async: true
  alias AgendaCli.Store

  @moduletag :tmp_dir

  test "save e load fazem o caminho de ida e volta", %{tmp_dir: dir} do
    path = Path.join(dir, "contacts.json")

    contacts = [
      %{id: 1, name: "Ana Lima", company: "Acme", phone: "85912345678", email: "ana@acme.com"}
    ]

    assert :ok = Store.save(contacts, path)
    assert Store.load(path) == contacts
  end

  test "arquivo inexistente vira lista vazia", %{tmp_dir: dir} do
    assert Store.load(Path.join(dir, "nao_existe.json")) == []
  end
end
