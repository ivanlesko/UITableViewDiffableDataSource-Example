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
        dataSource.defaultRowAnimation = .right
        dataSource.appendFriend(Friend.random as! Friend)
    }
    
    @objc internal func removeRandomFriend(_ sender: UIButton) {
        dataSource.defaultRowAnimation = .left
        dataSource.removeRandomFriend()
    }
    
    @objc internal func addRandomContact(_ sender: UIButton) {
        dataSource.defaultRowAnimation = .right
        dataSource.appendContact(Contact.random as! Contact)
    }
    
    @objc internal func removeRandomContact(_ sender: UIButton) {
        dataSource.defaultRowAnimation = .left
        dataSource.removeRandomContact()
    }
}

fileprivate class UserTableDataSource: UITableViewDiffableDataSource<UserSection, AnyHashable> {
    
    private var sections: [UserSection] {
        return [.friends, .contacts]
    }
    
    var cancellables = Set<AnyCancellable>()
    @Published private var friends = [Friend]()
    @Published private var contacts = [Contact]()
    
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
        
        configureInitialSnapshot()
        setupObservers()
        
    }
    
    private func setupObservers() {
        Publishers.CombineLatest($friends, $contacts)
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.applySnapshot()
            }
            .store(in: &cancellables)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    private func configureInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, AnyHashable>()
        snapshot.appendSections(sections)
        apply(snapshot, animatingDifferences: false)
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, AnyHashable>()
        snapshot.appendSections(sections)
        snapshot.appendItems(friends, toSection: .friends)
        snapshot.appendItems(contacts, toSection: .contacts)
        apply(snapshot, animatingDifferences: true)
    }
    
    public func appendFriend(_ friend: Friend) {
        friends.insert(friend, at: 0)
    }
    
    public func removeRandomFriend() {
        if let index = friends.indices.randomElement() {
            friends.remove(at: index)
        }
    }
    
    public func appendContact(_ contact: Contact) {
        contacts.insert(contact, at: 0)
    }
    
    public func removeRandomContact() {
        if let index = contacts.indices.randomElement() {
            contacts.remove(at: index)
        }
    }
}

// MARK: Models

enum UserSection {
    case friends
    case contacts
    
    var title: String {
        switch self {
        case .friends:
            return "Friends"
        case .contacts:
            return "Contacts"
        }
    }
}

protocol User: Identifiable {
    var firstName: String { get }
    var lastName: String { get }
    static var random: any User { get }
}

protocol UserRow: User, Hashable {
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

private struct Friend: User, UserRow, Hashable {
    var firstName: String
    var lastName: String
    let id = UUID()
    var subtitle: String? {
        return nil
    }
    
    static var random: any User {
        Friend(firstName: Name.randomFirstName, lastName: Name.randomLastName)
    }
}

private struct Contact: User, UserRow, Hashable {
    var firstName: String
    var lastName: String
    let id = UUID()
    var phoneNumber: String?
    
    static var random: any User {
        let number = Bool.random() ? Phone.randomNumber : nil
        return Contact(firstName: Name.randomFirstName, lastName: Name.randomLastName, phoneNumber: number)
    }
    
    var subtitle: String? {
        phoneNumber ?? "missing #"
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
        return [
            "Nathalie",
            "Daija",
            "Jamar",
            "Daniella",
            "Dwight",
            "Danny",
            "Mindy",
            "Kennedy",
            "Terence",
            "Reilly",
            "Cooper",
            "Bradly",
            "Stephon",
            "Bernard",
            "Dontae",
            "Callie",
            "Cody",
            "Kelton",
            "Chaim",
            "Janessa",
            "Vicente",
            "Aiden",
            "Devan",
            "Jaden",
            "Fredy",
            "Dawson",
            "Vanessa",
            "Kendrick",
            "Deangelo",
            "Yaquelin",
            "Phoebe",
            "Candice",
            "Nayeli",
            "Emanuel",
            "Mariela",
            "Annamarie",
            "Joshua",
            "David",
            "Ruby",
            "Alexus",
            "Ayesha",
            "Juwan",
            "Deasia",
            "Konnor",
            "Makayla",
            "Trista",
            "Lars",
            "Carrie",
            "Jocelyn",
            "Kallie",
            "Kyron",
            "Carrington",
            "Dario",
            "Moses",
            "Osvaldo",
            "Jalil",
            "Damien",
            "Chelsie",
            "Gabriel",
            "Susannah",
            "Mauro",
            "Kimberly",
            "Jerome",
            "Tai",
            "Vincent",
            "Brad",
            "Vladimir",
            "Melody",
            "Tiffany",
            "Lauren",
            "Bo",
            "Mateo",
            "Hazel",
            "Marcus",
            "Daisha",
            "Skyler",
            "Shelby",
            "Gabrielle",
            "Maxwell",
            "Sienna",
            "Braiden",
            "Karley",
            "Neha",
            "Darwin",
            "Kristin",
            "Odalis",
            "Sergio",
            "Ariana",
            "Elvin",
            "Arnold",
            "Araceli",
            "Camden",
            "Kendall",
            "Clara",
            "Demetrius",
            "Kami",
            "Louise",
            "Winston",
            "Emerson",
            "Jairo"
        ].randomElement() ?? "random"
    }
    static var randomLastName: String {
        return [
            "Romero"
            ,"Salter"
            ,"Boyle"
            ,"Thorne"
            ,"Mcfarland"
            ,"Cortes"
            ,"Choi"
            ,"Hayden"
            ,"Malone"
            ,"Morton"
            ,"Pendleton"
            ,"Stacy"
            ,"Sanders"
            ,"Kirkpatrick"
            ,"Montgomery"
            ,"Darling"
            ,"Dickens"
            ,"Aguirre"
            ,"Cortes"
            ,"Velasquez"
            ,"Wu"
            ,"Lovell"
            ,"Suarez"
            ,"Briggs"
            ,"Lowery"
            ,"Ruiz"
            ,"Byers"
            ,"Tillman"
            ,"Sharpe"
            ,"Darnell"
            ,"Jefferson"
            ,"Hoover"
            ,"Hutchison"
            ,"Farr"
            ,"Gregory"
            ,"Locke"
            ,"Hoffman"
            ,"Navarro"
            ,"Saldana"
            ,"Chandler"
            ,"Parra"
            ,"Lockwood"
            ,"Newell"
            ,"Calvert"
            ,"Battle"
            ,"Hamilton"
            ,"Cisneros"
            ,"Lord"
            ,"Hayes"
            ,"Trent"
            ,"Hood"
            ,"Levine"
            ,"Mcdonald"
            ,"Downing"
            ,"Earl"
            ,"Mcclain"
            ,"Kerns"
            ,"Pope"
            ,"Farris"
            ,"Love"
            ,"Mcdaniel"
            ,"Summers"
            ,"Skinner"
            ,"Carmichael"
            ,"Perdue"
            ,"Field"
            ,"Wiggins"
            ,"Montes"
            ,"Serrano"
            ,"Dotson"
            ,"Paulson"
            ,"Dunham"
            ,"Prather"
            ,"Sheffield"
            ,"Rogers"
            ,"Hall"
            ,"Witt"
            ,"Summers"
            ,"Fournier"
            ,"Palmer"
            ,"Meza"
            ,"Lovett"
            ,"Bledsoe"
            ,"Feliciano"
            ,"Reyes"
            ,"Pickens"
            ,"Yang"
            ,"Cordero"
            ,"Davidson"
            ,"Montes"
            ,"Amos"
            ,"Champion"
            ,"Shirley"
            ,"Hurley"
            ,"Metcalf"
            ,"Washington"
            ,"Kirk"
            ,"Bryan"
            ,"Massey"
            ,"Bravo"
        ].randomElement() ?? "random"
    }
}

struct Phone {
    static var randomNumber: String {
        return [
            "+1 505-646-7508",
            "+1 302-818-1121",
            "+1 505-646-2937",
            "+1 505-354-8426",
            "+1 505-646-3970",
            "+1 313-642-8268",
            "+1 339-918-8407",
            "+1 513-870-0863",
            "+1 279-713-6857",
            "+1 248-829-3198",
            "+1 505-620-9164",
            "+1 505-251-9296",
            "+1 720-952-4244",
            "+1 820-793-8058",
            "+1 505-730-2335",
            "+1 229-795-3889",
            "+1 505-646-8879",
            "+1 505-682-8204",
            "+1 628-337-6139",
            "+1 202-450-2104",
            "+1 505-372-0239",
            "+1 505-646-7959",
            "+1 505-644-2437",
            "+1 341-636-4008",
            "+1 307-987-7605",
            "+1 317-455-5309",
            "+1 458-509-5083",
            "+1 517-384-5051",
            "+1 617-726-5145",
            "+1 213-844-9797",
            "+1 361-220-3622",
            "+1 414-583-7910",
            "+1 251-626-8544",
            "+1 317-260-5315",
            "+1 520-490-1155",
            "+1 212-234-1559",
            "+1 601-301-7242",
            "+1 505-644-8981",
            "+1 505-646-7727",
            "+1 501-425-3777",
            "+1 326-370-6562",
            "+1 505-944-6652",
            "+1 302-405-2944",
            "+1 224-415-1478",
            "+1 505-279-7516",
            "+1 505-644-0484",
            "+1 505-644-1653",
            "+1 505-627-2964",
            "+1 223-826-3819",
            "+1 308-435-0626",
            "+1 505-646-0242",
            "+1 208-742-9392",
            "+1 270-673-5422",
            "+1 228-658-5609",
            "+1 505-882-8640",
            "+1 218-618-1276",
            "+1 332-212-3352",
            "+1 505-644-6667",
            "+1 505-644-8818",
            "+1 330-523-6690",
            "+1 223-514-3314",
            "+1 303-636-8199",
            "+1 215-813-5892",
            "+1 307-451-3489",
            "+1 240-918-3957",
            "+1 505-215-8005",
            "+1 208-570-2549",
            "+1 239-942-2684",
            "+1 332-482-3180",
            "+1 505-631-8954",
            "+1 505-526-7049",
            "+1 347-999-1107",
            "+1 213-348-3632",
            "+1 201-265-5945",
            "+1 505-668-0128",
            "+1 505-638-4991",
            "+1 402-555-7698",
            "+1 351-906-5023",
            "+1 505-646-4409",
            "+1 505-646-9632",
            "+1 334-413-0625",
            "+1 505-393-8513",
            "+1 415-804-4318",
            "+1 505-371-2068",
            "+1 315-714-6756",
            "+1 505-380-1948",
            "+1 304-341-0599",
            "+1 218-461-5226",
            "+1 216-240-2033",
            "+1 505-644-2459",
            "+1 210-522-8797",
            "+1 316-963-8974",
            "+1 206-611-3704",
            "+1 234-519-2946",
            "+1 214-586-9530",
            "+1 248-797-6570",
            "+1 505-646-2788",
            "+1 505-265-5305",
            "+1 505-665-6270",
            "+1 616-251-8638"
        ].randomElement() ?? "invalid #"
    }
}