//
//  OnboardingViewController.swift
//  GoodsAI
//
//  Created by Emily on 2025/4/1.
//

import UIKit

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let image: UIImage?
    let title: String
    let description: String
}

// MARK: - Onboarding Content View Controller
class OnboardingContentViewController: UIViewController {
    var page: OnboardingPage?
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        
        if let page = page {
            imageView.image = page.image
            titleLabel.text = page.title
            descriptionLabel.text = page.description
        }
    }
    
    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(80)
            make.width.equalToSuperview().multipliedBy(0.6)
            make.height.equalTo(imageView.snp.width).multipliedBy(0.8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(40)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
    }
}

// MARK: - Onboarding View Controller
class OnboardingViewController: UIViewController {
    
    // UserDefaults key to store onboarding shown status
    static let hasShownOnboardingKey = "com.inventoryiq.hasShownOnboarding"
    
    // Check if onboarding has been shown
    static func hasOnboardingBeenShown() -> Bool {
        return UserDefaults.standard.bool(forKey: hasShownOnboardingKey)
    }
    
    // Mark onboarding as shown
    static func markOnboardingAsShown() {
        UserDefaults.standard.set(true, forKey: hasShownOnboardingKey)
        UserDefaults.standard.synchronize()
    }
    
    // Reset onboarding status (for testing)
    static func resetOnboardingStatus() {
        UserDefaults.standard.set(false, forKey: hasShownOnboardingKey)
        UserDefaults.standard.synchronize()
    }
    
    // Create a large colorful SF Symbol with specific configuration
    private func createLargeSymbol(name: String, color: UIColor) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 100, weight: .medium, scale: .large)
        return UIImage(systemName: name)?
            .withConfiguration(configuration)
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }
    
    // Onboarding pages
    private lazy var pages: [OnboardingPage] = [
        OnboardingPage(
            image: createLargeSymbol(name: "list.dash.clipboard", color: .systemBlue),
            title: "Dashboard",
            description: "View all your inventory items at a glance. Search, sort and manage your items from this central screen."
        ),
        OnboardingPage(
            image: createLargeSymbol(name: "plus.circle.fill", color: .systemGreen),
            title: "Add Items",
            description: "Tap the + button to add a new item. Take a photo and fill in details like name, price and quantity."
        ),
        OnboardingPage(
            image: createLargeSymbol(name: "arrow.up.arrow.down.circle.fill", color: .systemPurple),
            title: "Sort Items",
            description: "Use the sort button to arrange items by name or price in ascending or descending order."
        ),
        OnboardingPage(
            image: createLargeSymbol(name: "magnifyingglass.circle.fill", color: .systemBlue),
            title: "Search Tab",
            description: "Switch to the Search tab to find items using different search methods."
        ),
        OnboardingPage(
            image: createLargeSymbol(name: "text.bubble.fill", color: .systemIndigo),
            title: "Text Search",
            description: "Type keywords to find items by name or description."
        ),
        OnboardingPage(
            image: createLargeSymbol(name: "mic.fill", color: .systemRed),
            title: "Voice Search",
            description: "Tap the microphone button in the search tab to find items by speaking your search query. Simply tap once to start and stop recording."
        ),
        OnboardingPage(
            image: createLargeSymbol(name: "mic.circle.fill", color: .systemPink),
            title: "Voice Input for Forms",
            description: "Press and hold the microphone button next to text fields when adding or editing items. Release when you're done speaking to automatically fill the field with your voice input."
        ),
        OnboardingPage(
            image: createLargeSymbol(name: "camera.fill", color: .systemOrange),
            title: "Image Search",
            description: "Take a photo or select an image to find similar items in your inventory."
        )
    ]
    
    private lazy var pageViewController: UIPageViewController = {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate = self
        return pageVC
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .systemBlue
        pageControl.pageIndicatorTintColor = .lightGray
        return pageControl
    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        
        // Set the initial page
        if let firstPage = contentViewController(at: 0) {
            pageViewController.setViewControllers([firstPage], direction: .forward, animated: true)
        }
    }
    
    private func setupUI() {
        // Add page view controller
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        // Add controls
        view.addSubview(pageControl)
        view.addSubview(skipButton)
        view.addSubview(nextButton)
        
        // Setup constraints
        pageViewController.view.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-20)
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-60)
        }
        
        skipButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalTo(pageControl)
        }
        
        nextButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(pageControl)
        }
    }
    
    private func contentViewController(at index: Int) -> OnboardingContentViewController? {
        guard index >= 0 && index < pages.count else { return nil }
        
        let contentVC = OnboardingContentViewController()
        contentVC.page = pages[index]
        return contentVC
    }
    
    @objc private func skipTapped() {
        finishOnboarding()
    }
    
    @objc private func nextTapped() {
        // If we're on the last page, finish onboarding
        if pageControl.currentPage == pages.count - 1 {
            finishOnboarding()
            return
        }
        
        // Otherwise, go to next page
        pageControl.currentPage += 1
        
        if let nextVC = contentViewController(at: pageControl.currentPage) {
            pageViewController.setViewControllers([nextVC], direction: .forward, animated: true)
            updateButtonTitles()
        }
    }
    
    private func updateButtonTitles() {
        // Update the next button title if we're on the last page
        if pageControl.currentPage == pages.count - 1 {
            nextButton.setTitle("Get Started", for: .normal)
        } else {
            nextButton.setTitle("Next", for: .normal)
        }
    }
    
    private func finishOnboarding() {
        // Mark onboarding as shown
        OnboardingViewController.markOnboardingAsShown()
        
        // Dismiss onboarding and show main app
        dismiss(animated: true)
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let contentVC = viewController as? OnboardingContentViewController,
              let currentIndex = pages.firstIndex(where: { $0.title == contentVC.page?.title }),
              currentIndex > 0 else {
            return nil
        }
        
        return contentViewController(at: currentIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let contentVC = viewController as? OnboardingContentViewController,
              let currentIndex = pages.firstIndex(where: { $0.title == contentVC.page?.title }),
              currentIndex < pages.count - 1 else {
            return nil
        }
        
        return contentViewController(at: currentIndex + 1)
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let contentVC = pageViewController.viewControllers?.first as? OnboardingContentViewController,
           let currentIndex = pages.firstIndex(where: { $0.title == contentVC.page?.title }) {
            pageControl.currentPage = currentIndex
            updateButtonTitles()
        }
    }
} 