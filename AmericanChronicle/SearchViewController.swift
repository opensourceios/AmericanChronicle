//
//  SearchViewController.swift
//  AmericanChronicle
//
//  Created by Ryan Peterson on 8/8/15.
//  Copyright (c) 2015 ryanipete. All rights reserved.
//

import UIKit
import Crashlytics

// NOTES:
//
// The View is passive. It waits for the Presenter to give it content to display; it never asks the Presenter for data.
// The view controller shouldn’t be making decisions based on (user) actions, but it should pass these events along to something that can.

protocol SearchViewInterface: class {
    weak var delegate: SearchViewDelegate? { get set }
    var searchTerm: String? { get set }
    var earliestDate: String? { get set }
    var latestDate: String? { get set }
    var USStates: String? { get set }

    func setViewState(state: ViewState)
    func setBottomContentInset(bottom: CGFloat)
    func resignFirstResponder() -> Bool
}

protocol SearchViewDelegate: class {
    func userDidTapCancel()
    func userDidTapReturn()
    func userDidTapUSStates()
    func userDidTapEarliestDateButton()
    func userDidTapLatestDateButton()
    func userDidChangeSearchToTerm(term: String?)
    func userIsApproachingLastRow(term: String?, inCollection: [SearchResultsRow])
    func userDidSelectSearchResult(row: SearchResultsRow)
    func viewDidLoad()
}

class SearchViewController: UIViewController, SearchViewInterface, UITableViewDelegate, UITableViewDataSource {

    // MARK: Properties

    weak var delegate: SearchViewDelegate?

    var searchTerm: String? {
        get { return tableHeaderView.searchTerm }
        set { tableHeaderView.searchTerm = newValue }
    }

    var earliestDate: String? {
        get { return tableHeaderView.earliestDate }
        set { tableHeaderView.earliestDate = newValue }
    }

    var latestDate: String? {
        get { return tableHeaderView.latestDate }
        set { tableHeaderView.latestDate = newValue }
    }

    var USStates: String? {
        get { return tableHeaderView.USStates }
        set { tableHeaderView.USStates = newValue }
    }

    private static let approachingCount = 5

    private let emptyResultsView = EmptyResultsView()
    private let errorView = ErrorView()
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)

    private let tableView = UITableView()
    private let tableHeaderView = SearchTableHeaderView()
    private let tableFooterView = UIView()
    private let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()

    private var sectionTitle = ""
    private var rows: [SearchResultsRow] = []

    // MARK: UIViewController Init methods

    @available(*, unavailable) required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported. Use designated initializer instead")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Info", style: .Plain, target: self, action: #selector(SearchViewController.infoButtonTapped(_:)))
        navigationItem.leftBarButtonItem?.setTitlePositionAdjustment(Measurements.leftBarButtonItemTitleAdjustment, forBarMetrics: .Default)
        navigationItem.title = "Search"
    }

    // MARK: Internal methods

    func setBottomContentInset(bottom: CGFloat) {
        if !isViewLoaded() {
            return
        }
        var contentInset = tableView.contentInset
        contentInset.bottom = bottom
        tableView.contentInset = contentInset

        var indicatorInsets = tableView.scrollIndicatorInsets
        indicatorInsets.bottom = bottom
        tableView.scrollIndicatorInsets = indicatorInsets
    }

    // > The partial state is the screen someone will see when the page is no longer empty and
    //   sparsely populated. Your job here is to prevent people from getting discouraged and giving
    //   up on your product.
    //
    // - http://scotthurff.com/posts/why-your-user-interface-is-awkward-youre-ignoring-the-ui-stack
    func setViewState(state: ViewState) {
        switch state {
        case .EmptySearchField:
            setLoadingIndicatorsVisible(false)
            emptyResultsView.alpha = 0
            errorView.alpha = 0
            sectionTitle = ""
            rows = []
            tableView.reloadData()
            tableFooterView.alpha = 0
        case .EmptyResults:
            setLoadingIndicatorsVisible(false)
            emptyResultsView.alpha = 1.0
            emptyResultsView.title = "No results"
            errorView.alpha = 0
            sectionTitle = ""
            rows = []
            tableView.reloadData()
            tableFooterView.alpha = 0
        case .LoadingNewParamaters:
            setLoadingIndicatorsVisible(true)
            emptyResultsView.alpha = 0
            errorView.alpha = 0
            sectionTitle = ""
            rows = []
            tableView.reloadData()
            tableFooterView.alpha = 0
        case .LoadingMoreRows:
            setLoadingIndicatorsVisible(false)
            emptyResultsView.alpha = 0
            errorView.alpha = 0
            tableFooterView.alpha = 1.0
        case let .Partial(title, rows):
            setLoadingIndicatorsVisible(false)
            emptyResultsView.alpha = 0
            errorView.alpha = 0
            sectionTitle = title
            if self.rows != rows {
                self.rows = rows
                tableView.reloadData()
            }
            tableFooterView.alpha = 0
        case let .Ideal(title, rows):
            setLoadingIndicatorsVisible(false)
            emptyResultsView.alpha = 0
            errorView.alpha = 0
            sectionTitle = title
            if self.rows != rows {
                self.rows = rows
                tableView.reloadData()
            }
            tableFooterView.alpha = 0
        case let .Error(title, message):
            setLoadingIndicatorsVisible(false)
            emptyResultsView.alpha = 0
            errorView.alpha = 1.0
            sectionTitle = ""
            rows = []
            tableView.reloadData()
            errorView.title = title
            errorView.message = message
            tableFooterView.alpha = 0
        }
    }

    func infoButtonTapped(sender: UIBarButtonItem) {
        let vc = InfoViewController()
        vc.userDidDismiss = { [weak self] in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        let nvc = UINavigationController(rootViewController: vc)
        presentViewController(nvc, animated: true, completion: nil)
    }

    // MARK: UITableViewDelegate & -DataSource methods

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (rows.count == 0) { return nil }

        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("Header") as? TableHeaderView
        headerView?.text = sectionTitle
        print("[RP] headerView: \(headerView)")
        return headerView
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (rows.count > 0) ? 1 : 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let pageCell = tableView.dequeueReusableCellWithIdentifier(String(SearchResultsPageCell)) as! SearchResultsPageCell
        let result = rows[indexPath.row]
        if let date = result.date {
            pageCell.date = dateFormatter.stringFromDate(date)
        } else {
            pageCell.date = ""
        }
        pageCell.cityState = result.cityState ?? ""
        pageCell.publicationTitle = result.publicationTitle ?? ""
        pageCell.thumbnailURL = result.thumbnailURL
        return pageCell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        tableHeaderView.resignFirstResponder()
        delegate?.userDidSelectSearchResult(rows[indexPath.row])
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard (rows.count > 0) else { return }
        guard ((rows.count - indexPath.row) < SearchViewController.approachingCount) else { return }

        delegate?.userIsApproachingLastRow(tableHeaderView.searchTerm, inCollection: rows)
    }

    // MARK: UIViewController overrides

    override func loadView() {
        view = UIView()
        view.backgroundColor = Colors.lightBackground

        loadTableView()
        loadTableHeaderView()
        loadTableFooterView()
        loadErrorView()
        loadEmptyResultsView()
        loadActivityIndicator()

        setViewState(.EmptySearchField)

        delegate?.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBarHidden = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
    }

    // MARK: UIResponder overrides

    override func becomeFirstResponder() -> Bool {
        return tableHeaderView.becomeFirstResponder() ?? false
    }

    override func resignFirstResponder() -> Bool {
        return tableHeaderView.resignFirstResponder() ?? false
    }

    // MARK: Private methods

    private func loadTableView() {
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(SearchResultsPageCell.self, forCellReuseIdentifier:  String(SearchResultsPageCell))
        tableView.registerClass(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "Header")
        tableView.sectionHeaderHeight = 24.0
        tableView.separatorColor = Colors.lightGray
        tableView.rowHeight = 160.0
        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.top.equalTo(0)
            make.bottom.equalTo(0)
            make.leading.equalTo(0)
            make.trailing.equalTo(0)
        }
    }

    private func loadTableHeaderView() {

        tableHeaderView.frame = CGRect(x: 0, y: 0, width: 0, height: tableHeaderView.intrinsicContentSize().height)

        tableHeaderView.shouldChangeCharactersHandler = { [weak self] original, range, replacement in
            var text = original
            if let range = original.rangeFromNSRange(range) {
                text.replaceRange(range, with: replacement)
            }

            self?.delegate?.userDidChangeSearchToTerm(text)

            return true
        }
        tableHeaderView.shouldReturnHandler = { [weak self] in
            self?.delegate?.userDidTapReturn()
            return false
        }
        tableHeaderView.shouldClearHandler = { [weak self] in
            self?.delegate?.userDidChangeSearchToTerm("")
            return true
        }
        tableHeaderView.earliestDateButtonTapHandler = { [weak self] _ in
            self?.delegate?.userDidTapEarliestDateButton()
        }
        tableHeaderView.latestDateButtonTapHandler = { [weak self] _ in
            self?.delegate?.userDidTapLatestDateButton()
        }
        tableHeaderView.USStatesButtonTapHandler = { [weak self] _ in
            self?.delegate?.userDidTapUSStates()
        }
    }

    private func loadTableFooterView() {
        tableFooterView.frame = CGRect(x: 0, y: 0, width: 300, height: 48)

        let spinner = UIActivityIndicatorView()
        spinner.startAnimating()
        tableFooterView.addSubview(spinner)
        spinner.snp_makeConstraints { make in
            make.center.equalTo(0)
        }
    }

    private func loadErrorView() {
        view.addSubview(errorView)
        errorView.snp_makeConstraints { make in
            make.center.equalTo(self.view.snp_center)
        }
    }

    private func loadEmptyResultsView() {
        view.addSubview(emptyResultsView)
        emptyResultsView.snp_makeConstraints { make in
            make.center.equalTo(self.view.snp_center)
        }
    }

    private func loadActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.snp_makeConstraints { make in
            make.center.equalTo(view.snp_center)
        }
    }

    private func setLoadingIndicatorsVisible(visible: Bool) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = visible
        if visible {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}
