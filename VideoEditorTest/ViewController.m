//
//  ViewController.m
//  VideoEditorTest
//
//  Created by 柴东鹏 on 16/7/31.
//  Copyright © 2016年 CDP. All rights reserved.
//

#import "ViewController.h"

#import "CDPVideoEditor.h"//import此.h文件

@interface ViewController (){
    NSInteger i;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor=[UIColor whiteColor];

    //异步导出视频成功通知(在导出视频时最好不要进行其他操作，防止失败)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exportSuccess) name:CDPVideoEditorExportSuccess object:nil];
    //视频存入本地照片库成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveSuccess) name:CDPVideoEditorSaveToLibrarySuccess object:nil];
    
    //改变i值进行不同测试(目前0为剪切视频,1为合并视频)
    i=0;
    
    UIButton *bt=[[UIButton alloc] initWithFrame:CGRectMake(20,100,200,100)];
    [bt setTitle:@"视频Editor" forState:UIControlStateNormal];
    [bt setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [bt addTarget:self action:@selector(editVideo) forControlEvents:UIControlEventTouchUpInside];
    bt.backgroundColor=[UIColor blackColor];
    [self.view addSubview:bt];
    
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - 部分通知,其余通知可在.h中查看
//导出视频成功
-(void)exportSuccess{
    NSLog(@"导出视频成功");
}
//存入本地照片库成功
-(void)saveSuccess{
    NSLog(@"视频存入本地照片库成功");
}
#pragma mark - 视频处理点击事件
-(void)editVideo{
    //path为本地视频路径
    NSString *onePath=[[NSBundle mainBundle] pathForResource:@"One" ofType:@"m4v"];
    NSString *twoPath=[[NSBundle mainBundle] pathForResource:@"Two" ofType:@"mp4"];
    
    switch (i) {
        case 0:{
            //视频剪切使用(具体使用看.h文件说明)
            //调用视频剪切api剪切该视频5s-10s
            [CDPVideoEditor trimWithVideoUrl:[NSURL fileURLWithPath:onePath]
                                       start:5
                                         end:8
                                  completion:^(BOOL success, NSString *error, AVAsset *asset) {
                
                                      if (success&&asset) {
                                          NSLog(@"剪切成功");
                                          //剪切成功后进行异步导出并存到本地照片库中,在导出视频时最好不要进行其他操作，防止失败(具体使用看.h文件说明)
                                          //各种结果可用NSNotificationCenter通知接收
                                          [CDPVideoEditor exportAsset:asset
                                                        saveToLibrary:YES
                                                        exportQuality:CDPVideoEditorExportMediumQuality];
                                      }
                                      else{
                                          NSLog(@"%@",error);
                                      }
                                  }];
        }
            break;
        case 1:{
            //视频合并使用(具体使用看.h文件说明)
            [CDPVideoEditor composeWithOriginalVideoUrl:[NSURL fileURLWithPath:onePath]
                                          otherVideoUrl:[NSURL fileURLWithPath:twoPath]
                                             completion:^(BOOL success, NSString *error, AVAsset *asset, AVMutableAudioMix *audioMix, AVMutableVideoComposition *videoComposition) {
                
                                                 if (success&&asset) {
                                                     NSLog(@"合并成功");
                                                     //合并成功后进行异步导出并存到本地照片库中,在导出视频时最好不要进行其他操作，防止失败(具体使用看.h文件说明)
                                                     //各种结果可用NSNotificationCenter通知接收
                                                     [CDPVideoEditor exportAsset:asset
                                                                        audioMix:audioMix
                                                                videoComposition:videoComposition
                                                                   saveToLibrary:YES
                                                                   exportQuality:CDPVideoEditorExportMediumQuality];
                                                 }
                                                 else{
                                                     NSLog(@"%@",error);
                                                 }
                
                                             }];
        }
            break;
        default:
            NSLog(@"请在viewDidLoad中对变量i赋予正确的值");
            break;
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
