# CDPVideoEditor
An video editor,can trim a video or compose two video, and export video to the library.Details see demo.

## Trim an video
+(void)trimWithVideoUrl:(NSURL *)videoUrl start:(CGFloat)startTime end:(CGFloat)endTime completion:(void(^)(BOOL success,NSString *error,AVAsset *asset))block;

## Compose two video
+(void)composeWithOriginalVideoUrl:(NSURL *)originalVideoUrl otherVideoUrl:(NSURL *)otherVideoUrl completion:(void(^)(BOOL success,NSString *error,AVAsset *asset,AVMutableAudioMix *audioMix,AVMutableVideoComposition *videoComposition))block;
