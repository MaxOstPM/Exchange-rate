//
//  BankPlace.m
//  PrivatBank
//
//  Created by admin on 02.12.16.
//  Copyright © 2016 admin. All rights reserved.
//

#import "BankPlace.h"


@implementation BankPlace

- (void) setCoordinate:(CLLocationCoordinate2D)coordinate
{
    static UIImageView* bankomatLogo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bankomatLogo = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"map_icon"]];
    });
    
    _coordinate = coordinate;
    self.marker = [[GMSMarker alloc]init];
    self.marker.position = coordinate;
    self.marker.title = self.placeUa;
    self.marker.snippet = self.fullAddressUa;
    self.marker.iconView = bankomatLogo;
    self.marker.iconView.frame = CGRectMake(0, 0, 10, 10);
}

- (void) setType:(NSString *)type
{
    _type = nil;
    _type = type;
    
    if ([type isEqualToString:@"TSO"])
    {
        self.typeOfEnum = TSO;
    }
    else if ([type isEqualToString:@"ATM"])
    {
        self.typeOfEnum = ATM;
    }
    else if ([type isEqualToString:@"OFFICE"])
    {
        self.typeOfEnum = OFFICE;
    }

}

@end
