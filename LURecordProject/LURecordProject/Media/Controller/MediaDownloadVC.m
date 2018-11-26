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
//  MediaDownloadVC.m
//  DookayProject
//
//  Created by dookay_73 on 2018/10/10.
//  Copyright © 2018年 Dookay. All rights reserved.
//

#import "MediaDownloadVC.h"
#import "MediaDownloadCell.h"
#import "DKDownloadTask.h"
#import "MediaDownloadModel.h"

#import "DKAVPlayer.h"
#import "DKFullScreenVC.h"

NSString *kMediaDownloadCell = @"MediaDownloadCell";

@interface MediaDownloadVC ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, assign) BOOL isDelete;



@property (nonatomic, strong) DKAVPlayer *avPlayer;
@property (nonatomic, strong) DKFullScreenVC *fullPlayer;

@end

@implementation MediaDownloadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"离线下载";
    _isDelete = NO;
    WS(weakSelf);
    [self setRightButtonWithTitle:@"编辑"
                            Image:@""
                    SelectedImage:@""
                           Action:^{
                               weakSelf.isDelete = !weakSelf.isDelete;
                               for (int i = 0; i < weakSelf.dataArray.count; i++) {
                                   NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                                   MediaDownloadCell *cell = (MediaDownloadCell *)[weakSelf.tableView cellForRowAtIndexPath:indexPath];
                                   cell.isDelete = weakSelf.isDelete;
                               }
                               
                           }];
    
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:kDownloadVideoList];
    _dataArray = [NSMutableArray array];
    for (int i = 0; i < array.count; i++) {
        NSDictionary *dic = array[i];
        MediaDownloadModel *model = [MediaDownloadModel yy_modelWithDictionary:dic];
        [_dataArray addObject:model];
    }
    [self.view addSubview:self.tableView];
    
    [self refreshDownloadCell];
    
}
#pragma mark - 下载状态刷新
- (void)refreshDownloadCell
{
    WS(weakSelf);
    [[DKDownloadTask taskShared] setRefreshSliderValueBlock:^(CGFloat value, CGFloat currentBytes, CGFloat totalBytes, NSString *videoUrl) {
        
        NSLog(@"%f__%f___%f___%@", value, currentBytes, totalBytes, videoUrl);
        for (int i = 0; i < weakSelf.dataArray.count; i++) {
            MediaDownloadModel *model = weakSelf.dataArray[i];
            
            if ([videoUrl rangeOfString:model.url].location != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                MediaDownloadCell *cell = (MediaDownloadCell *)[weakSelf.tableView cellForRowAtIndexPath:indexPath];
                NSString *str = [NSString stringWithFormat:@"缓存中：%.1f/%.1fMB", currentBytes, totalBytes];
                [cell refreshDownloadTaskInfoWithValue:value andBytesStr:str andTotalBytes:[NSString stringWithFormat:@"大小：%.1fMB", totalBytes]];
                break;
            }
        }
        
    }];
    
    [[DKDownloadTask taskShared] setRefreshDownloadSuccessCellBlock:^(NSString *videoUrl) {

        for (int i = 0; i < weakSelf.dataArray.count; i++) {
            MediaDownloadModel *model = weakSelf.dataArray[i];
            
            if ([videoUrl rangeOfString:model .url].location != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                MediaDownloadCell *cell = (MediaDownloadCell *)[weakSelf.tableView cellForRowAtIndexPath:indexPath];
                [cell refreshDownloadUI:YES];
                break;
            }
        }
    }];
}



#pragma mark - table View
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:kMediaDownloadCell];
    MediaDownloadModel *model = _dataArray[indexPath.row];
//    cell.videoName = dic[@"videoName"];
    cell.model = model;
    cell.isDelete = _isDelete;
    [cell refreshDownloadUI:model.isDownload];
    NSLog(@"[cellForRowAtIndexPath]model.fileName = %@",model.fileName);
    WS(weakSelf);
    [cell setDeleteCellBlock:^(MediaDownloadCell *cell) {
        NSInteger index = [weakSelf.tableView indexPathForCell:cell].row;
        [[DKDownloadTask taskShared] deleteDownloadVideoWithIndex:index];
        [weakSelf.dataArray removeObjectAtIndex:index];
        weakSelf.isDelete = NO;
        [weakSelf.tableView reloadData];
    }];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    MediaDownloadModel *model = _dataArray[indexPath.row];
    NSLog(@"model.url = %@",model.url);//下载地址
    NSLog(@"model.videoName = %@",model.videoName);//视频名称
    NSLog(@"model.isDownload = %d",model.isDownload);//是否下载完成
    NSLog(@"model.videoBytes = %lf",model.videoBytes);//视频大小
    NSLog(@"model.fileName = %@",model.fileName);//本地视频地址、名称
//    NSArray *paths1 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    //获取Caches中的缓存地址
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
//    NSString *docDir = [paths objectAtIndex:0];
//    NSLog(@"docDir = %@",docDir);
//    NSString *filePath1 = [docDir stringByAppendingPathComponent:@"fe86a70dc4b8497f828eaa19058639ba-6e51c667edc099f5b9871e93d0370245-sd.mp4"];
//    NSArray *array1 = [[NSArray alloc] initWithContentsOfFile:filePath1];
//    NSLog(@"array1 = %@",array1);
    
    
    [self setAVPlayer];
    NSString *UrlStr = model.fileName;
    NSLog(@"UrlStr = %@",UrlStr);
//    UrlStr = @"http://v.dansewudao.com/444fccb3590845a799459f6154d2833f/fe86a70dc4b8497f828eaa19058639ba-6e51c667edc099f5b9871e93d0370245-sd.mp4";
    self.avPlayer.mediaUrlStr = [NSString stringWithFormat:@"%@",UrlStr];
    [self.view addSubview:self.avPlayer];
    
    
    
    //删除操作
//    NSInteger index = indexPath.row;
//    NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kDownloadVideoList]];
//    NSDictionary *dataDic = [array objectAtIndex:index];
//    [array removeObjectAtIndex:index];
//    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:array] forKey:kDownloadVideoList];
//    NSString *filePath = dataDic[@"fileName"];
//    NSLog(@"filePath = %@",filePath);
//    BOOL isHave = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
//    NSLog(@"isHave = %d",isHave);
//    if (isHave) {
//        BOOL isDelte = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
//        if (isDelte) {
//            //            [array removeObjectAtIndex:index];
//            //            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:array] forKey:kDownloadVideoList];
//            NSLog(@"删除成功");
//        }else{
//            //            删除失败
//            NSLog(@"删除失败");
//        }
//    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}
#pragma mark - tableView
- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, mainWidth, mainHeight) style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = UIColorFromRGB(0xFFFFFF);
//        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = 96*ScaleX;
        
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        
        [_tableView registerClass:[MediaDownloadCell class]
           forCellReuseIdentifier:kMediaDownloadCell];
    }
    return _tableView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)setAVPlayer{
    _avPlayer = [[DKAVPlayer alloc] initWithFrame:CGRectMake(0, 60, mainWidth, mainWidth*9/16) andMediaURL:nil];
    _avPlayer.backgroundColor = UIColorFromRGB(0x1D1C1F);
    WS(weakSelf);
    [_avPlayer setClickedFullScreenBlock:^(BOOL isFullScreen) {
        if (isFullScreen) {
            weakSelf.avPlayer.isFullScreen = YES;
            weakSelf.fullPlayer = [[DKFullScreenVC alloc] init];
            [weakSelf.fullPlayer.view addSubview:weakSelf.avPlayer];
            weakSelf.avPlayer.frame = CGRectMake(0, 0, mainHeight, mainWidth);
            [weakSelf.tempbtn removeFromSuperview];
            [weakSelf presentViewController:weakSelf.fullPlayer animated:NO completion:nil];
        }else{
            weakSelf.avPlayer.isFullScreen = NO;
            [weakSelf.fullPlayer dismissViewControllerAnimated:NO completion:^{
                
                weakSelf.avPlayer.frame = CGRectMake(0, 0, mainWidth, 200*ScaleX);
                [weakSelf.tableView reloadData];
                
            }];
            
        }
    }];
}


-(void)dealloc{
    [self.avPlayer pausePlay];
    self.avPlayer =nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
