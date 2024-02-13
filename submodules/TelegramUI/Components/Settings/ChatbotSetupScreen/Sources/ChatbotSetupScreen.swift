import Foundation
import UIKit
import Photos
import Display
import AsyncDisplayKit
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import PresentationDataUtils
import AccountContext
import ComponentFlow
import ViewControllerComponent
import MultilineTextComponent
import BalancedTextComponent
import BackButtonComponent
import ListSectionComponent
import ListActionItemComponent
import ListTextFieldItemComponent
import BundleIconComponent
import LottieComponent
import Markdown
import PeerListItemComponent
import AvatarNode

private let checkIcon: UIImage = {
    return generateImage(CGSize(width: 12.0, height: 10.0), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1.98)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.translateBy(x: 1.0, y: 1.0)
        
        let _ = try? drawSvgPath(context, path: "M0.215053763,4.36080467 L3.31621263,7.70466293 L3.31621263,7.70466293 C3.35339229,7.74475231 3.41603123,7.74711109 3.45612061,7.70993143 C3.45920681,7.70706923 3.46210733,7.70401312 3.46480451,7.70078171 L9.89247312,0 S ")
    })!.withRenderingMode(.alwaysTemplate)
}()

final class ChatbotSetupScreenComponent: Component {
    typealias EnvironmentType = ViewControllerComponentContainer.Environment
    
    let context: AccountContext

    init(
        context: AccountContext
    ) {
        self.context = context
    }

    static func ==(lhs: ChatbotSetupScreenComponent, rhs: ChatbotSetupScreenComponent) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }

        return true
    }
    
    private final class ScrollView: UIScrollView {
        override func touchesShouldCancel(in view: UIView) -> Bool {
            return true
        }
    }
    
    private struct BotResolutionState: Equatable {
        enum State: Equatable {
            case searching
            case notFound
            case found(peer: EnginePeer, isInstalled: Bool)
        }
        
        var query: String
        var state: State
        
        init(query: String, state: State) {
            self.query = query
            self.state = state
        }
    }
    
    private struct AdditionalPeerList {
        enum Category: Int {
            case newChats = 0
            case existingChats = 1
            case contacts = 2
            case nonContacts = 3
        }
        
        struct Peer {
            var peer: EnginePeer
            var isContact: Bool
            
            init(peer: EnginePeer, isContact: Bool) {
                self.peer = peer
                self.isContact = isContact
            }
        }
        
        var categories: Set<Category>
        var peers: [Peer]
        
        init(categories: Set<Category>, peers: [Peer]) {
            self.categories = categories
            self.peers = peers
        }
    }
    
    final class View: UIView, UIScrollViewDelegate {
        private let topOverscrollLayer = SimpleLayer()
        private let scrollView: ScrollView
        
        private let navigationTitle = ComponentView<Empty>()
        private let icon = ComponentView<Empty>()
        private let subtitle = ComponentView<Empty>()
        private let nameSection = ComponentView<Empty>()
        private let accessSection = ComponentView<Empty>()
        private let excludedSection = ComponentView<Empty>()
        private let permissionsSection = ComponentView<Empty>()
        
        private var isUpdating: Bool = false
        
        private var component: ChatbotSetupScreenComponent?
        private(set) weak var state: EmptyComponentState?
        private var environment: EnvironmentType?
        
        private var chevronImage: UIImage?
        private let textFieldTag = NSObject()
        
        private var botResolutionState: BotResolutionState?
        private var botResolutionDisposable: Disposable?
        
        private var hasAccessToAllChatsByDefault: Bool = true
        private var additionalPeerList = AdditionalPeerList(
            categories: Set(),
            peers: []
        )
        
        private var replyToMessages: Bool = true
        
        override init(frame: CGRect) {
            self.scrollView = ScrollView()
            self.scrollView.showsVerticalScrollIndicator = true
            self.scrollView.showsHorizontalScrollIndicator = false
            self.scrollView.scrollsToTop = false
            self.scrollView.delaysContentTouches = false
            self.scrollView.canCancelContentTouches = true
            self.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                self.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
            self.scrollView.alwaysBounceVertical = true
            
            super.init(frame: frame)
            
            self.scrollView.delegate = self
            self.addSubview(self.scrollView)
            
            self.scrollView.layer.addSublayer(self.topOverscrollLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
        }

        func scrollToTop() {
            self.scrollView.setContentOffset(CGPoint(), animated: true)
        }
        
        func attemptNavigation(complete: @escaping () -> Void) -> Bool {
            return true
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.updateScrolling(transition: .immediate)
        }
        
        var scrolledUp = true
        private func updateScrolling(transition: Transition) {
            let navigationRevealOffsetY: CGFloat = 0.0
            
            let navigationAlphaDistance: CGFloat = 16.0
            let navigationAlpha: CGFloat = max(0.0, min(1.0, (self.scrollView.contentOffset.y - navigationRevealOffsetY) / navigationAlphaDistance))
            if let controller = self.environment?.controller(), let navigationBar = controller.navigationBar {
                transition.setAlpha(layer: navigationBar.backgroundNode.layer, alpha: navigationAlpha)
                transition.setAlpha(layer: navigationBar.stripeNode.layer, alpha: navigationAlpha)
            }
            
            var scrolledUp = false
            if navigationAlpha < 0.5 {
                scrolledUp = true
            } else if navigationAlpha > 0.5 {
                scrolledUp = false
            }
            
            if self.scrolledUp != scrolledUp {
                self.scrolledUp = scrolledUp
                if !self.isUpdating {
                    self.state?.updated()
                }
            }
            
            if let navigationTitleView = self.navigationTitle.view {
                transition.setAlpha(view: navigationTitleView, alpha: 1.0)
            }
        }
        
        private func updateBotQuery(query: String) {
            guard let component = self.component else {
                return
            }
            
            if !query.isEmpty {
                if self.botResolutionState?.query != query {
                    let previousState = self.botResolutionState?.state
                    self.botResolutionState = BotResolutionState(
                        query: query,
                        state: self.botResolutionState?.state ?? .searching
                    )
                    self.botResolutionDisposable?.dispose()
                    
                    if previousState != self.botResolutionState?.state {
                        self.state?.updated(transition: .spring(duration: 0.35))
                    }
                    
                    self.botResolutionDisposable = (component.context.engine.peers.resolvePeerByName(name: query)
                    |> deliverOnMainQueue).start(next: { [weak self] result in
                        guard let self else {
                            return
                        }
                        switch result {
                        case .progress:
                            break
                        case let .result(peer):
                            let previousState = self.botResolutionState?.state
                            if let peer {
                                self.botResolutionState?.state = .found(peer: peer, isInstalled: false)
                            } else {
                                self.botResolutionState?.state = .notFound
                            }
                            if previousState != self.botResolutionState?.state {
                                self.state?.updated(transition: .spring(duration: 0.35))
                            }
                        }
                    })
                }
            } else {
                if let botResolutionDisposable = self.botResolutionDisposable {
                    self.botResolutionDisposable = nil
                    botResolutionDisposable.dispose()
                }
                if self.botResolutionState != nil {
                    self.botResolutionState = nil
                    self.state?.updated(transition: .spring(duration: 0.35))
                }
            }
        }
        
        private func openAdditionalPeerListSetup() {
            guard let component = self.component else {
                return
            }
            
            enum AdditionalCategoryId: Int {
                case existingChats
                case newChats
                case contacts
                case nonContacts
            }
            
            let additionalCategories: [ChatListNodeAdditionalCategory] = [
                ChatListNodeAdditionalCategory(
                    id: self.hasAccessToAllChatsByDefault ? AdditionalCategoryId.existingChats.rawValue : AdditionalCategoryId.newChats.rawValue,
                    icon: generateAvatarImage(size: CGSize(width: 40.0, height: 40.0), icon: generateTintedImage(image: UIImage(bundleImageName: "Chat List/Filters/Contact"), color: .white), cornerRadius: 12.0, color: .purple),
                    smallIcon: generateAvatarImage(size: CGSize(width: 22.0, height: 22.0), icon: generateTintedImage(image: UIImage(bundleImageName: "Chat List/Filters/Contact"), color: .white), iconScale: 0.6, cornerRadius: 6.0, circleCorners: true, color: .purple),
                    title: self.hasAccessToAllChatsByDefault ? "Existing Chats" : "New Chats"
                ),
                ChatListNodeAdditionalCategory(
                    id: AdditionalCategoryId.contacts.rawValue,
                    icon: generateAvatarImage(size: CGSize(width: 40.0, height: 40.0), icon: generateTintedImage(image: UIImage(bundleImageName: "Chat List/Filters/User"), color: .white), cornerRadius: 12.0, color: .blue),
                    smallIcon: generateAvatarImage(size: CGSize(width: 22.0, height: 22.0), icon: generateTintedImage(image: UIImage(bundleImageName: "Chat List/Filters/User"), color: .white), iconScale: 0.6, cornerRadius: 6.0, circleCorners: true, color: .blue),
                    title: "Contacts"
                ),
                ChatListNodeAdditionalCategory(
                    id: AdditionalCategoryId.nonContacts.rawValue,
                    icon: generateAvatarImage(size: CGSize(width: 40.0, height: 40.0), icon: generateTintedImage(image: UIImage(bundleImageName: "Chat List/Filters/User"), color: .white), cornerRadius: 12.0, color: .yellow),
                    smallIcon: generateAvatarImage(size: CGSize(width: 22.0, height: 22.0), icon: generateTintedImage(image: UIImage(bundleImageName: "Chat List/Filters/User"), color: .white), iconScale: 0.6, cornerRadius: 6.0, circleCorners: true, color: .yellow),
                    title: "Non-Contacts"
                )
            ]
            var selectedCategories = Set<Int>()
            for category in self.additionalPeerList.categories {
                switch category {
                case .existingChats:
                    selectedCategories.insert(AdditionalCategoryId.existingChats.rawValue)
                case .newChats:
                    selectedCategories.insert(AdditionalCategoryId.newChats.rawValue)
                case .contacts:
                    selectedCategories.insert(AdditionalCategoryId.contacts.rawValue)
                case .nonContacts:
                    selectedCategories.insert(AdditionalCategoryId.nonContacts.rawValue)
                }
            }
            
            //TODO:localize
            let controller = component.context.sharedContext.makeContactMultiselectionController(ContactMultiselectionControllerParams(context: component.context, mode: .chatSelection(ContactMultiselectionControllerMode.ChatSelection(
                title: self.hasAccessToAllChatsByDefault ? "Exclude Chats" : "Include Chats",
                searchPlaceholder: "Search chats",
                selectedChats: Set(self.additionalPeerList.peers.map(\.peer.id)),
                additionalCategories: ContactMultiselectionControllerAdditionalCategories(categories: additionalCategories, selectedCategories: selectedCategories),
                chatListFilters: nil,
                onlyUsers: true
            )), options: [], filters: [], alwaysEnabled: true, limit: 100, reachedLimit: { _ in
            }))
            controller.navigationPresentation = .modal
            
            let _ = (controller.result
            |> take(1)
            |> deliverOnMainQueue).startStandalone(next: { [weak self, weak controller] result in
                guard let self, let component = self.component, case let .result(rawPeerIds, additionalCategoryIds) = result else {
                    controller?.dismiss()
                    return
                }
                
                let peerIds = rawPeerIds.compactMap { id -> EnginePeer.Id? in
                    switch id {
                    case let .peer(id):
                        return id
                    case .deviceContact:
                        return nil
                    }
                }
                
                let _ = (component.context.engine.data.get(
                    EngineDataMap(
                        peerIds.map(TelegramEngine.EngineData.Item.Peer.Peer.init(id:))
                    ),
                    EngineDataMap(
                        peerIds.map(TelegramEngine.EngineData.Item.Peer.IsContact.init(id:))
                    )
                )
                |> deliverOnMainQueue).start(next: { [weak self] peerMap, isContactMap in
                    guard let self else {
                        return
                    }
                    
                    let mappedCategories = additionalCategoryIds.compactMap { item -> AdditionalPeerList.Category? in
                        switch item {
                        case AdditionalCategoryId.existingChats.rawValue:
                            return .existingChats
                        case AdditionalCategoryId.newChats.rawValue:
                            return .newChats
                        case AdditionalCategoryId.contacts.rawValue:
                            return .contacts
                        case AdditionalCategoryId.nonContacts.rawValue:
                            return .nonContacts
                        default:
                            return nil
                        }
                    }
                    
                    self.additionalPeerList.categories = Set(mappedCategories)
                    
                    self.additionalPeerList.peers.removeAll()
                    for id in peerIds {
                        guard let maybePeer = peerMap[id], let peer = maybePeer else {
                            continue
                        }
                        self.additionalPeerList.peers.append(AdditionalPeerList.Peer(
                            peer: peer,
                            isContact: isContactMap[id] ?? false
                        ))
                    }
                    self.additionalPeerList.peers.sort(by: { lhs, rhs in
                        return lhs.peer.debugDisplayTitle < rhs.peer.debugDisplayTitle
                    })
                    self.state?.updated(transition: .immediate)
                    
                    controller?.dismiss()
                })
            })
            
            self.environment?.controller()?.push(controller)
        }
        
        func update(component: ChatbotSetupScreenComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
            self.isUpdating = true
            defer {
                self.isUpdating = false
            }
            
            let environment = environment[EnvironmentType.self].value
            let themeUpdated = self.environment?.theme !== environment.theme
            self.environment = environment
            
            self.component = component
            self.state = state
            
            if themeUpdated {
                self.backgroundColor = environment.theme.list.blocksBackgroundColor
            }
            
            let presentationData = component.context.sharedContext.currentPresentationData.with { $0 }
            
            //TODO:localize
            let navigationTitleSize = self.navigationTitle.update(
                transition: transition,
                component: AnyComponent(MultilineTextComponent(
                    text: .plain(NSAttributedString(string: "Chatbots", font: Font.semibold(17.0), textColor: environment.theme.rootController.navigationBar.primaryTextColor)),
                    horizontalAlignment: .center
                )),
                environment: {},
                containerSize: CGSize(width: availableSize.width, height: 100.0)
            )
            let navigationTitleFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - navigationTitleSize.width) / 2.0), y: environment.statusBarHeight + floor((environment.navigationHeight - environment.statusBarHeight - navigationTitleSize.height) / 2.0)), size: navigationTitleSize)
            if let navigationTitleView = self.navigationTitle.view {
                if navigationTitleView.superview == nil {
                    if let controller = self.environment?.controller(), let navigationBar = controller.navigationBar {
                        navigationBar.view.addSubview(navigationTitleView)
                    }
                }
                transition.setFrame(view: navigationTitleView, frame: navigationTitleFrame)
            }
            
            let bottomContentInset: CGFloat = 24.0
            let sideInset: CGFloat = 16.0 + environment.safeInsets.left
            let sectionSpacing: CGFloat = 32.0
            
            let _ = bottomContentInset
            let _ = sectionSpacing
            
            var contentHeight: CGFloat = 0.0
            
            contentHeight += environment.navigationHeight
            
            let iconSize = self.icon.update(
                transition: .immediate,
                component: AnyComponent(LottieComponent(
                    content: LottieComponent.AppBundleContent(name: "BotEmoji"),
                    loop: true
                )),
                environment: {},
                containerSize: CGSize(width: 100.0, height: 100.0)
            )
            let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - iconSize.width) * 0.5), y: contentHeight + 2.0), size: iconSize)
            if let iconView = self.icon.view {
                if iconView.superview == nil {
                    self.scrollView.addSubview(iconView)
                }
                transition.setPosition(view: iconView, position: iconFrame.center)
                iconView.bounds = CGRect(origin: CGPoint(), size: iconFrame.size)
            }
            
            contentHeight += 129.0
            
            //TODO:localize
            let subtitleString = NSMutableAttributedString(attributedString: parseMarkdownIntoAttributedString("Add a bot to your account to help you automatically process and respond to the messages you receive. [Learn More]()", attributes: MarkdownAttributes(
                body: MarkdownAttributeSet(font: Font.regular(15.0), textColor: environment.theme.list.freeTextColor),
                bold: MarkdownAttributeSet(font: Font.semibold(15.0), textColor: environment.theme.list.freeTextColor),
                link: MarkdownAttributeSet(font: Font.regular(15.0), textColor: environment.theme.list.itemAccentColor),
                linkAttribute: { attributes in
                    return ("URL", "")
                }), textAlignment: .center
            ))
            if self.chevronImage == nil {
                self.chevronImage = UIImage(bundleImageName: "Settings/TextArrowRight")
            }
            if let range = subtitleString.string.range(of: ">"), let chevronImage = self.chevronImage {
                subtitleString.addAttribute(.attachment, value: chevronImage, range: NSRange(range, in: subtitleString.string))
            }
            
            //TODO:localize
            let subtitleSize = self.subtitle.update(
                transition: .immediate,
                component: AnyComponent(BalancedTextComponent(
                    text: .plain(subtitleString),
                    horizontalAlignment: .center,
                    maximumNumberOfLines: 0,
                    lineSpacing: 0.25,
                    highlightColor: environment.theme.list.itemAccentColor.withMultipliedAlpha(0.1),
                    highlightAction: { attributes in
                        if let _ = attributes[NSAttributedString.Key(rawValue: "URL")] {
                            return NSAttributedString.Key(rawValue: "URL")
                        } else {
                            return nil
                        }
                    },
                    tapAction: { [weak self] _, _ in
                        guard let self, let component = self.component else {
                            return
                        }
                        let _ = component
                    }
                )),
                environment: {},
                containerSize: CGSize(width: availableSize.width - sideInset * 2.0, height: 1000.0)
            )
            let subtitleFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - subtitleSize.width) * 0.5), y: contentHeight), size: subtitleSize)
            if let subtitleView = self.subtitle.view {
                if subtitleView.superview == nil {
                    self.scrollView.addSubview(subtitleView)
                }
                transition.setPosition(view: subtitleView, position: subtitleFrame.center)
                subtitleView.bounds = CGRect(origin: CGPoint(), size: subtitleFrame.size)
            }
            contentHeight += subtitleSize.height
            contentHeight += 27.0
            
            var nameSectionItems: [AnyComponentWithIdentity<Empty>] = []
            nameSectionItems.append(AnyComponentWithIdentity(id: 0, component: AnyComponent(ListTextFieldItemComponent(
                theme: environment.theme,
                initialText: "",
                placeholder: "Bot Username",
                autocapitalizationType: .none,
                autocorrectionType: .no,
                updated: { [weak self] value in
                    guard let self else {
                        return
                    }
                    self.updateBotQuery(query: value)
                },
                tag: self.textFieldTag
            ))))
            if let botResolutionState = self.botResolutionState {
                let mappedContent: ChatbotSearchResultItemComponent.Content
                switch botResolutionState.state {
                case .searching:
                    mappedContent = .searching
                case .notFound:
                    mappedContent = .notFound
                case let .found(peer, isInstalled):
                    mappedContent = .found(peer: peer, isInstalled: isInstalled)
                }
                nameSectionItems.append(AnyComponentWithIdentity(id: 1, component: AnyComponent(ChatbotSearchResultItemComponent(
                    context: component.context,
                    theme: environment.theme,
                    strings: environment.strings,
                    content: mappedContent,
                    installAction: { [weak self] in
                        guard let self else {
                            return
                        }
                        if var botResolutionState = self.botResolutionState, case let .found(peer, isInstalled) = botResolutionState.state, !isInstalled {
                            botResolutionState.state = .found(peer: peer, isInstalled: true)
                            self.botResolutionState = botResolutionState
                            self.state?.updated(transition: .spring(duration: 0.3))
                        }
                    },
                    removeAction: { [weak self] in
                        guard let self else {
                            return
                        }
                        if let botResolutionState = self.botResolutionState, case let .found(_, isInstalled) = botResolutionState.state, isInstalled {
                            self.botResolutionState = nil
                            if let botResolutionDisposable = self.botResolutionDisposable {
                                self.botResolutionDisposable = nil
                                botResolutionDisposable.dispose()
                            }
                            
                            if let textFieldView = self.nameSection.findTaggedView(tag: self.textFieldTag) as? ListTextFieldItemComponent.View {
                                textFieldView.setText(text: "", updateState: false)
                            }
                            self.state?.updated(transition: .spring(duration: 0.3))
                        }
                    }
                ))))
            }
            
            //TODO:localize
            let nameSectionSize = self.nameSection.update(
                transition: transition,
                component: AnyComponent(ListSectionComponent(
                    theme: environment.theme,
                    header: nil,
                    footer: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(
                            string: "Enter the username or URL of the Telegram bot that you want to automatically process your chats.",
                            font: Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize),
                            textColor: environment.theme.list.freeTextColor
                        )),
                        maximumNumberOfLines: 0
                    )),
                    items: nameSectionItems
                )),
                environment: {},
                containerSize: CGSize(width: availableSize.width - sideInset * 2.0, height: 10000.0)
            )
            let nameSectionFrame = CGRect(origin: CGPoint(x: sideInset, y: contentHeight), size: nameSectionSize)
            if let nameSectionView = self.nameSection.view {
                if nameSectionView.superview == nil {
                    self.scrollView.addSubview(nameSectionView)
                }
                transition.setFrame(view: nameSectionView, frame: nameSectionFrame)
            }
            contentHeight += nameSectionSize.height
            contentHeight += sectionSpacing
            
            //TODO:localize
            let accessSectionSize = self.accessSection.update(
                transition: transition,
                component: AnyComponent(ListSectionComponent(
                    theme: environment.theme,
                    header: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(
                            string: "CHATS ACCESSIBLE FOR THE BOT",
                            font: Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize),
                            textColor: environment.theme.list.freeTextColor
                        )),
                        maximumNumberOfLines: 0
                    )),
                    footer: nil,
                    items: [
                        AnyComponentWithIdentity(id: 0, component: AnyComponent(ListActionItemComponent(
                            theme: environment.theme,
                            title: AnyComponent(VStack([
                                AnyComponentWithIdentity(id: AnyHashable(0), component: AnyComponent(MultilineTextComponent(
                                    text: .plain(NSAttributedString(
                                        string: "All 1-to-1 Chats Except...",
                                        font: Font.regular(presentationData.listsFontSize.baseDisplaySize),
                                        textColor: environment.theme.list.itemPrimaryTextColor
                                    )),
                                    maximumNumberOfLines: 1
                                ))),
                            ], alignment: .left, spacing: 2.0)),
                            leftIcon: AnyComponentWithIdentity(id: 0, component: AnyComponent(Image(
                                image: checkIcon,
                                tintColor: !self.hasAccessToAllChatsByDefault ? .clear : environment.theme.list.itemAccentColor,
                                contentMode: .center
                            ))),
                            accessory: nil,
                            action: { [weak self] _ in
                                guard let self else {
                                    return
                                }
                                if !self.hasAccessToAllChatsByDefault {
                                    self.hasAccessToAllChatsByDefault = true
                                    self.additionalPeerList.categories.removeAll()
                                    self.additionalPeerList.peers.removeAll()
                                    self.state?.updated(transition: .immediate)
                                }
                            }
                        ))),
                        AnyComponentWithIdentity(id: 1, component: AnyComponent(ListActionItemComponent(
                            theme: environment.theme,
                            title: AnyComponent(VStack([
                                AnyComponentWithIdentity(id: AnyHashable(0), component: AnyComponent(MultilineTextComponent(
                                    text: .plain(NSAttributedString(
                                        string: "Only Selected Chats",
                                        font: Font.regular(presentationData.listsFontSize.baseDisplaySize),
                                        textColor: environment.theme.list.itemPrimaryTextColor
                                    )),
                                    maximumNumberOfLines: 1
                                ))),
                            ], alignment: .left, spacing: 2.0)),
                            leftIcon: AnyComponentWithIdentity(id: 0, component: AnyComponent(Image(
                                image: checkIcon,
                                tintColor: self.hasAccessToAllChatsByDefault ? .clear : environment.theme.list.itemAccentColor,
                                contentMode: .center
                            ))),
                            accessory: nil,
                            action: { [weak self] _ in
                                guard let self else {
                                    return
                                }
                                if self.hasAccessToAllChatsByDefault {
                                    self.hasAccessToAllChatsByDefault = false
                                    self.additionalPeerList.categories.removeAll()
                                    self.additionalPeerList.peers.removeAll()
                                    self.state?.updated(transition: .immediate)
                                }
                            }
                        )))
                    ]
                )),
                environment: {},
                containerSize: CGSize(width: availableSize.width - sideInset * 2.0, height: 10000.0)
            )
            let accessSectionFrame = CGRect(origin: CGPoint(x: sideInset, y: contentHeight), size: accessSectionSize)
            if let accessSectionView = self.accessSection.view {
                if accessSectionView.superview == nil {
                    self.scrollView.addSubview(accessSectionView)
                }
                transition.setFrame(view: accessSectionView, frame: accessSectionFrame)
            }
            contentHeight += accessSectionSize.height
            contentHeight += sectionSpacing
            
            var excludedSectionItems: [AnyComponentWithIdentity<Empty>] = []
            excludedSectionItems.append(AnyComponentWithIdentity(id: 0, component: AnyComponent(ListActionItemComponent(
                theme: environment.theme,
                title: AnyComponent(VStack([
                    AnyComponentWithIdentity(id: AnyHashable(0), component: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(
                            string: self.hasAccessToAllChatsByDefault ? "Exclude Chats..." : "Select Chats...",
                            font: Font.regular(presentationData.listsFontSize.baseDisplaySize),
                            textColor: environment.theme.list.itemAccentColor
                        )),
                        maximumNumberOfLines: 1
                    ))),
                ], alignment: .left, spacing: 2.0)),
                leftIcon: AnyComponentWithIdentity(id: 0, component: AnyComponent(BundleIconComponent(
                    name: "Chat List/AddIcon",
                    tintColor: environment.theme.list.itemAccentColor
                ))),
                accessory: nil,
                action: { [weak self] _ in
                    guard let self else {
                        return
                    }
                    self.openAdditionalPeerListSetup()
                }
            ))))
            for category in self.additionalPeerList.categories.sorted(by: { $0.rawValue < $1.rawValue }) {
                let title: String
                let icon: String
                let color: AvatarBackgroundColor
                //TODO:localize
                switch category {
                case .newChats:
                    title = "New Chats"
                    icon = "Chat List/Filters/Contact"
                    color = .purple
                case .existingChats:
                    title = "Existing Chats"
                    icon = "Chat List/Filters/Contact"
                    color = .purple
                case .contacts:
                    title = "Contacts"
                    icon = "Chat List/Filters/Contact"
                    color = .blue
                case .nonContacts:
                    title = "Non-Contacts"
                    icon = "Chat List/Filters/Contact"
                    color = .yellow
                }
                excludedSectionItems.append(AnyComponentWithIdentity(id: category, component: AnyComponent(PeerListItemComponent(
                    context: component.context,
                    theme: environment.theme,
                    strings: environment.strings,
                    style: .generic,
                    sideInset: 0.0,
                    title: title,
                    avatar: PeerListItemComponent.Avatar(
                        icon: icon,
                        color: color,
                        clipStyle: .roundedRect
                    ),
                    peer: nil,
                    subtitle: nil,
                    subtitleAccessory: .none,
                    presence: nil,
                    selectionState: .none,
                    hasNext: false,
                    action: { peer, _, _ in
                    }
                ))))
            }
            for peer in self.additionalPeerList.peers {
                excludedSectionItems.append(AnyComponentWithIdentity(id: peer.peer.id, component: AnyComponent(PeerListItemComponent(
                    context: component.context,
                    theme: environment.theme,
                    strings: environment.strings,
                    style: .generic,
                    sideInset: 0.0,
                    title: peer.peer.displayTitle(strings: environment.strings, displayOrder: .firstLast),
                    peer: peer.peer,
                    subtitle: peer.isContact ? "contact" : "non-contact",
                    subtitleAccessory: .none,
                    presence: nil,
                    selectionState: .none,
                    hasNext: false,
                    action: { peer, _, _ in
                    }
                ))))
            }
            
            //TODO:localize
            let excludedSectionSize = self.excludedSection.update(
                transition: transition,
                component: AnyComponent(ListSectionComponent(
                    theme: environment.theme,
                    header: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(
                            string: self.hasAccessToAllChatsByDefault ? "EXCLUDED CHATS" : "INCLUDED CHATS",
                            font: Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize),
                            textColor: environment.theme.list.freeTextColor
                        )),
                        maximumNumberOfLines: 0
                    )),
                    footer: AnyComponent(MultilineTextComponent(
                        text: .markdown(
                            text: self.hasAccessToAllChatsByDefault ? "Select chats or entire chat categories which the bot **WILL NOT** have access to." : "Select chats or entire chat categories which the bot **WILL** have access to.",
                            attributes: MarkdownAttributes(
                                body: MarkdownAttributeSet(font: Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize), textColor: environment.theme.list.freeTextColor),
                                bold: MarkdownAttributeSet(font: Font.semibold(presentationData.listsFontSize.itemListBaseHeaderFontSize), textColor: environment.theme.list.freeTextColor),
                                link: MarkdownAttributeSet(font: Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize), textColor: environment.theme.list.itemAccentColor),
                                linkAttribute: { _ in
                                    return nil
                                }
                            )
                        ),
                        maximumNumberOfLines: 0
                    )),
                    items: excludedSectionItems
                )),
                environment: {},
                containerSize: CGSize(width: availableSize.width - sideInset * 2.0, height: 10000.0)
            )
            let excludedSectionFrame = CGRect(origin: CGPoint(x: sideInset, y: contentHeight), size: excludedSectionSize)
            if let excludedSectionView = self.excludedSection.view {
                if excludedSectionView.superview == nil {
                    self.scrollView.addSubview(excludedSectionView)
                }
                transition.setFrame(view: excludedSectionView, frame: excludedSectionFrame)
            }
            contentHeight += excludedSectionSize.height
            contentHeight += sectionSpacing
            
            //TODO:localize
            let permissionsSectionSize = self.permissionsSection.update(
                transition: transition,
                component: AnyComponent(ListSectionComponent(
                    theme: environment.theme,
                    header: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(
                            string: "BOT PERMISSIONS",
                            font: Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize),
                            textColor: environment.theme.list.freeTextColor
                        )),
                        maximumNumberOfLines: 0
                    )),
                    footer: AnyComponent(MultilineTextComponent(
                        text: .plain(NSAttributedString(
                            string: "The bot will be able to view all new incoming messages, but not the messages that had been sent before you added the bot.",
                            font: Font.regular(presentationData.listsFontSize.itemListBaseHeaderFontSize),
                            textColor: environment.theme.list.freeTextColor
                        )),
                        maximumNumberOfLines: 0
                    )),
                    items: [
                        AnyComponentWithIdentity(id: 0, component: AnyComponent(ListActionItemComponent(
                            theme: environment.theme,
                            title: AnyComponent(VStack([
                                AnyComponentWithIdentity(id: AnyHashable(0), component: AnyComponent(MultilineTextComponent(
                                    text: .plain(NSAttributedString(
                                        string: "Reply to Messages",
                                        font: Font.regular(presentationData.listsFontSize.baseDisplaySize),
                                        textColor: environment.theme.list.itemPrimaryTextColor
                                    )),
                                    maximumNumberOfLines: 1
                                ))),
                            ], alignment: .left, spacing: 2.0)),
                            accessory: .toggle(ListActionItemComponent.Toggle(style: .icons, isOn: self.replyToMessages, action: { [weak self] _ in
                                guard let self else {
                                    return
                                }
                                self.replyToMessages = !self.replyToMessages
                                self.state?.updated(transition: .spring(duration: 0.4))
                            })),
                            action: nil
                        ))),
                    ]
                )),
                environment: {},
                containerSize: CGSize(width: availableSize.width - sideInset * 2.0, height: 10000.0)
            )
            let permissionsSectionFrame = CGRect(origin: CGPoint(x: sideInset, y: contentHeight), size: permissionsSectionSize)
            if let permissionsSectionView = self.permissionsSection.view {
                if permissionsSectionView.superview == nil {
                    self.scrollView.addSubview(permissionsSectionView)
                }
                transition.setFrame(view: permissionsSectionView, frame: permissionsSectionFrame)
            }
            contentHeight += permissionsSectionSize.height
            
            contentHeight += bottomContentInset
            contentHeight += environment.safeInsets.bottom
            
            let previousBounds = self.scrollView.bounds
            
            let contentSize = CGSize(width: availableSize.width, height: contentHeight)
            if self.scrollView.frame != CGRect(origin: CGPoint(), size: availableSize) {
                self.scrollView.frame = CGRect(origin: CGPoint(), size: availableSize)
            }
            if self.scrollView.contentSize != contentSize {
                self.scrollView.contentSize = contentSize
            }
            let scrollInsets = UIEdgeInsets(top: environment.navigationHeight, left: 0.0, bottom: 0.0, right: 0.0)
            if self.scrollView.scrollIndicatorInsets != scrollInsets {
                self.scrollView.scrollIndicatorInsets = scrollInsets
            }
                        
            if !previousBounds.isEmpty, !transition.animation.isImmediate {
                let bounds = self.scrollView.bounds
                if bounds.maxY != previousBounds.maxY {
                    let offsetY = previousBounds.maxY - bounds.maxY
                    transition.animateBoundsOrigin(view: self.scrollView, from: CGPoint(x: 0.0, y: offsetY), to: CGPoint(), additive: true)
                }
            }
            
            self.topOverscrollLayer.frame = CGRect(origin: CGPoint(x: 0.0, y: -3000.0), size: CGSize(width: availableSize.width, height: 3000.0))
            
            self.updateScrolling(transition: transition)
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View()
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

public final class ChatbotSetupScreen: ViewControllerComponentContainer {
    private let context: AccountContext
    
    public init(context: AccountContext) {
        self.context = context
        
        super.init(context: context, component: ChatbotSetupScreenComponent(
            context: context
        ), navigationBarAppearance: .default, theme: .default, updatedPresentationData: nil)
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.title = ""
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        
        self.scrollToTop = { [weak self] in
            guard let self, let componentView = self.node.hostView.componentView as? ChatbotSetupScreenComponent.View else {
                return
            }
            componentView.scrollToTop()
        }
        
        self.attemptNavigation = { [weak self] complete in
            guard let self, let componentView = self.node.hostView.componentView as? ChatbotSetupScreenComponent.View else {
                return true
            }
            
            return componentView.attemptNavigation(complete: complete)
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    @objc private func cancelPressed() {
        self.dismiss()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
    }
}
