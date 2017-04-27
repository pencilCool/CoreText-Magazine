//
//  CTView.m
//  CoreTextMagazine
//
//  Created by Marin Todorov on 8/11/11.
//  Copyright 2011 Marin Todorov. All rights reserved.
//

#import "CTView.h"
#import <CoreText/CoreText.h>
#import "MarkupParser.h"
#import "CTColumnView.h"

@implementation CTView

@synthesize attString;
@synthesize frames;
@synthesize images;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)buildFrames
{
    frameXOffset = 20; //1
    frameYOffset = 20;
    self.pagingEnabled = YES;
    self.delegate = self;
    self.frames = [NSMutableArray array];
    
    CGMutablePathRef path = CGPathCreateMutable(); //2
    CGRect textFrame = CGRectInset(self.bounds, frameXOffset, frameYOffset);
    CGPathAddRect(path, NULL, textFrame );
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    
    int textPos = 0; //3
    int columnIndex = 0;
    
    while (textPos < [attString length]) { //4
        CGPoint colOffset = CGPointMake( (columnIndex+1)*frameXOffset + columnIndex*(textFrame.size.width/2), 20 );
        CGRect colRect = CGRectMake(0, 0 , textFrame.size.width/2-10, textFrame.size.height-40);
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, colRect);
        
        //use the column path
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);
        CFRange frameRange = CTFrameGetVisibleStringRange(frame); //5
        
        //create an empty column view
        CTColumnView* content = [[[CTColumnView alloc] initWithFrame: CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)] autorelease];
        content.backgroundColor = [UIColor clearColor];
        content.frame = CGRectMake(colOffset.x, colOffset.y, colRect.size.width, colRect.size.height) ;
        
		//set the column view contents and add it as subview
        [content setCTFrame:(__bridge id)frame];  //6  
        [self attachImagesWithFrame:frame inColumnView: content];
        [self.frames addObject: (id)frame];
        [self addSubview: content];
        
        //prepare for next frame
        textPos += frameRange.length;
        
        //CFRelease(frame);
        CFRelease(path);
        
        columnIndex++;
    }
    
    //set the total width of the scroll view
    int totalPages = (columnIndex+1) / 2; //7
    self.contentSize = CGSizeMake(totalPages*self.bounds.size.width, textFrame.size.height);
}

-(void)setAttString:(NSAttributedString *)string withImages:(NSArray*)imgs
{
    self.attString = string;
    self.images = imgs;
}

-(void)attachImagesWithFrame:(CTFrameRef)f inColumnView:(CTColumnView*)col
{
    //drawing images
    NSArray *lines = (NSArray *)CTFrameGetLines(f); //1 获得这一帧率中的行数
    
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(f, CFRangeMake(0, 0), origins); //2 获得这一帧中，最上面的一行的起点位置
    
    int imgIndex = 0; //3  获取图片和 图片的位置信息   ，图片会被一张一张安置。imageIndex = 0 以为这当前被安置的个数为 0。
    NSDictionary* nextImage = [self.images objectAtIndex:imgIndex];
    int imgLocation = [[nextImage objectForKey:@"location"] intValue];
    
    //find images for the current column
    CFRange frameRange = CTFrameGetVisibleStringRange(f); //4 获取当前帧中能看到的可见 字符的范围。
    while ( imgLocation < frameRange.location ) {   //在文字被显示的范围里面找，看图片是不是在这个范围里面出现了。
        imgIndex++;
        if (imgIndex>=[self.images count]) return; //quit if no images for this column
        nextImage = [self.images objectAtIndex:imgIndex];
        imgLocation = [[nextImage objectForKey:@"location"] intValue];// 遍历的是图片的位置，而不是当前显示的文字的位置。
    }
    
    NSUInteger lineIndex = 0;
    for (id lineObj in lines) { //5   一帧 中， 一行一行的来处理。
        CTLineRef line = (__bridge CTLineRef)lineObj;
        
        for (id runObj in (NSArray *)CTLineGetGlyphRuns(line)) { //6
            CTRunRef run = (__bridge CTRunRef)runObj;
            CFRange runRange = CTRunGetStringRange(run);
            
            if ( runRange.location <= imgLocation && runRange.location+runRange.length > imgLocation ) { //7  看看图片插入的位置是不是在扎个run 中间。
	            CGRect runBounds;
	            CGFloat ascent;//height above the baseline
	            CGFloat descent;//height below the baseline
	            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL); //8 获取run 的宽和高
	            runBounds.size.height = ascent + descent;
                
	            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL); //9 获取run的原点
	            runBounds.origin.x = origins[lineIndex].x + self.frame.origin.x + xOffset + frameXOffset;
	            runBounds.origin.y = origins[lineIndex].y + self.frame.origin.y + frameYOffset;
	            runBounds.origin.y -= descent;
                
                UIImage *img = [UIImage imageNamed: [nextImage objectForKey:@"fileName"] ];
                CGPathRef pathRef = CTFrameGetPath(f); //10
                CGRect colRect = CGPathGetBoundingBox(pathRef);
                
                // 根据 run 的原点 和尺寸 和图片的尺寸 ，确定 图片的frame 。我比较好奇的是，新的frame 会不会导致图片超出屏幕尺寸？
                // 其实应该是不会的，colRect.origin 是这一帧中左上角的点。
                CGRect imgBounds = CGRectOffset(runBounds, colRect.origin.x - frameXOffset - self.contentOffset.x, colRect.origin.y - frameYOffset - self.frame.origin.y);
                [col.images addObject: //11
                 [NSArray arrayWithObjects:img, NSStringFromCGRect(imgBounds) , nil]
                 ]; 
                //load the next image //12
                imgIndex++;
                if (imgIndex < [self.images count]) {
                    nextImage = [self.images objectAtIndex: imgIndex];
                    imgLocation = [[nextImage objectForKey: @"location"] intValue];
                }
                
            }
        }
        lineIndex++;
    }
}

-(void)dealloc
{
    self.attString = nil;
    self.frames = nil;
    self.images = nil;
    [super dealloc];
}

@end
