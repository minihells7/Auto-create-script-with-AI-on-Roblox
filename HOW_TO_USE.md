# How to Use Dump Explorer

A quick guide to preparing your dump for AI-assisted development.

---

## 1. Locate your dump

After Dump Explorer finishes, open your executor's workspace directory and find the game folder:

```text
INFORMATION/
└── <Game Name>/
```

This folder contains the information collected during the dump, such as remote data, scripts, modules, game context and logs.

## 2. Create a ZIP archive

Compress the **game folder** inside `INFORMATION/` into a `.zip` archive. Keep the folder structure intact.

### Windows

1. Open `INFORMATION/`.
2. Right-click the `<Game Name>` folder.
3. Select **Send to → Compressed (zipped) folder**.
4. Rename the archive, for example: `dump_gamename.zip`.

### Android

Using a file manager such as ZArchiver:

1. Open the directory containing `INFORMATION/`.
2. Long-press the `<Game Name>` folder.
3. Select **Compress**.
4. Choose **ZIP** and confirm.

## 3. Upload the dump to your AI

Attach the `.zip` archive to your ChatGPT, Claude or other AI conversation.

Explain what you want to develop. You can use this prompt as a starting point:

> I'm attaching a Dump Explorer export for **[Game Name]**. Analyze the files and use the collected game information as context. I want to develop a script that **[describe your goal]**. Before writing the code, identify the relevant objects, modules and remotes in the dump. If information is missing, tell me instead of making assumptions.

The AI can use collected paths, names, module information and captured remote-call samples as references. The available context depends on what Dump Explorer successfully collected.

## 4. Useful files

If the archive is large, ask the AI to inspect these files first:

| File | What it contains |
|---|---|
| `REMOTE_MAP.txt` | Discovered remotes and their paths |
| `CALL_LOG.txt` | Captured remote calls and argument samples |
| `SCRIPT_TO_REMOTE.txt` | Recorded script-to-remote relationships |
| `MODULE_DEPENDENCIES.txt` | Module dependency information |
| `GAME_CONTEXT.txt` | Game name, PlaceId and environment information |

These are useful starting points. Depending on your task, the AI may also need to inspect other files.

## Tips for better results

- **Enable Live Hooks before dumping.** This allows `CALL_LOG.txt` to collect outgoing remote calls while the game is running.
- **Play the game after starting the dump.** Spend around 30–60 seconds performing relevant actions so enabled hooks have an opportunity to capture activity.
- **Wait until the dump is complete.** Large games can take several minutes. Collect the output only after the interface indicates completion.
- **Reduce the dump size when appropriate.** If you do not need script contents, enable **Skip Script Content** in Settings.
- **Describe your goal clearly.** Explain what the script should do and what behavior you expect.

> **Important:** Dump Explorer can only provide information it successfully collects. Results depend on the game state, enabled settings and APIs supported by your executor. A dump does not guarantee that every remote, argument or internal system has been discovered.

---

## Need help?

Found a bug or have a suggestion? Join the [Dump Explorer Discord](https://discord.gg/GGuW36hfPm).
