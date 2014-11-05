//
//  KLMapViewController.m
//  KnowingLife
//
//  Created by tanyang on 14/11/5.
//  Copyright (c) 2014年 tany. All rights reserved.
//

#import "KLMapViewController.h"
#import <MapKit/MapKit.h>
#import "KLTGHttpTool.h"
#import "KLDeal.h"
#import "KLBusiness.h"
#import "KLDealAnnotation.h"
#import "KLDetailDealController.h"

@interface KLMapViewController ()<MKMapViewDelegate>
@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *showingDeals;
@property (nonatomic, strong) KLDeal *currentDeal;
@end

@implementation KLMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"地图";
    
    // 添加mapView
    MKMapView *mapView = [[MKMapView alloc]init];
    mapView.frame = self.view.frame;
    
    // 显示用户位置点
    mapView.showsUserLocation = YES;
    mapView.delegate = self;
    
    [self.view addSubview:mapView];
    //self.mapView = mapView;
    
    _showingDeals = [NSMutableArray array];
    
    
}

#pragma mark 根据经度纬度定位
- (void)locateToCoordinate2D:(CLLocationCoordinate2D) locateCoordinate
{
    // 设置地图经度纬度
    CLLocationCoordinate2D center = locateCoordinate;
    
    // 设置地图显示范围
    MKCoordinateSpan span;
    span.latitudeDelta = 0.02;
    span.longitudeDelta = 0.03;
    
    // 创建MKCoordinateRegion 地区
    MKCoordinateRegion region = {center,span};
    
    // 设置当前地图的显示中心和范围
    [self.mapView setRegion:region animated:YES];
    
}

#pragma mark MKMapViewDelegate
#pragma mark 当定位到用户的位置就会调用
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    // 调用一次
    if (self.mapView == nil) {
        self.mapView = mapView;
        
        [self locateToCoordinate2D:userLocation.location.coordinate];
    }
}

#pragma mark 拖动地图（地图展示的区域改变了）就会调用
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    // 地图当前展示区域的中心位置
    CLLocationCoordinate2D pos = mapView.region.center;
    
    __typeof (self) __weak weakSelf = self;
    [[KLTGHttpTool sharedKLTGHttpTool] dealsWithLatitude:pos.latitude longitude:pos.longitude success:^(NSArray *deals, int totalCount) {
        for (KLDeal *deal in deals) {
            // 已经显示过
            if ([weakSelf.showingDeals containsObject:deal]) continue;
            
            // 从未显示过
            [weakSelf.showingDeals addObject:deal];
            
            for (KLBusiness *business in deal.businesses) {
                KLDealAnnotation *anno = [[KLDealAnnotation alloc] init];
                anno.business = business;
                anno.deal = deal;
                anno.coordinate = CLLocationCoordinate2DMake(business.latitude, business.longitude);
                anno.title = business.name;
                [mapView addAnnotation:anno];
            }
        }
    } error:nil];
}

#pragma mark 循环取出mapView
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(KLDealAnnotation *)annotation
{
    if (![annotation isKindOfClass:[KLDealAnnotation class]]) return nil;
    
    // 从缓存池中取出大头针view
    static NSString *ID = @"MKAnnotationView";
    MKAnnotationView *annoView = [mapView dequeueReusableAnnotationViewWithIdentifier:ID];
    
    // 缓存池没有可循环利用的大头针view
    if (annoView == nil) {
        // 这里应该用MKPinAnnotationView这个子类
        annoView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ID];
    }
    
    // 设置view的大头针信息
    annoView.annotation = annotation;
    
    // 设置图片
    annoView.image = [UIImage imageNamed:@"ic_category_default"];
    
    // 设置该锚点控件是否可显示气泡信息
    annoView.canShowCallout = YES;
    
    // 定义一个按钮，用于为锚点控件设置附加控件
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    // 为按钮绑定事件处理方法
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // 可通过锚点控件的rightCalloutAccessoryView、leftCalloutAccessoryView设置附加控件
    annoView.rightCalloutAccessoryView = button;
    
    return annoView;
}

#pragma mark 点击了大头针
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    KLLog(@"您点击了大头针！");
    // 展示详情
    KLDealAnnotation *anno = view.annotation;
    
    self.currentDeal = anno.deal;
    
    // 让选中的大头针居中
    [mapView setCenterCoordinate:anno.coordinate animated:YES];
    
    // 让view周边产生一些阴影效果
    //view.layer.shadowColor = [UIColor redColor].CGColor;
    //view.layer.shadowOpacity = 1;
    //view.layer.shadowRadius = 10;
}

// 点击了锚点信息
- (void) buttonTapped:(UIButton *)sender
{
    KLLog(@"您点击了锚点信息！");
    
    if (self.currentDeal) {
        // 跳转到团购
        KLDetailDealController *detailDealCtrl = [[KLDetailDealController alloc]init];
        detailDealCtrl.deal = self.currentDeal;
        
        [self.navigationController pushViewController:detailDealCtrl animated:YES];
    }
}

- (void)dealloc
{
    [self.showingDeals removeAllObjects];
    KLLog(@"KLMapViewController dealloc");
}



@end