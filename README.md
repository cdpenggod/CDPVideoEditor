# CDPVideoEditor视频编辑
An video editor,can trim a video or compose two video, and export video to the library.Details see demo.

# Simple instructions

## Trim an video视频剪切
+(void)trimWithVideoUrl:(NSURL *)videoUrl start:(CGFloat)startTime end:(CGFloat)endTime completion:(void(^)(BOOL success,NSString *error,AVAsset *asset))block;

## Compose two video视频合并
+(void)composeWithOriginalVideoUrl:(NSURL *)originalVideoUrl otherVideoUrl:(NSURL *)otherVideoUrl completion:(void(^)(BOOL success,NSString *error,AVAsset *asset,AVMutableAudioMix *audioMix,AVMutableVideoComposition *videoComposition))block;

## Add watermark to video视频添加水印
+(void)addWatermarkWithVideoUrl:(NSURL *)videoUrl image:(UIImage *)image frame:(CGRect)frame completion:(void(^)(BOOL success,NSString *error,AVAsset *asset,AVMutableVideoComposition *videoComposition))block;

## Compressed and Export video视频压缩导出
+(void)exportWithVideoUrl:(nonnull NSURL *)videoUrl saveToLibrary:(BOOL)isSave exportQuality:(CDPVideoEditorExportQuality)exportQuality;

## Write an video to photo library视频导出到本地照片库
+(void)writeVideoToPhotoLibrary:(nonnull NSURL *)url;
