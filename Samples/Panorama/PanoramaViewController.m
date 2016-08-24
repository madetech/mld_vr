#import "PanoramaViewController.h"
#import "GVRPanoramaView.h"

int officeFloor = 0;

@interface PanoramaViewController ()<GVRWidgetViewDelegate>
- (void)updatePanoView;
@end

@implementation PanoramaViewController {
  GVRPanoramaView *_panoView;
}

- (void)updatePanoView {
    [_panoView loadImage:[UIImage imageNamed:[self getFloorImage:officeFloor]]
                  ofType:kGVRPanoramaImageTypeMono];
}

- (NSString *)getFloorImage:(int)floorNumber {
    switch (floorNumber) {
        case 3:
            return @"andes.jpg";
        case 2:
            return @"k+1.jpeg";
        case 1:
            return @"andes.jpg";
        case 0:
        default:
            return @"k+1.jpeg";
    }
}

- (void)loadView {
    _panoView = [[GVRPanoramaView alloc] init];
    _panoView.delegate = self;
    _panoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
    [self updatePanoView];
    self.view = _panoView;
}

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
    if (_panoView.headRotation.pitch >= 40) {
      if (officeFloor < 3) {
        officeFloor++;
      }
    } else if (_panoView.headRotation.pitch <= -40) {
      if (officeFloor > 0) {
        officeFloor--;
      }
    }
    
    NSLog(@(_panoView.headRotation.pitch).stringValue);
    NSLog(@(_panoView.headRotation.yaw).stringValue);
    [self updatePanoView];
}
@end
