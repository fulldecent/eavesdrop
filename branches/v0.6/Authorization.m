/*
 *  Authorization.m
 *  Eavesdrop
 *
 *  Created by Eric Baur on 10/12/04.
 *  Copyright 2004 Eric Shore Baur. All rights reserved.
 *  (a lot of help from Apple's sample code)
 */

#include <Cocoa/Cocoa.h>

#include "Authorization.h"

int authorize( const char* path_to_tool, char * const *arguments )
{
	IFDEBUG(NSLog( @"Waiting for authorization..." ));
    AuthorizationRef authorizationRef;
    OSStatus status;

    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
    if (status != errAuthorizationSuccess) {
        IFDEBUG(NSLog( @"Failed to create the authref: %ld.", status));
        return kMyAuthorizedCommandInternalError;
    } else {
		if (AuthorizationExecuteWithPrivileges(authorizationRef,path_to_tool,kAuthorizationFlagDefaults,arguments,NULL)) {
			IFDEBUG(NSLog( @"authorization failed, giving up."));
			return kMyAuthorizedCommandInternalError;
		}
		IFDEBUG(NSLog( @"authorization succeeded.");)
		AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
    }

    return 0;
}