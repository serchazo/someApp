//
//  MyRestoMap.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 11.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit

class MyRestoMap: UIViewController {
    
    // Class variables
    var selectedPin:MKPlacemark? = nil
    
    // To be taken from segue-r
    var mapItems = [MKMapItem]()
    var infoLabel = UILabel()
    

    @IBOutlet weak var coolMap: MKMapView!{
        didSet{
            coolMap.delegate = self
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the info label
        infoLabel.frame = CGRect(x: 125, y: 130, width: 240, height: 30)
        infoLabel.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).withAlphaComponent(0.8)
        infoLabel.textAlignment = .center
        infoLabel.textColor = SomeApp.themeColor
        infoLabel.text = "Click on the pin for directions"
        
        self.view.addSubview(infoLabel)
        
        // Make sure `MKPinAnnotationView` and the reuse identifier is recognized in this map view.
        coolMap.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "pin")
        coolMap.removeAnnotations(coolMap.annotations)
        
        //Add the annotations
        var zoomRect:MKMapRect = MKMapRect.null
        for mapItem in mapItems{
            let placemark = mapItem.placemark
            selectedPin = placemark
            let annotation = MKPointAnnotation()
            annotation.coordinate = placemark.coordinate
            annotation.title = placemark.name!
            
            coolMap.addAnnotation(annotation)
            
            let tempPoint = MKMapPoint(placemark.coordinate)
            let pointRect = MKMapRect(x: tempPoint.x, y: tempPoint.y, width: 0.1, height: 0.1)
            zoomRect = zoomRect.union(pointRect)
        }
        
        coolMap.setVisibleMapRect(zoomRect, animated: true)
        
        // Do any additional setup after loading the view.
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: mapItems[0].placemark.coordinate, span: span)
        coolMap.setRegion(region, animated: true)
        
        
    }

}

extension MyRestoMap: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        // 3
        let identifier = "marker"
        var annotationView: MKMarkerAnnotationView
        // 4
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            annotationView = dequeuedView
        } else {
            // 5
            print("hao")
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.canShowCallout = true
            annotationView.calloutOffset = CGPoint(x: -5, y: 5)
            //
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            label.textAlignment = .center
            label.text = "Get directions"
            annotationView.detailCalloutAccessoryView = label
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
        }
        return annotationView
    }
    
    func getDirections(){
        if let selectedPin = selectedPin {
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //let location = view.mk
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItems[0].openInMaps(launchOptions: launchOptions)
    }
}
