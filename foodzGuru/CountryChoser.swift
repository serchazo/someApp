//
//  CountryChoser.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 29.11.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

protocol CountryChooserViewDelegate: class{
    func itemChooserReceiveCity(city: City, countryName: String, stateName: String)
}

class CountryChoser: UIViewController {
    
    private let cellIdentifier = "countryCell"
    
    // Control var
    var firstLoginFlag = false
    
    private var screenSize = UIScreen.main.bounds.size
    private var selectedCountryName: String!
    private var cityList: [(city: City, stateName: String)] = []
    private var countryList: [(key:String, name:String, imageURL:URL?)] = []
    
    // MARK: Broadcast messages
    weak var delegate: CountryChooserViewDelegate?
    
    @IBOutlet weak var countryChoserCollectionView: UICollectionView!{
        didSet{
            countryChoserCollectionView.delegate = self
            countryChoserCollectionView.dataSource = self
        }
    }
    
    // City chooser
    private var transparentView = UIView()
    private var cityTable = UITableView()
    
    
    // MARK: timeline funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cityTable.delegate = self
        cityTable.dataSource = self
        
        // For avoiding drawing the extra lines
        cityTable.tableFooterView = UIView()
        
        getCountryListFromDB()
        if firstLoginFlag{
            setCountryTableHeader()
        }
    
        countryChoserCollectionView.collectionViewLayout = generateLayout()
        
    }
    
    // MARK: Get values from DB
    private func getCountryListFromDB(){
        // Get the list of countries
        var count = 0
        var tmpCountries: [(key:String, name:String, imageURL: URL?)] = []
        SomeApp.dbGeographyCountry.observeSingleEvent(of: .value, with: {snapshot in
            for child in snapshot.children{
                if let countrySnap = child as? DataSnapshot,
                    let countryName = countrySnap.value as? String {
                    let countryKey = countrySnap.key
                    tmpCountries.append((key: countryKey,name:countryName,imageURL: nil))
                    count += 1
                    if count == snapshot.childrenCount{
                        self.countryList = tmpCountries.sorted(by: {$0.name < $1.name})
                        self.getImages()
                        self.countryChoserCollectionView.reloadData()
                    }
                }
            }
        })
        
    }
    
    // Get country images from DB
    private func getImages(){
        guard countryList.count > 0 else{return}
        
        for country in countryList{
            // [START] Get the image
            let storagePath = country.key + ".png"
            let imageRef = SomeApp.storageContryPicRef.child(storagePath)
            // Fetch the download URL
            imageRef.downloadURL { url, error in
              if let error = error {
                print(error.localizedDescription)
              } else {
                let index = self.countryList.firstIndex(where: {$0.key == country.key})
                self.countryList[index!].imageURL = url
                self.countryChoserCollectionView.reloadItems(at: [IndexPath(item: index!, section: 0)])
              }
            }
            // [END] Get the image
            
        }
        
    }
    
    //
    private func getCityListFromDB(countryKey: String){
        var count = 0
        var tmpCities:[(city:City, stateName: String)] = []
        //I. top level is states
        SomeApp.dbGeographyStates.child(countryKey).observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                if let stateSnap = child as? DataSnapshot{
                    let state = stateSnap.key
                    let stateName = stateSnap.value
        
                    // II. Now look for Cities
                    SomeApp.dbGeography.child(countryKey).child(state).observeSingleEvent(of: .value, with: {snap in
                        for cityChild in snap.children{
                            if let citySnap = cityChild as? DataSnapshot{
                                let cityKey = citySnap.key
                                if let cityDetails = citySnap.value as? [String:AnyObject],
                                    let cityName = cityDetails["name"] as? String {
                                    tmpCities.append((city: City(name: cityName, state: state, country: countryKey, key: cityKey), stateName: stateName as! String))
                                }
                            }
                        }
                        count += 1
                        if count == snapshot.childrenCount{
                            self.cityList = tmpCities.sorted(by: {$0.city.name < $1.city.name})
                            self.cityTable.reloadData()
                        }
                    })
                }
                
            }
        })
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


// MARK: Other funcs
extension CountryChoser{
    func setCountryTableHeader(){
        let headerView: UIView = UIView.init(frame: CGRect(
            x: 0, y: 0, width: screenSize.width, height: 50))
        let labelView: UILabel = UILabel.init(frame: CGRect(
            x: 0, y: 0, width: screenSize.width, height: 50))
        labelView.textAlignment = NSTextAlignment.center
        labelView.textColor = SomeApp.themeColor
        labelView.font = UIFont.preferredFont(forTextStyle: .title2)
        labelView.text = MyStrings.title.localized()
        
        headerView.addSubview(labelView)
        //countryChoserCollectionView.tableHeaderView = headerView
    }
    
    
    // Same for cities
    func setCityTableHeader(){
        let headerView: UIView = UIView.init(frame: CGRect(
            x: 0, y: 0, width: screenSize.width, height: 50))
        let labelView: UILabel = UILabel.init(frame: CGRect(
            x: 0, y: 0, width: screenSize.width, height: 50))
        labelView.textAlignment = NSTextAlignment.center
        labelView.textColor = SomeApp.themeColor
        labelView.font = UIFont.preferredFont(forTextStyle: .title2)
        labelView.text = MyStrings.cityTitle.localized()
        
        headerView.addSubview(labelView)
        
        cityTable.tableHeaderView = headerView
    }
    
    
    // Set the city view
    func showCityTable(){
        // Create the frame
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        //let window = UIApplication.shared.keyWindow
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        transparentView.frame = self.view.frame
        window?.addSubview(transparentView)
        
        // Add the table
        cityTable.frame = CGRect(
            x: 0,
            y: screenSize.height,
            width: screenSize.width,
            height: screenSize.height * 0.9)
        window?.addSubview(cityTable)
        
        // Go back to "normal" if we tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickTransparentView))
        transparentView.addGestureRecognizer(tapGesture)
        
        // Cool "slide-up" animation when appearing
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0.7 //Start at 0, go to 0.5
                        self.cityTable.frame = CGRect(
                            x: 0,
                            y: self.screenSize.height * 0.1,
                            width: self.screenSize.width,
                            height: self.screenSize.height * 0.9)
        },
                       completion: nil)
    }
    
    //Disappear!
    @objc func onClickTransparentView(){
        // Animation when disapearing
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
                        self.transparentView.alpha = 0 //Start at value above, go to 0
                        self.cityTable.frame = CGRect(
                            x: 0,
                            y: self.screenSize.height ,
                            width: self.screenSize.width * 0.9,
                            height: self.screenSize.height * 0.9)
                        
        },
                       completion: nil)
        
        // Deselect the row to go back to normal
        /*
        if let indexPath = countryTable.indexPathForSelectedRow {
            countryTable.deselectRow(at: indexPath, animated: true)
        }*/

    }
}

// MARK: Collection view stuff
extension CountryChoser: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard countryList.count > 0 else { return 1 }
        return countryList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard countryList.count > 0 else {
            // then go
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath) as? CountryChoserCell {
                cell.countryNameLabel.text = FoodzLayout.FoodzStrings.loading.localized()
                return cell
            }else{
                fatalError("No cell")
            }
        }
        
        // Image cells
        //if foodList[indexPath.row].imageURL != nil,
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier, for: indexPath) as? CountryChoserCell {
            
            // Image
            if countryList[indexPath.row].imageURL != nil {
                cell.countryImage.sd_imageIndicator = SDWebImageActivityIndicator.gray
                cell.countryImage.sd_imageTransition = .fade
                cell.countryImage.sd_setImage(
                with: countryList[indexPath.row].imageURL,
                placeholderImage: nil,//UIImage(named: "defaultBest"),
                options: [],
                completed: nil)
                
                cell.countryNameLabel.textColor = .white
            }
            
            // Label
            cell.countryNameLabel.text = countryList[indexPath.row].name
            
            return cell
        }
        // Cannot
        else{
            fatalError("Can't create cell")
        }
    }
    
    // Select a cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCountryName = countryList[indexPath.row].name
        getCityListFromDB(countryKey: countryList[indexPath.row].key)
        setCityTableHeader()
        showCityTable()
    }
    
}

// MARK: Layout stuff
extension CountryChoser{
    // snippet from : https://www.raywenderlich.com/5436806-modern-collection-views-with-compositional-layouts
    func generateLayout() -> UICollectionViewLayout {
        
        // Insets
        let insets = NSDirectionalEdgeInsets(
            top: 2,
            leading: 2,
            bottom: 2,
            trailing: 2)
      
        // We have only one row style
        // 'Twins': Two 1/2 width photos stacked horizontally
        
        let twinItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1/2),
                heightDimension: .fractionalHeight(1.0)))
        
        twinItem.contentInsets = insets
        
        let twinGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(3/8)),
            subitems: [twinItem, twinItem])
        
        let nestedGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                //heightDimension: .fractionalWidth(16/9)),
            heightDimension: .fractionalWidth(3/8)),
            subitems: [
                twinGroup,
            ]
        )
      
        let section = NSCollectionLayoutSection(group: nestedGroup)
        // Return the layout
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}

// MARK: Table view stuff
extension CountryChoser: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == cityTable{
            // City Table
            guard cityList.count > 0 else{
                return 1
            }
            return cityList.count
        }
        else{return 0}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // If country Table
        if tableView == cityTable{
            guard cityList.count > 0 else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = FoodzLayout.FoodzStrings.loading.localized()
                let spinner = UIActivityIndicatorView(style: .medium)
                
                spinner.startAnimating()
                cell.accessoryView = spinner
                
                return cell
            }
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            let tmpCellText = cityList[indexPath.row].city.name + ", " + cityList[indexPath.row].stateName
            cell.textLabel?.text = tmpCellText
            return cell
        }
        // Cannot
        else{fatalError("Can't create cell")}
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Choose your city
        if tableView == cityTable{
            let chosenCity = cityList[indexPath.row].city
            self.delegate?.itemChooserReceiveCity(city: chosenCity, countryName: selectedCountryName, stateName: cityList[indexPath.row].stateName)
            
            onClickTransparentView()
            
            if firstLoginFlag{
                self.dismiss(animated: true, completion: nil)
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: Localized Strings
extension CountryChoser{
    private enum MyStrings {
        case title
        case cityTitle
        
        func localized(arguments: CVarArg...) -> String{
            switch self{
            case .title:
                return String(
                format: NSLocalizedString("COUNTRYCHOSER_COUNTRY_TITLE", comment: "Choose"),
                locale: .current,
                arguments: arguments)
            case .cityTitle:
                return String(
                format: NSLocalizedString("COUNTRYCHOSER_CITY_TITLE", comment: "Choose city"),
                locale: .current,
                arguments: arguments)
                
                
            }
        }
    }
}
