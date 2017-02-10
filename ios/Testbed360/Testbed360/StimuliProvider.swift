//
//  TestImages.swift
//  Testbed360
//
//  Created by Evgeniy Upenik on 12/06/16.
//
//  Copyright (C) 2017 ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland
//  Multimedia Signal Processing Group
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

// Absolute Category Rating Scale
enum ACRGrade: Int {
    case Excellent =    5
    case Good =         4
    case Fair =         3
    case Poor =         2
    case Bad =          1
}

class StimuliProvider: NSObject {
    
    private var trainFiles: Array<String> = []
    private var evalFiles: Array<String> = []
    
    private var trainingStimuliList:
        Array<(vendor: String, name: String, proj: String, w: String, h: String, q: String, g: String)> = []
    
    private var evaluationStimuliList:
        Array<(vendor: String, name: String, proj: String, w: String, h: String, q: String)> = []
    
    let welcomeText = "Welcome!\nYou are about to participate in VR subjective quality evaluation experiment.\nPress the button to proceed."
    let introTexts = [
    "Pay attention to the sky, trees, and ground. Look for the compression artifacts such as posterizing (tone borders) and blockiness (distinct squares). Remember: you can look in all directions including up, down and back.\nPress any button to start the training",
    "First, you will watch training images which already have grades. This will help you to understand how to rate the pictures. After the training you will proceed to the evaluation. Press any button for next",
    "There are two buttons on the top of the goggles: both buttons allow you to proceed to the NEXT view and SELECT the grade, you can use gaze pointer to choose the item in the menu\nPlease press any button",
    ]
    let introVoting = [
    "Now press a button to start evaluating the images.\n\nYou can use a button to activate grading and choose the grade with a pointer. Press a button to SELECT the chosen grade and proceed.",
    ]
    
    
    override init() {
        super.init()
        trainFiles = getTrainStimuliFiles()
        //trainingStimuliList = trainFiles.map(self.parseTrainStimuliFile)
        evalFiles = getEvalStimuliFiles()
        //imageList = imageFiles.map(self.parceFile)
    }
    
    private func enumFilesInDirectory(dir: String) -> NSDirectoryEnumerator? {
        let docDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
                                                         NSSearchPathDomainMask.AllDomainsMask, true).first!
        let trainStimuliPath: NSURL = NSURL(fileURLWithPath: docDir).URLByAppendingPathComponent(dir)!
        
        return NSFileManager.defaultManager().enumeratorAtPath(trainStimuliPath.path!)
    }
    
    private func getTrainStimuliFiles() -> Array<String> {
        var list: Array<String> = []
        
        if let enumerator: NSDirectoryEnumerator = enumFilesInDirectory("stimuli/training") {
            while let element = enumerator.nextObject() as? String {
                if element.hasSuffix(".png") || element.hasSuffix(".jpg") {
                    list.append(element)
                }
            }
        }
        return list
    }
    private func parseTrainStimuliFile(file: String) -> (String,String,String,String,String,String,String) {
        let xs = file.componentsSeparatedByString("_")
        let vendor = xs[0]
        let name = xs[1]
        let projection = xs[2]
        let resolution = xs[3]
        let (width, height) = (resolution.componentsSeparatedByString("x")[0],resolution.componentsSeparatedByString("x")[1])
        var quality = xs[4]
        quality = quality[quality.startIndex.advancedBy(1)...quality.startIndex.advancedBy(2)]
        var grade = xs[5]
        grade = grade[grade.startIndex.advancedBy(5)...grade.startIndex.advancedBy(7)]
        
        return (vendor: vendor, name: name, proj: projection, w: width, h: height, q: quality, g: grade)
    }
    private func getEvalStimuliFiles() -> Array<String> {
        var list: Array<String> = []
        
        if let enumerator: NSDirectoryEnumerator = enumFilesInDirectory("stimuli/evaluation") {
            while let element = enumerator.nextObject() as? String {
                if element.hasSuffix(".png") || element.hasSuffix(".jpg") {
                    list.append(element)
                }
            }
        }
        return list
    }
    private func parseEvalStimuliFiles(file: String) -> (String,String,String,String,String,String) {
        let xs = file.componentsSeparatedByString("_")
        let vendor = xs[0]
        let name = xs[1]
        let projection = xs[2]
        let resolution = xs[3]
        let (width, height) = (resolution.componentsSeparatedByString("x")[0],resolution.componentsSeparatedByString("x")[1])
        var quality = xs[4]
        quality = quality[quality.startIndex.advancedBy(1)...quality.startIndex.advancedBy(2)]
        
        return (vendor: vendor, name: name, proj: projection, w: width, h: height, q: quality)
    }

    private func getGrade(file: String) -> Int {
        let xs = file.componentsSeparatedByString("_")
        var grade = xs[5]
        grade = grade[grade.startIndex.advancedBy(5)...grade.startIndex.advancedBy(6)]
        return Int(grade)!
    }
    private func getProj(file: String) -> Int {
        var p: Int = 0
        let proj = file.componentsSeparatedByString("_")[2]
        if proj == "equirec" {
            p = 0
        }
        else if proj == "cubemap32" {
            p = 1
        }
        return p
    }

    func getTrainingStimuli() -> Array<(String,Int,ACRGrade)> {
        var dict: Array<(String,Int,ACRGrade)> = []

        for file in trainFiles {
            dict.append((file, getProj(file), ACRGrade(rawValue: getGrade(file))!))
        }
        //dict = trainFiles.map(<#T##transform: (String) throws -> T##(String) throws -> T#>)
        
        return dict
    }
    func getEvaluationStimuli() -> Array<(String,Int)> {
        var dict: Array<(String,Int)> = []
        var output: Array<(String,Int)> = []
        var p: Int = 0
        for file in evalFiles {
            let proj = file.componentsSeparatedByString("_")[2]
            if proj == "equirec" {
                p = 0
            }
            else if proj == "cubemap32" {
                p = 1
            }
            dict.append((file,p))
        }
        
        if dict.isEmpty {
            return output
        }
        
        // Perform randomization on returned array
        func checkRepeats() -> Bool {
            var counter: Int = 0
            for i in 1..<output.count {
                let comp = output[i-1].0.componentsSeparatedByString("_")
                let pref = comp[0] + "_" + comp[1]
                if (output[i].0.hasPrefix(pref)) {
                    counter=counter+1
                }
            }
            return (counter > 0) // Nubmer of allowed consiquent repeates of the same content
        }
        repeat {
            output = dict.sort() {_, _ in arc4random() % 2 == 0}
        } while (checkRepeats() || (output.count != dict.count) )
        
        
        // Sorted output
        //output = dict.sort(<)
        
        return output
    }

}
