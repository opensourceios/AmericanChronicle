final class SearchResultsPageCell: UITableViewCell {

    // MARK: Properties

    var thumbnailURL: NSURL? {
        get { return thumbnailImageView.sd_imageURL() }
        set { thumbnailImageView.sd_setImageWithURL(newValue) }
    }
    var cityState: String? {
        get { return cityStateLabel.text }
        set { cityStateLabel.text = newValue }
    }
    var date: String? {
        get { return dateLabel.text }
        set { dateLabel.text = newValue }
    }
    var publicationTitle: String? {
        get { return publicationTitleLabel.text }
        set { publicationTitleLabel.text = newValue }
    }

    private let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.backgroundColor = UIColor.whiteColor()
        view.layer.borderColor = UIColor.whiteColor().CGColor
        view.layer.borderWidth = 2.0
        view.clipsToBounds = true
        return view
    }()
    private let cityStateLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.darkGray
        label.numberOfLines = 0
        label.textAlignment = .Right
        label.font = Fonts.mediumBody
        return label
    }()
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.darkGray
        label.numberOfLines = 0
        label.textAlignment = .Right
        label.font = Fonts.largeBodyBold
        return label
    }()
    private let publicationTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.darkGray
        label.numberOfLines = 0
        label.textAlignment = .Right
        label.font = Fonts.mediumBody
        return label
    }()

    // MARK: Init methods

    func commonInit() {

        contentView.backgroundColor = UIColor.whiteColor()

        addSubview(thumbnailImageView)
        thumbnailImageView.snp_makeConstraints { make in
            make.top.equalTo(Measurements.verticalMargin)
            make.leading.equalTo(Measurements.horizontalMargin)
            make.bottom.equalTo(-Measurements.verticalMargin)
            make.width.equalTo(snp_height).multipliedBy(0.6)
        }

        addSubview(dateLabel)
        dateLabel.snp_makeConstraints { make in
            make.top.equalTo(Measurements.verticalMargin)
            make.leading.equalTo(thumbnailImageView.snp_trailing)
                        .offset(Measurements.horizontalSiblingSpacing)
            make.trailing.equalTo(-Measurements.horizontalMargin)
        }

        addSubview(cityStateLabel)
        cityStateLabel.snp_makeConstraints { make in
            make.top.equalTo(dateLabel.snp_bottom).offset(Measurements.verticalSiblingSpacing)
            make.leading.equalTo(thumbnailImageView.snp_trailing)
                        .offset(Measurements.horizontalSiblingSpacing)
            make.trailing.equalTo(-Measurements.horizontalMargin)
        }

        addSubview(publicationTitleLabel)
        publicationTitleLabel.snp_makeConstraints { make in
            make.top.greaterThanOrEqualTo(cityStateLabel.snp_bottom)
                        .offset(Measurements.verticalSiblingSpacing)
            make.leading.equalTo(thumbnailImageView.snp_trailing)
                        .offset(Measurements.horizontalSiblingSpacing)
            make.bottom.equalTo(-Measurements.verticalMargin)
            make.trailing.equalTo(-Measurements.horizontalMargin)
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
}
