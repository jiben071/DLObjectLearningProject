/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

/*
 POPAnimationRuntime主要写了很多的C函数。利用runtime得知要进行动画的属性的类型，从而能够使它能用自己的Vector向量知道如何POPBOX、POPUnbox，实现了单一数据结构就能对于CALayer所有可动画属性时行相互转换。转换之后数学方面的计算就是可以简单的对Vector里的每个值进行数学方面的运算。这样代码接口就是统一了，这是它的另一个亮点。还有一个比较隐藏的点，什么时候去获取属性的类型呢，就是在设置动画的toValue的时候。
 */

#import <objc/runtime.h>

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import "POPAnimatablePropertyTypes.h"
#import "POPVector.h"

enum POPValueType
{
  kPOPValueUnknown = 0,
  kPOPValueInteger,
  kPOPValueFloat,
  kPOPValuePoint,
  kPOPValueSize,
  kPOPValueRect,
  kPOPValueEdgeInsets,
  kPOPValueAffineTransform,
  kPOPValueTransform,
  kPOPValueRange,
  kPOPValueColor,
  kPOPValueSCNVector3,
  kPOPValueSCNVector4,
};

using namespace POP;

/**
 Returns value type based on objc type description, given list of supported value types and length.
 */
extern POPValueType POPSelectValueType(const char *objctype, const POPValueType *types, size_t length);

/**
 Returns value type based on objc object, given a list of supported value types and length.
 */
extern POPValueType POPSelectValueType(id obj, const POPValueType *types, size_t length);

/**
 Array of all value types.
 */
extern const POPValueType kPOPAnimatableAllTypes[12];

/**
 Array of all value types supported for animation.
 */
extern const POPValueType kPOPAnimatableSupportTypes[10];

/**
 Returns a string description of a value type.
 */
extern NSString *POPValueTypeToString(POPValueType t);

/**
 Returns a mutable dictionary of weak pointer keys to weak pointer values.
 */
extern CFMutableDictionaryRef POPDictionaryCreateMutableWeakPointerToWeakPointer(NSUInteger capacity) CF_RETURNS_RETAINED;

/**
 Returns a mutable dictionary of weak pointer keys to weak pointer values.
 */
extern CFMutableDictionaryRef POPDictionaryCreateMutableWeakPointerToStrongObject(NSUInteger capacity) CF_RETURNS_RETAINED;

/**
 Box a vector.
 */
extern id POPBox(VectorConstRef vec, POPValueType type, bool force = false);

/**
 Unbox a vector.
 */
extern VectorRef POPUnbox(id value, POPValueType &type, NSUInteger &count, bool validate);

/**
 Read object value and return a Vector4r.
 */
NS_INLINE Vector4r read_values(POPAnimatablePropertyReadBlock read, id obj, size_t count)
{
  Vector4r vec = Vector4r::Zero();
  if (0 == count)
    return vec;

  read(obj, vec.data());

  return vec;
}

NS_INLINE NSString *POPStringFromBOOL(BOOL value)
{
  return value ? @"YES" : @"NO";
}
