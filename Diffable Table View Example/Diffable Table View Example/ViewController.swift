//
//  ViewController.swift
//  Diffable Table View Example
//
//  Created by Ivan Lesko on 7/2/23.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    private lazy var dataSource = UserTableDataSource(tableView: table)
    
    private lazy var table: UITableView = {
        let table = UITableView()
        table.register(SubtitleTableViewCell.self, forCellReuseIdentifier: SubtitleTableViewCell.identifier)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.allowsSelection = false
        return table
    }()
    
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
    
    /// Setup buttons that trigger remove/delete actions
    private func configureStackViews() {
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        [contactsStack, friendsStack].forEach { stack.addArrangedSubview($0) }
        
        [ClosureButton(title: "Add random friend") { self.dataSource.appendFriend(Friend.random()) },
         ClosureButton(title: "Remove random friend") { self.dataSource.removeRandomFriend() }]
            .forEach { friendsStack.addArrangedSubview($0) }
        
        [ClosureButton(title: "Add random contact") { self.dataSource.appendContact(Contact.random()) },
         ClosureButton(title: "Remove random contact") { self.dataSource.removeRandomContact()}]
            .forEach { contactsStack.addArrangedSubview($0) }
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
        
        // Applies the initial snapshot to the table view data source.
        applySnapshot(animated: false)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Returns the number of `User` objects in the section + the count
        let title = String(arrayFor(sections[section]).count) + " " + sections[section].rawValue
        return title
    }
    
    /// Used as a `reloadData()` alternative.  Call this to reload
    /// all of the sections and items.
    /// - Parameter animated: animate the differences.
    private func applySnapshot(animated: Bool) {
        defaultRowAnimation = .fade
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, AnyHashable>()
        snapshot.appendSections(sections)
        snapshot.appendItems(friends, toSection: .friends)
        snapshot.appendItems(contacts, toSection: .contacts)
        apply(snapshot, animatingDifferences: animated)
    }
    
    /// Convenience function to get a specific array for a given section.
    private func arrayFor(_ section: UserSection) -> [User] {
        switch section {
        case .friends:
            return friends
        case .contacts:
            return contacts
        }
    }
    
    public func appendFriend(_ friend: Friend) {
        /**
         This function has a two goals and has to be performned in a specific order.
         1. Reload the section title with the current friend count but don't use an animation
         for the reload.  This is accomplished by inserting `friend` at the beginning
         of the friends array and immediately reloading the `.friends` section.
         We get the current snapshot of the data source and only reload the section
         at this point.  This forces
         `tableView(_ tableView: UITableView, titleForHeaderInSection section: Int)`
         to perform a reload and display the string returned.
         */
        let count = friends.count
        defaultRowAnimation = .none
        friends.insert(friend, at: 0)
        var curr = snapshot()
        curr.reloadSections([.friends])
        apply(curr, animatingDifferences: false)
        
        /**
         2. After the section header title has been refreshed we can how perform the
         row insert with animation by inserting the new friend into the `.friend` section.
         We track the number of friends before the `friends` insert so we know
         if `snapshot.appendItems` or `snapshot.insertItemsBeforeItem` should be called.
         */
        curr = snapshot()
        defaultRowAnimation = .right
        
        switch count {
        case 0:
            curr.appendItems([friend], toSection: .friends)
        default:
            curr.insertItems([friend], beforeItem: curr.itemIdentifiers(inSection: .friends).first!)
        }
        
        // Apply the latest snapshot with the row insert.
        apply(curr, animatingDifferences: true)
    }
    
    public func removeRandomFriend() {
        /**
         The order of operations for removing a friend row is similar to
         appending a friend row.  The `friends` section is reloaded first
         without animation.  Once the apply snapshot closure has been called
         we can delete the friend item from the latest snapshot and
         apply the updated snapshot and animate the difference.
         */
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
        // Refer to `appendFriend(_ friend: Friend)` for a detailed
        // explanation of how this works since the code is duplicated.
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
        // See `removeRandomFriend()` for a detailed explanation
        // of how this works since the code is duplicated.
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
        /**
         Since `Person` conforms to `Identifiable`
         we can use its unique id to generate the hash.
         */
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
