defmodule AgendaCliTest do
  use ExUnit.Case, async: true
  doctest AgendaCli

  describe "parse_command/1" do
    test "comandos sem argumentos" do
      assert AgendaCli.parse_command("list\n") == :list
      assert AgendaCli.parse_command("exit") == :exit
      assert AgendaCli.parse_command("   ") == :empty
    end

    test "add com nome composto" do
      assert AgendaCli.parse_command(
               "add --name Ana Lima --company Acme Ltda --phone 85912345678 --email ana@acme.com"
             ) ==
               {:add,
                %{
                  name: "Ana Lima",
                  company: "Acme Ltda",
                  phone: "85912345678",
                  email: "ana@acme.com"
                }}
    end

    test "edit com um ou mais campos" do
      assert AgendaCli.parse_command("edit 123 --phone 85912341234") ==
               {:edit, 123, %{phone: "85912341234"}}

      assert AgendaCli.parse_command("edit 123 --name Ana Silva --company Acme LTDA") ==
               {:edit, 123, %{name: "Ana Silva", company: "Acme LTDA"}}
    end

    test "del e show com id" do
      assert AgendaCli.parse_command("del 42") == {:del, 42}
      assert AgendaCli.parse_command("show 42") == {:show, 42}
    end

    test "erros de parse" do
      assert {:error, _} = AgendaCli.parse_command("show abc")
      assert {:error, _} = AgendaCli.parse_command("del")
      assert {:error, _} = AgendaCli.parse_command("voar")
      assert {:error, _} = AgendaCli.parse_command("add Ana")
      assert {:error, _} = AgendaCli.parse_command("add --idade 30")
      assert {:error, _} = AgendaCli.parse_command("add --name")
      assert {:error, _} = AgendaCli.parse_command("edit 1 --name A --name B")
    end
  end

  describe "parse_search/1" do
    test "devolve a tupla do campo" do
      assert AgendaCli.parse_search("--name ana") == {:name, "ana"}
      assert AgendaCli.parse_search("--phone 85") == {:phone, "85"}
      assert AgendaCli.parse_search("--email gmail") == {:email, "gmail"}
    end

    test "aceita só uma flag e só name/phone/email" do
      assert {:error, _} = AgendaCli.parse_search("")
      assert {:error, _} = AgendaCli.parse_search("--name ana --phone 85")
      assert {:error, _} = AgendaCli.parse_search("--company acme")
    end
  end
end
