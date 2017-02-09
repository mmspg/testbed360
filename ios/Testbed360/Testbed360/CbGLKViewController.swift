//
//  CbGLKViewController.swift
//  mmspg360
//
//  Created by Evgeniy Upenik on 08/06/16.
//  Copyright © 2016 Evgeniy Upenik. All rights reserved.
//

import GLKit
import UIKit
import CoreMotion

class CbGLKViewController: GLKViewController {
    // MARK: OpenGL ES variables
    @IBOutlet weak var cbGLKView: CbGLKView!
    private var context: EAGLContext!
    
    // MARK: Buttons and labels
    @IBOutlet weak var pointerLeft: UILabel!
    @IBOutlet weak var pointerRight: UILabel!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var leftText: UILabel!
    @IBOutlet weak var rightText: UILabel!
    
    var VoteL: Array<UIButton>? = nil
    var VoteR: Array<UIButton>? = nil
    
    @IBOutlet weak var doneL: UILabel!
    @IBOutlet weak var doneR: UILabel!
    
    // MARK: Motion control variables
    let motionManager = CMMotionManager()
    //var motionQueue: NSOperationQueue = NSOperationQueue.init()
    var isMotion = false
    
    // MARK: States
    var curGrade: ACRGrade? = nil
    var curFile: String? = nil
    enum EvaluationState {
        case Welcome
        case Intro
        case Training
        case Evaluating
        case Done
    }
    enum EvaluationSubState {
        case watching
        case rating
    }
    var evalState: EvaluationState = .Welcome
    var evalSubState: EvaluationSubState = .watching
    
    // Menu3D
    var menu3D: Menu3D? = nil
    var activeVote = 0
    
    // Data collector
    var dataCollector: DataCollector? = nil
    
    // MARK: - Test images
    let stimuliProvider = StimuliProvider()
    
    var evaluationSet: Array<(String,Int)> = []
    var trainingSet: Array<(String,Int,ACRGrade)> = []
    
    // MARK: - Text instructions
    var introVotingList: Array<String> = []
    var introTexts: Array<String> = []
    var introVoting: Array<String> = []

    
    // MARK: - Overwritten methods
    deinit {
        if EAGLContext.currentContext() == self.context {
            EAGLContext.setCurrentContext(nil)
        }
        self.stopDeviceMotion()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureContext()
        self.configureView()
        
        self.preferredFramesPerSecond = 60
        
        self.startDeviceMotion()
        
        self.initUserInterface()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - GLKView update
    func update() {
        self.updateMotion()
        //cbGLKView.cameraL.updateViewMatrix()
        //cbGLKView.cameraR.updateViewMatrix()
        // TODO: Collect attitude here, maybe
    }
    
    // MARK: - View Configuration
    private func configureContext() {
        self.context = EAGLContext(API: EAGLRenderingAPI.OpenGLES3)
        EAGLContext.setCurrentContext(self.context)
        
    }
    private func configureView() {
        self.cbGLKView.context = self.context
    }

    // MARK: - Device Motion
    func startDeviceMotion() {
        guard !isMotion else {
            return
        }
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.gyroUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryCorrectedZVertical)
            isMotion = true
            NSLog("startDeviceMotion: Done")
        }
    }
    func stopDeviceMotion() {
        guard isMotion else {
            return
        }
        motionManager.stopDeviceMotionUpdates()
        isMotion = false
        NSLog("stopDeviceMotion: Done")
    }
    func updateMotion() {
        guard isMotion else {
            return
        }
        let deviceMotion = motionManager.deviceMotion
        if let attitude = deviceMotion?.attitude {
            
            cbGLKView.cameraL.pitch = Float(attitude.pitch)
            cbGLKView.cameraL.yaw = Float(attitude.yaw)     // Horizontal (right = negative)
            cbGLKView.cameraL.roll = Float(attitude.roll)   // Vertical (up = negative)
            
            cbGLKView.cameraR.pitch = Float(attitude.pitch)
            cbGLKView.cameraR.yaw = Float(attitude.yaw)
            cbGLKView.cameraR.roll = Float(attitude.roll)
            
            cbGLKView.cameraL.updateViewMatrix()
            cbGLKView.cameraR.updateViewMatrix()
            
            // Check if pointer position is inside the 3D menu
            if let m = menu3D {
                let v = m.checkPointerPosition(Double(attitude.roll) + M_PI_2, y: Double(attitude.yaw))
                if activeVote != v {
                    activeVote = v
                    m.updateVotingMenuTexture()
                    //NSLog("Active menu Item: %d", activeVote)
                    if activeVote != 0 {
                        curGrade = ACRGrade(rawValue: activeVote)
                    }
                    else { curGrade = nil }
                }
            }
            //else {
            //    NSLog("ERROR: menu3D not initialized!")
            //}

            
            if let d = dataCollector {
                d.addPosition(NSDate().timeIntervalSince1970, horiz: attitude.yaw, vert: attitude.roll, roll: attitude.pitch)
            }
            
            //NSLog("Y:\(round(attitude.yaw/M_PI*180)) P:\(round(attitude.pitch/M_PI*180)) R:\(round(attitude.roll/M_PI*180))")
        }
        else {
            NSLog("No Motion")
        }
    }
    
    func showImage360(file: String, filePath: String, proj: Int) {
        let docDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
                                                         NSSearchPathDomainMask.AllDomainsMask, true).first!
        let imageToShow = UIImage(contentsOfFile: NSURL(fileURLWithPath: docDir).URLByAppendingPathComponent(filePath)!.URLByAppendingPathComponent(file)!.path!)

        self.cbGLKView.removeAllSceneObjects()
        
        if proj == 0 {
            let equirec = ProjEquirec(radius: 1)
            equirec.loadTexture(imageToShow)
            self.cbGLKView.addSceneObject(equirec)
        }
        else if proj == 1 {
            let cubmap32 = ProjCubemap32(radius: 1, image: imageToShow)
            self.cbGLKView.addSceneObject(cubmap32)
        }
        else {
            NSLog("Wrong projection")
            return
        }
    }

    // MARK: - User interface
    @IBAction func leftButtonPressed(sender: AnyObject) {
        
        // Grading action
        if let vote = curGrade, file = curFile where ((evalState == .Evaluating) && (evalSubState == .rating)) {
            dataCollector!.addVote(file, vote)
            dataCollector!.stopTracking()
            curGrade = nil
            curFile = nil
            evalSubState = .watching
            if evaluationSet.isEmpty {
                evalState = .Done
                self.showScreenText(false)
                if let m = menu3D {
                    self.cbGLKView.removeSceneObject(m)
                    showPointer(false)
                    menu3D = nil
                }
            }
        }
        // Intro and instructions handler
        if let text = introTexts.popLast() {
            self.screenText = text
            NSLog("Intro: %d", introTexts.count)
        }
        // Training session handler
        else if let (file,proj,vote) = trainingSet.popLast() {
            
            showImage360(file, filePath: "stimuli/training", proj: proj)
            
            self.showScreenText(false)

            menu3D = Menu3D(interEnbl: false, vote: vote.rawValue)
            self.cbGLKView.addSceneObject(menu3D!)
            NSLog("Training: %d", trainingSet.count)
        }
        // Prompt screen before evaluation session
        else if !introVoting.isEmpty {
            let text = introVoting.popLast()!

            if let m = menu3D {
                self.cbGLKView.removeSceneObject(m)
                showPointer(false)
                menu3D = nil
            }
            self.screenText = text
        }
        // Evaluation session handler
        else if (!evaluationSet.isEmpty || evalState == .Evaluating) {
            if(menu3D == nil && evalState == .Evaluating) {
                curGrade = nil
                menu3D = Menu3D(radius: 1, yaw: cbGLKView.cameraL.yaw)
                self.cbGLKView.addSceneObject(menu3D!)
                showPointer()
                evalSubState = .rating
                return
            }
            if (evalSubState == .rating && curGrade == nil) {
                return
            }
            // TODO: Workaround for not shoing voting menu at the last picture
            if (evaluationSet.isEmpty && evalState == .Evaluating){
                return
            }
            self.showScreenText(false)
            if let m = menu3D {
                self.cbGLKView.removeSceneObject(m)
                showPointer(false)
                menu3D = nil
            }
            stopDeviceMotion()
            startDeviceMotion()
            
            // - Show the 360 picture
            let (file, proj) = evaluationSet.removeFirst()
            curFile = file
            showImage360(file, filePath: "stimuli/evaluation", proj: proj)
            
            // DEBUG: show filename
            //self.screenText = file
            //self.screenText = String(evaluationSet.count)
            //self.showScreenText(false)
            
            dataCollector!.startTracking()
            evalState = .Evaluating
            NSLog("Evaluating: %d", evaluationSet.count)
        }
        else if doneL.hidden {
            // Last vote
            self.showDone()
            self.dataCollector = nil
            evalState = .Done
        }
    }
    @IBAction func rightButtonPressed(sender: AnyObject) {
        leftButtonPressed(sender)
//        // DEBUG: show file name
//        if(self.leftText.hidden == true) {
//            self.showScreenText(true)
//        }
//        else {
//            self.showScreenText(false)
//        }
    }
    
    @IBAction func resetButtonPressed(sender: AnyObject) {
        stopDeviceMotion()
        curGrade = nil
        curFile = nil
        evalState = .Welcome
        evalSubState = .watching
        menu3D = nil
        activeVote = 0
        self.cbGLKView.removeAllSceneObjects()
        initUserInterface()
    }
    
    private func showPointer(state: Bool = true) {
        self.pointerLeft.hidden = !state
        self.pointerRight.hidden = !state
    }

    var screenText: NSString = "Welcome!" {
        didSet {
            self.leftText.text = screenText as String
            self.rightText.text = screenText as String
            self.showScreenText()
        }
    }
    func showScreenText(state: Bool = true) {
        self.leftText.hidden = !state
        self.rightText.hidden = !state
    }
    
    
    func showDone(state: Bool = true) {
        self.doneL.hidden = !state
        self.doneR.hidden = !state
    }
    
    func initUserInterface() {
        
        dataCollector = DataCollector()
        
        evaluationSet = stimuliProvider.getEvaluationStimuli()
        trainingSet = stimuliProvider.getTrainingStimuli()
        
        introTexts = stimuliProvider.introTexts
        introVoting = stimuliProvider.introVoting
        
        // Render Welcome picture
        let equirec = ProjEquirec(radius: 1)
        equirec.loadTexture(UIImage(named: "welcome.jpg"))
        self.cbGLKView.addSceneObject(equirec)
        
        // Reset all menus
        showDone(false)
        showPointer(false)
        menu3D = nil
        
        // Reset states
        startDeviceMotion()
        evalState = .Welcome
        
        
        // Show welcome message
        self.screenText = stimuliProvider.welcomeText
    }
    
}
