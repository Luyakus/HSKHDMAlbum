//
//  HouseDecorateModule
//
//  Created by Sam on 12/03/2018.
//  Copyright © 2018 com.best. All rights reserved.
//

#import "HSKHDMAssetsModel.h"
#define _HDMAM_CM [HSKHDMAssetManager defaultManager].manager
#define _HDMAM    [HSKHDMAssetManager defaultManager]

@interface HSKHDMholderAlbum : HSKBaseModel
@property (nonatomic, copy  ) NSString *title;
@property (nonatomic, strong) NSArray <PHAsset *> *assets;
+ (instancetype)albumWithAssets:(NSArray <PHAsset *> *)assets title:(NSString *)title;
@end
@implementation HSKHDMholderAlbum
+ (instancetype)albumWithAssets:(NSArray <PHAsset *> *)assets title:(NSString *)title
{
    HSKHDMholderAlbum *a = [HSKHDMholderAlbum new];
    a.assets = assets;
    a.title  = title;
    return a;
}
@end


@interface HSKHDMAsset()
@property (nonatomic, strong) PHAsset   *asset;
@property (nonatomic, assign) CGSize     targetSize;
@property (nonatomic, strong) RACSignal *imageSignal;
@property (nonatomic, copy  ) NSString  *identifier;
@end

@interface HSKHDMAlbum()
@property (nonatomic, copy  ) NSString *title;
@property (nonatomic, strong) NSArray  <HSKHDMAsset *> *assets;
@property (nonatomic, assign) CGSize   targetSize;
@end



@interface PHFetchResult(collect)
- (NSArray *)collect:(BOOL (^)(id element))filter;
@end
@implementation PHFetchResult(collect)
- (NSArray *)collect:(BOOL (^)(id element))filter;
{
    NSMutableArray *_ = @[].mutableCopy;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!filter) [_ addObject:obj];
        if (filter && filter(obj)) [_ addObject:obj];
    }];
    return _.copy;
}
@end

typedef void(^HSKHDMAssethandle)(UIImage *image);
NSString * const HSKHDMPhotoLibraryChangedNotification = @"HSKHDMPhotoLibraryChangedNotification";
@interface HSKHDMAssetManager : HSKBaseModel <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHCachingImageManager *manager;
@property (nonatomic, strong) NSMutableArray <HSKHDMholderAlbum *> *albums;
@property (nonatomic, strong) NSMutableArray <PHAsset *> *assets;
@property (nonatomic, copy) void(^initCompleteBlock)(BOOL success);
@property (nonatomic, assign) BOOL initComplete;
+ (instancetype)defaultManager;

@end
@implementation HSKHDMAssetManager
+ (instancetype)defaultManager
{
    static HSKHDMAssetManager *m = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [[self alloc] init];
        m.manager = [[PHCachingImageManager alloc] init];
        m.albums  = @[].mutableCopy;
        m.assets  = @[].mutableCopy;
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:m];
        [AVCaptureDevice checkCameraDevice:^(BOOL isAuth) {
            if (isAuth) {
               if(!m.initComplete)  [m prepare];
            }
        }];
    });
    return m;
}
- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}
- (void)prepare
{
    NSMutableArray <PHAssetCollection *> *albums = @[].mutableCopy;

    PHFetchResult <PHAssetCollection *> *usercs = (id)[PHAssetCollection fetchTopLevelUserCollectionsWithOptions:nil];
    
    PHFetchResult <PHAssetCollection *>*smartcs = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    [usercs enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumVideos &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumAllHidden &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumTimelapses &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumSlomoVideos &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumPanoramas &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumBursts &&
            obj.assetCollectionSubtype != 1000000201)
        {
             [albums addObject:obj];
        }
    }];
    
    [smartcs enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumVideos &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumAllHidden &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumTimelapses &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumSlomoVideos &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumPanoramas &&
            obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumBursts &&
            obj.assetCollectionSubtype != 1000000201)
        {
            if (obj.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary)
            {
                [albums insertObject:obj atIndex:0];
            }
            else
            {
                [albums addObject:obj];
            }
        }
    }];
    PHFetchOptions *o = [[PHFetchOptions alloc] init];
    o.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES]];
    [albums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PHFetchResult <PHAsset *> *ars = [PHAsset fetchAssetsInAssetCollection:obj options:o];
        NSArray <PHAsset *> *assets= [ars collect:^BOOL(PHAsset *element) {
                                        return element.mediaType == PHAssetMediaTypeImage;
                                     }];
        
        if(assets.count > 0) [self.albums addObject:[HSKHDMholderAlbum albumWithAssets:assets title:obj.localizedTitle]];
        [self.assets addObjectsFromArray:assets];
    }];
    self.initComplete = YES;
    if(self.initCompleteBlock)
    {
        self.initCompleteBlock(YES);
        self.initCompleteBlock = nil;
    }
}

#pragma mark - 协议
- (void)photoLibraryDidChange:(PHChange *)changeInstance
{

    [self.albums removeAllObjects];
    [self.assets removeAllObjects];
    [self prepare];
    [[NSNotificationCenter defaultCenter] postNotificationName:HSKHDMPhotoLibraryChangedNotification object:nil];
   
}

- (void)fetchImageForAsset:(PHAsset *)asset size:(CGSize)targetSize handle:(HSKHDMAssethandle)handle
{
    NSAssert([asset isKindOfClass:[PHAsset class]], @"asset must be kind of class PHAsset");
    
    PHImageRequestOptions *o = [[PHImageRequestOptions alloc] init];
    o.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    o.resizeMode = PHImageRequestOptionsResizeModeFast;
    o.networkAccessAllowed = YES;

    [_HDMAM_CM requestImageForAsset:asset
                         targetSize:CGSizeMake(targetSize.width * [UIScreen scale], targetSize.height * [UIScreen scale])
                        contentMode:PHImageContentModeAspectFill
                            options:o
                      resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                          handle(result);
                          [_HDMAM_CM startCachingImagesForAssets:@[asset] targetSize:targetSize contentMode:PHImageContentModeAspectFill options:o];
                      }];
}
@end

@implementation HSKHDMAsset
- (NSString *)identifier
{
    return _identifier ?: ({
        _identifier = self.asset.localIdentifier;
    });
}
+ (NSArray<HSKHDMAsset *> *)allAssetsForSize:(CGSize)targetSize
{
    NSMutableArray *_  = @[].mutableCopy;
    [_HDMAM.assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HSKHDMAsset *a = [HSKHDMAsset new];
        a.targetSize   = targetSize;
        a.asset        = obj;
        [_ addObject:a];
    }];
    return _;
}

- (instancetype)assetForSize:(CGSize)targetSize
{
    HSKHDMAsset *a = [HSKHDMAsset new];
    a.targetSize   = targetSize;
    a.asset        = self.asset;
    return a;
}
- (RACSignal *)imageSignal
{
    @weakify(self)
    return _imageSignal ?: ({
        @strongify(self)
        _imageSignal =
        [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [_HDMAM fetchImageForAsset:self.asset size:self.targetSize handle:^(UIImage *image) {
                [subscriber sendNext:image];
                [subscriber sendCompleted];
            }];
            return nil;
        }] replayLast] deliverOnMainThread];
        _imageSignal;
    });
}
@end

@implementation HSKHDMAlbum
+ (void)prepare:(void(^)(BOOL success))completeBlock
{
    if (_HDMAM.initComplete)
    {
        completeBlock(YES);
    }
    else
    {
        _HDMAM.initCompleteBlock = completeBlock;
    }
}
- (HSKHDMAsset *)cover
{
    return self.assets.lastObject;
}

+ (instancetype)albumForTitle:(NSString *)title size:(CGSize)targetSize
{
    __block HSKHDMAlbum *album = nil;
    [_HDMAM.albums enumerateObjectsUsingBlock:^(HSKHDMholderAlbum * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.title isEqualToString:title])
        {
            album = [HSKHDMAlbum albumWithHolderAlbum:obj size:targetSize];
        }
    }];
    return album;
}
+ (NSArray <HSKHDMAlbum *> *)albumsWithSize:(CGSize)targetSize
{
    NSMutableArray *_ = @[].mutableCopy;
    [_HDMAM.albums enumerateObjectsUsingBlock:^(HSKHDMholderAlbum * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HSKHDMAlbum *a = [HSKHDMAlbum albumWithHolderAlbum:obj size:targetSize];
        [_ addObject:a];
    }];
    return _;
}
- (instancetype)albumForSize:(CGSize)targetSize
{
    if (CGSizeEqualToSize(self.targetSize, targetSize)) return self;
    HSKHDMAlbum *a = [HSKHDMAlbum albumForTitle:self.title size:targetSize];
    return a;
}
+ (instancetype)albumWithHolderAlbum:(HSKHDMholderAlbum *)holder size:(CGSize)targetSize
{
    HSKHDMAlbum *album = [HSKHDMAlbum new];
    album.title = holder.title;
    album.targetSize = targetSize;
    album.assets = ({
        NSMutableArray *_ = @[].mutableCopy;
        [holder.assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            HSKHDMAsset *a = [HSKHDMAsset new];
            a.targetSize   = targetSize;
            a.asset        = asset;
            [_ addObject:a];
        }];
        _;
    });
    return album;
}
@end

