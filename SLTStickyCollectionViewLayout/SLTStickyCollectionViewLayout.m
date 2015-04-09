//
//  SLTStickyCollectionViewLayout.m
//  SLTStickyCollectionViewLayout
//
//  Created by Andrei Raifura on 4/1/15.
//  Copyright (c) 2015 YOPESO. All rights reserved.
//

#import "SLTStickyCollectionViewLayout.h"
#import "SLTStickyLayoutSection.h"
#import "Utils.h"
#import "NSArray+Additions.h"

@interface SLTStickyCollectionViewLayout ()
@property (nonatomic) NSMutableArray *sections;
@property (nonatomic) BOOL needsSectionInitialization;
@end

@implementation SLTStickyCollectionViewLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setInitialValues];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setInitialValues];
    }
    return self;
}


- (CGRect)frameForSectionAtIndex:(NSUInteger)sectionIndex {
    if (![_sections containsObjectAtIndex:sectionIndex]) return CGRectZero;
    
    return [_sections[sectionIndex] sectionRect];
}


#pragma mark - Override Methods

- (void)prepareLayout {
    [super prepareLayout];
    
    if (_needsSectionInitialization) {
        [self initializeSections];
    }
}


- (CGSize)collectionViewContentSize {
    CGFloat width = [self lastXPosition] + self.sectionInset.right;
    CGFloat height = CGRectGetHeight(self.collectionView.bounds);
    
    return CGSizeMake(width, height);
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *sections = [self sectionsIntersectingRect:rect];
    NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:300];
    CGRect rectForSuplimentaryViews = [self rectWithVisibleLeftEdgeForRect:rect];

    for (SLTStickyLayoutSection *section in sections) {
        [attributes addObjectsFromArray:[section layoutAttributesForItemsInRect:rect]];

        if ([section hasHeaderInRect:rectForSuplimentaryViews]) {
            [attributes addObject:[section layoutAttributesForHeaderInRect:rectForSuplimentaryViews]];
        }
        
        if ([section hasFooterInRect:rectForSuplimentaryViews]) {
            [attributes addObject:[section layoutAttributesForFooterInRect:rectForSuplimentaryViews]];
        }
    }
    
    return attributes;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    SLTStickyLayoutSection *section = _sections[(NSUInteger)indexPath.section];
    
    return [section layoutAttributesForItemAtIndex:indexPath.row];
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    _needsSectionInitialization = !CGSizeEqualToSize(newBounds.size, self.collectionView.bounds.size);
    
    return YES;
}


- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    if (!_optimizedScrolling) return proposedContentOffset;
    if (![self shouldOptimizeScrollingForProposedOffset:proposedContentOffset]) return proposedContentOffset;
    
    CGFloat shiftedX = proposedContentOffset.x + _sectionInset.left;
    NSRange indexRange = [self indexRangeOfSectionsForHorizontalOffset:shiftedX];
    if (NSRangeIsUndefined(indexRange)) return proposedContentOffset;
    
    BOOL indexContainsOneIndex = (0 == indexRange.length);
    if (indexContainsOneIndex) {
        SLTStickyLayoutSection *section = _sections[indexRange.location];
        CGFloat xTarget = [section offsetForNearestColumnToOffset:shiftedX] - _sectionInset.left;
        
        return CGPointMake(xTarget, proposedContentOffset.y);
    } else {
        SLTStickyLayoutSection *firstSection = _sections[indexRange.location];
        SLTStickyLayoutSection *secondSection = _sections[NSMaxRange(indexRange)];
        
        CGFloat firstXTarget = [firstSection offsetForNearestColumnToOffset:shiftedX];
        CGFloat secondXTarget = [secondSection offsetForNearestColumnToOffset:shiftedX];
        
        CGFloat xTarget = SLTNearestNumberToReferenceNumber(firstXTarget, secondXTarget, shiftedX) - _sectionInset.left;
        
        return CGPointMake(xTarget, proposedContentOffset.y);
    }
}


#pragma mark - Private Methods

- (void)setInitialValues {
    _needsSectionInitialization = YES;
    [self setupDefaultDimensions];
}


- (void)setupDefaultDimensions {
    _itemSize = CGSizeMake(50.f, 50.f);
    _minimumLineSpacing = 10.f;
    _interitemSpacing = 10.f;
    
    _headerReferenceHeight = 0.f;
    _footerReferenceHeight = 0.f;
    
    _headerReferenceContentWidth = 0.f;
    _footerReferenceContentWidth = 0.f;
    
    _sectionInset = UIEdgeInsetsMake(0.f, 5.f, 0.f, 5.f);
    _interSectionSpacing = 0.f;
    
    _distanceBetweenHeaderAndItems = 0.f;
    _distanceBetweenFooterAndItems = 0.f;
}


- (void)initializeSections {
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    
    _sections = [NSMutableArray arrayWithCapacity:(NSUInteger)numberOfSections];
    
    for(NSInteger index = 0; index < numberOfSections; index++) {
        SLTMetrics metrics = [self metricsForSectionAtIndex:index];
        SLTStickyLayoutSection *section = [self instantiateSectionAtIndex:index withMetrics:metrics];
        [_sections addObject:section];
    }
}


- (SLTStickyLayoutSection *)instantiateSectionAtIndex:(NSInteger)index withMetrics:(SLTMetrics)metrics {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithMetrics:metrics];
    section.sectionIndex = index;
    section.itemSize = _itemSize;
    section.minimumLineSpacing = _minimumLineSpacing;
    section.interitemSpacing = _interitemSpacing;
    section.distanceBetweenHeaderAndItems = _distanceBetweenHeaderAndItems;
    section.distanceBetweenFooterAndItems = _distanceBetweenFooterAndItems;
    section.headerInset = _sectionInset.left;

    section.numberOfItems = [self.collectionView numberOfItemsInSection:index];

    section.headerHeight = [self headerHeightForSectionAtIndex:index];
    section.footerHeight = [self footerHeightForSectionAtIndex:index];
    section.headerContentWidth = [self headerContentWidthForSectionAtIndex:index];
    section.footerContentWidth = [self footerContentWidthForSectionAtIndex:index];
    [section prepareIntermediateMetrics];
    
    return section;
}


- (CGFloat)headerHeightForSectionAtIndex:(NSInteger)sectionIndex {
    SEL selector = @selector(collectionView:layout:headerHeightInSection:);
    
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate collectionView:self.collectionView
                                      layout:self
                       headerHeightInSection:sectionIndex];
    } else {
        return _headerReferenceHeight;
    }
}


- (CGFloat)footerHeightForSectionAtIndex:(NSInteger)sectionIndex {
    SEL selector = @selector(collectionView:layout:footerHeightInSection:);
    
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate collectionView:self.collectionView
                                      layout:self
                       footerHeightInSection:sectionIndex];
    } else {
        return _footerReferenceHeight;
    }
}


- (CGFloat)headerContentWidthForSectionAtIndex:(NSInteger)sectionIndex {
    SEL selector = @selector(collectionView:layout:headerContentWidthInSection:);
    
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate collectionView:self.collectionView
                                      layout:self
                 headerContentWidthInSection:sectionIndex];
    } else {
        return _headerReferenceContentWidth;
    }
}


- (CGFloat)footerContentWidthForSectionAtIndex:(NSInteger)sectionIndex {
    SEL selector = @selector(collectionView:layout:footerContentWidthInSection:);
    
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate collectionView:self.collectionView
                                      layout:self
                 footerContentWidthInSection:sectionIndex];
    } else {
        return _footerReferenceContentWidth;
    }
}


- (NSArray *)sectionsIntersectingRect:(CGRect)rect {
    NSMutableArray *intersectingSections = [NSMutableArray array];
    
    for (SLTStickyLayoutSection *section in _sections) {
        if (CGRectIntersectsRect([section sectionRect], rect)) {
            [intersectingSections addObject:section];
        }
    }
    
    return intersectingSections;
}


- (NSRange)indexRangeOfSectionsForHorizontalOffset:(CGFloat)offset {
    CGFloat firstContentX = [_sections[0] metrics].x;
    if (offset < firstContentX) return NSMakeRange(0, 0);
    
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    
    CGFloat lastContentX = CGRectGetMaxX([[_sections lastObject] sectionRect]);
    if (offset > lastContentX) {
        return NSMakeRange((numberOfSections - 1), 0);
    }
    
    
    for (NSUInteger index = 0; index < numberOfSections - 1; index++) {
        BOOL offsetIsBetweenSections = [self isXOffset:offset
                                        betweenSection:_sections[index]
                                            andSection:_sections[index + 1]];
        if (offsetIsBetweenSections) {
            return NSMakeRange(index, 1);
        }
    }
    
    
    for (NSUInteger index = 0; index < numberOfSections; index++) {
        SLTStickyLayoutSection *section = _sections[index];
        CGRect sectionRect = [section sectionRect];
        CGPoint pointInSection = CGPointMake(offset,section.metrics.y);
        if (CGRectContainsPoint(sectionRect, pointInSection)) {
            
            if (CGRectGetMaxX(sectionRect) < (offset + _itemSize.width / 2)) {
                if (index != numberOfSections - 1) {
                    return NSMakeRange(index, 1);
                }
            }
            return NSMakeRange(index, 0);
        }
    }

    NSLog(@"SLTStickyCollectionViewLayout BUG: Optimized scrolling might not work properly");
    return NSRangeUndefined;
}


- (BOOL)isXOffset:(CGFloat)offset betweenSection:(SLTStickyLayoutSection *)firstSection andSection:(SLTStickyLayoutSection *)secondSection {
    return (offset > CGRectGetMaxX([firstSection sectionRect]) && offset < secondSection.metrics.x);
}


- (CGRect)rectWithVisibleLeftEdgeForRect:(CGRect)rect {
    return CGRectFromRectWithX(rect, self.collectionView.contentOffset.x);
}


- (BOOL)shouldOptimizeScrollingForProposedOffset:(CGPoint)proposedContentOffset {
    return (proposedContentOffset.x <= [self lastXContentOffset] - _itemSize.width / 2 - _sectionInset.right);
}


- (CGFloat)lastXContentOffset {
    return self.collectionView.contentSize.width - CGRectGetWidth(self.collectionView.bounds);
}


#pragma mark - Metrics

- (SLTMetrics)metricsForSectionAtIndex:(NSInteger)sectionIndex {
    CGSize collectionViewSize = self.collectionView.bounds.size;
    UIEdgeInsets insets = _sectionInset;
    
    CGFloat xOrigin = [self xOriginForSectionAtIndex:sectionIndex];
    CGFloat yOrigin = insets.top;
    CGFloat height = collectionViewSize.height - insets.top - insets.bottom;
    
    return SLTMetricsMake(xOrigin, yOrigin, height);
}


- (CGFloat)xOriginForSectionAtIndex:(NSInteger)sectionIndex {
    if (0 == sectionIndex) {
        return _sectionInset.left;
    } else {
        return [self lastXPosition] + [self distanceBetweenSections];
    }
}


- (CGFloat)lastXPosition {
    SLTStickyLayoutSection *section = [_sections lastObject];
    CGRect previousSectionRect = [section sectionRect];
    
    return CGRectGetMaxX(previousSectionRect);
}


- (CGFloat)distanceBetweenSections {
    return _sectionInset.right + _interSectionSpacing + _sectionInset.left;
}

@end