//
//  ProjVertex.swift
//  mmspg360
//
//  Created by Evgeniy Upenik on 12/06/16.
//  Copyright © 2016 Evgeniy Upenik. All rights reserved.
//

import GLKit

typealias VertexPositionComponent = (GLfloat, GLfloat, GLfloat)
typealias VertexTextureCoordinateComponent = (GLfloat, GLfloat)

struct TextureVertex {
    var position: VertexPositionComponent = (0, 0, 0)
    var texture: VertexTextureCoordinateComponent = (0, 0)
}