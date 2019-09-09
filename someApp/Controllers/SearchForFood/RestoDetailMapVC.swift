//
//  RestoDetailMapVC.swift
//  someApp
//
//  Created by Sergio Ortiz on 01.09.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class RestoDetailMapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!{
        didSet{
            mapView.delegate = self
        }
    }
    var mapItems = [MKMapItem]()
    var selectedPin:MKPlacemark? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        var zoomRect:MKMapRect = MKMapRect.null
        
        // Make sure `MKPinAnnotationView` and the reuse identifier is recognized in this map view.
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "pin")
        mapView.removeAnnotations(mapView.annotations)
        
        //Add the annotations
        for mapItem in mapItems{
            let placemark = mapItem.placemark
            selectedPin = placemark
            let annotation = MKPointAnnotation()
            annotation.coordinate = placemark.coordinate
            annotation.title = placemark.name
            
            mapView.addAnnotation(annotation)
            
            let tempPoint = MKMapPoint(placemark.coordinate)
            let pointRect = MKMapRect(x: tempPoint.x, y: tempPoint.y, width: 0.1, height: 0.1)
            zoomRect = zoomRect.union(pointRect)

        }
                
        mapView.setVisibleMapRect(zoomRect, animated: true)
        
        // Do any additional setup after loading the view.
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: mapItems[0].placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RestoDetailMapVC: MKMapViewDelegate{
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
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.canShowCallout = true
            annotationView.calloutOffset = CGPoint(x: -5, y: 5)
            //
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
            label.textAlignment = .center
            label.text = "Get directions"
            annotationView.detailCalloutAccessoryView = label
            //
            
            
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



