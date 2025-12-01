### 17.5.2. 实战：构建并推送到 Docker Hub

我们将创建一个 Workflow，它会在 Release 发布时构建生产镜像，也会在 Push 到 Main 时构建开发镜像。

**文件路径**：`.github/workflows/docker-publish.yml`

**顶层面包（Before）：事件监听配置**
首先定义触发器。我们监听两个事件：`push` 到 main 分支（开发镜像）和 `push` 新的 tag（生产镜像）。注意，如果使用 Release Please，建议监听 `push: tags` 而不是 `release` 事件，原因与 NPM 发布相同：Release Please 使用 `GITHUB_TOKEN` 创建的事件可能不会触发其他 workflow。

```yaml
name: Build and Push Docker Image

on:
  push:
    branches:
      - main
    tags:
      - 'v*'  # 监听以 v 开头的 tag（如 v1.0.0, v1.0.1）

jobs:
  push_to_registry:
    name: Push Docker image to Docker Hub
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
```

**步骤一：元数据生成**
这是 Docker 构建中最"魔法"的一步。我们需要告诉 `metadata-action` 如何根据触发事件生成标签。注意 `images` 字段必须是完整的 Docker Hub 仓库路径（包含用户名），格式为 `username/repository-name`。

```yaml
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Docker Meta
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: my-username/my-app
          # 标签规则配置：
          tags: |
            # 规则1：如果是 tag 事件 (v1.2.3)，生成 v1.2.3 和 latest
            type=semver,pattern={{version}}
            # 规则2：如果是 push 事件，生成 branch-name (main)
            type=ref,event=branch
            # 规则3：始终生成短 SHA (sha-xxxxxx)
            type=sha
```

**步骤二：登录与构建环境准备**
为了构建多架构镜像（同时支持 Intel 和 Apple Silicon 芯片），我们需要启用 QEMU 和 Buildx。如果只需要构建单一架构（如 linux/amd64），可以省略 QEMU 步骤，但 Buildx 仍然是必需的（Docker 官方推荐使用 Buildx 而不是传统的 `docker build`）。

登录 Docker Hub 时，**企业级场景必须使用 Access Token 而不是账户密码**。Token 提供了更好的安全性和可管理性，可以设置权限范围和过期时间，并且可以随时撤销而不影响主账户。在 Docker Hub 的 Account Settings → Security 中生成 Access Token，将 Token 存入 GitHub Secrets 作为 `DOCKER_TOKEN`。

```yaml
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
```

**步骤三：构建与推送**
最后，我们调用 `build-push-action`。注意这里我们直接引用了步骤一生成的标签和注释。`context` 参数指定构建上下文路径，通常是 `.`（项目根目录），但如果 Dockerfile 在子目录中，需要相应调整。

```yaml
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile  # 如果 Dockerfile 不在根目录，需要指定路径
          push: true
          # 引用 meta 步骤生成的 tags 和 labels
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          # 开启多架构构建（可选）
          platforms: linux/amd64,linux/arm64
          # 利用 GitHub Actions 缓存加速构建
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**底层面包（After）：执行逻辑解析和常见坑点**

当这个 Workflow 运行完毕后，你的 Docker Hub 仓库中会出现同一个镜像的多个标签。如果是 `v1.0.0` 的 Release 触发的，你会看到 `v1.0.0`, `1.0.0`, `latest`, `sha-7f8a9d0` 四个标签指向同一个镜像 ID。运维人员可以放心地在 Kubernetes 中使用 `my-app:v1.0.0` 进行部署，而开发者可以使用 `my-app:sha-7f8a9d0` 调试特定代码。

**常见坑点总结**：

第一个坑是触发机制的选择。如果使用 Release Please，直接监听 `release: types: [published]` 可能不会触发，原因与 NPM 发布相同。最佳实践是监听 `push: tags`，当 Release Please 创建 tag 时自动触发构建。如果需要在 Release PR 合并时立即构建，也可以将 Docker 构建作为 Release Please workflow 的一部分，使用 job outputs 和条件判断。

第二个坑是 Dockerfile 路径问题。如果 Dockerfile 不在项目根目录，必须在 `build-push-action` 中指定 `file` 参数。例如，如果 Dockerfile 在 `docker/Dockerfile`，需要设置 `file: ./docker/Dockerfile`，同时 `context` 仍然应该是 `.`（项目根目录），这样构建上下文才能包含所有需要的文件。

第三个坑是多架构构建的性能问题。构建多架构镜像（如 `linux/amd64,linux/arm64`）会显著增加构建时间，因为需要为每个架构分别构建。如果项目暂时不需要支持 ARM 架构，可以先只构建 `linux/amd64`，后续再扩展。另外，QEMU 模拟 ARM 架构构建可能比原生构建慢 3-5 倍，这是正常现象。

第四个坑是缓存配置的误解。`cache-from: type=gha` 和 `cache-to: type=gha,mode=max` 使用的是 GitHub Actions 缓存，而不是 Docker 层缓存。虽然可以加速构建，但首次构建或缓存失效时仍然需要完整构建。对于大型项目，建议在 Dockerfile 中合理使用多阶段构建和层缓存策略，将变化频率低的依赖安装步骤放在前面。

第五个坑是镜像名称格式错误。`docker/metadata-action` 的 `images` 字段必须是完整的 Docker Hub 仓库路径，格式为 `username/repository-name`。如果只写 `my-app`，会导致推送失败。另外，确保 Docker Hub 用户名和仓库名都是小写，Docker Hub 不允许大写字母。

第六个坑是认证方式的选择。**企业级场景必须使用 Access Token 而不是个人账户密码**。原因有三：第一，企业通常使用组织账户或服务账户，而不是个人账户；第二，Token 可以设置权限范围和过期时间，安全性更高；第三，Token 可以随时撤销，即使泄露也不会影响主账户。配置方法：在 Docker Hub 的 Account Settings → Security 中生成 Access Token，将 Token 存入 GitHub Secrets 作为 `DOCKER_TOKEN`，用户名作为 `DOCKER_USERNAME`（通常是组织账户名）。在 workflow 中使用 `password: ${{ secrets.DOCKER_TOKEN }}` 而不是 `DOCKER_PASSWORD`。

---

## 17.6. 本章小结

至此，我们已经打通了从“代码合并”到“制品交付”的完整 CD 链路。现在，你的项目已经具备了互联网大厂级别的自动化交付能力。

让我们回顾一下本章构建的 **“自动化发布列车”** 的全貌：

**第一节车厢：环境治理**
我们建立了 **Dev / Staging / Prod** 的物理隔离，并通过 GitHub Environments 的 **Required Reviewers** 机制，给生产环境加装了“人工确认”的刹车片，防止了误操作导致的灾难。

**第二节车厢：密钥安全**
我们确立了 **零信任** 的密钥管理原则，利用 **Environment Secrets** 实现了不同环境的凭证隔离，并了解了如何防御 Fork 仓库的恶意攻击。

**第三节车厢：版本调度**
我们引入了 **Release Please** 机器人，它基于 **Conventional Commits** 自动推导版本号、维护 Changelog，让版本管理从“手工作坊”升级为“智能调度”。

**第四节车厢：制品交付**
无论是 **NPM 包** 还是 **Docker 镜像**，我们都实现了基于语义化版本的自动构建与推送。特别是 **不可变标签策略** 的应用，为后续的部署回滚提供了坚实的工程基础。

**CD 流水线成熟度自检**

最后，请对照以下清单，检查你的项目是否达到了本章的标准：

*   [ ] 生产环境部署必须经过至少一人的审批，不能完全自动。
*   [ ] 代码库中搜索不到任何以 `sk-` 或 `pwd` 开头的明文密钥。
*   [ ] 版本号（Version）和变更日志（Changelog）不再由人工手动修改。
*   [ ] 生产环境使用的 Docker 镜像标签是具体的版本号（如 `v1.2.0`），而不是 `latest`。

下一章，我们将进入更为宏大的 **企业级架构与效能治理** 领域，探讨如何在 Monorepo（单体仓库）中实现增量构建，以及如何利用 OIDC 协议进一步提升安全性