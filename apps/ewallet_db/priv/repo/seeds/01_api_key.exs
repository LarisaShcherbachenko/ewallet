defmodule EWalletDB.Repo.Seeds.APIKeySeed do
  alias EWalletDB.{Account, APIKey}

  def seed do
    [
      run_banner: "Seeding an Admin Panel API key",
      argsline: [],
    ]
  end

  def run(writer, args) do
    %Account{} = account = Account.get_master_account()

    data = %{
      account_id: account.id,
      owner_app: "admin_api",
    }

    case APIKey.insert(data) do
      {:ok, api_key} ->
        writer.success("""
          Account ID : #{account.id}
          API key ID : #{api_key.id}
          API key    : #{api_key.key}
        """)
      {:error, changeset} ->
        writer.error("  Admin Panel API key could not be inserted:")
        writer.print_errors(changeset)
      _ ->
        writer.error("  Admin Panel API key could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
