//
//  BoxOfficeViewController.swift
//  BoxOffice
//
//  Created by vetto, brody on 23/03/20.
//
import UIKit

@available(iOS 16.0, *)
final class BoxOfficeViewController: UIViewController {
    enum Section {
        case main
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, BoxOfficeItem.ID>! = nil
    var collectionView: UICollectionView! = nil
    var boxOfficeItems: [BoxOfficeItem] = []
    private var snapshot = NSDiffableDataSourceSnapshot<Section, BoxOfficeItem.ID>()
    
    private var refreshControl = UIRefreshControl()
    
    private var yesterday: Date? {
        guard let yesterdayDate = Calendar.current.date(
            byAdding: Calendar.Component.day,
            value: -1,
            to: Date()) else {
            return nil
        }
            
        return yesterdayDate
    }
    
    private var selectedDate: Date?
    
    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = UIActivityIndicatorView.Style.large
        activityIndicator.startAnimating()
        
        return activityIndicator
    }()
    
    private let toolBar: UIToolbar = {
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 44)))
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedDate = yesterday
        self.configureHierarchy()
        self.configureDataSource()
        self.setupUI()
        self.fetchDailyBoxOffice(from: self.selectedDate)
    }
    
    private func setupUI() {
        setupNavigation()
        setupToolBar()
        setupActivityIndicator()
        setupRefreshControl()
    }
    
    private func setupNavigation() {
        self.updateNavigationTitle(form: "yyyy-MM-dd", date: self.selectedDate)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "날짜선택",
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(dateSelectionTapped))
        let appearance = UINavigationBarAppearance()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func setupToolBar() {
        self.view.addSubview(toolBar)
        
        NSLayoutConstraint.activate([
            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        toolBar.items = [
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(title: "화면 모드 변경", style: .plain, target: self, action: #selector(presentScreenMode)),
            UIBarButtonItem.flexibleSpace()
        ]
    }
    
    private func setupActivityIndicator() {
        self.view.addSubview(activityIndicator)
        self.activityIndicator.center = self.view.center
        self.activityIndicator.frame = self.view.frame
    }
    
    private func setupRefreshControl() {
        self.refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl
    }
    
    @objc private func presentScreenMode() {
        self.present(AlertManager.shared.showScreenMode(), animated: true)
    }
    
    private func fetchDailyBoxOffice(from date: Date?) {
        guard let formattedSelectedDate = date?.formatToDate(with: "yyyyMMdd") else {
            return
        }
        
        let boxOfficeProvider = BoxOfficeProvider<BoxOfficeAPI>()
        boxOfficeProvider.fetchData(.dailyBoxOffice(date: formattedSelectedDate),
                                    type: BoxOfficeDTO.self) { [weak self] result in
            switch result {
            case .success(let boxOfficeDTOData):
                self?.boxOfficeItems = boxOfficeDTOData.toDomain()
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.updateSnapshot()
                }
            case .failure:
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    let alertController = AlertManager.shared.showFailureAlert()
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
    
    @objc private func dateSelectionTapped() {
        guard let selectedDate = self.selectedDate,
              let yesterdayDate = yesterday else {
            return
        }
        
        let calendarViewController = CalendarViewController(
            selectedDate: selectedDate,
            yesterday: yesterdayDate)
        calendarViewController.delegate = self
        self.present(calendarViewController, animated: true)
    }
    
    @objc private func refresh() {
        guard let date = self.yesterday?.formatToDate(with: "yyyyMMdd") else {
            return
        }
        
        let boxOfficeProvider = BoxOfficeProvider<BoxOfficeAPI>()
        boxOfficeProvider.fetchData(.dailyBoxOffice(date: date),
                                    type: BoxOfficeDTO.self) { [weak self] result in
            switch result {
            case .success(let boxOfficeDTOData):
                self?.boxOfficeItems = boxOfficeDTOData.toDomain()
                DispatchQueue.main.async {
                    self?.updateSnapshot()
                    self?.updateNavigationTitle(form: "yyyy-MM-dd", date: self?.yesterday)
                    self?.refreshControl.endRefreshing()
                }
            case .failure:
                DispatchQueue.main.async {
                    let alertController = AlertManager.shared.showFailureAlert()
                    self?.present(alertController, animated: true)
                    self?.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    private func updateNavigationTitle(form: String, date: Date?) {
        guard let date = date, let formattedDate = date.formatToDate(with: form) else {
            return
        }
        
        self.navigationItem.title = formattedDate
    }
}

@available(iOS 16.0, *)
extension BoxOfficeViewController {
    private func createLayout(for layout: LayoutType = .list) -> UICollectionViewLayout {
        switch layout {
        case .list:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalWidth(0.2))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                             subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            let layout = UICollectionViewCompositionalLayout(section: section)
            
            return layout
        case .grid:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalWidth(0.5))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
            let spacing = CGFloat(10)
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

            let layout = UICollectionViewCompositionalLayout(section: section)
            return layout
        }
        
    }
}

@available(iOS 16.0, *)
extension BoxOfficeViewController {
    private func configureHierarchy(for layout: LayoutType = .list) {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    private func configureDataSource(for layout: LayoutType = .list) {
        let cellRegistration = UICollectionView.CellRegistration<BoxOfficeListCell, BoxOfficeItem> {
            (cell, indexPath, item) in
            cell.item = item
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, BoxOfficeItem.ID>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: BoxOfficeItem.ID) -> UICollectionViewCell? in
            
            let boxOfficeItem = self.boxOfficeItems.filter { $0.id == identifier }.first
            
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                    for: indexPath,
                                                                    item: boxOfficeItem)
            
            return cell
        }
    }
    
    private func updateSnapshot() {
        snapshot.deleteAllItems()
        snapshot.appendSections([.main])
        snapshot.appendItems(boxOfficeItems.map { $0.id })
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

@available(iOS 16.0, *)
extension BoxOfficeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedTitle = boxOfficeItems[indexPath.row].title
        let selectedCode = boxOfficeItems[indexPath.row].code
        let movieDetailViewController = MovieDetailViewController(movieName: selectedTitle,
                                                                  movieCode: selectedCode)
        self.navigationController?.pushViewController(movieDetailViewController, animated: true)
    }
}

@available(iOS 16.0, *)
extension BoxOfficeViewController: DateChangeable {
    func updateSelectedDate(selectedDate: Date?) {
        self.activityIndicator.startAnimating()
        self.selectedDate = selectedDate
        updateNavigationTitle(form: "yyyy-MM-dd", date: selectedDate)
        fetchDailyBoxOffice(from: selectedDate)
    }
}

fileprivate enum LayoutType {
    case list
    case grid
}
