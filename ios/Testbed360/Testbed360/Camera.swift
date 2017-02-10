//
//  Camera.swift
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

class Camera: NSObject {
    private var projectionMatrix = GLKMatrix4()
    private var viewMatrix = GLKMatrix4Identity
    
    // MARK: - Projection parameters
    var fovRadians: Float = GLKMathDegreesToRadians(90.0) {
        didSet { self.updateProjectionMatrix() }
    }
    var aspect: Float = (320.0 / 480.0) {
        didSet { self.updateProjectionMatrix() }
    }
    var nearZ: Float = 0.1 {
        didSet { self.updateProjectionMatrix() }
    }
    var farZ: Float = 100.0
        {
        didSet { self.updateProjectionMatrix() }
    }
    
    // MARK: - Camera attitude
    var yaw: Float = 0.0
    var pitch: Float = 0.0
    var roll: Float = 0.0
    
    // MARK: - Matrix getters
    var projection: GLKMatrix4 {
        get { return self.projectionMatrix }
    }
    var view: GLKMatrix4 {
        get { return self.viewMatrix }
    }
    
    // MARK: - Init
    init(fovRadians: Float = GLKMathDegreesToRadians(90.0), aspect: Float = (320.0 / 480.0),
         nearZ: Float = 0.1, farZ: Float = 400) {
        super.init()
        self.fovRadians = fovRadians
        self.aspect = aspect
        self.nearZ = nearZ
        self.farZ = farZ
        self.updateProjectionMatrix()
        self.updateViewMatrix()
    }
    
    // MARK: - Updaters
    private func updateProjectionMatrix() {
        self.projectionMatrix = GLKMatrix4MakePerspective(self.fovRadians, self.aspect, self.nearZ, self.farZ)
        self.projectionMatrix = GLKMatrix4Rotate(self.projectionMatrix, Float(M_PI), 0, 0, 1)
    }
    
    func updateViewMatrix() {
        self.viewMatrix = GLKMatrix4Identity
        self.viewMatrix = GLKMatrix4Scale(self.viewMatrix, 300, 300, 300)
        
        self.viewMatrix = GLKMatrix4RotateX(self.viewMatrix, -roll)
        self.viewMatrix = GLKMatrix4RotateY(self.viewMatrix, pitch)
        self.viewMatrix = GLKMatrix4RotateZ(self.viewMatrix, -yaw)
        
        self.viewMatrix = GLKMatrix4RotateX(self.viewMatrix, Float(M_PI_2))
        self.viewMatrix = GLKMatrix4RotateY(self.viewMatrix, Float(M_PI_2))
    }
}
