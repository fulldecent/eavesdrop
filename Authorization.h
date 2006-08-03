/*
 *  Authorization.h
 *  Eavesdrop
 *
 *  Created by Eric Baur on 10/12/04.
 *  Copyright 2004 Eric Shore Baur. All rights reserved.
 *	Well... not really, at this time.  This is Apple's sample code - see copyright below.
 */
/*
	File:		authinfo.h
	Copyright: 	© Copyright 2002 Apple Computer, Inc. All rights reserved.
	Change History (most recent first):
                5/1/02		2.0d2		Improved the reliability of determining the path to the
                                                executable during self-repair.
                12/19/01	2.0d1		First release of self-repair version.
*/


#include <Security/AuthorizationTags.h>
#include <CoreFoundation/CoreFoundation.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>

#include <Security/Authorization.h>
#include <sys/param.h>

//#define DEBUG		/* Log actions to stderr */

//#if defined(DEBUG)
//# define IFDEBUG(code)		code
//#else
//# define IFDEBUG(code)		/* no-op */
//#endif


// Command Ids
enum
{
    kMyAuthorizedCommandOperation1 = 1,
    kMyAuthorizedCommandOperation2 = 2
};



// Command structure
typedef struct MyAuthorizedCommand
{
    int authorizedCommandId;

    // Arguments to operate on
    char file[1024];
        
} MyAuthorizedCommand;



// Exit codes (positive values) and return codes from exec function
enum
{
    kMyAuthorizedCommandInternalError = -1,
    kMyAuthorizedCommandSuccess = 0,
    kMyAuthorizedCommandExecFailed,
    kMyAuthorizedCommandChildError,
    kMyAuthorizedCommandAuthFailed,
    kMyAuthorizedCommandOperationFailed
};

int authorize( const char* path_to_tool, char * const *arguments );
