//
//  HSKHDMImgageAssetsViewModel.h
//  HouseDecorateModule
//
//  Created by Sam on 12/03/2018.
//  Copyright © 2018 com.best. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HSKHDMAsset;
@class HSKHDMAlbum;

extern NSString * const HSKHDMPhotoLibraryChangedNotification;
@interface HSKHDMAsset : YYModel
@property (nonatomic, readonly) RACSignal *imageSignal;
@property (nonatomic, readonly) PHAsset   *asset;
@property (nonatomic, readonly) CGSize     targetSize;
@property (nonatomic, readonly) NSString  *identifier;

+ (NSArray <HSKHDMAsset *> *)allAssetsForSize:(CGSize)targetSize;
- (instancetype)assetForSize:(CGSize)targetSize;
@end


@interface HSKHDMAlbum : YYModel
@property (nonatomic, readonly) NSString    *title;
@property (nonatomic, readonly) CGSize       targetSize;
@property (nonatomic, readonly) HSKHDMAsset *cover;
@property (nonatomic, readonly) NSArray  <HSKHDMAsset *> *assets;

+ (void)prepare:(void(^)(BOOL success))completeBlock;
+ (instancetype)albumForTitle:(NSString *)title size:(CGSize)targetSize;
+ (NSArray <HSKHDMAlbum *> *)albumsWithSize:(CGSize)targetSize;
- (instancetype)albumForSize:(CGSize)targetSize;
@end


