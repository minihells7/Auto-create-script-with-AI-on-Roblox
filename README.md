<div align="center">

<img src="https://cdn.imgup.com.br/ZtF8cKHaSXAyT0hUzzW7Sn.webp" width="490" alt="Dump Explorer">

# Dump Explorer

**Explore. Analyze. Develop.**

A runtime intelligence tool for Roblox developers and AI-assisted script development.

[![Open Source](https://img.shields.io/badge/OPEN%20SOURCE-FFD43B?style=for-the-badge&logo=github&logoColor=black)](https://github.com/)
[![Roblox](https://img.shields.io/badge/ROBLOX-111111?style=for-the-badge&logo=roblox&logoColor=white)](https://www.roblox.com/)
[![AI Assisted](https://img.shields.io/badge/AI%20ASSISTED-FFD43B?style=for-the-badge&logo=openai&logoColor=black)](https://github.com/)

[Overview](#overview) · [Features](#features) · [Installation](#installation) · [Output](#output) · [Settings](#settings) · [Community](#community)

</div>

---

## Overview

Dump Explorer scans a Roblox game at runtime and organizes the collected information into structured files.

The goal is to give AI models real game context — including remotes, modules, scripts and world data — so developers can build scripts with fewer assumptions.

## Features

| Category | Included systems |
|---|---|
| **Game Exploration** | Service scanning, remote discovery, module discovery, dependency analysis, NPC and world object discovery, player state and inventory |
| **Script Analysis** | Script decompilation, automatic retries, script-to-remote mapping, dispatcher analysis, hook script generation |
| **Network Analysis** | Live hooks, incoming event capture, remote call logging, argument samples, RakNet analysis |
| **Performance** | Fast Mode, Fast Save, checkpoint and resume, crash guard, asynchronous write queue |

## How It Works

<div align="center">

| 01 · SCAN | 02 · ANALYZE | 03 · EXPORT | 04 · DEVELOP |
|:---:|:---:|:---:|:---:|
| Collect game data | Inspect available information | Generate organized files | Use the dump as AI context |

</div>

## Installation

Run Dump Explorer inside a Roblox game using a compatible executor.

```lua
loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()
```

### Quick Start

1. Execute the script.
2. Open the **Settings** tab and configure the scan.
3. Open the **Run** tab and select **Start Dump**.
4. Wait until **Dump Completed** appears.
5. Find the generated `INFORMATION/` folder in your executor workspace.
6. Compress the game folder into a `.zip` and upload it to your AI tool.

For detailed instructions, see [How to Use](./How to Use).

## Output

Collected information is saved inside `INFORMATION/`.

<details>
<summary><strong>Remote & Network</strong></summary>

| File | Description |
|---|---|
| `REMOTE_MAP.txt` | Remote paths, classes and call counts |
| `NET_REMOTES.txt` | Remotes indexed by service |
| `CALL_LOG.txt` | Captured remote calls and argument samples |
| `SCRIPT_TO_REMOTE.txt` | Script-to-remote relationships |
| `RAKNET_ANALYSIS.txt` | Network traffic analysis |
| `WORKSPACE_REMOTES.txt` | Remotes found in Workspace |

</details>

<details>
<summary><strong>Scripts & Modules</strong></summary>

| File | Description |
|---|---|
| `GAME_MODULES.txt` | Discovered ModuleScripts and paths |
| `MODULE_DEPENDENCIES.txt` | Module require dependency graph |
| `DISPATCHER_ACTIONS.txt` | Dispatcher and action patterns |
| `HOOK_SCRIPTS/` | Generated per-remote hook scripts |

</details>

<details>
<summary><strong>Game & Player</strong></summary>

| File | Description |
|---|---|
| `GAME_CONTEXT.txt` | Game, place, job and executor information |
| `ENEMIES_CATALOG.txt` | NPC and enemy models |
| `TOOLS_INVENTORY.txt` | Local player's tool inventory |
| `PLAYER_STATE.txt` | Player attributes and current state |
| `WORLD_ITEMS.txt` | Tagged and notable world objects |
| `INDEX.txt` | Master index of collected data |

</details>

<details>
<summary><strong>Logs</strong></summary>

| File | Description |
|---|---|
| `Logs/dump_log.txt` | Timestamped execution log |
| `Logs/failed.txt` | Scripts that failed to decompile |

</details>

## Settings

| Setting | Purpose |
|---|---|
| **Enable Live Hooks** | Capture outgoing remote calls |
| **Enable Incoming Hooks** | Capture incoming server-to-client events |
| **RakNet Analysis** | Analyze low-level network traffic |
| **Skip Script Content** | Skip saving script source content |
| **Skip Roblox Scripts** | Ignore Roblox internal scripts |
| **Fast Mode** | Reduce scanning yield intervals |
| **Fast Save** | Flush file writes more aggressively |
| **Soak Duration** | Set the pre-scan wait duration |
| **Max Decompile Retries** | Set the retry limit for failed decompilation |
| **UI Scale** | Adjust the interface size |

Available results depend on enabled settings, game state and executor API support.

## Compatibility

Dump Explorer checks for supported executor APIs at startup. Features that require unavailable APIs may be disabled while other systems continue to run.

**Tested executors:** Delta · Potassium 

Compatibility may vary by executor version and game behavior.

## Community

Found a bug or have a suggestion? Get in touch on Discord.

<div align="center">

[![Join our Discord](https://img.shields.io/badge/JOIN%20OUR%20DISCORD-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/GGuW36hfPm)

**Open source. Built for developers. Designed for AI-assisted development.**

</div>
