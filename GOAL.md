# DCRMux — Goal & Guardrails

`dcrmux` is a client-server 3-pane terminal multiplexer (similar to Rex) that unifies GitHub issue tree navigation, AI issue summaries, and interactive `dcr <repo> <issue>` devcontainer sessions so you never have to leave the terminal or track issue dependencies manually. A persistent server runs inside the network—receiving real-time GitHub updates and pre-caching issue trees and Ollama summaries in the background—so everything is warm and ready as soon as a client attaches.

## 1. Layout & Core UX

```text
+--------------------------+-------------------------------------------------------+
| LEFT PANE (25-30% W)     | TOP-RIGHT PANE (~25% H): Issue Summary                |
|                          | #6 PStore Layer — 2-paragraph Ollama summary          |
| brotherlogic/dcrmux      | (pre-cached on server; falls back to raw markdown)    |
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

- **Architecture:** Rex-style client-server application. A persistent `dcrmux` server runs inside the local network (maintaining state, subscriptions, and pre-computed caches), and a client attaches to it (exact server placement and attach transport deferred to MVP prototyping).
- **Stack:** Go (`github.com/brotherlogic/dcrmux`), Charmbracelet (`bubbletea`, `lipgloss`, `bubbles`), and `creack/pty` for terminal emulation.
- **Real Workspace Integrations:**
  - **Session Execution:** Invoke `dcr <repo> <issue>` (reusing `dcrouter` / devcontainer SSH routing rather than reimplementing SSH jump-host logic).
  - **GitHub State:** Authenticate via `gh auth token` / `GITHUB_TOKEN`. Read issue hierarchies, PR links, and `devcontainer-manager` state (`container-creating`, `container-ready`, `container-failed`).
  - **Live Events & Pre-Caching:** Because the server runs persistently inside the network, register directly with `brotherlogic/ghwebhook` (`ghwebhook.v1.RegistrationService.Register` + `WebhookHandler.ReceiveWebhook` for `IssueEvent` and `PullRequestEvent`) to pre-cache issue tree updates in real time, with background GitHub API polling as a fallback.
  - **Summaries:** Use a local Ollama instance on the network to pre-generate and cache 2-paragraph issue summaries in the background so they are immediately ready on attach or issue switch; render raw issue markdown as a fallback if offline or still generating.

## 3. Candidate Features to Prototype & Lock

See [`WORKFLOW.md`](./WORKFLOW.md) for the full **Liquid-to-Crystal (Feature-Locking Ratchet)** workflow (`Hack -> Lock -> Document -> Test`).

Build in Liquid mode on `main`, and lock each behavior into `specs/<feature>.md` + `tests/<feature>_test.go` once it feels right:

1. `client-server-attach` — Persistent in-network `dcrmux` server and client attach loop.
2. `three-pane-layout` — Responsive 3-pane TUI shell with focus toggling.
3. `embedded-dcr-pty` — Interactive session running `dcr <repo> <issue>` with resize propagation and disconnect recovery (`[r]` to reconnect).
4. `issue-tree-resolution` — GitHub issue tree & PR discovery with sequential leaf-blocking logic.
5. `ollama-summary-pane` — Background pre-cached 2-paragraph issue summaries via local Ollama with raw markdown fallback.
6. `auto-advance-on-close` — Live update via `ghwebhook` / poller that closes the active session and advances to the next unblocked leaf (waiting on `container-ready` if needed).
