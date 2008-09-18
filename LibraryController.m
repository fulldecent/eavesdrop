//
//  LibraryController.m
//  Eavesdrop
//
//  Created by Eric Baur on 12/15/07.
//  Copyright 2007 Eric Shore Baur. All rights reserved.
//

#import "LibraryController.h"


@implementation LibraryController
#pragma mark -
#pragma mark NSOutlineView Datasource methods

- (id)init
{
	ENTRY;
    self = [super init];
    if (self) {
		libraryArray = [[NSMutableArray array] retain];
		
		[libraryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],	@"isSourceGroup",
			@"Library",						@"name",
			[NSArray array],				@"children",
			nil ]
		];
		
		NSDictionary *pluginDict = [Plugin registeredAggregators];
		NSMutableArray *tempArray = [NSMutableArray array];
		for ( NSString *key in pluginDict ) {
			[tempArray addObject:[NSDictionary dictionaryWithObject:[[pluginDict objectForKey:key] valueForKey:@"name"] forKey:@"name"] ];
		}
		[libraryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],	@"isSourceGroup",
			@"Aggregators",					@"name",
			tempArray,						@"children",
			nil ]
		];
		
		pluginDict  = [Plugin registeredDissectors];
		tempArray = [NSMutableArray array];
		for ( NSString *key in pluginDict ) {
			NSString *tempString = [[pluginDict objectForKey:key] valueForKey:@"protocol"];
			if ( [tempString isEqualToString:@""] )
				[tempArray addObject:[NSDictionary dictionaryWithObject:@"All" forKey:@"name"] ];
			else
				[tempArray addObject:[NSDictionary dictionaryWithObject:tempString forKey:@"name"] ];
		}
		[libraryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],	@"isSourceGroup",
			@"Dissectors",					@"name",
			tempArray,						@"children",
			nil ]
		];
		
		pluginDict  = [Plugin registeredDecoders];
		tempArray = [NSMutableArray array];
		for ( NSString *key in pluginDict ) {
			[tempArray addObject:[NSDictionary dictionaryWithObject:[[pluginDict objectForKey:key] valueForKey:@"name"] forKey:@"name"] ];
		}
		[libraryArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES],	@"isSourceGroup",
			@"Decoders",					@"name",
			tempArray,						@"children",
			nil ]
		];
	}
	EXIT( @"init" );
	return self;
}

@end

