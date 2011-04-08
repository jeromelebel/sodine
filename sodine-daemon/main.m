//
//  main.m
//  sodine-daemon
//
//  Created by Jérôme Lebel on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDIodineServer.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool *pool;
    SDIodineServer *iodineServer;
    NSString *topDomain = nil;
    NSString *password = nil;
    
    pool = [[NSAutoreleasePool alloc] init];
    if (argc > 2) {
        topDomain = [NSString stringWithUTF8String:argv[1]];
        password = [NSString stringWithUTF8String:argv[2]];
    }
    if (topDomain) {
        iodineServer = [[SDIodineServer alloc] init];
        iodineServer.port = 5360;
        iodineServer.topDomain = topDomain;
        iodineServer.passwordValue = password;
        [iodineServer run];
    }
    [pool release];
}

