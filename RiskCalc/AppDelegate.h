//
//  AppDelegate.h
//  RiskCalc
//
//  Created by Kailun Wu on 12/29/14.
//  Copyright (c) 2014 Kailun Wu. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IssuerData.h"
#import "RiskData.h"
#import "GCDAsyncSocket.h"

#define TAG_TEST 1
#define TAG_CALC 2

@interface AppDelegate : NSObject <NSApplicationDelegate, NSPopoverDelegate, NSSharingServicePickerDelegate>

@property GCDAsyncSocket *socket;
@property NSString *messageIn;
@property NSString *messageOut;
@property NSArray *lines;
@property NSString *spread2;
@property NSString *spread5;
@property NSString *spread10;
@property NSString *spread30;
@property NSString *shiftControlString;
@property (strong) NSMutableArray *issuerData;
@property (strong) NSMutableArray *riskData;

@property (weak) IBOutlet NSPopover *popoverHistogram;
@property (unsafe_unretained) IBOutlet NSWindow *popoverWindow;


- (IBAction)showPopoverHistogram:(id)sender;
- (IBAction)showShare:(id)sender;
- (IBAction)changeBook:(id)sender;
- (IBAction)shiftYield:(id)sender;
- (void)parseMessage;
- (IBAction)changeSpread2YR:(id)sender;
- (IBAction)changeSpread5YR:(id)sender;
- (IBAction)changeSpread10YR:(id)sender;
- (IBAction)changeSpread30YR:(id)sender;

@end

