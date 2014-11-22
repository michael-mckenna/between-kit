//
//  I3ViewController.m
//  BetweenKit
//
//  Created by stephen fortune on 09/14/2014.
//  Copyright (c) 2014 stephen fortune. All rights reserved.
//

#import "I32RearrangeableTablesViewController.h"
#import <BetweenKit/I3GestureCoordinator.h>
#import <BetweenKit/I3BasicRenderDelegate.h>


static NSString* DequeueReusableCell = @"DequeueReusableCell";


@interface I32RearrangeableTablesViewController ()

@property (nonatomic, strong) I3GestureCoordinator *dragCoordinator;

@property (nonatomic, strong) NSMutableArray *leftData;

@property (nonatomic, strong) NSMutableArray *rightData;

@end


@implementation I32RearrangeableTablesViewController


-(void) viewDidLoad{
    
    [super viewDidLoad];

    
    /** Setup the table views with their data */

    NSArray *data = @[@1, @2, @3, @4, @5];
    self.leftData = [NSMutableArray arrayWithArray:data];
    self.rightData = [NSMutableArray arrayWithArray:data];

    [self.leftTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DequeueReusableCell];
    [self.rightTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DequeueReusableCell];
    
    self.dragCoordinator = [I3GestureCoordinator basicGestureCoordinatorFromViewController:self withCollections:@[self.leftTableView, self.rightTableView]];
    
}


-(void) didReceiveMemoryWarning{
    
    [super didReceiveMemoryWarning];

}


#pragma mark - UITableViewDataSource, UITableViewDelegate


-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0f;
};


-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section{
    
    if(tableView == self.leftTableView){
        return [self.leftData count];
    }
    else{
        return [self.rightData count];
    }
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:DequeueReusableCell
                                                            forIndexPath:indexPath];
    NSInteger row = [indexPath row];

    if(tableView == self.leftTableView){
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [self.leftData objectAtIndex:row]];
    }
    else{
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [self.rightData objectAtIndex:row]];
    }
    
    return cell;
}


#pragma mark - I3DragDataSource


-(BOOL) canItemBeDraggedAtPoint:(CGPoint) at inCollection:(id<I3Collection>) collection{
    return YES;
}


-(BOOL) canItemFromPoint:(CGPoint)from beRearrangedWithItemAtPoint:(CGPoint)to inCollection:(id<I3Collection>)collection{
    return YES;
}


-(BOOL) hidesItemWhileDraggingAtPoint:(CGPoint) at inCollection:(id<I3Collection>) collection{
    return YES;
}


-(void) rearrangeItemAtPoint:(CGPoint)from withItemAtPoint:(CGPoint)to inCollection:(id<I3Collection>)collection{
    
    UITableView *targetTableView = (UITableView *)collection.collectionView;
    
    NSIndexPath *toIndex = [targetTableView indexPathForRowAtPoint:to];
    NSIndexPath *fromIndex = [targetTableView indexPathForRowAtPoint:from];

    NSMutableArray *targetDataset = targetTableView == self.leftTableView ? self.leftData : self.rightData;
    
    [targetDataset exchangeObjectAtIndex:toIndex.row withObjectAtIndex:fromIndex.row];
    [targetTableView reloadRowsAtIndexPaths:@[toIndex, fromIndex] withRowAnimation:UITableViewRowAnimationFade];
}


-(void) dropItemAtPoint:(CGPoint) from fromCollection:(id<I3Collection>) fromCollection toPoint:(CGPoint) to inCollection:(id<I3Collection>) toCollection{

    
    UITableView *fromTable = (UITableView *)fromCollection.collectionView;
    UITableView *toTable = (UITableView *)toCollection.collectionView;
    
    NSIndexPath *toIndex = [toTable indexPathForRowAtPoint:to];
    NSIndexPath *fromIndex = [fromTable indexPathForRowAtPoint:from];
    
    
    /** Determine the `from` and `to` datasets */
    
    BOOL isFromLeftTable = fromTable == self.leftTableView;
    
    NSNumber *exchangingData = isFromLeftTable ? [self.leftData objectAtIndex:fromIndex.row] : [self.rightData objectAtIndex:fromIndex.row];
    NSMutableArray *fromDataset = isFromLeftTable ? self.leftData : self.rightData;
    NSMutableArray *toDataset = isFromLeftTable ? self.rightData : self.leftData;
    

    /** Update the data source and the individual table view rows */
    
    [fromDataset removeObjectAtIndex:fromIndex.row];
    [toDataset insertObject:exchangingData atIndex:toIndex.row];

    NSLog(@"Left data: %@", self.leftData);
    NSLog(@"Right data: %@", self.rightData);
    

    [fromTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:fromIndex.row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [toTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:toIndex.row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

}

@end
