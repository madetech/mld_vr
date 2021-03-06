#import "PanoramaViewController.h"
#import "GVRPanoramaView.h"

int officeFloor = 1;
NSString * easterEgg = NULL;

@interface PanoramaViewController ()<GVRWidgetViewDelegate>
- (void)updateFloorView;
- (void)updateImageView:(NSString *)image;
- (Boolean)transitionFloor:(float) pitchAngle;
@end

@implementation PanoramaViewController {
  GVRPanoramaView *_panoView;
}

- (void)updateFloorView {
    [_panoView loadImage:[UIImage imageNamed:[self getFloorImage:officeFloor]]
                  ofType:kGVRPanoramaImageTypeMono];
}

- (void)updateImageView:(NSString *)image {
    [_panoView loadImage:[UIImage imageNamed:image]
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
    NSArray *floorImages = @[@"Images/k-1.jpg", @"Images/k+0.jpg", @"Images/k+1.jpg", @"Images/k+2.jpg", @"Images/k+3.jpg", @"Images/k+4.jpg"];
    return floorImages[floorNumber];
}

- (Boolean)transitionFloor:(float) pitchAngle {
    Boolean changed = false;
    if (_panoView.headRotation.pitch >= 40) {
        if (officeFloor < 5) {
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

- (Boolean)easterEggTransition:(GVRHeadRotation) headRotation {
    if (easterEgg != NULL) {
        easterEgg = NULL;
        [self updateFloorView];
        return false;
    }
    
    Boolean seb = ABS(headRotation.pitch) <= 5 && (ABS(headRotation.yaw + 122)) <= 5 && officeFloor == 2;
    Boolean luke = ABS(headRotation.pitch) <= 5 && (ABS(headRotation.yaw + 146)) <= 5 && officeFloor == 2;
    Boolean scott = ABS(headRotation.pitch - 6) <= 5 && (ABS(headRotation.yaw + 155)) <= 5 && officeFloor == 3;
    Boolean k2Door = ABS(headRotation.pitch - 7) <= 7 && (ABS(headRotation.yaw - 164)) <= 5 && officeFloor == 3;
    Boolean chris = ABS(headRotation.pitch + 8) <= 5 && (ABS(headRotation.yaw - 167)) <= 5 && officeFloor == 4;
    
    if (seb) {
      easterEgg = @"Images/seb.jpg";
    } else if (luke) {
      easterEgg = @"Images/luke.jpg";
    } else if (chris) {
      easterEgg = @"Images/chris.jpg";
    } else if (scott) {
      easterEgg = @"Images/scott.jpg";
    } else if (k2Door) {
      easterEgg = @"Images/k+2door.jpg";
    }

    return easterEgg != NULL;
}

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
    if (easterEgg == NULL && [self transitionFloor:_panoView.headRotation.pitch]) {
      [self updateFloorView];
    } else if ([self easterEggTransition:_panoView.headRotation]) {
      [self updateImageView:easterEgg];
    }
}
@end
