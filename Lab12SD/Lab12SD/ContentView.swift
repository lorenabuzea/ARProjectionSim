//
//  ContentView.swift
//  Lab12SD
//
//  Created by Lorena Buzea on 19.05.2025.
//

import SwiftUI
import RealityKit
import ARKit

enum ProjectionMode {
    case staticBox
    case animatedPulse
    case rotating
}

struct ContentView: View {
    @StateObject private var viewModel = ARViewModel()

    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                HStack {
                    Button("Scan") {
                        viewModel.scanEnvironment()
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)

                    Button("Change Mode") {
                        viewModel.changeProjectionMode()
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARViewModel

    func makeUIView(context: Context) -> ARView {
        viewModel.setupARView()
        return viewModel.arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

class ARViewModel: NSObject, ObservableObject, ARSessionDelegate {
    let arView = ARView(frame: .zero)

    private var currentMode: ProjectionMode = .staticBox
    private var mainAnchor: AnchorEntity?
    private var boxEntity: ModelEntity?

    func setupARView() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        //removed ar debug
        // arView.debugOptions.insert(.showAnchorOrigins)
        // arView.debugOptions.insert(.showSceneUnderstanding)

        arView.session.delegate = self
    }

    func scanEnvironment() {
        guard let cameraTransform = arView.session.currentFrame?.camera.transform else {
            print("[Camera] Could not get camera transform.")
            return
        }

        print("[Camera] Updating anchor position.")

        if mainAnchor == nil {
            // Create a fixed anchor at the current camera position
            let anchor = AnchorEntity(world: cameraTransform)
            
            let box = createBoxForCurrentMode()
            box.position = [0, 0, -0.3] // Slightly in front of anchor's origin

            anchor.addChild(box)
            arView.scene.addAnchor(anchor)

            mainAnchor = anchor
            boxEntity = box

            print("[Projector] Placed new box.")
        } else {
            // Keep anchor in original position, just update the box
            boxEntity?.removeFromParent()

            let box = createBoxForCurrentMode()
            box.position = [0, 0, -0.3] // Same offset from anchor

            mainAnchor?.addChild(box)
            boxEntity = box

            print("[Projector] Updated box with new mode.")
        }

    }

    func changeProjectionMode() {
        switch currentMode {
        case .staticBox:
            currentMode = .animatedPulse
        case .animatedPulse:
            currentMode = .rotating
        case .rotating:
            currentMode = .staticBox
        }

        print("[Controller] Switched to mode: \(currentMode)")

        //update current box
        if let box = boxEntity {
            box.transform = .identity
            applyModeEffect(to: box)
        }
    }

    private func createBoxForCurrentMode() -> ModelEntity {
        let box = ModelEntity(mesh: .generateBox(size: 0.05))
        applyMaterial(to: box)
        applyModeEffect(to: box)
        return box
    }

    private func applyMaterial(to box: ModelEntity) {
        let material: SimpleMaterial

        switch currentMode {
        case .staticBox:
            material = SimpleMaterial(color: .blue, isMetallic: false)
        case .animatedPulse:
            material = SimpleMaterial(color: .green, isMetallic: false)
        case .rotating:
            material = SimpleMaterial(color: .red, isMetallic: false)
        }

        box.model?.materials = [material]
    }

    private func applyModeEffect(to box: ModelEntity) {
        switch currentMode {
        case .staticBox:
            break
        case .animatedPulse:
            let scaleUp = Transform(scale: SIMD3(repeating: 10.0))
            box.move(to: scaleUp, relativeTo: box, duration: 0.6, timingFunction: .easeInOut)
        case .rotating:
            let rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            let transform = Transform(rotation: rotation)
            box.move(to: transform, relativeTo: box, duration: 3.0, timingFunction: .linear)
        }
    }
}
