//
//  AppDelegate.m
//  RiskCalc
//
//  Created by Kailun Wu on 12/29/14.
//  Copyright (c) 2014 Kailun Wu. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end


@implementation AppDelegate

@synthesize socket;
@synthesize messageIn;
@synthesize messageOut;
@synthesize lines;
@synthesize spread2;
@synthesize spread5;
@synthesize spread10;
@synthesize spread30;
@synthesize shiftControlString;
@synthesize issuerData;
@synthesize riskData;

- (id)init {
    self = [super init];
    
    // START THE SERVER PROGRAMMATICALLY.
    NSString *exePath = [[NSBundle mainBundle] pathForResource:@"server" ofType:nil];
    NSArray *args = [[NSArray alloc] init];
    NSString *dirPath = [exePath substringToIndex:([exePath length] - 7)];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:exePath];
    [task setArguments:args];
    [task setCurrentDirectoryPath:dirPath];
    [task launch];
    
    // Create the data for the issuer table.
    issuerData = [[NSMutableArray alloc] init];
    for (int i = 0; i < 14; i++) {
        [issuerData insertObject:[[IssuerData alloc] init] atIndex:[issuerData count]];
    }
    [[issuerData objectAtIndex:0] setIssuer:@"GM"];
    [[issuerData objectAtIndex:1] setIssuer:@"FG"];
    [[issuerData objectAtIndex:2] setIssuer:@"YU"];
    [[issuerData objectAtIndex:3] setIssuer:@"XY"];
    [[issuerData objectAtIndex:4] setIssuer:@"TT"];
    [[issuerData objectAtIndex:5] setIssuer:@"A"];
    [[issuerData objectAtIndex:6] setIssuer:@"AA"];
    [[issuerData objectAtIndex:7] setIssuer:@"AAA"];
    [[issuerData objectAtIndex:8] setIssuer:@"B"];
    [[issuerData objectAtIndex:9] setIssuer:@"BB"];
    [[issuerData objectAtIndex:10] setIssuer:@"BBB"];
    [[issuerData objectAtIndex:11] setIssuer:@"VaR Credit"];
    [[issuerData objectAtIndex:12] setIssuer:@"VaR Rate"];
    [[issuerData objectAtIndex:13] setIssuer:@"VaR Total"];
    
    // Create the data for the risk table.
    riskData = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; i++) {
        [riskData insertObject: [[RiskData alloc] init] atIndex:[riskData count]];
    }
    [[riskData objectAtIndex:0] setBook:@"Closing Risk"];
    [[riskData objectAtIndex:1] setBook:@"Closing Mkt Value"];
    [[riskData objectAtIndex:2] setBook:@"2 Year Hedge"];
    [[riskData objectAtIndex:3] setBook:@"Yield Curve (%)"];
    
    return self;
}


#pragma mark Communication with the server.

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Setup socket.
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    NSString *host = [[NSProcessInfo processInfo] hostName];
    uint16_t port = 4660;
    NSError *error = nil;
    NSLog(@"Start connecting to %@ at port %d.", host, port);
    if (![socket connectToHost:host onPort:port error:&error]) {
        NSLog(@"Error connecting: %@.", error);
    }
    
    // Send the initial messageOut.
    spread2 = @"0";
    spread5 = @"0";
    spread10 = @"0";
    spread30 = @"0";
    shiftControlString = @"original";
    messageOut = [[NSString alloc]initWithString:[self sendMessageOut:NO]];
}

- (NSString *)sendMessageOut:(BOOL)shiftControlChanged {
    if (shiftControlChanged) {
        messageOut =
        [NSString stringWithFormat:@"0 0 0 0 %@", shiftControlString];
    } else {
        messageOut =
        [NSString stringWithFormat:@"%@ %@ %@ %@ nil", spread2, spread5, spread10, spread30];
    }
    NSLog(@"messageOut: %@", messageOut);
    NSData *dataToWrite = [messageOut dataUsingEncoding:NSUTF8StringEncoding];
    [socket writeData:dataToWrite withTimeout:-1 tag:TAG_CALC];
    // After sending, immediately waiting for reading.
    NSMutableData *buffer = [[NSMutableData alloc] initWithCapacity:128];
    [socket readDataWithTimeout:-1 buffer:buffer bufferOffset:0 tag:TAG_CALC];
    return messageOut;
}

- (void)parseMessage {
    lines = [messageIn componentsSeparatedByString:@"\n"];
    NSLog(@"messageIn: %lu lines", (unsigned long)[lines count]);
    
    // lines[0~4] 5 lines for 5 tickers. Each line has 9 numbers.
    // lines[5~10] 6 lines for 6 ratings. Each line has 9 numbers.
    for (int i = 0; i < 11; i++) {
        NSArray *lineData = [self parseLine:i];
        IssuerData *tableRow = [issuerData objectAtIndex:i];
        [tableRow setAmount:[[lineData objectAtIndex:3] intValue]];
        [tableRow setRisk:[[lineData objectAtIndex:4] doubleValue]];
        [tableRow setLGD:[[lineData objectAtIndex:5] doubleValue]];
    }
    
    // lines[11~14] 4 lines for 4 buckets. Each: risk, market value(in 1000), hedge.
    for (int i = 0; i < 3; i++) {
        RiskData *tableRow = [riskData objectAtIndex:i];
        [tableRow setData2YR:[[[self parseLine:11] objectAtIndex:i] doubleValue]];
        [tableRow setData5YR:[[[self parseLine:12] objectAtIndex:i] doubleValue]];
        [tableRow setData10YR:[[[self parseLine:13] objectAtIndex:i] doubleValue]];
        [tableRow setData30YR:[[[self parseLine:14] objectAtIndex:i] doubleValue]];
    }
    
    // lines[15] 3 cs VaR, 3 IR VaR, 3 total VaR.
    for (int i = 11; i < 14; i++) {
        long j = (i - 11) * 3 + 1;
        [[issuerData objectAtIndex:i] setAmount:0];
        [[issuerData objectAtIndex:i] setRisk:[[[self parseLine:15] objectAtIndex:j] doubleValue]];
        [[issuerData objectAtIndex:i] setLGD:0.0];
    }

    // lines[16~19] Histogram
    // lines[20] Yield curves
    RiskData *yieldCurves = [riskData objectAtIndex:3];
    [yieldCurves setData2YR:[[[self parseLine:20] objectAtIndex:0] doubleValue]];
    [yieldCurves setData5YR:[[[self parseLine:20] objectAtIndex:1] doubleValue]];
    [yieldCurves setData10YR:[[[self parseLine:20] objectAtIndex:2] doubleValue]];
    [yieldCurves setData30YR:[[[self parseLine:20] objectAtIndex:3] doubleValue]];
    // lines[21] Execution time: real, user, system
}

- (IBAction)changeSpread2YR:(id)sender {
    if ([self isNumber:[sender stringValue]]) {
        spread2 = [sender stringValue];
        messageOut = [self sendMessageOut:NO];
    } else {
        [sender setStringValue:@""];
    }
}

- (IBAction)changeSpread5YR:(id)sender {
    if ([self isNumber:[sender stringValue]]) {
        spread5 = [sender stringValue];
        messageOut = [self sendMessageOut:NO];
    } else {
        [sender setStringValue:@""];
    }
}

- (IBAction)changeSpread10YR:(id)sender {
    if ([self isNumber:[sender stringValue]]) {
        spread10 = [sender stringValue];
        messageOut = [self sendMessageOut:NO];
    } else {
        [sender setStringValue:@""];
    }
}

- (IBAction)changeSpread30YR:(id)sender {
    if ([self isNumber:[sender stringValue]]) {
        spread30 = [sender stringValue];
        messageOut = [self sendMessageOut:NO];
    } else {
        [sender setStringValue:@""];
    }
}

- (IBAction)changeBook:(id)sender {
    long offset = [sender selectedSegment] * 3;
    for (int i = 0; i < 11; i++) {
        NSArray *lineData = [self parseLine:i];
        IssuerData *tableRow = [issuerData objectAtIndex:i];
        [tableRow setAmount:[[lineData objectAtIndex:offset] intValue]];
        [tableRow setRisk:[[lineData objectAtIndex:offset + 1] doubleValue]];
        [tableRow setLGD:[[lineData objectAtIndex:offset + 2] doubleValue]];
    }
    for (int i = 11; i < 14; i++) {
        long j = (i - 11) * 3 + [sender selectedSegment];
        [[issuerData objectAtIndex:i] setAmount:0];
        [[issuerData objectAtIndex:i] setRisk:[[[self parseLine:15] objectAtIndex:j] doubleValue]];
        [[issuerData objectAtIndex:i] setLGD:0.0];
    }
}

- (IBAction)shiftYield:(id)sender {
    switch ([sender selectedSegment]) {
        case 0:
            shiftControlString = @"down";
            messageOut = [self sendMessageOut:YES];
            break;
        case 1:
            shiftControlString = @"original";
            messageOut = [self sendMessageOut:YES];
            break;
        case 2:
            shiftControlString = @"up";
            messageOut = [self sendMessageOut:YES];
            break;
        default:
            break;
    }
}

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"Cool, now I'm connected!");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    messageIn = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self parseMessage];
}


#pragma mark Histogram popover

- (IBAction)showPopoverHistogram:(id)sender {
    [self.popoverHistogram showRelativeToRect:[sender bounds]
                                       ofView:sender
                                preferredEdge:NSMaxYEdge];
}

- (NSWindow *)detachableWindowForPopover:(NSPopover *)popover {
    NSLog(@"detach");
    return _popoverWindow;
}

#pragma mark Share button

- (NSArray *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker
          sharingServicesForItems:(NSArray *)items
          proposedSharingServices:(NSArray *)proposedServices {
    NSMutableArray *sharingServices = [proposedServices mutableCopy];
    return sharingServices;
}

- (IBAction)showShare:(id)sender {
//    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] init];
//    //sharingServicePicker.delegate = self;
//    [sharingServicePicker showRelativeToRect:[sender bounds]
//                                      ofView:sender
//                               preferredEdge:NSMinYEdge];
}

#pragma mark Helper functions

- (NSArray *)parseLine:(int)lineIndex {
    return [[lines objectAtIndex:lineIndex] componentsSeparatedByString:@" "];
}

- (BOOL)isNumber:(NSString *)string {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(?:|0|[1-9]\\d*)(?:\\.\\d*)?$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:string
                                                    options:0
                                                      range:NSMakeRange(0, [string length])];
    return match != nil;
}

@end
