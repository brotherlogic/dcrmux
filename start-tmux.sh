#!/bin/bash

# Ensure the 'dcrmux' session exists
if ! tmux has-session -t dcrmux 2>/dev/null; then
  # Create a new session named 'dcrmux', detached
  cd /workspaces/dcrmux
  tmux new-session -d -s dcrmux
  
  # Split the window horizontally (-h)
  # The left pane will remain a terminal
  # The right pane will run 'gh dash'
  tmux split-window -h -t dcrmux "gh dash"
fi
