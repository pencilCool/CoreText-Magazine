# CoreText-Magazine

[demo](https://www.raywenderlich.com/4147/core-text-tutorial-for-ios-making-a-magazine-app) for CoreText

update to ARC

## 基本概念

####找到画板 ： 
  
 	CGContextRef context = UIGraphicsGetCurrentContext();
  
### 修剪画板：

	 CGMutablePathRef path = CGPathCreateMutable();
 	 CGPathAddRect(path, NULL, self.bounds );
    
### 调好画笔的颜色：

```
  	CTFramesetterRef framesetter = 
  	     CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString); 
  	
```
        
### 找到画板的区域位置
```
 CTFrameRef frame =
	        CTFramesetterCreateFrame(framesetter,
	            CFRangeMake(0, [attString length]), path, NULL);	                                           
```
   
            
### 开始画：

```
  CTFrameDraw(frame, context);  
```

### 清理裁剪工具， 画笔，和作画区域
- CFRelease(frame); 
- CFRelease(path);
- CFRelease(framesetter);
    
### 基本用法：
```
    作画分很多个区域来完成：
    while (textPos < [attString length]) { // 从头到尾画完
      ...
      //但是呢这些内容是在不同的区域内完成的。
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);//
        CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    ... 
    }
```  
### 复杂一点的加点图片
    
    
    
    
  
  
  
  
