//
//  SodineViewController.m
//  Sodine
//
//  Created by Jérôme Lebel on 29/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SodineViewController.h"
#import "SDIodine.h"

#define IODINE_PASSWORD_KEY @"iodine.password"
#define IODINE_TOP_DOMAIN_KEY @"iodine.top_domain"

@implementation SodineViewController

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)_loadInfo
{
    _password.text = [[NSUserDefaults standardUserDefaults] stringForKey:IODINE_PASSWORD_KEY];
    _topDomain.text = [[NSUserDefaults standardUserDefaults] stringForKey:IODINE_TOP_DOMAIN_KEY];
}

- (void)_saveInfo
{
    [[NSUserDefaults standardUserDefaults] setValue:_password.text forKey:IODINE_PASSWORD_KEY];
    [[NSUserDefaults standardUserDefaults] setValue:_topDomain.text forKey:IODINE_TOP_DOMAIN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    _iodine = [[SDIodine alloc] init];
    [self _loadInfo];
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self _saveInfo];
    [_iodine release];
    _iodine = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)startAction:(id)sender
{
    [self _saveInfo];
    _iodine.topDomain = _topDomain.text;
    _iodine.password = _password.text;
    [_iodine load];
}

@end
