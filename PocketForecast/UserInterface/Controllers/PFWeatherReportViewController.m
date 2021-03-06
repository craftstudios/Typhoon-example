////////////////////////////////////////////////////////////////////////////////
//
//  JASPER BLUES
//  Copyright 2012 - 2013 Jasper Blues
//  All Rights Reserved.
//
//  NOTICE: Jasper Blues permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////



#import "PFWeatherReportViewController.h"
#import "PFCurrentConditionsTableViewCell.h"
#import "PFForecastConditionsTableViewCell.h"
#import "PFWeatherReport.h"
#import "PFCurrentConditions.h"
#import "PFForecastConditions.h"
#import "PFTemperature.h"
#import "PFActivityIndicatorTableViewCell.h"
#import "PFWeatherReportDao.h"
#import "PFCityDao.h"
#import "Typhoon.h"
#import <QuartzCore/QuartzCore.h>

static int const CURRENT_CONDITIONS_ROW = 0;
static int const LOADING_INDICATOR_ROW = 4;
static int const CURRENT_CONDITIONS_CELL_HEIGHT = 91;
static int const DETAIL_ROW_CELL_HEIGHT = 58;

@implementation PFWeatherReportViewController

@synthesize presentCitiesViewButton = _presentCitiesViewButton;
@synthesize refreshReportButton = _refreshReportButton;
@synthesize weatherReportTableView = _weatherReportTableView;
@synthesize injectedTableViewCell = _injectedTableViewCell;
@synthesize statusMessageLabel = _statusMessageLabel;
@synthesize currentConditionsImageView = _currentConditionsImageView;


/* ============================================================ Initializers ============================================================ */
- (id)initWithWeatherClient:(id <PFWeatherClient>)weatherClient weatherReportDao:(id <PFWeatherReportDao>)weatherReportDao
        cityDao:(id <PFCityDao>)cityDao
{
    self = [super initWithNibName:@"WeatherReport" bundle:[NSBundle mainBundle]];
    if (self)
    {
        _weatherClient = weatherClient;
        _weatherReportDao = weatherReportDao;
        _cityDao = cityDao;

        _mostlyCloudyImage = [UIImage imageNamed:@"mostly_cloudy.png"];
        _sunnyImage = [UIImage imageNamed:@"sunny.png"];
        _mostlySunnyImage = [UIImage imageNamed:@"mostly_sunny.png"];
        _partlyCloudyImage = [UIImage imageNamed:@"partly_cloudy.png"];
        _chanceOfRainImage = [UIImage imageNamed:@"chance_of_rain.png"];
        _chanceOfStormImage = [UIImage imageNamed:@"chance_of_storm.png"];
    }
    return self;
}


/* ========================================================== Interface Methods ========================================================= */
- (void)viewDidLoad
{
    [super viewDidLoad];
    [_presentCitiesViewButton setAction:@selector(presentCitiesView)];
    [_refreshReportButton setAction:@selector(retrieveRemoteReport)];
    _weatherReportTableView.layer.cornerRadius = 10;
    _weatherReportTableView.layer.masksToBounds = YES;
    _weatherReportTableView.layer.borderColor = UIColorFromRGB(0x374b58).CGColor;
    _weatherReportTableView.layer.borderWidth = 4.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_activityIndicatorCell startAnimating];
    _cityName = [_cityDao getCurrentlySelectedCity];
    _weatherReport = [_weatherReportDao getReportForCityName:_cityName];
    if (_weatherReport)
    {
        [self presentReport:_weatherReport];
    }
    else
    {
        [self retrieveRemoteReport];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self clearStaleData];
}



/* ====================================================================================================================================== */
#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{

    UITableViewCell* cell;
    if (indexPath.row == CURRENT_CONDITIONS_ROW)
    {
        cell = [self makeCurrentConditionsCellWith:[_weatherReport currentConditions]];
        self.injectedTableViewCell = nil;
    }
    else if (indexPath.row == LOADING_INDICATOR_ROW)
    {
        cell = [self makeLoadingTableCell];
    }
    else
    {
        cell = [self makeForecastConditionsCellWith:[[_weatherReport forecast] objectAtIndex:indexPath.row] tableView:tableView];
    }
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{

}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView
        editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.row == 0)
    {
        return CURRENT_CONDITIONS_CELL_HEIGHT;
    }
    else
    {
        return DETAIL_ROW_CELL_HEIGHT;
    }
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell
        forRowAtIndexPath:(NSIndexPath*)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
}

/* ============================================================ Utility Methods ========================================================= */
- (void)dealloc
{
    NSLog(@"%@ in dealloc!", self);
}


/* ============================================================ Private Methods ========================================================= */
/**
* Clears all data from the controller - ready for reuse.
*/
- (void)clearStaleData
{
    _weatherReport = nil;
    [_weatherReportTableView reloadData];
    [_currentConditionsImageView setImage:nil];
    [_statusMessageLabel setText:@""];
}

- (void)presentReport:(PFWeatherReport*)weatherReport
{
    [_activityIndicatorCell stopAnimating];
    _weatherReport = weatherReport;
    [_weatherReportTableView reloadData];
    [_currentConditionsImageView setImage:[self uiImageForImageUri:weatherReport.currentConditions.imageUri]];
    [_statusMessageLabel setText:[NSString stringWithFormat:@"Updated %@", [weatherReport reportDateAsString]]];
}

- (void)retrieveRemoteReport
{
    __weak PFWeatherReportViewController* weakSelf = self;
    [_activityIndicatorCell startAnimating];
    [_weatherClient loadWeatherReportFor:_cityName onSuccess:^(PFWeatherReport* report)
    {
        [weakSelf presentReport:report];
    } onError:nil];
}

- (void)presentCitiesView
{

    [_cityDao clearCurrentlySelectedCity];

    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    UINavigationController* controller = [[TyphoonComponentFactory defaultFactory] componentForType:[UINavigationController class]];
    //pre-load this, because it may not have loaded yet.
    assert(controller.visibleViewController.view != nil);

    [UIView transitionWithView:window duration:0.9f options:UIViewAnimationOptionTransitionFlipFromRight animations:^
    {
        [window setRootViewController:controller];
    } completion:nil];
}

- (PFCurrentConditionsTableViewCell*)makeCurrentConditionsCellWith:(PFCurrentConditions*)currentConditions
{
    [[NSBundle mainBundle] loadNibNamed:@"CurrentConditionsTableCell" owner:self options:nil];
    PFCurrentConditionsTableViewCell* cell = (PFCurrentConditionsTableViewCell*) self.injectedTableViewCell;
    self.injectedTableViewCell = nil;
    [cell.cityNameLabel setText:_cityName];
    [cell.temperatureLabel setText:[currentConditions.temperature asLongStringInDefaultUnits]];
    [cell.conditionsSummary setText:currentConditions.longSummary];
    return cell;
}

- (PFForecastConditionsTableViewCell*)makeForecastConditionsCellWith:(PFForecastConditions*)forecastConditions
        tableView:(UITableView*)tableView
{
    static NSString* CellIdentifier = @"weatherForecast";
    PFForecastConditionsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"ForecastTableCell" owner:self options:nil];
        cell = (PFForecastConditionsTableViewCell*) self.injectedTableViewCell;
    }

    self.injectedTableViewCell = nil;
    [cell.dayLabel setText:forecastConditions.longDayOfTheWeek];

    [cell.lowLabel setText:[forecastConditions.low asShortStringInDefaultUnits]];
    [cell.highLabel setText:[forecastConditions.high asShortStringInDefaultUnits]];
    [cell.weatherIconView setImage:[self uiImageForImageUri:forecastConditions.imageUri]];
    return cell;
}

- (UITableViewCell*)makeLoadingTableCell
{
    [[NSBundle mainBundle] loadNibNamed:@"LoadingTableCell" owner:self options:nil];
    _activityIndicatorCell = (PFActivityIndicatorTableViewCell*) self.injectedTableViewCell;
    [_activityIndicatorCell stopAnimating];
    self.injectedTableViewCell = nil;
    return _activityIndicatorCell;
}

- (UIImage*)uiImageForImageUri:(NSString*)imageUri
{

    if ([imageUri length] > 0)
    {
        LogDebug(@"Retrieving image for URI: %@", imageUri);
        if ([imageUri hasSuffix:@"wsymbol_0001_sunny.png"])
        {
            return _sunnyImage;
        }
        else if ([imageUri hasSuffix:@"/ig/images/weather/mostly_sunny.gif"])
        {
            return _mostlySunnyImage;
        }
        else if ([imageUri hasSuffix:@"/ig/images/weather/partly_cloudy.gif"])
        {
            return _partlyCloudyImage;
        }
        else if ([imageUri hasSuffix:@"wsymbol_0004_black_low_cloud.png"])
        {
            return _mostlyCloudyImage;
        }
        else if ([imageUri hasSuffix:@"wsymbol_0017_cloudy_with_light_rain.png"])
        {
            return _chanceOfRainImage;
        }
        else
        {
            return _mostlySunnyImage;
        }
    }
    return nil;

}

@end