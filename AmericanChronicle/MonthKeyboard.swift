import SnapKit

final class MonthKeyboard: UIView {

    var monthTapHandler: ((Int) -> Void)?
    var selectedMonth: Int? { // 1-based (like the month in NSDateComponent)
        didSet {
            for (idx, button) in allMonthButtons.enumerate() {
                if let selectedMonth = selectedMonth {
                    button.selected = (idx == (selectedMonth - 1))
                } else {
                    button.selected = false
                }
            }
        }
    }

    private var allMonthButtons: [UIButton] = []

    func commonInit() {

        backgroundColor = UIColor.whiteColor()

        for monthSymbol in DayMonthYear.allMonthSymbols() {
            let button: UIButton = MonthKeyboard.newButtonWithTitle(monthSymbol)
            button.addTarget(self,
                             action: #selector(didTapButton(_:)),
                             forControlEvents: .TouchUpInside)
            allMonthButtons.append(button)
        }
        var buttonsToAdd = allMonthButtons // copy
        var prevRow: UIButton?
        while !buttonsToAdd.isEmpty {
            var row: [UIButton] = []
            while row.count < 4 && !buttonsToAdd.isEmpty {
                row.append(buttonsToAdd.first!)
                buttonsToAdd.removeFirst()
            }
            prevRow = addRowWithButtons(row, prevRow: prevRow)
        }
        prevRow?.snp_makeConstraints { make in
            make.bottom.equalTo(self.snp_bottom).offset(-4.0)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    func didTapButton(button: UIButton) {
        if let index = allMonthButtons.indexOf(button) {
            monthTapHandler?(index + 1)
        }
    }

    class func newButtonWithTitle(title: String) -> UIButton {

        let selectedBgColor = Colors.lightBlueBright
        let normalBgColor = UIColor.whiteColor()

        let button = UIButton()
        button.setTitle(title, forState: .Normal)
        button.titleLabel?.font = Fonts.largeBody
        button.layer.shadowColor = Colors.darkGray.CGColor
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 0.5
        button.layer.shadowOpacity = 0.4

        button.setTitleColor(Colors.darkBlue, forState: .Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: .Highlighted)
        button.setTitleColor(UIColor.whiteColor(), forState: .Selected)
        if title == "" {
            button.enabled = false
        }

        let normalImage = UIImage.imageWithFillColor(normalBgColor, cornerRadius: 1.0)
        let highlightedImage = UIImage.imageWithFillColor(selectedBgColor, cornerRadius: 1.0)
        button.setBackgroundImage(normalImage, forState: .Normal)
        button.setBackgroundImage(highlightedImage, forState: .Highlighted)
        button.setBackgroundImage(highlightedImage, forState: .Selected)

        return button
    }

    private func addRowWithButtons(buttons: [UIButton], prevRow: UIButton? = nil) -> UIButton? {
        var prevColumn: UIButton? = nil
        for button in buttons {
            addSubview(button)

            let leading: ConstraintItem
            if let prevColumn = prevColumn {
                leading = prevColumn.snp_trailing
            } else {
                leading = self.snp_leading
            }
            let top: ConstraintItem
            if let prevRow = prevRow {
                top = prevRow.snp_bottom
            } else {
                top = self.snp_top
            }
            button.snp_makeConstraints { make in
                make.leading.equalTo(leading).offset(4.0)
                make.top.equalTo(top).offset(4.0)
                if let width = prevColumn?.snp_width {
                    make.width.equalTo(width)
                }
                if let height = prevRow?.snp_height {
                    make.height.equalTo(height)
                } else if let height = prevColumn?.snp_height {
                    make.height.equalTo(height)
                }
            }
            prevColumn = button
        }

        prevColumn?.snp_makeConstraints { make in
            make.trailing.equalTo(self.snp_trailing).offset(-4.0)
        }
        return prevColumn
    }

}
