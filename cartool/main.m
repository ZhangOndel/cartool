//
//  main.m
//  cartool
//
//  Created by Steven Troughton-Smith on 14/07/2013.
//  Copyright (c) 2013 High Caffeine Content. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CUICommonAssetStorage : NSObject

-(NSArray *)allAssetKeys;
-(NSArray *)allRenditionNames;

-(id)initWithPath:(NSString *)p;

-(NSString *)versionString;

@end

@interface CUINamedImage : NSObject

@property(readonly) CGSize size;
@property(readonly) double scale;
@property(readonly) long long idiom;

-(CGImageRef)image;

@end

@interface CUIRenditionKey : NSObject
@end

@interface CUIThemeFacet : NSObject

+(CUIThemeFacet *)themeWithContentsOfURL:(NSURL *)u error:(NSError **)e;

@end

@interface CUICatalog : NSObject
-(id)initWithName:(NSString *)n fromBundle:(NSBundle *)b;
-(id)allKeys;
-(CUINamedImage *)imageWithName:(NSString *)n scaleFactor:(CGFloat)s;
-(CUINamedImage *)imageWithName:(NSString *)n scaleFactor:(CGFloat)s deviceIdiom:(int)idiom;
-(NSArray *)imagesWithName:(NSString *)n;
@end

#define kCoreThemeIdiomPhone 1
#define kCoreThemeIdiomPad 2

void CGImageWriteToFile(CGImageRef image, NSString *path)
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }
    
    CFRelease(destination);
}


void exportCarFileAtPath(NSString * carPath, NSString *outputDirectoryPath)
{
    NSError *error = nil;
    
    outputDirectoryPath = [outputDirectoryPath stringByExpandingTildeInPath];
    
    CUIThemeFacet *facet = [CUIThemeFacet themeWithContentsOfURL:[NSURL fileURLWithPath:carPath] error:&error];
    
    CUICatalog *catalog = [[CUICatalog alloc] init];
    
    [catalog setValue:facet forKey:@"_storageRef"];
    
    CUICommonAssetStorage *storage = [[NSClassFromString(@"CUICommonAssetStorage") alloc] initWithPath:carPath];
    
    for (NSString *key in [storage allRenditionNames])
    {
        printf("%s\n", [key UTF8String]);
        
        for(NSString *scale in @[@"3", @"2"]) {
            CGImageRef imageRef = [[catalog imageWithName:key scaleFactor:scale.doubleValue] image];
            
            if(imageRef == nil) {
                continue;
                
            }
            CGFloat width = CGImageGetWidth(imageRef);
            CGImageWriteToFile(imageRef, [outputDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@%@x.png", key, scale]]);
        }
    }
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        if (argc != 3)
        {
            printf("Usage: cartool Assets.car outputDirectory\n");
            return -1;
        }
        
        exportCarFileAtPath([NSString stringWithUTF8String:argv[1]], [NSString stringWithUTF8String:argv[2]]);
        
    }
    return 0;
}

