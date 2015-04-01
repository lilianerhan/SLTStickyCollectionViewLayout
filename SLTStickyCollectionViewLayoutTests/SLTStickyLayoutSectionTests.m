//
//  TitledCollectionViewSectionTests.m
//  TestHorizontalCollectionView
//
//  Created by thelvis on 3/3/15.
//  Copyright (c) 2015 Yopeso. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SLTStickyLayoutSection.h"

@interface SLTStickyLayoutSectionTests : XCTestCase

@end

@implementation SLTStickyLayoutSectionTests

- (void)testSectionWidthOnlyCells {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(0, 0, 0, 50)];
    section.numberOfCells = 14;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    section.distanceBetweenHeaderAndCells = 0.f;
    section.distanceBetweenFooterAndCells = 0.f;
    
    section.headerHeight = 0.f;
    section.footerHeight = 0.f;
    
    section.headerContentWidth = 0.f;
    section.footerContentWidth = 0.f;
    [section prepareIntermediateMetrics];
    
    XCTAssertEqual([section sectionWidth], 170.f, @"The section width is not calculated correctly");
}


- (void)testSectionWidthFooter {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(0, 0, 0, 50)];
    section.numberOfCells = 14;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 0.f;
    section.distanceBetweenFooterAndCells = 10.f;
    
    section.headerHeight = 0.f;
    section.footerHeight = 10.f;
    
    section.headerContentWidth = 0.f;
    section.footerContentWidth = 0.f;
    [section prepareIntermediateMetrics];
    
    XCTAssertEqual([section sectionWidth], 240.f, @"The section width is not calculated correctly");
}


- (void)testSectionWidthHeader {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(0, 0, 0, 50)];
    section.numberOfCells = 14;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 10.f;
    section.distanceBetweenFooterAndCells = 0.f;
    
    section.headerHeight = 5.f;
    section.footerHeight = 0.f;
    
    section.headerContentWidth = 0.f;
    section.footerContentWidth = 0.f;
    [section prepareIntermediateMetrics];
    
    XCTAssertEqual([section sectionWidth], 240.f, @"The section width is not calculated correctly");
}

- (void)testSectionWidthHeaderAndFooter {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(0, 0, 0, 60)];
    section.numberOfCells = 14;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 10.f;
    section.distanceBetweenFooterAndCells = 10.f;
    
    section.headerHeight = 5.f;
    section.footerHeight = 5.f;
    
    section.headerContentWidth = 0.f;
    section.footerContentWidth = 0.f;
    [section prepareIntermediateMetrics];
    
    XCTAssertEqual([section sectionWidth], 240.f, @"The section width is not calculated correctly");
}

- (void)testSectionWidthBigHeader{
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(0, 0, 0, 60)];
    section.numberOfCells = 1;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 10.f;
    section.distanceBetweenFooterAndCells = 10.f;
    
    section.headerHeight = 5.f;
    section.footerHeight = 5.f;
    
    section.headerContentWidth = 120.f;
    section.footerContentWidth = 0.f;
    [section prepareIntermediateMetrics];
    
    XCTAssertEqual([section sectionWidth], section.headerContentWidth, @"The section width is not calculated correctly");
}

- (void)testSectionWidthBigFooter{
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(0, 0, 0, 60)];
    section.numberOfCells = 1;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 10.f;
    section.distanceBetweenFooterAndCells = 10.f;
    
    section.headerHeight = 5.f;
    section.footerHeight = 5.f;
    
    section.headerContentWidth = 0.f;
    section.footerContentWidth = 120.f;
    [section prepareIntermediateMetrics];
    
    XCTAssertEqual([section sectionWidth], section.footerContentWidth, @"The section width is not calculated correctly");
}


- (void)testItemFrameCalculus {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(0, 0, 0, 100)];
    section.numberOfCells = 14;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 10.f;
    section.distanceBetweenFooterAndCells = 10.f;
    
    section.headerHeight = 5.f;
    section.footerHeight = 5.f;
    
    section.headerContentWidth = 0.f;
    section.footerContentWidth = 120.f;
    [section prepareIntermediateMetrics];
    
    CGRect itemFrame = [section frameForItemAtIndex:6];
    CGRect expectedFrame = CGRectMake(35, 30, 30, 10);
    XCTAssertTrue(CGRectEqualToRect(itemFrame, expectedFrame), @"The Item frame is not calculated correctly");
}


- (void)testHeaderFrameWhenVisibleRectIsNotShowingHeader {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(10, 0, 0, 100)];
    section.numberOfCells = 14;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 10.f;
    section.distanceBetweenFooterAndCells = 10.f;
    
    section.headerHeight = 5.f;
    
    section.headerContentWidth = 30.f;
    [section prepareIntermediateMetrics];
    
    CGRect headerRect = [section headerFrameForVisibleRect:CGRectMake(140, 20, 10, 10)];
    XCTAssertEqual(headerRect.origin.x, 10, @"Should return initial frame if visible Rect is out of section header");
}

- (void)testHeaderFrameWhenVisibleRectHasOffset {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(10, 0, 0, 100)];
    section.numberOfCells = 14;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 10.f;
    section.distanceBetweenFooterAndCells = 10.f;
    
    section.headerHeight = 5.f;
    
    section.headerContentWidth = 30.f;
    [section prepareIntermediateMetrics];
    
    CGRect expectedRect = CGRectMake(20, 0.f, 30.f, 5.f);
    
    __block CGRect headerRect;
    [self measureBlock:^{
        headerRect = [section headerFrameForVisibleRect:CGRectMake(20, 0, 100, 30)];
    }];
    
    XCTAssertTrue(CGRectEqualToRect(headerRect, expectedRect), @"Should return initial frame if visible Rect is out of section header");
}

- (void)testHeaderFrameWhenSectionEnds {
    SLTStickyLayoutSection *section = [[SLTStickyLayoutSection alloc] initWithSectionRect:CGRectMake(10, 0, 0, 100)];
    section.numberOfCells = 14;
    section.itemSize = CGSizeMake(30, 10);
    section.minimumLineSpacing = 5.f;
    section.minimumInteritemSpacing = 5.f;
    
    section.distanceBetweenHeaderAndCells = 10.f;
    section.distanceBetweenFooterAndCells = 10.f;
    
    section.headerHeight = 5.f;
    
    section.headerContentWidth = 30.f;
    [section prepareIntermediateMetrics];
    
    CGRect expectedRect = CGRectMake([section sectionWidth]+10-section.headerContentWidth, 0.f, 30.f, 5.f);
    
    __block CGRect headerRect;
    [self measureBlock:^{
        headerRect = [section headerFrameForVisibleRect:CGRectMake([section sectionWidth]-10, 0, 100, 30)];
    }];
    
    XCTAssertTrue(CGRectEqualToRect(headerRect, expectedRect), @"Should return initial frame if visible Rect is out of section header");
}

@end