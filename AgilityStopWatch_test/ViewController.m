//
//  ViewController.m
//  AgilityStopWatch_test
//
//  Created by showta on 2014/03/27.
//  Copyright (c) 2014年 testes. All rights reserved.
//

#import "ViewController.h"
#import "Konashi.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *BlueToothStatus_Mark;
@property (strong, nonatomic) IBOutlet UIView *ViewBackGround;
@property (weak, nonatomic) IBOutlet UILabel *RedBoxOpticalAxisStatus;
@property (weak, nonatomic) IBOutlet UILabel *BlueBoxOpticalAxisStatus;

@property (weak, nonatomic) IBOutlet UILabel *BlueToothStatus_num;


@end

@implementation ViewController
{
    NSMutableArray *TimeHistory_No;
    NSMutableArray *TimeHistory_Time;
    NSMutableArray *TimeHistory_Memo;
}



@synthesize timeLavel;
@synthesize StopWatchReset;
@synthesize StopWatchStartStop;
@synthesize TimeRec;
@synthesize RecordClear;
@synthesize FindKonashi;
@synthesize HistoryList;


BOOL bStartButtonflg = FALSE;       // TRUE:start FALSE:stop
bool bLEDTimerFlg = FALSE;
int TimeHistory_No_Counter = 0;
static NSString *identifier = @"tableCell";
BOOL bFindButtonflg = FALSE;        // TRUE:Find FALSE:DisConnect
NSTimer *KonashiDisconnectTimer;
NSTimer *KonashiConnectCheckTimer;
NSTimer *KonashiFindCheckTimer;
BOOL bConnecting = FALSE;
BOOL bDisconnecting = FALSE;
BOOL bOnTimerKonashiFindCheckFirstFlag = FALSE;

BOOL RedBoxOpticalAxisStatus_Old = TRUE;
BOOL BlueBoxOpticalAxisStatus_Old = TRUE;

int DBG_Count = 0;

typedef enum{
    BT_STATUS_0 = 0,
    BT_STATUS_1,
    BT_STATUS_2,
    BT_STATUS_3,
    BT_STATUS_4,
    BT_STATUS_5
}BT_STATUS_MARK;


/**********************************************************************
    ＊＊＊KONASHIの準備
**********************************************************************/
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    //
    [Konashi initialize];
    
    // このHandlerはKonashiが使用可能状態になった際に呼び出されます
    [[Konashi shared]setReadyHandler:^{
        [self KonashiReady];}];

    // このHandlerはKonashiが切断された際に呼び出されます
    [[Konashi shared]setDisconnectedHandler:^{
        [self KonashiDisconnect];}];

    // このHandlerはKonashiPinModeOutputに設定されているPIOの値が変化した際に呼び出されます
    [[Konashi shared]setDigitalInputDidChangeValueHandler:^(KonashiDigitalIOPin pin, int value){
        [self KonashiUpdatePioInput];}];

    //
    [[Konashi shared]setSignalStrengthDidUpdateHandler:^(int value){
        [self KonashiStrength];}];
    
    // ボタンのコーナーR指定
    // StopWatchReset Button
    StopWatchReset.layer.cornerRadius = 10;

    // StopWatchStart Button
    StopWatchStartStop.layer.cornerRadius = 10;

    // TimeRec Button
    TimeRec.layer.cornerRadius = 10;

    // RecordClear Button
    RecordClear.layer.cornerRadius = 10;

    // FindKonashi Button
    FindKonashi.layer.cornerRadius = 10;
    
    
    [PushStartStopButton setTitle:@"start" forState:UIControlStateNormal];
    

    TimeHistory_No = [NSMutableArray arrayWithCapacity:1];
    TimeHistory_Time = [NSMutableArray arrayWithCapacity:1];
    TimeHistory_Memo = [NSMutableArray arrayWithCapacity:1];
    
    HistoryList.delegate = self;
    HistoryList.dataSource = self;
    
    // BT接続状態の初期化
    [self DispBlueToothStatusMark:(BT_STATUS_MARK)BT_STATUS_0];
    
    _BlueToothStatus_num.text = 0;
    
    _ViewBackGround.backgroundColor = [UIColor whiteColor];
    self.table.backgroundColor = [UIColor whiteColor];
    
    RedBoxOpticalAxisStatus_Old = TRUE;
    BlueBoxOpticalAxisStatus_Old = TRUE;
    
}
// BLEの電波強度の表示

- (void) DispBlueToothStatusMark:(BT_STATUS_MARK)BtStatusMark
{
    switch(BtStatusMark)
    {
        case BT_STATUS_0:
            _BlueToothStatus_Mark.text = @"□□□□□";
            break;
            
        case BT_STATUS_1:
            _BlueToothStatus_Mark.text = @"■□□□□";
            break;
            
        case BT_STATUS_2:
            _BlueToothStatus_Mark.text = @"■■□□□";
            break;
            
        case BT_STATUS_3:
            _BlueToothStatus_Mark.text = @"■■■□□";
            break;
            
        case BT_STATUS_4:
            _BlueToothStatus_Mark.text = @"■■■■□";
            break;
            
        case BT_STATUS_5:
            _BlueToothStatus_Mark.text = @"■■■■■";
            break;
            
        default:
            _BlueToothStatus_Mark.text = @"□□□□□";
            break;
    }
}

//赤外線光軸ズレ　インジケータの定義
//- (void) DispOpticalAxisStatusMark:(BOOL)OAStatusMark
- (void) DispOpticalAxisStatusMark:(UILabel*)BoxOpticalAxis //:(BOOL)OAStatusMark
{
/*
    if(OAStatusMark)
    {
        BoxOpticalAxis.text = @"●";
        BoxOpticalAxis.font = [UIFont systemFontOfSize:55];
    }
    else
    {
        BoxOpticalAxis.text = @"○";
        BoxOpticalAxis.font = [UIFont systemFontOfSize:27];
    }
*/
 }
/*=================================================================*/
//   タイム履歴の表示
/*=================================================================*/
//ロード時に呼び出される（セクションに含まれるセル数を返す（実装必須））
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [TimeHistory_No count];
}

//ロード時に呼び出される（セルの内容を返す（実装必須））
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    UITableViewCell *cell;
    
    //カスタムセルを選ぶ
    cell =  [HistoryList dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
//    NSArray *cells = [HistoryList visibleCells];
    
    //番号の表示
    UILabel *idNoLabel = (UILabel*)[cell viewWithTag:1];
    idNoLabel.text = [TimeHistory_No objectAtIndex:indexPath.row];
 
    //タイムの表示
    UILabel *idTimeLabel = (UILabel*)[cell viewWithTag:2];
    idTimeLabel.text = [TimeHistory_Time objectAtIndex:indexPath.row];

/*
    //メモの表示
    UITextField *idTextField = (UITextField*)[cell viewWithTag:3];
    
    NSUInteger TimeHistory_Memo_ArrayNum = [TimeHistory_Memo count];
*/

    
    
    
/*
    if(TimeHistory_Memo_ArrayNum == 0)
    {
        // 配列の追加
        //        [TimeHistory_Memo insertObject:idTextField.text atIndex:indexPath.row];
        [TimeHistory_Memo insertObject:@"" atIndex:0];
    }
    
    
    // memo配列数がTableViewの行数より小さい
//    if(TimeHistory_Memo_ArrayNum <= indexPath.row)
    if(TimeHistory_Memo_ArrayNum <= idNoLabel.text.intValue)
    {
        // 配列の追加
//        [TimeHistory_Memo insertObject:idTextField.text atIndex:indexPath.row];
        [TimeHistory_Memo insertObject:idTextField.text atIndex:idNoLabel.text.intValue];
    }
    else
    {
        // 配列の入れ替え
//        [TimeHistory_Memo replaceObjectAtIndex:indexPath.row withObject:idTextField.text];
        [TimeHistory_Memo replaceObjectAtIndex:idNoLabel.text.intValue withObject:idTextField.text];
    }

    idTextField.text = [TimeHistory_Memo objectAtIndex:idNoLabel.text.intValue];
*/
    
    
    return cell;
}


//セルがタップされたときにコールされるメソッド
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return;
}



/*=================================================================*/
// KonashiからのEvent受信時の処理
/*=================================================================*/
// konashiに接続完了した時の処理(この時からkonashiにアクセスできるようになります)
- (void)KonashiReady
{
    // ボタン表示をfindからdisconnectに変更する
    [FindButton setTitle:@"disconnect"
                forState:UIControlStateNormal];
        
    FindButton.titleLabel.font =[UIFont systemFontOfSize:14];
        
    [FindButton setTitleColor:[UIColor greenColor]
                     forState:UIControlStateNormal];
        
    FindButton.backgroundColor = [UIColor blueColor];
    
    // 接続状態監視タイマーの生成
    KonashiConnectCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                target:self
                                                              selector:@selector(KonashiConnectCheck)
                                                              userInfo:nil
                                                               repeats:YES];
    
    // 接続状態監視タイマーを起動する（接続しているかを１秒ごとに監視する）
    [KonashiConnectCheckTimer fire];
    
    
    // 接続完了なのでフラグを落とす
    bConnecting = FALSE;
    
    //
    bFindButtonflg = true;
    
    // タイマーが動作中
    if(TRUE == [KonashiFindCheckTimer isValid])
    {
        // タイマーを停止する
        [KonashiFindCheckTimer invalidate];
        
        // 初回フラグを初期化
        bOnTimerKonashiFindCheckFirstFlag = FALSE;
    }
    
    
    // DBGDBGDBG
    {
        [Konashi pinMode:KonashiLED2 mode:KonashiPinModeOutput];
//        [Konashi pinMode:LED5 mode:OUTPUT];
        
        [Konashi digitalWrite:KonashiLED2 value:KonashiLevelHigh];
//        [Konashi digitalWrite:LED5 value:LOW];
    }
}

- (void)KonashiConnectCheck
{
    //Konashiとの接続状態を取得する
    BOOL bKonashiConnectState = [Konashi isConnected];
    
    // 電波強度を要求する
    [Konashi signalStrengthReadRequest];

    // Konashiとの通信が接続していない場合
    if(FALSE == bKonashiConnectState)
    {
        // 接続していないのでフラグを落とす
        bConnecting = FALSE;
    }
}


- (void)KonashiDisconnect
{
    bFindButtonflg = false;

    // Disconnectボタン押下時のクルクル表示がされていない
    if (false == (KonashiDisconnectIndicator.isAnimating))
    {
        // findボタンに表示を変える
        [self DispFindButton];
        
        // 背景の色を変更する
        _ViewBackGround.backgroundColor = [UIColor redColor];
        self.table.backgroundColor = [UIColor redColor];
        
        self.timeLavel.textColor = [UIColor blackColor];
    }

}

// PIOの入力の状態が変化した時の処理
- (void)KonashiUpdatePioInput
{
    
// 光軸ズレインジケーター対応
    // 光軸ズレチェック
    [self CheckOpticalAxis];

    BOOL bButtonClickStatus = FALSE;
    
    BOOL BlueBoxOpticalAxisStatus_Now = [Konashi digitalRead:KonashiDigitalIO3];
    BOOL RedBoxOpticalAxisStatus_Now  = [Konashi digitalRead:KonashiDigitalIO2];
 
#if 0
    if(HIGH == [Konashi digitalRead:PIO3])
    {
        bButtonClickStatus = FALSE;
    }
    else
    {
        bButtonClickStatus = FALSE;
    }
    if(HIGH == [Konashi digitalRead:PIO2])
    {
        bButtonClickStatus = FALSE;
    }
    else
    {
        bButtonClickStatus = FALSE;
    }
#endif
    
    // 青BOXのセンサーが遮光された
    if(FALSE == BlueBoxOpticalAxisStatus_Now)
    {
        // 前回状態と異なる
        if(BlueBoxOpticalAxisStatus_Now != BlueBoxOpticalAxisStatus_Old)
        {
            bButtonClickStatus = TRUE;
        }
    }
    
    // 今回状態を前回状態として保持
    BlueBoxOpticalAxisStatus_Old = BlueBoxOpticalAxisStatus_Now;

    
    // 赤BOXのセンサーが遮光された
    if(FALSE == RedBoxOpticalAxisStatus_Now)
    {
        // 前回状態と異なる
        if(RedBoxOpticalAxisStatus_Now != RedBoxOpticalAxisStatus_Old)
        {
            bButtonClickStatus = TRUE;
        }
    }

    // 今回状態を前回状態として保持
    RedBoxOpticalAxisStatus_Old = RedBoxOpticalAxisStatus_Now;

    
 // startボタン押下＝Timmer Start　stopボタン押下＝Timmer Stop
    if(bButtonClickStatus)
    {
        // startボタン押下
        if (bStartButtonflg == FALSE)
        {
            // タイマー開始
            [self StopWatchStart];
        }
        // stopボタン押下
        else
        {
            // タイマー停止
            [self StopWatchStop];
        }
        
    }
/*
    // 物理SW　離され
    if(FALSE == [Konashi digitalRead:PIO3])
    {
        // startボタン押下
        if (bStartButtonflg == FALSE)
        {
            // タイマー開始
            [self StopWatchStart];
        }
        // stopボタン押下
        else
        {
            // タイマー停止
            [self StopWatchStop];
        }
    }
*/

}
// 光軸状態確認
- (void) CheckOpticalAxis
{
    // 青BOXセンサー
    BOOL bBlueBoxStatus = [Konashi digitalRead:KonashiDigitalIO3];
    
    // 赤BOXセンサー
    BOOL bRedBoxStatus = [Konashi digitalRead:KonashiDigitalIO2];
   
    //DBGDBGDBGDBGDBGDBGDBGDBGDBGDBGDBGDBGDBGDBG
    NSLog(@"[%d]--------",DBG_Count);
    
    NSLog(@"PIO3(青) = %d",bBlueBoxStatus);
    NSLog(@"PIO2(赤) = %d",bRedBoxStatus);
    
    
    DBG_Count++;
    //DBGDBGDBGDBGDBGDBGDBGDBGDBGDBGDBGDBGDBGDBG
    
    if(bBlueBoxStatus)
    {
        _BlueBoxOpticalAxisStatus.text = @"●";
        _BlueBoxOpticalAxisStatus.font = [UIFont systemFontOfSize:55];
    }
    else
    {
        _BlueBoxOpticalAxisStatus.text = @"○";
        _BlueBoxOpticalAxisStatus.font = [UIFont systemFontOfSize:27];
    }
    
    if(bRedBoxStatus)
    {
        _RedBoxOpticalAxisStatus.text = @"●";
        _RedBoxOpticalAxisStatus.font = [UIFont systemFontOfSize:55];
    }
    else
    {
        _RedBoxOpticalAxisStatus.text = @"○";
        _RedBoxOpticalAxisStatus.font = [UIFont systemFontOfSize:27];
    }
    
}
// konashiの電波強度を取得できた時の処理
- (void) KonashiStrength
{
    const int BT_SIGNAL_STRENGTH_BASE = 100;
/*
    const int BT_SIGNAL_LV5 = 40;
    const int BT_SIGNAL_LV4 = 30;
    const int BT_SIGNAL_LV3 = 20;
    const int BT_SIGNAL_LV2 = 10;
*/
    const int BT_SIGNAL_LV5 = 50;
    const int BT_SIGNAL_LV4 = 35;
    const int BT_SIGNAL_LV3 = 20;
    const int BT_SIGNAL_LV2 = 5;

    // BTの電波強度を取得
    int BtSignalStrangth = [Konashi signalStrengthRead];
    
    int BtSignalStrangthChanged = BtSignalStrangth + BT_SIGNAL_STRENGTH_BASE;
    
//    NSLog(@"READ_STRENGTH: %3d %3d ", BtSignalStrangth, BtSignalStrangthChanged);
        
    BT_STATUS_MARK BtStatus = BT_STATUS_0;
    
    // Lv5
    if(BT_SIGNAL_LV5 <= BtSignalStrangthChanged)
    {
        BtStatus = BT_STATUS_5;
    }
    // Lv4
    else if(BT_SIGNAL_LV4 <= BtSignalStrangthChanged && BT_SIGNAL_LV5 > BtSignalStrangthChanged)
    {
        BtStatus = BT_STATUS_4;
    }
    // Lv3
    else if(BT_SIGNAL_LV3 <= BtSignalStrangthChanged && BT_SIGNAL_LV4 > BtSignalStrangthChanged)
    {
        BtStatus = BT_STATUS_3;
    }
    // Lv2
    else if(BT_SIGNAL_LV2 <= BtSignalStrangthChanged && BT_SIGNAL_LV3 > BtSignalStrangthChanged)
    {
        BtStatus = BT_STATUS_2;
    }
    // Lv1
    else if( BT_SIGNAL_LV2 > BtSignalStrangthChanged)
    {
        BtStatus = BT_STATUS_1;
    }
    else
    {
        BtStatus = BT_STATUS_0;
    }
    
    [self DispBlueToothStatusMark:(BT_STATUS_MARK)BtStatus];
    
    _BlueToothStatus_num.text = [NSString stringWithFormat:@"%d",BtSignalStrangthChanged];
    
}

/**********************************************************************
    ＊＊＊
**********************************************************************/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/**********************************************************************
    start/stopボタン押下時の処理
**********************************************************************/
- (IBAction)StopWatchStartStop:(id)sender {
    
    // startボタン押下
    if (bStartButtonflg == FALSE)
    {
        // タイマー開始
        [self StopWatchStart];
    }
    // stopボタン押下
    else
    {
        // タイマー停止
        [self StopWatchStop];
    }
    
    // 背景を白にする
    _ViewBackGround.backgroundColor = [UIColor whiteColor];
    self.table.backgroundColor = [UIColor whiteColor];

    // タイマー色を赤に戻す
    self.timeLavel.textColor = [UIColor redColor];
 }

- (void)StopWatchStart
{
    startTime = [NSDate timeIntervalSinceReferenceDate];
    self.timeLavel.text = @"00:00.00";
    
    if(_timer && [_timer isValid])
    {
        [_timer invalidate];
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:(0.01)
                                              target:(self)
                                            selector:(@selector(updateTime:))
                                            userInfo:(nil)
                                             repeats:YES];
    
    // ボタン名をStopに変更
    [PushStartStopButton setTitle:@"stop"
                         forState:UIControlStateNormal];
    
    bStartButtonflg = TRUE;

    bLEDTimerFlg = FALSE;
     _LEDtimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                  target:self
                                                selector:@selector(onLEDTimer)
                                                userInfo:nil
                                                 repeats:YES];
    

}

//********************
//StopWatch時間計算処理
//******************
- (void)updateTime:(NSTimer*)timer
{
    
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate] - startTime;
    int sec = time;
    int msec = (time - sec) * 100;
    
    self.timeLavel.text = [NSString stringWithFormat:@"%02d:%02d.%02d", sec / 60, sec % 60, msec];
}

-(void)onLEDTimer
{
    if (FALSE == bLEDTimerFlg)
    {
        // LED5 点灯
//        [Konashi digitalWrite:LED5 value:HIGH];
        bLEDTimerFlg = TRUE;
    }
    else
    {
        // LED5 消灯
//        [Konashi digitalWrite:LED5 value:LOW];
        bLEDTimerFlg = FALSE;
    }
}


- (void)StopWatchStop
{
    [_timer invalidate];
    _timer = nil;
    
    // ボタン名をStartに変更
    [PushStartStopButton setTitle:@"start" forState:UIControlStateNormal];
    bStartButtonflg = FALSE;
    
    [_LEDtimer invalidate];
//    [Konashi digitalWrite:LED5 value:LOW];
}


/**********************************************************************
    Resetボタン押下時の処理
**********************************************************************/
- (IBAction)PushResetButton:(id)sender {

    // ストップウオッチ停止中
    if (bStartButtonflg == FALSE)
    {
        self.timeLavel.text = @"00:00.00";
    }
    
    
    // 電波強度を要求する
    [Konashi signalStrengthReadRequest];

}

/**********************************************************************
    Clearボタン押下時の処理
**********************************************************************/
- (IBAction)PushClearButton:(id)sender {

    // ストップウオッチ停止中
    if (bStartButtonflg == FALSE)
    {
        if(1 <= TimeHistory_No_Counter)
        {
#if 0
            /* UIAlertViewはiOS8以降非推奨　UIAlertControllerを使う */
            
            //アラートビューの生成と設定
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"履歴を削除しますか？"
                                                            message:@""
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:nil];
            [alert addButtonWithTitle:@"OK"];

            // 確認メッセージ表示
            [alert show];
#else
            //アラートの生成
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"履歴を削除しますか？" message:@"" preferredStyle:UIAlertControllerStyleAlert];

            //下記のコードでボタンを追加します。また{}内に記述された処理がボタン押下時の処理なります。
             [alertController addAction:[UIAlertAction actionWithTitle:@"はい" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
              //「はい」ボタンがタップされた際の処理
              }]];

            [alertController addAction:[UIAlertAction actionWithTitle:@"いいえ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
              //「いいえ」ボタンがタップされた際の処理
              }]];

            //ダイアログを表示
            [self presentViewController:alertController animated:YES completion:nil];
#endif
        }
   }

}

/**********************************************************************
    Recボタン押下時の処理
**********************************************************************/
- (IBAction)PushRecButton:(id)sender
{
    // タイム表時が00:00.00の場合は何も行わない
    if([self.timeLavel.text isEqualToString:@"00:00.00"])
    {
        return;
    }
    
    // ストップウオッチ動作中は何も行わない
    if (TRUE == bStartButtonflg)
    {
        return;
    }

    //
    TimeHistory_No_Counter ++;
        
    // NSString型への変換
    NSString *strNo = [NSString stringWithFormat:@"%d",TimeHistory_No_Counter];
        
    [TimeHistory_No insertObject:strNo atIndex:0];
    [TimeHistory_Time insertObject:self.timeLavel.text atIndex:0];
    
    // タイム表示の初期化
    self.timeLavel.text = @"00:00.00";

    [self.HistoryList reloadData];
    
    
 
}

/**********************************************************************
    Findボタン押下時の処理
**********************************************************************/
- (IBAction)FindKonashi:(id)sender {

    if(TRUE == bConnecting)
    {
        return;
    }
    
    if(TRUE == bDisconnecting)
    {
        return;
    }

    // Konashiの検索
    if(FALSE == bFindButtonflg)
    {
        // 背景を白に戻す
        _ViewBackGround.backgroundColor = [UIColor whiteColor];
        self.table.backgroundColor = [UIColor whiteColor];
        
        // タイマー色を赤に戻す
        self.timeLavel.textColor = [UIColor redColor];

        // 周辺のKonashiを検索する
        [Konashi find];
        
        NSLog(@"[Konashi find]");

        // findからKONASHI_EVENT_READYまでボタン押下を無効とする
        bConnecting = TRUE;
        
        // find状態監視タイマーの生成
        KonashiFindCheckTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                 target:self
                                                               selector:@selector(OnTimerKonashiFindCheck:)
                                                               userInfo:nil
                                                                repeats:YES];
        
        // find状態監視タイマーを起動する
        [KonashiFindCheckTimer fire];


    }
    // Konashiの切断
    else
    {
        // Konashiを切断する
        [Konashi disconnect];
        
        KonashiDisconnectTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                                  target:self
                                                                selector:@selector(OnTimerKonashiDisonnect)
                                                                userInfo:nil
                                                                 repeats:YES];
        // Konash切断待ちのタイマを開始する
        [KonashiDisconnectTimer fire];
        
        // くるくるを動かす
        [KonashiDisconnectIndicator startAnimating];
        
        // disconnectから切断完了（KonashiDisconnectTimerタイムアウト）までボタン押下無効とする
        bDisconnecting = TRUE;
        
    }
}
-(void)OnTimerKonashiFindCheck:(NSTimer*)timer
{
    // 初回の処理の場合（fire後すぐに１回呼ばれるのでそれはスルーする）
    if(TRUE == bOnTimerKonashiFindCheckFirstFlag)
    {
        // findから3秒以内にKONASHI_EVENT_READYが通知されない場合はフラグを落とす（findボタン押下可能とする）
        bConnecting = FALSE;
    }
    
    bOnTimerKonashiFindCheckFirstFlag = TRUE;
    
//    NSLog(@"bConnecting[後] = %d", bConnecting);
}

-(void)OnTimerKonashiDisonnect
{
    // Konashiに接続されていない場合
    if(false == [Konashi isConnected])
    {
        // くるくるしてるか？
        if (KonashiDisconnectIndicator.isAnimating)
        {
            // くるくるを止める
            [KonashiDisconnectIndicator stopAnimating];

            // タイマの停止
            [KonashiDisconnectTimer invalidate];
            
            // findボタンに表示を変える
            [self DispFindButton];
            
            bDisconnecting = FALSE;

        }
        

        
    }
}

- (void)DispFindButton
{
    [FindButton setTitle:@"find"
                forState:UIControlStateNormal];
    
    [FindButton.titleLabel setFont:[UIFont systemFontOfSize:25]];
    
    [FindButton setTitleColor:[UIColor blueColor]
                     forState:UIControlStateNormal];
    
    FindButton.backgroundColor = [UIColor greenColor];
    
    // BT接続状態の初期化
    [self DispBlueToothStatusMark:(BT_STATUS_MARK)BT_STATUS_0];

    // 光軸状態の初期化
    _BlueBoxOpticalAxisStatus.text = @"○";
    _BlueBoxOpticalAxisStatus.font = [UIFont systemFontOfSize:27];
    _RedBoxOpticalAxisStatus.text = @"○";
    _RedBoxOpticalAxisStatus.font = [UIFont systemFontOfSize:27];
    
    _BlueToothStatus_num.text = 0;

    // 接続中が終了
    bConnecting = FALSE;

//    [Konashi digitalWrite:LED5 value:LOW];
}




// TextFieldのReturnキーが押下された場合に実行
-(BOOL)textFieldShouldReturn:(UITextField*)textField{
    [HistoryList endEditing:YES];
    return YES;
}






// テキスト入力終了時の処理
- (IBAction)textend:(id)sender {
    NSLog(@"textend");
/*
    NSArray *cells = [self.HistoryList visibleCells];
//    NSIndexPath *indexPath = [HistoryList indexPathForCell:HistoryListCell];
    
    [self.HistoryList indexPathForCell:cells];
    
    NSIndexPath *indexpath = [HistoryList indexPathForSelectedRow];
*/
    
    
//    int aaa = indexPath.row;
}

// 画面をタップされた場合
- (IBAction)HideKeyboard:(id)sender {
    
    // キーボードを消す
    [HistoryList endEditing:YES];
    
    return;
}


// アラートのボタンが押された場合の処理
-(void)alertView:(UIAlertController*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            //1番目のボタン（cancelButtonTitle）が押されたときのアクション
            NSLog(@"Cancel");
 

            break;
            
        case 1:
            //2番目のボタンが押されたときのアクション
            NSLog(@"OK");
            
            // 配列の初期化
            [TimeHistory_No removeAllObjects];
            [TimeHistory_Time removeAllObjects];
            [TimeHistory_Memo removeAllObjects];
            
            TimeHistory_No_Counter = 0;
            
            [self.HistoryList reloadData];
            
            
            
            break;
            
        default:
            break;
            
            
            
   }
    
}

/**********************************************************************
 Findボタン押下時の処理
 **********************************************************************/
- (IBAction)PushAutoRecButton:(id)sender {
}

@end
