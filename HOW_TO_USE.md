::: {align="center"}
# HOW TO USE DUMP EXPLORER

**A quick guide to preparing your dump for AI-assisted development.**
:::

------------------------------------------------------------------------

## 1. Locate your dump

After Dump Explorer finishes, open your executor's workspace directory
and find:

``` text
INFORMATION/
└── <Game Name>/
```

The game folder contains the information collected during the dump,
including available remote data, scripts, modules, game context and
logs.

## 2. Create a ZIP archive

Compress the **game folder** inside `INFORMATION/` into a `.zip` file.
Keep its contents together so the folder structure remains intact.

```{=html}
<details>
```
```{=html}
<summary>
```
`<strong>`{=html}Windows`</strong>`{=html}
```{=html}
</summary>
```
1.  Open `INFORMATION/`.
2.  Right-click the `<Game Name>` folder.
3.  Select **Send to → Compressed (zipped) folder**.
4.  Give the archive a clear name, such as `dump_gamename.zip`.

```{=html}
</details>
```
```{=html}
<details>
```
```{=html}
<summary>
```
`<strong>`{=html}Android`</strong>`{=html}
```{=html}
</summary>
```
Using a file manager such as ZArchiver:

1.  Open the directory containing `INFORMATION/`.
2.  Long-press the `<Game Name>` folder.
3.  Choose **Compress**.
4.  Select **ZIP** and confirm.

```{=html}
</details>
```
## 3. Upload the dump to your AI

Attach the `.zip` archive to your ChatGPT, Claude or other AI chat.

Then explain what you want to build. For example:

> I'm attaching a Dump Explorer export for **\[Game Name\]**. Analyze
> the available files and use the collected game information as context.
> I want to develop a script that **\[describe your goal\]**. Before
> writing the code, identify the relevant objects, modules and remotes
> in the dump. If something is missing, tell me instead of making
> assumptions.

The AI can use the collected paths, names, module information and
captured remote-call samples as references. The amount of usable context
depends on what was collected during the dump.

## 4. Files worth mentioning

If the archive is large, point the AI to the most relevant files first:

  File                        What it contains
  --------------------------- ------------------------------------------------
  `REMOTE_MAP.txt`            Discovered remotes and their paths
  `CALL_LOG.txt`              Captured remote calls and argument samples
  `SCRIPT_TO_REMOTE.txt`      Recorded script-to-remote relationships
  `MODULE_DEPENDENCIES.txt`   Module dependency information
  `GAME_CONTEXT.txt`          Game name, PlaceId and environment information

These files are useful starting points. The AI may also need to inspect
other files depending on your task.

------------------------------------------------------------------------

## Getting better results

-   **Enable Live Hooks before running the dump.** This allows
    `CALL_LOG.txt` to collect outgoing remote calls while the game is
    running.
-   **Play the game after starting the dump.** Spend around 30--60
    seconds performing relevant actions so enabled hooks have an
    opportunity to capture activity.
-   **Wait for the dump to finish.** Large games can take several
    minutes. Collect the output after the interface indicates
    completion.
-   **Reduce the dump size when appropriate.** If you only need remote
    information and do not need script contents, enable **Skip Script
    Content** in Settings.
-   **Describe your goal clearly.** Explain what the script should do,
    what behavior you expect and any relevant constraints.

> **Important:** Dump Explorer can only provide information it
> successfully collects. Results depend on the game state, enabled
> settings and APIs supported by your executor. A dump does not
> guarantee that every remote, argument or internal system has been
> discovered.

------------------------------------------------------------------------

::: {align="center"}
**Need help or found a problem?**

[Join the Dump Explorer Discord](https://discord.gg/GGuW36hfPm)
:::
