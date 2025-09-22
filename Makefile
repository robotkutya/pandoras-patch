# ========================================
# Build & Install Makefile
# ========================================

# App versions
GIT_VERSION ?= 2.51.0
NVIM_VERSION ?= 0.10.3

# Docker image names
BASE_IMAGE  = base-builder:bookworm
GIT_IMAGE   = git-builder
NVIM_IMAGE  = nvim-builder

# Remote server info
REMOTE_USER ?= efs4sg
REMOTE_HOST ?= szamrend.inf.elte.hu
REMOTE_PATH ?= ~/.local

# CPUs to use for building
CPUS ?= $(shell nproc)

# Output directories
GIT_OUT   = ./git-dist/git
NVIM_OUT  = ./nvim-dist/nvim

# ------------------------
# Base image
# ------------------------
base:
	docker build --build-arg DEBIAN_FRONTEND=noninteractive \
		-f Dockerfile.base -t $(BASE_IMAGE) .

# ------------------------
# Git
# ------------------------
git: base
	@echo "=== Building Git v$(GIT_VERSION) as AppImage (extract) ==="
	docker build --build-arg GIT_VERSION=$(GIT_VERSION) \
		-f Dockerfile.git -t $(GIT_IMAGE) .
	rm -rf ./git-dist
	mkdir -p ./git-dist
	docker create --name temp-git $(GIT_IMAGE) >/dev/null
	docker cp temp-git:/git $(GIT_OUT)
	docker rm temp-git
	@echo "=== Git extracted AppImage ready in $(GIT_OUT) ==="

scp-git: git
	scp -r $(GIT_OUT) $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/

symlink-git:
	@echo "=== Uploading and running Git symlink setup script ==="
	scp setup-symlinks-git.sh $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/
	ssh $(REMOTE_USER)@$(REMOTE_HOST) "bash $(REMOTE_PATH)/setup-symlinks-git.sh"

# ------------------------
# Neovim
# ------------------------
nvim: base
	@echo "=== Downloading Neovim v$(NVIM_VERSION) AppImage (extract) ==="
	docker build --build-arg NVIM_VERSION=$(NVIM_VERSION) \
		-f Dockerfile.nvim -t $(NVIM_IMAGE) .
	rm -rf ./nvim-dist
	mkdir -p ./nvim-dist
	docker create --name temp-nvim $(NVIM_IMAGE) >/dev/null
	docker cp temp-nvim:/nvim $(NVIM_OUT)
	docker rm temp-nvim
	@echo "=== Neovim extracted AppImage ready in $(NVIM_OUT) ==="

scp-nvim: nvim
	scp -r $(NVIM_OUT) $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/

symlinks-nvim:
	@echo "=== Uploading and running Neovim symlink setup script ==="
	scp setup-symlinks-nvim.sh $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/
	ssh $(REMOTE_USER)@$(REMOTE_HOST) "bash $(REMOTE_PATH)/setup-symlinks-nvim.sh"

# ------------------------
# Reporting utilities
# ------------------------
size-report:
	@echo "=== Bundle Size Report ==="
	@if [ -d "$(GIT_OUT)" ]; then du -sh $(GIT_OUT); fi
	@if [ -d "$(NVIM_OUT)" ]; then du -sh $(NVIM_OUT); fi

# List all binaries for sanity
bin-list:
	@echo "=== Git binaries ==="
	@if [ -d "$(GIT_OUT)" ]; then find $(GIT_OUT)/usr/bin -type f; fi
	@echo "=== Neovim binaries ==="
	@if [ -d "$(NVIM_OUT)" ]; then find $(NVIM_OUT)/usr/bin -type f; fi

# ------------------------
# Cleanup
# ------------------------
clean:
	rm -rf ./git-dist ./nvim-dist

distclean: clean
	-docker rm temp-git temp-nvim >/dev/null 2>&1 || true
	-docker rmi $(BASE_IMAGE) $(GIT_IMAGE) $(NVIM_IMAGE) >/dev/null 2>&1 || true