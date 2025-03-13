//
//  WeatherManager.swift
//  SwiftUI-Weather
//
//  Created by Incolet on 11/03/2025.
//

import Foundation
import Combine

class WeatherManager: ObservableObject {
    
    @Published var currentTemperature: Int = 0
    @Published var currentIcon: String = "cloud.sun.fill"
    @Published var forecast: [DailyForecast] = []
    
    private let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "WEATHER_API_KEY") as? String else {
            fatalError("API Key not found in Info.plist")
        }
        return key
    }()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchWeather(for city: String, state: String) {
        fetchCurrentWeather(for: city, state: state)
        fetchForecast(for: city, state: state)
    }
    
    private func fetchCurrentWeather(for city: String, state: String) {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(city),\(state),US&appid=\(apiKey)&units=imperial") else {
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: CurrentWeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching current weather: \(error)")
                }
            } receiveValue: { [weak self] weatherResponse in
                self?.currentTemperature = Int(weatherResponse.main.temp)
                
                self?.currentIcon = Self.mapIcon(from: weatherResponse.weather.first?.icon ?? "")
            }
            .store(in: &cancellables)
    }
    
    private func fetchForecast(for city: String, state: String) {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/forecast?q=\(city),\(state),US&appid=\(apiKey)&units=imperial") else {
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: ForecastResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching forecast: \(error)")
                    self.forecast = Self.defaultForecast()
                }
            } receiveValue: { [weak self] forecastResponse in
                let daily = Self.filterDailyForecast(from: forecastResponse.list)
                self?.forecast = daily.isEmpty ? Self.defaultForecast() : daily
            }
            .store(in: &cancellables)
    }
    
    
    static func mapIcon(from openWeatherIcon: String) -> String {
        let mapping: [String: String] = [
            "01d": "sun.max.fill",
            "01n": "moon.fill",
            "02d": "cloud.sun.fill",
            "02n": "cloud.moon.fill",
            "03d": "cloud.fill",
            "03n": "cloud.fill",
            "04d": "smoke.fill",
            "04n": "smoke.fill",
            "09d": "cloud.drizzle.fill",
            "09n": "cloud.drizzle.fill",
            "10d": "cloud.sun.rain.fill",
            "10n": "cloud.moon.rain.fill",
            "11d": "cloud.bolt.fill",
            "11n": "cloud.bolt.fill",
            "13d": "snow",
            "13n": "snow",
            "50d": "cloud.fog.fill",
            "50n": "cloud.fog.fill"
        ]
        return mapping[openWeatherIcon] ?? "cloud.sun.fill"
    }
    
    
    static func filterDailyForecast(from list: [ForecastItem]) -> [DailyForecast] {
        // Group forecasts by day
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: list) { item in
            calendar.startOfDay(for: Date(timeIntervalSince1970: item.dt))
        }
        // For each day, pick the forecast closest to noon (12:00)
        var dailyForecasts: [DailyForecast] = []
        for (day, items) in grouped {
            let targetTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
            if let closest = items.min(by: { abs(Date(timeIntervalSince1970: $0.dt).timeIntervalSince(targetTime)) < abs(Date(timeIntervalSince1970: $1.dt).timeIntervalSince(targetTime)) }) {
                let forecast = DailyForecast(date: day,
                                             dayOfWeek: DateFormatter().shortWeekdaySymbols[calendar.component(.weekday, from: Date(timeIntervalSince1970: closest.dt)) - 1].lowercased(),
                                             temperature: Int(closest.main.temp),
                                             icon: mapIcon(from: closest.weather.first?.icon ?? ""))
                dailyForecasts.append(forecast)
            }
        }
        // Sort by day
        return dailyForecasts.sorted { $0.date < $1.date }
    }
    
    // Generate default forecast data for the next 5 days
    static func defaultForecast() -> [DailyForecast] {
        let calendar = Calendar.current
        let today = Date()
        
        return (1...5).map { offset in
            let futureDate = calendar.date(byAdding: .day, value: offset, to: today)!
            let dayOfWeek = DateFormatter().shortWeekdaySymbols[calendar.component(.weekday, from: futureDate) - 1].uppercased()
            return DailyForecast(date: futureDate, dayOfWeek: dayOfWeek, temperature: 70, icon: "cloud.sun.fill")
        }
    }
}


// For current weather
struct CurrentWeatherResponse: Decodable {
    let main: Main
    let weather: [Weather]
}

struct Main: Decodable {
    let temp: Double
}

struct Weather: Decodable {
    let icon: String
}

// For forecast
struct ForecastResponse: Decodable {
    let list: [ForecastItem]
}

struct ForecastItem: Decodable {
    let dt: TimeInterval
    let main: Main
    let weather: [Weather]
}

struct DailyForecast: Identifiable {
    var id = UUID()
    let date: Date
    let dayOfWeek: String
    let temperature: Int
    let icon: String
}
