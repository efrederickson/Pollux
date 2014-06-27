#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>

@interface PolluxSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation PolluxSettingsListController
-(NSString*) plistName { return @"PolluxSettings"; }
-(UIColor*) switchOnTintColor { return [UIColor orangeColor]; }
-(NSString*) headerText { return @"Pollux"; }
-(NSString*) headerSubText { return @"Free Message Enhancements"; }
-(BOOL) tintNavigationTitleText { return NO; }
-(UIColor*) heartImageColor { return [UIColor orangeColor]; }
-(UIColor*) navigationTintColor { return [UIColor orangeColor]; }
-(UIColor*) iconColor { return self.navigationTintColor; }

-(NSString*) customTitle { return @"Pollux"; }
-(NSArray*) customSpecifiers
{
    return @[ 
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.pollux.settings",
                 @"key": @"enabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.pollux.settings/reloadSettings",
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"enabled.png"
                 }
             ];
}
@end
