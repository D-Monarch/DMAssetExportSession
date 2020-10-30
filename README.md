# DMAssetExportSession

#import <LBAssetExportSession/LBAssetExportSession.h>
 
  
    //网络配置  
    //1、同时配置baseUrl和path      
    [LBNetworkConfig shareConfig].baseUrl = @"http://10.20.7.142:8091/web-2/";
    [LBNetworkConfig shareConfig].path = @"workorder/file/upload.do";
 
    //2、只配置path
    [LBNetworkConfig shareConfig].path = @"http://10.20.7.142:8091/web-2/workorder/file/upload.do";
 
 
    //不配置 1、2情况下，默认取params中的url
 
 
 
    [[LBMediaManager shareManaegr] handleMediaWithParams:params
                                                 headers:headers
                                                complete:^(NSString * _Nonnull result) {
 
    }];
