//
//  Video Module.swift
//  PlayerKit
//
//  Created by Anton2016 on 19.12.2022.


import UIKit

fileprivate struct VMSingletonStorage { static var instance: Any? }

public protocol IVideoModuleDelegate: NTXVideoModuleDelegate where Device == Int {}

public final class VideoModule<Delegate: IVideoModuleDelegate> {
 
  /// #В Приложении может быть только один экземпляр класскласса VideoModule,
  /// поэтому используется шаблон «Одиночка».
  /// Для получения экземпляра класса используется статическое свойство instance.
 
 public static var instance: VideoModule {
  if let instance = VMSingletonStorage.instance as? VideoModule { return instance }
  let delegate = Delegate()
  let instance = VideoModule(delegate: delegate)
  VMSingletonStorage.instance = instance
  return instance
 }
 
 public static var videoModuleDelegate: Delegate { instance.delegate }
 
 private init(delegate: Delegate) { self.delegate = delegate }

  // Для обработки возникающих в Модуле ошибок Приложение должно использовать шаблон «Делегирования». Для этого в
  // Приложении должен быть реализован интерфейс ‘IVideoModuleDelegate’.
 
 private let delegate: Delegate
 
  ///2.3.1 setAuthData
  ///Перед началом работы в Модуль нужно передать авторизационную информацию: JSESSIONID (параметр 'sessionId'); grails_remember_me (параметр 'refreshToken').
  
 
 private var credentials: NTXCredentials?
 
 public func setAuthData(sessionId: String, refreshToken: String){
  self.credentials = .init(token: refreshToken, sessionId: sessionId)
 }
 
/// 2.3.2 createView
/// Метод создаёт массив областей с плеерами и наложенными маркерами для проигрывания видео с камер. Камеры задаются идентификаторами СВН. Если переданы неверные идентификаторы СВН, то должен быть возвращен пустой массив.
 
 
 private var players = [ Int : PlayerAdapter ]()
 
 public func createView(cameraIds: [String] ) -> [ UIView ] {
  createView(cameraIds: cameraIds.compactMap{ Int($0) })
 }
 
 ///Метод накладывает на область маркер и возвращает URL для проигрывания видео в режиме панорамы. Камера задаётся идентификатором СВН. Если переданы неверные идентификаторы СВН, то должен быть возвращен пустой массив.
 ///#Cоздаваемые области работы плеера должны иметь реальный размер и довалены в superview для работы плееров видеомодуля!!
 
 
 ///##По уполчанию область создается ``CGRect(0,0,0,0)``!!##
 
 public func createView(cameraIds: [Int] ) -> [ UIView ] {
  
  guard let credentials = self.credentials else { return [] }
  
  return Set(cameraIds).compactMap{ deviceID -> UIView? in
   if let view = players[deviceID]?.ownerView { return view }
   let view = UIView(frame: .zero)
   
   let player = NTXPlayerAdapter(device: deviceID,
                                 credentials: credentials,
                                 ownerView: view,
                                 delegate: delegate) { [ weak self ] device in
    self?.players[device] = nil
    
   }
   
   guard let _ = try? player.start() else { return nil }
   players[deviceID] = player
   view.tag = deviceID
   return view
  }
 }
 
 
 public func getVideoPlayerState(cameraId: String) -> VideoPlayerState {
  guard let id = Int(cameraId) else { return .error }
  return getVideoPlayerState(cameraId: id)
 }
 
 public func getVideoPlayerState(cameraId: Int) -> VideoPlayerState {
  players[cameraId]?.playerState ?? .error
 }
 

 public func play(cameraIds: [String], time: UInt = 0) -> Bool {
  play(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 
 public func play(cameraIds: [Int], time: UInt = 0) -> Bool {
  
  if cameraIds.isEmpty { return false }
  
  return cameraIds
   .compactMap{ players[$0] }
   .map{ time == 0 ? $0.play() : $0.play(at: time)}
   .allSatisfy{$0}
 }

 public func pause(cameraIds: [String]) -> Bool {
  pause(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 
 public func pause(cameraIds: [Int]) -> Bool {
  
  if cameraIds.isEmpty { return false }
  
  return Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.pause() }
   .allSatisfy{$0}
 }

 public func toggeMute(cameraIds: [String]) -> Bool {
  play(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 
 public func toggeMute(cameraIds: [Int]) -> Bool {
  
  if cameraIds.isEmpty { return false }
  
  return Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.toggleMuted() }
   .allSatisfy{ $0 }
 }

 public func stop(cameraIds: [String]) -> Bool {
  stop(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 
 public func stop(cameraIds: [Int]) -> Bool {
  
  if cameraIds.isEmpty { return false }
  
  return Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.stop() }
   .allSatisfy{ $0 }
 }
 
 
 public func getArchiveIntervals(cameraId: String) -> [ DateInterval ]{
  guard let id = Int(cameraId) else { return [] }
  return getArchiveIntervals(cameraId: id)
 }
 
 public func getArchiveIntervals(cameraId: Int) -> [ DateInterval ]{
  players[cameraId]?.archiveDateInterval ?? []
 }
 
 public func getArchiveIntervals(cameraId: String) -> [(Int, Int)]{
  guard let id = Int(cameraId) else { return [] }
  return getArchiveIntervals(cameraId: id)
 }
 
 public func getArchiveIntervals(cameraId: Int) -> [(Int, Int)]{
  players[cameraId]?.archiveDepthInterval ?? []
 }
 
}
