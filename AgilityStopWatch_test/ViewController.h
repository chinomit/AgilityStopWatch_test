//
//  ViewController.h
//  AgilityStopWatch_test
//
//  Created by showta on 2014/03/27.
//  Copyright (c) 2014年 testes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, UITextViewDelegate>
{
    UILabel *timeLavel;
    NSTimer *_timer;
    NSTimer *_LEDtimer;
    NSTimeInterval startTime;
    NSTimeInterval LEDTimer;
    IBOutlet UIButton *PushStartStopButton;
    
    UITableView *HistoryList;
    __weak IBOutlet UIButton *FindButton;
    
    __weak IBOutlet UIActivityIndicatorView *KonashiDisconnectIndicator;
}

@property IBOutlet UITableView *table;


- (IBAction)FindKonashi:(id)sender;



@property (strong, nonatomic) IBOutlet UITableView *HistoryList;

@property (strong, nonatomic) IBOutlet UILabel *timeLavel;
@property (weak, nonatomic) IBOutlet UIButton *FindKonashi;

@property (weak, nonatomic) IBOutlet UIButton *StopWatchStartStop;
@property (weak, nonatomic) IBOutlet UIButton *StopWatchReset;

@property (weak, nonatomic) IBOutlet UIButton *TimeRec;
@property (weak, nonatomic) IBOutlet UIButton *RecordClear;




@end
