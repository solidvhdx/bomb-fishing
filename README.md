# bomb-fishing

Autofarm script for Bomb Fishing.

## what it does

- **Auto Farm** — starts a round, throws, waits for the round to actually finish (via `BombService.RE.Finished`), then repeats
- **Auto Claim Money** — collects cash from your base every 60s
- **Auto Claim Cage** — claims fish from your cage every 120s
- **Auto Equip Best** — equips your best rod after each round
- **Auto Sell Inventory** — sells inventory after each round (runs after Equip Best if both are on)
- **Auto Rebirth** — rebirths automatically when you have enough cash; never fires if conditions aren't met

There's a menu you can drag around. Press **V** to hide/show it. The **×** asks before fully closing the script.

## requirements

Any executor with `loadstring`, HTTP requests, and `hookmetamethod` support. Tested on Medium.

## note on base detection

Stand at your base the first time you turn on Auto Claim. The script figures out which plot is yours and remembers it for the rest of the session.
