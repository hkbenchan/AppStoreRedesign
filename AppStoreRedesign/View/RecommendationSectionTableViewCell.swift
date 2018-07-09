//
//  RecommendationSectionTableViewCell.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 8/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import UIKit

class RecommendationSectionTableViewCell: UITableViewCell {
  
  public static let identifier = "RecommendationSectionTableViewCell"
  
  // IBOutlet
  @IBOutlet weak var grossingAppsCollectionView: UICollectionView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    
    self.selectionStyle = .none
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  func registerCollectionViewNib(nib: UINib, forCellWithReuseIdentifier identifier: String) {
    grossingAppsCollectionView?.register(nib, forCellWithReuseIdentifier: identifier)
  }
  
  func setCollectionViewDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>(dataSourceDelegate: D) {
    grossingAppsCollectionView?.delegate = dataSourceDelegate
    grossingAppsCollectionView?.dataSource = dataSourceDelegate
    grossingAppsCollectionView?.reloadData()
  }
  
}
