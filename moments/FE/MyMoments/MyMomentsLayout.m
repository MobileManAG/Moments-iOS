/*******************************************************************************
 * Copyright 2015 MobileMan GmbH
 * www.mobileman.com
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

//
//  MyMomentsLayout.m
//  moments
//
//  Created by MobileMan GmbH on 30/05/15.
//  Copyright (c) 2015 MobileMan GmbH. All rights reserved.
//

#import "MyMomentsLayout.h"
#import "fe_defines.h"

@implementation MyMomentsLayout

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.minimumLineSpacing = 5.0;
        self.minimumInteritemSpacing = 5.0;
    }
    return self;
}

- (int) numberOfItemsPerRow
{
    int result = 1;
    
    if (IS_IPAD) {
        result = 3;
    }
    
    return result;
}

- (void)prepareLayout
{
    [super prepareLayout];
    
    if (self.collectionView) {
        CGSize newItemSize = self.itemSize;
        int itemsPerRow = MAX([self numberOfItemsPerRow], 1);
        CGFloat totalSpacing = self.minimumInteritemSpacing * (itemsPerRow - 1.0);
        CGFloat collectionViewWidth = self.collectionView.bounds.size.width;
        newItemSize.width = (collectionViewWidth - totalSpacing)/itemsPerRow;
        
        if (self.itemSize.height > 0) {
            CGFloat itemAspectRatio = self.itemSize.width/self.itemSize.height;
            newItemSize.height = newItemSize.width/itemAspectRatio;
        }
        
        self.itemSize = newItemSize;
    }
}

@end
