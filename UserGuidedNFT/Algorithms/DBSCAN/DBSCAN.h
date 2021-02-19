//
//  DBSCAN.h
//  Density-Based Spatial Clustering of Applications with Noise
//  基于密度的聚类算法
//  Created by RealCloud on 14-7-24.
//  Copyright (c) 2014年 Real Cloud. All rights reserved.
//

// DBSCAN Algorithm
// Sources:
//   - https://github.com/Sinkup/DBSCAN
//   - https://dl.acm.org/doi/10.1145/3068335

#import <Foundation/Foundation.h>

typedef float(^distanceCalculator)(id obj1, id obj2);

@interface DBSCAN : NSObject//NSOperation

/**
 *  噪声点
 */
@property (atomic, strong, readonly) NSArray *noisePoints;

/**
 *  被聚类的点
 */
//@property (nonatomic, strong, readonly) NSArray *clusteredPoints;

/**
 *  聚类后的结果
 */
//@property (nonatomic, strong, readonly) NSArray *clusters;

/**
 *  初始化
 *
 *  @param radius 扫描半径
 *  @param minPts 扫描半径最小应包含的点数
 *  @param block  距离计算block
 *
 *  @return 对象实例
 */
- (id)initWithRadius:(float)radius minNumberOfPointsInCluster:(int)minPts andDistanceCalculator:(distanceCalculator)block;

/**
 *  聚类传入的点集合并返回聚类后的结果
 *
 *  @param points 要聚类的点集合
 *
 *  @return 聚类后的结果，不包括噪声点
 */
- (NSArray *)clustersFromPoints:(NSArray *)points;

//- (void)reset;

@end
