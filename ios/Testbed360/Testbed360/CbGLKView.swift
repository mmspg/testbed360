//
//  CbGLKView.swift
//  Testbed360
//
//  Created by Evgeniy Upenik on 08/06/16.
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

import GLKit
import CoreMotion

class CbGLKView: GLKView {
    private var sceneObjects = [NSObject]()
    private let res_h: GLint = GLint(UIScreen.mainScreen().bounds.height*2) // 750
    private let res_w: GLint = GLint(UIScreen.mainScreen().bounds.width*2)  // 1334
    
    var cameraL = Camera() {
        didSet { self.setNeedsDisplay() }
    }
    var cameraR = Camera() {
        didSet { self.setNeedsDisplay() }
    }
    
    // MARK: - Public interface
    func addSceneObject(object: NSObject) {
//        self.sceneObjects.removeAll()
//        self.sceneObjects.append(object)
        if !self.sceneObjects.contains(object) {
            self.sceneObjects.append(object)
        }
    }
    
    func removeSceneObject(object: NSObject) {
        if let index = self.sceneObjects.indexOf(object) {
            self.sceneObjects.removeAtIndex(index)
        }
    }
    
    func removeAllSceneObjects() {
        self.sceneObjects.removeAll()
    }
    
    // MARK: - Overriden interface
    override func layoutSubviews() {
        super.layoutSubviews()
        self.cameraL.aspect = fabsf(Float(self.bounds.size.width/2 / self.bounds.size.height))
        self.cameraR.aspect = fabsf(Float(self.bounds.size.width/2 / self.bounds.size.height))
        //NSLog("CbGLKView.layoutSubviews(): W:%.0f H:%.0f", UIScreen.mainScreen().bounds.width*2,UIScreen.mainScreen().bounds.height*2)
        
    }
    
    override func display() {
        super.display()
        
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        let objects = self.sceneObjects
        for object in objects {
            if let renderable = object as? Renderable {
                glViewport(0, 0, res_w/2, res_h) // 1334 × 750
                renderable.render(self.cameraL)
                glViewport(res_w/2, 0, res_w/2, res_h) // 1334 × 750
                renderable.render(self.cameraR)
            }
        }
    }
    
}
