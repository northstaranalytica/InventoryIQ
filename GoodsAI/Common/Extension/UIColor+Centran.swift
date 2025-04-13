//
//  UIColor+Centran.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit
extension UIColor {
    

    /// Get color
    static let kHexRGB:(Int) -> UIColor = {hex in
        return UIColor(red: ((CGFloat)((hex & 0xFF0000) >> 16)) / 255.0, green: ((CGFloat)((hex & 0xFF00) >> 8)) / 255.0, blue: ((CGFloat)(hex & 0xFF)) / 255.0, alpha: 1)
    }

    /// Get color with transparency
    static let kHexRGBA:(Int, CGFloat) -> UIColor = { hex,ali in
        return UIColor(red: ((CGFloat)((hex & 0xFF0000) >> 16)) / 255.0, green: ((CGFloat)((hex & 0xFF00) >> 8)) / 255.0, blue: ((CGFloat)(hex & 0xFF)) / 255.0, alpha:ali)
    }
    
    /// Black + transparency
    static let zdBlackA_000000:(CGFloat) -> UIColor = { ali in
        return UIColor(red: ((CGFloat)((0x000000 & 0xFF0000) >> 16)) / 255.0, green: ((CGFloat)((0x000000 & 0xFF00) >> 8)) / 255.0, blue: ((CGFloat)(0x000000 & 0xFF)) / 255.0, alpha:ali)
    }
    
    // Main color tone
    static let cColor_Main = kHexRGB(0x0762E1)
    static let cColor_light_blue = kHexRGB(0x0061FF)
    
    // Black main color tone
    static let cColor_text_333 = kHexRGB(0x333333)
    
    // Gray
    static let cColor_text_9BA3AA = kHexRGB(0x9BA3AA)
    
    // Gray
    static let cColor_text_787878 = kHexRGB(0x787878)
    
    // Line color
    static let cColor_Line = kHexRGB(0xEAEAEA )
    
    // Background
    static let cColor_F3F3F3 = kHexRGB(0xF3F3F3)
    
    // Purple
    static let cColor_other_7C79F4 = kHexRGB(0x7C79F4)

    // Purple background
    static let cColor_other_ECEBFF = kHexRGB(0xECEBFF)
   
    // Light blue background
    static let cColor_other_E6F7FF = kHexRGB(0xE6F7FF)

    
    // Red
    static let cColor_red_EF2C2B = kHexRGB(0xEF2C2B)
    
    
    
    
    /**
     The shorthand three-digit hexadecimal representation of color.
     #RGB defines to the color #RRGGBB.
     
     - parameter hex3: Three-digit hexadecimal value.
     - parameter alpha: 0.0 - 1.0. The default is 1.0.
     */
    convenience init(hex3: UInt16, alpha: CGFloat = 1) {
        let divisor = CGFloat(15)
        let red     = CGFloat((hex3 & 0xF00) >> 8) / divisor
        let green   = CGFloat((hex3 & 0x0F0) >> 4) / divisor
        let blue    = CGFloat( hex3 & 0x00F      ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     The shorthand four-digit hexadecimal representation of color with alpha.
     #RGBA defines to the color #RRGGBBAA.
     
     - parameter hex4: Four-digit hexadecimal value.
     */
     convenience init(hex4: UInt16) {
        let divisor = CGFloat(15)
        let red     = CGFloat((hex4 & 0xF000) >> 12) / divisor
        let green   = CGFloat((hex4 & 0x0F00) >>  8) / divisor
        let blue    = CGFloat((hex4 & 0x00F0) >>  4) / divisor
        let alpha   = CGFloat( hex4 & 0x000F       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     The six-digit hexadecimal representation of color of the form #RRGGBB.
     
     - parameter hex6: Six-digit hexadecimal value.
     */
     convenience init(hex6: UInt32, alpha: CGFloat = 1) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     The six-digit hexadecimal representation of color with alpha of the form #RRGGBBAA.
     
     - parameter hex8: Eight-digit hexadecimal value.
     */
     convenience init(hex8: UInt32) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex8 & 0xFF000000) >> 24) / divisor
        let green   = CGFloat((hex8 & 0x00FF0000) >> 16) / divisor
        let blue    = CGFloat((hex8 & 0x0000FF00) >>  8) / divisor
        let alpha   = CGFloat( hex8 & 0x000000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     The rgba string representation of color with alpha of the form #RRGGBBAA/#RRGGBB, throws error.
     
     - parameter rgba: String value.
     */
     convenience init(rgba_throws rgba: String) throws {
        guard rgba.hasPrefix("#") else {
            let error = UIColorInputError.missingHashMarkAsPrefix(rgba)
            print(error.localizedDescription)
            throw error
        }
        
        let hexString: String = String(rgba[String.Index(utf16Offset: 1, in: rgba)...])
        var hexValue:  UInt32 = 0
        
        guard Scanner(string: hexString).scanHexInt32(&hexValue) else {
            let error = UIColorInputError.unableToScanHexValue(rgba)
            print(error.localizedDescription)
            throw error
        }
        
        switch (hexString.count) {
        case 3:
            self.init(hex3: UInt16(hexValue))
        case 4:
            self.init(hex4: UInt16(hexValue))
        case 6:
            self.init(hex6: hexValue)
        case 8:
            self.init(hex8: hexValue)
        default:
            let error = UIColorInputError.mismatchedHexStringLength(rgba)
            print(error.localizedDescription)
            throw error
        }
    }
    
    /**
     The rgba string representation of color with alpha of the form #RRGGBBAA/#RRGGBB, fails to default color.
     
     - parameter rgba: String value.
     */
    convenience init(_ rgba: String, defaultColor: UIColor = UIColor.clear) {
        guard let color = try? UIColor(rgba_throws: rgba) else {
            self.init(cgColor: defaultColor.cgColor)
            return
        }
        self.init(cgColor: color.cgColor)
    }
    
    /**
     Hex string of a UIColor instance, throws error.
     
     - parameter includeAlpha: Whether the alpha should be included.
     */
    func hexStringThrows(_ includeAlpha: Bool = true) throws -> String  {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        guard r >= 0 && r <= 1 && g >= 0 && g <= 1 && b >= 0 && b <= 1 else {
            let error = UIColorInputError.unableToOutputHexStringForWideDisplayColor
            print(error.localizedDescription)
            throw error
        }
        
        if (includeAlpha) {
            return String(format: "#%02X%02X%02X%02X",
                          Int(round(r * 255)), Int(round(g * 255)),
                          Int(round(b * 255)), Int(round(a * 255)))
        } else {
            return String(format: "#%02X%02X%02X", Int(round(r * 255)),
                          Int(round(g * 255)), Int(round(b * 255)))
        }
    }
    
    /**
     Hex string of a UIColor instance, fails to empty string.
     
     - parameter includeAlpha: Whether the alpha should be included.
     */
    func hexString(_ includeAlpha: Bool = true) -> String  {
        guard let hexString = try? hexStringThrows(includeAlpha) else {
            return ""
        }
        return hexString
    }
    
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let iRed = (hex & 0xFF0000) >> 16
        let iGreen = ((hex & 0xFF00)) >> 8
        let iBlue = (hex & 0xFF)
        self.init(iRed: UInt8(iRed),
                  iGreen: UInt8(iGreen),
                  iBlue: UInt8(iBlue),
                  alpha: alpha)
    }
    convenience init(iRed: UInt8,
                    iGreen: UInt8,
                    iBlue: UInt8,
                    alpha: CGFloat = 1) {
        let red     = CGFloat(iRed) / 255.0
        let green   = CGFloat(iGreen) / 255.0
        let blue    = CGFloat(iBlue) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
}

public enum UIColorInputError: Error {
    
    case missingHashMarkAsPrefix(String)
    case unableToScanHexValue(String)
    case mismatchedHexStringLength(String)
    case unableToOutputHexStringForWideDisplayColor
}

extension UIColorInputError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .missingHashMarkAsPrefix(let hex):
            return "Invalid RGB string, missing '#' as prefix in \(hex)"
            
        case .unableToScanHexValue(let hex):
            return "Scan \(hex) error"
            
        case .mismatchedHexStringLength(let hex):
            return "Invalid RGB string from \(hex), number of characters after '#' should be either 3, 4, 6 or 8"
            
        case .unableToOutputHexStringForWideDisplayColor:
            return "Unable to output hex string for wide display color"
        }
    }
}


