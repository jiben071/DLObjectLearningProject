//
//  DLMVVMTestThreeViewController.m
//  DLObjectLearningProject
//
//  Created by denglong on 13/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//  http://www.cocoachina.com/industry/20140609/8737.html

/*
 MVVM是Model-View-ViewModel的简称，它们之间的关系如下
 
 可以看到View(其实是ViewController)持有ViewModel，这样做的好处是ViewModel更加独立且可测试，ViewModel里不应包含任何View相关的元素，哪怕换了一个View也能正常工作。而且这样也能让View/ViewController「瘦」下来。
 
 ViewModel主要做的事情是作为View的数据源，所以通常会包含网络请求。
 
 或许你会疑惑，ViewController哪去了？在MVVM的世界里，ViewController已经成为了View的一部分。它的主要职责是将VM与View绑定、响应VM数据的变化、调用VM的某个方法、与其他的VC打交道。
 
 而RAC为MVVM带来很大的便利，比如RACCommand, UIKit的RAC Extension等等。使用MVVM不一定能减少代码量，但能降低代码的复杂度。
 */


/*
 以下面这个需求为例，要求大图滑动结束时，底部的缩略图滚动到对应的位置，并高亮该缩略图；同时底部的缩略图被选中时，大图也要变成该缩略图的大图。
 */

#import "DLMVVMTestThreeViewController.h"

@interface DLMVVMTestThreeViewController ()

@end

@implementation DLMVVMTestThreeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
/*
// PinsViewController.m
- (void)viewDidLoad
{
    [super viewDidLoad];
    @weakify(self);
    [[RACObserve(self, viewModel.indexPath)
      skip:1]
     subscribeNext:^(NSIndexPath *indexPath) {
         @strongify(self);
         [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
     }];
}
 */

@end


/*
// childVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    @weakify(self);
    [RACObserve(self, viewModel.indexPath) subscribeNext:^(NSNumber *index) {
        @strongify(self);
        [self scrollToIndexPath];
    }];
}

- (void)scrollToIndexPath
{
    if (self.collectionView.subviews.count) {
        NSIndexPath *indexPath = self.viewModel.indexPath;
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        [self.collectionView.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            view.layer.borderWidth = 0;
        }];
        UIView *view = [self.collectionView cellForItemAtIndexPath:indexPath];
        view.layer.borderWidth = kHBPinsNaviThumbnailPadding;
        view.layer.borderColor = [UIColor whiteColor].CGColor;
    }
}
 */



/*
 这里有一个小技巧，当Cell里的元素比较复杂时，我们可以给Cell也准备一个ViewModel，这个CellViewModel可以由上一层的ViewModel提供，这样Cell如果需要相应的数据，直接跟CellViewModel要即可，CellViewModel也可以包含一些command，比如likeCommand。假如点击Cell时，要做一些处理，也很方便。
 */
// CellViewModel已经在ViewModel里准备好了
/*
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HBPinsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.viewModel = self.viewModel.cellViewModels[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    HBCellViewModel *cellViewModel = self.viewModel.cellViewModels[indexPath.row];
    // 对cellViewModel执行某些操作，因为Cell已经与cellViewModel绑定，所以cellViewModel的改变也会反映到Cell上
    // 或拿到cellViewModel的数据来执行某些操作
}
 */


