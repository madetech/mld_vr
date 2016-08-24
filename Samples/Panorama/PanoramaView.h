#import "GVRCardboardView.h"

/** Panorama renderer. */
@protocol PanoramaViewDelegate <NSObject>
@optional

@end

@interface PanoramaView : NSObject<GVRCardboardViewDelegate>

@property(nonatomic, weak) id<PanoramaViewDelegate> delegate;

@end
