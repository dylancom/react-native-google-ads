//
/**
 * Copyright (c) 2016-present Invertase Limited & Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this library except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#import "RNGoogleAdsBannerViewManager.h"
#import <GoogleMobileAds/GADBannerView.h>
#import <GoogleMobileAds/GADBannerViewDelegate.h>
#import "RNGoogleAdsCommon.h"

@interface BannerComponent : UIView <GADBannerViewDelegate>

@property GADBannerView *banner;
@property(nonatomic, assign) BOOL requested;

@property(nonatomic, copy) NSString *size;
@property(nonatomic, copy) NSString *unitId;
@property(nonatomic, copy) NSDictionary *request;

@property(nonatomic, copy) RCTBubblingEventBlock onNativeEvent;

- (void)requestAd;

@end

@implementation BannerComponent

- (void)initBanner:(GADAdSize)adSize {
  if (_requested) {
    [_banner removeFromSuperview];
  }
  _banner = [[GADBannerView alloc] initWithAdSize:adSize];
  _banner.rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
  _banner.delegate = self;
}

- (void)setUnitId:(NSString *)unitId {
  _unitId = unitId;
  [self requestAd];
}

- (void)setSize:(NSString *)size {
  _size = size;
  [self requestAd];
}

- (void)setRequest:(NSDictionary *)request {
  _request = request;
  [self requestAd];
}

- (void)requestAd {
#ifndef __LP64__
  return;  // prevent crash on 32bit
#endif

  if (_unitId == nil || _size == nil || _request == nil) {
    [self setRequested:NO];
    return;
  }

  [self initBanner:[RNGoogleAdsCommon stringToAdSize:_size]];
  [self addSubview:_banner];
  _banner.adUnitID = _unitId;
  [self setRequested:YES];
  [_banner loadRequest:[RNGoogleAdsCommon buildAdRequest:_request]];
  [self sendEvent:@"onSizeChange"
          payload:@{
            @"width" : @(_banner.bounds.size.width),
            @"height" : @(_banner.bounds.size.height),
          }];
}

- (void)sendEvent:(NSString *)type payload:(NSDictionary *_Nullable)payload {
  if (!self.onNativeEvent) {
    return;
  }

  NSMutableDictionary *event = [@{
    @"type" : type,
  } mutableCopy];

  if (payload != nil) {
    [event addEntriesFromDictionary:payload];
  }

  self.onNativeEvent(event);
}

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView {
  [self sendEvent:@"onAdLoaded"
          payload:@{
            @"width" : @(bannerView.bounds.size.width),
            @"height" : @(bannerView.bounds.size.height),
          }];
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
  NSDictionary *errorAndMessage = [RNGoogleAdsCommon getCodeAndMessageFromAdError:error];
  [self sendEvent:@"onAdFailedToLoad" payload:errorAndMessage];
}

- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView {
  [self sendEvent:@"onAdOpened" payload:nil];
}

- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView {
  // not in use
}

- (void)bannerViewDidDismissScreen:(GADBannerView *)bannerView {
  [self sendEvent:@"onAdClosed" payload:nil];
}

@end

@implementation RNGoogleAdsBannerViewManager

RCT_EXPORT_MODULE(RNGoogleAdsBannerView);

RCT_EXPORT_VIEW_PROPERTY(size, NSString);

RCT_EXPORT_VIEW_PROPERTY(unitId, NSString);

RCT_EXPORT_VIEW_PROPERTY(request, NSDictionary);

RCT_EXPORT_VIEW_PROPERTY(onNativeEvent, RCTBubblingEventBlock);

@synthesize bridge = _bridge;

- (UIView *)view {
  BannerComponent *banner = [BannerComponent new];
  return banner;
}

- (dispatch_queue_t)methodQueue {
  return dispatch_get_main_queue();
}

@end
