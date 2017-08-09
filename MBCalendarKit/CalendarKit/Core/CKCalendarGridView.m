//
//  CKCalendarGridView.m
//  MBCalendarKit
//
//  Created by Moshe Berman on 8/8/17.
//  Copyright © 2017 Moshe Berman. All rights reserved.
//

#import "CKCalendarGridView.h"
#import "CKCalendarCell.h"
#include <tgmath.h>
#import "NSCalendarCategories.h"

@interface CKCalendarGridView () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@end

@implementation CKCalendarGridView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self configure];
    }
    return self;
}


// MARK: - Configuring the Collection View

- (void)configure
{
    [self registerCells];

    self.delegate = self;
    self.dataSource = self;
}

// MARK: - Setting the Cell Class

- (void)setCellClass:(Class)cellClass
{
    if(self.class == cellClass)
    {
        return;
    }
    
    [self registerClass:cellClass forCellWithReuseIdentifier:NSStringFromClass(cellClass)];
    _cellClass = cellClass;
}

- (void)registerCells
{
    self.cellClass = CKCalendarCell.class;
}

// MARK: - Mapping Dates and Index Paths


/**
 Returns an NSDate representing the day being displayed by the index path.

 @discussion If the index path isn't visible, returns `nil`.
 @param indexPath An index path to convert to a date.
 @return An NSDate represented by the index path.
 */
- (nullable NSDate *)dateForIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDate *correspondingDate = nil;
    
    
    NSDate *firstVisible = [self firstVisibleDate];
    NSInteger daysToAdd = (indexPath.section * [self.calendar rangeOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfYear forDate:self.date].length) + indexPath.item;
    
    correspondingDate = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:daysToAdd toDate:firstVisible options:0];
    
    
    return correspondingDate;
}


/**
 Converts a date into an index path.

 @discussion If the date isn't visible, returns `nil`.
 @param date Returns a date corresponding to the index path.
 @return An index path for the cell displaying the date.
 */
- (nullable NSIndexPath *)indexPathForDate:(NSDate *)date
{
    return nil;
}

// MARK: -

- (NSDate *)firstVisibleDate
{

    NSDate *firstOfTheMonth = [self.calendar firstDayOfTheMonthUsingReferenceDate:self.date];
    NSDate *firstVisible = [self.calendar firstDayOfTheWeekUsingReferenceDate:firstOfTheMonth andStartDay:self.calendar.firstWeekday];
    
    return firstVisible;
}

// MARK: - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger itemCount = [self.calendar rangeOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfYear forDate:self.date].length;
    
    return itemCount;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger sectionCount = [self.calendar rangeOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:self.date].length;
    
    return sectionCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(self.cellClass) forIndexPath:indexPath];
    
    self.cellConfigurationBlock(cell, [self dateForIndexPath:indexPath]);
    
    return cell;
}

// MARK: - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    cell.layer.borderColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.5].CGColor;
    cell.layer.borderWidth = 1.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    NSUInteger numberOfDaysPerWeek = [self.calendar rangeOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfYear forDate:self.date].length;
    CGFloat width = CGRectGetWidth(self.superview.bounds);
    CGFloat margin = (CGFloat)((NSInteger)width % numberOfDaysPerWeek);
    CGFloat inset = margin / 2.0;
    
    return UIEdgeInsetsMake(0, inset, 0, inset);
}

// MARK: - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger numberOfDaysPerWeek = [self.calendar rangeOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfYear forDate:self.date].length;
    
    if (numberOfDaysPerWeek == 0)
    {
        return CGSizeZero;
    }
    
    CGFloat width = CGRectGetWidth(self.superview.bounds);
    CGFloat widthAdjustForEvenDivisionByDaysPerWeek = width - (CGFloat)((NSInteger)width % numberOfDaysPerWeek);
    CGFloat side =  widthAdjustForEvenDivisionByDaysPerWeek / (CGFloat)numberOfDaysPerWeek;
    
    return CGSizeMake(side, side);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;
{
    return 0.0;
}

// MARK: - Changing the Date

- (void)setDate:(NSDate *)date
{
    [self reloadData];
    
    _date = date;
}

// MARK: -

- (void)adjustSectionCountToTransitionFrom:(NSDate *)oldDate to:(NSDate *)newDate
{
    NSInteger oldWeekCount = [self.calendar rangeOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:oldDate].length;
    NSInteger newWeekCount = [self.calendar rangeOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:newDate].length;
    
    if (oldWeekCount > newWeekCount)
    {
        while (self.visibleIndexSets.count > newWeekCount)
        {
            [self deleteSections:self.lastVisibleIndexSet];
        }
    }
    else
    {
        while (self.visibleIndexSets.count < newWeekCount)
        {
            [self insertSections:self.lastVisibleIndexSet];
        }
    }
    
}

// MARK: - Calculating Visible Index Sets

- (nullable NSArray <NSIndexSet *> *)visibleIndexSets
{
    NSArray <NSIndexPath *> * visibleIndexPaths = self.indexPathsForVisibleItems;
    NSMutableSet <NSIndexSet *> *indexSets = [[NSMutableSet alloc] init];
    
    for (NSIndexPath *indexPath in visibleIndexPaths)
    {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
        [indexSets addObject:indexSet];
    }
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"firstIndex" ascending:YES];
    NSArray *sortedIndexSets = [indexSets sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    return sortedIndexSets;
}

- (nullable NSIndexSet *)lastVisibleIndexSet
{
    return self.visibleIndexSets.lastObject;
}

@end
