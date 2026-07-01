# bomb-fishing

Small autofarm script for Bomb Fishing. Loads from GitHub so you don't have to paste the whole thing every time.

## load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/solidvhdx/bomb-fishing/main/main.lua"))()
```

If your executor chokes on `HttpGet`, try `HttpGetAsync` instead.

## what it does

- **Auto Farm** — starts a round, waits 0.5s, throws at full power, repeats every 12s
- **Auto Claim** — collects cash from your base every 60s

There's a menu you can drag around. Press **V** to hide/show it. The **×** in the corner asks before it fully closes the script.

## auto claim note

Stand at your base the first time you turn on Auto Claim. The script needs to figure out which plot is yours — after that it remembers it and keeps claiming even when you're out fishing.

## requirements

Any executor with `loadstring` and HTTP requests. Tested on Medium.

## updates

Push to `main` on this repo and the loadstring line above always pulls the latest version. No need to redistribute a file.
