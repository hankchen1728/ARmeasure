import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNSceneRendererDelegate {
    
    var sceneView: ARSCNView!
    var spheres = [SCNNode]()
    let resetButton = UIButton()
    var lineColor = UIColor.white
    var ScreenCenter: CGPoint!
    var currentLine = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView = ARSCNView(frame: self.view.frame)
        self.ScreenCenter = self.sceneView.center
        self.view.addSubview(self.sceneView)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene()
        
        //create a button
        self.resetButton.frame = CGRect(x: self.view.frame.size.width - 60, y: 60, width: 50, height: 50)
        self.resetButton.backgroundColor = UIColor.red
        self.resetButton.setTitle("Reset", for: .normal)
        self.resetButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(self.resetButton)
        
        addCrossSign()
        registerGestureRecognizers()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    //function to delete all sphere and line when touching button
    @objc func buttonAction(sender: UIButton!) {
        let allNode = self.sceneView.scene.rootNode.childNodes
        for node in allNode{
            node.removeFromParentNode()
        }
        spheres = [SCNNode]()
        sender.isHidden = true
        print("reset button tapped")
    }
    private func registerGestureRecognizers() {
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(longPress)
    }
    
    //function to control action when pressing screen
    @objc func tapped(recognizer :UILongPressGestureRecognizer) {
        resetButton.isHidden = false
        let sceneView = recognizer.view as! ARSCNView
        
        //delete all sphere and line when num of point equals to or more than 2
        if spheres.count >= 2{
            let allNode = self.sceneView.scene.rootNode.childNodes
            for node in allNode{
                node.removeFromParentNode()
            }
            spheres = [SCNNode]()
            self.resetButton.isHidden = true
        }
        switch recognizer.state {
            case UIGestureRecognizerState.began:
                let hitTestResults = sceneView.hitTest(self.ScreenCenter, types: .featurePoint)
                
                if !hitTestResults.isEmpty {
                    
                    guard let hitTestResult = hitTestResults.first else {
                        return
                    }
                    
                    addPoint(hitTestResult: hitTestResult)
                }
            case UIGestureRecognizerState.ended:
                let hitTestResults = sceneView.hitTest(self.ScreenCenter, types: .featurePoint)
                
                if !hitTestResults.isEmpty {
                    
                    guard let hitTestResult = hitTestResults.first else {
                        return
                    }
                    
                    addPoint(hitTestResult: hitTestResult)
                    
                    if self.spheres.count == 2 {
                        
                        let firstPoint = self.spheres.first!
                        let secondPoint = self.spheres.last!
                        
                        let position = SCNVector3Make(secondPoint.position.x - firstPoint.position.x, secondPoint.position.y - firstPoint.position.y, secondPoint.position.z - firstPoint.position.z)
                        
                        let result = sqrt(position.x*position.x + position.y*position.y + position.z*position.z)
                        
                        let centerPoint = SCNVector3((firstPoint.position.x+secondPoint.position.x)/2,(firstPoint.position.y+secondPoint.position.y),(firstPoint.position.z+secondPoint.position.z))
                        
                        display(distance: result, position: centerPoint)
                        
                        // M = (x1+x2)/2,(y1+y2)/2,(z1+z2)/2
                    }
                }
            default:
                return
        }
        
    }
    
    //function to add sphere on screen when press start and end
    private func addPoint(hitTestResult: ARHitTestResult){
        let sphere = SCNSphere(radius: 0.005)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        
        sphere.firstMaterial = material
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
        
        self.sceneView.scene.rootNode.addChildNode(sphereNode)
        self.spheres.append(sphereNode)
    }
    
    //function to count distance between two points
    private func countDistance(){
        let firstPoint = self.spheres.first!
        let secondPoint = self.spheres.last!
        
        let position = SCNVector3Make(secondPoint.position.x - firstPoint.position.x, secondPoint.position.y - firstPoint.position.y, secondPoint.position.z - firstPoint.position.z)
        
        let result = sqrt(position.x*position.x + position.y*position.y + position.z*position.z)
        
        let centerPoint = SCNVector3((firstPoint.position.x+secondPoint.position.x)/2,(firstPoint.position.y+secondPoint.position.y),(firstPoint.position.z+secondPoint.position.z))
        
        display(distance: result, position: centerPoint)
        
        // M = (x1+x2)/2,(y1+y2)/2,(z1+z2)/2
    }
    
    //function to write line
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if spheres.isEmpty || spheres.count == 2{
            return
        }
        let startPoint = self.spheres.first!.position
        let hitPoint = sceneView.hitTest(ScreenCenter, types: .featurePoint)
        
        if !hitPoint.isEmpty{
            DispatchQueue.main.async {
                if !self.currentLine.isEmpty{
                    if self.currentLine.count >= 1{
                        let length = self.currentLine.count - 1
                        for node in self.currentLine[0...length]{
                            node.removeFromParentNode()
                        }
                    }
                }
            }
            glLineWidth(8.0)
            let lineEndPoint = hitPoint.first!
            let lineEndPointPosition = SCNVector3(lineEndPoint.worldTransform.columns.3.x,lineEndPoint.worldTransform.columns.3.y,lineEndPoint.worldTransform.columns.3.z)
            let line = lineFrom(vector: startPoint, toVector: lineEndPointPosition)
            let lineNode = SCNNode(geometry: line)
            lineNode.geometry?.firstMaterial?.diffuse.contents = lineColor
            sceneView.scene.rootNode.addChildNode(lineNode)
            self.currentLine.append(lineNode)
        }
    }
    
    //function to display the distance
    private func display(distance: Float,position :SCNVector3) {
        
        let textGeo = SCNText(string: "\(distance) m", extrusionDepth: 1.0)
        textGeo.firstMaterial?.diffuse.contents = UIColor.black
        
        let textNode = SCNNode(geometry: textGeo)
        textNode.position = position
        textNode.rotation = SCNVector4(1,0,0,Double.pi/(-2))
        textNode.scale = SCNVector3(0.002,0.002,0.002)
        
        self.sceneView.scene.rootNode.addChildNode(textNode)
        
        print(distance)
    }
    
    //function to add cross sign at center of the screen
    private func addCrossSign() {
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 33))
        label.text = "+"
        label.textAlignment = .center
        label.center = self.sceneView.center
        
        self.sceneView.addSubview(label)
        
    }
    
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
}
