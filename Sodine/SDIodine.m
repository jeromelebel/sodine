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
#include "dns.h"
#include "login.h"

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

- (int)handshake_login:(int)seed
{
	char in[4096];
	char login[16];
	char server[65];
	char client[65];
	int mtu;
	int i;
	int read;
    
	login_calculate(login, 16, password, seed);
	
	for (i=0; running && i<5 ;i++) {
        
		send_login(_dnsFD, login, 16);
        
		read = handshake_waitdns(_dnsFD, in, sizeof(in), 'l', 'L', i+1);
        
		/*XXX START adjust indent 1 tab back*/
        if (read > 0) {
            int netmask;
            if (strncmp("LNAK", in, 4) == 0) {
                fprintf(stderr, "Bad password\n");
                return 1;
            } else if (sscanf(in, "%64[^-]-%64[^-]-%d-%d", 
                              server, client, &mtu, &netmask) == 4) {
                return 0;
            } else {
                fprintf(stderr, "Received bad handshake\n");
            }
        }
		/*XXX END adjust indent 1 tab back*/
        
		fprintf(stderr, "Retrying login...\n");
	}
	warnx("couldn't login to server");
	return 1;
}

- (int)client_handshake
{
	int seed;
	int upcodec;
	int r;
    
	dnsc_use_edns0 = 0;
    
	/* qtype message printed in handshake function */
	if (do_qtype == T_UNSET) {
		r = handshake_qtype_autodetect(_dnsFD);
		if (r) {
			return r;
		}
	}
    
	fprintf(stderr, "Using DNS type %s queries\n", get_qtype());
    
	r = handshake_version(_dnsFD, &seed);
	if (r) {
		return r;
	}
    
	r = [self handshake_login:seed];
	if (r) {
		return r;
	}
    
	if (_rawMode && handshake_raw_udp(_dnsFD, seed)) {
		conn = CONN_RAW_UDP;
		selecttimeout = 20;
	} else {
		if (_rawMode == 0) {
			fprintf(stderr, "Skipping raw mode\n");
		}
        
		dnsc_use_edns0 = 1;
		if (handshake_edns0_check(_dnsFD) && running) {
			fprintf(stderr, "Using EDNS0 extension\n");
		} else if (!running) {
			return -1;
		} else {
			fprintf(stderr, "DNS relay does not support EDNS0 extension\n");
			dnsc_use_edns0 = 0;
		}
        
		upcodec = handshake_upenc_autodetect(_dnsFD);
		if (!running)
			return -1;
        
		if (upcodec == 1) {
			handshake_switch_codec(_dnsFD, 6);
		} else if (upcodec == 2) {
			handshake_switch_codec(_dnsFD, 26);
		} else if (upcodec == 3) {
			handshake_switch_codec(_dnsFD, 7);
		}
		if (!running)
			return -1;
        
		if (downenc == ' ') {
			downenc = handshake_downenc_autodetect(_dnsFD);
		}
		if (!running)
			return -1;
        
		if (downenc != ' ') {
			handshake_switch_downenc(_dnsFD);
		}
		if (!running)
			return -1;
        
		if (lazymode) {
			handshake_try_lazy(_dnsFD);
		}
		if (!running)
			return -1;
        
		if (_autoDetectFragmentSize) {
			_maxDownStreamFragmentSize = handshake_autoprobe_fragsize(_dnsFD);
			if (!_maxDownStreamFragmentSize) {
				return 1;
			}
		}
        
		handshake_set_fragsize(_dnsFD, _maxDownStreamFragmentSize);
		if (!running)
			return -1;
	}
    
	return 0;
}

- (BOOL)load
{
    BOOL result = YES;
    
    client_init();
    client_set_nameserver([_nameServerAddress UTF8String], DNS_PORT);
	client_set_selecttimeout(_selectTimeout);
	client_set_lazymode(_lazyMode);
	client_set_topdomain([_topDomain UTF8String]);
	client_set_hostname_maxlen(_hostNameMaxLength);
    client_set_password([_password UTF8String]);
	if ((_dnsFD = open_dns(0, INADDR_ANY)) == -1) {
        NSLog(@"no open DNS");
        result = NO;
    }
    NSLog(@"open dns %@", result?@"YES":@"NO");
	if ([self client_handshake]) {
        NSLog(@"no client hand shake");
        result = NO;
	}
    NSLog(@"result %@", result?@"YES":@"NO");
    return result;
}

@end
