# Obsidian Quick Sync

Drop-folder publishing pipeline: export a page from Obsidian → drop into this folder → auto-commits, pushes to GitHub, and Cloudflare Pages deploys it live.

## How to use

1. In Obsidian, use **Export to HTML** on the note(s) you want to publish.
2. Copy the resulting `.html` file into this folder (`D:\GitHub\obsidian-quick-sync\`).
3. That's it. The watcher picks it up, commits, pushes, and Cloudflare Pages deploys within ~30 seconds.

Your page will appear at: `https://obsidian-quick-sync.pages.dev/<filename>.html`
And will be listed on the landing page at `https://obsidian-quick-sync.pages.dev/`.

## Starting the watcher

Double-click **`start-watcher.bat`**. A PowerShell window will open and stay running — leave it open while you work. Close it to stop auto-syncing.

To have it start automatically on login, put a shortcut to `start-watcher.bat` in:
`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\`

## What gets published

- Any `.html` file dropped directly into this folder.
- Asset folders that Obsidian exports alongside the HTML (images, CSS) are also committed.

## Files in this repo

- `index.html` — auto-generated landing page listing all published pages
- `pages.json` — index of published pages (updated by the watcher)
- `watcher.ps1` — the file-watch + auto-commit script
- `start-watcher.bat` — double-click launcher for the watcher
