/*
 *  Authorization.m
 *  Eavesdrop
 *
 *  Created by Eric Baur on 10/12/04.
 *  Copyright 2004 Eric Shore Baur. All rights reserved.
 *  (a lot of help from Apple's sample code, see .h file)
 */

#include "Authorization.h" 

int authorize( const char* path_to_tool, char * const *arguments )
{
	IFDEBUG(NSLog( @"Waiting for authorization..." ));
    AuthorizationRef authorizationRef;
    OSStatus status;

	AuthorizationItem myItems = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights myRights = {1, &myItems};
	AuthorizationFlags myFlags = kAuthorizationFlagDefaults |
		kAuthorizationFlagExtendRights |
		kAuthorizationFlagInteractionAllowed |
		kAuthorizationFlagPreAuthorize;

	//create the authorization ref.
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
    if (status != errAuthorizationSuccess) {
        IFDEBUG(NSLog( @"Failed to create the authref: %ld.", status));
        return -1;
    }
	
	//ask for admin rights
	status = AuthorizationCopyRights (authorizationRef, &myRights, NULL, myFlags, NULL );
	if ( status != errAuthorizationSuccess ) {
		IFDEBUG(NSLog( @"authorization copy failed, giving up: %ld.", status));
		return -1;
	}

	//launch the tool
	status = AuthorizationExecuteWithPrivileges(authorizationRef,path_to_tool,kAuthorizationFlagDefaults,arguments,NULL);
	if (status != errAuthorizationSuccess) {
		IFDEBUG(NSLog( @"authorization execute failed, giving up: %ld.", status));
		return -1;
	}
	IFDEBUG(NSLog( @"authorization succeeded.");)
	AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
    
    return 0;

}