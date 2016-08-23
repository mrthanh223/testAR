//
//  ViewController.m
//  ARTest
//
//  Created by ThanhPham on 8/23/16.
//  Copyright © 2016 LUKINFO Studio. All rights reserved.
//

#import "ViewController.h"
#import <CraftARAugmentedRealitySDK/CraftARSDK.h>
#import <CraftARAugmentedRealitySDK/CraftARCloudRecognition.h>
#import <CraftARAugmentedRealitySDK/CraftARTracking.h>
#import <CraftARAugmentedRealitySDK/CraftARTrackingContentImage.h>

@interface ViewController () <CraftARSDKProtocol, CraftARContentEventsProtocol, SearchProtocol, CraftARTrackingEventsProtocol> {
    CraftARSDK *mSDK;
    CraftARCloudRecognition *mCloudRecognition;
    CraftARTracking* mTracking;
}


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get the instance of the SDK and become delegate
    mSDK = [CraftARSDK sharedCraftARSDK];
    mSDK.delegate = self;
    
    // Get the Cloud recognition module and set 'self' as delegate to receive the SearchProtocol callbacks
    mCloudRecognition = [CraftARCloudRecognition sharedCloudImageRecognition];
    mCloudRecognition.delegate = self;
    
    // Get the tracking module and become delegate to receive tracking events
    mTracking = [CraftARTracking sharedTracking];
    mTracking.delegate = self;
}

- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    // Start the camera capture to be able to perform Single Shot searches
    [mSDK startCaptureWithView:self.videoPreviewView];
}

- (void) viewWillDisappear:(BOOL)animated {
    // stop the capture when the view is disappearing. This releases the camera resources.
    [mSDK stopCapture];
    // Remove all items from the Tracking when leaving the view.
    [mTracking removeAllARItems];
    [super viewWillDisappear:animated];
}

#pragma mark -


#pragma mark Finder mode AR implementation

- (void) didStartCapture {
    
    // The SDK manages the Single shot search and the Finder Mode search, the cloud recognition's
    // search controller is the delegate for doing the searches.
    // This needs to be done after the camera initialization
    mSDK.searchControllerDelegate = mCloudRecognition.mSearchController;
    
    // Set the colleciton we will search using the token.
    __block ViewController* mySelf = self;
    [mCloudRecognition setCollectionWithToken:@"augmentedreality" onSuccess:^{
        NSLog(@"Ready to search!");
        mySelf._scanOverlay.hidden = false;
        
        // The Search methods (Single shot search and Finder Mode) are controlled by
        // the SDK. The searchControllerDelegate will receive the camera events and search
        // with the picture or image frames coming from the camera.
        [[CraftARSDK sharedCraftARSDK] startFinder];
    } andOnError:^(NSError *error) {
        NSLog(@"Error setting token: %@", error.localizedDescription);
    }];
}

- (void) didGetSearchResults:(NSArray *)results {
    
    bool haveARItems = NO;
    
    if ([results count] >= 1) {
        [mSDK stopFinder];
        // Found one result, launch its content on a webView:
        CraftARSearchResult *result = [results objectAtIndex:0];
        
        // Each result has one item
        CraftARItem* item = result.item;
        
        if ([item isKindOfClass:[CraftARItemAR class]]) {
            CraftARItemAR* arItem = (CraftARItemAR*)item;
            
            // Local content creation
            CraftARTrackingContentImage *image = [[CraftARTrackingContentImage alloc] initWithImageNamed:@"AR_programmatically_content" ofType:@"png"];
            image.wrapMode = CRAFTAR_TRACKING_WRAP_ASPECT_FIT;
            [arItem addContent:image];
            
            NSError *err = [mTracking addARItem:arItem];
            if (err) {
                NSLog(@"Error adding AR item: %@", err.localizedDescription);
            }
            haveARItems = YES;
        }
        if (haveARItems) {
            self._scanOverlay.hidden = YES;
            [mTracking startTracking];
        } else {
            [mSDK startFinder];
        }
    }
}

- (void) didFailSearchWithError:(NSError *)error {
    // Check the error type
    NSLog(@"Error calling CRS: %@", [error localizedDescription]);
}

#pragma mark -

#pragma mark Receive Tracking and contents events

// Using the CraftARTrackingEventsProtocol and becoming delegate of the CraftARTracking class,
// you can start receiving globally all tracking events produced by the SDK on the items added.

- (void) didStartTrackingItem:(CraftARItemAR *)item {
    NSLog(@"Start tracking: %@", item.name);
}

- (void) didStopTrackingItem:(CraftARItemAR *)item {
    NSLog(@"Stop tracking: %@", item.name);
}

// The CraftARContentEventsProtocol protocol allows to receive events for specific contents
// You can navigate to the parent item of a content using content.parentARItem
- (void) didGetTouchEvent:(CraftARContentTouchEvent)event forContent:(CraftARTrackingContent *)content {
    switch (event) {
        case CRAFTAR_CONTENT_TOUCH_IN:
            NSLog(@"Touch in: %@", content.uuid);
            break;
        case CRAFTAR_CONTENT_TOUCH_OUT:
            NSLog(@"Touch out: %@", content.uuid);
            break;
        case CRAFTAR_CONTENT_TOUCH_UP:
            NSLog(@"Touch up: %@", content.uuid);
            break;
        case CRAFTAR_CONTENT_TOUCH_DOWN:
            NSLog(@"Touch down: %@", content.uuid);
            break;
        default:
            break;
    }
}

@end
