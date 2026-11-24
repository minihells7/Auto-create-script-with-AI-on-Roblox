::: {align="center"}
`<img src="https://cdn.imgup.com.br/mH58zUfEeB8sPUv1HUZBZs.webp" width="720" alt="Dump Explorer">`{=html}

# DUMP EXPLORER

**Explore. Analyze. Develop.**

A runtime intelligence tool built for Roblox developers and AI-assisted
script development.

`<br>`{=html}

![Open
Source](https://img.shields.io/badge/OPEN%20SOURCE-FFD43B?style=for-the-badge&logo=github&logoColor=black)
![Roblox](https://img.shields.io/badge/ROBLOX-111111?style=for-the-badge&logo=roblox&logoColor=white)
![AI
Assisted](https://img.shields.io/badge/AI%20ASSISTED-FFD43B?style=for-the-badge&logo=openai&logoColor=black)

[Overview](#overview) · [Features](#features) ·
[Installation](#installation) · [Output](#output) ·
[Community](#community)
:::

------------------------------------------------------------------------

## Overview

Dump Explorer scans Roblox games at runtime and transforms collected
information into structured files.

Its purpose is simple: **give AI models real game context to help
developers build more accurate scripts.**

Instead of relying on assumptions, AI can analyze actual game
structures, remotes, modules, scripts and runtime data.

## Features

```{=html}
<details open>
```
```{=html}
<summary>
```
`<strong>`{=html}Game Exploration`</strong>`{=html}
```{=html}
</summary>
```
-   Full service scanning
-   Remote and ModuleScript discovery
-   Module dependency analysis
-   NPC and world object discovery
-   Player state and inventory collection

```{=html}
</details>
```
```{=html}
<details>
```
```{=html}
<summary>
```
`<strong>`{=html}Script Analysis`</strong>`{=html}
```{=html}
</summary>
```
-   Script decompilation
-   Automatic retry system
-   Script-to-Remote mapping
-   Dispatcher analysis
-   Automatic hook script generation

```{=html}
</details>
```
```{=html}
<details>
```
```{=html}
<summary>
```
`<strong>`{=html}Network Analysis`</strong>`{=html}
```{=html}
</summary>
```
-   Live outgoing hooks
-   Incoming event capture
-   Remote call logging
-   Argument inspection
-   RakNet analysis

```{=html}
</details>
```
```{=html}
<details>
```
```{=html}
<summary>
```
`<strong>`{=html}Performance & Reliability`</strong>`{=html}
```{=html}
</summary>
```
-   Fast Mode
-   Fast Save
-   Checkpoint and Resume
-   Crash Guard
-   Asynchronous write queue

```{=html}
</details>
```

------------------------------------------------------------------------

## How It Works

::: {align="center"}
**01 --- SCAN**

Collect game structures and runtime information.

↓

**02 --- ANALYZE**

Inspect scripts, modules, remotes and network activity.

↓

**03 --- EXPORT**

Organize everything into structured files.

↓

**04 --- DEVELOP**

Give the generated dump to an AI model and start developing.
:::

------------------------------------------------------------------------

## Installation

Execute Dump Explorer inside a Roblox game using a compatible executor.

``` lua
loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()
```

### Quick Start

1.  Execute the script.
2.  Open the **Settings** tab.
3.  Configure your scan options.
4.  Open **Run** and press `Start Dump`.
5.  Wait until `Dump Completed` appears.
6.  Find the generated `INFORMATION/` folder.

Compress the generated game folder into a `.zip` and upload it to your
AI tool.

For detailed instructions, check [USAGE.md](./USAGE.md).

------------------------------------------------------------------------

## Output

All collected information is organized inside `INFORMATION/`.

```{=html}
<details open>
```
```{=html}
<summary>
```
`<strong>`{=html}Remote & Network`</strong>`{=html}
```{=html}
</summary>
```
  File                     Description
  ------------------------ ------------------------------
  `REMOTE_MAP.txt`         Remote paths and call counts
  `NET_REMOTES.txt`        Remote index by service
  `CALL_LOG.txt`           Captured remote calls
  `SCRIPT_TO_REMOTE.txt`   Script relationships
  `RAKNET_ANALYSIS.txt`    Network analysis

```{=html}
</details>
```
```{=html}
<details>
```
```{=html}
<summary>
```
`<strong>`{=html}Scripts & Modules`</strong>`{=html}
```{=html}
</summary>
```
  File                        Description
  --------------------------- -------------------------
  `GAME_MODULES.txt`          Discovered modules
  `MODULE_DEPENDENCIES.txt`   Module dependency graph
  `DISPATCHER_ACTIONS.txt`    Dispatcher patterns
  `HOOK_SCRIPTS/`             Generated hook scripts

```{=html}
</details>
```
```{=html}
<details>
```
```{=html}
<summary>
```
`<strong>`{=html}Game & Player`</strong>`{=html}
```{=html}
</summary>
```
  File                    Description
  ----------------------- -------------------------------
  `GAME_CONTEXT.txt`      Game and executor information
  `ENEMIES_CATALOG.txt`   NPC and enemy catalog
  `TOOLS_INVENTORY.txt`   Player tool inventory
  `PLAYER_STATE.txt`      Player state and attributes
  `WORLD_ITEMS.txt`       World object information
  `INDEX.txt`             Master dump index

```{=html}
</details>
```
```{=html}
<details>
```
```{=html}
<summary>
```
`<strong>`{=html}Logs`</strong>`{=html}
```{=html}
</summary>
```
  File                  Description
  --------------------- -------------------------------
  `Logs/dump_log.txt`   Execution history
  `Logs/failed.txt`     Failed decompilation attempts

```{=html}
</details>
```

------------------------------------------------------------------------

## Configuration

Customize how Dump Explorer collects and processes information.

  Setting                 Purpose
  ----------------------- ---------------------------------
  Live Hooks              Capture outgoing remote calls
  Incoming Hooks          Capture incoming events
  RakNet Analysis         Analyze network activity
  Skip Script Content     Skip script source collection
  Skip Roblox Scripts     Ignore internal Roblox scripts
  Fast Mode               Reduce scanning delays
  Fast Save               Accelerate file writing
  Soak Duration           Configure pre-scan waiting time
  Max Decompile Retries   Configure retry attempts
  UI Scale                Adjust interface size

Feature availability depends on executor APIs and game behavior.

------------------------------------------------------------------------

## Compatibility

Dump Explorer uses executor APIs for scanning, hooking, decompilation
and file operations.

Some features may be unavailable depending on the executor.

**Tested executors:** - Delta - Synapse X - Fluxus - Wave

------------------------------------------------------------------------

## Community

::: {align="center"}
### Found a bug? Have an idea?

Help improve Dump Explorer.

[**JOIN OUR DISCORD**](https://discord.gg/GGuW36hfPm)

------------------------------------------------------------------------

**OPEN SOURCE PROJECT**

Built for developers. Designed for AI-assisted development.
:::
