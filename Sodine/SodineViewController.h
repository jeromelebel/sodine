//
//  SodineViewController.h
//  Sodine
//
//  Created by Jérôme Lebel on 29/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SDIodine;

@interface SodineViewController : UIViewController
{
    IBOutlet UITextField *_topDomain;
    IBOutlet UITextField *_password;

    SDIodine *_iodine;
}

- (IBAction)startAction:(id)sender;

@end
