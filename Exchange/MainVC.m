//
//  ViewController.m
//  Exchange
//
//  Created by Max Ostapchuk on 2/21/17.
//  Copyright © 2017 Max Ostapchuk. All rights reserved.
//

#import "MainVc.h"
#import "constants.h"
#import "ServerManager.h"
#import "СurrencyModel.h"
#import "CurrencyConvertVC.h"


@interface MainVC ()

@property(strong,nonatomic) NSMutableArray *modelsArray;
@property(strong,nonatomic) NSArray *yesterdayModelsArray;
@property(strong,nonatomic) NSDateFormatter *lastUpdateTime;

@property(strong,nonatomic) CurrencyModel *eurModel;
@property(strong,nonatomic) CurrencyModel *rubModel;
@property(strong,nonatomic) CurrencyModel *usdModel;

@property(strong,nonatomic) CurrencyModel *yesterdayEurModel;
@property(strong,nonatomic) CurrencyModel *yesterdayRubModel;
@property(strong,nonatomic) CurrencyModel *yesterdayUsdModel;

@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.modelsArray = [NSMutableArray new];
    [self createModelsAndUpdateLabels];
    [self addTapAndSwipeRecognizer];
}


#pragma mark - Labels update

-(void)updateLabels{
    
    self.eurBuy.text = [NSString stringWithFormat:@"%.2f",self.eurModel.buyRate];
    self.eurSell.text = [NSString stringWithFormat:@"%.2f",self.eurModel.sellRate];
    self.usdBuy.text = [NSString stringWithFormat:@"%.2f",self.usdModel.buyRate];
    self.usdSell.text = [NSString stringWithFormat:@"%.2f",self.usdModel.sellRate];
    self.rubBuy.text = [NSString stringWithFormat:@"%.2f",self.rubModel.buyRate];
    self.rubSell.text = [NSString stringWithFormat:@"%.2f",self.rubModel.sellRate];
    [self lastUpdateDate];
    [self stopIndicators];
}

#pragma mark - Check Internet connection

-(void)checkInternetConnection{
    
    if(_usdModel.buyRate == 0.f){
        _errorLabel.hidden = NO;
    }
    else
        _errorLabel.hidden = YES;
}

#pragma mark - Get models

-(void)createModelsAndUpdateLabels{
    
    [CurrencyModel getCurrencyModels:^(NSMutableArray *array) {
        self.modelsArray = array;
        for(CurrencyModel *model in self.modelsArray){
            if([model.exchangeToCurrency  isEqual: @"EUR"]){
                self.eurModel = model;
            }else
                if([model.exchangeToCurrency  isEqual: @"RUR"]){
                    self.rubModel = model;
                }else
                    self.usdModel = model;
        }
        [self checkInternetConnection];
        [self updateLabels];
        [self createYesterdayModels];
        
    }];
}

-(void)stopIndicators{
    
    for(UIActivityIndicatorView *indicator in _rateActivityIndicators){
        [indicator stopAnimating];
    }
}

-(void)createYesterdayModels{
       
    [CurrencyModel getYesterdayCurrencyModels:^(NSMutableArray *array) {
        
        self.yesterdayModelsArray = array;
        for(CurrencyModel *model in self.yesterdayModelsArray){
            if([model.exchangeToCurrency  isEqual: @"EUR"]){
                self.yesterdayEurModel = model;
            }else
                if([model.exchangeToCurrency  isEqual: @"RUB"]){
                    self.yesterdayRubModel = model;
                }else
                    self.yesterdayUsdModel = model;
        }
        [self setCompracions];
    }];
}

-(void)setCompracions{
    [self setCompracion:_rubModel and:_yesterdayRubModel andSet:_rubComprasionImageView];
    [self setCompracion:_usdModel and:_yesterdayUsdModel andSet:_usdComprasionImageView];
    [self setCompracion:_eurModel and:_yesterdayEurModel andSet:_eurCompraisonImageView];
}

#pragma mark - Update time

-(void)lastUpdateDate{
    
    NSDate* now = [NSDate date];
    self.lastUpdateLabel.text = [NSString stringWithFormat:@"Last info update - %@",[self convertDateToString:now]];
}

#pragma mark - VC buttons

- (IBAction)refreshButtonAction:(id)sender {
    
    [self createModelsAndUpdateLabels];
}

- (IBAction)moneyConvertButton:(id)sender {
    
    [self performSegueWithIdentifier:@"convertSegue" sender:nil];
}

#pragma mark - Currency Compracion

-(void)setCompracion:(CurrencyModel*)firstM and:(CurrencyModel*)secondM andSet:(UIImageView*)imageView{
    
    if(firstM.buyRate > secondM.buyRate){
        imageView.image = [UIImage imageNamed:@"arrow_up"];
        imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [imageView setTintColor:RATING_UP];
    }
    else
        if(firstM.buyRate < secondM.buyRate){
            imageView.image = [UIImage imageNamed:@"arrow_down"];
            imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [imageView setTintColor:RATING_DOWN];
    }
}

#pragma mark - Compracion View

-(void)addTapAndSwipeRecognizer{
    UITapGestureRecognizer *usdTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    usdTap.numberOfTapsRequired = 1;
    [_usdComprasionImageView setUserInteractionEnabled:YES];
    [_usdComprasionImageView addGestureRecognizer:usdTap];
    UITapGestureRecognizer *eurTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    usdTap.numberOfTapsRequired = 1;
    [_eurCompraisonImageView setUserInteractionEnabled:YES];
    [_eurCompraisonImageView addGestureRecognizer:eurTap];
    UITapGestureRecognizer *rubTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    usdTap.numberOfTapsRequired = 1;
    [_rubComprasionImageView setUserInteractionEnabled:YES];
    [_rubComprasionImageView addGestureRecognizer:rubTap];
    
    UISwipeGestureRecognizer * recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeSegue)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:recognizer];
}

-(void)swipeSegue{
    [self performSegueWithIdentifier:@"convertSegue" sender:nil];
}

-(void)tapDetected:(UITapGestureRecognizer *)recognizer{
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 100.f, 65.f)];
    view.center = self.view.center;
    view.backgroundColor = WHITE_COLOR;
    [view setAlpha:0.0f];
    view.layer.cornerRadius = 8.f;
    [self.view addSubview:view];
    
    UILabel *label = [[UILabel alloc] init];
    float compracion;
    if(recognizer.view.tag == 1){
        compracion = _eurModel.buyRate - _yesterdayEurModel.buyRate;
        [self setTextColorBy:compracion for:label];
    }
    else
        if(recognizer.view.tag == 2){
            compracion = _rubModel.buyRate - _yesterdayRubModel.buyRate;
            [self setTextColorBy:compracion for:label];
        }
        else
            if(recognizer.view.tag == 3){
                compracion = _usdModel.buyRate - _yesterdayUsdModel.buyRate;
                [self setTextColorBy:compracion for:label];
            }
    
    label.font = [UIFont systemFontOfSize:23.f];
    [label sizeToFit];
    
    float xpos = (view.frame.size.width/2.0f) - (label.frame.size.width/2.0f);
    float ypos = (view.frame.size.height/2.0f) - (label.frame.size.height/2.0f);
    [label setFrame:CGRectMake(xpos, ypos, label.frame.size.width, label.frame.size.height)];
    [view addSubview:label];
    
    [UIView animateWithDuration:1.0f animations:^{
        [view setAlpha:0.85f];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.1 animations:^{
            [view setAlpha:0.0f];
        }];
    }];
}

-(void)setTextColorBy:(float)compracion for:(UILabel*)label{
    if(compracion > 0){
        label.textColor = [GREEN_COLOR colorWithAlphaComponent:0.8f];
        label.text = [NSString stringWithFormat:@"+%.2f",compracion];
    }else
        if(compracion < 0){
            label.textColor = [RATING_DOWN colorWithAlphaComponent:0.8f];
            label.text = [NSString stringWithFormat:@"%.2f",compracion];
        }
}

#pragma mark - Data to string

-(NSString*)convertDateToString:(NSDate*)date{
    
    NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
    [dateformate setDateFormat:@"MMM d, h:mm a"]; // Date formater
    NSString *finalDate = [dateformate stringFromDate:date];
    return  finalDate;
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"convertSegue"]) {
        
        CurrencyConvertVC *convertVC = segue.destinationViewController;
        convertVC.eurModel = self.eurModel;
        convertVC.rubModel = self.rubModel;
        convertVC.usdModel = self.usdModel;
    }    
}

@end
