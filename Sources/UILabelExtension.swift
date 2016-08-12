// FittableLabel.swift
//
// Copyright (c) 2016 Tom Baranes (https://github.com/tbaranes)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public extension UILabel {
    
    /**
     Resize the font to make the current text fit the label frame.
     
     - parameter maxFontSize:  The max font size available
     - parameter minFontScale: The min font scale that the font will have
     - parameter rectSize:     Rect size where the label must fit
     */
    public func fontSizeToFit(maxFontSize maxFontSize: CGFloat = 100, minFontScale: CGFloat = 0.1,rectSize: CGSize? = nil) {
        let maxFontSize = maxFontSize.isNaN ? 100 : maxFontSize
        let minFontScale = minFontScale.isNaN ? 0.1 : minFontScale
        let rectSize = rectSize ?? bounds.size
        fontSizeToFit(maxFontSize: maxFontSize, minimumFontScale: minFontScale, rectSize: rectSize)
    }
    
    /**
     Returns a font size of a specific string in a specific font that fits a specific size
     
     - parameter text:         The text to use
     - parameter maxFontSize:  The max font size available
     - parameter minFontScale: The min font scale that the font will have
     - parameter rectSize:     Rect size where the label must fit
     */
    public func fontSizeThatFits(text string: String, maxFontSize: CGFloat = CGFloat.NaN, minFontScale: CGFloat = 0.1,rectSize: CGSize? = nil) -> CGFloat {
        let maxFontSize = maxFontSize.isNaN ? 100 : maxFontSize
        let minFontScale = minFontScale.isNaN ? 0.1 : minFontScale
        let minimumFontSize = maxFontSize * minFontScale
        let rectSize = rectSize ?? bounds.size
        guard string.characters.count != 0 else {
            return self.font.pointSize
        }


        let constraintSize = numberOfLines == 1 ? CGSize(width: CGFloat.max, height: rectSize.height) : CGSize(width: rectSize.width, height: CGFloat.max)
        return binarySearch(string, minSize: minimumFontSize, maxSize: maxFontSize, size: rectSize, constraintSize: constraintSize)
    }

}

// MARK: - Helpers

private extension UILabel {

    func fontSizeToFit(maxFontSize maxFontSize: CGFloat, minimumFontScale: CGFloat, rectSize: CGSize) {
        guard let unwrappedText = self.text else {
            return
        }

        let newFontSize = fontSizeThatFits(text: unwrappedText, maxFontSize: maxFontSize, minFontScale: minimumFontScale, rectSize: rectSize)
        font = font.fontWithSize(newFontSize)
    }
    
    func currentAttributedStringAttributes() -> [String : AnyObject] {
        var newAttributes = [String: AnyObject]()
        attributedText?.enumerateAttributesInRange(NSRange(0..<(text?.characters.count ?? 0)), options: .LongestEffectiveRangeNotRequired, usingBlock: { attributes, range, stop in
            newAttributes = attributes
        })
        return newAttributes
    }

}

// MARK: - Search

private extension UILabel {

    enum FontSizeState {
        case Fit, TooBig, TooSmall
    }

    func binarySearch(string: String, minSize: CGFloat, maxSize: CGFloat, size: CGSize, constraintSize: CGSize) -> CGFloat {
        guard maxSize > minSize else {
            return maxSize
        }

        let fontSize = (minSize + maxSize) / 2;
        var attributes = currentAttributedStringAttributes()
        attributes[NSFontAttributeName] = font.fontWithSize(fontSize)

        let rect = string.boundingRectWithSize(constraintSize, options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
        let state = numberOfLines == 1 ? singleLineSizeState(rect, size: size) : multiLineSizeState(rect, size: size)
        switch state {
        case .Fit: return fontSize
        case .TooBig: return binarySearch(string, minSize: minSize, maxSize: maxSize - 1, size: size, constraintSize: constraintSize)
        case .TooSmall: return binarySearch(string, minSize: fontSize + 1, maxSize: maxSize, size: size, constraintSize: constraintSize)
        }
    }

    func singleLineSizeState(rect: CGRect, size: CGSize) -> FontSizeState {
        if rect.width >= size.width + 10 && rect.width <= size.width {
            return .Fit
        } else if rect.width > size.width {
            return .TooBig
        } else {
            return .TooSmall
        }
    }

    func multiLineSizeState(rect: CGRect, size: CGSize) -> FontSizeState {
        if rect.height >= size.height + 10 && rect.height <= size.height {
            return .Fit
        } else if rect.height > size.height {
            return .TooBig
        } else {
            return .TooSmall
        }
    }

}