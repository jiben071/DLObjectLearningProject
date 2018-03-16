//
//  RVMViewModelSpec.m
//  DLObjectLearningProject
//
//  Created by denglong on 14/03/2018.
//Copyright © 2018 long deng. All rights reserved.
//  该示例存在于ReactiveViewModel开源项目中（值得学习）

//为了让这两个@import可用：
//总结：统一整个项目的Swift版本，引起引入不对的根本原因是swift版本没有统一

//以下方式仅为建议，统一swift版本方为根本出路
//1.尝试了使用xcode8.3进行swift转化
//2.配置setting  Defines Module 参考链接：http://blog.csdn.net/u010407865/article/details/62886943
//3.Podfinle文件中使用了 use_frameworks!
//4.使用了Nimble-Swift.h Quick-Swift.h的方式先导入，然后屏蔽
@import Quick;
@import Nimble;

#import <ReactiveObjC/ReactiveObjC.h>

#import "ReactiveViewModel.h"
#import "RVMTestViewModel.h"


//关键，如果第三方库是swift文件，必须导入以下文件
//#import <Quick/Quick.h>
//#import <Nimble/Nimble.h>
//#import "Nimble-Swift.h"
//#import "Quick-Swift.h"


QuickSpecBegin(RVMViewModelSpec)
__block RVMTestViewModel *viewModel;

beforeEach(^{
    viewModel = [[RVMTestViewModel alloc] init];
});

describe(@"active property", ^{
    it(@"should default to NO",^{
        //https://stackoverflow.com/questions/46338588/xcode-9-swift-language-version-swift-version
        expect(@(viewModel.active)).to(beFalsy());//这里报错的根本原因是源码的swift版本不兼容(没有统一)，没有引入-Swift.h文件
    });
    
    it(@"should send on didBecomeActiveSignal when set to YES",^{
        __block NSUInteger nextEvents = 0;
        [viewModel.didBecomeActiveSignal subscribeNext:^(RVMViewModel  *_Nullable viewModel) {
            expect(viewModel).to(beIdenticalTo(viewModel));
            expect(viewModel.active).to(beTruthy());
            nextEvents++;
        }];
        
        expect(@(nextEvents)).to(equal(@0));
        
        viewModel.active = YES;
        expect(@(nextEvents)).to(equal(@1));
        
        //Indistinct changes should not trigger the signal again.
        viewModel.active = NO;
        viewModel.active = YES;
        expect(@(nextEvents)).to(equal(@2));
    });
    
    it(@"should send on didBecomeInactiveSignal when set to NO",^{
        __block NSUInteger nextEvents = 0;
        [viewModel.didBecomeInactiveSignal subscribeNext:^(RVMViewModel *_Nullable viewModel) {
            expect(viewModel).to(beIdenticalTo(viewModel));
            expect(@(viewModel.active)).to(beFalsy());
            nextEvents++;
        }];
        expect(@(nextEvents)).to(equal(@1));
        
        viewModel.active = YES;
        viewModel.active = NO;
        expect(@(nextEvents)).to(equal(@2));
        
        //Indistinct changes should not trigger the signal again.
        viewModel.active = NO;
        expect(@(nextEvents)).to(equal(@2));
    });
    
    describe(@"signal manipulation", ^{
        __block NSMutableArray *values;
        __block NSArray *expectedValues;
        __block BOOL completed;
        __block BOOL deallocated;
        
        __block RVMTestViewModel * (^createViewModel)(void);
        
        beforeEach(^{
            values = [NSMutableArray array];
            expectedValues = @[];
            completed = NO;
            deallocated = NO;
            
            createViewModel = ^{
                RVMTestViewModel *viewModel = [[RVMTestViewModel alloc] init];
                [viewModel.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
                    deallocated = YES;
                }]];
                
                viewModel.active = YES;
                return viewModel;
            };
        });
        
        afterEach(^{
            expect(@(deallocated)).toEventually(beTruthy());
            expect(@(completed)).to(beTruthy());
        });
        
        it(@"should forward a signal",^{
            @autoreleasepool {
                RVMTestViewModel *viewModel __attribute__((objc_precise_lifetime)) = createViewModel();
                
                RACSignal *input = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                    [subscriber sendNext:@1];
                    [subscriber sendNext:@2];
                    return nil;
                }];
                
                [[viewModel forwardSignalWhileActive:input] subscribeNext:^(id  _Nullable x) {
                    [values addObject:x];
                } completed:^{
                    completed = YES;
                }];
                
                expectedValues = @[@1,@2];
                expect(values).to(equal(expectedValues));
                expect(@(completed)).to(beFalsy());
                
                viewModel.active = NO;
                
                expect(values).to(equal(expectedValues));
                expect(@(completed)).to(beFalsy());
                
                viewModel.active = YES;
                
                expectedValues = @[@1,@2,@1,@2];
                expect(values).to(equal(expectedValues));
                expect(@(completed)).to(beFalsy());
            }
        });
        
        it(@"should throttle a signal",^{
            @autoreleasepool {
                RVMTestViewModel *viewModel __attribute__((objc_precise_lifetime)) = createViewModel();
                RACSubject *subject = [RACSubject subject];
                
                [[viewModel throttleSignalWhileInactive:[subject startWith:@0]]subscribeNext:^(id  _Nullable x) {
                    [values addObject:x];
                } completed:^{
                    completed = YES;
                }];
                
                expectedValues = @[@0];
                expect(values).to(equal(expectedValues));
                expect(@(completed)).to(beFalsy());
                
                [subject sendNext:@1];
                
                expectedValues = @[@0,@1];
                expect(values).to(equal(expectedValues));
                expect(@(completed)).to(beFalsy());
                
                viewModel.active = NO;
                
                //Since the VM is inactive,these events should be throttled
                [subject sendNext:@2];
                [subject sendNext:@3];
                
                expect(values).to(equal(expectedValues));
                expect(@(completed)).to(beFalsy());
                
                expectedValues = @[@0,@1,@3];
                // FIXME: Nimble doesn't support custom timeouts right now, and
                // our operation may take longer than 1 second (the default
                // timeout), sooo... trololo
                [NSThread sleepForTimeInterval:1];
                
                expect(values).toEventually(equal(expectedValues));
                expect(@(completed)).to(beFalsy());
                
                //After reactivating,we should still get this event.
                [subject sendNext:@4];
                viewModel.active = YES;
                
                expectedValues = @[@0,@1,@3,@4];
                expect(values).toEventually(equal(expectedValues));
                expect(@(completed)).to(beFalsy());
                
                // And now new events should be instant.
                [subject sendNext:@5];
                
                expectedValues = @[@0,@1,@3,@4,@5];
                expect(values).to(beFalsy());
                
                [subject sendCompleted];
                
                expect(values).to(equal(expectedValues));
                expect(@(completed)).to(beTruthy());
                
            }
        });
        
    });
    
    
});






QuickSpecEnd
