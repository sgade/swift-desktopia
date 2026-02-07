//
//  DeskProperties.swift
//  DesktopiaProX
//
//  Created by Sören Gade on 06.01.23.
//

import Foundation

public enum DeskProperties {

    public static let minimumHeight = Measurement(
        value: 62.3,
        unit: UnitLength.centimeters
    )

    public static let maximumHeight = Measurement(
        value: 127,
        unit: UnitLength.centimeters
    )

    public static let movementSpeed = Measurement(
        value: 0.038,
        unit: UnitSpeed.metersPerSecond
    )

}
