//
//  RiskData.h
//  RiskCalc
//
//  Used to hold the data of a row in the risk table.
//
//  Created by Kailun Wu on 12/29/14.
//  Copyright (c) 2014 Kailun Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RiskData : NSObject

@property (strong) NSString *book;
@property double data2YR;
@property double data5YR;
@property double data10YR;
@property double data30YR;

@end
