defmodule EWallet.Seeder.CLI do
  @moduledoc """
  Provides an interactive seeder.
  """

  defmodule Writer do
    alias EWallet.CLI

    def success(message), do: CLI.success(message)
    def warn(message), do: CLI.warn(message)
    def error(message), do: CLI.error("  #{message}")
    def print_errors(%{errors: errors}) do
      Enum.each(errors, fn({field, {message, _}}) ->
        error("  `#{field}` #{message}")
      end)
    end
  end

  alias EWallet.CLI
  alias EWallet.Seeder
  alias EWallet.EmailValidator
  alias EWalletDB.Validator

  @confirm_message """
  Please verify that the information you've entered are correct.
  Press Enter to start seeding or `Ctrl+C` twice to exit.
  """

  def run(app_name), do: run(app_name, "seeds")
  def run(app_name, seed_name) do
    mods = Seeder.gather_seeds(app_name, seed_name)

    args =
      mods
      |> Seeder.argsline_for()
      |> process_argsline()

    IO.puts("\n-----\n")
    IO.gets(@confirm_message)

    run_seeds(mods, args)
  end

  defp run_seeds([], args), do: args
  defp run_seeds([mod | t], args) do
    case Keyword.get(mod.seed, :run_banner) do
      nil -> nil
      t -> CLI.print("#{t}")
    end

    case mod.run(Writer, args) do
      n when is_list(n) -> run(t, n)
      _ -> run(t, args)
    end
  end

  #
  # Argsline processing
  #

  defp process_argsline(argsline), do: process_argsline(argsline, [])
  defp process_argsline([], acc), do: acc
  defp process_argsline([{:title, title} | t], acc) do
    CLI.print("## #{title}\n")
    process_argsline(t, acc)
  end

  defp process_argsline([{:text, text} | t], acc) do
    CLI.print(text)
    process_argsline(t, acc)
  end

  defp process_argsline([{:input, input} | t], acc) do
    case process_input(input) do
      nil -> process_argsline(t, acc)
      {_, _} = a -> process_argsline(t, acc ++ [a])
    end
  end

  defp process_argsline([_ | t], acc) do
    process_argsline(t, acc)
  end

  #
  # Input processing
  #

  defp process_input({type, name, prompt}), do: process_input({type, name, prompt, nil})
  defp process_input({:email, name, prompt, default} = input) do
    prompt_text = prompt_for(prompt, default)

    val =
      prompt_text
      |> IO.gets()
      |> String.trim()

    cond do
      byte_size(val) == 0 -> {name, process_default(default)}
      EmailValidator.validate(val) -> {name, val}
      true ->
        IO.puts("#{prompt} is invalid. Please try again.")
        process_input(input)
    end
  end

  defp process_input({:password, name, prompt, default} = input) do
    prompt_text = prompt_for(prompt, default)

    val =
      prompt_text
      |> CLI.gets_sensitive()
      |> String.trim()

    if byte_size(val) == 0 do
      {name, process_default(default)}
    else
      case Validator.validate_password(val) do
        {:ok, password} -> {name, password}
        {:error, :too_short, d} ->
          IO.puts("#{prompt} must be at least #{d[:min_length]} characters. Please try again.")
          process_input(input)
      end
    end
  end

  defp process_input(_) do
    nil
  end

  #
  # Utils
  #

  defp prompt_for(l, nil), do: "#{l}: "
  defp prompt_for(l, d) when is_binary(d), do: "#{l} (#{d}): "
  defp prompt_for(l, {_, _, _}), do: "#{l} (auto-generated): "
  defp prompt_for(l, _), do: prompt_for(l, nil)

  defp process_default({mod, func, args}), do: apply(mod, func, args)
  defp process_default(default), do: default
end
