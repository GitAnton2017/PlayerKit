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

///# Рабочий объект видео модуля одиночка (Singleton).
public typealias VideoModule = GenericVideoModule<DefaultPlayerDelegate>

///# Для обработки возникающих в Модуле ошибок Приложение должно использовать шаблон «Делегирования». Для этого в
/// Приложении должен быть реализован интерфейс ‘IVideoModuleDelegate’
/// ``public weak var delegate: IVideoModuleDelegate
 
public protocol IVideoModuleDelegate where Self: AnyObject {

 /// ``Ошибка авторизации.
 func didFailToAuth         (error: VideoModuleError)

 ///``Отсутствие связи (недоступность видеопотока) для камер.
 func didFailToConnect      (error: VideoModuleError)
 
 ///``Не получилось загрузить информацию о камерах, архивах, пользователе.
 func didFailToGetInfo      (error: VideoModuleError)

 ///``Не удалось запустить видео для камер.
 func didFailToPlay         (error: VideoModuleError)
 
 ///``Отсутствие видеоархива в указанное время
 func didFailToPlayArchive  (error: VideoModuleError)
 
 ///``Состояние плеера для конкретной камеры изменилось.
 func didChangeState(cameraId: String, state: VideoPlayerStateEnum)
 
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
 
 public weak var delegate: IVideoModuleDelegate? {
  didSet {
   self.playerDelegate.videoModuleDelegate = delegate
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
 
 
 
 
///# VIDEO MODULE - AUTHORIZATION.
///# Перед началом работы в Модуль нужно передать авторизационную информацию:
///
///``- JSESSIONID (параметр 'sessionId')``;
///``- grails_remember_me (параметр 'refreshToken')``.

/// При передаче не корректых значений делегат (`IVideoModuleDelegate`) сообщает об ошибке авторизации в методе делегата
///`didFailToAuth(error: VideoModuleError)
  
 public func setAuthData(sessionId: String, refreshToken: String){
  self.credentials = .init(token: refreshToken, sessionId: sessionId)
 }
 
 
 
 
/// # VIDEO MODULE - CREATE VIEW.
/// # Метод создаёт массив областей с плеерами и наложенными маркерами для проигрывания видео с камер.
/// Камеры задаются идентификаторами СВН в виде мссива строк `["1", "22", "223"]` либо массива целочисленных значений `[1, 22, 223]` (2 overload ниже). Если переданы все неверные идентификаторы СВН (либо строки не могут быть конвертированы в ID камер Int),
/// метод возвращает пустой массив. Для верных ID создаются индвидульный UIView  плееров для добавления в UI клтентского приложения.
///
/// ``Cоздаваемые области работы плеера должны иметь реальный размер и добавлены после создания в клиентском
/// ``приложении в какой-либо Superview (например: UIViewController UIView, UICollectionViewCell content view,
/// ``UITableViewCell content view, SwiftUI View) c реальными размерами для работы плееров видеомодуля!
/// ``По уполчанию область создается - CGRect(0,0,0,0)!!! ``
///
///  ПРИМЕР ЗАПУСКА ОДНОЙ КАМЕРЫ (НА БАЗЕ UIViewController):
///
/// `videoModule.setAuthData(sessionId: user.sessionId, refreshToken: user.token)
///
/// `VideoModule.instance.delegate = self //UIViewController is VM Delagate!
///
/// `let pv = videoModule.createView(cameraIds: ["12345"])[0]
/// `let pv = videoModule.createView(cameraIds: [ 12345 ])[0]
///
/// `pv.translatesAutoresizingMaskIntoConstraints = false
///
/// `self.view.addSubview(pv)
///
/// `self.view.topAnchor     .constraint(equalTo:  pv.topAnchor,      constant: 0   ).isActive = true
/// `self.view.bottomAnchor  .constraint(equalTo:  pv.bottomAnchor,   constant: 0   ).isActive = true
/// `self.view.leadingAnchor .constraint(equalTo:  pv.leadingAnchor,  constant: 0   ).isActive = true
/// `self.view.trailingAnchor.constraint(equalTo:  pv.trailingAnchor, constant: 0   ).isActive = true

 
 public func createView(cameraIds:  [ String ] ) -> [ UIView ] {
  createView(cameraIds: cameraIds.compactMap{ Int($0) })
 }
 
/// Вариант для передачи массива целочисленных идентификаторов СВН. (`[1, 22, 223]`)
 
 public func createView(cameraIds: [ Int ] ) -> [ UIView ] {
  
  guard let credentials = self.credentials else { return [] }
  
  return Set(cameraIds).compactMap{ deviceID -> UIView? in
   if let view = players[deviceID]?.ownerView { return view }
   let view = UIView(frame: .zero)
   view.clipsToBounds = true
   
   let player = NTXPlayerAdapter(device: deviceID,
                                 credentials: credentials,
                                 ownerView: view,
                                 delegate: playerDelegate) { [ weak self ] device in
    self?.players[device] = nil
    
   }
   
   //player.securityMarker = EchdSettingsService.instance.securityMarker
   
   guard let _ = try? player.start() else { return nil }
   players[ deviceID ] = player
   view.tag = deviceID
   return view
  }
 }
 
 
 
 
///# VIDEO MODULE - GET VIDEO PLAYER STATE.
///# Метод возвращает текущее состояние плеера связанного с конкретной СВН. (`VideoPlayerStateEnum`).
///     - ``case loading - идет опрос и зазгрузка СВН
///  - ``case started - плеер запущен, но проигрывание ещё не началось
///  - ``case stopped - плеер остановлен
///  - ``case playing - плеер играет
///  - ``case paused  - плеер приостановлен
///  - ``case error   - произошла ошибка
/// ``Камера задается идентификатором СВН в виде String, конвертируемым в Int либо сразу Int ( 2 вариант ниже ).
/// Если ID камеры задан не верно, либо строковый ID не может быть конвертирован в Int, либо же камера отсутсует в видео модуле и для нее еще не создан плеер, данный метод возвращает значение `VideoPlayerStateEnum.error`.

 public func getVideoPlayerState(cameraId: String) -> VideoPlayerStateEnum {
  guard let id = Int(cameraId) else { return .error }
  return getVideoPlayerState(cameraId: id)
 }
 
///  Вариант для передачи целочисленого идентификатора СВН.
 public func getVideoPlayerState(cameraId: Int) -> VideoPlayerStateEnum { players[cameraId]?.playerState ?? .error }
 
 
 
 
 
 
///# VIDEO MODULE - PLAY VIDEO AT TIME.
///# Метод вызывает проигрывание видео с СВН с определенной временной целочисленной метки из архива записей.
///    Метка времени сервера равна кол-ву секунд в Int формате с момента `1 января 1970 (00:00:00 UTC on 1 January 1970.)`
///  Если задана метка времени вне интевала архива возвращаемого в методе запроса границ архива `getArchiveIntervals(cameraId:)`
///  Метод возвращает `False`. Если в массиве `cameraIds: [String]` переданы неверные идентификаторы СВН
///  (или строки не конвертируемы в целочисленный вариант Int), метод возвращает `False.`
 
 public func play(cameraIds: [ String ], time: UInt) -> Bool {
  play(cameraIds: cameraIds.compactMap{ Int($0)}, time: time )
 }
 

///  Вариант для передачи массива целочисленных идентификаторов СВН. `[1, 22, 223]`
 
 public func play(cameraIds: [ Int ], time: UInt) -> Bool {
  
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.play(at: time)}
   .allSatisfy{$0}
 }
 
 
 

 
///# VIDEO MODULE - PLAY LIVE VIDEO.
///# Метод вызывает включение либо перевод на трасляцию живого видео с СВН.
///    Метод возвращает `FALSE` если проигрывание одной из камер плеера не возможен в данном режиме.
///  Если данный режим успешно запущен для всех камер в списке, метод возвращает `TRUE`.
///  При повторном вызове данного метода в режиме проигрывания живого видео, плеер ставится на паузу по указанным СВН.
///  Вариант для передачи массива строковых идентификаторов СВН, конвертируемых в массив [ Int ] - `["1","22","223"]`
  
 public func play(cameraIds: [ String ]) -> Bool { play(cameraIds: cameraIds.compactMap{ Int($0)}) }
 
///  Вариант для передачи массива целочисленных идентификаторов СВН. `[1, 22, 223]`
 
 public func play(cameraIds: [ Int ]) -> Bool {
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.play() }
   .allSatisfy{$0}
 }
 
 
 
 
 
///# VIDEO MODULE - PAUSE LIVE/ARCHIVE VIDEO.
///# Метод вызывает постановку на паузу живой и архивной трнсляции видео с СВН.
///    Метод возвращает `FALSE` если постановка на паузу одной из камер плеера не возможен в данном режиме.
///  Если данный режим успешно установлен для всех камер в списке, метод возвращает `TRUE`.
///  При повторном вызове данного метода в режиме проигрывания живого видео, плеер ставится на паузу по указанным СВН.
///  Вариант для передачи массива строковых идентификаторов СВН, конвертируемых в массив [ Int ] - `["1", "22", "223"]`
 
 
 public func pause(cameraIds: [ String ] ) -> Bool {
  pause(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 
///  Вариант для передачи массива целочисленных идентификаторов СВН. `[1, 22, 223]`
  
 public func pause(cameraIds: [ Int ]) -> Bool {
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.pause() }
   .allSatisfy{$0}
 }

 
 
 
 
///# VIDEO MODULE - TOGGLE (SET) CAMERA MUTED STATE.
///# Включает либо выключает звук при трансляции с СВН, имеющей поддержку трансляции видеопотока со звуком.
///    Если СВН не поддерживает звук плеер этой камеры возвращает `FALSE`и данный метод возвращает `FALSE`.
///  Параметр `cameraIds: [String]` должен содержать ID СВН в текстовом формате конвертируемый целочисленные  ID СВН - [Int].
/// `["1", "23", "222"]`.
///
 public func toggleMute(cameraIds: [ String ], isMuted: Bool) -> Bool {
  toggeMute(cameraIds: cameraIds.compactMap{ Int($0)}, isMuted: isMuted )
 }
 
  /// Вариант для передачи целочисленного массива ID СВН - cameraIds: `[1, 23, 222]`.

 public func toggeMute(cameraIds: [ Int ], isMuted: Bool) -> Bool {
  
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.toggleMuted(isMuted: isMuted) }
   .allSatisfy{ $0 }
 }

///# VIDEO MODULE - TOGGLE VIEW MODE STATE.
///# Включает покадровый режим плееров (VIEW MODE) с разовым запросом кадра от заданных СВН.
///    Для динамического покадрового просмотра необходимо организовать периодический поллинг `(camera polling)`
///  с использованием данного метода из приложения клиента с указанием флага `isVideo = true`.
///  Для остановки данного режима `(VIEW MODE)` необходиио вызвать данный метод еще раз и передать значение  `isVideo = false.
///  После этого плееры по заданным СВН переходят в режим живой трансляции архива СВН либо живой трансляции СВН.
///  Параметр `cameraIds: [String]` должен содержать ID СВН в текстовом формате конвертируемый целочисленные  ID СВН - [Int].
/// `["1", "23", "222"]`.
  

 public func toggleViewMode(cameraIds: [ String ], isVideo: Bool) -> Bool {
  toggleViewMode(cameraIds: cameraIds.compactMap{ Int($0) }, isVideo: isVideo)
 }
 
 /// Вариант для передачи целочисленного массива ID СВН - cameraIds: `[1, 23, 222]`.

 public func toggleViewMode(cameraIds: [ Int ], isVideo: Bool) ->  Bool {
  
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.toggleViewMode(isVideo: isVideo) }
   .allSatisfy{ $0 }
 }
 
 
///# VIDEO MODULE - TOGGLE VIEW MODE POLLING STATE.
/// Вариант метода, который включает покадровый режим плееров (VIEW MODE) с автоматическим периодическим поллингом сервера по всем СВН в запросе. Повторный вызов данного метода по камерам останавливает поллинг сервера и покадровый режим просмотра (VIEW MODE).
 
 public func toggleViewMode(cameraIds:  [ String ]) ->  Bool {
  toggleViewMode(cameraIds: cameraIds.compactMap{ Int($0) })
 }
 
/// Вариант для передачи целочисленного массива ID СВН - cameraIds: `[1, 23, 222]`.
 public func toggleViewMode(cameraIds:  [ Int ]) ->  Bool {
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.toggleViewMode() }
   .allSatisfy{ $0 }
 }
 
 
///# VIDEO MODULE - STOP CAMERA PLAYER STATE.
///# Останавливает полностью трансляцию плееров по заданным камерам.
///   Параметр `cameraIds: [String]` должен содержать ID СВН в текстовом формате конвертируемый целочисленные  ID СВН - [Int].
/// `["1", "23", "222"]`.
 
 public func stop(cameraIds: [ String ]) -> Bool {
  stop(cameraIds: cameraIds.compactMap{ Int($0)} )
 }
 

/// Вариант для передачи целочисленного массива ID СВН - cameraIds: `[1, 23, 222]`.

 public func stop(cameraIds: [ Int ]) -> Bool {
  cameraIds.isEmpty ? false : Set(cameraIds)
   .compactMap{ players[$0] }
   .map{ $0.stop() }
   .allSatisfy{ $0 }
 }
 
 
///# VIDEO MODULE - GET CAMERA PLAYER ARCHIVE INTERVALS.
///# Метод возвращает доступный интрервал записи архива видеонаблюдения.
///    Камера задается идентификатором СВН в виде String, конвертируемым в Int либо сразу Int ( 2 вариант ниже ).

 public func getArchiveIntervals(cameraId: String) -> [ DateInterval ]{
  guard let id = Int(cameraId) else { return [] }
  return getArchiveIntervals(cameraId: id)
 }
 
 public func getArchiveIntervals(cameraId: Int) -> [ DateInterval ]{
  players[cameraId]?.archiveDateInterval ?? []
 }
 
 

 
///# VIDEO MODULE - GET CAMERAs DESCRIPTIONs.
///# Метод возвращает технические возможности камер из списка.
///  public struct CameraDescription {
///  public let cameraId: String -
///  public let isVR: Bool
///  public let hasSound: Bool
/// }
///
/// Камера задается идентификатором СВН в виде String, конвертируемым в Int либо сразу Int ( 2 вариант ниже ).
  
 public func getCamerasDescriptions(cameraIds: [String]) -> [CameraDescription] {
  getCamerasDescriptions(cameraIds: cameraIds.compactMap{Int($0)})
 }
 
  /// Вариант для передачи целочисленного массива ID СВН - cameraIds: `[1, 23, 222]`.
  ///
 public func getCamerasDescriptions(cameraIds: [Int]) -> [CameraDescription] {
  Set(cameraIds).compactMap{ players[$0]?.vssDescription }
   
 }

 
 /// Флаги для вкл/откл внутренних индивидуальных кнопок управления плеерами и их уведомлений о состояниях.
 /// 
 public var showsPlayersInternalControls : Bool = false {
  didSet {
   players.values.forEach{ $0.showsInternalControls = showsPlayersInternalControls }
  }
 }
 public var showsPlayersInternalAlerts   : Bool = false {
  didSet {
   players.values.forEach{ $0.showsInternalAlerts = showsPlayersInternalAlerts }
  }
 }

 func getArchiveIntervals(cameraId: String) -> [(Int, Int)]{
  guard let id = Int(cameraId) else { return [] }
  return getArchiveIntervals(cameraId: id)
 }
 
 func getArchiveIntervals(cameraId: Int) -> [(Int, Int)]{
  players[cameraId]?.archiveDepthInterval ?? []
 }
 
 
 
 
}
