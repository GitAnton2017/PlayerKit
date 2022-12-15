//
//  AppContext.swift
//  AreaSight
//
//  Created by Shamil on 5/22/20.
//  Copyright © 2020 Netris. All rights reserved.
//

import Foundation

struct AppContext {
    
    // MARK: - Default server addresses
    
    struct DefaultServerAddresses {
        
        static let main = DefaultServerAddresses.setServerAddress()
        // В данный момент совпадает с главным хостом
        static let test = DefaultServerAddresses.setServerAddress()
        
        static let mainPortal = "https://echd.mos.ru"
        static let testPortal = "https://echd.mos.ru"
        static let testPortalWithoutPort = "https://testportal-echd.mos.ru:1443"
        static let demoPortal = "https://demoportal-echd.mos.ru"
        static let demoPortalWithPort = "https://demoportal-echd.mos.ru:1443"
        static let stage60 = "https://stage60-echd.mos.ru"
        
        static func setServerAddress() -> String {
            #if PROFILE_ALPHA
            return DefaultServerAddresses.mainPortal
            #else
            return DefaultServerAddresses.mainPortal
            #endif
        }
    }
    
    // MARK: - Paths
    
    struct Paths {
        
        // Sudir
        
        static let sudirConfigurationPath = "/login/sudir/config"
        static let sudirAuthenticatePath = "/login/sudir/authenticate"
        static let sudirTestRegistrationPath = "/blitz/oauth/register"
        static let sudirAuthorizationCodePath = "/blitz/oauth/ae"
        static let sudirTokensPath = "/blitz/oauth/te"
        static let sudirUserDataPath = "/blitz/oauth/me"
        
        // User agreement
        
        static let userAgreementsPath = "/notices/userAgreements"
        static let acceptAgreement = "/notices/acceptAgreement"
        static let agreement = "/notices/agreement"
        
        // Tickets
        
        static let user = "/user"
        static let ajaxTicketTypes = "/helpdesk/ajaxTicketTypes"
        static let ajaxTickets = "/helpdesk/ajaxTickets"
        
        // Support
        
        static let ajaxRegister = "/helpdesk/ajaxRegister"
    }
    
    // MARK: - Schemes
    
    struct Schemes {
        
        static let http = "http"
        static let https = "https"
        static let ruNetrisVideogorod = "ru.netris.videogorod"
    }
    
    // MARK: - App center
    
    struct AppCenterKeys {
        
        static let enterprice = "8aad1c69-53bc-4a74-8cd5-cf6538a4136e"
        static let beta = "f9327f97-93af-4501-a93e-0ece4232ad8d"
        static let alpha = "10e3f01d-c32a-4fd2-8937-d2bf24f9cfca"
    }
    
    // MARK: - Sudir
    
    struct Sudir {
        
        static let softwareId = Sudir.setSoftwareId()
        static let softwareStatement = Sudir.setSoftwareStatement()
        static let initialAccessToken = Sudir.setInitialAccessToken()
        
        static let authorizationUrl = Sudir.setAuthorizationUrl()
        static let authorizationUrlWithoutScheme = Sudir.setAuthorizationUrlWithoutScheme()
        
        static let mainSoftwareId = "echd.mos.ru-mp"
        static let mainSoftwareStatement = "eyJ0eXAiOiJKV1QiLCJibGl0ejpraW5kIjoiU09GVF9TVE0iLCJhbGciOiJSUzI1NiJ9.eyJncmFudF90eXBlcyI6WyJhdXRob3JpemF0aW9uX2NvZGUiLCJjbGllbnRfY3JlZGVudGlhbHMiLCJyZWZyZXNoX3Rva2VuIl0sInNjb3BlIjoib3BlbmlkIHByb2ZpbGUiLCJqdGkiOiI0NWFkZWM4Yi00OGYxLTQ5YjUtOWVmNi03NjE0ZWZlNWU2Y2MiLCJzb2Z0d2FyZV9pZCI6ImVjaGQubW9zLnJ1LW1wIiwic29mdHdhcmVfdmVyc2lvbiI6IjEiLCJyZXNwb25zZV90eXBlcyI6WyJjb2RlIl0sImlhdCI6MTYyNDU0NTQxNCwicmVkaXJlY3RfdXJpcyI6WyJydS5uZXRyaXMudmlkZW9nb3JvZDovL29hdXRoMnJlZGlyZWN0L3N1ZGlyL2xvZ2luIl0sImF1ZCI6WyJlY2hkLm1vcy5ydS1tcCJdLCJpc3MiOiJodHRwczovL3N1ZGlyLm1vcy5ydSJ9.OwSPhKBH6ijqn0nmq9XsRWvqxxk7MGUZnLdPUKugDaTElwLjlpjgpjMsMrHD9YJhfFi3sKLD4h7QpT8zIfAic7RQ_Co_ydtV13dHJWcR6_d_b5EveE0LkQTFALLlhQ57TL7_KEohv74TyRMIkQlravE9oO6Bg5KBFIXaT2MuP0f0ajXZtcHlhXDyYDR1GcSbyDoelygVnpkst9jWSIfaUHhnQoCRmVi3LbVSOVsA6bII0SIyqYQ3nHSE_QvhKs35QToDH_dXJuCpnB3PYtM6nFywI11po8omF2bCLn37e5APGb1OXu9Hw4081bFq5IfZ4oeRNJG1G0U7H3X-zm_mKQ"
        static let mainInitialAccessToken = "B7cu2Cwd10Pz3lm1zRkqOYPualiVCdCgedG1XNSrk6pajpCr3o_fsKn3vegCaUOOzgOYke7Ex74TQnH7mhF_dw"
        
        static let testSoftwareId = "demoportal-echd-mp"
        static let testSoftwareStatement = "eyJ0eXAiOiJKV1QiLCJibGl0ejpraW5kIjoiU09GVF9TVE0iLCJhbGciOiJSUzI1NiJ9.eyJncmFudF90eXBlcyI6WyJhdXRob3JpemF0aW9uX2NvZGUiLCJjbGllbnRfY3JlZGVudGlhbHMiLCJyZWZyZXNoX3Rva2VuIl0sInNjb3BlIjoib3BlbmlkIHByb2ZpbGUiLCJqdGkiOiIzM2U4NGNjNC1mYzQ1LTQ4ZGItOTMwMC1lZGU4N2M4MTA4MTYiLCJzb2Z0d2FyZV9pZCI6ImRlbW9wb3J0YWwtZWNoZC1tcCIsInNvZnR3YXJlX3ZlcnNpb24iOiIxIiwicmVzcG9uc2VfdHlwZXMiOlsiY29kZSJdLCJpYXQiOjE2MDI2ODAzNzMsInJlZGlyZWN0X3VyaXMiOlsicnUubmV0cmlzLnZpZGVvZ29yb2Q6Ly9vYXV0aDJyZWRpcmVjdC9zdWRpci9sb2dpbiJdLCJhdWQiOlsiZGVtb3BvcnRhbC1lY2hkLW1wIl0sImlzcyI6Imh0dHBzOi8vc3VkaXItdGVzdC5tb3MucnUifQ.jEBoydCe2zKBnYRrD8u1EYvb92DzwTBDLXJGr0K0uXVOcx0-PTCt-rgIPPXBy_wpQBwu_4rosKyx3VoSB2ZF4iDaBQazUEZkjRS2Gsz2rLD25BHuRYCQHck2GtVTndHudaz98N01XEh8fl5Klev-qDPD91A6QRXS0LMURNZznpobx-QRuCUj6CkXXnohNw7rf46w8ujwLQn5shtTI1MWdgJ64Z1BqONGGi8ImlKyYodJ2Rx02EhVReq5ivHT1cbJxXmNbGkqAIRGHEoqiVUyC4cmttzZEpdM6HiFQfEslIMQseo53Fr7p36Fd0bKmCmgGnnrp4RqS8eYxL7J9Hbk5A"
        static let testInitialAccessToken = "NtGgvkk7eIyIlAv5aEbi5_bjr12kB4q4Z-GesLNjw3Og9W07foMFlGJhaiSh7mdv_ipuj5CrsosYSe4NBpzfPw"
        
        static let mainAuthorizationUrl = "https://sudir.mos.ru"
        static let mainAuthorizationUrlWithoutScheme = "sudir.mos.ru"
        
        static let testAuthorizationUrl = "https://sudir-test.mos.ru"
        static let testAuthorizationUrlWithoutScheme = "sudir-test.mos.ru"
        
        static func setSoftwareId() -> String {
            #if PROFILE_ALPHA
            return Sudir.testSoftwareId
            #else
            return Sudir.mainSoftwareId
            #endif
        }
        
        static func setSoftwareStatement() -> String {
            #if PROFILE_ALPHA
            return Sudir.testSoftwareStatement
            #else
            return Sudir.mainSoftwareStatement
            #endif
        }
        
        static func setInitialAccessToken() -> String {
            #if PROFILE_ALPHA
            return Sudir.testInitialAccessToken
            #else
            return Sudir.mainInitialAccessToken
            #endif
        }
        
        static func setAuthorizationUrl() -> String {
            #if PROFILE_ALPHA
            return Sudir.testAuthorizationUrl
            #else
            return Sudir.mainAuthorizationUrl
            #endif
        }
        
        static func setAuthorizationUrlWithoutScheme() -> String {
            #if PROFILE_ALPHA
            return Sudir.testAuthorizationUrlWithoutScheme
            #else
            return Sudir.mainAuthorizationUrlWithoutScheme
            #endif
        }
    }
    
    // MARK: - Yandex map
    
    static let yandexMapApiKey = "15b26b47-5f9e-418b-8e59-099287a14f56"
    static let yandexMapGeocodeApiKey = "d5e98521-c6c2-4cac-8234-021d8c353332"
    
    // Yandex map geocode url
    
    static let yandexMapGeocodeUrl = "https://enterprise.geocode-maps.yandex.ru/1.x/"
    
    // Yandex map default camera position
    
    static let latitude = 55.75222
    static let longitude = 37.61556
    static let zoom: Float = 9.5
    
    // MARK: - Videogorod manual
    
    static let manualUrl = DefaultServerAddresses.main + "/files/videogorod-manual-ios.pdf"
    static let testportalManualUrl = "https://testportal-echd.mos.ru/files/videogorod-manual-ios.pdf"
    static let manualName = "Videogorod_manual_iOS.pdf"
    static let helpInformationUrl = "https://echd-cloud.mos.ru/index.php/s/lttALf2bI0jadQm"
    static let sudirAuthorizationUrl = "https://sudir.mos.ru"
    static let sudirAuthorizationUrlWithoutScheme = "sudir.mos.ru"
}
