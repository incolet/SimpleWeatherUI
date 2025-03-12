//
//  LocationManager.swift
//  SwiftUI-Weather
//
//  Created by Incolet on 11/03/2025.
//


import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var city: String = "Cupertino"
    @Published var state: String = "CA"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        fetchCityAndState(from: location)
    }

    private func fetchCityAndState(from location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("Error during reverse geocoding: \(error.localizedDescription)")
                return
            }
            if let placemark = placemarks?.first,
               let cityName = placemark.locality {
                DispatchQueue.main.async {
                    self?.city = cityName
                }
                let stateName = placemark.administrativeArea ?? ""
                DispatchQueue.main.async {
                    self?.state = stateName
                }
            }
        }
    }
}
