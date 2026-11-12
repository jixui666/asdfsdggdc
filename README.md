# sing-box iOS (SFI) — 源码 + GitHub Actions 打包 ipa

这个仓库把 sing-box 官方源码和它的 iOS 客户端源码放到一起，用 GitHub Actions 在 macOS runner 上编译出**未签名 ipa**。

## 目录结构

| 路径 | 内容 | 来源 |
| --- | --- | --- |
| `sing-box/` | sing-box 核心（Go），提供 `experimental/libbox` | https://github.com/SagerNet/sing-box (分支 `testing`) |
| `sing-box-for-apple/` | SFI / SFM / SFT 客户端（SwiftUI + Xcode 工程） | https://github.com/SagerNet/sing-box-for-apple (分支 `dev`) |
| `.github/workflows/build-ipa.yml` | 编译流水线 | 本仓库 |

> `sing-box-for-apple/Frameworks/Runestone` 是上游的 git submodule，工作流里会自动 clone
> （上游 submodule 地址：https://github.com/nekohasekai/Runestone）。

源码快照信息见 `VERSION.txt`。

## 编译流程（workflow 做的事）

1. `macos-26` runner（Xcode 26，源码用到 iOS 26 SDK 的 `.glassEffect`）。
2. `setup-go` 安装 Go 1.26.10；`bash .github/patch_go_for_ios.sh` 给 Go 运行时打 iOS arm64 CPU 特性补丁。
3. `go install github.com/sagernet/gomobile/cmd/{gomobile,gobind}@v0.1.13`。
4. clone Runestone 到 `sing-box-for-apple/Frameworks/Runestone`（Xcode 本地 SPM 依赖）。
5. `cd sing-box && go run ./cmd/internal/build_libbox -target apple -platform ios`
   → 生成 `sing-box-for-apple/Libbox.xcframework`（Go 核心里被 Swift 调用的部分）。
6. `xcodebuild build -scheme SFI -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO ...`
7. 把 `SFI.app` 塞进 `Payload/` 打 zip，改名 `.ipa`，作为 artifact 上传。

## 怎么用

1. 仓库 → **Actions** → `Build sing-box iOS IPA` → **Run workflow**（可改 Go 版本 / libbox 平台 / 版本号）。
2. 跑完在运行页面底部 **Artifacts** 下载 `sing-box-SFI-unsigned-<version>-<build>.ipa`。
3. 安装（未签名，需要自签）：
   - **Sideloadly / AltStore / SideStore**：导入 ipa，用你自己的 Apple ID 签名后安装（免费账号 7 天有效期）。
   - **TrollStore**（仅支持的系统版本）：直接安装，无需证书。

> 说明：ipa 未签名，因为 GitHub 托管 runner 上没有你的 Apple 开发者证书；
> 另外 iOS 上的 VPN 隧道依赖 NetworkExtension entitlement，个人免费开发者证书不包含该权限，
> 自签后 app 能启动，但"启用 VPN"这类功能需要付费开发者账号 + 对应 provisioning profile。

## 手动本地构建（macOS）

```bash
git clone --depth 1 -b testing https://github.com/SagerNet/sing-box.git
git clone --depth 1 -b dev     https://github.com/SagerNet/sing-box-for-apple.git
git clone --depth 1 https://github.com/nekohasekai/Runestone.git \
  sing-box-for-apple/Frameworks/Runestone

cd sing-box
make lib_install
export PATH="$PATH:$(go env GOPATH)/bin"
go run ./cmd/internal/build_libbox -target apple -platform ios

cd ../sing-box-for-apple
xcodebuild build -project sing-box.xcodeproj -scheme SFI -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/dd -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""

mkdir -p build/Payload && cp -R build/dd/Build/Products/Release-iphoneos/sing-box.app build/Payload/
cd build && zip -qry SFI-unsigned.ipa Payload
```

## 许可

`sing-box` 与 `sing-box-for-apple` 均为 GPL-3.0（见各自目录下的 LICENSE）。本仓库只是把两者放在一起用于构建。
