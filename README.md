# Pandora's Patch

Patch up the holes in ELTE's `szamrend.inf.elte.hu` server – build modern versions of essential apps (like `git` and `nvim`) that can run on ELTE's **ancient Debian Stretch** box without requiring root.

The trick: bundle new builds with their own **runtime bubble** (modern glibc + other `.so` libraries from Debian Bookworm), and lightweight wrapper scripts that ensure every binary + its helpers are executed inside that bubble. This allows users with only home‑dir access to run modern tools without disturbing the system’s outdated libraries.

---

## How it works?

- All builds happen **locally** (on your laptop) in Docker, against a more modern Debian base (Bookworm).  
- From each build we extract:
  - The **application binary** (e.g. `git.real`)
  - A **wrapper script** that launches it through the bundled loader and runtime libs
  - Any **helpers** (`git-remote-https` etc.), similarly wrapped
  - Supporting data (e.g. Git's templates)
- These are packaged into a self‑contained tree under `dist/<app>/`.
- You then `scp` the tree into your ELTE home directory (`~/.local/<app>`) and run the included setup script to symlink it into `~/.local/bin/`.  
- Result: you can call `git`, `nvim`, etc. directly — and they run new versions inside their bubble, while the server’s old glibc remains untouched.

---

## Setup

### Requirements

On your **local machine**:

- Docker with buildx support (`docker buildx version`)
- Colima (or Docker Desktop) if you’re on macOS ARM
- GNU `make`

On the **ELTE server**:

- Just your `$HOME` directory. No root required.
- Ensure `~/.local/bin` exists and is in your `PATH`.

### Install

Clone this repo on your local machine:

```bash
git clone https://github.com/robotkutya/pandoras-patch.git
cd pandoras-patch
```

Build and install the runtime bubble and Git:

```bash
make install-runtime
make install-git
```

This will:
- Build the runtime under `dist/runtime`
- Copy it to the remote server into `~/.local/runtime`
- Symlink `~/.local/bin/git` → bundled wrapper

On the server you should now see:

```bash
git --version
git version 2.39.5
```

### Controlling cache

If you want to force a **fresh rebuild** ignoring the Docker cache:

```bash
make build-git DOCKER_BUILD_FLAGS=--no-cache
```

---

## Rice 🎨

With a working modern `git`, you can start improving your day‑to‑day environment on the Stretch box.

### Oh My Bash

Install [Oh My Bash](https://ohmybash.nntoan.com/) to get a nice prompt, aliases, themes, and plugin support:

```bash
git clone https://github.com/ohmybash/oh-my-bash.git ~/.oh-my-bash
cp ~/.oh-my-bash/templates/bashrc.osh-template ~/.bashrc
```

Then log out and back in. Now you can configure colors and aliases more easily.

### fzf

[`fzf`](https://github.com/junegunn/fzf) is a general‑purpose fuzzy finder, great for searching through files, history, git branches, etc.

On ELTE’s Stretch box, first build and install modern `git` via Pandora’s Patch (done). Then pull in fzf:

```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc
```

Restart your shell and you’ll get `fzf` keybindings for Ctrl‑R (history search), Ctrl‑T (file search), and fuzzy reverse‑i‑search.

---

## Maintainer workflow

- To **audit runtime deps** for all built apps, run:

  ```bash
  utils/collect-runtime.sh
  utils/diff-runtime.sh
  ```

  Then update `Dockerfile.base` to include newly required `.so` files under appropriate categories.

- Deploy new versions using the `install-*` targets.  

---

Pandora’s Patch is a survival kit: it doesn’t solve the problem that ELTE runs Stretch, but it gives you a modern toolbox anyway. Shortcuts had to be made in order to fit under our ~500M storage quota. If you run into a missing feature, please open up an issue or patch things up yourself locally.