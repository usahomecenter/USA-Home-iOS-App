import Foundation
import CoreLocation
import UIKit
import MapKit

class LocationService: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationService()
    
    private var locationManager: CLLocationManager
    private var currentLocation: CLLocation?
    private var locationUpdateCallbacks: [(CLLocation) -> Void] = []
    private var authorizationCallbacks: [(CLAuthorizationStatus) -> Void] = []
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission(completion: @escaping (CLAuthorizationStatus) -> Void) {
        authorizationCallbacks.append(completion)
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            completion(.denied)
        case .authorizedWhenInUse, .authorizedAlways:
            completion(.authorizedWhenInUse)
        @unknown default:
            completion(.denied)
        }
    }
    
    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        // Return cached location if available and recent (within 5 minutes)
        if let location = currentLocation,
           Date().timeIntervalSince(location.timestamp) < 300 {
            completion(location)
            return
        }
        
        // Check authorization
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            completion(nil)
            return
        }
        
        // Add callback for when location is received
        locationUpdateCallbacks.append(completion)
        
        // Start location updates
        locationManager.requestLocation()
    }
    
    func startContinuousLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func isLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled() &&
               (locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways)
    }
    
    // MARK: - Location Processing
    
    func findNearbyProfessionals(serviceType: String? = nil, radius: Double = 50000, completion: @escaping ([String: Any]) -> Void) {
        getCurrentLocation { [weak self] location in
            guard let location = location else {
                completion(["error": "Location not available"])
                return
            }
            
            self?.searchProfessionalsNearby(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                serviceType: serviceType,
                radius: radius,
                completion: completion
            )
        }
    }
    
    private func searchProfessionalsNearby(latitude: Double, longitude: Double, serviceType: String?, radius: Double, completion: @escaping ([String: Any]) -> Void) {
        var urlComponents = URLComponents(string: "https://usa-homedollar-thenilecreditle.replit.app/api/professionals/nearby")!
        
        var queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "radius", value: String(radius))
        ]
        
        if let serviceType = serviceType {
            queryItems.append(URLQueryItem(name: "service", value: serviceType))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            completion(["error": "Invalid URL"])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(["error": error.localizedDescription])
                    return
                }
                
                guard let data = data else {
                    completion(["error": "No data received"])
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        completion(json)
                    } else {
                        completion(["error": "Invalid response format"])
                    }
                } catch {
                    completion(["error": "JSON parsing error"])
                }
            }
        }.resume()
    }
    
    func getAddressFromCoordinates(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    completion(nil)
                    return
                }
                
                let address = self.formatAddress(from: placemark)
                completion(address)
            }
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        
        if let streetName = placemark.thoroughfare {
            addressComponents.append(streetName)
        }
        
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        
        if let zipCode = placemark.postalCode {
            addressComponents.append(zipCode)
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    // MARK: - Distance Calculations
    
    func calculateDistance(from: CLLocation, to: CLLocation) -> CLLocationDistance {
        return from.distance(from: to)
    }
    
    func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        
        // Call all pending callbacks
        locationUpdateCallbacks.forEach { callback in
            callback(location)
        }
        locationUpdateCallbacks.removeAll()
        
        // Send location to web app if WebView is available
        sendLocationToWebApp(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        
        // Call callbacks with nil
        locationUpdateCallbacks.forEach { callback in
            callback(nil)
        }
        locationUpdateCallbacks.removeAll()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization changed to: \(status.rawValue)")
        
        // Call all pending authorization callbacks
        authorizationCallbacks.forEach { callback in
            callback(status)
        }
        authorizationCallbacks.removeAll()
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Start location updates if we have permission
            if !locationUpdateCallbacks.isEmpty {
                locationManager.requestLocation()
            }
        case .denied, .restricted:
            // Clear any pending callbacks
            locationUpdateCallbacks.forEach { callback in
                callback(nil)
            }
            locationUpdateCallbacks.removeAll()
        case .notDetermined:
            // Wait for user decision
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Web Integration
    
    private func sendLocationToWebApp(location: CLLocation) {
        // Find the current WebView and send location data
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let navigationController = window.rootViewController as? UINavigationController,
           let viewController = navigationController.topViewController as? ViewController {
            
            let script = """
                if (window.receiveLocation) {
                    window.receiveLocation({
                        latitude: \(location.coordinate.latitude),
                        longitude: \(location.coordinate.longitude),
                        accuracy: \(location.horizontalAccuracy),
                        timestamp: \(location.timestamp.timeIntervalSince1970)
                    });
                }
                
                // Also update any location-related UI elements
                if (window.updateLocationUI) {
                    window.updateLocationUI(\(location.coordinate.latitude), \(location.coordinate.longitude));
                }
            """
            
            viewController.webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error sending location to WebView: \(error)")
                }
            }
        }
    }
    
    // MARK: - Geofencing (Advanced Feature)
    
    func setupGeofence(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    func removeGeofence(identifier: String) {
        for region in locationManager.monitoredRegions {
            if region.identifier == identifier {
                locationManager.stopMonitoring(for: region)
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        
        // Send notification or update to web app
        NotificationService.shared.scheduleLocalNotification(
            title: "Service Area Nearby",
            body: "You've entered an area with available professional services",
            identifier: "geofence_enter_\(region.identifier)"
        )
        
        // Notify web app
        let script = """
            if (window.onGeofenceEnter) {
                window.onGeofenceEnter('\(region.identifier)');
            }
        """
        executeWebScript(script)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        
        let script = """
            if (window.onGeofenceExit) {
                window.onGeofenceExit('\(region.identifier)');
            }
        """
        executeWebScript(script)
    }
    
    private func executeWebScript(_ script: String) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let navigationController = window.rootViewController as? UINavigationController,
           let viewController = navigationController.topViewController as? ViewController {
            
            viewController.webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
}

// MARK: - Extensions

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized Always"
        case .authorizedWhenInUse:
            return "Authorized When In Use"
        @unknown default:
            return "Unknown"
        }
    }
}