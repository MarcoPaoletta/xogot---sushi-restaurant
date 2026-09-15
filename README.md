# Sushi Restaurant

A counter-service sushi restaurant sim built in **Xogot for Mac** (a native Godot 4.7 editor) by **Claude Fable 5.1**, driven from the Claude desktop app through Xogot's `xo` command line tool. Five days, a rotating menu of seven dishes, a panda chef who walks the corridor between the customer counter and the back counter, and rabbit customers with a patience ring over their heads.

It started from an empty project, two free asset packs and one design document. Every scene in the game was created and edited inside the Xogot editor by the agent (scene, node, material, particle and UI commands through `xo`), not hand-written as `.tscn` text.

Built for the Letta Corporation video *Claude Fable 5.1 is INCREDIBLE At Making Godot Games on Mac with Xogot*.

## Running it

1. Install [Xogot for Mac](https://xogot.com/mac) (free while it is in beta) or Godot 4.7.
2. Open `project.godot`.
3. Press play. On a keyboard, A and D (or the arrow keys) move the chef along the counter, E or Space grabs, mixes and serves, R toggles the recipe book and Esc pauses. On an iPad the same actions are on-screen touch controls. All five days are unlocked by default so you can jump to any of them (`Game.ALL_DAYS_UNLOCKED`).

## The game design document

The full spec lives in [`docs/GDD.md`](docs/GDD.md) (also as [`docs/GDD.pdf`](docs/GDD.pdf)). It is written for an implementing agent, not for a human reader, and that changes what goes in it.

### How the GDD was created

1. **Start from what exists, not from a blank page.** The project began as an empty Xogot project plus the two Quaternius packs already imported. The GDD was written with **Claude Opus** in the Claude desktop app, back and forth: pitch the idea, discuss the mechanics, cut what does not fit, repeat. Before writing, the model went through the two packs so that every 3D object named in the document is a real file. `Environment_Counter_Straight` in the GDD means `res://assets/Sushi Restaurant Kit - May 2023/Environment/glTF/Environment_Counter_Straight.gltf` in the project. An agent can build from that; it cannot build from "a counter".

2. **Specify behaviour, never code.** The GDD says what happens, with numbers: the customer walks in over 2.0 s, the plate glows green for 0.3 s when the ingredients match a dish, the dish flies to the customer in a 0.35 s arc. It contains no GDScript. The agent that builds has the whole project in front of it and writes better code than a spec can paste in.

3. **Every pillar and every non-trivial mechanic carries an acceptance test.** "Hand the iPad to someone who has never seen the game; if they serve their first correct dish within 40 seconds of Day 1 starting, the pillar holds." A test the agent can run is the difference between an agent that declares something finished and one that cannot.

4. **Scope is written down, including what is out.** Section 12 has an explicit cut list (no drinks, no table service, no upgrades, no localisation) and a numbered build order where each step ends with a run in Xogot, a screenshot check and a commit. Section 13 lists every asset the design needs that the packs do not contain, and what to do instead (audio synthesised by a script, icons drawn in code, the egg borrowed from the food pack).

5. **The document is versioned after each round of play, it is never rewritten.** The first build was one prompt: *create the game, follow @GDD.md* (Fable 5.1, medium effort). After playing that build, the changes were written as a new section that supersedes the earlier ones, and the agent was pointed at the new section:
   - **1.0** the pre-build specification (sections 0 to 13).
   - **1.1** implementation notes: where the shipped build deviated from 1.0 and why (section 14).
   - **2.0** the chef moves: stations to the back counter, the panda becomes the player's avatar (section 15).
   - **3.0** readability pass after the first playtest: no grab prompts, recipes shown as models, the recipe book (section 16).
   - **3.1** desktop fullscreen and 16:10 framing for the Mac build.
   - **4.0** a restaurant that grows over the week, more ingredients and dishes (section 17).
   - **5.0** UI pass, depth instead of width, seven dishes a day (section 18).

   So the GDD in this repo is the real history of the build, not a cleaned-up summary written afterwards.

6. **Iterate with screenshots, not descriptions.** Most rounds after V1 were a screenshot of what looked wrong ("this fish clips through the wall", "the sink does nothing, remove it") plus one sentence. The agent could also take its own screenshots and run the game through `xo`, so it checked its own work before reporting back.

The commit history of this repo follows the build order in section 12.2 one step per commit, so `git log` reads as the build diary.

## Layout

| Path | What it is |
|---|---|
| `docs/GDD.md`, `docs/GDD.pdf` | the game design document, all versions in one file |
| `scenes/` | every scene, created in the Xogot editor (`actors/`, `dishes/`, `ui/`, `fx/`) |
| `scripts/` | GDScript, one script per scene plus the `autoload/` singletons (`Game`, `Audio`, `TouchInput`) |
| `assets/Sushi Restaurant Kit - May 2023/` | Quaternius pack, untouched |
| `assets/Ultimate Food Pack - Oct 2019/` | Quaternius pack, untouched |
| `assets/audio/` | 18 SFX and 3 music loops, all synthesised by `tools/gen_audio.py` |
| `assets/fonts/` | Lilita One (OFL) |
| `assets/shaders/` | the patience ring and the full-screen fade, vignette and flash |
| `.claude/skills/xogot/` | the `xo` skill Xogot installs for external agents |

## License

The project is released under the **MIT License** (see [`LICENSE`](LICENSE)). The `assets/` folder includes third-party content that ships under its own licenses: the two Quaternius packs are **CC0 1.0** and the Lilita One font is **SIL OFL 1.1**. Each keeps its license file inside its folder, and the note at the end of `LICENSE` lists them.

## Credits

- 3D art: [Sushi Restaurant Kit](https://quaternius.com/packs/sushirestaurantkit.html) and [Ultimate Food Pack](https://quaternius.com/packs/ultimatefood.html) by Quaternius (CC0).
- Editor: [Xogot for Mac](https://xogot.com/mac).
- Build: Claude Fable 5.1 through the Claude desktop app; design document with Claude Opus.
- Produced by [Letta Corporation](https://lettacorporation.com).
