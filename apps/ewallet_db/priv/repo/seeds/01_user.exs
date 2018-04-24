defmodule EWalletDB.Repo.Seeds.UserSeed do
  alias EWalletDB.Helpers.Crypto

  @argsline_desc """
  This email and password combination is required for logging into the admin panel.
  If a user with this email already exists, it will escalate the user to admin role,
  but the password will not be changed.
  """

  def seed do
    [
      run_banner: "Seeding the initial admin panel user",
      argsline: [
        {:title, "What email and password should I set for your first admin user?"},
        {:text, @argsline_desc},
        {:input, {:email, :admin_email, "E-mail", "admin@example.com"}},
        {:input, {:password, :admin_password, "Password", {Crypto, :generate_key, [16]}}},
      ],
    ]
  end

  def run(_writer, _args) do
  end
end
