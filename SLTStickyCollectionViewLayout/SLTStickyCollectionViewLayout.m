//
//  SLTStickyCollectionViewLayout.m
//  SLTStickyCollectionViewLayout
//
//  Created by Andrei Raifura on 4/1/15.
//  Copyright (c) 2015 YOPESO. All rights reserved.
//

#import "SLTStickyCollectionViewLayout.h"
#import "SLTStickyLayoutSection.h"

@interface SLTStickyCollectionViewLayout ()
@property (copy, nonatomic) NSArray *sections;

@end

@implementation SLTStickyCollectionViewLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupDefaultDimensions];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDefaultDimensions];
    }
    return self;
}


- (CGRect)frameForSectionAtIndex:(NSInteger)sectionIndex {
    if (sectionIndex < 0)                   return CGRectZero;
    if (sectionIndex >= [_sections count])  return CGRectZero;
    
    return [_sections[sectionIndex] sectionRect];
}


#pragma mark - Override Methods

- (void)prepareLayout {
    [super prepareLayout];
    
    NSInteger numSections = [self.collectionView numberOfSections];
    
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:numSections];
    for(NSInteger sectionNumber = 0; sectionNumber < numSections; sectionNumber++) {
        SLTMetrics metrics = (0 == sectionNumber) ? [self metricsForFirstSection] : [self metricsForSectionFollowingSection:[sections lastObject]];
        SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithMetrics:metrics];
        [self configureSection:section sectionNumber:sectionNumber];
        [sections addObject:section];
    }
    
    self.sections = sections;
}


- (CGSize)collectionViewContentSize {
    SLTStickyLayoutSection *section = [self.sections lastObject];
    CGRect lastSectionRect = [section sectionRect];
    
    CGFloat width = CGRectGetMaxX(lastSectionRect) + self.sectionInset.right;
    CGFloat height = self.collectionView.bounds.size.height;
    
    return CGSizeMake(width, height);
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSSet *sections = [self sectionsIntersectingRect:rect];
    NSArray *itemIndexPaths = [self indexPathsOfItemsInSections:sections intersectingRect:rect];
    
    NSMutableArray *itemAttributes = [NSMutableArray array];
    for (NSIndexPath *indexPath in itemIndexPaths) {
        [itemAttributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
    }
    
    NSMutableArray *attributes = [NSMutableArray arrayWithArray:itemAttributes];
    
    CGRect visibleRect = rect;
    visibleRect.origin.x = self.collectionView.contentOffset.x;
    
    for (SLTStickyLayoutSection *section in sections) {
        if ([section headerIsVisibleInRect:visibleRect]) {
            CGRect headerRect = [section headerFrameForVisibleRect:visibleRect];
            UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                      atIndexPath:[section headerIndexPath]];
            [headerAttributes setFrame:headerRect];
            [attributes addObject:headerAttributes];
        }
        
        if ([section footerIsVisibleInRect:visibleRect]) {
            CGRect footerRect = [section footerFrameForVisibleRect:visibleRect];
            UICollectionViewLayoutAttributes *footerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                                      atIndexPath:[section footerIndexPath]];
            [footerAttributes setFrame:footerRect];
            [attributes addObject:footerAttributes];
        }
    }
    
    return attributes;
}


- (NSArray *)indexPathsOfItemsInSections:(NSSet *)sections intersectingRect:(CGRect)rect {
    NSMutableArray *indexPaths = [NSMutableArray array];
    
    for (SLTStickyLayoutSection *section in sections) {
        [indexPaths addObjectsFromArray:[section indexPathsOfItemsInRect:rect]];
    }
    
    return [NSArray arrayWithArray:indexPaths];
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    SLTStickyLayoutSection *section = self.sections[indexPath.section];
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.frame = [section frameForItemAtIndex:indexPath.row];
    
    return attributes;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

//
//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset {
//    if (!_optimizedScrolling) return proposedContentOffset;
//    
//    CGFloat shiftedX = proposedContentOffset.x + _sectionInset.left;
//    
//    NSRange indexRange = [self indexRangeOfSectionsForHorizontalOffset:shiftedX];
//    if (NSRangeIsUndefined(indexRange)) return proposedContentOffset;
//    
//    BOOL indexContainsOneIndex = (0 == indexRange.length);
//    if (indexContainsOneIndex) {
//        SLTStickyLayoutSection *section = self.sections[indexRange.location];
//        CGFloat xTarget = [section offsetForNearestColumnToOffset:shiftedX] - _sectionInset.left;
//        
//        return CGPointMake(xTarget, proposedContentOffset.y);
//    } else {
//        SLTStickyLayoutSection *firstSection = self.sections[indexRange.location];
//        SLTStickyLayoutSection *secondSection = self.sections[NSMaxRange(indexRange)];
//        
//        CGFloat firstXTarget = [firstSection offsetForNearestColumnToOffset:shiftedX];
//        CGFloat secondXTarget = [secondSection offsetForNearestColumnToOffset:shiftedX];
//        
//        CGFloat xTarget = nearestNumberToReferenceNumber(firstXTarget, secondXTarget, shiftedX) - _sectionInset.left;
//        
//        return CGPointMake(xTarget, proposedContentOffset.y);
//    }
//    
//    return proposedContentOffset;
//}


- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    if (!_optimizedScrolling) return proposedContentOffset;
    
    CGFloat shiftedX = proposedContentOffset.x + _sectionInset.left;
    
    NSRange indexRange = [self indexRangeOfSectionsForHorizontalOffset:shiftedX];
    if (NSRangeIsUndefined(indexRange)) return proposedContentOffset;
    
    BOOL indexContainsOneIndex = (0 == indexRange.length);
    if (indexContainsOneIndex) {
        SLTStickyLayoutSection *section = self.sections[indexRange.location];
        CGFloat xTarget = [section offsetForNearestColumnToOffset:shiftedX] - _sectionInset.left;
        
        return CGPointMake(xTarget, proposedContentOffset.y);
    } else {
        SLTStickyLayoutSection *firstSection = self.sections[indexRange.location];
        SLTStickyLayoutSection *secondSection = self.sections[NSMaxRange(indexRange)];
        
        CGFloat firstXTarget = [firstSection offsetForNearestColumnToOffset:shiftedX];
        CGFloat secondXTarget = [secondSection offsetForNearestColumnToOffset:shiftedX];
        
        CGFloat xTarget = nearestNumberToReferenceNumber(firstXTarget, secondXTarget, shiftedX) - _sectionInset.left;
        
        return CGPointMake(xTarget, proposedContentOffset.y);
    }
}


- (NSRange)indexRangeOfSectionsForHorizontalOffset:(CGFloat)offset {
    if (offset < [self.sections[0] metrics].x) return NSMakeRange(0, 0);

    NSInteger numberOfSections = [self.collectionView numberOfSections];

    if (offset > CGRectGetMaxX([[self.sections lastObject] sectionRect])) {
        return NSMakeRange(numberOfSections - 1, 0);
    }
    
    for (NSInteger index = 0; index < numberOfSections; index++) {
        SLTStickyLayoutSection *section = self.sections[index];
        CGRect sectionRect = [section sectionRect];
        CGPoint pointInSection = CGPointMake(offset,section.metrics.y);
        if (CGRectContainsPoint(sectionRect, pointInSection)) {
            return NSMakeRange(index, 0);
        }
    }
    
    for (NSInteger index = 0; index < numberOfSections - 1; index++) {
        SLTStickyLayoutSection *section = self.sections[index];
        SLTStickyLayoutSection *nextSection = self.sections[index + 1];
        
        if (offset > section.metrics.x && offset < nextSection.metrics.x) {
            return NSMakeRange(index, 1);
        }
    }
    
    NSLog(@"SLTStickyCollectionViewLayout BUG: Optimized scrolling might not work properly");
    return NSRangeUndefined;
}


- (CGFloat)lastXOffsetThatCanBeUsedForOptimizing {
    SLTStickyLayoutSection *lastSection = [self.sections lastObject];
    CGRect bounds = self.collectionView.bounds;
    CGSize size = [self.collectionView contentSize];
    CGFloat x = CGRectGetMaxX(bounds) - size.width;
    CGFloat shiftedX = x + _sectionInset.left;

    CGFloat targetX = [lastSection offsetForNearestColumnToOffset:shiftedX];
    if (targetX <= shiftedX) return targetX - _sectionInset.left;
    return 0;
}


#pragma mark - Private Methods

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


- (void)configureSection:(SLTStickyLayoutSection *)section sectionNumber:(NSInteger)sectionNumber {
    section.sectionNumber = sectionNumber;
    section.numberOfCells = [self.collectionView numberOfItemsInSection:sectionNumber];
    section.itemSize = _itemSize;
    section.minimumLineSpacing = _minimumLineSpacing;
    section.minimumInteritemSpacing = _interitemSpacing;
    section.distanceBetweenHeaderAndCells = _distanceBetweenHeaderAndItems;
    section.distanceBetweenFooterAndCells = _distanceBetweenFooterAndItems;
    section.headerHeight = [self headerHeightForSectionWithSectionNumber:sectionNumber];
    section.footerHeight = [self footerHeightForSectionWithSectionNumber:sectionNumber];
    section.headerContentWidth = [self headerContentWidthForSectionWithSectionNumber:sectionNumber];
    section.footerContentWidth = [self footerContentWidthForSectionWithSectionNumber:sectionNumber];
    section.headerInset = _sectionInset.left;
    [section prepareIntermediateMetrics];
}


- (CGFloat)headerHeightForSectionWithSectionNumber:(NSInteger)sectionNumber {
    SEL selector = @selector(collectionView:layout:headerHeightInSection:);
    
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate collectionView:self.collectionView
                                      layout:self
                       headerHeightInSection:sectionNumber];
    } else {
        return _headerReferenceHeight;
    }
}


- (CGFloat)footerHeightForSectionWithSectionNumber:(NSInteger)sectionNumber {
    SEL selector = @selector(collectionView:layout:footerHeightInSection:);
    
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate collectionView:self.collectionView
                                      layout:self
                       footerHeightInSection:sectionNumber];
    } else {
        return _footerReferenceHeight;
    }
}


- (CGFloat)headerContentWidthForSectionWithSectionNumber:(NSInteger)sectionNumber {
    SEL selector = @selector(collectionView:layout:headerContentWidthInSection:);
    
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate collectionView:self.collectionView
                                      layout:self
                 headerContentWidthInSection:sectionNumber];
    } else {
        return _headerReferenceContentWidth;
    }
}


- (CGFloat)footerContentWidthForSectionWithSectionNumber:(NSInteger)sectionNumber {
    SEL selector = @selector(collectionView:layout:footerContentWidthInSection:);
    
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate collectionView:self.collectionView
                                      layout:self
                 footerContentWidthInSection:sectionNumber];
    } else {
        return _footerReferenceContentWidth;
    }
}


- (SLTMetrics)metricsForFirstSection {
    CGSize collectionViewSize = self.collectionView.bounds.size;
    UIEdgeInsets insets = self.sectionInset;
    
    CGFloat xOrigin = insets.left;
    CGFloat yOrigin = insets.top;
    CGFloat height = collectionViewSize.height - insets.top - insets.bottom;
    
    return SLTMetricsMake(xOrigin, yOrigin, height);
}


- (SLTMetrics)metricsForSectionFollowingSection:(SLTStickyLayoutSection *)section {
    CGRect previousSectionRect = [section sectionRect];
    
    CGSize collectionViewSize = self.collectionView.bounds.size;
    UIEdgeInsets insets = self.sectionInset;
    
    CGFloat lastXPosition = CGRectGetMaxX(previousSectionRect);
    CGFloat xOrigin = lastXPosition + [self distanceBetweenSections];
    CGFloat yOrigin = insets.top;
    CGFloat height = collectionViewSize.height - insets.top - insets.bottom;
    
    return SLTMetricsMake(xOrigin, yOrigin, height);
}


- (NSSet *)sectionsIntersectingRect:(CGRect)rect {
    NSMutableSet *intersectingSections = [[NSMutableSet alloc] init];
    
    for (SLTStickyLayoutSection *section in self.sections) {
        if (CGRectIntersectsRect([section sectionRect], rect)) {
            [intersectingSections addObject:section];
        }
    }
    
    return [NSSet setWithSet:intersectingSections];
}


- (CGFloat)distanceBetweenSections {
    return _sectionInset.right + self.interSectionSpacing + _sectionInset.left;
}

@end