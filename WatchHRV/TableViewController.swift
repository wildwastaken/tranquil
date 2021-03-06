//
//  TableViewController.swift
//  Tranquil
//
//  Created by Allen Liu on 01/10/21.
//  Copyright © 2021 Allen Liu. All rights reserved.
//

import UIKit
import HealthKit
import Firebase

class TableViewController: UITableViewController {

    var ref:DatabaseReference?
    
    let healthStore = HKHealthStore()
    let heartRateUnit = HKUnit(from: "count/min")
    var hrvData = [HKQuantitySample]()
    var query: HKQuery!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        
        refreshControl?.addTarget(self, action: #selector(refreshHRVData(_:)), for: .valueChanged)
        refreshControl?.tintColor = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        refreshControl?.attributedTitle = NSAttributedString(string: "Quering HealthKit ...", attributes: nil)
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            print("not available")
            return
        }
        
        guard let hrQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            print("not allowed")
            return
        }
        
        guard let hrvQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN) else {
            print("not allowed")
            return
        }
        
        let dataTypes: Set<HKQuantityType> = [hrQuantityType, hrvQuantityType]
        
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success {
                let day = Date(timeIntervalSinceNow: -7*24*60*60)
                self.query = self.createheartRateVariabilitySDNNStreamingQuery(day)
                self.healthStore.execute(self.query)
            }
            else {
                print("not allowed")
            }
        }
    }
    
    @objc private func refreshHRVData(_ sender: Any) {
        hrvData.removeAll()
        let day = Date(timeIntervalSinceNow: -7*24*60*60)
        query = createheartRateVariabilitySDNNStreamingQuery(day)
        self.healthStore.execute(query)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    func createheartRateVariabilitySDNNStreamingQuery(_ startDate: Date) -> HKQuery {
        let typeHRV = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
        let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: HKQueryOptions.strictStartDate)
        
        let squery = HKSampleQuery(sampleType: typeHRV!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async(execute: {() -> Void in
                guard error == nil, let hrvSamples = samples as? [HKQuantitySample] else {return}
                
                self.hrvData.append(contentsOf: hrvSamples)
                self.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            })
        }
        
        return squery
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return hrvData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hrvCell", for: indexPath)

        let sample = hrvData[indexPath.row]
        let value = sample.quantity.doubleValue(for: self.heartRateUnit)
        let date = sample.startDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd hh:mm"
        let todaysDate = dateFormatter.string(from: date)
        let ihatecoding = "\(date)"
        cell.textLabel?.text = String(format: "%.1f", value)
        cell.detailTextLabel?.text = todaysDate
        ref = Database.database().reference()
        ref?.child(todaysDate).child(ihatecoding).setValue(value)
        
        return cell
    }
}
