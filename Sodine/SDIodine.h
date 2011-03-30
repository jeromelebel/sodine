//
//  SDIodine.h
//  Sodine
//
//  Created by Jérôme Lebel on 30/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SDIodine : NSObject
{
    NSString *_nameServerAddress;
    NSString *_topDomain;
    int _selectTimeout;
    int _lazyMode;
    int _hostNameMaxLength;
    int _rawMode;
    int _autoDetectFragmentSize;
    int _maxDownStreamFragmentSize;
    NSString *_password;
}

@property(nonatomic, readwrite, retain) NSString *nameServerAddress;
@property(nonatomic, readwrite, retain) NSString *topDomain;
@property(nonatomic, readwrite, assign) int selectTimeout;
@property(nonatomic, readwrite, assign) int lazyMode;
@property(nonatomic, readwrite, assign) int hostNameMaxLength;
@property(nonatomic, readwrite, assign) int rawMode;
@property(nonatomic, readwrite, assign) int autoDetectFragmentSize;
@property(nonatomic, readwrite, assign) int maxDownStreamFragmentSize;
@property(nonatomic, readwrite, retain) NSString *password;

- (BOOL)load;

@end
