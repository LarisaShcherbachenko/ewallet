defmodule EWallet.Seeder do
  @moduledoc """
  Provides a base functions for handling seeds data.
  """

  def gather_seeds(app_name), do: gather_seeds(app_name, "seeds")
  def gather_seeds(app_name, seed_name) do
    app_name
    |> Application.get_env(:ecto_repos, [])
    |> Enum.flat_map(&(seeds_for(&1, seed_name)))
    |> Enum.flat_map(&mod_from/1)
  end

  def argsline_for(mods) do
    Enum.flat_map mods, fn mod ->
      Keyword.get(mod.seed, :argsline, [])
    end
  end

  defp mod_from(file) do
    for {mod, _bin} <- Code.load_file(file), do: mod
  end

  defp seeds_for(repo, seed_name) do
    seeds_path = priv_path_for(repo, seed_name)
    query = Path.join(seeds_path, "*")
    for entry <- Path.wildcard(query), do: entry
  end

  defp priv_dir(app), do: "#{:code.priv_dir(app)}"
  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split |> List.last |> Macro.underscore
    Path.join([priv_dir(app), repo_underscore, filename])
  end
end
