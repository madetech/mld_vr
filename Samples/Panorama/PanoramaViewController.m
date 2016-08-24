#import "PanoramaViewController.h"

#import "GVRPanoramaView.h"

@interface PanoramaViewController ()<GVRWidgetViewDelegate>

@end

@implementation PanoramaViewController {
  GVRPanoramaView *_panoView;
}

- (void)loadView {

  _panoView = [[GVRPanoramaView alloc] init];
  _panoView.delegate = self;
  _panoView.displayMode = kGVRWidgetDisplayModeFullscreenVR;
  [_panoView loadImage:[UIImage imageNamed:@"k+1.jpeg"]
                ofType:kGVRPanoramaImageTypeMono];
  self.view = _panoView;
}

@end
