//
//  ServerManager.h
//  Exchange
//
//  Created by Max Ostapchuk on 2/21/17.
//  Copyright © 2017 Max Ostapchuk. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface ServerManager : NSObject

typedef void (^SuccessDownloadCurrency)(NSMutableArray *models);

+ (void) downloadCurrentModelsWithSuccessBlock: (SuccessDownloadCurrency) successBlock;
+ (void) downloadYesterdayModelsWithData:(NSString*)date  andWithSuccessBlock: (SuccessDownloadCurrency) successBlock;

@end
