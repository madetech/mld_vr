#import "PanoramaViewController.h"
#import "GVRPanoramaView.h"

@interface PanoramaViewController ()<GVRWidgetViewDelegate>
- (void)setPanoView:(NSString *)imageName;
@end

@implementation PanoramaViewController {
  GVRPanoramaView *_panoView;
}

- (void)setPanoView:(NSString *)imageName {
    _panoView = [[GVRPanoramaView alloc] init];
    _panoView.delegate = self;
    _panoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
    [_panoView loadImage:[UIImage imageNamed:imageName]
                  ofType:kGVRPanoramaImageTypeMono];
    self.view = _panoView;
}

- (void)loadView {
    [self setPanoView:@"k+1.jpeg"];
}

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
    if (_panoView.headRotation.pitch >= 40) {
        printf("GO UP");
        [_panoView loadImage:[UIImage imageNamed:@"andes.jpg"]
                      ofType:kGVRPanoramaImageTypeMono];
    } else if (_panoView.headRotation.pitch <= -40) {
        printf("GO DOWN");
        [_panoView loadImage:[UIImage imageNamed:@"andes.jpg"]
                      ofType:kGVRPanoramaImageTypeMono];
    }
}
@end
