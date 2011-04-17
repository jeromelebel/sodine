//
//  SDIodineServer.m
//  Sodine
//
//  Created by Jérôme Lebel on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SDIodineServer.h"
#include <pwd.h>
#include "common.h"
#include "base32.h"
#include "base64.h"
#include "base64u.h"
#include "base128.h"
#include "fw_query.h"
#include "version.h"
#include "user.h"

extern in_addr_t ns_ip;
extern int debug;
extern int netmask;
extern struct encoder *b32;
extern struct encoder *b64;
extern struct encoder *b64u;
extern struct encoder *b128;
extern char password[33];
extern int bind_port;
extern in_addr_t my_ip;
extern char *topdomain;
extern int my_mtu;
extern int created_users;
extern int check_ip;

void help();
void version();
void usage();
void sigint(int sig);
int tunnel(int tun_fd, int dns_fd, int bind_fd);


@implementation SDIodineServer

@synthesize port = _port;

- (id)init
{
    self = [super init];
    if (!self) {
        _port = DNS_PORT;
        check_ip = 0;
        _listenIP = INADDR_ANY;
        my_mtu = 1130;
        ns_ip = INADDR_ANY;
        created_users = USERS;
    }
    return self;
}

- (void)_checkValues
{
	if(_port < 1 || _port > 65535) {
        [NSException raise:@"bad port" format:@"Bad port number"];
	}
}

- (void)run
{
	char *context;
	int dnsd_fd;
	int tun_fd = 0;
    
	/* settings for forwarding normal DNS to 
	 * local real DNS server */
	int bind_fd;
	int bind_enable;
	int retval;
    
	context = NULL;
	bind_enable = 0;
	bind_fd = 0;
    
	b32 = get_base32_encoder();
	b64 = get_base64_encoder();
	b64u = get_base64u_encoder();
	b128 = get_base128_encoder();
	
	retval = 0;
    
	srand((unsigned int)time(NULL));
	fw_query_init();
    
	if(bind_enable) {
		if (bind_port < 1 || bind_port > 65535) {
			warnx("Bad DNS server port number given.");
			usage();
			/* NOTREACHED */
		}
		/* Avoid forwarding loops */
		if (bind_port == _port && (_listenIP == INADDR_ANY || _listenIP == htonl(0x7f000001L))) {
			warnx("Forward port is same as listen port (%d), will create a loop!", bind_port);
			fprintf(stderr, "Use -l to set listen ip to avoid this.\n");
			usage();
			/* NOTREACHED */
		}
		fprintf(stderr, "Requests for domains outside of %s will be forwarded to port %d\n",
                topdomain, bind_port);
	}
	
	if (ns_ip == INADDR_NONE) {
		warnx("Bad IP address to return as nameserver.");
		usage();
	}
	
	if (strlen(password) == 0) {
		if (NULL != getenv(SERVER_PASSWORD_ENV_VAR))
			snprintf(password, sizeof(password), "%s", getenv(SERVER_PASSWORD_ENV_VAR));
		else
			read_password(password, sizeof(password));
	}
    
	if ((dnsd_fd = open_dns(_port, _listenIP)) == -1) {
		retval = 1;
		goto cleanup2;
	}
	if (bind_enable) {
		if ((bind_fd = open_dns(0, INADDR_ANY)) == -1) {
			retval = 1;
			goto cleanup3;
		}
	}
	
	fprintf(stderr, "Listening to dns for domain %s\n", topdomain);
    
#ifdef FREEBSD
	tzsetwall();
#endif
    
	signal(SIGINT, sigint);
    
	tunnel(tun_fd, dnsd_fd, bind_fd);
    
cleanup3:
	close_dns(bind_fd);
cleanup2:
	close_dns(dnsd_fd);
cleanup1:
	close_tun(tun_fd);	
cleanup0:
    return;
}

- (void)setDebugFlag:(int)debugValue
{
    [self willChangeValueForKey:@"debugFlag"];
    debug = debugValue;
    [self didChangeValueForKey:@"debugFlag"];
}

- (int)debugFlag
{
    return debug;
}

- (void)setPasswordValue:(NSString *)passwordValue
{
    [self willChangeValueForKey:@"passwordValue"];
    if ([passwordValue length] > sizeof(password) - 1) {
        [NSException raise:@"password length" format:@"Password too long"];
    }
    strncpy(password, [passwordValue UTF8String], sizeof(password));
    [self didChangeValueForKey:@"passwordValue"];
}

- (NSString *)passwordValue
{
    return [NSString stringWithUTF8String:password];
}

- (void)setTopDomain:(NSString *)topDomain
{
    [self willChangeValueForKey:@"topDomain"];
    if (topdomain) {
        free(topdomain);
    }
    topdomain = strdup([topDomain UTF8String]);
	if (strlen(topdomain) <= 128) {
		if(check_topdomain(topdomain)) {
            [NSException raise:@"topdomain" format:@"Topdomain contains invalid characters."];
		}
	} else {
        [NSException raise:@"topdomain" format:@"Use a topdomain max 128 chars long."];
	}
    [self didChangeValueForKey:@"topDomain"];
}

- (NSString *)topDomain
{
    return [NSString stringWithUTF8String:topdomain];
}

- (void)setListenIP:(NSString *)listenIP
{
    [self willChangeValueForKey:@"listenIP"];
    [_listenIPString autorelease];
    _listenIPString = [listenIP retain];
    _listenIP = inet_addr([listenIP UTF8String]);
    
	if (_listenIP == INADDR_NONE) {
        [NSException raise:@"listenip" format:@"Bad IP address to listen on."];
	}
    [self didChangeValueForKey:@"listenIP"];
}

- (NSString *)listenIP
{
    return _listenIPString;
}

@end
