# To Run:

Environment Variables:

```
# Auth Related
TWITCH_BROADCASTER_USER_ID
TWITCH_USER_ID
TWITCH_CLIENT_ID=<your client id>

# Scope Related
TWITCH_AUTH_SCOPE=<whitespace delimited list of scopes, can be used with mix twitch.auth>
```

Should run (from mixery folder):

```
mixery/ $ mix twitch.auth --json
```

# TODO:

- [ ] broadcast a message via block in overlay
- [ ] login with twitch, associated github account

# Personal Neovim Config Rewrite

Rules:
- No copy paste (yank/put) from anywhere (old config/readmes/kickstart/etc)
  - No AI Completions
- No git/fs/undohistory/etc tricks
- I will act in good faith on each "gift"
- Goal: have a config that I want at the end

"Gifts":

- Delete: random file from config, gifter chosen file from config, entire config(?)
- Keyboard: onscreen, tablet-handwriting, one-finger-only
- Monitor: rotated, right-to-left
- Random: no-talking-only-singing, sports-commentator-mode, YT Chat on screen
- Editors: ed, emacs, libre office, chat-gpt-copy-paste, vs c*de
- Multi-Time:
  - 5 minutes:
    - Peace
    - No-going-back/First-try
      - Cannot move backwards in the file at all, must delete file to go back
    - No typing -> deletes a random line from the file
    - Flipped/substituded keys
    - input-delay
  - One Minute:
    - right-to-left: `set rightleft`
    - invisalign: Make current line invisible
    - flashlight: only current line visible
    - snake: snake mode
    - Marimba
    - hide the cursor
  - At least 1 minute:
    - Random Colorscheme
    - Random font

- One-Time:
  - solve wordle or delete file
  - Corporate mode (just talk about what we'll build, instead of building)
    - (no code for 5 minutes, only standup and agile/waterfall meetings)
  - react to a programmer article
  - do one leetcode problem in language of choice
  - Freeze the screen, but chat and i keep moving
    - chat has to pretend it's still working

I want to make a website where you can:
- send me "gifts" using your twitch points

Scopes:

user:write:chat user:bot channel:bot channel:manage:redemptions analytics:read:extensions analytics:read:games bits:read channel:read:ads channel:read:charity channel:read:goals channel:read:guest_star channel:read:hype_train channel:read:polls channel:read:predictions channel:read:redemptions channel:read:subscriptions channel:read:vips moderation:read moderator:read:automod_settings moderator:read:blocked_terms moderator:read:chat_settings moderator:read:chatters moderator:read:followers moderator:read:guest_star moderator:read:shield_mode moderator:read:shoutouts user:read:blocked_users user:read:broadcast user:read:email user:read:follows user:read:subscriptions channel:bot chat:read user:bot user:read:chat
