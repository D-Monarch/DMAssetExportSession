# DMAssetExportSession

#import <DMAssetExportSession/DMAssetExportSession.h>
 
  
    //网络配置  
    //1、同时配置baseUrl和path      
    [DMNetworkConfig shareConfig].baseUrl = @"http://10.20.7.142:8091/web-2/";
    [DMNetworkConfig shareConfig].path = @"workorder/file/upload.do";
 
    //2、只配置path
    [DMNetworkConfig shareConfig].path = @"http://10.20.7.142:8091/web-2/workorder/file/upload.do";
 
 
    //不配置 1、2情况下，默认取params中的url
 
 
 
    [[DMMediaManager shareManaegr] handleMediaWithParams:params
                                                 headers:headers
                                                complete:^(NSString * _Nonnull result) {
 
    }];
