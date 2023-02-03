//
//  Player States Public Enum.swift
//  PlayerKitFramework
//
//  Created by Anton V. Kalinin on 16.12.2022.
//

///– case stopped (плеер остановлен);
///– case paused (плеер приостановлен);
///– case playing (плеер играет);
///– case error (произошла ошибка);
///– case started (плеер запущен, но проигрывание ещё не началось);
///– case loading (идёт загрузка информации об СВН).





public typealias VideoPlayerStateEnum = NTXVideoPlayerStates

public enum NTXVideoPlayerStates: String, Codable, Hashable, CaseIterable {
 case loading   /// (1) идет опрос и зазгрузка СВН
 case started   /// (2) плеер запущен, но проигрывание ещё не началось
 case stopped   /// (3) плеер остановлен
 case playing   /// (4) плеер играет
 case paused    /// (5) плеер приостановлен
 case error     /// (6) произошла ошибка
}
