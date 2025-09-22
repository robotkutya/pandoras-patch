# ========================================
# Build & Install Makefile
# ========================================

# ------------------------
# Build settings
# ------------------------
BASE_DISTRO    ?= debian:bookworm-slim
BASE_IMAGE     ?= base-builder:bookworm
GIT_IMAGE      ?= git-builder
NVIM_IMAGE     ?= nvim-builder
CPUS           ?= $(shell nproc)
ARCH           ?= linux/amd64   # build platform to target

# Extra docker build flags (override on CLI, e.g. DOCKER_BUILD_FLAGS=--no-cache)
DOCKER_BUILD_FLAGS ?=

# ------------------------
# Versions
# ------------------------
NVIM_VERSION   ?= 0.10.3

# ------------------------
# Remote deployment
# ------------------------
REMOTE_USER    ?= efs4sg
REMOTE_HOST    ?= szamrend.inf.elte.hu
REMOTE_PATH    ?= ~/.local

# ------------------------
# Local output directories
# ------------------------
DISTDIR        ?= ./dist
RUNTIME_OUT    ?= $(DISTDIR)/runtime
GIT_OUT        ?= $(DISTDIR)/git
NVIM_OUT       ?= $(DISTDIR)/nvim

# ------------------------
# Temporary container names
# ------------------------
RUNTIME_CONT   ?= temp-runtime
GIT_CONT       ?= temp-git
NVIM_CONT      ?= temp-nvim

# ========================================
# Targets
# ========================================

# ------------------------
# Base
# ------------------------
base:
	docker buildx build $(DOCKER_BUILD_FLAGS) --platform $(ARCH) \
		--build-arg DEBIAN_FRONTEND=noninteractive \
		--build-arg BASE_DISTRO=$(BASE_DISTRO) \
		-f Dockerfile.base -t $(BASE_IMAGE) .

# ------------------------
# Runtime bubble
# ------------------------
build-runtime: base
	@echo "=== Extracting runtime bubble ==="
	rm -rf $(RUNTIME_OUT)
	mkdir -p $(DISTDIR)
	docker create --name $(RUNTIME_CONT) $(BASE_IMAGE) >/dev/null
	docker cp $(RUNTIME_CONT):/runtime $(RUNTIME_OUT)
	docker rm $(RUNTIME_CONT)

scp-runtime:
	scp -r $(RUNTIME_OUT) $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/

install-runtime: build-runtime scp-runtime

# ------------------------
# Git
# ------------------------
build-git: base
	@echo "=== Building Git package ==="
	rm -rf $(GIT_OUT)
	mkdir -p $(DISTDIR)
	docker buildx build $(DOCKER_BUILD_FLAGS) --platform $(ARCH) \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		-f Dockerfile.git -t $(GIT_IMAGE) .
	docker create --platform $(ARCH) --name $(GIT_CONT) $(GIT_IMAGE) >/dev/null
	docker cp $(GIT_CONT):/git $(GIT_OUT)
	docker rm $(GIT_CONT)

scp-git:
	scp -r $(GIT_OUT) $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_PATH)/

symlink-git:
	ssh $(REMOTE_USER)@$(REMOTE_HOST) "bash $(REMOTE_PATH)/git/setup-symlink-git.sh"

install-git: build-git scp-git symlink-git

# ------------------------
# Utilities
# ------------------------
clean:
	rm -rf $(DISTDIR)

distclean: clean
	-docker rm $(RUNTIME_CONT) $(GIT_CONT) $(NVIM_CONT) >/dev/null 2>&1 || true
	-docker rmi $(BASE_IMAGE) $(GIT_IMAGE) $(NVIM_IMAGE) >/dev/null 2>&1 || true