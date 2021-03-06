//
//  MapviewController.swift
//  ReverseGeolocation
//
//  Created by Aivars Meijers on 23/06/2018.
//  Copyright © 2018 Aivars Meijers. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapviewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var pinImage: UIImageView!
    @IBOutlet weak var addresView: RoundedView!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var getDirectionsBtn: RoundedButton!
    
    
    var locationManager = CLLocationManager()
    var geocoder = CLGeocoder()
    private var mapChangedFromUserInteraction = false
    var destination = MKMapItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateUi()
        setLocationData()
        verifyLocationStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    // verify is location services available
    func verifyLocationStatus() {
        let status = CLLocationManager.authorizationStatus()

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            //location services are available, show users location
            return
        case .denied, .restricted:
            //localisation status denied, you may like to inform user here
            print ("localisation status denied buy user")
        default:
            //location services are not available, request access
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    func setLocationData() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.startUpdatingLocation()
    }
    
    func updateUi() {
        
        addressLbl.text = "Move the map to update location adress"
        getDirectionsBtn.isHidden = true
        
    }
    
    private func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        // Update View
        if let error = error {
            print("Unable to Reverse Geocode Location (\(error))")
            addressLbl.text = "Unable to Find Address for Location"
            
        } else {
            if let placemarks = placemarks, let placemark = placemarks.first {
                addressLbl.text = placemark.compactAddress
            } else {
                addressLbl.text = "No Matching Addresses Found"
            }
        }
    }
    
    private func hideAddressView() {
        addresView.isHidden = true
        addressLbl.text = ""
        getDirectionsBtn.isHidden = true
    }
    
    func calculateDirections(destination : MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.requestsAlternateRoutes = false
        
        // to show alternative routes change value to true
        request.requestsAlternateRoutes = false
        // transport typee can be specified here
        request.transportType = .any
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            if error != nil {
                print("Error getting directions")
            } else {
                guard let directionResponse = response else { return }
                
                for route in directionResponse.routes {
                    // draw route on the map
                    self.mapView.addOverlay(route.polyline)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                    // print out navigation steps (can be used in UI as well)
                    for step in route.steps {
                        print(step.instructions)
                        
                    }
                }
            }
        }
    }
    
    @IBAction func getDirections(_ sender: Any) {
        //clear previous route if it is presented on map
        mapView.removeOverlays(mapView.overlays)
        //hide not needed elements
        hideAddressView()
        pinImage.isHidden = true
        getDirectionsBtn.isHidden = true
        //calculate and draw directions
        calculateDirections(destination: destination)
    }
    

}

extension MapviewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let LastCordinates = locations[0]
        let location = LastCordinates.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
    

}

extension MapviewController: MKMapViewDelegate {
    
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.ended ) {
                    return true
                }
            }
        }
        return false
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
        if (mapChangedFromUserInteraction) {
            // user changed map region, hide location untill will move again
            mapView.showsUserLocation = false
            //hide location label while map moving
            hideAddressView()
            
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (mapChangedFromUserInteraction) {
            // user changed map region, get coordinates for map center
            let centerCoordinate = mapView.centerCoordinate
            // transfer coordinates to location and reverse to placemark
            let location = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                // Process Response
                self.processResponse(withPlacemarks: placemarks, error: error)
            }
            //show pin and location label
            pinImage.isHidden = false
            addresView.isHidden = false
            getDirectionsBtn.isHidden = false
            
            //update destination coordinates from droped pin position
            let destinationPlacemark = MKPlacemark(coordinate: centerCoordinate)
            destination = MKMapItem(placemark: destinationPlacemark)
            
        }
    }
    
    //get directionns to the pin
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }
    
}

//Parse placemark to adress
extension CLPlacemark {
    
    var compactAddress: String? {
        if let name = name {
            var result = name
            
            if let city = locality {
                result += ",\n \(city)"
            }
            
            if let country = country {
                result += ",\n \(country)"
            }
            
            return result
        }
        
        return nil
    }
    
}
