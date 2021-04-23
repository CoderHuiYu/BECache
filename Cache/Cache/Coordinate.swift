//
//  Coordinate.swift
//  Codeable
//
//  Created by yuhui on 2021/4/20.
//

struct Coordinate : Codable {
    var latitude: Double
    var longitude: Double
}

struct Placemark : Codable {
    var name: String
    var coordinate: Coordinate
}
