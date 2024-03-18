import Foundation
import Postbox
import TelegramApi

public enum CachedPeerAutoremoveTimeout: Equatable, PostboxCoding {
    public struct Value: Equatable, PostboxCoding {
        public var peerValue: Int32
        
        public init(peerValue: Int32) {
            self.peerValue = peerValue
        }
        
        public init(decoder: PostboxDecoder) {
            self.peerValue = decoder.decodeInt32ForKey("peerValue", orElse: 0)
        }
        
        public func encode(_ encoder: PostboxEncoder) {
            encoder.encodeInt32(self.peerValue, forKey: "peerValue")
        }
        
        public var effectiveValue: Int32 {
            return self.peerValue
        }
    }
    
    case unknown
    case known(Value?)
    
    public init(decoder: PostboxDecoder) {
        switch decoder.decodeInt32ForKey("_v", orElse: 0) {
        case 1:
            self = .known(decoder.decodeObjectForKey("v", decoder: Value.init(decoder:)) as? Value)
        default:
            self = .unknown
        }
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        switch self {
        case .unknown:
            encoder.encodeInt32(0, forKey: "_v")
        case let .known(value):
            encoder.encodeInt32(1, forKey: "_v")
            if let value = value {
                encoder.encodeObject(value, forKey: "v")
            } else {
                encoder.encodeNil(forKey: "v")
            }
        }
    }
}

public enum CachedPeerProfilePhoto: Equatable, PostboxCoding {
    case unknown
    case known(TelegramMediaImage?)
    
    public init(decoder: PostboxDecoder) {
        switch decoder.decodeInt32ForKey("_v", orElse: 0) {
        case 1:
            self = .known(decoder.decodeObjectForKey("v", decoder: { TelegramMediaImage(decoder: $0) }) as? TelegramMediaImage)
        default:
            self = .unknown
        }
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        switch self {
        case .unknown:
            encoder.encodeInt32(0, forKey: "_v")
        case let .known(value):
            encoder.encodeInt32(1, forKey: "_v")
            if let value = value {
                encoder.encodeObject(value, forKey: "v")
            } else {
                encoder.encodeNil(forKey: "v")
            }
        }
    }
}

public enum CachedTelegramBusinessIntro: Equatable, PostboxCoding {
    case unknown
    case known(TelegramBusinessIntro?)
    
    public init(decoder: PostboxDecoder) {
        switch decoder.decodeInt32ForKey("_v", orElse: 0) {
        case 1:
            self = .known(decoder.decodeCodable(TelegramBusinessIntro.self, forKey: "v"))
        default:
            self = .unknown
        }
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        switch self {
        case .unknown:
            encoder.encodeInt32(0, forKey: "_v")
        case let .known(value):
            encoder.encodeInt32(1, forKey: "_v")
            if let value {
                encoder.encodeCodable(value, forKey: "v")
            } else {
                encoder.encodeNil(forKey: "v")
            }
        }
    }
}

public struct CachedPremiumGiftOption: Equatable, PostboxCoding {
    public let months: Int32
    public let currency: String
    public let amount: Int64
    public let botUrl: String
    public let storeProductId: String?
    
    public init(months: Int32, currency: String, amount: Int64, botUrl: String, storeProductId: String?) {
        self.months = months
        self.currency = currency
        self.amount = amount
        self.botUrl = botUrl
        self.storeProductId = storeProductId
    }
    
    public init(decoder: PostboxDecoder) {
        self.months = decoder.decodeInt32ForKey("months", orElse: 0)
        self.currency = decoder.decodeStringForKey("currency", orElse: "")
        self.amount = decoder.decodeInt64ForKey("amount", orElse: 0)
        self.botUrl = decoder.decodeStringForKey("botUrl", orElse: "")
        self.storeProductId = decoder.decodeOptionalStringForKey("storeProductId")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.months, forKey: "months")
        encoder.encodeString(self.currency, forKey: "currency")
        encoder.encodeInt64(self.amount, forKey: "amount")
        encoder.encodeString(self.botUrl, forKey: "botUrl")
        if let storeProductId = self.storeProductId {
            encoder.encodeString(storeProductId, forKey: "storeProductId")
        } else {
            encoder.encodeNil(forKey: "storeProductId")
        }
    }
}

public enum PeerNameColor: Hashable {
    case red
    case orange
    case violet
    case green
    case cyan
    case blue
    case pink
    case other(Int32)
    
    public init(rawValue: Int32) {
        switch rawValue {
        case 0:
            self = .red
        case 1:
            self = .orange
        case 2:
            self = .violet
        case 3:
            self = .green
        case 4:
            self = .cyan
        case 5:
            self = .blue
        case 6:
            self = .pink
        default:
            self = .other(rawValue)
        }
    }
    
    public var rawValue: Int32 {
        switch self {
        case .red:
            return 0
        case .orange:
            return 1
        case .violet:
            return 2
        case .green:
            return 3
        case .cyan:
            return 4
        case .blue:
            return 5
        case .pink:
            return 6
        case let .other(value):
            return value
        }
    }
}

public struct PeerEmojiStatus: Equatable, Codable {
    public var fileId: Int64
    public var expirationDate: Int32?
    
    public init(fileId: Int64, expirationDate: Int32?) {
        self.fileId = fileId
        self.expirationDate = expirationDate
    }
}

extension PeerEmojiStatus {
    init?(apiStatus: Api.EmojiStatus) {
        switch apiStatus {
        case let .emojiStatus(documentId):
            self.init(fileId: documentId, expirationDate: nil)
        case let .emojiStatusUntil(documentId, until):
            self.init(fileId: documentId, expirationDate: until)
        case .emojiStatusEmpty:
            return nil
        }
    }
}

public struct CachedUserFlags: OptionSet {
    public var rawValue: Int32
    
    public init() {
        self.rawValue = 0
    }
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let translationHidden = CachedUserFlags(rawValue: 1 << 0)
    public static let isBlockedFromStories = CachedUserFlags(rawValue: 1 << 1)
    public static let readDatesPrivate = CachedUserFlags(rawValue: 1 << 2)
    public static let premiumRequired = CachedUserFlags(rawValue: 1 << 3)
}

public final class EditableBotInfo: PostboxCoding, Equatable {
    public let name: String
    public let about: String
    public let description: String
    
    public init(name: String, about: String, description: String) {
        self.name = name
        self.about = about
        self.description = description
    }
    
    public init(decoder: PostboxDecoder) {
        self.name = decoder.decodeStringForKey("n", orElse: "")
        self.about = decoder.decodeStringForKey("a", orElse: "")
        self.description = decoder.decodeStringForKey("d", orElse: "")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeString(self.name, forKey: "n")
        encoder.encodeString(self.about, forKey: "a")
        encoder.encodeString(self.description, forKey: "d")
    }
    
    public static func ==(lhs: EditableBotInfo, rhs: EditableBotInfo) -> Bool {
        return lhs.name == rhs.name && lhs.about == rhs.about && lhs.description == rhs.description
    }
    
    public func withUpdatedName(_ name: String) -> EditableBotInfo {
        return EditableBotInfo(name: name, about: self.about, description: self.description)
    }
    
    public func withUpdatedAbout(_ about: String) -> EditableBotInfo {
        return EditableBotInfo(name: self.name, about: about, description: self.description)
    }
    
    public func withUpdatedDescription(_ description: String) -> EditableBotInfo {
        return EditableBotInfo(name: self.name, about: self.about, description: description)
    }
}

public final class TelegramBusinessHours: Equatable, Codable {
    public struct WorkingTimeInterval: Equatable, Codable {
        private enum CodingKeys: String, CodingKey {
            case startMinute
            case endMinute
        }
        
        public let startMinute: Int
        public let endMinute: Int
        
        public init(startMinute: Int, endMinute: Int) {
            self.startMinute = startMinute
            self.endMinute = endMinute
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.startMinute = Int(try container.decode(Int32.self, forKey: .startMinute))
            self.endMinute = Int(try container.decode(Int32.self, forKey: .endMinute))
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(Int32(clamping: self.startMinute), forKey: .startMinute)
            try container.encode(Int32(clamping: self.endMinute), forKey: .endMinute)
        }
        
        public static func ==(lhs: WorkingTimeInterval, rhs: WorkingTimeInterval) -> Bool {
            if lhs.startMinute != rhs.startMinute {
                return false
            }
            if lhs.endMinute != rhs.endMinute {
                return false
            }
            return true
        }
    }
    
    public let timezoneId: String
    public let weeklyTimeIntervals: [WorkingTimeInterval]
    
    public init(timezoneId: String, weeklyTimeIntervals: [WorkingTimeInterval]) {
        self.timezoneId = timezoneId
        self.weeklyTimeIntervals = weeklyTimeIntervals
    }
    
    public static func ==(lhs: TelegramBusinessHours, rhs: TelegramBusinessHours) -> Bool {
        if lhs.timezoneId != rhs.timezoneId {
            return false
        }
        if lhs.weeklyTimeIntervals != rhs.weeklyTimeIntervals {
            return false
        }
        return true
    }
    
    public enum WeekDay {
        case closed
        case open
        case intervals([WorkingTimeInterval])
    }
    
    public func splitIntoWeekDays() -> [WeekDay] {
        var mappedDays: [[WorkingTimeInterval]] = Array(repeating: [], count: 7)
        
        var weekMinutes = IndexSet()
        for interval in self.weeklyTimeIntervals {
            weekMinutes.insert(integersIn: interval.startMinute ..< interval.endMinute)
        }
        
        for i in 0 ..< mappedDays.count {
            let dayRange = i * 24 * 60 ..< (i + 1) * 24 * 60
            var removeMinutes = IndexSet()
            inner: for range in weekMinutes.rangeView {
                if range.lowerBound >= dayRange.upperBound {
                    break inner
                } else {
                    let clippedRange: Range<Int>
                    if range.lowerBound == dayRange.lowerBound {
                        clippedRange = range.lowerBound ..< min(range.upperBound, dayRange.upperBound)
                    } else {
                        clippedRange = range.lowerBound ..< min(range.upperBound, dayRange.upperBound + 12 * 60)
                    }
                    
                    let startTimeInsideDay = clippedRange.lowerBound - i * (24 * 60)
                    let endTimeInsideDay = clippedRange.upperBound - i * (24 * 60)
                    
                    mappedDays[i].append(WorkingTimeInterval(
                        startMinute: startTimeInsideDay,
                        endMinute: endTimeInsideDay
                    ))
                    removeMinutes.insert(integersIn: clippedRange)
                }
            }
            
            weekMinutes.subtract(removeMinutes)
        }
        
        return mappedDays.map { day -> WeekDay in
            var minutes = IndexSet()
            for interval in day {
                minutes.insert(integersIn: interval.startMinute ..< interval.endMinute)
            }
            if minutes.isEmpty {
                return .closed
            } else if minutes == IndexSet(integersIn: 0 ..< 24 * 60) || minutes == IndexSet(integersIn: 0 ..< (24 * 60 - 1)) {
                return .open
            } else {
                return .intervals(day)
            }
        }
    }
    
    public func weekMinuteSet() -> IndexSet {
        var result = IndexSet()
        
        for interval in self.weeklyTimeIntervals {
            result.insert(integersIn: interval.startMinute ..< interval.endMinute)
        }
        
        return result
    }
}

public final class TelegramBusinessLocation: Equatable, Codable {
    public struct Coordinates: Equatable, Codable {
        public let latitude: Double
        public let longitude: Double
        
        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
    
    public let address: String
    public let coordinates: Coordinates?
    
    public init(address: String, coordinates: Coordinates?) {
        self.address = address
        self.coordinates = coordinates
    }
    
    public static func ==(lhs: TelegramBusinessLocation, rhs: TelegramBusinessLocation) -> Bool {
        if lhs.address != rhs.address {
            return false
        }
        if lhs.coordinates != rhs.coordinates {
            return false
        }
        return true
    }
}

extension TelegramBusinessHours.WorkingTimeInterval {
    init(apiInterval: Api.BusinessWeeklyOpen) {
        switch apiInterval {
        case let .businessWeeklyOpen(startMinute, endMinute):
            self.init(startMinute: Int(startMinute), endMinute: Int(endMinute))
        }
    }
    
    var apiInterval: Api.BusinessWeeklyOpen {
        return .businessWeeklyOpen(startMinute: Int32(clamping: self.startMinute), endMinute: Int32(clamping: self.endMinute))
    }
}

extension TelegramBusinessHours {
    convenience init(apiWorkingHours: Api.BusinessWorkHours) {
        switch apiWorkingHours {
        case let .businessWorkHours(_, timezoneId, weeklyOpen):
            self.init(timezoneId: timezoneId, weeklyTimeIntervals: weeklyOpen.map(TelegramBusinessHours.WorkingTimeInterval.init(apiInterval:)))
        }
    }
    
    var apiBusinessHours: Api.BusinessWorkHours {
        return .businessWorkHours(flags: 0, timezoneId: self.timezoneId, weeklyOpen: self.weeklyTimeIntervals.map(\.apiInterval))
    }
}

extension TelegramBusinessLocation.Coordinates {
    init?(apiGeoPoint: Api.GeoPoint) {
        switch apiGeoPoint {
        case let .geoPoint(_, long, lat, _, _):
            self.init(latitude: lat, longitude: long)
        case .geoPointEmpty:
            return nil
        }
    }
    
    var apiInputGeoPoint: Api.InputGeoPoint {
        return .inputGeoPoint(flags: 0, lat: self.latitude, long: self.longitude, accuracyRadius: nil)
    }
}

extension TelegramBusinessLocation {
    convenience init(apiLocation: Api.BusinessLocation) {
        switch apiLocation {
        case let .businessLocation(_, geoPoint, address):
            self.init(address: address, coordinates: geoPoint.flatMap { Coordinates(apiGeoPoint: $0) })
        }
    }
}

public final class CachedUserData: CachedPeerData {
    public let about: String?
    public let botInfo: BotInfo?
    public let editableBotInfo: EditableBotInfo?
    public let peerStatusSettings: PeerStatusSettings?
    public let pinnedMessageId: MessageId?
    public let isBlocked: Bool
    public let commonGroupCount: Int32
    public let voiceCallsAvailable: Bool
    public let videoCallsAvailable: Bool
    public let callsPrivate: Bool
    public let canPinMessages: Bool
    public let hasScheduledMessages: Bool
    public let autoremoveTimeout: CachedPeerAutoremoveTimeout
    public let themeEmoticon: String?
    public let photo: CachedPeerProfilePhoto
    public let personalPhoto: CachedPeerProfilePhoto
    public let fallbackPhoto: CachedPeerProfilePhoto
    public let premiumGiftOptions: [CachedPremiumGiftOption]
    public let voiceMessagesAvailable: Bool
    public let wallpaper: TelegramWallpaper?
    public let flags: CachedUserFlags
    public let businessHours: TelegramBusinessHours?
    public let businessLocation: TelegramBusinessLocation?
    public let greetingMessage: TelegramBusinessGreetingMessage?
    public let awayMessage: TelegramBusinessAwayMessage?
    public let connectedBot: TelegramAccountConnectedBot?
    public let businessIntro: CachedTelegramBusinessIntro
    
    public let peerIds: Set<PeerId>
    public let messageIds: Set<MessageId>
    public let associatedHistoryMessageId: MessageId? = nil
    
    public init() {
        self.about = nil
        self.botInfo = nil
        self.editableBotInfo = nil
        self.peerStatusSettings = nil
        self.pinnedMessageId = nil
        self.isBlocked = false
        self.commonGroupCount = 0
        self.voiceCallsAvailable = true
        self.videoCallsAvailable = true
        self.callsPrivate = false
        self.canPinMessages = false
        self.hasScheduledMessages = false
        self.autoremoveTimeout = .unknown
        self.themeEmoticon = nil
        self.photo = .unknown
        self.personalPhoto = .unknown
        self.fallbackPhoto = .unknown
        self.premiumGiftOptions = []
        self.voiceMessagesAvailable = true
        self.wallpaper = nil
        self.flags = CachedUserFlags()
        self.businessHours = nil
        self.businessLocation = nil
        self.peerIds = Set()
        self.messageIds = Set()
        self.greetingMessage = nil
        self.awayMessage = nil
        self.connectedBot = nil
        self.businessIntro = .unknown
    }
    
    public init(about: String?, botInfo: BotInfo?, editableBotInfo: EditableBotInfo?, peerStatusSettings: PeerStatusSettings?, pinnedMessageId: MessageId?, isBlocked: Bool, commonGroupCount: Int32, voiceCallsAvailable: Bool, videoCallsAvailable: Bool, callsPrivate: Bool, canPinMessages: Bool, hasScheduledMessages: Bool, autoremoveTimeout: CachedPeerAutoremoveTimeout, themeEmoticon: String?, photo: CachedPeerProfilePhoto, personalPhoto: CachedPeerProfilePhoto, fallbackPhoto: CachedPeerProfilePhoto, premiumGiftOptions: [CachedPremiumGiftOption], voiceMessagesAvailable: Bool, wallpaper: TelegramWallpaper?, flags: CachedUserFlags, businessHours: TelegramBusinessHours?, businessLocation: TelegramBusinessLocation?, greetingMessage: TelegramBusinessGreetingMessage?, awayMessage: TelegramBusinessAwayMessage?, connectedBot: TelegramAccountConnectedBot?, businessIntro: CachedTelegramBusinessIntro) {
        self.about = about
        self.botInfo = botInfo
        self.editableBotInfo = editableBotInfo
        self.peerStatusSettings = peerStatusSettings
        self.pinnedMessageId = pinnedMessageId
        self.isBlocked = isBlocked
        self.commonGroupCount = commonGroupCount
        self.voiceCallsAvailable = voiceCallsAvailable
        self.videoCallsAvailable = videoCallsAvailable
        self.callsPrivate = callsPrivate
        self.canPinMessages = canPinMessages
        self.hasScheduledMessages = hasScheduledMessages
        self.autoremoveTimeout = autoremoveTimeout
        self.themeEmoticon = themeEmoticon
        self.photo = photo
        self.personalPhoto = personalPhoto
        self.fallbackPhoto = fallbackPhoto
        self.premiumGiftOptions = premiumGiftOptions
        self.voiceMessagesAvailable = voiceMessagesAvailable
        self.wallpaper = wallpaper
        self.flags = flags
        self.businessHours = businessHours
        self.businessLocation = businessLocation
        self.greetingMessage = greetingMessage
        self.awayMessage = awayMessage
        self.connectedBot = connectedBot
        self.businessIntro = businessIntro
        
        self.peerIds = Set<PeerId>()
        
        var messageIds = Set<MessageId>()
        if let pinnedMessageId = self.pinnedMessageId {
            messageIds.insert(pinnedMessageId)
        }
        self.messageIds = messageIds
    }
    
    public init(decoder: PostboxDecoder) {
        self.about = decoder.decodeOptionalStringForKey("a")
        self.botInfo = decoder.decodeObjectForKey("bi") as? BotInfo
        self.editableBotInfo = decoder.decodeObjectForKey("ebi") as? EditableBotInfo
        if let legacyValue = decoder.decodeOptionalInt32ForKey("pcs") {
            self.peerStatusSettings = PeerStatusSettings(flags: PeerStatusSettings.Flags(rawValue: legacyValue), geoDistance: nil, managingBot: nil)
        } else if let peerStatusSettings = decoder.decodeObjectForKey("pss", decoder: { PeerStatusSettings(decoder: $0) }) as? PeerStatusSettings {
            self.peerStatusSettings = peerStatusSettings
        } else {
            self.peerStatusSettings = nil
        }
        if let pinnedMessagePeerId = decoder.decodeOptionalInt64ForKey("pm.p"), let pinnedMessageNamespace = decoder.decodeOptionalInt32ForKey("pm.n"), let pinnedMessageId = decoder.decodeOptionalInt32ForKey("pm.i") {
            self.pinnedMessageId = MessageId(peerId: PeerId(pinnedMessagePeerId), namespace: pinnedMessageNamespace, id: pinnedMessageId)
        } else {
            self.pinnedMessageId = nil
        }
        self.isBlocked = decoder.decodeInt32ForKey("b", orElse: 0) != 0
        self.commonGroupCount = decoder.decodeInt32ForKey("cg", orElse: 0)
        self.voiceCallsAvailable = decoder.decodeInt32ForKey("ca", orElse: 0) != 0
        self.videoCallsAvailable = decoder.decodeInt32ForKey("vca", orElse: 0) != 0
        self.callsPrivate = decoder.decodeInt32ForKey("cp", orElse: 0) != 0
        self.canPinMessages = decoder.decodeInt32ForKey("cpm", orElse: 0) != 0
        self.hasScheduledMessages = decoder.decodeBoolForKey("hsm", orElse: false)
        self.autoremoveTimeout = decoder.decodeObjectForKey("artv", decoder: CachedPeerAutoremoveTimeout.init(decoder:)) as? CachedPeerAutoremoveTimeout ?? .unknown
        self.themeEmoticon = decoder.decodeOptionalStringForKey("te")
        
        self.photo = decoder.decodeObjectForKey("phv", decoder: CachedPeerProfilePhoto.init(decoder:)) as? CachedPeerProfilePhoto ?? .unknown
        self.personalPhoto = decoder.decodeObjectForKey("pphv", decoder: CachedPeerProfilePhoto.init(decoder:)) as? CachedPeerProfilePhoto ?? .unknown
        self.fallbackPhoto = decoder.decodeObjectForKey("fphv", decoder: CachedPeerProfilePhoto.init(decoder:)) as? CachedPeerProfilePhoto ?? .unknown
        
        self.premiumGiftOptions = decoder.decodeObjectArrayWithDecoderForKey("pgo") as [CachedPremiumGiftOption]
        self.voiceMessagesAvailable = decoder.decodeInt32ForKey("vma", orElse: 0) != 0
        self.wallpaper = decoder.decode(TelegramWallpaperNativeCodable.self, forKey: "wp")?.value
        self.flags = CachedUserFlags(rawValue: decoder.decodeInt32ForKey("fl", orElse: 0))
        
        self.peerIds = Set<PeerId>()
        
        var messageIds = Set<MessageId>()
        if let pinnedMessageId = self.pinnedMessageId {
            messageIds.insert(pinnedMessageId)
        }
        self.messageIds = messageIds
        
        self.businessHours = decoder.decodeCodable(TelegramBusinessHours.self, forKey: "bhrs")
        self.businessLocation = decoder.decodeCodable(TelegramBusinessLocation.self, forKey: "bloc")
        
        self.greetingMessage = decoder.decodeCodable(TelegramBusinessGreetingMessage.self, forKey: "bgreet")
        self.awayMessage = decoder.decodeCodable(TelegramBusinessAwayMessage.self, forKey: "baway")
        self.connectedBot = decoder.decodeCodable(TelegramAccountConnectedBot.self, forKey: "bbot")
        self.businessIntro = decoder.decodeObjectForKey("businessIntro", decoder: CachedTelegramBusinessIntro.init(decoder:)) as? CachedTelegramBusinessIntro ?? .unknown
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        if let about = self.about {
            encoder.encodeString(about, forKey: "a")
        } else {
            encoder.encodeNil(forKey: "a")
        }
        if let botInfo = self.botInfo {
            encoder.encodeObject(botInfo, forKey: "bi")
        } else {
            encoder.encodeNil(forKey: "bi")
        }
        if let editableBotInfo = self.editableBotInfo {
            encoder.encodeObject(editableBotInfo, forKey: "ebi")
        } else {
            encoder.encodeNil(forKey: "ebi")
        }
        if let peerStatusSettings = self.peerStatusSettings {
            encoder.encodeObject(peerStatusSettings, forKey: "pss")
        } else {
            encoder.encodeNil(forKey: "pss")
        }
        if let pinnedMessageId = self.pinnedMessageId {
            encoder.encodeInt64(pinnedMessageId.peerId.toInt64(), forKey: "pm.p")
            encoder.encodeInt32(pinnedMessageId.namespace, forKey: "pm.n")
            encoder.encodeInt32(pinnedMessageId.id, forKey: "pm.i")
        } else {
            encoder.encodeNil(forKey: "pm.p")
            encoder.encodeNil(forKey: "pm.n")
            encoder.encodeNil(forKey: "pm.i")
        }
        encoder.encodeInt32(self.isBlocked ? 1 : 0, forKey: "b")
        encoder.encodeInt32(self.commonGroupCount, forKey: "cg")
        encoder.encodeInt32(self.voiceCallsAvailable ? 1 : 0, forKey: "ca")
        encoder.encodeInt32(self.videoCallsAvailable ? 1 : 0, forKey: "vca")
        encoder.encodeInt32(self.callsPrivate ? 1 : 0, forKey: "cp")
        encoder.encodeInt32(self.canPinMessages ? 1 : 0, forKey: "cpm")
        encoder.encodeBool(self.hasScheduledMessages, forKey: "hsm")
        encoder.encodeObject(self.autoremoveTimeout, forKey: "artv")
        if let themeEmoticon = self.themeEmoticon, !themeEmoticon.isEmpty {
            encoder.encodeString(themeEmoticon, forKey: "te")
        } else {
            encoder.encodeNil(forKey: "te")
        }
        
        encoder.encodeObject(self.photo, forKey: "phv")
        encoder.encodeObject(self.personalPhoto, forKey: "pphv")
        encoder.encodeObject(self.fallbackPhoto, forKey: "fphv")

        encoder.encodeObjectArray(self.premiumGiftOptions, forKey: "pgo")
        encoder.encodeInt32(self.voiceMessagesAvailable ? 1 : 0, forKey: "vma")
        
        if let wallpaper = self.wallpaper {
            encoder.encode(TelegramWallpaperNativeCodable(wallpaper), forKey: "wp")
        } else {
            encoder.encodeNil(forKey: "wp")
        }
        
        encoder.encodeInt32(self.flags.rawValue, forKey: "fl")
        
        if let businessHours = self.businessHours {
            encoder.encodeCodable(businessHours, forKey: "bhrs")
        } else {
            encoder.encodeNil(forKey: "bhrs")
        }
        
        if let businessLocation = self.businessLocation {
            encoder.encodeCodable(businessLocation, forKey: "bloc")
        } else {
            encoder.encodeNil(forKey: "bloc")
        }
        
        if let greetingMessage = self.greetingMessage {
            encoder.encodeCodable(greetingMessage, forKey: "bgreet")
        } else {
            encoder.encodeNil(forKey: "bgreet")
        }
        
        if let awayMessage = self.awayMessage {
            encoder.encodeCodable(awayMessage, forKey: "baway")
        } else {
            encoder.encodeNil(forKey: "baway")
        }
        
        if let connectedBot = self.connectedBot {
            encoder.encodeCodable(connectedBot, forKey: "bbot")
        } else {
            encoder.encodeNil(forKey: "bbot")
        }
        
        encoder.encodeObject(self.businessIntro, forKey: "businessIntro")
    }
    
    public func isEqual(to: CachedPeerData) -> Bool {
        guard let other = to as? CachedUserData else {
            return false
        }
        
        if other.pinnedMessageId != self.pinnedMessageId {
            return false
        }
        if other.canPinMessages != self.canPinMessages {
            return false
        }
        if other.businessHours != self.businessHours {
            return false
        }
        if other.businessLocation != self.businessLocation {
            return false
        }
        if other.greetingMessage != self.greetingMessage {
            return false
        }
        if other.awayMessage != self.awayMessage {
            return false
        }
        if other.connectedBot != self.connectedBot {
            return false
        }
        if other.businessIntro != self.businessIntro {
            return false
        }
        
        return other.about == self.about && other.botInfo == self.botInfo && other.editableBotInfo == self.editableBotInfo && self.peerStatusSettings == other.peerStatusSettings && self.isBlocked == other.isBlocked && self.commonGroupCount == other.commonGroupCount && self.voiceCallsAvailable == other.voiceCallsAvailable && self.videoCallsAvailable == other.videoCallsAvailable && self.callsPrivate == other.callsPrivate && self.hasScheduledMessages == other.hasScheduledMessages && self.autoremoveTimeout == other.autoremoveTimeout && self.themeEmoticon == other.themeEmoticon && self.photo == other.photo && self.personalPhoto == other.personalPhoto && self.fallbackPhoto == other.fallbackPhoto && self.premiumGiftOptions == other.premiumGiftOptions && self.voiceMessagesAvailable == other.voiceMessagesAvailable && self.flags == other.flags && self.wallpaper == other.wallpaper
    }
    
    public func withUpdatedAbout(_ about: String?) -> CachedUserData {
        return CachedUserData(about: about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedBotInfo(_ botInfo: BotInfo?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedEditableBotInfo(_ editableBotInfo: EditableBotInfo?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedPeerStatusSettings(_ peerStatusSettings: PeerStatusSettings) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedPinnedMessageId(_ pinnedMessageId: MessageId?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedIsBlocked(_ isBlocked: Bool) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedCommonGroupCount(_ commonGroupCount: Int32) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedVoiceCallsAvailable(_ voiceCallsAvailable: Bool) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedVideoCallsAvailable(_ videoCallsAvailable: Bool) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedCallsPrivate(_ callsPrivate: Bool) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedCanPinMessages(_ canPinMessages: Bool) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedHasScheduledMessages(_ hasScheduledMessages: Bool) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedAutoremoveTimeout(_ autoremoveTimeout: CachedPeerAutoremoveTimeout) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedThemeEmoticon(_ themeEmoticon: String?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedPhoto(_ photo: CachedPeerProfilePhoto) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedPersonalPhoto(_ personalPhoto: CachedPeerProfilePhoto) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedFallbackPhoto(_ fallbackPhoto: CachedPeerProfilePhoto) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedPremiumGiftOptions(_ premiumGiftOptions: [CachedPremiumGiftOption]) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedVoiceMessagesAvailable(_ voiceMessagesAvailable: Bool) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedWallpaper(_ wallpaper: TelegramWallpaper?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedFlags(_ flags: CachedUserFlags) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedBusinessHours(_ businessHours: TelegramBusinessHours?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedBusinessLocation(_ businessLocation: TelegramBusinessLocation?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedGreetingMessage(_ greetingMessage: TelegramBusinessGreetingMessage?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedAwayMessage(_ awayMessage: TelegramBusinessAwayMessage?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: awayMessage, connectedBot: self.connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedConnectedBot(_ connectedBot: TelegramAccountConnectedBot?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: connectedBot, businessIntro: self.businessIntro)
    }
    
    public func withUpdatedBusinessIntro(_ businessIntro: TelegramBusinessIntro?) -> CachedUserData {
        return CachedUserData(about: self.about, botInfo: self.botInfo, editableBotInfo: self.editableBotInfo, peerStatusSettings: self.peerStatusSettings, pinnedMessageId: self.pinnedMessageId, isBlocked: self.isBlocked, commonGroupCount: self.commonGroupCount, voiceCallsAvailable: self.voiceCallsAvailable, videoCallsAvailable: self.videoCallsAvailable, callsPrivate: self.callsPrivate, canPinMessages: self.canPinMessages, hasScheduledMessages: self.hasScheduledMessages, autoremoveTimeout: self.autoremoveTimeout, themeEmoticon: self.themeEmoticon, photo: self.photo, personalPhoto: self.personalPhoto, fallbackPhoto: self.fallbackPhoto, premiumGiftOptions: self.premiumGiftOptions, voiceMessagesAvailable: self.voiceMessagesAvailable, wallpaper: self.wallpaper, flags: self.flags, businessHours: self.businessHours, businessLocation: self.businessLocation, greetingMessage: self.greetingMessage, awayMessage: self.awayMessage, connectedBot: self.connectedBot, businessIntro: .known(businessIntro))
    }
}
