//
//  ViewController.swift
//  Diffable Table View Example
//
//  Created by Ivan Lesko on 7/2/23.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    private lazy var table: UITableView = {
        let t = UITableView()
        t.register(SubtitleTableViewCell.self, forCellReuseIdentifier: SubtitleTableViewCell.identifier)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.allowsSelection = false
        return t
    }()
    
    private lazy var dataSource = UserTableDataSource(tableView: table)
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var contactsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var friendsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStackViews()
        configureTableView()
        _ = dataSource
    }
    
    private func configureStackViews() {
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        [contactsStack, friendsStack].forEach { stack.addArrangedSubview($0) }
        
        let addFriend = UIButton(type: .roundedRect)
        addFriend.setTitle("Add random friend", for: .normal)
        addFriend.addTarget(self, action: #selector(addRandomFriend(_:)), for: .primaryActionTriggered)
        
        let removeFriend = UIButton(type: .roundedRect)
        removeFriend.setTitle("Remove random friend", for: .normal)
        removeFriend.addTarget(self, action: #selector(removeRandomFriend(_:)), for: .primaryActionTriggered)
        [addFriend, removeFriend].forEach { friendsStack.addArrangedSubview($0) }
        
        let addContact = UIButton(type: .roundedRect)
        addContact.setTitle("Add random contact", for: .normal)
        addContact.addTarget(self, action: #selector(addRandomContact(_:)), for: .primaryActionTriggered)
        
        let removeContact = UIButton(type: .roundedRect)
        removeContact.setTitle("Remove random contact", for: .normal)
        removeContact.addTarget(self, action: #selector(removeRandomContact(_:)), for: .primaryActionTriggered)
        [addContact, removeContact].forEach { contactsStack.addArrangedSubview($0) }
    }
    
    private func configureTableView() {
        view.addSubview(table)
        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -16)
        ])
    }
    
    @objc internal func addRandomFriend(_ sender: UIButton) {
        dataSource.appendFriend(Friend.random())
    }
    
    @objc internal func removeRandomFriend(_ sender: UIButton) {
        dataSource.removeRandomFriend()
    }
    
    @objc internal func addRandomContact(_ sender: UIButton) {
        dataSource.appendContact(Contact.random())
    }
    
    @objc internal func removeRandomContact(_ sender: UIButton) {
        dataSource.removeRandomContact()
    }
}

fileprivate class UserTableDataSource: UITableViewDiffableDataSource<UserSection, AnyHashable> {
    
    private let sections = UserSection.allCases
    private var friends = [Friend]()
    private var contacts = [Contact]()
    
    
    init(tableView: UITableView) {
        super.init(tableView: tableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleTableViewCell.identifier, for: indexPath) as? SubtitleTableViewCell else {
                return UITableViewCell()
            }

            switch item {
            case let item as any UserRow:
                cell.textLabel?.text = item.title
                cell.detailTextLabel?.text = item.subtitle
            default:
                cell.textLabel?.text = "undefined"
                cell.detailTextLabel?.text = "undefined subtitle"
            }

            return cell
        }
        
        applySnapshot(animated: false)
    }
    
    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, AnyHashable>()
        snapshot.appendSections(sections)
        snapshot.appendItems(friends, toSection: .friends)
        snapshot.appendItems(contacts, toSection: .contacts)
        apply(snapshot, animatingDifferences: animated)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = String(arrayFor(sections[section]).count) + " " + sections[section].rawValue
        return title
    }
    
    private func arrayFor(_ section: UserSection) -> [User] {
        switch section {
        case .friends:
            return friends
        case .contacts:
            return contacts
        }
    }
    
    public func appendFriend(_ friend: Friend) {
        // Reload section title only
        let count = friends.count
        defaultRowAnimation = .none
        friends.insert(friend, at: 0)
        var curr = snapshot()
        curr.reloadSections([.friends])
        apply(curr, animatingDifferences: false)
        
        // Insert item animated after section title reload
        curr = snapshot()
        defaultRowAnimation = .right
        
        switch count {
        case 0:
            curr.appendItems([friend], toSection: .friends)
        default:
            curr.insertItems([friend], beforeItem: curr.itemIdentifiers(inSection: .friends).first!)
        }
        
        apply(curr, animatingDifferences: true)
    }
    
    public func removeRandomFriend() {
        if let index = friends.indices.randomElement() {
            let friend = friends[index]
            friends.remove(at: index)
            
            defaultRowAnimation = .none
            var curr = snapshot()
            curr.reloadSections([.friends])
            apply(curr, animatingDifferences: false) { [unowned self] in
                curr = self.snapshot()
                self.defaultRowAnimation = .left
                curr.deleteItems([friend])
                self.apply(curr, animatingDifferences: true)
            }
        }
    }
    
    public func appendContact(_ contact: Contact) {
        // Reload section title only
        let count = contacts.count
        defaultRowAnimation = .none
        contacts.insert(contact, at: 0)
        var curr = snapshot()
        curr.reloadSections([.contacts])
        apply(curr, animatingDifferences: false)
        
        // Insert item animated after section title reload
        curr = snapshot()
        defaultRowAnimation = .right
        
        switch count {
        case 0:
            curr.appendItems([contact], toSection: .contacts)
        default:
            curr.insertItems([contact], beforeItem: curr.itemIdentifiers(inSection: .contacts).first!)
        }
        
        apply(curr, animatingDifferences: true)
    }
    
    public func removeRandomContact() {
        if let index = contacts.indices.randomElement() {
            let contact = contacts[index]
            contacts.remove(at: index)
            
            defaultRowAnimation = .none
            var curr = snapshot()
            curr.reloadSections([.contacts])
            apply(curr, animatingDifferences: false) { [unowned self] in
                curr = self.snapshot()
                self.defaultRowAnimation = .left
                curr.deleteItems([contact])
                self.apply(curr, animatingDifferences: true)
            }
        }
    }
}

// MARK: Models

/// Defines a protocol that will return a random object for a given type.
protocol RandomObject {
    associatedtype T
    static func random() -> T
}

/// Defines the type of sections that can be used in the table view
enum UserSection: String, CaseIterable {
    case friends = "Friends"
    case contacts = "Contacts"
}

protocol Person: Identifiable {
    var firstName: String { get }
    var lastName: String { get }
}

protocol UserRow: Person, Hashable {
    var title: String { get }
    var subtitle: String? { get }
}

extension UserRow {
    var title: String {
        firstName + " " + lastName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

private class User: Person, UserRow {
    var firstName: String
    var lastName: String
    var subtitle: String?
    let id = UUID()
    
    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}

private class Friend: User, RandomObject {
    static func random() -> Friend {
        Friend(firstName: Name.randomFirstName, lastName: Name.randomLastName)
    }
}

private class Contact: User, RandomObject {
    var phoneNumber: String?
    
    override var subtitle: String? {
        get {
            return phoneNumber ?? "missing #"
        }
        set {
            super.subtitle = newValue
        }
    }
    
    init(firstName: String, lastName: String, phoneNumber: String? = nil) {
        super.init(firstName: firstName, lastName: lastName)
        self.phoneNumber = phoneNumber
    }
    
    static func random() -> Contact {
        let number = Bool.random() ? Phone.randomNumber : nil
        return Contact(firstName: Name.randomFirstName, lastName: Name.randomLastName, phoneNumber: number)
    }
}

fileprivate class SubtitleTableViewCell: UITableViewCell {
    
    static var identifier: String {
        "subtitleCell"
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct Name {
    static var randomFirstName: String {
        return String.convertTextResourceNamedToString("firstNames")?.randomElement() ?? "randomFirst"
    }
    
    static var randomLastName: String {
        return String.convertTextResourceNamedToString("lastNames")?.randomElement() ?? "randomLast"
    }
}

struct Phone {
    static var randomNumber: String {
        return String.convertTextResourceNamedToString("phoneNumbers")?.randomElement() ?? "invalid #"
    }
}

extension String {
    static func convertTextResourceNamedToString(_ filename: String) -> [String]? {
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "txt") else { return nil }
        
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
                .components(separatedBy: ",")
                .map {
                    var res = $0.replacingOccurrences(of: "\n", with: "")
                    res = res.replacingOccurrences(of: "\"", with: "")
                    return res
                }
        } catch {
            return nil
        }
    }
}
