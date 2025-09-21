# ========================================
# Git + Neovim Builder & Installer
# ========================================

# Versions (overridable with make GIT_VERSION=... etc.)
GIT_VERSION ?= 2.51.0
NVIM_VERSION ?= 0.10.2

# Docker image names
GIT_IMAGE  = git-builder
NVIM_IMAGE = nvim-builder

# Remote server info (adjust!)
REMOTE_USER ?= efs4sg
REMOTE_HOST ?= szamrend.inf.elte.hu
REMOTE_PATH ?= ~/bin

# CPUs to use for building
CPUS ?= $(shell nproc)

# Default build: both tools
all: git nvim

# ------------------------
# Build + export Git + helpers
# ------------------------
git:
	@echo "=== Building Git v$(GIT_VERSION) with HTTPS support ==="
	docker build \
		--build-arg GIT_VERSION=$(GIT_VERSION) \
		--build-arg CPUS=$(CPUS) \
		-f Dockerfile.git -t $(GIT_IMAGE) .
	@echo "=== Exporting Git binaries/helpers into ./git-dist/ ==="
	rm -rf ./git-dist
	mkdir -p ./git-dist
	docker create --name temp-git $(GIT_IMAGE) >/dev/null
	docker cp temp-git:/ ./git-dist/
	docker rm temp-git
	@echo "=== Git binaries are in ./git-dist/usr/bin ==="

install-git: git
	@echo "=== Installing Git + helpers to $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/git ==="
	scp -r ./git-dist/usr/bin $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/git

# ------------------------
# Build and export Neovim
# ------------------------
nvim:
	@echo "=== Building Neovim v$(NVIM_VERSION) with $(CPUS) cores ==="
	docker build \
		--build-arg NVIM_VERSION=$(NVIM_VERSION) \
		--build-arg CPUS=$(CPUS) \
		-f Dockerfile.nvim -t $(NVIM_IMAGE) .
	@echo "=== Exporting Neovim into ./nvim/ ==="
	rm -rf ./nvim
	docker create --name temp-nvim $(NVIM_IMAGE) >/dev/null
	docker cp temp-nvim:/nvim ./nvim
	docker rm temp-nvim
	@echo "=== Neovim exported to ./nvim/ ==="

install-nvim: nvim
	@echo "=== Installing Neovim to $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/nvim ==="
	scp -r ./nvim $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/nvim

# ------------------------
# Install both
# ------------------------
install-all: install-git install-nvim
	@echo "=== Installed Git + Neovim to $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH) ==="

update-all: distclean install-all
	@echo "=== Updated Git v$(GIT_VERSION) + Neovim v$(NVIM_VERSION) ==="

# ------------------------
# Cleanup
# ------------------------
clean:
	rm -f ./git
	rm -rf ./git-dist
	rm -rf ./nvim

distclean: clean
	-docker rm temp-git temp-nvim >/dev/null 2>&1 || true