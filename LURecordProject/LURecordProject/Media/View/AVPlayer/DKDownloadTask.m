//
/*****************************************
 *                                       *
 *  @dookay.com Internet make it happen  *
 *  ----------- -----------------------  *
 *  dddd  ddddd Internet make it happen  *
 *  o   o     o Internet make it happen  *
 *  k    k    k Internet make it happen  *
 *  a   a     a Internet make it happen  *
 *  yyyy  yyyyy Internet make it happen  *
 *  ----------- -----------------------  *
 *  Say hello to the future.		     *
 *  hello，未来。                   	     *
 *  未来をその手に。                        *
 *                                       *
 *****************************************/
//
//  DKDownloadTask.m
//  DookayProject
//
//  Created by dookay_73 on 2018/10/11.
//  Copyright © 2018年 Dookay. All rights reserved.
//

#import "DKDownloadTask.h"

@interface DKDownloadTask()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSMutableArray *videoList;

@end

@implementation DKDownloadTask

#pragma mark - 单例 -
+ (instancetype)taskShared {
    static id instace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instace = [[self alloc] init];
    });
    return instace;
}

- (void)startDownloadVideoWithModel:(MediaModel *)model
{

    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kDownloadVideoList]];
//    NSMutableArray *array = [NSMutableArray array];
    BOOL isAllowLoad = YES;
    for (NSDictionary *videoDic in array) {
        if ([model.downloadUrl isEqualToString:videoDic[@"url"]]) {
            isAllowLoad = NO;
            break;
        }
    }
    //如果视频已经存在，则返回不允许下载
    if (!isAllowLoad) {
        return;
    }

    NSDictionary *dic = @{@"url":model.downloadUrl,
                          @"videoName":model.title,
                          @"isDownload":@(NO),
                          @"videoBytes":@(0),
                          @"fileName":@""
                          };
    [array insertObject:dic atIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:array] forKey:kDownloadVideoList];
    _videoList = array;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    self.downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",  model.downloadUrl]]];
    [self.downloadTask resume];
}

- (void)deleteDownloadVideoWithIndex:(NSInteger)index
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kDownloadVideoList]];
    NSDictionary *dataDic = [array objectAtIndex:index];
    
    [array removeObjectAtIndex:index];
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:array] forKey:kDownloadVideoList];
    
    NSString *filePath = dataDic[@"fileName"];
    BOOL isHave = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (isHave) {
        BOOL isDelte = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        if (isDelte) {
//            [array removeObjectAtIndex:index];
//            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:array] forKey:kDownloadVideoList];
        }else{
//            删除失败
        }
    }
}
#pragma mark - delegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSString *videoUrl = downloadTask.response.URL.description;
    for (int i = 0; i < _videoList.count; i++) {
        NSDictionary *dic = _videoList[i];
        if ([videoUrl rangeOfString:dic[@"url"]].location != NSNotFound) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:dic];
            [dict setValue:@(totalBytesExpectedToWrite) forKey:@"videoBytes"];
            [_videoList replaceObjectAtIndex:i withObject:dict];
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:_videoList] forKey:kDownloadVideoList];
    
    //下载进度
    CGFloat progress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    dispatch_async(dispatch_get_main_queue(), ^{
        //进行UI操作  设置进度条
        //字节KB转MB
        self.refreshSliderValueBlock(progress, totalBytesWritten/1024/1024, totalBytesExpectedToWrite/1024/1024, videoUrl);
    });
}
//下载完成 保存到本地相册
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    //创建文件夹
    [self createDir];
    //1.拿到cache文件夹的路径
    NSString *cache=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
    //2,拿到cache文件夹和文件名
    NSString *filePath=[cache stringByAppendingPathComponent:[NSString stringWithFormat:@"videos/%@",downloadTask.response.suggestedFilename]];
    NSString *fileName = downloadTask.response.suggestedFilename;
    NSLog(@"location = %@\ncache = %@\nfilePath =%@\nfileName = %@\n",location,cache,filePath,fileName);
    //保存至缓存地址：cache
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:nil];

//    //3，保存视频到相册
//    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(file)) {
//        //保存相册核心代码
//        UISaveVideoAtPathToSavedPhotosAlbum(file, self, nil, nil);
//    }
    
    NSString *videoUrl = downloadTask.response.URL.description;
    
    for (int i = 0; i < _videoList.count; i++) {
        NSDictionary *dic = _videoList[i];
        if ([videoUrl rangeOfString:dic[@"url"]].location != NSNotFound) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:dic];
            [dict setValue:@(YES) forKey:@"isDownload"];
            [dict setValue:fileName forKey:@"fileName"];
            [_videoList replaceObjectAtIndex:i withObject:dict];
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:_videoList] forKey:kDownloadVideoList];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshDownloadSuccessCellBlock(videoUrl);
    });
}
#pragma mark 使用 NSHomeDirectory() 创建文件目录
- (void) createDir {
    
    // NSHomeDirectory()：应用程序目录， @"Library/Caches/videos"：在tmp文件夹下创建videos 文件夹
    NSString *filePath=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/videos"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    
    // fileExistsAtPath 判断一个文件或目录是否有效，isDirectory判断是否一个目录
    BOOL existed = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    
    if ( !(isDir == YES && existed == YES) ) {
        
        // 在 tmp 目录下创建一个 temp 目录
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSLog(@"+++++++++++++++++++%@",filePath);
}


@end
