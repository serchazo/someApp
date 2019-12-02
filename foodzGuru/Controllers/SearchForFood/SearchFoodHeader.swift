//
//  SearchFoodHeader.swift
//  foodzGuru
//
//  Created by Sergio Ortiz on 02.12.19.
//  Copyright © 2019 sergioortiz.com. All rights reserved.
//

import UIKit

class SearchFoodHeader: UICollectionReusableView {
      static let reuseIdentifier = "header-reuse-identifier"

      let label = UILabel()

      override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
      }

      required init?(coder: NSCoder) {
        fatalError()
      }
    }

    extension SearchFoodHeader {
      func configure() {
        backgroundColor = .systemBackground

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true

        let inset = CGFloat(10)
        NSLayoutConstraint.activate([
          label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
          label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
          label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
          label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])
        label.font = UIFont.preferredFont(forTextStyle: .title3)
      }
    }
