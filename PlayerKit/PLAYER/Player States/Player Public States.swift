//
//  Player States Public Enum.swift
//  PlayerKitFramework
//
//  Created by Anton2016 on 16.12.2022.
//


///Перечень возможных значений состояния плеера (VideoPlayerStateEnum, п. 3.2.1)
///
///– case stopped (плеер остановлен);
///– case paused (плеер приостановлен);
///– case playing (плеер играет);
///– case error (произошла ошибка);
///– case started (плеер запущен, но проигрывание ещё не началось);
///– case loading (идёт загрузка информации об СВН).

public enum NTXVideoPlayerStates: String, Codable, Hashable, CaseIterable {
 case stopped   // (плеер остановлен);
 case paused    // (плеер приостановлен);
 case playing   // (плеер играет);
 case playingArchiveForward
 case playingArchiveBack
 case error     // (произошла ошибка);
 case started   // (плеер запущен, но проигрывание ещё не началось);
 case loading
 case connecting
 case connected
}
