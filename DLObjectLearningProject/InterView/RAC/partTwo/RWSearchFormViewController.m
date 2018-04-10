//
//  RWSearchFormViewController.m
//  TwitterInstant
//
//  Created by Colin Eberhardt on 02/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//  http://www.cocoachina.com/ios/20160211/15020.html  第二部分教程

#import "RWSearchFormViewController.h"
#import "RWSearchResultsViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <ReactiveObjC/RACEXTScope.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "RWTweet.h"
#import <LinqToObjectiveC/LinqToObjectiveC.h>

typedef NS_ENUM(NSInteger,RWTwitterInstantError) {
    RWTwitterInstantErrorAccessDenied,
    RWTwitterInstantErrorNoTwitterAccounts,
    RWTwitterInstantErrorInvalidResponse
};

static NSString * const RWTwitterInstantDomain = @"TwitterInstant";

@interface RWSearchFormViewController ()

@property (weak, nonatomic) IBOutlet UITextField *searchText;

@property (strong, nonatomic) RWSearchResultsViewController *resultsViewController;
@property(nonatomic, strong) ACAccountStore  *accountStore;
@property(nonatomic, strong) ACAccountType   *twitterAccountType;
@end

@implementation RWSearchFormViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.title = @"Twitter Instant";
  
  [self styleTextField:self.searchText];
  
  self.resultsViewController = self.splitViewController.viewControllers[1];
    
    [self addTwitterAccount];
    /*
    [[self requestAccessToTwitterSignal] subscribeNext:^(id  _Nullable x) {
        NSLog(@"Access granted");
    } error:^(NSError * _Nullable error) {
        NSLog(@"An error occurred:%@",error);
    }];
     */
    
    /*
     http://bbs.520it.com/forum.php?mod=viewthread&tid=257  辅助理解
     FlatternMap和Map的区别
     1.FlatternMap中的Block返回信号。
     2.Map中的Block返回对象。
     3.开发中，如果信号发出的值不是信号，映射一般使用Map
     4.开发中，如果信号发出的值是信号，映射一般使用FlatternMap。
     总结：signalOfsignals用FlatternMap。
     */
    
    //不同信号连续的链
    @weakify(self)
    [[[[[[[self requestAccessToTwitterSignal] then:^RACSignal * _Nonnull{//then方法会一直等待，知道completed事件发出
        //then:用于连接两个信号，当第一个信号完成，才会连接then返回的信号。
        // 注意使用then，之前信号的值会被忽略掉.
        // 底层实现：1、先过滤掉之前的信号发出的值。2.使用concat连接then返回的信号
        @strongify(self)
        return self.searchText.rac_textSignal;
    }] filter:^BOOL(NSString *  _Nullable value) {
        @strongify(self)
        return [self isValidSearchText:value];
        //throttle限流  500毫秒后才真正进行搜索  500毫秒后，数据无变化，才进行真正的搜索
    }] throttle:0.5] flattenMap:^__kindof RACSignal * _Nullable(NSString  *_Nullable value) {//flattenMap作用:把源信号的内容映射成一个新的信号，信号可以是任意类型。
        @strongify(self)
        return [self signalForSearchWithText:value];
    }] deliverOn:[RACScheduler mainThreadScheduler]]//将subscribeNext的内容切换到主线程
     subscribeNext:^(NSDictionary  *_Nullable jsonSearchResult) {
//        NSLog(@"%@", x);
         @strongify(self)
         NSArray *statuses = jsonSearchResult[@"statuses"];
         NSArray *tweets = [statuses linq_select:^id(id tweet) {
             return [RWTweet tweetWithStatus:tweet];
         }];
         [self.resultsViewController displayTweets:tweets];
    } error:^(NSError * _Nullable error) {
        NSLog(@"An error occurred: %@", error);
    }];
  
}

- (SLRequest *)requestForTwitterSearchWithText:(NSString *)text{
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    NSDictionary *params = @{@"q":text};
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:params];
    return request;
}

- (RACSignal *)signalForSearchWithText:(NSString *)text{
    //1.define the errors
    NSError *noAccountsError = [NSError errorWithDomain:RWTwitterInstantDomain
                                                   code:RWTwitterInstantErrorNoTwitterAccounts
                                               userInfo:nil];
    NSError *invalidResponseError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorInvalidResponse userInfo:nil];
    
    //2.create the signal block
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self)
        
        //3.create the request
        SLRequest *request = [self requestForTwitterSearchWithText:text];
        
        //4.supply a twitter account
        NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:self.twitterAccountType];
        if (twitterAccounts.count == 0) {
            [subscriber sendError:noAccountsError];
        }else{
            [request setAccount:[twitterAccounts lastObject]];
            
            //5. perform the request
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (urlResponse.statusCode == 200) {
                    //6 on success, parse the response
                    NSDictionary *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                    [subscriber sendNext:timelineData];
                    [subscriber sendCompleted];
                }else{
                    //7 send an error on failure
                    [subscriber sendError:invalidResponseError];
                }
            }];
        }
        return nil;
    }];
    
}

- (void)addTwitterAccount{
    self.accountStore = [[ACAccountStore alloc] init];
    self.twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
}

- (RACSignal *)requestAccessToTwitterSignal{
    //1.define an error
    NSError *accessError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorAccessDenied userInfo:nil];
    //2.create the signal
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self)
        //3.request access to twitter
        [self.accountStore requestAccessToAccountsWithType:self.twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
            //4. handle the response
            if (!granted) {
                [subscriber sendError:accessError];
            }else{
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }];
}


- (void)checkText{
    /*
     内存管理模式：ReactiveCocoa维持和保留自己全局的信号。如果它有一个或者多个subscribers（订阅者），信号就会活跃。如果所有的订阅者都移除掉了，信号就会被释放。
     */
    [[self.searchText.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return [self isValidSearchText:value] ? [UIColor whiteColor]:[UIColor yellowColor];
    }] subscribeNext:^(UIColor  *_Nullable x) {
        self.searchText.backgroundColor = x;
    }];
}

/*你如何从一个信号取消订阅？当一个completed或者error事件之后，订阅会自动的移除（一会就会学到）。手工的移除将会通过RACDisposable.*/
- (void)checkTextWithDisapol{//手动移除订阅 不常用
    RACSignal *backgroundColorSignal = [self.searchText.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return [self isValidSearchText:value] ? [UIColor whiteColor]:[UIColor yellowColor];
    }];
    
    RACDisposable *subscription = [backgroundColorSignal subscribeNext:^(UIColor  *_Nullable x) {
        self.searchText.backgroundColor = x;//subscribeNext:block使用self来获得一个textField的引用，Blocks在封闭返回内捕获并且持有了值。因此在self和这个信号量之间造成了强引用，造成了循环引用。
        //解决办法：使用@weakify(self)  @strongify(self)
    }];
    
    //at some point in the future
    [subscription dispose];//取消订阅
}

- (void)styleTextField:(UITextField *)textField {
  CALayer *textFieldLayer = textField.layer;
  textFieldLayer.borderColor = [UIColor grayColor].CGColor;
  textFieldLayer.borderWidth = 2.0f;
  textFieldLayer.cornerRadius = 0.0f;
}


- (BOOL)isValidSearchText:(NSString *)text{
    return text.length > 2;
}




@end
