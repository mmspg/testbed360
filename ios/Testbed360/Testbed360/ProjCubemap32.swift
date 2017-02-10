//
//  ProjCubemap32.swift
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

class ProjCubemap32: NSObject, Renderable {
    private let radius: Float
    
    private let effect = GLKBaseEffect()
    private var vertices = [TextureVertex]()
    private var indices = [UInt32]()
    private var vertexArray: GLuint = 0
    private var vertexBuffer: GLuint = 0
    private var indexBuffer: GLuint = 0
    private var texture: GLuint = 0
    
    var txH: GLfloat = 1/1500;
    var txW: GLfloat = 1/3000;
    
    init(radius: Float = 1, image: UIImage?) {
        self.radius = radius
        super.init()
        
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
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), sizeof(UInt) * self.indices.count, self.indices, GLenum(GL_STATIC_DRAW))
        
        
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
    
    
    // MARK: - Cube geometry: vertices and texture mapping
    private func generateVertices() {
        let r = radius*0.707
        
        // Vertices for cube in 3D space
        //
        //            7-----6      ^ y                  6---7
        //           /|    /|      |                    |+Y |
        //          4-----5 |      |                6---5---4---7---6
        //          | 3- -|-2      /-----> x        |-X |+Z |+X |-Z |
        //          |/    |/      /                 2---1---0---3---2
        //          0-----1      |/                     |-Y |
        //                       'z                     2---3

        let pos = [
            GLKVector3(v: (-r, -r,  r)),  // 0
            GLKVector3(v: ( r, -r,  r)),  // 1
            GLKVector3(v: ( r, -r, -r)),  // 2
            GLKVector3(v: (-r, -r, -r)),  // 3
            GLKVector3(v: (-r,  r,  r)),  // 4
            GLKVector3(v: ( r,  r,  r)),  // 5
            GLKVector3(v: ( r,  r, -r)),  // 6
            GLKVector3(v: (-r,  r, -r))   // 7
        ]
        
        // Texture coordinates on plane for vertices
        //
        //        6---7               4---7 6---5 6---7  <--- top
        //        |+Y |               |+X | |-X | |+Y |
        //    6---5---4---7---6       0---3 2---1 5---4  <--- mid
        //    |-X |+Z |+X |-Z |       1---0 5---4 7---6
        //    2---1---0---3---2       |-Y | |+Z | |-Z |
        //        |-Y |               2---3 1---0 3---2  <--- bottom
        //        2---3               ^    ^     ^    ^
        //                          left l_mid r_mid right

        let dx = Float(1.0/3.0)
        let dy = Float(0.5)
        let xs = [Float(0.0), dx, 1.0 - dx]
        let ys = [Float(0.0), dy]
        
        
        let vxs = [
            6, 2, 1, 5, // LEFT  (-X)
            5, 1, 0, 4, // FRONT (+Z)
            4, 0, 3, 7, // RIGHT (+X)
            //1, 2, 3, 0, // BOTTOM (-Y)
            0, 1, 2, 3, // BOTTOM Rotated (-Y)
            //7, 3, 2, 6, // BACK (-Z)
            3, 2, 6, 7, // BACK Rotated (-Z)
            //6, 5, 4, 7, // TOP (+Y)
            7, 6, 5, 4, // TOP Rotetad (+Y)
        ]
        var vxsSlice = vxs[vxs.indices]

        for tv in ys {
            for tu in xs {
                self.vertices.append(TextureVertex(position: pos[vxsSlice.popFirst()!].v, texture: (tu + 0.5*txW, tv + 0.5*txH)))
                self.vertices.append(TextureVertex(position: pos[vxsSlice.popFirst()!].v, texture: (tu + 0.5*txW, tv + dy - 0.5*txH)))
                self.vertices.append(TextureVertex(position: pos[vxsSlice.popFirst()!].v, texture: (tu + dx - 0.5*txW, tv + dy - 0.5*txH)))
                self.vertices.append(TextureVertex(position: pos[vxsSlice.popFirst()!].v, texture: (tu + dx - 0.5*txW, tv + 0.5*txH)))
            }
        }

        
    }
    
    private func generateIndices() {
        for i: UInt32 in 0...5 {
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
        //NSLog("Laoding texture...")
        let width = CGImageGetWidth(image.CGImage!)
        let height = CGImageGetHeight(image.CGImage!)
        txW = 1.0/GLfloat(width)
        txH = 1.0/GLfloat(height)
        //NSLog("W: %d,H: %d", width, height)
        let imageData = UnsafeMutablePointer<GLubyte>(calloc(Int(width * height * 4), sizeof(GLubyte)))
        let imageColorSpace = CGImageGetColorSpace(image.CGImage!)
        //NSLog("Colorspace: %s", imageColorSpace.debugDescription)
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
        self.effect.transform.modelviewMatrix = GLKMatrix4RotateY(camera.view, GLfloat(-M_PI_2))
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
