# space_air_model

[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![iOS](https://img.shields.io/badge/iOS-18.0%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-16-147EFB?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)

用 SwiftUI 包一层 SceneKit，在 iPhone / iPad 上查看并微调仓库自带的 `space_air` 三维模型。这是一个单目标的 iOS 练习应用：没有网络请求、没有账号，也没有第三方库。

模型是一艘小型飞行器。SceneKit 归档里的节点名包括机身 `ShipBody`、机头 `ShipNose`、座舱 `Cockpit`、左右机翼 `LeftWing` / `RightWing`、左右发动机 `LeftEngine` / `RightEngine` 以及对应喷口 `LeftEngineExhaust` / `RightEngineExhaust`。

## 界面上有什么

启动后进入标题为「SCN 模型查看器」的单页：

| 区域 | 行为 |
| --- | --- |
| 模型视图 | `SCNView`，背景浅灰，开启 `allowsCameraControl`（单指旋转、双指缩放和平移）和 `autoenablesDefaultLighting` |
| 文件位置 | 分段选择「根目录」或 `art.scnassets`，传给场景加载时的子目录 |
| 垂直位置调整 | 滑块范围 `-3.0` … `3.0`，步进 `0.1`，初始值 `-1.0` |
| 相机距离 | 滑块范围 `1.0` … `5.0`，步进 `0.1`，初始值 `2.0`，表示相机距离 = 模型最大边长 × 该系数 |

加载成功时，视图会：

1. 按下面的顺序寻找 `space_air.scn`。
2. 根据全部几何体的世界坐标包围盒，把模型沿 Y 轴移到中心，再叠加「垂直位置调整」。
3. 在 `(0, 0, 距离)` 放一架看向场景根节点的相机（`SCNLookAtConstraint`）。
4. 去掉场景里已有的灯光，改加一盏方向光（强度 `1000`）和一盏环境光（强度 `500`，白色 60%）。

加载失败时显示一个红色倒角方块，以及白色文字「无法加载模型」。

查找顺序（命中即停，控制台打印 `场景加载成功：方法 N`）：

1. 主 bundle 资源名 `space_air.scn`
2. 若选了子目录，再试 `子目录/space_air.scn`
3. `art.scnassets/space_air.scn`
4. `Bundle.main.url(forResource:withExtension:)`
5. 带 `subdirectory` 的 bundle URL

## 技术栈

| 项 | 工程里的值 |
| --- | --- |
| 语言 | Swift 5.0（`SWIFT_VERSION`） |
| UI | SwiftUI（`@main` 的 `App` + `ContentView`） |
| 三维 | SceneKit / `UIViewRepresentable` 包装的 `SCNView` |
| 工程格式 | Xcode 16（`CreatedOnToolsVersion = 16.0`，`objectVersion = 77`） |
| 最低系统 | iOS 18.0（`IPHONEOS_DEPLOYMENT_TARGET`） |
| 设备 | iPhone 与 iPad（`TARGETED_DEVICE_FAMILY = 1,2`） |
| Bundle ID | `com.yiwen.space-air-model` |
| 版本 | Marketing `1.0`，Build `1` |
| 依赖 | 无。只 import 系统框架 `SwiftUI`、`SceneKit`；Frameworks 构建阶段为空 |
| 测试 | 工程只有应用 target，没有单元测试或 UI 测试 |

`Info.plist` 由构建设置生成（`GENERATE_INFOPLIST_FILE = YES`）。iPhone 支持竖屏和左右横屏；iPad 另外支持倒置竖屏。签名方式为 Automatic，工程里填写的 Development Team 是 `84F8R9TAQN`。

## 目录

```text
.
├── space_air_model.xcodeproj
│   ├── project.pbxproj          # 唯一 target：space_air_model
│   ├── project.xcworkspace
│   └── xcuserdata/              # 本机 scheme 顺序，没有提交共享 .xcscheme
└── space_air_model/             # PBXFileSystemSynchronizedRootGroup，目录内容会打进包
    ├── space_air_modelApp.swift # 应用入口，WindowGroup { ContentView() }
    ├── ContentView.swift        # 查看器、居中、相机、灯光、失败占位场景
    ├── space_air.scn            # SceneKit 归档（约 96 KB），网格数据在文件内
    ├── space_air.usdz           # 对应 USDZ（约 17 KB），内含 untitled1-3.usdc
    ├── Assets.xcassets          # AppIcon、AccentColor 只有槽位，没有图片
    └── Preview Content/         # 空的 Preview Assets
```

界面固定加载名为 `space_air`、扩展名为 `scn` 的资源。`space_air.usdz` 会随目录进包，但界面没有单独打开它的入口。

`space_air.scn` 的 `sourceURL` 仍是导出时的本机路径：

`file:///Users/yw.hao/Documents/ios/space_air_model/space_air_model/space_air.usdz`

网格（顶点、法线、UV 与材质）写在归档内部。USDZ 内的 `untitled1-3.usdc` 标明由 Blender 4.3.2 建模，再经 Apple Reality Converter 导出；材质使用 Principled BSDF，SceneKit 侧对应 `SCNLightingModelPhysicallyBased`。材质名包括 `BodyMaterial`、`GlassMaterial`、`WingMaterial`、`EngineMaterial`、`ExhaustMaterial`、`DetailMaterial`。场景里还有 `Camera`、`Sun` 和 `env_light`。

仓库中的 `art.scnassets` 选择只是加载参数。源码树里没有这个目录，模型文件放在 `space_air_model/` 根下。

## 环境要求

- macOS，并安装 **Xcode 16** 或与工程格式兼容的更新版本
- iOS **18.0+** 模拟器，或同一系统版本的 iPhone / iPad
- 不需要 CocoaPods、Swift Package Manager 或额外安装步骤

## 运行

在 Mac 上克隆后：

```bash
git clone https://github.com/Hao-yiwen/space_air_model.git
cd space_air_model
open space_air_model.xcodeproj
```

在 Xcode 中：

1. 若签名报错，打开 target **space_air_model → Signing & Capabilities**，把 Team 换成自己的 Apple 开发团队。模拟器调试通常改完即可；安装到真机还需要该团队的有效签名。
2. 目标设备选一台 **iOS 18+** 模拟器（或已连接的真机）。
3. 使用 **Product → Run**（⌘R）。

仓库没有提交 `xcshareddata/xcschemes` 下的共享 scheme，只有 `xcuserdata` 里的 scheme 顺序记录。命令行构建前，先用 Xcode 打开一次工程，让它生成 scheme；若 `xcodebuild` 提示找不到 scheme，在 **Product → Scheme → Manage Schemes…** 中勾选 Shared 后再执行：

```bash
xcodebuild \
  -project space_air_model.xcodeproj \
  -scheme space_air_model \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  build
```

模拟器名称以本机 `xcodebuild -project space_air_model.xcodeproj -scheme space_air_model -showdestinations` 的输出为准。Xcode 16 自带的运行时里常见的是 iPhone 16 系列；没有同名模拟器时，把 `name=` 换成列表中的一台 iOS 18 设备。

### 本次文档核对到哪一步

写这份说明的环境是 Linux，未安装 Xcode 和 Swift 工具链（`xcodebuild`、`swift` 均不存在），因此 **没有实际编译，也没有在模拟器里启动应用**。上面的配置、资源名、滑块范围和加载顺序来自 `project.pbxproj` 与 `ContentView.swift`；模型节点名来自 `space_air.scn` 归档和 USDZ 内的 USDC 字符串。

## 使用时会碰到的实现细节

这些都是当前源码的行为，避免和界面文案对不上：

- `VerticalCenteredModelView.updateUIView(_:context:)` 是空的。滑块和「文件位置」虽然绑了 `@State`，视图创建之后再拖动或切换，**不会**重新加载场景或改相机。第一次出现时用的是初始值：根目录、垂直偏移 `-1.0`、相机距离系数 `2.0`。
- 新建的相机加进了场景图，代码没有设置 `sceneView.pointOfView`。归档里原本还有名为 `Camera` 的相机。手势控制的是 SceneKit 当前的 point of view。
- 垂直居中会把根节点当时的子节点摘下，改 Y 坐标后挂到一个新的容器节点。加载成功后的灯光设置会删掉带 `SCNLight` 的节点，再加自己的方向光和环境光。
- 源码里没有 `#Preview`。工程打开了 `ENABLE_PREVIEWS`，但 Canvas 需要自行加预览才能用。
- `Assets.xcassets` 的 App Icon（含 dark / tinted 槽）和 Accent Color 没有填内容，图标会是系统占位。
- 没有许可证文件。

## 参考

- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [SceneKit](https://developer.apple.com/documentation/scenekit)
- [`SCNView.allowsCameraControl`](https://developer.apple.com/documentation/scenekit/scnview/1523701-allowscameracontrol)
- [`UIViewRepresentable`](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)
