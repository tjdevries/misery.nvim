# TODOs

- Special/program/something to easily send events to my system, so we can test notifications without having to Jebait chat into subscribing.


- Notification for new sub
    - Sub sound/clip for t1, t2, t3
- Text-to-speech for sub message
    - I want to do this w/ elixir ML stuffz
    - also, add content filter (because twitch)
    - !prime this and that !teej yup nope dumb

- Raid notification (what have i been doing???!?!?)

- My twitch chat as overlay, instead of separte one
    - Youtube chat as well
    - it would be cool to make a chat client where they can make fun of each other

- Need a few more good clips, like !focused



Bunch of ways to get a new notification:
- We want to display them in overlay

If no notifications in queue, then emit a new event
Otherwise, don't emit an event (the overlay will send us something back later)












# Mixery

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

{:mix_test_watch, "~> 1.0", only: :dev, runtime: false}, if you want to run your test in a watch mode
