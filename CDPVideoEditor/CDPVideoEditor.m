//
//  CDPVideoEditor.m
//  VideoEditorTest
//
//  Created by 柴东鹏 on 16/7/27.
//  Copyright © 2016年 CDP. All rights reserved.
//

#import "CDPVideoEditor.h"


#define CDPNotificationCenter [NSNotificationCenter defaultCenter]
#define CDPRadians( degrees ) (M_PI * ( degrees ) / 180.0 )


#ifdef DEBUG
#    define CDPLog(fmt,...) NSLog(fmt,##__VA_ARGS__)
#else
#    define CDPLog(fmt,...) /* */
#endif


@implementation CDPVideoEditor

#pragma mark - 视频合并
+(void)composeWithOriginalVideoUrl:(NSURL *)originalVideoUrl otherVideoUrl:(NSURL *)otherVideoUrl completion:(void (^)(BOOL, NSString *, AVAsset *, AVMutableAudioMix *, AVMutableVideoComposition *))block{
    if (originalVideoUrl==nil||[originalVideoUrl isKindOfClass:[NSNull class]]||otherVideoUrl==nil||[otherVideoUrl isKindOfClass:[NSNull class]]) {
        if (block) {
            block(NO,@"视频合并:传入的originalVideoUrl或otherVideoUrl为nil",nil,nil,nil);
        }
        return;
    }
    
    AVURLAsset *originalAsset = [[AVURLAsset alloc] initWithURL:originalVideoUrl options:nil];
    AVURLAsset *otherAsset = [[AVURLAsset alloc] initWithURL:otherVideoUrl options:nil];
    
    [self composeWithOriginalAVAsset:originalAsset otherAVAsset:otherAsset completion:block];
}
+(void)composeWithOriginalAVAsset:(AVAsset *)originalAsset otherAVAsset:(AVAsset *)otherAsset completion:(void(^)(BOOL success,NSString *error,AVAsset *asset,AVMutableAudioMix *audioMix,AVMutableVideoComposition *videoComposition))block{
    
    if (originalAsset==nil||[originalAsset isKindOfClass:[NSNull class]]||otherAsset==nil||[otherAsset isKindOfClass:[NSNull class]]) {
        if (block) {
            block(NO,@"视频合并:传入的originalAsset或otherAsset为nil",nil,nil,nil);
        }
        return;
    }
    
    CGFloat originalDuration=CMTimeGetSeconds([originalAsset duration]);
    CGFloat otherDuration=CMTimeGetSeconds([otherAsset duration]);
    
    //视频资源
    AVAssetTrack *originalVideoTrack = [self getAssetTrackWithMediaType:AVMediaTypeVideo asset:originalAsset];
    AVAssetTrack *otherVideoTrack = [self getAssetTrackWithMediaType:AVMediaTypeVideo asset:otherAsset];
    
    //音频资源
    AVAssetTrack *originalAudioTrack = [self getAssetTrackWithMediaType:AVMediaTypeAudio asset:originalAsset];
    AVAssetTrack *otherAudioTrack = [self getAssetTrackWithMediaType:AVMediaTypeAudio asset:otherAsset];
    
    AVMutableComposition *composition=[AVMutableComposition composition];
    NSError *error=nil;
    
    //合并音频
    AVMutableAudioMix *audioMix=nil;
    
    //original音频资源
    if (originalAudioTrack!=nil) {
        [self insertTrack:originalAudioTrack
            toComposition:composition
                mediaType:AVMediaTypeAudio
         preferredTrackID:kCMPersistentTrackID_Invalid
          insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(originalDuration,1))
                   atTime:kCMTimeZero
                    error:&error];
        
        if (error) {
            if (block) {
                block(NO,[NSString stringWithFormat:@"合并originalVideo音频资源出错:%@",error],nil,nil,nil);
            }
            return;
        }
    }
    else{
        CDPLog(@"视频合并:提供的originalVideo资源内部无音频资源或不支持该视频格式");
    }
    //other音频资源
    if (otherAudioTrack!=nil) {
        AVMutableCompositionTrack *audioTrack=[self insertTrack:otherAudioTrack
                                                  toComposition:composition
                                                      mediaType:AVMediaTypeAudio
                                               preferredTrackID:kCMPersistentTrackID_Invalid
                                                insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(otherDuration,1))
                                                         atTime:CMTimeMakeWithSeconds(originalDuration,1)
                                                          error:&error];
        
        if (error) {
            if (block) {
                block(NO,[NSString stringWithFormat:@"合并otherVideo音频资源出错:%@",error],nil,nil,nil);
            }
            return;
        }
        
        if (audioTrack) {
            AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
            [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:1 timeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(otherDuration,1))];
            
            audioMix=[AVMutableAudioMix audioMix];
            audioMix.inputParameters=@[mixParameters];
        }
    }
    else{
        CDPLog(@"视频合并:提供的otherVideo资源内部无音频资源或不支持该视频格式");
    }
    
    //合并视频
    AVMutableVideoComposition *videoComposition=nil;
    NSMutableArray *videoArr=[[NSMutableArray alloc] init];
    
    AVMutableVideoCompositionLayerInstruction *originalLayerInstruction=nil;
    AVMutableVideoCompositionLayerInstruction *otherLayerInstruction=nil;
    
    CGAffineTransform originalTransform;
    CGAffineTransform otherTransform;
    
    UIImageOrientation originalOrientation=UIImageOrientationUp;
    UIImageOrientation otherOrientation=UIImageOrientationUp;

    //original视频资源
    if (originalVideoTrack!=nil) {
        AVMutableCompositionTrack *videoTrack=[self insertTrack:originalVideoTrack
                                                  toComposition:composition
                                                      mediaType:AVMediaTypeVideo
                                               preferredTrackID:kCMPersistentTrackID_Invalid
                                                insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(originalDuration,1))
                                                         atTime:kCMTimeZero
                                                          error:&error];
        
        if (error) {
            if (block) {
                block(NO,[NSString stringWithFormat:@"合并originalVideo视频资源出错:%@",error],nil,nil,nil);
            }
            return;
        }
        
        if (videoTrack) {
            originalLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            //视频ImageOrientation方向
            originalOrientation=[self getUIImageOrientationWithAssetTrack:originalVideoTrack];
            
            //修正视频方向
            originalTransform=[self getTransformWithAssetTrack:originalVideoTrack imageOrientation:originalOrientation];
        }
    }
    else{
        CDPLog(@"视频合并:提供的originalVideo资源内部无视频资源或不支持该视频格式");
    }
    //other视频资源
    if (otherVideoTrack!=nil) {
        AVMutableCompositionTrack *videoTrack=[self insertTrack:otherVideoTrack
                                                  toComposition:composition
                                                      mediaType:AVMediaTypeVideo
                                               preferredTrackID:kCMPersistentTrackID_Invalid
                                                insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(otherDuration,1))
                                                         atTime:CMTimeMakeWithSeconds(originalDuration,1)
                                                          error:&error];
        
        if (error) {
            if (block) {
                block(NO,[NSString stringWithFormat:@"合并otherVideo视频资源出错:%@",error],nil,nil,nil);
            }
            return;
        }
        
        if (videoTrack) {
            otherLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            //视频ImageOrientation方向
            otherOrientation=[self getUIImageOrientationWithAssetTrack:otherVideoTrack];
            
            //修正视频方向
            otherTransform=[self getTransformWithAssetTrack:otherVideoTrack imageOrientation:otherOrientation];
        }
    }
    else{
        CDPLog(@"视频合并:提供的otherVideo资源内部无视频资源或不支持该视频格式");
    }
    
    CGFloat originalWidth;
    CGFloat originalHeight;
    CGFloat otherWidth;
    CGFloat otherHeight;
    
    BOOL isOriginalPortrait=NO,isOtherPortrait=NO;
    if (originalOrientation==UIImageOrientationDown||originalOrientation==UIImageOrientationUp) {
        isOriginalPortrait=YES;
    }
    if (otherOrientation==UIImageOrientationDown||otherOrientation==UIImageOrientationUp) {
        isOtherPortrait=YES;
    }
    
    if (isOriginalPortrait==YES&&isOtherPortrait==YES&&originalOrientation==otherOrientation) {
        //两个视频都竖直方向且相同
        originalWidth=originalVideoTrack.naturalSize.width;
        originalHeight=originalVideoTrack.naturalSize.height;
        otherWidth=otherVideoTrack.naturalSize.width;
        otherHeight=otherVideoTrack.naturalSize.height;
    }
    else{
        originalWidth=MIN(originalVideoTrack.naturalSize.width,originalVideoTrack.naturalSize.height);
        originalHeight=MAX(originalVideoTrack.naturalSize.width,originalVideoTrack.naturalSize.height);
        otherWidth=MIN(otherVideoTrack.naturalSize.width,otherVideoTrack.naturalSize.height);
        otherHeight=MAX(otherVideoTrack.naturalSize.width,otherVideoTrack.naturalSize.height);
    }
    
    //获得合成视频最终渲染size
    CGFloat renderWidth=MAX(originalWidth,otherWidth);
    CGFloat renderHeight=MAX(originalHeight,otherHeight);
    
    //判断是否存在originalLayerInstruction对象
    if (originalLayerInstruction) {
        CGFloat spanWidth=0;
        CGFloat spanHeight=0;
        
        if (renderWidth>originalWidth) {
            //与最终视频渲染宽度差
            spanWidth=renderWidth-originalWidth;
        }
        if (renderHeight>originalHeight) {
            //与最终视频渲染高度差
            spanHeight=renderHeight-originalHeight;
        }
        if (spanWidth!=0||spanHeight!=0) {
            CGAffineTransform t=originalTransform;
            originalTransform=CGAffineTransformTranslate(t,spanWidth/2,spanHeight/2);
        }
        
        [originalLayerInstruction setTransform:originalTransform atTime:kCMTimeZero];
        [originalLayerInstruction setOpacity:0 atTime:CMTimeMakeWithSeconds(originalDuration,1)];
        [videoArr addObject:originalLayerInstruction];
    }
    
    //判断是否存在otherLayerInstruction对象
    if (otherLayerInstruction) {
        CGFloat spanWidth=0;
        CGFloat spanHeight=0;
        
        if (renderWidth>otherWidth) {
            //与最终视频渲染宽度差
            spanWidth=renderWidth-otherWidth;
        }
        if (renderHeight>otherHeight) {
            //与最终视频渲染高度差
            spanHeight=renderHeight-otherHeight;
        }
        if (spanWidth!=0||spanHeight!=0) {
            CGAffineTransform t=otherTransform;
            otherTransform=CGAffineTransformTranslate(t,spanWidth/2,spanHeight/2);
        }
        
        [otherLayerInstruction setTransform:otherTransform atTime:CMTimeMakeWithSeconds(originalDuration-0.5,1)];
        [videoArr addObject:otherLayerInstruction];
    }
    
    //判断是否有LayerInstruction视频资源，有则合成
    if (videoArr.count>0) {
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange=CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(originalDuration+otherDuration,1));
        instruction.layerInstructions=videoArr;
        
        videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.instructions=[NSArray arrayWithObject:instruction];
        videoComposition.frameDuration = CMTimeMake(1,30);
        videoComposition.renderSize = CGSizeMake(renderWidth, renderHeight);
    }
    else{
        CDPLog(@"视频合并:提供的originalVideo和otherVideo资源内部都无视频资源,可能不支持视频格式");
    }
    
    
    if (block) {
        block(YES,@"",composition,audioMix,videoComposition);
    }
}
#pragma mark - 视频剪切
+(void)trimWithVideoUrl:(NSURL *)videoUrl start:(CGFloat)startTime end:(CGFloat)endTime completion:(void (^)(BOOL, NSString *, AVAsset *))block{
    if (videoUrl==nil||[videoUrl isKindOfClass:[NSNull class]]) {
        if (block) {
            block(NO,@"视频剪切:传入的videoUrl为nil",nil);
        }
        return;
    }
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    [self trimWithAVAsset:asset start:startTime end:endTime completion:block];
}
+(void)trimWithAVAsset:(AVAsset *)asset start:(CGFloat)startTime end:(CGFloat)endTime completion:(void(^)(BOOL success,NSString *error,AVAsset *asset))block{
    if (asset==nil||[asset isKindOfClass:[NSNull class]]) {
        if (block) {
            block(NO,@"视频剪切:传入的视频资源asset为nil",nil);
        }
        return;
    }
    if (startTime<0) {
        startTime=0;
    }
    
    if (startTime>=endTime) {
        if (block) {
            block(NO,@"视频剪切:startTime 大于 endTime",nil);
        }
        return;
    }
    
    //视频资源
    AVAssetTrack *assetVideoTrack = [self getAssetTrackWithMediaType:AVMediaTypeVideo asset:asset];
    //音频资源
    AVAssetTrack *assetAudioTrack = [self getAssetTrackWithMediaType:AVMediaTypeAudio asset:asset];
    
    //处理要剪切的视频时间段
    CGFloat assetDuration=CMTimeGetSeconds([asset duration]);
    if (startTime>=assetDuration) {
        if (block) {
            block(NO,[NSString stringWithFormat:@"参数startTime:%f 大于 视频总时间:%f,如果总时间为0,可能是不支持该视频格式",startTime,assetDuration],nil);
        }
        return;
    }
    CMTime startPoint=CMTimeMakeWithSeconds(startTime,1);
    CMTime trimmedDuration = (endTime>=assetDuration)?CMTimeMakeWithSeconds(assetDuration-startTime,1):CMTimeMakeWithSeconds(endTime-startTime,1);
    
    //composition对象主要是音频和视频组合
    AVMutableComposition *composition=[AVMutableComposition composition];
    NSError *error=nil;
    
    if(assetVideoTrack!=nil) {
        //composition添加视频资源
        [self insertTrack:assetVideoTrack
            toComposition:composition
                mediaType:AVMediaTypeVideo
         preferredTrackID:kCMPersistentTrackID_Invalid
          insertTimeRange:CMTimeRangeMake(startPoint,trimmedDuration)
                   atTime:kCMTimeZero
                    error:&error];
        
        if (error) {
            if (block) {
                block(NO,[NSString stringWithFormat:@"剪切视频资源出错:%@",error],nil);
            }
            return;
        }
    }
    else{
        CDPLog(@"视频剪切:提供的资源内部无视频资源或不支持该视频格式");
    }
    
    if(assetAudioTrack != nil) {
        //composition添加音频资源
        [self insertTrack:assetAudioTrack
            toComposition:composition
                mediaType:AVMediaTypeAudio
         preferredTrackID:kCMPersistentTrackID_Invalid
          insertTimeRange:CMTimeRangeMake(startPoint,trimmedDuration)
                   atTime:kCMTimeZero
                    error:&error];
        
        if (error) {
            if (block) {
                block(NO,[NSString stringWithFormat:@"剪切音频资源出错:%@",error],nil);
            }
            return;
        }
    }
    else{
        CDPLog(@"视频剪切:提供的资源内部无音频资源或不支持该视频格式");
    }
    
    if (block) {
        block(YES,@"",composition);
    }
}
#pragma mark - 视频添加水印
+(void)addWatermarkWithVideoUrl:(NSURL *)videoUrl image:(UIImage *)image frame:(CGRect)frame completion:(void (^)(BOOL, NSString *, AVAsset *, AVMutableVideoComposition *))block{
    if (videoUrl==nil||[videoUrl isKindOfClass:[NSNull class]]) {
        if (block) {
            block(NO,@"视频添加水印:传入的videoUrl为nil",nil,nil);
        }
        return;
    }
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    [self addWatermarkWithAVAsset:asset image:image frame:frame completion:block];
}
+(void)addWatermarkWithAVAsset:(AVAsset *)asset image:(UIImage *)image frame:(CGRect)frame completion:(void (^)(BOOL, NSString *, AVAsset *, AVMutableVideoComposition *))block{
    if (asset==nil||[asset isKindOfClass:[NSNull class]]) {
        if (block) {
            block(NO,@"视频添加水印:传入的视频资源asset为nil",nil,nil);
        }
        return;
    }
    //视频资源
    AVAssetTrack *assetVideoTrack = [self getAssetTrackWithMediaType:AVMediaTypeVideo asset:asset];
    //音频资源
    AVAssetTrack *assetAudioTrack = [self getAssetTrackWithMediaType:AVMediaTypeAudio asset:asset];
    
    CMTime startPoint=CMTimeMakeWithSeconds(0,1);
    
    //composition对象主要是音频和视频组合
    AVMutableComposition *composition=[AVMutableComposition composition];
    NSError *error=nil;
    
    if(assetVideoTrack!=nil) {
        //composition添加视频资源
        [self insertTrack:assetVideoTrack
            toComposition:composition
                mediaType:AVMediaTypeVideo
         preferredTrackID:kCMPersistentTrackID_Invalid
          insertTimeRange:CMTimeRangeMake(startPoint,[asset duration])
                   atTime:kCMTimeZero
                    error:&error];
        
        if (error) {
            if (block) {
                block(NO,[NSString stringWithFormat:@"视频添加水印:视频资源出错:%@",error],nil,nil);
            }
            return;
        }
    }
    else{
        CDPLog(@"视频添加水印:提供的资源内部无视频资源或不支持该视频格式");
    }
    
    if(assetAudioTrack != nil) {
        //composition添加音频资源
        [self insertTrack:assetAudioTrack
            toComposition:composition
                mediaType:AVMediaTypeAudio
         preferredTrackID:kCMPersistentTrackID_Invalid
          insertTimeRange:CMTimeRangeMake(startPoint,[asset duration])
                   atTime:kCMTimeZero
                    error:&error];
        
        if (error) {
            if (block) {
                block(NO,[NSString stringWithFormat:@"视频添加水印:音频资源出错:%@",error],nil,nil);
            }
            return;
        }
    }
    else{
        CDPLog(@"视频添加水印:提供的资源内部无音频资源或不支持该视频格式");
    }
    
    //检查composition中是否有视频资源
    AVMutableVideoComposition *videoComposition=nil;
    if ([[composition tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.frameDuration=CMTimeMake(1, 30);
        videoComposition.renderSize=assetVideoTrack.naturalSize;
        
        AVMutableVideoCompositionInstruction *instruction=[AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange=CMTimeRangeMake(kCMTimeZero,[composition duration]);
            
        AVAssetTrack *videoTrack=[composition tracksWithMediaType:AVMediaTypeVideo][0];
        AVMutableVideoCompositionLayerInstruction *layerInstruction=[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
        instruction.layerInstructions = @[layerInstruction];
        videoComposition.instructions = @[instruction];
        
        //创建水印背景layer
        CAShapeLayer *parentLayer=[CAShapeLayer layer];
        parentLayer.geometryFlipped=YES;
        parentLayer.frame=CGRectMake(0,0,videoComposition.renderSize.width,videoComposition.renderSize.height);
        
        CALayer *videoLayer=[CALayer layer];
        videoLayer.frame=CGRectMake(0,0,videoComposition.renderSize.width,videoComposition.renderSize.height);
        [parentLayer addSublayer:videoLayer];
        
        //创建水印        
        CALayer *watermarkLayer=[CALayer layer];
        watermarkLayer.contentsGravity=@"resizeAspect";
        watermarkLayer.frame=frame;
        watermarkLayer.contents=(__bridge id _Nullable)image.CGImage;
        [parentLayer addSublayer:watermarkLayer];
        
        videoComposition.animationTool=[AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }
    else{
        if (block) {
            block(NO,@"视频添加水印:提供的资源内部无视频资源或不支持该视频格式,无法添加水印",asset,nil);
        }
        return;
    }
    
    if (block) {
        block(YES,@"",composition,videoComposition);
    }
}
#pragma mark - 压缩视频导出
+(void)exportWithVideoUrl:(nonnull NSURL *)videoUrl saveToLibrary:(BOOL)isSave exportQuality:(CDPVideoEditorExportQuality)exportQuality{
    if (videoUrl==nil||[videoUrl isKindOfClass:[NSNull class]]) {
        CDPLog(@"视频压缩导出:传入的videoUrl为nil");
        [CDPNotificationCenter postNotificationName:CDPVideoEditorExportFail object:@"视频压缩导出:传入的videoUrl为nil"];
        return;
    }
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    [self exportAsset:asset audioMix:nil videoComposition:nil saveToLibrary:isSave exportQuality:exportQuality];
}
+(void)exportAsset:(nonnull AVAsset *)asset saveToLibrary:(BOOL)isSave exportQuality:(CDPVideoEditorExportQuality)exportQuality{
    [self exportAsset:asset audioMix:nil videoComposition:nil saveToLibrary:isSave exportQuality:exportQuality];
}
+(void)exportAsset:(nonnull AVAsset *)asset audioMix:(nullable AVMutableAudioMix *)audioMix videoComposition:(nullable AVMutableVideoComposition *)videoComposition saveToLibrary:(BOOL)isSave exportQuality:(CDPVideoEditorExportQuality)exportQuality{
    
    if (asset==nil||[asset isKindOfClass:[NSNull class]]) {
        CDPLog(@"视频压缩导出:传入的AVAsset为nil");
        [CDPNotificationCenter postNotificationName:CDPVideoEditorExportFail object:@"视频压缩导出:传入的AVAsset为nil"];
        return;
    }
    
    //创建导出路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *outputURL = paths[0];
    
    NSFileManager *manager=[NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    
    outputURL=[outputURL stringByAppendingPathComponent:@"CDPVideoEditorOutput.mp4"];
    //移除文件
    [manager removeItemAtPath:outputURL error:nil];
    
    
    //根据asset对象创建exportSession视频导出对象
    AVAssetExportSession *exportSession=[[AVAssetExportSession alloc] initWithAsset:asset presetName:[self getVideoExportQuality:exportQuality]];
    //音频混合器
    exportSession.audioMix=audioMix;
    //视频组合器
    exportSession.videoComposition=videoComposition;
    //视频导出路径
    exportSession.outputURL=[NSURL fileURLWithPath:outputURL];
    //导出格式
    exportSession.outputFileType=AVFileTypeMPEG4;
    
    //开始异步导出
    [[UIApplication sharedApplication] delegate].window.userInteractionEnabled=NO;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        [[UIApplication sharedApplication] delegate].window.userInteractionEnabled=YES;
        
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
                //导出成功
                [CDPNotificationCenter postNotificationName:CDPVideoEditorExportSuccess object:[NSURL fileURLWithPath:outputURL]];
                if (isSave==YES) {
                    [self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outputURL]];
                }
                break;
            case AVAssetExportSessionStatusFailed:
                //导出失败
                CDPLog(@"视频压缩导出失败error:%@",exportSession.error);
                [CDPNotificationCenter postNotificationName:CDPVideoEditorExportFail object:[NSString stringWithFormat:@"%@",exportSession.error]];
                break;
            case AVAssetExportSessionStatusCancelled:
                //导出取消
                CDPLog(@"视频压缩导出取消error:%@",exportSession.error);
                [CDPNotificationCenter postNotificationName:CDPVideoEditorExportCancel object:[NSString stringWithFormat:@"%@",exportSession.error]];
                break;
            default:
                break;
        }
    }];
}
#pragma mark - 根据视频url地址将其保存到本地照片库
+(void)writeVideoToPhotoLibrary:(nonnull NSURL *)url{
    if (url==nil||[url isKindOfClass:[NSNull class]]) {
        CDPLog(@"视频保存到本地照片库:传入的视频url为nil");
        [CDPNotificationCenter postNotificationName:CDPVideoEditorSaveToLibraryFail object:@"视频保存到本地照片库:传入的视频url为nil"];
        return;
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success==YES) {
            [CDPNotificationCenter postNotificationName:CDPVideoEditorSaveToLibrarySuccess object:url];
        }
        else{
            CDPLog(@"视频保存到本地照片库失败error:%@",error);
            [CDPNotificationCenter postNotificationName:CDPVideoEditorSaveToLibraryFail object:[NSString stringWithFormat:@"%@",error]];
        }
    }];
}
#pragma mark - 其他相关方法
//根据videoTrack获得视频方向
+(UIImageOrientation)getUIImageOrientationWithAssetTrack:(nonnull AVAssetTrack *)assetTrack{
    CGAffineTransform transform=assetTrack.preferredTransform;

    if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
        //UIImageOrientationLeft
        return UIImageOrientationLeft;
    }
    else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0) {
        //UIImageOrientationRight
        return UIImageOrientationRight;
    }
    else if (transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0) {
        //UIImageOrientationUp
        return UIImageOrientationUp;
    }
    else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {
        //UIImageOrientationDown
        return UIImageOrientationDown;
    }
    else{
        return UIImageOrientationUp;
    }
}
//根据AVAssetTrack等参数获得视频正确的transform
+(CGAffineTransform)getTransformWithAssetTrack:(nonnull AVAssetTrack *)assetTrack imageOrientation:(UIImageOrientation)orientation{
    CGAffineTransform transform=assetTrack.preferredTransform;
    
    if (orientation==UIImageOrientationLeft) {
        CGAffineTransform t = CGAffineTransformMakeTranslation(assetTrack.naturalSize.height,0.0);
        transform = CGAffineTransformRotate(t,CDPRadians(90.0));
    }
    else if (orientation==UIImageOrientationRight) {
        CGAffineTransform t = CGAffineTransformMakeTranslation(-assetTrack.naturalSize.height,0.0);
        transform = CGAffineTransformRotate(t,CDPRadians(270.0));
    }
    else if (orientation==UIImageOrientationUp) {
    }
    else if (orientation==UIImageOrientationDown) {
        CGAffineTransform t = CGAffineTransformMakeTranslation(assetTrack.naturalSize.width,assetTrack.naturalSize.height);
        transform = CGAffineTransformRotate(t,CDPRadians(180.0));
    }
    
    
    return transform;
}
//根据指定mediaType类型获得asset内相关资源
+(AVAssetTrack *)getAssetTrackWithMediaType:(NSString *)mediaType asset:(AVAsset *)asset{
    if ([[asset tracksWithMediaType:mediaType] count] != 0) {
        return [asset tracksWithMediaType:mediaType][0];
    }
    else{
        return nil;
    }
}
//给Composition添加资源
+(AVMutableCompositionTrack *)insertTrack:(AVAssetTrack *)assetTrack toComposition:(AVMutableComposition *)composition mediaType:(NSString *)mediaType preferredTrackID:(CMPersistentTrackID)trackID insertTimeRange:(CMTimeRange)timeRange atTime:(CMTime)atTime error:(NSError * __nullable * __nullable)error{
    
    if (composition&&assetTrack) {
        AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:mediaType preferredTrackID:trackID];
        
        //添加资源的timeRange时间段到composition对象的atTime时间点
        [compositionTrack insertTimeRange:timeRange ofTrack:assetTrack atTime:atTime error:error];
        
        return compositionTrack;
    }
    else{
        return nil;
    }
}
//根据CDPVideoEditorExportQuality获得所需视频质量
+(NSString *)getVideoExportQuality:(CDPVideoEditorExportQuality)quality{
    switch (quality) {
        case CDPVideoEditorExportQuality960x540:
            return AVAssetExportPreset960x540;
            break;
        case CDPVideoEditorExportQuality640x480:
            return AVAssetExportPreset640x480;
            break;
        case CDPVideoEditorExportQuality1280x720:
            return AVAssetExportPreset1280x720;
            break;
        case CDPVideoEditorExportQuality1920x1080:
            return AVAssetExportPreset1920x1080;
            break;
        case CDPVideoEditorExportQuality3840x2160:
            return AVAssetExportPreset3840x2160;
            break;
        case CDPVideoEditorExportLowQuality:
            return AVAssetExportPresetLowQuality;
            break;
        case CDPVideoEditorExportHighQuality:
            return AVAssetExportPresetHighestQuality;
        default:
            return AVAssetExportPresetMediumQuality;
            break;
    }
}

@end
