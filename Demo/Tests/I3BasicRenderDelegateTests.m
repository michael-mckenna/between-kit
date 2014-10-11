//
//  I3GestureCoordinatorTests.m
//  BetweenKit
//
//  Created by Stephen Fortune on 14/09/2014.
//  Copyright (c) 2014 stephen fortune. All rights reserved.
//

#import <BetweenKit/I3BasicRenderDelegate.h>
#import <BetweenKit/I3CloneView.h>


/// @todo What happens if any of these render delegate methods are called in the incorrect
//        order? For example, how will the class cope if a user erroneously makes a call
//        to `renderDropOnCollection:atPoint:fromCoordinator` ?
SpecBegin(I3BasicRenderDelegate)


    __block I3BasicRenderDelegate *renderDelegate;
    __block UIView *superview;
    __block id coordinator;
    __block id arena;
    __block id gestureRecognizer;
    __block id currentDraggingCollection;
    __block id currentDragDataSource;
    __block UIView *draggingItem;
    __block UIView *collectionView;
    CGPoint touchPoint = CGPointMake(10, 10);


    beforeEach(^{
        
        renderDelegate = [[I3BasicRenderDelegate alloc] init];
        coordinator = OCMClassMock([I3GestureCoordinator class]);
        arena = OCMClassMock([I3DragArena class]);
        superview = OCMPartialMock([[UIView alloc] init]);
        currentDraggingCollection = OCMProtocolMock(@protocol(I3Collection));
        currentDragDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
        draggingItem = [[UIView alloc] init];
        collectionView = [[UIView alloc] init];
        gestureRecognizer = OCMClassMock([UIPanGestureRecognizer class]);
        
        OCMStub([arena superview]).andReturn(superview);
        OCMStub([coordinator arena]).andReturn(arena);
        OCMStub([currentDraggingCollection itemAtPoint:touchPoint]).andReturn(draggingItem);
        OCMStub([currentDraggingCollection collectionView]).andReturn(collectionView);
        OCMStub([currentDraggingCollection dragDataSource]).andReturn(currentDragDataSource);
        OCMStub([coordinator currentDragOrigin]).andReturn(touchPoint);
        OCMStub([coordinator currentDraggingCollection]).andReturn(currentDraggingCollection);
        OCMStub([coordinator gestureRecognizer]).andReturn(gestureRecognizer);
        
    });

    afterEach(^{
    
        renderDelegate = nil;
        coordinator = nil;
        arena = nil;
        currentDraggingCollection = nil;
        draggingItem = nil;
        gestureRecognizer = nil;
        currentDragDataSource = nil;
        
    });


    describe(@"rendering", ^{

        
        describe(@"begin drag", ^{
        
            
            it(@"should construct a dragging view from an item in the dragging collection on start", ^{
                
                CGRect convertedRect = CGRectMake(100, 100, 100, 100);
                OCMStub([superview convertRect:draggingItem.frame fromView:collectionView]).andReturn(convertedRect);
                
                [renderDelegate renderDragStart:coordinator];
                
                expect(renderDelegate.draggingView).to.beInstanceOf([I3CloneView class]);
                expect(renderDelegate.draggingView.sourceView).to.equal(draggingItem);
                expect([renderDelegate.draggingView.superview isEqual:superview]).to.beTruthy;
                expect(renderDelegate.draggingView.frame).to.equal(convertedRect);
                
                OCMVerify([superview convertRect:draggingItem.frame fromView:collectionView]);
                
            });

            
            it(@"should hide the original item if required by the datasource", ^{
            
                OCMStub([currentDragDataSource hidesItemWhileDraggingAtPoint:touchPoint inCollection:currentDraggingCollection]).andReturn(YES);
                
                [renderDelegate renderDragStart:coordinator];
                
                expect(draggingItem.alpha).to.equal(0.01f);
                OCMVerify([currentDragDataSource hidesItemWhileDraggingAtPoint:touchPoint inCollection:currentDraggingCollection]);
                
            });
            
            it(@"should not hide the original item if specified by the datasource", ^{
                
                OCMStub([currentDragDataSource hidesItemWhileDraggingAtPoint:touchPoint inCollection:currentDraggingCollection]).andReturn(NO);
                
                [renderDelegate renderDragStart:coordinator];
                
                expect(draggingItem.alpha).notTo.equal(0.01f);
                OCMVerify([currentDragDataSource hidesItemWhileDraggingAtPoint:touchPoint inCollection:currentDraggingCollection]);
                
            });
            
        });
        
        describe(@"dragging", ^{
        
            
            it(@"should translate the current dragging view and then reset the recognizer's translation", ^{
                
                CGPoint translation = CGPointMake(5, 5);
                [renderDelegate renderDragStart:coordinator];
                [renderDelegate.draggingView setCenter:CGPointMake(50, 50)];
                
                OCMStub([gestureRecognizer translationInView:superview]).andReturn(translation);
                
                [renderDelegate renderDraggingFromCoordinator:coordinator];
                
                expect(renderDelegate.draggingView.center).to.equal(CGPointMake(55, 55));
                
            });
        
        });
        
        describe(@"reset from point", ^{

            it(@"should release strong reference to the dragging view, whilst animating it back to the origin in an async animation", ^{
                
                [renderDelegate renderDragStart:coordinator];
                
                UIView *draggingView = renderDelegate.draggingView;
                CGPoint resetPoint = CGPointMake(25, 25);
                CGRect resetRect = CGRectMake(0, 0, 100, 100);
                
                id uiViewMock = OCMClassMock([UIView class]);
                OCMStub([superview convertRect:draggingItem.frame fromView:collectionView]).andReturn(resetRect);
                OCMStub([uiViewMock animateWithDuration:0.15 animations:[OCMArg any] completion:[OCMArg any]]).andDo(^(NSInvocation *invocation){
                    
                    void (^animateBlock)();
                    void (^completionBlock)();
                    
                    [invocation getArgument:&animateBlock atIndex:3];
                    [invocation getArgument:&completionBlock atIndex:4];
                    
                    animateBlock();
                    completionBlock();

                    expect(draggingView.frame).to.equal(resetRect);
                    expect(draggingView.superview).to.beNil();

                });
                
                [renderDelegate renderResetFromPoint:resetPoint fromCoordinator:coordinator];
                
                expect(renderDelegate.draggingView).to.beNil();
                OCMVerify([uiViewMock animateWithDuration:0.15 animations:[OCMArg any] completion:[OCMArg any]]);
                
                [uiViewMock stopMocking];
                
            });
            
        });
        
        
        describe(@"drop on another collection", ^{

            it(@"should release reference to dragging view and remove it from superview on exchange between collections", ^{
                
                [renderDelegate renderDragStart:coordinator];
                id dstCollection = OCMProtocolMock(@protocol(I3Collection));
                
                [renderDelegate renderDropOnCollection:dstCollection atPoint:CGPointMake(0, 0) fromCoordinator:coordinator];
                
                expect([superview.subviews containsObject:renderDelegate.draggingView]).to.beFalsy;
                expect(renderDelegate.draggingView).to.beNil();
                
            });

            it(@"should re-show the hidden item in the collection if specified by the data source", ^{
            
                id dstCollection = OCMProtocolMock(@protocol(I3Collection));
                OCMStub([currentDragDataSource hidesItemWhileDraggingAtPoint:touchPoint inCollection:currentDraggingCollection]).andReturn(YES);
                [[currentDraggingCollection reject] itemAtPoint:touchPoint];

                
                [renderDelegate renderDropOnCollection:dstCollection atPoint:CGPointMake(0, 0) fromCoordinator:coordinator];

                expect(draggingItem.alpha).to.equal(1);
                OCMVerify([currentDragDataSource hidesItemWhileDraggingAtPoint:touchPoint inCollection:currentDraggingCollection]);
                
            });
            
            
            it(@"should not attempt to 'un-hide' the item in the collection if not specified by the data source", ^{
                
                id dstCollection = OCMProtocolMock(@protocol(I3Collection));
                OCMStub([currentDragDataSource hidesItemWhileDraggingAtPoint:touchPoint inCollection:currentDraggingCollection]).andReturn(NO);
                [[currentDraggingCollection reject] itemAtPoint:touchPoint];
                
                [renderDelegate renderDropOnCollection:dstCollection atPoint:CGPointMake(0, 0) fromCoordinator:coordinator];

                expect(draggingItem.alpha).to.equal(1);
                OCMVerify([currentDragDataSource hidesItemWhileDraggingAtPoint:touchPoint inCollection:currentDraggingCollection]);
            
            });
            
        });
        
        describe(@"rearrange", ^{
        
            /*it(@"should animate an exchange between the dragging view and the destination item", ^{
            
                /// @todo Employ this mocking technique to mock animations in the reset test as well

                [renderDelegate renderDragStart:coordinator];
                UIView *draggingView = renderDelegate.draggingView;
                
                id uiViewMock = OCMClassMock([UIView class]);
                CGFloat duration = 0.15;
                
                OCMStub([uiViewMock animateWithDuration:duration animations:[OCMArg any] completion:[OCMArg any]]).andDo(^(NSInvocation *invocation){
                
                    void (^animateBlock)();
                    void (^completionBlock)();
                    
                    [invocation getArgument:&animateBlock atIndex:1];
                    [invocation getArgument:&completionBlock atIndex:2];
                    
                    animateBlock();
                    
                    /// @todo Expect deduce the exchangeView from the superview
                    /// @todo Expect the draggingView frame to be the dst view's frame in the superview
                    /// @todo Expect the exchangeView frame to be the source view's frame in the superview
                    
                    completionBlock();
                    
                    /// @todo Expect draggingView and exchangeView to be removed from the superview
                });
                
                
                /// @todo Expect draggingView to be nil
                /// @todo Expect draggingView still to be a subview of the superview
                
                OCMVerify([uiViewMock animateWithDuration:duration animations:[OCMArg any] completion:[OCMArg any]]);
                
                [uiViewMock stopMocking];
                
            });*/
            
        });
        
    });


SpecEnd
