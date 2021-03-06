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



#import "PFAddCityViewController.h"
#import "PFCityDao.h"
#import "PFWeatherReport.h"


@implementation PFAddCityViewController

@synthesize nameOfCityToAdd = _nameOfCityToAdd;
@synthesize doneButton = _doneButton;
@synthesize validationMessage = _validationMessage;
@synthesize spinner = _spinner;


/* ============================================================ Initializers ============================================================ */
- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {

    }
    return self;
}


/* ========================================================== Interface Methods ========================================================= */
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:@"Add City"];
    self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    [_nameOfCityToAdd becomeFirstResponder];
    [_doneButton setAction:@selector(doneAdding:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_validationMessage setHidden:YES];
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [self doneAdding:textField];
    return YES;
}

- (void)validateRequiredProperties
{
    if (!_weatherClient)
    {
        [NSException raise:NSInternalInconsistencyException format:@"Property weatherClient is required."];
    }
    if (!_cityDao)
    {
        [NSException raise:NSInternalInconsistencyException format:@"Property cityDao is required."];
    }
}


/* ============================================================ Utility Methods ========================================================= */
- (void)dealloc
{
    NSLog(@"%@ in dealloc!", self);
}


/* ============================================================ Private Methods ========================================================= */
- (void)doneAdding:(id)sender
{
    if ([[_nameOfCityToAdd text] length] > 0)
    {
        [_validationMessage setText:@"Validating city . ."];
        [_nameOfCityToAdd setEnabled:NO];
        [_validationMessage setHidden:NO];
        [_spinner startAnimating];

        __weak id weatherClientDelegate = self;
        __weak id <PFCityDao> cityDao = _cityDao;


        [_weatherClient loadWeatherReportFor:[_nameOfCityToAdd text] onSuccess:^(PFWeatherReport* weatherReport)
        {
            LogDebug(@"Got weather report: %@", weatherReport);
            [cityDao saveCity:[weatherReport cityDisplayName]];
            [weatherClientDelegate dismissViewControllerAnimated:YES completion:nil];
        } onError:^(NSUInteger statusCode, NSString* message)
        {
            [_spinner stopAnimating];
            [_nameOfCityToAdd setEnabled:YES];
            [_validationMessage setText:[NSString stringWithFormat:@"No weather reports for '%@'.", [_nameOfCityToAdd text]]];
        }];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end