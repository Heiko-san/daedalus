# Project Daedalus

In greek mythology, Daedalus built a labyrinth to trap the Minotaur.
This project aims to create a "labyrinth" for AI in VS Code to prevent it from
accessing sensitive environment variables and files while still allowing it to
freely manipulate non-sensitive data within the workspace.

## Options

- Utilize [systemd](systemd/) to create a sandbox for VS Code.
