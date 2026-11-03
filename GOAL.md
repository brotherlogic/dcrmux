# DCRMux — Goal & Guardrails

`dcrmux` is a single-window 3-pane terminal multiplexer (TUI) that unifies GitHub issue tree navigation, AI issue summaries, and interactive `dcr <repo> <issue>` devcontainer sessions so you never have to leave the terminal or track issue dependencies manually.

## 1. Layout & Core UX

```text
+--------------------------+-------------------------------------------------------+
| LEFT PANE (25-30% W)     | TOP-RIGHT PANE (~25% H): Issue Summary                |
|                          | #6 PStore Layer — 2-paragraph Llama summary           |
| brotherlogic/dcrmux      | (falls back to raw issue markdown while loading)      |
|   #1 Project Setup [x]   +-------------------------------------------------------+
| > #6 PStore Layer  [*]   | BOTTOM-RIGHT PANE (~75% H): Active dcr Session        |
|   #7 gRPC Handler  [ ]   |                                                       |
|                          | $ dcr dcrmux 6                                        |
| brotherlogic/gramophile  | (interactive SSH / agy session in embedded PTY)       |
| > #2075 Fix Sync   [*]   |                                                       |
+--------------------------+-------------------------------------------------------+
```

- **Default Focus:** Keyboard input goes straight into the **Bottom-Right PTY** (`dcr <repo> <issue>`).
- **Navigation (`Ctrl+B`):** Intercepts `Ctrl+B` to move focus to the **Left Pane** (`j`/`k` or arrows to move, `Enter` to switch the active `dcr` session and summary, `Esc` or `Ctrl+B` to return to the PTY).
- **Blocking Order:** Within an issue tree (native GitHub sub-issues or `- [ ] #123` tasklists), lower-numbered open issues block higher-numbered ones. The lowest open leaf is highlighted (`[*]`). Open PRs referencing an issue appear as child leaves.
- **Container Readiness:** If the selected issue has the `container-creating` label (managed by `devcontainer-manager`) instead of `container-ready`, the bottom-right pane shows a waiting spinner and automatically spawns `dcr <repo> <issue>` once `container-ready` appears.
- **Auto-Advance:** When the currently active issue closes on GitHub, `dcrmux` tears down the current `dcr` PTY session, updates the tree, and automatically switches to the next unblocked leaf.

## 2. Hard Guardrails (The Constitution)

- **Stack:** Go (`github.com/brotherlogic/dcrmux`), Charmbracelet (`bubbletea`, `lipgloss`, `bubbles`), and `creack/pty` for terminal emulation.
- **Real Workspace Integrations:**
  - **Session Execution:** Invoke `dcr <repo> <issue>` via `creack/pty` (reusing `dcrouter`'s existing SSH config; do not reimplement SSH jump-host routing).
  - **GitHub State:** Authenticate via `gh auth token` / `GITHUB_TOKEN`. Read issue hierarchies, PR links, and `devcontainer-manager` state labels (`container-creating`, `container-ready`, `container-failed`).
  - **Live Events:** Support `brotherlogic/ghwebhook` (`ghwebhook.v1.RegistrationService.Register` + `WebhookHandler.ReceiveWebhook` for `IssueEvent` and `PullRequestEvent`), with a background GitHub API polling fallback (every 45s) when running locally without an ingress callback address.
  - **Summaries:** Query an OpenAI-compatible `/v1/chat/completions` endpoint (configurable in `~/.config/dcrmux/config.yaml`) for a 2-paragraph summary; always render raw issue markdown immediately as a fallback if offline or in-flight.

## 3. Candidate Features to Prototype & Lock

See [`WORKFLOW.md`](./WORKFLOW.md) for the full **Liquid-to-Crystal (Feature-Locking Ratchet)** workflow (`Hack -> Lock -> Document -> Test`).

Build in Liquid mode on `main`, and lock each behavior into `specs/<feature>.md` + `tests/<feature>_test.go` once it feels right:

1. `three-pane-layout` — Responsive 3-pane Bubble Tea shell with `Ctrl+B` focus toggling.
2. `embedded-dcr-pty` — Interactive PTY running `dcr <repo> <issue>` with resize propagation and disconnect recovery (`[r]` to reconnect).
3. `issue-tree-resolution` — GitHub issue tree & PR discovery with sequential leaf-blocking logic.
4. `llama-summary-pane` — Asynchronous 2-paragraph issue summary with in-memory cache and raw markdown fallback.
5. `auto-advance-on-close` — Live update via `ghwebhook` / poller that closes the active session and advances to the next unblocked leaf (waiting on `container-ready` if needed).
