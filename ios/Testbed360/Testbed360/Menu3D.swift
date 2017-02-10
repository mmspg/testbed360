//
//  menu3d.swift
//  Testbed360
//
//  Created by Evgeniy Upenik on 03/10/16.
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

import UIKit
import GLKit

class Menu3D: NSObject, Renderable {
    private let radius: Float
    
    private let effect = GLKBaseEffect()
    private var vertices = [TextureVertex]()
    private var indices = [UInt32]()
    private var vertexArray: GLuint = 0
    private var vertexBuffer: GLuint = 0
    private var indexBuffer: GLuint = 0
    private var texture: GLuint = 0
    
    private var interactionEnbl: Bool = false
    
    private var deltaYaw: Float = 0.0
    
    var txH: GLfloat = 200;
    var txW: GLfloat = 200;
    
    private let voteLabels = [
        (num: 1, text: "1 Bad"),
        (num: 2, text: "2 Poor"),
        (num: 3, text: "3 Fair"),
        (num: 4, text: "4 Good"),
        (num: 5, text: "5 Excellent")
    ]
    private var activeVote = 0
    private var votePlaneAngles = (upper: 0.0, lower: 0.0, left: 0.0, right: 0.0)
    private var votePositions = [
        (0.0,0.0,0.1,0.1),
        (0.0,0.0,0.1,0.1),
        (0.0,0.0,0.1,0.1),
        (0.0,0.0,0.1,0.1),
        (0.0,0.0,0.1,0.1)
    ]
    
    init(interEnbl: Bool = true, radius: Float = 1, vote: Int = 0, yaw: Float = 0.0) {
        self.interactionEnbl = interEnbl
        self.radius = radius
        self.deltaYaw = yaw
        self.activeVote = vote
        
        super.init()
        
        let image = generateMenuTexture()
        
        self.prepareEffect()
        self.load()
        self.loadTexture(image)
    }
    
    deinit {
        self.unload()
    }
    
    private func prepareEffect() {
        self.effect.colorMaterialEnabled = GLboolean(GL_TRUE)
        self.effect.useConstantColor = GLboolean(GL_FALSE)
    }
    
    private func load() {
        self.unload()
        
        // Generate vertices and indices
        self.generateVertices()
        self.generateIndices()
        
        // Create OpenGL's buffers
        glGenVertexArraysOES(1, &self.vertexArray)
        glBindVertexArrayOES(self.vertexArray)
        
        glGenBuffers(1, &self.vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), self.vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), sizeof(TextureVertex) * self.vertices.count, self.vertices, GLenum(GL_STATIC_DRAW))
        
        glGenBuffers(1, &self.indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), self.indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), sizeof(UInt32) * self.indices.count, self.indices, GLenum(GL_STATIC_DRAW))
        
        
        // Describe vertex format to OpenGL
        let ptr = UnsafePointer<GLfloat>(bitPattern: 0)
        let sizeOfVertex = GLsizei(sizeof(TextureVertex))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Position.rawValue), GLint(3), GLenum(GL_FLOAT), GLboolean(GL_FALSE), sizeOfVertex, ptr)
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.TexCoord0.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.TexCoord0.rawValue), GLint(2), GLenum(GL_FLOAT), GLboolean(GL_FALSE), sizeOfVertex, ptr.advancedBy(3))
        
        glBindVertexArrayOES(0)
    }
    
    private func unload() {
        self.vertices.removeAll()
        self.indices.removeAll()
        
        glDeleteBuffers(1, &self.vertexBuffer)
        glDeleteBuffers(1, &self.indexBuffer)
        glDeleteVertexArraysOES(1, &self.vertexArray)
        glDeleteTextures(1, &self.texture)
    }
    
    // MARK: - Generate menu texture and coordinates
    private func generateMenuTexture() -> UIImage {
        // Setup the font specific variables
        let textColor = UIColor.blackColor()
        let textFont = UIFont(name: "Helvetica", size: 24)!
        // Setup the font attributes
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ]
        
        //let text2draw = "Welcome!\nYou are about to participate in VR subjective quality evaluation experiment.\nPress LEFT Button to proceed."
        
        // Texture dimentions and margines
        let textureWidth = CGFloat(300);
        let textureHeight = CGFloat(350);
        //let textMargines = CGFloat(20);
        
        let rect = CGRectMake(0, 0, textureWidth, textureHeight)
        //let textRect = CGRectMake(textMargines, textMargines, textureWidth-textMargines*2, textureHeight-textMargines*2)
        let color = UIColor(red: 0, green: 50, blue: 100, alpha: 1.0)
        
        // Begin drawing the image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: textureWidth,height: textureHeight), true, 0)
        
        // Fill the background with solide color
        color.setFill()
        UIRectFill(rect)
        
        // Draw the text into an image
        //text2draw.drawInRect(textRect, withAttributes: textFontAttributes)
        var vlPos = CGFloat(0)
        let vlMargineX = textureWidth*0.3
        let vlMargineY = textureHeight*0.07
        
        // Draw the labels
        for vl in voteLabels {
            let vlRect = CGRectMake(0, textureHeight*0.8 -  vlPos*textureHeight/5,
                                    textureWidth, textureHeight/5)
            let vlTextRect = CGRectMake(vlMargineX, textureHeight*0.8 -  vlPos*textureHeight/5 + vlMargineY,
                                        textureWidth - vlMargineX, textureHeight/5-vlMargineY)
            
            if(vl.num == activeVote) {
                UIColor.greenColor().setFill()
                UIRectFill(vlRect)
            }
            
            UIColor.whiteColor().setStroke()
            UIRectFrame(vlRect)
            
            vl.text.drawInRect(vlTextRect, withAttributes: textFontAttributes)
            vlPos += 1
        }
        
        // Finish drawing the image
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func updateVotingMenuTexture() {
        let image = generateMenuTexture()
        self.loadTexture(image)
    }
    
    func checkPointerPosition(p: Double,y: Double) -> Int {
        guard interactionEnbl else {
            return 0
        }
        for i in 0...4 {
            if(p < votePositions[i].0 && p > votePositions[i].1 &&
                y > votePositions[i].2 && y < votePositions[i].3) {
                activeVote = i+1
                return i+1
            }
        }
        activeVote = 0
        return 0
    }
    
    func getActiveVote() -> Int? {
        if activeVote != 0 {
            return activeVote
        }
        else {
            return nil
        }
    }
    
    // MARK: -
    private func generateVertices() {
        let r = radius*0.5
        let rx = Float(0.3)
        let ry = Float(0.35)
        
        //                         ^ y
        //                         |
        //          0-----3        |
        //          |     |        /-----> x
        //          |     |       /
        //          1-----2      |/
        //                       'z
        
        let pos = [
            GLKVector3(v: (-r*rx,  r*ry,  r)),  // 0
            GLKVector3(v: (-r*rx, -r*ry,  r)),  // 1
            GLKVector3(v: ( r*rx, -r*ry,  r)),  // 2
            GLKVector3(v: ( r*rx,  r*ry,  r)),  // 3
        ]
        
        // set initial vote plane angles
        votePlaneAngles.upper =  atan(Double(r*ry/r))
        votePlaneAngles.lower = -votePlaneAngles.upper
        votePlaneAngles.left = -atan(Double(r*rx/r)) + Double(self.deltaYaw)//+ Double(self.deltaYaw) // TODO: initial position
        votePlaneAngles.right = atan(Double(r*rx/r)) + Double(self.deltaYaw)//-votePlaneAngles.left
        // set vote positions
        //let stepX = abs(votePlaneAngles.left - votePlaneAngles.right)/5.0
        let stepY = abs(votePlaneAngles.upper - votePlaneAngles.lower)/5.0
        let areaMargin = stepY*0.08
        for i in 0...4 {
            votePositions[i] = (votePlaneAngles.upper - Double(i)*stepY - areaMargin,
                                votePlaneAngles.upper - Double(i+1)*stepY + areaMargin,
                                votePlaneAngles.left + areaMargin,
                                votePlaneAngles.right - areaMargin)
        }
        
        
        // Texture coordinates on plane for vertices
        let vxs = [
            3, 2, 1, 0
        ]
        var vxsSlice = vxs[vxs.indices]
        
        self.vertices.append(TextureVertex(position: pos[vxsSlice.popFirst()!].v, texture: (0, 0)))
        self.vertices.append(TextureVertex(position: pos[vxsSlice.popFirst()!].v, texture: (0, 1)))
        self.vertices.append(TextureVertex(position: pos[vxsSlice.popFirst()!].v, texture: (1, 1)))
        self.vertices.append(TextureVertex(position: pos[vxsSlice.popFirst()!].v, texture: (1, 0)))
        
    }
    
    private func generateIndices() {
        for i: UInt32 in 0...0 {
            self.indices.append(i*4+0)
            self.indices.append(i*4+1)
            self.indices.append(i*4+2)
            self.indices.append(i*4+2)
            self.indices.append(i*4+3)
            self.indices.append(i*4+0)
        }
    }
    
    // MARK: - Loading texture and rendering
    private func loadTexture(image: UIImage?) {
        guard let image = image else {
            NSLog("Image not found")
            return
        }
        NSLog("Laoding texture...")
        let width = CGImageGetWidth(image.CGImage!)
        let height = CGImageGetHeight(image.CGImage!)
        txW = 1.0/GLfloat(width)
        txH = 1.0/GLfloat(height)
        NSLog("W: %d,H: %d", width, height)
        let imageData = UnsafeMutablePointer<GLubyte>(calloc(Int(width * height * 4), sizeof(GLubyte)))
        let imageColorSpace = CGImageGetColorSpace(image.CGImage!)
        NSLog("Colorspace: %s", imageColorSpace.debugDescription)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        let gc = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, imageColorSpace!, bitmapInfo.rawValue)
        CGContextDrawImage(gc!, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image.CGImage!)
        
        self.updateTexture(CGSize(width: width, height: height), imageData: imageData)
        free(imageData)
    }
    
    func render(camera: Camera) {
        glBindVertexArrayOES(self.vertexArray)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.texture)
        
        self.effect.transform.projectionMatrix = camera.projection
        //self.effect.transform.modelviewMatrix = GLKMatrix4RotateY(camera.view, GLfloat(-M_PI_2))
        // TODO: initial position
        self.effect.transform.modelviewMatrix = GLKMatrix4RotateY(camera.view, GLfloat(deltaYaw)+GLfloat(-M_PI_2))
        
        self.effect.texture2d0.enabled = GLboolean(GL_TRUE)
        self.effect.texture2d0.name = self.texture
        self.effect.prepareToDraw()
        
        let bufferOffset = UnsafePointer<UInt>(bitPattern: 0)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(self.indices.count), GLenum(GL_UNSIGNED_INT), bufferOffset)
        
        glBindVertexArrayOES(0)
    }
    
    private func updateTexture(size: CGSize, imageData: UnsafeMutablePointer<Void>) {
        if self.texture == 0 {
            glGenTextures(1, &self.texture)
            glBindTexture(GLenum(GL_TEXTURE_2D), self.texture)
            
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLint(GL_REPEAT))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLint(GL_REPEAT))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLint(GL_LINEAR))
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLint(GL_LINEAR))
        }
        
        glBindTexture(GLenum(GL_TEXTURE_2D), self.texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(GL_RGBA), GLsizei(size.width), GLsizei(size.height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), imageData)
    }
}
