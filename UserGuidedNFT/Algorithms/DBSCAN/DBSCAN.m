//
//  DBSCAN.m
//  LoochaCampusMain
//
//  Created by RealCloud on 14-7-24.
//  Copyright (c) 2014年 Real Cloud. All rights reserved.
//

// DBSCAN Algorithm
// Sources:
//   - https://github.com/Sinkup/DBSCAN
//   - https://dl.acm.org/doi/10.1145/3068335

#import "DBSCAN.h"

@interface DBSCAN ()

@property (nonatomic      ) float              radius;
@property (nonatomic      ) int                minPts;
@property (nonatomic, copy) distanceCalculator distanceBlock;

@property (nonatomic, strong) NSArray        *points;
@property (nonatomic, strong) NSMutableSet *visitedPoints;

@property (atomic, strong, readwrite) NSArray *noisePoints;
@property (nonatomic, strong, readwrite) NSMutableSet *clusteredPoints;
@property (atomic) NSUInteger clusterOperationID;

//@property (nonatomic, strong, readwrite) NSArray *clusters;

//@property (nonatomic, strong) id lock;

@end

@implementation DBSCAN

- (void)dealloc
{
    self.distanceBlock = nil;
}

- (id)initWithRadius:(float)radius minNumberOfPointsInCluster:(int)minPts andDistanceCalculator:(distanceCalculator)block
{
    self = [super init];
    if (self) {
        self.radius = radius;
        self.minPts = minPts - 1;
        self.distanceBlock = block;
    }
    
    return self;
}

- (NSArray *)clustersFromPoints:(NSArray *)points
{
    NSMutableArray *clusters = nil;
    
    {
        self.visitedPoints = [NSMutableSet setWithCapacity:points.count];
        NSMutableArray *noisePoints = [NSMutableArray array];
        self.clusteredPoints = [NSMutableSet set];
        
        self.points = points;
        
        clusters = [NSMutableArray array];
        
        //遍历集合中未被访问过的点
        for (NSInteger i = 0; i < points.count; i++) {
            if (self.visitedPoints.count == points.count) {
                break;
            }
            
            id current = [points objectAtIndex:i];
            if ([self.visitedPoints containsObject:current]) {
                continue;
            }
            
            [self.visitedPoints addObject:current];
            
            NSMutableArray *arr = [self getNeighbours:i];
            if (arr.count < self.minPts) {
                [noisePoints addObject:current];
            } else {
                NSArray *cluster = [self ExpandClusterForPoint:current withNeighbourIndexes:arr];
                [clusters addObject:cluster];
            }
        }
        
        self.clusteredPoints = nil;
        self.visitedPoints = nil;
        self.points = nil;
        self.noisePoints = noisePoints;
    }
        
    return clusters;
}

/**
 *  查找集合中某一点周围半径内的点
 *
 *  @param theIndex 在points中的索引
 *
 *  @return 半径内所有的点
 */
- (NSMutableArray *)getNeighbours:(NSInteger)theIndex
{
    NSMutableArray *arr = [NSMutableArray array];
    for (NSInteger index = 0; index < self.points.count; index++) {
        if (theIndex == index) {
            continue;
        }
        
        id thePoint = self.points[theIndex];
        id point = self.points[index];
        float distance = self.distanceBlock(thePoint, point);
        if (distance < self.radius) {
            [arr addObject:[NSNumber numberWithInteger:index]];
        }
    }
    
    return arr;
}


- (NSArray *)ExpandClusterForPoint:(id)point withNeighbourIndexes:(NSMutableArray *)neighbourIndexes
{
    NSMutableArray *cluster = [NSMutableArray array];
    [cluster addObject:point];
    [self.clusteredPoints addObject:point];
    
    NSMutableSet *neighbourSet = [NSMutableSet setWithArray:neighbourIndexes];
    for (NSInteger index = 0; index < neighbourIndexes.count; index++) {
        NSInteger currentIndex = [neighbourIndexes[index] integerValue];
        id currentPoint = self.points[currentIndex];
        if (![self.visitedPoints containsObject:currentPoint]) {
            [self.visitedPoints addObject:currentPoint];
            
            NSArray *arr = [self getNeighbours:currentIndex];
            if (arr.count >= self.minPts) {
                [self merge:neighbourIndexes with:arr neighbourSet:neighbourSet];
            }
        }
        
        if (![self.clusteredPoints containsObject:currentPoint]) {
            [cluster addObject:currentPoint];
            [self.clusteredPoints addObject:currentPoint];
        }
    }
    
    return cluster;
}

- (void)merge:(NSMutableArray *)currentNeighbors with:(NSArray *)newNeighbors neighbourSet:(NSMutableSet *)neighbourSet {
    for (NSNumber *p in newNeighbors) {
        if (![neighbourSet containsObject:p]) {
            [currentNeighbors addObject:p];
            [neighbourSet addObject:p];
        }
    }
}

@end
