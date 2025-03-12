//
//  ContentView.swift
//  SwiftUI-Weather
//
//  Created by Incolet on 11/03/2025.
//

import SwiftUI

struct ContentView: View {
    
    @State private var isNight = false
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherManager = WeatherManager()
    
    var body: some View {
        ZStack{
            BackgroundView(isNight: $isNight)
            
            VStack{
                CityTextView(cityName: "\(locationManager.city), \(locationManager.state)")
                
                MainWeatherStatusView(imageName: weatherManager.currentIcon,
                                      temperature: weatherManager.currentTemperature)
                HStack(spacing: 20) {
                    ForEach(weatherManager.forecast.prefix(5)) { forecast in
                        WeatherDayView(dayOfWeek: forecast.dayOfWeek,
                                       imageName: forecast.icon,
                                       temperature: forecast.temperature)
                    }
                }
                
                Spacer()
                
                Button{
                    isNight.toggle()
                } label: {
                    WeatherButton(title: "Change Day Time",
                                  textColor: .blue,
                                  backgroundColor: .white)
                }
                
                Spacer()
            }
        }
        .onAppear {
            weatherManager.fetchWeather(for: locationManager.city, state: locationManager.state)
        }
    }
}

#Preview {
    ContentView()
}

struct WeatherDayView: View {
    
    var dayOfWeek: String
    var imageName: String
    var temperature: Int
    
    var body: some View {
        VStack{
            Text(dayOfWeek.uppercased())
                .font(.system(size: 16, weight: .medium, design: .default))
            
            Image(systemName: imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            Text("\(temperature)°")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct BackgroundView: View {
    
    @Binding var isNight: Bool
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [isNight ? .black : .blue,
                                                   isNight ? .gray : .lightBlue]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
        .edgesIgnoringSafeArea(.all)
    }
}

struct CityTextView: View {
    
    var cityName: String
    
    var body: some View {
        Text(cityName)
            .font(.system(size: 32, weight: .medium, design: .default))
            .foregroundColor(.white)
            .padding()
    }
}

struct MainWeatherStatusView: View {
    
    var imageName: String
    var temperature: Int
    
    var body: some View{
        VStack{
            Image(systemName: imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
            
            Text("\(temperature)°")
                .font(.system(size: 70, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.bottom, 40)
    }
}


