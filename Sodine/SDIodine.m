//
//  SDIodine.m
//  Sodine
//
//  Created by Jérôme Lebel on 30/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SDIodine.h"
#import "client.h"
#import "common.h"
#import "util.h"

@implementation SDIodine

@synthesize nameServerAddress = _nameServerAddress;
@synthesize topDomain = _topDomain;
@synthesize selectTimeout = _selectTimeout;
@synthesize lazyMode = _lazyMode;
@synthesize hostNameMaxLength = _hostNameMaxLength;
@synthesize rawMode = _rawMode;
@synthesize autoDetectFragmentSize = _autoDetectFragmentSize;
@synthesize maxDownStreamFragmentSize = _maxDownStreamFragmentSize;
@synthesize password = _password;

- (id)init
{
    self = [super init];
    if (self) {
        self.nameServerAddress = [NSString stringWithCString:get_resolvconf_addr() encoding:NSUTF8StringEncoding];
        self.selectTimeout = 4;
        self.lazyMode = 1;
        self.hostNameMaxLength = 0xFF;
        self.rawMode = 1;
        self.autoDetectFragmentSize = 1;
        self.maxDownStreamFragmentSize = 3072;
    }
    return self;
}

- (BOOL)load
{
    BOOL result = YES;
    int dns_fd;
    
    client_init();
    client_set_nameserver([_nameServerAddress UTF8String], DNS_PORT);
	client_set_selecttimeout(_selectTimeout);
	client_set_lazymode(_lazyMode);
	client_set_topdomain([_topDomain UTF8String]);
	client_set_hostname_maxlen(_hostNameMaxLength);
    client_set_password([_password UTF8String]);
	if ((dns_fd = open_dns(0, INADDR_ANY)) == -1) {
        NSLog(@"no open DNS");
        result = NO;
    }
    NSLog(@"open dns %@", result?@"YES":@"NO");
	if (client_handshake(dns_fd, _rawMode, _autoDetectFragmentSize, _maxDownStreamFragmentSize)) {
        NSLog(@"no client hand shake");
        result = NO;
	}
    NSLog(@"result %@", result?@"YES":@"NO");
    return result;
}

@end
