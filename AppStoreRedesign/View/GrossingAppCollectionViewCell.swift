//
//  GrossingAppCollectionViewCell.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 8/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import UIKit
import AlamofireImage

class GrossingAppCollectionViewCell: UICollectionViewCell {
  
  public static let identifier = "GrossingAppCollectionViewCell"
  
  // IBOutlets
  @IBOutlet weak var appIconImageView: UIImageView!
  
  @IBOutlet weak var appTitleLabel: UILabel!
  
  @IBOutlet weak var appCategoryLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func prepareForReuse() {
    self.appIconImageView?.af_cancelImageRequest()
    self.appIconImageView?.image = nil
  }
  
  public func viewSetup(data: AppObject) {
    
    self.appTitleLabel?.text = data.title ?? ""
    self.appCategoryLabel?.text = data.appCategory ?? ""
    
    if let iconUrl = data.iconUrl, let url = URL(string: iconUrl) {
      let filter = RoundedCornersFilter(radius: 8.0)
      self.appIconImageView?.af_setImage(withURL: url, placeholderImage: nil, filter: filter)
    }
    
  }
}
