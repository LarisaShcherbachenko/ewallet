defmodule EWalletDB.Repo.Seeds.MembershipSeed do
  alias EWalletDB.{Account, Membership, Role, User}

  def seed do
    [
      run_banner: "Seeding the admin membership",
      argsline: [],
    ]
  end

  def run(writer, args) do
    admin_email = args[:admin_email]

    %User{} = user = User.get_by_email(admin_email)
    %Account{} = account = Account.get_master_account()
    %Role{} = role = Role.get_by_name("admin")

    case Membership.get_by_user_and_account(user, account) do
      nil ->
        case Membership.assign(user, account, role) do
        {:ok, _} ->
            writer.success("""
              Email   : #{user.email}
              Account : #{account.name}
              Role    : #{role.name}
            """)
        {:error, changeset} ->
            writer.error("  Admin Panel user #{admin_email} could not be assigned:")
            writer.print_errors(changeset)
        _ ->
            writer.error("  Admin Panel user #{admin_email} could not be assigned:")
            writer.error("  Unknown error.")
        end
      %Membership{} = membership ->
        writer.warn("""
          Email   : #{user.email}
          Account : #{account.name}
          Role    : #{role.name}
        """)
    end
  end
end
