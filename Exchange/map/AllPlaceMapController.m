//
//  ViewController.m
//  MapGoogles
//
//  Created by admin on 30.11.16.
//  Copyright © 2016 admin. All rights reserved.
//




#import "AllPlaceMapController.h"
#import <MapKit/MapKit.h>
#import "PrivatBankAPI.h"
#import "GoogleAPIManager.h"
#import "BankPlace.h"
#import "InfoWindowView.h"
#import "constants.h"



@import GoogleMaps;
@import GoogleMapsBase;
@import GoogleMapsCore;


@interface AllPlaceMapController () <CLLocationManagerDelegate, GMSMapViewDelegate, GetAllBankPlaceDelegate>
    
@property (nonatomic,strong) CLLocationManager* locManager;
@property (strong, nonatomic) CLLocation* previusLocation;

@property (strong, nonatomic) NSMutableSet* setOfOffice;
@property (strong, nonatomic) NSMutableSet* setOfATM;
@property (strong, nonatomic) NSMutableSet* setOfTSO;
@property (strong, nonatomic) InfoWindowView* infoWindowView;

@property (strong, nonatomic) GMSMarker* placeMarker;
@property (strong, nonatomic) GMSPolyline* placePolyline;

@property (nonatomic, strong) PrivatBankAPI* apiManager;
@property (nonatomic, strong) GoogleAPIManager* googleAPIManager;

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *typePlaceSegmentController;

@property (strong, nonatomic) UIView* backgroundView;

@end

@implementation AllPlaceMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.backgroundColor = [UIColor blackColor];
    
    self.backgroundView = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.backgroundView.backgroundColor = BACKGROUND_MAP_COLOR;
    [self.mapView addSubview:self.backgroundView];
    
    [self initLocationManager];
    [self customizeMap];
    
    self.apiManager = [[PrivatBankAPI alloc] init];
    self.apiManager.delegate = self;
    
    self.googleAPIManager = [GoogleAPIManager sharedManager];
    self.mapView.delegate = self;
    
    self.setOfOffice = [NSMutableSet set];
    self.setOfATM = [NSMutableSet set];
    self.setOfTSO = [NSMutableSet set];
    
    //[self initInfoWindowView];
}


- (void)customizeMap {
    
    NSURL *styleUrl = [[NSBundle mainBundle] URLForResource:@"style" withExtension:@"json"];
    
    NSError *error;
    // Set the map style by passing the URL for style.json.
    GMSMapStyle *style = [GMSMapStyle styleWithContentsOfFileURL:styleUrl error:&error];
    
    self.mapView.mapStyle = style;
}

- (void)dealloc {
    [self.mapView clear];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - init
-(void) initLocationManager {
    self.locManager = [[CLLocationManager alloc]init];
    self.locManager.delegate = self;
    self.locManager.distanceFilter = 1000;
    self.locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self.locManager requestWhenInUseAuthorization];
}

- (void) initInfoWindowView
{
    self.infoWindowView = [[[NSBundle mainBundle] loadNibNamed:@"InfoWindowView" owner:self options:nil] firstObject];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        self.infoWindowView.bounds = CGRectMake(0, 0, 250, 70);
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.infoWindowView.bounds = CGRectMake(0, 0, 450, 80);
    }
}

#pragma mark - GMSMapViewDelegate

- (void)mapViewDidFinishTileRendering:(GMSMapView *)mapView {
    [self.backgroundView setHidden:YES];
}

- (void)mapViewSnapshotReady:(GMSMapView *)mapView {
    
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
    self.infoWindowView.titleLabel.text = marker.title;
    self.infoWindowView.detailedLabel.text = marker.snippet;
    
    return self.infoWindowView;
}
#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if  ((status == kCLAuthorizationStatusAuthorizedWhenInUse) ||
        (status == kCLAuthorizationStatusAuthorizedAlways))
    {
       [self.locManager startUpdatingLocation];
        self.mapView.myLocationEnabled = YES;
        self.mapView.settings.myLocationButton = YES;
    }
}


- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    //if current loc change
    void(^ChangeSelfLocation)(CLLocation*) = ^(CLLocation* location) {
        self.previusLocation = location;
        self.mapView.myLocationEnabled =  YES;
        self.mapView.camera = [[GMSCameraPosition alloc]initWithTarget:location.coordinate zoom:13 bearing:0 viewingAngle:0];
        
        [self.googleAPIManager getReverseGeocoding:location.coordinate completionHandler:^(NSString* cityName){
            
            dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView clear];
            });
            
            [self.apiManager getAllBankPlaceInCity:cityName myLoc:location inRadius:1000];
        } errorBlock:^(NSError* error) {
            
        }];
    };
    
    CLLocation *location = [locations lastObject];
    //if location change more than 1000m
    if (self.previusLocation) {
        if([location distanceFromLocation:self.previusLocation] > 1000) {
            if (location) {
                ChangeSelfLocation(location);
            }
        }
        else {
            return;
        }
    }
    else if (location) {
        ChangeSelfLocation(location);
    }
    
}

- (void)takeBankPlace:(BankPlace*)place {
    
    switch (place.typeOfEnum) {
         case ATM:
             [self.setOfATM addObject:place];
             break;
         case TSO:
            place.marker.map = self.mapView;
             [self.setOfTSO addObject:place];
             break;
         case OFFICE:
            place.marker.map = self.mapView;
             [self.setOfOffice addObject:place];
             break;
         default:
             break;
     }
    
    if (self.typePlaceSegmentController.selectedSegmentIndex == place.typeOfEnum) {
        place.marker.map = self.mapView;
    }
}

- (void) mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(nonnull GMSMarker *)marker {
    [self.googleAPIManager getPolylineWithOrigin:self.previusLocation.coordinate
                                     destination:self.mapView.selectedMarker.position
                               completionHandler:^(GMSPath* path) {
         if (!path) {
             return;
         }
         GMSPolyline* polyline = [GMSPolyline polylineWithPath:path];
         
         GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
         GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds];
         [self.mapView moveCamera:update];
         
         self.placePolyline.map = nil;
         self.placePolyline = nil;
         
         self.placePolyline = polyline;
         self.placePolyline.strokeWidth = 2.f;
         self.placePolyline.map = self.mapView;
         
     } errorBlock:^(NSError* error) {
         
     }];
}

#pragma mark - HELP methods

- (void) removeAllPlaces {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.setOfATM) {
            for (BankPlace* place in self.setOfATM) {
                place.marker.map = nil;
            }
            self.setOfATM = [NSMutableSet set];
        }
        
        if (self.setOfOffice) {
            for (BankPlace* place in self.setOfOffice) {
                place.marker.map = nil;
            }
            self.setOfOffice = [NSMutableSet set];
        }
        
        if (self.setOfTSO) {
            for (BankPlace* place in self.setOfTSO) {
                place.marker.map = nil;
            }
            self.setOfTSO = [NSMutableSet set];
        }
    });
}

- (void)watchAllMarkersInSet:(NSSet*)markers {
    for (BankPlace* place in markers) {
        place.marker.map = self.mapView;
    }
}

#pragma mark - Actions

- (IBAction)BackButton:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changeTypePlaces:(UISegmentedControl *)sender {
    [self.mapView clear];
    switch (sender.selectedSegmentIndex) {
        case ATM:
            [self watchAllMarkersInSet:self.setOfATM];
            break;
        case TSO:
            [self watchAllMarkersInSet:self.setOfTSO];
            break;
        case OFFICE:
            [self watchAllMarkersInSet:self.setOfOffice];
            break;
        default:
            break;
    }
}
@end