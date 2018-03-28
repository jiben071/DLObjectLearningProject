//
//  DLMVVMViewModel.h
//  DLObjectLearningProject
//
//  Created by denglong on 28/03/2018.
//  Copyright © 2018 long deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

typedef enum : NSUInteger {
    InputStateEmpty,
    InputStateValid,
    InputStateInvalid
} InputState;

#define ConvertInputStateToColor(signal) [InputStateToColorConverter convert:signal]

@interface InputStateToColorConverter : NSObject

+ (RACSignal *)convert:(RACSignal *)signal;

@end

#define ConvertTextToInputState(signal, minimum, maximum) [TextToInputStateConverter convert:signal m##inimum:minimum m##aximum:maximum]

@interface TextToInputStateConverter : NSObject

+ (RACSignal *)convert:(RACSignal *)signal minimum:(NSInteger)minimum maximum:(NSInteger)maximum;
+ (InputState)inputStateForText:(NSString *)text minimum:(NSInteger)minimum maximum:(NSInteger)maximum;

@end

@interface DLMVVMViewModel : NSObject
@property (nonatomic, assign, readonly) InputState usernameInputState;
@property (nonatomic, assign, readonly) InputState passwordInputState;
@property (nonatomic, assign, readonly) BOOL loginEnabled;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@end
