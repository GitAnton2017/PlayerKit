//
//  Video Module.swift
//  PlayerKit
//
//  Created by Anton V. Kalinin on 19.12.2022.


import UIKit
import Foundation

fileprivate struct VMSingletonStorage { static var instance: Any? }

public struct VideoModuleError: Error, Hashable {
 let cameraId: String     /// (идентификатор камеры)
 let description: String  /// (описание ошибки)
 let url: URL?            /// (URL, для которого произошла ошибка).
}

///Видео модуль Singleton.
public typealias VideoModule = GenericVideoModule<DefaultPlayerDelegate>

/// Для обработки возникающих в Модуле ошибок Приложение должно использовать шаблон «Делегирования». Для этого в
/// Приложении должен быть реализован интерфейс ‘IVideoModuleDelegate’.
 
public protocol IVideoModuleDelegate where Self: AnyObject {

 /// Ошибка авторизации.
 func didFailToAuth(error: VideoModuleError)

 ///Отсутствие связи (недоступность видеопотока) для камер.
 func didFailToConnect(error: VideoModuleError)
 
 ///Не получилось загрузить информацию о камерах, архивах, пользователе.
 func didFailToGetInfo(error: VideoModuleError)

 ///Не удалось запустить видео для камер.
 func didFailToPlay(error: VideoModuleError)
 
 ///Отсутствие видеоархива в указанное время
 func didFailToPlayArchive(error: VideoModuleError)
 
 ///Состояние плеера для конкретной камеры изменилось.
 func didChangeState(cameraId: String, state: VideoPlayerState)
 
}

public final class GenericVideoModule<Delegate: NTXVideoPlayerDelegate> where Delegate.Device == Int {
 
 private var credentials: NTXCredentials?
 
 private var players = [ Delegate.Device : PlayerAdapter ]()
 
 public static var instance: GenericVideoModule {
  if let instance = VMSingletonStorage.instance as? GenericVideoModule { return instance }
  let delegate = Delegate()
  let instance = GenericVideoModule(playerDelegate: delegate)
  VMSingletonStorage.instance = instance
  return instance
 }
 
 public weak var videoModuleDelegate: IVideoModuleDelegate? {
  didSet {
   self.playerDelegate.videoModuleDelegate = videoModuleDelegate
  }
 }
 
 
 private var memoryWarningToken: NSObjectProtocol?
 
 private init(playerDelegate: Delegate) {
  
  self.playerDelegate = playerDelegate
  
  self.memoryWarningToken = NotificationCenter.default
   .addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main) { [ weak self ] _ in self?.players.values.forEach{ $0.purgeArchiveCache()} }
 }
 
 deinit {
  if let memoryWarningToken = memoryWarningToken {
   NotificationCenter.default.removeObserver(memoryWarningToken)
  }
 }
 
 private let playerDelegate: Delegate
 
 ///Перед началом работы в Модуль нужно передать авторизационную информацию:
 ///``JSESSIONID (параметр 'sessionId')``;
 ///``grails_remember_me (параметр 'refreshToken')``.

 ///При передаче не корректых значений делегат (IVideoModuleDelegate) сообщает об ошибке авторизации в методе делегата
 ///``didFailToAuth(error: VideoModuleError)
  

 
 public func setAuthData(sessionId: String, refreshToken: String){
  self.credentials = .init(token: refreshToken, sessionId: sessionId)
 }
 
/// Метод создаёт массив областей с плеерами и наложенными маркерами для проигрывания видео с камер. Камеры задаются идентификаторами СВН в виде мссива строк либо массива челочисленных значений (2 вариант ниже).
/// Если переданы неверные идентификаторы СВН (либо строки не могут быть конвертированы в ID камер Int),
/// метод возвращает пустой массив. Cоздаваемые области работы плеера должны иметь реальный размер и добавлены в Superview c реальными размерами для работы плееров видеомодуля! По уполчанию область создается ``CGRect(0,0,0,0)``.
 
 public func createView(cameraIds: [String] ) -> [ UIView ] {
  createView(cameraIds: cameraIds.compactMap{ Int($0) })
 }
 
 
 /// Вариант для передачи массива целочисленных идентификаторов СВН.
 
 public func createView(cameraIds: [Int] ) -> [ UIView ] {
  
  guard let credentials = self.credentials else { return [] }
  
  return Set(cameraIds).compactMap{ deviceID -> UIView? in
   if let view = players[deviceID]?.ownerView { return view }
   let view = UIView(frame: .zero)
   
   let player = NTXPlayerAdapter(device: deviceID,
                                 credentials: credentials,
                                 ownerView: view,
                                 delegate: playerDelegate) { [ weak self ] device in
    self?.players[device] = nil
    
   }
   
   player.securityMarker = EchdSettingsService.instance.securityMarker
   
   guard let _ = try? player.start() else { return nil }
   players[deviceID] = player
   view.tag = deviceID
   return view
  }
 }
 
///Метод возвращает текущее состояние плеера связанного с конкретной СВН из списка VideoPlayerState Enum.
/// case loading     = 1  (1) идет опрос и зазгрузка СВН
/// case started     = 2   (2) плеер запущен, но проигрывание ещё не началось
/// case stopped   = 3   (3) плеер остановлен
/// case playing    = 4    (4) плеер играет
/// case paused    = 5   (5) плеер приостановлен
/// case error        = 6   (6) произошла ошибка
/// Камера задается идентификатором СВН в виде String, конвертируемым в Int либо сразу Int ( 2 вариант ниже ).

 public func getVideoPlayerState(cameraId: String) -> VideoPlayerState {
  guard let id = Int(cameraId) else { return .error }
  return getVideoPlayerState(cameraId: id)
 }
 
 ///Вариант для передачи целочисленого идентификатора СВН.
 public func getVideoPlayerState(cameraId: Int) -> VideoPlayerState {
  players[cameraId]?.playerState ?? .error
 }
 
 ///Метод вызывает проигрывание видео с СВН с определенной временной целочисленной метки из архива записей.
 ///Метка времени сервера равна кол-ву секунд в Int формате с момента 1 января 1970 (00:00:00 UTC on 1 January 1970.)
 ///Если задана метка времени вне интевала архива возвращаемого в методе запроса границ архива getArchiveIntervals(cameraId:)
 ///Метод возвращает False. Если в массиве ``cameraIds: [String]`` переданы неверные идентификаторы СВН (или строки не конвертируемы в целочисленный вариант Int), метод возвращает False.
 
 public func play(cameraIds: [String], time: UInt) -> Bool {
  play(cameraIds: cameraIds.compactMap{ Int($0)}, time: time )
 }
 
 ///Метод вызывает проигрывание живого видео стрима с СВН.
 ///Метод возвращает false если проигрывение плеера камеры в данном состоянии не возможно.
 ///При повторном вызове данного метода в режиме проигрывания живого видео, плеер ставится на паузу по указанным СВН.
  
 public func play(cameraIds: [String]) -> Bool {
  play(cameraIds: cameraIds.compactMap{ Int($0)})
 }
 
 ///Вариант для передачи массива целочисленных идентификаторов СВН.
 ///
 public func play(cameraIds: [Int], time: UInt) -> Bool {
  
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.play(at: time)}
   .allSatisfy{$0}
 }

 
 public func play(cameraIds: [Int]) -> Bool {
  
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.play()}
   .allSatisfy{$0}
 }
 
 public func pause(cameraIds: [ String ] ) -> Bool {
  pause(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 
 public func pause(cameraIds: [Int]) -> Bool {
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.pause() }
   .allSatisfy{$0}
 }

 public func toggeMute(cameraIds: [ String ]) -> Bool {
  toggeMute(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 
 public func toggeMute(cameraIds: [ Int ]) -> Bool {
  
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.toggleMuted() }
   .allSatisfy{ $0 }
 }

  ///Включает покадровый режим плееров (VIEW MODE) с разовым запромом кадра с  СВН.
  ///Для динамического покадрового просмотра необходимо организовать периодический поллинг с использованием данного метода.
 func toggleViewMode(cameraIds: [Int], isVideo: Bool) ->  Bool {
  
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.toggleViewMode(isVideo: isVideo) }
   .allSatisfy{ $0 }
 }

 ///Включает покадровый режим плееров с автоматическим периодическим поллингом сервера по всем СВН в запросе.
 ///Повторный вызов данного метода по камерам останавливает поллинг сервера и пкадровый режим просмотра.
 
 func toggleViewMode(cameraIds: [Int]) ->  Bool {
  cameraIds.isEmpty ? false : Set(cameraIds).compactMap{ players[$0] }.map{ $0.toggleViewMode() }.allSatisfy{ $0 }
 }
 
 public func stop(cameraIds: [ String ]) -> Bool {
  stop(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 
 public func stop(cameraIds: [Int]) -> Bool {
  cameraIds.isEmpty ? false : Set(cameraIds).compactMap{ players[$0] }.map{ $0.stop() }.allSatisfy{ $0 }
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
 
 public func getCamerasDescriptions(cameraIds: [Int]) -> [CameraDescription] {
  Set(cameraIds).compactMap{ players[$0]?.vssDescription }
   
 }

 public func getCamerasDescriptions(cameraIds: [String]) -> [CameraDescription] {
  getCamerasDescriptions(cameraIds: cameraIds.compactMap{Int($0)})
 }
}
