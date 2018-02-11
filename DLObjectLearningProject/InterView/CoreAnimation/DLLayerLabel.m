//
//  DLLayerLabel.m
//  DLObjectLearningProject
//
//  Created by denglong on 11/02/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  如果你打算支持iOS 6及以上，基于CATextLayer的标签可能就有有些局限性。但是总得来说，如果想在app里面充分利用CALayer子类，用+layerClass来创建基于不同图层的视图是一个简单可复用的方法。
//  https://zsisme.gitbooks.io/ios-/content/chapter6/CATextLayer.html

#import "DLLayerLabel.h"

@implementation DLLayerLabel

+ (Class)layerClass{
    //this make our label create a CATextLayer  //instead of a regular CALayer for its backing layer
    return [CATextLayer class];
}
- (CATextLayer *)textLayer{
    return (CATextLayer *)self.layer;
}

- (void)setup{
    //set defaults from UILabel settings
    self.text = self.text;
    self.textColor = self.textColor;
    self.font = self.font;
    
    //we should really derive these from th UIlabel setting too
    //but that's complicated, so for now we'll just hard-code them
    [self textLayer].alignmentMode = kCAAlignmentJustified;
    [self textLayer].wrapped = YES;
    [self.layer display];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib{
    //called when creating label using Interface Builder
    [self setup];
}

- (void)setText:(NSString *)text{
    super.text = text;
    //set layer text
    [self textLayer].string = text;
}

- (void)setTextColor:(UIColor *)textColor{
    super.textColor = textColor;
    //set layer text color
    [self textLayer].foregroundColor = textColor.CGColor;
}

- (void)setFont:(UIFont *)font{
    super.font = font;
    //set layer font
    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    [self textLayer].font = fontRef;
    [self textLayer].fontSize = font.pointSize;
    CGFontRelease(fontRef);
}

@end
