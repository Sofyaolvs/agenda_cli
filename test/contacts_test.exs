defmodule AgendaCli.ContactsTest do
  use ExUnit.Case, async: true
  alias AgendaCli.Contacts

  @ana %{name: "Ana Lima", company: "Acme", phone: "85912345678", email: "ana.lima@acme.com"}
  @jose %{name: "José Silva", company: "Acme", phone: "11988887777", email: "jose@gmail.com"}

  defp sample do
    {:ok, list, _} = Contacts.add([], @ana, 1)
    {:ok, list, _} = Contacts.add(list, @jose, 2)
    list
  end

  test "add cria contato com id e não altera a lista original" do
    original = []
    assert {:ok, [contact], contact} = Contacts.add(original, @ana, 10)
    assert contact.id == 10
    assert original == []
  end

  test "add exige todos os campos e valida telefone/e-mail" do
    assert {:error, _} = Contacts.add([], Map.delete(@ana, :email), 1)
    assert {:error, _} = Contacts.add([], %{@ana | phone: "123"}, 1)
    assert {:error, _} = Contacts.add([], %{@ana | email: "ana.acme.com"}, 1)
  end

  test "add evita id repetido" do
    {:ok, list, _} = Contacts.add([], @ana, 5)
    {:ok, _list, second} = Contacts.add(list, @jose, 5)
    assert second.id == 6
  end

  test "delete remove pelo id" do
    assert {:ok, [%{id: 2}], %{id: 1}} = Contacts.delete(sample(), 1)
    assert {:error, _} = Contacts.delete(sample(), 99)
  end

  test "edit altera só os campos informados" do
    {:ok, list, updated} = Contacts.edit(sample(), 1, %{phone: "85900001111"})
    assert updated.phone == "85900001111"
    assert updated.name == "Ana Lima"
    assert Enum.find(list, &(&1.id == 1)) == updated
    assert {:error, _} = Contacts.edit(sample(), 1, %{})
    assert {:error, _} = Contacts.edit(sample(), 1, %{email: "invalido"})
  end

  test "search é parcial e case-insensitive" do
    assert [%{id: 1}] = Contacts.search(sample(), :name, "ANA")
    assert [%{id: 2}] = Contacts.search(sample(), :name, "josé")
    assert [%{id: 1}] = Contacts.search(sample(), :phone, "85")
    assert [%{id: 2}] = Contacts.search(sample(), :email, "GMAIL")
    assert [] = Contacts.search(sample(), :name, "maria")
  end
end
