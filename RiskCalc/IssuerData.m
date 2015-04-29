//
//  IssuerData.m
//  RiskCalc
//
//  Created by Kailun Wu on 12/29/14.
//  Copyright (c) 2014 Kailun Wu. All rights reserved.
//

#import "IssuerData.h"

@implementation IssuerData

- (id)init {
    self.issuer = @"Issuer";
    self.amount = 0;
    self.risk = 0.0;
    self.LGD = 0.0;
    return self;
}

- (id)initWithIssuer:(NSString *)issuer {
    self.issuer = issuer;
    self.amount = 0;
    self.risk = 0.0;
    self.LGD = 0.0;
    return self;
}

@end
