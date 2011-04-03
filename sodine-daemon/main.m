//
//  main.m
//  sodine-daemon
//
//  Created by Jérôme Lebel on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <pwd.h>
#include <syslog.h>
#include "common.h"
#include "base32.h"
#include "base64.h"
#include "base64u.h"
#include "base128.h"
#include "fw_query.h"
#include "version.h"
#include "user.h"

extern in_addr_t ns_ip;
extern int check_ip;
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

void help();
void version();
void usage();
void sigint(int sig);
int tunnel(int tun_fd, int dns_fd, int bind_fd);

int main (int argc, const char * argv[])
{
	extern char *__progname;
	in_addr_t listen_ip;
#ifndef WINDOWS32
	struct passwd *pw;
#endif
	int foreground;
	char *username;
	char *newroot;
	char *context;
	char *device;
	char *pidfile;
	int dnsd_fd;
	int tun_fd;
    
	/* settings for forwarding normal DNS to 
	 * local real DNS server */
	int bind_fd;
	int bind_enable;
	
	int choice;
	int port;
	int mtu;
	int skipipconfig;
	char *netsize;
	int retval;
    
#ifndef WINDOWS32
	pw = NULL;
#endif
	username = NULL;
	newroot = NULL;
	context = NULL;
	device = NULL;
	foreground = 0;
	bind_enable = 0;
	bind_fd = 0;
	mtu = 1130;	/* Very many relays give fragsize 1150 or slightly
                 higher for NULL; tun/zlib adds ~17 bytes. */
	listen_ip = INADDR_ANY;
	port = DNS_PORT;
	ns_ip = INADDR_ANY;
	check_ip = 1;
	skipipconfig = 0;
	debug = 0;
	netmask = 27;
	pidfile = NULL;
    
	b32 = get_base32_encoder();
	b64 = get_base64_encoder();
	b64u = get_base64u_encoder();
	b128 = get_base128_encoder();
	
	retval = 0;
    
#ifdef WINDOWS32
	WSAStartup(req_version, &wsa_data);
#endif
    
#if !defined(BSD) && !defined(__GLIBC__)
	__progname = strrchr(argv[0], '/');
	if (__progname == NULL)
		__progname = argv[0];
	else
		__progname++;
#endif
    
	memset(password, 0, sizeof(password));
	srand((unsigned int)time(NULL));
	fw_query_init();
	
	while ((choice = getopt(argc, argv, "vcsfhDu:t:d:m:l:p:n:b:P:z:F:")) != -1) {
		switch(choice) {
            case 'v':
                version();
                break;
            case 'c':
                check_ip = 0;
                break;
            case 's':
                skipipconfig = 1;
                break;
            case 'f':
                foreground = 1;
                break;
            case 'h':
                help();
                break;
            case 'D':
                debug++;
                break;
            case 'u':
                username = optarg;
                break;
            case 't':
                newroot = optarg;
                break;
            case 'd':
                device = optarg;
                break;
            case 'm':
                mtu = atoi(optarg);
                break;
            case 'l':
                listen_ip = inet_addr(optarg);
                break;
            case 'p':
                port = atoi(optarg);
                break;
            case 'n':
                ns_ip = inet_addr(optarg);
                break;
            case 'b':
                bind_enable = 1;
                bind_port = atoi(optarg);
                break;
            case 'F':
                pidfile = optarg;
                break;    
            case 'P':
                strncpy(password, optarg, sizeof(password));
                password[sizeof(password)-1] = 0;
                
                /* XXX: find better way of cleaning up ps(1) */
                memset(optarg, 0, strlen(optarg)); 
                break;
            case 'z':
                context = optarg;
                break;
            default:
                usage();
                break;
		}
	}
    
	argc -= optind;
	argv += optind;
    
	check_superuser(usage);
    
	if (argc != 2) 
		usage();
	
	netsize = strchr(argv[0], '/');
	if (netsize) {
		*netsize = 0;
		netsize++;
		netmask = atoi(netsize);
	}
    
	my_ip = inet_addr(argv[0]);
	
	if (my_ip == INADDR_NONE) {
		warnx("Bad IP address to use inside tunnel.");
		usage();
	}
    
	topdomain = strdup(argv[1]);
	if (strlen(topdomain) <= 128) {
		if(check_topdomain(topdomain)) {
			warnx("Topdomain contains invalid characters.");
			usage();
		}
	} else {
		warnx("Use a topdomain max 128 chars long.");
		usage();
	}
    
	if (username != NULL) {
#ifndef WINDOWS32
		if ((pw = getpwnam(username)) == NULL) {
			warnx("User %s does not exist!", username);
			usage();
		}
#endif
	}
    
	if (mtu <= 0) {
		warnx("Bad MTU given.");
		usage();
	}
	
	if(port < 1 || port > 65535) {
		warnx("Bad port number given.");
		usage();
	}
	
	if(bind_enable) {
		if (bind_port < 1 || bind_port > 65535) {
			warnx("Bad DNS server port number given.");
			usage();
			/* NOTREACHED */
		}
		/* Avoid forwarding loops */
		if (bind_port == port && (listen_ip == INADDR_ANY || listen_ip == htonl(0x7f000001L))) {
			warnx("Forward port is same as listen port (%d), will create a loop!", bind_port);
			fprintf(stderr, "Use -l to set listen ip to avoid this.\n");
			usage();
			/* NOTREACHED */
		}
		fprintf(stderr, "Requests for domains outside of %s will be forwarded to port %d\n",
                topdomain, bind_port);
	}
	
	if (port != 53) {
		fprintf(stderr, "ALERT! Other dns servers expect you to run on port 53.\n");
		fprintf(stderr, "You must manually forward port 53 to port %d for things to work.\n", port);
	}
    
	if (debug) {
		fprintf(stderr, "Debug level %d enabled, will stay in foreground.\n", debug);
		fprintf(stderr, "Add more -D switches to set higher debug level.\n");
		foreground = 1;
	}
    
	if (listen_ip == INADDR_NONE) {
		warnx("Bad IP address to listen on.");
		usage();
	}
	
	if (ns_ip == INADDR_NONE) {
		warnx("Bad IP address to return as nameserver.");
		usage();
	}
	if (netmask > 30 || netmask < 8) {
		warnx("Bad netmask (%d bits). Use 8-30 bits.", netmask);
		usage();
	}
	
	if (strlen(password) == 0) {
		if (NULL != getenv(PASSWORD_ENV_VAR))
			snprintf(password, sizeof(password), "%s", getenv(PASSWORD_ENV_VAR));
		else
			read_password(password, sizeof(password));
	}
    
	created_users = init_users(my_ip, netmask);
    
	if ((tun_fd = open_tun(device)) == -1) {
		retval = 1;
		goto cleanup0;
	}
	if (!skipipconfig) {
		if (tun_setip(argv[0], users_get_first_ip(), netmask) != 0 || tun_setmtu(mtu) != 0) {
			retval = 1;
			goto cleanup1;
		}
	}
	if ((dnsd_fd = open_dns(port, listen_ip)) == -1) {
		retval = 1;
		goto cleanup2;
	}
	if (bind_enable) {
		if ((bind_fd = open_dns(0, INADDR_ANY)) == -1) {
			retval = 1;
			goto cleanup3;
		}
	}
    
	my_mtu = mtu;
	
	if (created_users < USERS) {
		fprintf(stderr, "Limiting to %d simultaneous users because of netmask /%d\n",
                created_users, netmask);
	}
	fprintf(stderr, "Listening to dns for domain %s\n", topdomain);
    
	if (foreground == 0) 
		do_detach();
	
	if (pidfile != NULL)
		do_pidfile(pidfile);
    
#ifdef FREEBSD
	tzsetwall();
#endif
#ifndef WINDOWS32
	openlog( __progname, LOG_NDELAY, LOG_DAEMON );
#endif
    
	if (newroot != NULL)
		do_chroot(newroot);
    
	signal(SIGINT, sigint);
	if (username != NULL) {
#ifndef WINDOWS32
		gid_t gids[1];
		gids[0] = pw->pw_gid;
		if (setgroups(1, gids) < 0 || setgid(pw->pw_gid) < 0 || setuid(pw->pw_uid) < 0) {
			warnx("Could not switch to user %s!\n", username);
			usage();
		}
#endif
	}
    
	if (context != NULL)
		do_setcon(context);
    
	syslog(LOG_INFO, "started, listening on port %d", port);
	
	tunnel(tun_fd, dnsd_fd, bind_fd);
    
	syslog(LOG_INFO, "stopping");
cleanup3:
	close_dns(bind_fd);
cleanup2:
	close_dns(dnsd_fd);
cleanup1:
	close_tun(tun_fd);	
cleanup0:
    
	return retval;
}

