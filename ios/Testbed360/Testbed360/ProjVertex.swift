//
//  ProjVertex.swift
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

import GLKit

typealias VertexPositionComponent = (GLfloat, GLfloat, GLfloat)
typealias VertexTextureCoordinateComponent = (GLfloat, GLfloat)

struct TextureVertex {
    var position: VertexPositionComponent = (0, 0, 0)
    var texture: VertexTextureCoordinateComponent = (0, 0)
}
