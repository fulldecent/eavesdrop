/*
 *  Authorization.c
 *  Eavesdrop
 *
 *  Created by Eric Baur on 10/12/04.
 *  Copyright 2004 Eric Shore Baur. All rights reserved.
 *  (a lot of help from Apple's sample code)
 */

#include "Authorization.h"

int authorize( const char* path_to_tool, char * const *arguments )
{
	IFDEBUG(fprintf(stderr,"authorization()\n"));
    AuthorizationRef authorizationRef;
    OSStatus status;

    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
    if (status != errAuthorizationSuccess) {
        IFDEBUG(fprintf(stderr, "Failed to create the authref: %ld.\n", status));
        return kMyAuthorizedCommandInternalError;
    } else {
		if (AuthorizationExecuteWithPrivileges(authorizationRef,path_to_tool,kAuthorizationFlagDefaults,arguments,NULL)) {
			IFDEBUG(fprintf(stderr, "authorization failed, giving up.\n"));
			return kMyAuthorizedCommandInternalError;
		}
		IFDEBUG(fprintf(stderr, "authorization succeeded.\n");)
		AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
    }

    return 0;
}