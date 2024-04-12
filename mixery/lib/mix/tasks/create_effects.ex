defmodule Mix.Tasks.CreateEffects do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"
  use Mix.Task

  import Ecto.Query
  alias Mixery.Repo

  alias Mixery.Effect
  alias Mixery.EffectStatus

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(_args) do
    IO.puts("Creating Rewards...")

    {:ok, _} = Application.ensure_all_started(:req)

    timeout_minute = 1

    effects = [
      %Effect{
        id: "suit-up",
        cost: 5,
        title: "Put on a Suit Coat",
        prompt: "Have TJ put on a suit coat for the rest of the stream.",
        enabled_on: :always,
        max_per_stream: 1
      },
      %Effect{
        id: "marimba",
        cost: 50,
        title: "Play the Marimba",
        prompt:
          "I will play one of the two songs I can actually play right now. I will practice more later.",
        enabled_on: :always,
        max_per_stream: 1
      },
      %Effect{
        id: "wordle",
        cost: 50,
        title: "Solve today's Wordle Puzzle",
        prompt:
          "I'll solve today's wordle. If I fail, I delete a file of your choosing from my config",
        is_user_input_required: true,
        enabled_on: :always,
        max_per_stream: 1
      },
      %Effect{
        id: "leetcode",
        cost: 50,
        title: "Solve a LeetCode easy first try",
        prompt:
          "If I don't get it first try, I'll delete a file of your choosing from my config.",
        is_user_input_required: true,
        enabled_on: :always,
        max_per_stream: 1
      },
      %Effect{
        id: "switch-seat",
        cost: 5,
        title: "Make me switch to a different seat",
        prompt:
          "Choose between 'chair', 'ball', 'standing' until someone else chooses or one hour (whichever is sooner)",
        enabled_on: :always,
        cooldown: 5 * timeout_minute
      },
      %Effect{
        id: "delete-random-file",
        cost: 100,
        title: "Delete random file in nvim config",
        prompt:
          "Delete a random file in my neovim config. I cannot undo the delete or use git to retrieve it.",
        enabled_on: :rewrite,
        cooldown: 15 * timeout_minute
      },
      %Effect{
        cost: 250,
        id: "delete-chosen-file",
        title: "Pick a file to delete in neovim config",
        prompt:
          "Pick a file to delete in my neovim config. I cannot undo the delete or use git to retrieve it. NOTE: if you pick a file that doesn't exist, no refunds! :)",
        enabled_on: :rewrite,
        cooldown: 15 * timeout_minute
      },
      # Skip song
      %Effect{
        id: "pick-colorscheme",
        title: "Pick a colorscheme",
        prompt: "Must be a valid colorscheme name (no refunds).",
        is_user_input_required: true,
        enabled_on: :neovim,
        cost: 2
      },
      %Effect{
        id: "random-colorscheme",
        title: "Random colorscheme",
        prompt: "Will pick a random colorscheme.",
        enabled_on: :neovim,
        cost: 1
      },
      %Effect{
        id: "fog-of-war",
        title: "Fog of War",
        prompt: "Shines flashlight in the darkness of code.",
        enabled_on: :neovim,
        cost: 5,
        cooldown: 2 * timeout_minute
      },
      %Effect{
        id: "invisaline",
        title: "Invisialine",
        prompt: "Makes current line invisible.",
        enabled_on: :neovim,
        cost: 5
      },
      %Effect{
        cost: 5,
        id: "hide-cursor",
        title: "Hide my cursor",
        prompt: "I will be unable to see my cursor at all.",
        enabled_on: :neovim,
        cooldown: 30 * timeout_minute
      },
      %Effect{
        cost: 15,
        id: "snake",
        title: "MODE: Snake Mode",
        prompt: "Only locations I recently visited will be visible, similar to the game 'snake'",
        enabled_on: :neovim,
        cooldown: 30 * timeout_minute
      },
      # Add on-screen keyboard only
      %Effect{
        id: "on-screen-keyboard",
        title: "MODE: On Screen Keyboard",
        prompt: "I can only use the on screen keyboard to type (including vim motions).",
        enabled_on: :rewrite,
        cost: 5
      },
      # Add tablet-writing only
      %Effect{
        id: "tablet-keyboard",
        title: "MODE: Tablet Handwriting Only",
        prompt:
          "I can only use my tablet to type via handwriting-to-text (including vim motions).",
        enabled_on: :rewrite,
        cost: 5
      },
      %Effect{
        id: "delayed-keyboard",
        title: "MODE: Keyboard 3 Second Delay",
        prompt:
          "We intercept every keystroke that I send to the computer and delay it 3 seconds before executing it",
        enabled_on: :rewrite,
        cost: 15
      },
      # Editors
      %Effect{
        cost: 50,
        id: "chat-gpt-only",
        title: "EDITOR: Only can copy/paste chat gpt",
        prompt:
          "Use ChatGPT as my editor. I cannot type anything into nvim. Only allowed to copy/paste to-and-from chat gpt.",
        enabled_on: :rewrite
      },
      %Effect{
        cost: 100,
        id: "vs-c*de",
        title: "EDITOR: Use VS C*de for 15 minutes",
        prompt: "Only allowed to use default VS C*de for 15 minutes. No other editors allowed.",
        enabled_on: :rewrite,
        cooldown: 60 * timeout_minute
      },
      %Effect{
        cost: 50,
        id: "emacs",
        title: "EDITOR: Use Emacs for 15 minutes",
        prompt: "Open default Emacs for 15 minutes. No other editors allowed.",
        enabled_on: :rewrite,
        cooldown: 60 * timeout_minute
      },
      %Effect{
        cost: 50,
        id: "ed",
        title: "EDITOR: Use `ed` for 15 minutes",
        prompt: "Open the default editor (ed) for 15 minutes. No other editors allowed.",
        enabled_on: :rewrite,
        cooldown: 60 * timeout_minute
      },
      %Effect{
        cost: 50,
        id: "libre-office",
        title: "EDITOR: Use libre-office for 15 minutes",
        prompt: "Open the libre-office for 15 minutes. No other editors allowed.",
        enabled_on: :rewrite,
        cooldown: 60 * timeout_minute
      },
      %Effect{
        cost: 15,
        id: "right-to-left",
        title: "EDITOR: set rightoleft",
        prompt: "Sets the editor to 'righttoleft' mode, which makes everything backwards",
        enabled_on: :rewrite,
        cooldown: 60 * timeout_minute
      },
      %Effect{
        cost: 15,
        id: "screen-upside-down",
        title: "Rotate screen upside-down",
        prompt: "Rotates my entire monitor 180 degrees (upside-down).",
        enabled_on: :rewrite,
        cooldown: 60 * timeout_minute
      },
      #
      %Effect{
        # TODO: This is way too low
        cost: 10,
        id: "no-going-back",
        title: "No Going Back",
        prompt: "If my cursor moves backwards at all, the entire file is deleted.",
        is_user_input_required: false,
        enabled_on: :rewrite
      },
      %Effect{
        cost: 5,
        id: "random-font",
        title: "Pick a Random Font",
        prompt: "Sets a random font in my terminal",
        is_user_input_required: false,
        enabled_on: :rewrite
      },
      %Effect{
        cost: 15,
        id: "peace-mode",
        title: "Peaceful Editing",
        prompt: "Five minutes of peaceful editing for teej",
        is_user_input_required: false,
        enabled_on: :rewrite,
        cooldown: 60 * 60
      },
      # Currently only via neovim?... But could be other places I guess
      %Effect{
        cost: 50,
        id: "jumpscare",
        title: "JUMPSCARE",
        prompt: "Play something loud to scare me. And chat.",
        is_user_input_required: false,
        enabled_on: :neovim
      }
    ]

    effects
    |> Enum.each(fn effect ->
      dbg(effect)

      effect
      |> Repo.insert!(on_conflict: :replace_all, conflict_target: :id)

      if effect.enabled_on == :always,
        do: %EffectStatus{effect_id: effect.id, status: :enabled} |> Repo.insert!()
    end)
  end
end
