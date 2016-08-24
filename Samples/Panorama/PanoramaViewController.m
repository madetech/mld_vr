#import "PanoramaViewController.h"
#import "GVRPanoramaView.h"

int officeFloor = 0;

@interface PanoramaViewController ()<GVRWidgetViewDelegate>
- (void)updateFloorView;
- (Boolean)transitionFloor:(float) pitchAngle;
@end

@implementation PanoramaViewController {
  GVRPanoramaView *_panoView;
}

- (void)updateFloorView {
    [_panoView loadImage:[UIImage imageNamed:[self getFloorImage:officeFloor]]
                  ofType:kGVRPanoramaImageTypeMono];
}

- (void)loadView {
    _panoView = [[GVRPanoramaView alloc] init];
    _panoView.delegate = self;
    _panoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
    [self updateFloorView];
    self.view = _panoView;
}

- (NSString *)getFloorImage:(int)floorNumber {
    NSArray *floorImages = @[@"k+0.jpg", @"k+1.jpg", @"k+2.jpg", @"k+3.jpg"];
    return floorImages[floorNumber];
}

- (Boolean)transitionFloor:(float) pitchAngle {
    Boolean changed = false;
    if (_panoView.headRotation.pitch >= 40) {
        if (officeFloor < 3) {
            officeFloor++;
            changed = true;
        }
    } else if (_panoView.headRotation.pitch <= -40) {
        if (officeFloor > 0) {
            officeFloor--;
            changed = true;
        }
    }
    return changed;
}

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
    if ([self transitionFloor:_panoView.headRotation.pitch]) {
      [self updateFloorView];
    }
    
    NSLog(@(_panoView.headRotation.pitch).stringValue);
    NSLog(@(_panoView.headRotation.yaw).stringValue);
}
@end
