//
//  SDIodineServer.h
//  Sodine
//
//  Created by Jérôme Lebel on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SDIodineServer : NSObject
{
    int _port;
    NSString *_topDomain;
	in_addr_t _listenIP;
    NSString *_listenIPString;
}

@property(nonatomic, assign, readwrite) int port;
@property(nonatomic, retain, readwrite) NSString *topDomain;
@property(nonatomic, assign, readwrite) NSString *passwordValue;
@property(nonatomic, assign, readwrite) int debugFlag;

- (void)run;

@end
