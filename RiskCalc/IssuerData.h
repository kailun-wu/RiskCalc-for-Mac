//
//  IssuerData.h
//  RiskCalc
//
//  Used to hold the data of a row in the issuer table.
//
//  Created by Kailun Wu on 12/29/14.
//  Copyright (c) 2014 Kailun Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IssuerData : NSObject

@property (strong) NSString *issuer;
@property int amount;
@property double risk;
@property double LGD;

- (id)initWithIssuer:(NSString *)issuer;

@end
