//
//  CDPVideoEditor.h
//  VideoEditorTest
//
//  Created by 柴东鹏 on 16/7/27.
//  Copyright © 2016年 CDP. All rights reserved.
//
//https://github.com/cdpenggod/CDPVideoEditor.git

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

//相关Notification通知

//视频保存到本地照片库成功(object为视频url)
#define CDPVideoEditorSaveToLibrarySuccess @"CDPVideoEditorSaveToLibrarySuccess"

//视频保存到本地照片库失败(object为错误信息)
#define CDPVideoEditorSaveToLibraryFail @"CDPVideoEditorSaveToLibraryFail"

//导出视频成功(object为视频url)
#define CDPVideoEditorExportSuccess @"CDPVideoEditorExportSuccess"

//导出视频失败(object为错误信息)
#define CDPVideoEditorExportFail @"CDPVideoEditorExportFail"

//导出视频取消(object为错误信息)
#define CDPVideoEditorExportCancel @"CDPVideoEditorExportCancel"


typedef enum{
    CDPVideoEditorExportMediumQuality=0,//中等质量(默认)
    CDPVideoEditorExportLowQuality,//低等质量
    CDPVideoEditorExportHighQuality,//高等质量
    CDPVideoEditorExportQuality640x480,//640x480尺寸
    CDPVideoEditorExportQuality960x540,//960x540尺寸
    CDPVideoEditorExportQuality1280x720,//1280x720尺寸
    CDPVideoEditorExportQuality1920x1080,//1920x1080尺寸
    CDPVideoEditorExportQuality3840x2160,//3840x2160尺寸
}CDPVideoEditorExportQuality;//导出视频质量(质量越高则在导出时花费时间越长)




@interface CDPVideoEditor : NSObject


/**
 *  合并视频(合并失败asset返回nil)
 *  originalVideoUrl 被合并入的视频URL(合并后首先播放)
 *  otherVideoUrl 要合并进OriginalVideo的视频URL(合并后在originalVideo后面播放)
 *  completion 执行结束block回调
 *  如果有一个视频的ImageOrientation为UIImageOrientationDown向下,而另一个并非UIImageOrientationDown向下,则合成后播放到ImageOrientationDown视频时，仍能正常播放和全部显示，只是其中心位置有可能不在屏幕中心
 */
+(void)composeWithOriginalVideoUrl:(NSURL *)originalVideoUrl otherVideoUrl:(NSURL *)otherVideoUrl completion:(void(^)(BOOL success,NSString *error,AVAsset *asset,AVMutableAudioMix *audioMix,AVMutableVideoComposition *videoComposition))block;
/**
 *  参考composeWithOriginalVideoUrl: otherVideoUrl: completion:类方法
 *  AVAsset 需要剪切的视频资源
 */
+(void)composeWithOriginalAVAsset:(AVAsset *)originalAsset otherAVAsset:(AVAsset *)otherAsset completion:(void(^)(BOOL success,NSString *error,AVAsset *asset,AVMutableAudioMix *audioMix,AVMutableVideoComposition *videoComposition))block;


/**
 *  剪切视频(剪切失败asset返回nil)
 *  videoUrl 视频URL
 *  startTime 剪切开始时间(小于0则自动变为0)
 *  endTime 剪切结束时间(大于视频总时间则自动变为视频总时间数)
 *  completion 执行结束block回调
 */
+(void)trimWithVideoUrl:(NSURL *)videoUrl start:(CGFloat)startTime end:(CGFloat)endTime completion:(void(^)(BOOL success,NSString *error,AVAsset *asset))block;
/**
 *  参考trimWithVideoUrl: start: end: completion:类方法
 *  AVAsset 需要剪切的视频资源
 */
+(void)trimWithAVAsset:(AVAsset *)asset start:(CGFloat)startTime end:(CGFloat)endTime completion:(void(^)(BOOL success,NSString *error,AVAsset *asset))block;


/**
 *  压缩导出视频(在进行异步压缩导出视频时会禁止用户屏幕交互,否则可能导致失败,exportQuality质量越高所耗时间越长)
 *  videoUrl 视频URL
 *  isSave 压缩导出视频后是否自动保存到本地照片库
 *  exportQuality 压缩导出视频质量
 */
+(void)exportWithVideoUrl:(nonnull NSURL *)videoUrl saveToLibrary:(BOOL)isSave exportQuality:(CDPVideoEditorExportQuality)exportQuality;

/**
 *  参考exportAsset: saveToLibrary: exportQuality:类方法
 *  asset 视频Asset对象
 *  audioMix 音频混合器
 *  videoComposition 视频混合器
 */
+(void)exportAsset:(nonnull AVAsset *)asset saveToLibrary:(BOOL)isSave exportQuality:(CDPVideoEditorExportQuality)exportQuality;
+(void)exportAsset:(nonnull AVAsset *)asset audioMix:(nullable AVMutableAudioMix *)audioMix videoComposition:(nullable AVMutableVideoComposition *)videoComposition saveToLibrary:(BOOL)isSave exportQuality:(CDPVideoEditorExportQuality)exportQuality;

/**
 *  根据视频url地址将其保存到本地照片库
 */
+(void)writeVideoToPhotoLibrary:(nonnull NSURL *)url;






@end
