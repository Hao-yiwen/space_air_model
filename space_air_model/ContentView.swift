import SwiftUI
import SceneKit

struct VerticalCenteredModelView: UIViewRepresentable {
    var scnFile: String
    var fileExtension: String = "scn"
    var searchPath: String? = nil
    
    // 额外的控制参数
    var verticalOffset: Float = -1.0  // 调整这个值来上下移动模型
    var cameraDistance: Float = 2.0   // 调整这个值来控制相机距离
    
    func makeUIView(context: Context) -> SCNView {
        // 创建场景视图
        let sceneView = SCNView()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .lightGray
        
        // 尝试加载模型
        if let scene = loadScene() {
            // 成功加载场景
            sceneView.scene = scene
            
            // 计算模型尺寸
            let modelSize = calculateModelSize(scene)
            
            // 调整模型的垂直位置 - 这是关键步骤
            forceModelVerticalCenter(in: scene, additionalOffset: verticalOffset)
            
            // 设置相机，确保模型在视图中心
            setupCamera(for: scene, modelSize: modelSize)
            
            // 添加灯光
            setupLighting(for: scene)
        } else {
            // 加载失败，显示错误场景
            sceneView.scene = createErrorScene()
        }
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 更新不需要特别处理
    }
    
    // 尝试加载场景的多种方法
    private func loadScene() -> SCNScene? {
        var scene: SCNScene?
        
        // 尝试多种路径加载
        let loadingMethods = [
            { SCNScene(named: "\(scnFile).\(fileExtension)") },
            { searchPath != nil ? SCNScene(named: "\(searchPath!)/\(scnFile).\(fileExtension)") : nil },
            { SCNScene(named: "art.scnassets/\(scnFile).\(fileExtension)") },
            {
                guard let url = Bundle.main.url(forResource: scnFile, withExtension: fileExtension) else { return nil }
                return try? SCNScene(url: url, options: nil)
            },
            {
                guard let path = searchPath,
                      let url = Bundle.main.url(forResource: scnFile, withExtension: fileExtension, subdirectory: path) else { return nil }
                return try? SCNScene(url: url, options: nil)
            }
        ]
        
        // 尝试每种方法直到成功
        for (index, method) in loadingMethods.enumerated() {
            if let loadedScene = method() {
                print("场景加载成功：方法 \(index + 1)")
                scene = loadedScene
                break
            }
        }
        
        return scene
    }
    
    // 计算模型尺寸
    private func calculateModelSize(_ scene: SCNScene) -> SCNVector3 {
        var minBounds = SCNVector3(x: Float.greatestFiniteMagnitude, y: Float.greatestFiniteMagnitude, z: Float.greatestFiniteMagnitude)
        var maxBounds = SCNVector3(x: -Float.greatestFiniteMagnitude, y: -Float.greatestFiniteMagnitude, z: -Float.greatestFiniteMagnitude)
        var hasGeometry = false
        
        // 遍历所有节点
        scene.rootNode.enumerateChildNodes { (node, _) in
            if let geometry = node.geometry {
                hasGeometry = true
                
                // 获取边界框
                let bbox = geometry.boundingBox
                
                // 计算在世界坐标系中的边界
                let vertices = [
                    SCNVector3(bbox.min.x, bbox.min.y, bbox.min.z),
                    SCNVector3(bbox.max.x, bbox.min.y, bbox.min.z),
                    SCNVector3(bbox.min.x, bbox.max.y, bbox.min.z),
                    SCNVector3(bbox.max.x, bbox.max.y, bbox.min.z),
                    SCNVector3(bbox.min.x, bbox.min.y, bbox.max.z),
                    SCNVector3(bbox.max.x, bbox.min.y, bbox.max.z),
                    SCNVector3(bbox.min.x, bbox.max.y, bbox.max.z),
                    SCNVector3(bbox.max.x, bbox.max.y, bbox.max.z)
                ]
                
                for vertex in vertices {
                    let worldVertex = node.convertPosition(vertex, to: nil)
                    
                    minBounds.x = min(minBounds.x, worldVertex.x)
                    minBounds.y = min(minBounds.y, worldVertex.y)
                    minBounds.z = min(minBounds.z, worldVertex.z)
                    
                    maxBounds.x = max(maxBounds.x, worldVertex.x)
                    maxBounds.y = max(maxBounds.y, worldVertex.y)
                    maxBounds.z = max(maxBounds.z, worldVertex.z)
                }
            }
        }
        
        if !hasGeometry {
            return SCNVector3(1, 1, 1)
        }
        
        let size = SCNVector3(
            maxBounds.x - minBounds.x,
            maxBounds.y - minBounds.y,
            maxBounds.z - minBounds.z
        )
        
        print("模型尺寸: \(size), 范围: (\(minBounds.y) 到 \(maxBounds.y)) Y轴")
        
        return size
    }
    
    // 强制调整模型位置使其垂直居中 - 这是关键函数
    // 修改后的强制垂直居中方法：计算所有节点的 Y 轴最小值和最大值，然后计算中心
    private func forceModelVerticalCenter(in scene: SCNScene, additionalOffset: Float) {
        var minY: Float = Float.greatestFiniteMagnitude
        var maxY: Float = -Float.greatestFiniteMagnitude
        
        // 遍历所有节点，获取所有几何体的 Y 轴范围
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                let bbox = geometry.boundingBox
                let vertices = [
                    SCNVector3(bbox.min.x, bbox.min.y, bbox.min.z),
                    SCNVector3(bbox.max.x, bbox.min.y, bbox.min.z),
                    SCNVector3(bbox.min.x, bbox.max.y, bbox.min.z),
                    SCNVector3(bbox.max.x, bbox.max.y, bbox.min.z),
                    SCNVector3(bbox.min.x, bbox.min.y, bbox.max.z),
                    SCNVector3(bbox.max.x, bbox.min.y, bbox.max.z),
                    SCNVector3(bbox.min.x, bbox.max.y, bbox.max.z),
                    SCNVector3(bbox.max.x, bbox.max.y, bbox.max.z)
                ]
                for vertex in vertices {
                    let worldPosition = node.convertPosition(vertex, to: nil)
                    minY = min(minY, worldPosition.y)
                    maxY = max(maxY, worldPosition.y)
                }
            }
        }
        
        // 计算模型中心（Y 轴中点）
        let modelCenterY = (minY + maxY) / 2
        // 使模型中心移到 Y=0 的偏移量
        let calculatedOffset = -modelCenterY
        // 总偏移量 = 自动计算的偏移 + 用户的额外偏移
        let totalOffset = calculatedOffset + additionalOffset
        
        // 将所有子节点移到一个容器节点中，并应用偏移
        let containerNode = SCNNode()
        let originalChildren = scene.rootNode.childNodes
        for child in originalChildren {
            child.removeFromParentNode()
            child.position.y += totalOffset
            containerNode.addChildNode(child)
        }
        
        // 将容器节点添加回场景
        scene.rootNode.addChildNode(containerNode)
        
        print("已应用垂直居中偏移: \(totalOffset)（自动计算: \(calculatedOffset)，额外偏移: \(additionalOffset)）")
    }
    
    // 设置相机确保模型在视图中心可见
    private func setupCamera(for scene: SCNScene, modelSize: SCNVector3) {
        // 创建相机
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // 计算适当的距离
        let maxDimension = max(modelSize.x, max(modelSize.y, modelSize.z))
        let distance = maxDimension * cameraDistance
        
        // 将相机放在Z轴正方向，看向原点
        // 关键是将Y设为0，确保相机与模型中心在同一水平线上
        cameraNode.position = SCNVector3(0, 0, distance)
        
        // 添加约束确保相机始终看向原点
        let constraint = SCNLookAtConstraint(target: scene.rootNode)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        
        scene.rootNode.addChildNode(cameraNode)
        
        print("相机位置: (0, 0, \(distance))")
    }
    
    // 设置灯光
    private func setupLighting(for scene: SCNScene) {
        // 移除现有灯光
        scene.rootNode.childNodes.filter { $0.light != nil }.forEach { $0.removeFromParentNode() }
        
        // 添加主方向光
        let mainLight = SCNNode()
        mainLight.light = SCNLight()
        mainLight.light?.type = .directional
        mainLight.light?.intensity = 1000
        mainLight.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
        scene.rootNode.addChildNode(mainLight)
        
        // 添加环境光
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        ambientLight.light?.color = UIColor(white: 0.6, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
    }
    
    // 创建错误提示场景
    private func createErrorScene() -> SCNScene {
        let scene = SCNScene()
        
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
        box.firstMaterial?.diffuse.contents = UIColor.red
        
        let boxNode = SCNNode(geometry: box)
        scene.rootNode.addChildNode(boxNode)
        
        // 添加文字
        let textGeometry = SCNText(string: "无法加载模型", extrusionDepth: 0.1)
        textGeometry.font = UIFont.systemFont(ofSize: 0.3)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(-1, 1.2, 0)
        textNode.scale = SCNVector3(0.2, 0.2, 0.2)
        scene.rootNode.addChildNode(textNode)
        
        // 添加灯光
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.position = SCNVector3(0, 5, 5)
        scene.rootNode.addChildNode(light)
        
        return scene
    }
}

// 主内容视图
struct ContentView: View {
    @State private var selectedPath: String? = nil
    @State private var verticalOffset: Float = -1.0  // 初始垂直偏移值
    @State private var cameraDistance: Float = 2.0   // 初始相机距离比例
    
    var body: some View {
        VStack {
            Text("SCN 模型查看器")
                .font(.headline)
                .padding(.top)
            
            // 模型查看器
            VerticalCenteredModelView(
                scnFile: "space_air",
                searchPath: selectedPath,
                verticalOffset: verticalOffset,
                cameraDistance: cameraDistance
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // 文件位置选择
            HStack {
                Text("文件位置:")
                Picker("位置", selection: $selectedPath) {
                    Text("根目录").tag(nil as String?)
                    Text("art.scnassets").tag("art.scnassets" as String?)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // 垂直位置调整滑块
            VStack(alignment: .leading) {
                Text("垂直位置调整: \(verticalOffset, specifier: "%.1f")")
                Slider(value: $verticalOffset, in: -3...3, step: 0.1)
            }
            .padding(.horizontal)
            
            // 相机距离调整滑块
            VStack(alignment: .leading) {
                Text("相机距离: \(cameraDistance, specifier: "%.1f")")
                Slider(value: $cameraDistance, in: 1...5, step: 0.1)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
