#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface CKTranscriptController : UIViewController 
@end

@interface CKComposition : NSObject
@property(copy) NSAttributedString *subject;
@property(copy) NSAttributedString *text;
- (id)initWithText:(id)arg1 subject:(id)arg2;
@end

@interface CKIMFileTransfer : NSObject
- (id)initWithFileURL:(id)arg1 transcoderUserInfo:(id)arg2;
-(void)mediaObjectAdded;
- (void)updateTransfer;
@end

@interface CKImageMediaObject : NSTextAttachment
- (id)initWithTransfer:(id)arg1;
@end

NSRegularExpression *imgurExpression;
NSRegularExpression *pngExpression;
NSRegularExpression *jpgExpression;
BOOL enabled = YES;

static void reloadSettings(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
NSDictionary *prefs = [NSDictionary 
        dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.efrederickson.pollux.settings.plist"];

    if ([prefs objectForKey:@"enabled"] != nil)
        enabled = [[prefs objectForKey:@"enabled"] boolValue];
    else
        enabled = YES;

}

%hook CKTranscriptController
-(void)sendMessage:(CKComposition*)message
{
    if (!enabled)
    {
        %orig;
        return;
    }

    NSTextCheckingResult *result = [imgurExpression firstMatchInString:message.text.string
                                                      options:0
                                                        range:NSMakeRange(0, message.text.string.length)];
                                                        
    NSTextCheckingResult *resultPng = [pngExpression firstMatchInString:message.text.string
                                                      options:0
                                                        range:NSMakeRange(0, message.text.string.length)];
                                    
    NSTextCheckingResult *resultJpg = [jpgExpression firstMatchInString:message.text.string
                                                      options:0
                                                        range:NSMakeRange(0, message.text.string.length)];

    if ([result rangeAtIndex:4].length > 0) // if the actual image link is above 0 characters
    {
        UIWindow* mainWindow = [[UIApplication sharedApplication] keyWindow];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:mainWindow animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Loading";
        [hud removeFromSuperview];
        UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
        [window addSubview:hud];
        [window bringSubviewToFront:hud];

        NSString *key = [message.text.string substringWithRange:[result rangeAtIndex:4]];
        NSString *stringURL = [NSString stringWithFormat:@"%@%@%@",@"https://i.imgur.com/",key,@".png"];

        NSURL  *url = [NSURL URLWithString:stringURL];

        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *urlData, NSError *error)
        {
            if (error)
            {
                //NSLog(@"Error,%@", [error localizedDescription]);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [hud hide:YES];
                    %orig;
                });
            }
            else
            {
                NSString  *filePath;
                NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString  *documentsDirectory = [paths objectAtIndex:0];

                filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,[NSString stringWithFormat:@"%@%@",key,@".png"]];
                [urlData writeToFile:filePath atomically:YES];

                dispatch_sync(dispatch_get_main_queue(), ^{
                    CKIMFileTransfer *trans = [[CKIMFileTransfer alloc] initWithFileURL:[NSURL URLWithString:filePath] transcoderUserInfo:nil];
                    CKImageMediaObject *image = [[CKImageMediaObject alloc] initWithTransfer:trans];

                    NSAttributedString *text = message.text;
                    NSMutableAttributedString *mod = [[NSMutableAttributedString alloc] initWithAttributedString:text];

                    NSAttributedString *attachmentStr = [NSAttributedString attributedStringWithAttachment:image];

                    int location = -1;
                    int len = 0;
                    for (int i = 1; i < 6; i++)
                    {
                        len += [result rangeAtIndex:i].length;
                        if (location == -1)
                            if ([result rangeAtIndex:i].location != NSNotFound)
                                location = [result rangeAtIndex:i].location;
                    }
                    NSRange imgurRange = NSMakeRange(location, len);

                    [mod replaceCharactersInRange:imgurRange withAttributedString:attachmentStr];

                    message.text = mod;

                    //NSLog(@"[CKTranscriptController sendMessage:%@]", message);

                    [hud hide:YES];
                    %orig(message);
                });
            }
        }];
    }
    else if ([resultPng rangeAtIndex:0].length > 0)
    {
        UIWindow* mainWindow = [[UIApplication sharedApplication] keyWindow];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:mainWindow animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Loading";
        [hud removeFromSuperview];
        UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
        [window addSubview:hud];
        [window bringSubviewToFront:hud];

        int len = [resultPng rangeAtIndex:0].length;
        int location = [resultPng rangeAtIndex:0].location;

        NSRange urlRange = NSMakeRange(location, len);

        NSString *stringURL = [[message.text attributedSubstringFromRange:urlRange] string];

        NSURL  *url = [NSURL URLWithString:stringURL];

        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *urlData, NSError *error)
        {
            if (error)
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [hud hide:YES];
                    %orig;
                });
            }
            else
            {
                NSString  *filePath;
                NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString  *documentsDirectory = [paths objectAtIndex:0];

                filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,[NSString stringWithFormat:@"pollux.png"]];
                [urlData writeToFile:filePath atomically:YES];

                dispatch_sync(dispatch_get_main_queue(), ^{
                    CKIMFileTransfer *trans = [[CKIMFileTransfer alloc] initWithFileURL:[NSURL URLWithString:filePath] transcoderUserInfo:nil];
                    CKImageMediaObject *image = [[CKImageMediaObject alloc] initWithTransfer:trans];

                    NSAttributedString *text = message.text;
                    NSMutableAttributedString *mod = [[NSMutableAttributedString alloc] initWithAttributedString:text];

                    NSAttributedString *attachmentStr = [NSAttributedString attributedStringWithAttachment:image];

                    [mod replaceCharactersInRange:urlRange withAttributedString:attachmentStr];

                    message.text = mod;

                    [hud hide:YES];
                    %orig(message);
                });
            }
        }];
    }
    else if ([resultJpg rangeAtIndex:0].length > 0)
    {
        UIWindow* mainWindow = [[UIApplication sharedApplication] keyWindow];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:mainWindow animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Loading";
        [hud removeFromSuperview];
        UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
        [window addSubview:hud];
        [window bringSubviewToFront:hud];

        int len = [resultJpg rangeAtIndex:0].length;
        int location = [resultJpg rangeAtIndex:0].location;

        NSRange urlRange = NSMakeRange(location, len);

        NSString *stringURL = [[message.text attributedSubstringFromRange:urlRange] string];

        NSURL  *url = [NSURL URLWithString:stringURL];

        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *urlData, NSError *error)
        {
            if (error)
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [hud hide:YES];
                    %orig;
                });
            }
            else
            {
                NSString  *filePath;
                NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString  *documentsDirectory = [paths objectAtIndex:0];

                filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,[NSString stringWithFormat:@"pollux.png"]];
                [urlData writeToFile:filePath atomically:YES];

                dispatch_sync(dispatch_get_main_queue(), ^{
                    CKIMFileTransfer *trans = [[CKIMFileTransfer alloc] initWithFileURL:[NSURL URLWithString:filePath] transcoderUserInfo:nil];
                    CKImageMediaObject *image = [[CKImageMediaObject alloc] initWithTransfer:trans];

                    NSAttributedString *text = message.text;
                    NSMutableAttributedString *mod = [[NSMutableAttributedString alloc] initWithAttributedString:text];

                    NSAttributedString *attachmentStr = [NSAttributedString attributedStringWithAttachment:image];

                    [mod replaceCharactersInRange:urlRange withAttributedString:attachmentStr];

                    message.text = mod;

                    [hud hide:YES];
                    %orig(message);
                });
            }
        }];
    }
    else
        %orig;
}
%end

%ctor
{
    NSError *error = nil;
    NSString *pattern = @"(https?:\\/\\/)?(i?m?\\.)?(imgur\\.com\\/)([A-Za-z0-9]{7})(\\.png)?";
    imgurExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];

    NSString *png = @"\\b([\\d\\w\\.\\/\\+\\-\\?\\:]*)((ht|f)tp(s|)\\:\\/\\/|[\\d\\d\\d|\\d\\d]\\.[\\d\\d\\d|\\d\\d]\\.|www\\.|\\.tv|\\.ac|\\.com|\\.edu|\\.gov|\\.int|\\.mil|\\.net|\\.org|\\.biz|\\.info|\\.name|\\.pro|\\.museum|\\.co)([\\d\\w\\.\\/\\%\\+\\-\\=\\&amp;\\?\\:\\\\\\&quot;\\'\\,\\|\\~\\;]*png)\\b";
    NSString *jpg = @"\\b([\\d\\w\\.\\/\\+\\-\\?\\:]*)((ht|f)tp(s|)\\:\\/\\/|[\\d\\d\\d|\\d\\d]\\.[\\d\\d\\d|\\d\\d]\\.|www\\.|\\.tv|\\.ac|\\.com|\\.edu|\\.gov|\\.int|\\.mil|\\.net|\\.org|\\.biz|\\.info|\\.name|\\.pro|\\.museum|\\.co)([\\d\\w\\.\\/\\%\\+\\-\\=\\&amp;\\?\\:\\\\\\&quot;\\'\\,\\|\\~\\;]*jpg)\\b";
    
    pngExpression = [NSRegularExpression regularExpressionWithPattern:png options:0 error:&error];
    jpgExpression = [NSRegularExpression regularExpressionWithPattern:jpg options:0 error:&error];

    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, &reloadSettings, CFSTR("com.efrederickson.pollux.settings/reloadSettings"), NULL, 0);
    reloadSettings(NULL, NULL, NULL, NULL, NULL);
}
