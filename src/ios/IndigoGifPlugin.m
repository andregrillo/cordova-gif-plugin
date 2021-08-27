/********* IndigoGifPlugin.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <Photos/Photos.h>

@interface IndigoGifPlugin : CDVPlugin {
  
}
- (void)saveGifToPhotoAlbum:(CDVInvokedUrlCommand*)command;
- (void)shareGif:(CDVInvokedUrlCommand*)command;
@end

@implementation IndigoGifPlugin

NSString *callbackId;

- (void)saveGifToPhotoAlbum:(CDVInvokedUrlCommand*)command {
    callbackId = command.callbackId;
    NSString *gifPath = [command.arguments objectAtIndex:0];
    NSURL *gifURL = [NSURL URLWithString:gifPath];
    NSData *data = [NSData dataWithContentsOfURL:gifURL];

    [self checkPhotoAlbumPermissions];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"：%d",success);
            if (error != nil) {
                CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
            } else {
                CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
            }
        }];
    });
}

- (void)shareGif:(CDVInvokedUrlCommand*)command {
    if (!NSClassFromString(@"UIActivityViewController")) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"not available"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    NSString *base64String = [command.arguments objectAtIndex:0];
    NSURL *imageUrl = [NSURL URLWithString:base64String];
    NSData *animatedGifData = [NSData dataWithContentsOfURL:imageUrl];
    NSArray *sharingItems = [NSArray arrayWithObjects: animatedGifData, nil];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
        
        if ([activityController respondsToSelector:(@selector(setCompletionWithItemsHandler:))]) {
            [activityController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray * returnedItems, NSError * activityError) {
                if (completed == YES || activityType == nil) {
                    //            [self cleanupStoredFiles];
                }
                NSDictionary * result = @{@"completed":@(completed), @"app":activityType == nil ? @"" : activityType};
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                            callbackId:command.callbackId];
            }];
        } else {
            // let's suppress this warning otherwise folks will start opening issues while it's not relevant
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
                if (completed == YES || activityType == nil) {
                    //              [self cleanupStoredFiles];
                }
                NSDictionary * result = @{@"completed":@(completed), @"app":activityType == nil ? @"" : activityType};
                CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }];
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
        }
        NSArray * socialSharingExcludeActivities = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SocialSharingExcludeActivities"];
        if (socialSharingExcludeActivities!=nil && [socialSharingExcludeActivities count] > 0) {
            activityController.excludedActivityTypes = socialSharingExcludeActivities;
        }
        //    dispatch_async(dispatch_get_main_queue(), ^(void){
        [[self getTopMostViewController] presentViewController:activityController animated:YES completion:nil];
        //    });
        
        
    });
}

- (UIViewController*) getTopMostViewController {
  UIViewController *presentingViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
  while (presentingViewController.presentedViewController != nil) {
    presentingViewController = presentingViewController.presentedViewController;
  }
  return presentingViewController;
}

- (void) checkPhotoAlbumPermissions {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        // Access has been granted.
    } else {
        if (status == PHAuthorizationStatusDenied) {
            // Access has been denied.
            [self showAlert];
        } else {
            if (status == PHAuthorizationStatusNotDetermined) {
                // Access has not been determined.
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    if (status == PHAuthorizationStatusAuthorized) {
                        // Access has been granted.
                    }
                    else {
                        // Denied; show an alert
                        [self showAlert];
                    }
                }];
            }
            else {
                if (status == PHAuthorizationStatusRestricted) {
                    // Restricted access
                }
            }
        }
    }
}

- (void) showAlert {
  // Denied; show an alert
  __weak IndigoGifPlugin* weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
      UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] message:NSLocalizedString(@"Access to the Photo Album has been denied. Please enable it in the Settings app to continue.", nil) preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          //[weakSelf sendNoPermissionResult:command.callbackId];
      }]];
      [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
          //[weakSelf sendNoPermissionResult:command.callbackId];
      }]];
      [weakSelf.viewController presentViewController:alertController animated:YES completion:nil];
  });
  CDVPluginResult* resulterror = [CDVPluginResult
                                  resultWithStatus:CDVCommandStatus_ERROR
                                  messageAsString:@"PhotoAlbumAccessIsDenied"];
  [self.commandDelegate sendPluginResult:resulterror callbackId:callbackId];
}

@end
