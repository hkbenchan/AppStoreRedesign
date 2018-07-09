//
//  AppTableViewCell.swift
//  AppStoreRedesign
//
//  Created by Chan Ho Pan on 6/7/2018.
//  Copyright © 2018 hpchan. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class AppTableViewCell: UITableViewCell {
  
  public static let identifier = "AppTableViewCell"
  
  // IBOutlet
  @IBOutlet weak var numberLabel: UILabel!
  @IBOutlet weak var appIconImageView: UIImageView!
  
  @IBOutlet weak var appTitleLabel: UILabel!
  @IBOutlet weak var appCategoryLabel: UILabel!
  
  @IBOutlet var ratingImageViews: [UIImageView]!
  @IBOutlet weak var ratingCountLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.tintColor = UIColor(red: 255.0/255, green: 127.0/255, blue: 0, alpha: 1)
    self.ratingImageViews?.forEach { $0.tintColor = self.tintColor }
    
    self.selectionStyle = .none
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  override func prepareForReuse() {
    // cancel previous loading request
    self.appIconImageView.af_cancelImageRequest()
    self.appIconImageView.image = nil
  }
  
  public func viewSetup(_ index: Int, data: AppObject, shouldDisplayRating: Bool = true) {
    self.numberLabel?.text = "\(index)"
    
    self.appTitleLabel.text = data.title ?? ""
    self.appCategoryLabel.text = data.appCategory ?? ""
    
    if let iconUrl = data.iconUrl, let url = URL(string: iconUrl) {
      let radius: CGFloat = (0 == index % 2) ? 25.0 : 8.0
      let filter = RoundedCornersFilter(radius: radius)
      self.appIconImageView?.af_setImage(withURL: url, placeholderImage: nil, filter: filter)
    }
    
    ratingImageViews.forEach { $0.isHidden = !shouldDisplayRating }
    ratingCountLabel.isHidden = !shouldDisplayRating
    
    if !shouldDisplayRating {
      return
    }
    // star ratings
    ratingImageViews?.forEach { (imageView: UIImageView) in
      if Double(imageView.tag - 100) <= data.rating {
        imageView.image = UIImage.init(named: "starFilled")
      } else {
        imageView.image = UIImage.init(named: "starNotFilled")
      }
    }
    
    // number of rating
    self.ratingCountLabel.text = "(\(data.ratingCount))"
  }
}
