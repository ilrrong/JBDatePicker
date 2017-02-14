//
//  JBDatePickerView.swift
//  JBDatePicker
//
//  Created by Joost van Breukelen on 09-10-16.
//  Copyright © 2016 Joost van Breukelen. All rights reserved.
//

import UIKit

typealias ContentController = JBDatePickerContentVC
typealias Manager = JBDatePickerManager
typealias MonthView = JBDatePickerMonthView
typealias WeekDaysView = JBDatePickerWeekDaysView

public final class JBDatePickerView: UIView {
    
    // MARK: - Properties
    
    var contentController: ContentController!
    var manager: Manager!
    var weekViewSize: CGSize!
    var dayViewSize: CGSize!
    var dateToPresent: Date!
    var weekdaysView: WeekDaysView!
    fileprivate var dateFormatter = DateFormatter()
  
    public weak var delegate: JBDatePickerViewDelegate? {
        didSet{
            commonInit()
        }
    }
    
    public var presentedMonthView: JBDatePickerMonthView! {
        didSet {
            if let dayView = presentedMonthView.dayViewForDate(self.dateToPresent) {
                self.selectedDateView = dayView
            }
            
            delegate?.didPresentOtherMonth(presentedMonthView)
            layoutIfNeeded()
        }
    }
    
    public var selectedDateView: JBDatePickerDayView! {
        
        willSet {
            selectedDateView?.deselect()
        }
        
        didSet {
            
            if let date0 = selectedDateView.date, let date1 = dateToPresent {
                let calendar = NSCalendar.init(identifier: .gregorian)
                let year0 = calendar!.component(.year, from: date0)
                let year1 = calendar!.component(.year, from: date1)
                let month0 = calendar!.component(.month, from: date0)
                let month1 = calendar!.component(.month, from: date1)
                let day0 = calendar!.component(.day, from: date0)
                let day1 = calendar!.component(.day, from: date1)
                
                if year0 != year1 || month0 != month1 || day0 != day1 {
                    if month0 > month1 {
                        self.loadNextView()
                    }
                    else if month0 < month1 {
                        self.loadPreviousView()
                    }
                }
            }
            
            selectedDateView.select()
            dateToPresent = selectedDateView.date
        }
    }
    
    
    // MARK: - Initialization
    
    private func commonInit() {

        //initialize datePickerManager
        manager = Manager(datePickerView: self)
        
        //initialize contentController with preferred (or current) date
        dateToPresent = delegate?.dateToShow ?? Date()
        contentController = ContentController(datePickerView: self, frame: bounds, presentedDate: dateToPresent)
        
        //add scrollView
        addSubview(contentController.scrollView)
        contentController.scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        //create and add weekdayView
        weekdaysView = WeekDaysView(datePickerView: self)
        addSubview(weekdaysView)
        weekdaysView.translatesAutoresizingMaskIntoConstraints = false
        
        //pin datePickerView to left, right and bottom of scrollView.
        leftAnchor.constraint(equalTo: contentController.scrollView.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: contentController.scrollView.rightAnchor).isActive = true
        bottomAnchor.constraint(equalTo: contentController.scrollView.bottomAnchor).isActive = true
        
        //pin weekDaysView to left, right and top of datePickerView
        weekdaysView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        weekdaysView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        weekdaysView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        //add heightconstraint for weekDaysview
        weekdaysView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: (delegate?.weekDaysViewHeightRatio)!).isActive = true

    }
}


extension JBDatePickerView {
    
    /**
     Updates the layout of JBDatePicker. This makes sure that elements in JBDatePicker that need a frame, will get their frame.
     */
    public func updateLayout() {
        
        guard delegate != nil else {
            
            print("JBDatePickerView warning: there is no delegate set. This is needed for JBDatePickerView to work correctly")
            return
        }
        
        guard weekdaysView != nil else { return }
        
        let width = bounds.size.width
        let availableRectForScrollView = CGRect(x: bounds.origin.x, y: weekdaysView.bounds.height, width: width, height: bounds.size.height - weekdaysView.bounds.height)

        //adjust scrollView frame to available space
        contentController.updateScrollViewFrame(availableRectForScrollView)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        updateLayout()
    }
}


extension JBDatePickerView {
    
    public func monthDescriptionForDate(_ date: Date) -> String {

        let monthFormatString = "MMMM yyyy"
        dateFormatter.dateFormat = monthFormatString
        if let preferredLanguage = Bundle.main.preferredLocalizations.first {
            if delegate?.shouldLocalize == true {
                dateFormatter.locale = Locale(identifier: preferredLanguage)
            }
        }

        return dateFormatter.string(from: date)
    }
    
    
    
    ///this will call the delegate as well as set the selectedDate on the datePicker. 
    func didTapDayView(dayView: JBDatePickerDayView) {
        selectedDateView = dayView
        delegate?.didSelectDay(dayView)
    }
}


extension JBDatePickerView {
    
    ///scrolls the next month into the visible area and creates an new 'next' month waiting in line.
    public func loadNextView() {
        contentController.presentNextView()
    }
    
    ///scrolls the previous month into the visible area and creates an new 'previous' month waiting in line.
    public func loadPreviousView() {
        contentController.presentPreviousView()
    }
    
}
