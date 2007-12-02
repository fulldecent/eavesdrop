/*
 *  Authorization.h
 *  Eavesdrop
 *
 *  Created by Eric Baur on 10/12/04.
 *  Copyright 2004 Eric Shore Baur. All rights reserved.
 *	Well... not really, at this time.  Most of this is Apple's sample code - see copyright below.
 */
/*
	File:		authinfo.h
	Copyright: 	© Copyright 2002 Apple Computer, Inc. All rights reserved.
	Change History (most recent first):
                5/1/02		2.0d2		Improved the reliability of determining the path to the
                                                executable during self-repair.
                12/19/01	2.0d1		First release of self-repair version.
*/


#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#include <CoreFoundation/CoreFoundation.h>

#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <sys/param.h>

#define DEBUG_ON		/* Log actions to stderr */

#if defined(DEBUG_ON)
# define IFDEBUG(code)		code
#else
# define IFDEBUG(code)		/* no-op */
#endif

int authorize( const char* path_to_tool, char * const *arguments );
