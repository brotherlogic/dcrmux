# DCRMux - Implementation Milestones

This document details the measurable, testable milestones for developing `dcrmux`. Each milestone includes clear deliverable goals, specific implementation components, and concrete acceptance criteria.

---

## Milestone 1: Project Scaffolding & 3-Pane TUI Layout

### Goal
Establish the Go repository foundation, configuration structure, and responsive 3-pane Bubble Tea user interface shell.

### Deliverables
- [ ] Initialize `go.mod` for `github.com/brotherlogic/dcrmux`.
- [ ] Configuration loader (`internal/config`) supporting `~/.config/dcrmux/config.yaml` (specifying default repos, llama endpoint URL, and router settings).
- [ ] Bubble Tea root model (`internal/ui`) with a 3-pane layout:
  - Left Pane (25-30% terminal width, full height)
  - Top-Right Pane (~25% height of right column)
  - Bottom-Right Pane (~75% height of right column)
- [ ] Responsive resize handler (`tea.WindowSizeMsg`) adapting pane dimensions dynamically.
- [ ] Lip Gloss styling with distinct border styles indicating pane focus.
- [ ] Command-key handler (`Ctrl+B`) to toggle focus between the left navigation pane and the conversation pane.

### Acceptance Criteria
- Running `go run main.go` renders the three bordered panes cleanly in the terminal.
- Resizing the terminal window adjusts pane dimensions smoothly without clipping or visual corruption.
- Pressing `Ctrl+B` switches the active border highlight between the left pane and the bottom-right pane.

---

## Milestone 2: Embedded PTY Terminal & `dcr` Subprocess Execution

### Goal
Integrate a virtual pseudo-terminal (PTY) inside the bottom-right pane to run interactive shell processes and `dcr <repo> <issue>`.

### Deliverables
- [ ] PTY manager (`internal/pty`) using `creack/pty` to allocate a master/slave PTY pair.
- [ ] Bubble Tea custom message handler routing raw stdin bytes to the PTY and streaming stdout/stderr back to the UI.
- [ ] Terminal window resize propagation (`pty.Setsize`) synchronizing PTY dimensions with the pane's inner dimensions.
- [ ] Process launcher executing `dcr <repo> <issue>` (or configured shell in local dev mode).
- [ ] Key interceptor: passes all keystrokes to the child process *except* `Ctrl+B` (which breaks out to left pane navigation).
- [ ] Session termination & disconnect handler: displays an inline banner (`[r] to reconnect, [Ctrl+B] to choose another issue`) if the SSH/dcr process terminates.

### Acceptance Criteria
- Launching `dcrmux` spawns an interactive shell/dcr session inside the bottom-right pane.
- Full interactive CLI tools (e.g. `vim`, `htop`, `agy`) function with correct ANSI color and cursor rendering.
- Pressing `Ctrl+B` immediately releases keystroke capture so the user can navigate the TUI.
- Exiting the shell displays the reconnect banner without crashing the parent `dcrmux` process.

---

## Milestone 3: Issue Tree Discovery & GitHub Integration

### Goal
Query GitHub repositories, reconstruct parent-child issue trees, identify unblocked leaves, and display them in the left pane.

### Deliverables
- [ ] GitHub client (`internal/github`) authenticating via `gh auth token` or `GITHUB_TOKEN`.
- [ ] Issue tree parser (`internal/tree`):
  - Traverses root issues (`[Breakdown]`, `[Implementation Plan]`, or parent epics).
  - Extracts tasklist items (`- [ ] #123`) and native GitHub sub-issues.
  - Detects linked Pull Requests referencing the issue or matching the feature branch name.
  - Sorts leaves sequentially by issue number; marks the lowest-numbered open issue as the next unblocked leaf.
- [ ] Left pane tree view (`internal/ui/treeview`):
  - Renders hierarchical tree with state badges (`[x]` closed, `[*]` active leaf, `[ ]` blocked).
  - Displays linked PRs as child leaves.
  - Keyboard navigation (`up`/`down` or `j`/`k`).
  - Pressing `Enter` selects the highlighted issue and swaps the active session.

### Acceptance Criteria
- Running `dcrmux <owner/repo>` fetches real GitHub issues and renders the tree hierarchy in the left pane.
- Blocked vs. unblocked status is correctly computed (older issues block newer issues).
- Navigating with `j`/`k` and pressing `Enter` selects the node and refocuses input to the bottom-right conversation pane.

---

## Milestone 4: LLaMA Machine Summarization & Top-Right View

### Goal
Connect to the local LLaMA machine's OpenAI-compatible endpoint to generate crisp 2-paragraph summaries for the active issue.

### Deliverables
- [ ] LLM client (`internal/summary`) targeting `POST /v1/chat/completions` (OpenAI format).
- [ ] Configurable endpoint URL (defaulting to `http://llama:11434/v1` or config file setting).
- [ ] Prompt template instructed to produce a concise two-paragraph executive summary:
  1. High-level feature context and objective.
  2. Concrete task scope, dependencies, and acceptance criteria.
- [ ] Asynchronous request dispatching with a loading spinner in the top-right pane.
- [ ] Local in-memory caching for summaries indexed by repository and issue ID.
- [ ] Resilient fallback: immediately displays raw issue description markdown if LLaMA is offline or unreachable.

### Acceptance Criteria
- Selecting an issue in the left pane triggers an asynchronous summary request to the LLaMA endpoint.
- Top-right pane shows a spinner, followed by the rendered 2-paragraph summary upon response.
- If the LLaMA endpoint is offline, the top-right pane gracefully displays the raw issue body without stalling the UI.

---

## Milestone 5: Real-Time ghwebhook Streaming & Auto-Advance

### Goal
Integrate streaming gRPC updates from `brotherlogic/ghwebhook`, automatically updating the tree and auto-advancing when issues close.

### Deliverables
- [ ] gRPC client (`internal/webhook`) connecting to `brotherlogic/ghwebhook.v1.RegistrationService`.
- [ ] Streaming event consumer processing `IssueEvent` and `PullRequestEvent`.
- [ ] Background polling fallback (45-second interval) when webhook connection is unavailable.
- [ ] Auto-advancement engine:
  - Detects when the currently active issue transitions to `closed`.
  - Updates the left pane tree view immediately.
  - Gracefully terminates the running `dcr` session.
  - Advances automatically to the next unblocked leaf issue in the tree.
- [ ] Container provisioning wait screen:
  - Checks if the target container is in `container-creating` status.
  - Displays a clean status banner with spinner (`Waiting for container-ready on <repo>-<issue>...`).
  - Spawns `dcr` automatically once `container-ready` is detected.

### Acceptance Criteria
- Closing an issue on GitHub sends a real-time event that updates the left pane within seconds without manual refresh.
- Upon closure of the active issue, the bottom-right pane immediately tears down the old session and switches to the next unblocked leaf.
- If the next container is still building, a loading screen is displayed until the container is ready.

---

## Milestone 6: Polish, Configuration & CLI Packaging

### Goal
Finalize CLI ergonomics, configuration persistence, test coverage, and documentation for daily developer use.

### Deliverables
- [ ] CLI argument parser supporting:
  - Positional repository arguments: `dcrmux [repo...]`
  - Flags: `--config <path>`, `--dry-run`, `--version`
- [ ] Configuration manager writing/reading `~/.config/dcrmux/config.yaml`.
- [ ] Unit tests for:
  - Issue tree dependency resolution and topological leaf sorting.
  - Webhook event dispatching and fallback polling logic.
  - Summary prompt generation and caching.
- [ ] Developer documentation (`README.md`) with setup instructions and keybindings cheat sheet.
- [ ] Verify `go install github.com/brotherlogic/dcrmux/cmd/dcrmux@latest` builds cleanly.

### Acceptance Criteria
- Unit test suite passes with `go test -v ./...`.
- `dcrmux` runs seamlessly as a standalone binary from anywhere in the user's terminal.
- End-to-end user workflow matches the specification in `INTENT.md`.
