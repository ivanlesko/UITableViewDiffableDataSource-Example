The goal of this repo is to show how UITableViewDiffableDataSource can be used with multiple `struct` types that conform to the same protocol and inherit from `AnyHashable`.  

Diffable data source works on the notion of data snapshots.  This reduces the need to manually manage the data and table view reload updates.