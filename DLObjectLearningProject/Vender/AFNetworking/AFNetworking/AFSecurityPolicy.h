// AFSecurityPolicy.h
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <Security/Security.h>

typedef NS_ENUM(NSUInteger, AFSSLPinningMode) {
    AFSSLPinningModeNone,//代表无条件信任服务器的证书
    AFSSLPinningModePublicKey,//代表会对服务器返回的证书中的PublicKey进行验证
    AFSSLPinningModeCertificate,//代表会对服务器返回的证书同本地证书全部进行校验
};

/**
 `AFSecurityPolicy` evaluates server trust against pinned X.509 certificates and public keys over secure connections.
 通过X.509证书和公钥来评估服务器建立安全连接的可靠性
 说的是AFSecurityPolicy 用来验证通过X.509(数字证书的标准)的数字证书和公开密钥进行的安全网络连接是否值得信任。
 Adding pinned SSL certificates to your app helps prevent man-in-the-middle attacks and other vulnerabilities. Applications dealing with sensitive customer data or financial information are strongly encouraged to route all communication over an HTTPS connection with SSL pinning configured and enabled.
 将固定的SSL证书添加到您的应用程序有助于防止中间人攻击和其他漏洞。 强烈建议处理敏感客户数据或财务信息的应用程序通过HTTPS连接路由所有通信，并配置并启用SSL固定。
 */

NS_ASSUME_NONNULL_BEGIN

/*
 学习到的知识点：
 
 HTTP、HTTPS通信过程
 加密的相关知识
 Security框架相关API
 __bridge_transfer把CF对象转换成OC对象
 __Require_noErr_Quiet
 __Require_Quiet
 数字证书的格式都遵循X.509标准
 自定义对象归档
 */

//AFSecurityPolicy是关于网络连接安全方面的类
//AFSecurityPolicy其实就是为了验证证书是否可信任
//https://www.jianshu.com/p/f522d041cd91
@interface AFSecurityPolicy : NSObject <NSSecureCoding, NSCopying>

/**
 The criteria by which(标准确认) server trust should be evaluated against(针对) the pinned SSL certificates. Defaults to `AFSSLPinningModeNone`.
 服务器信任应根据固定的SSL证书进行评估的标准。
 返回SSL Pinning的类型。默认的是AFSSLPinningModeNone。
 */
@property (readonly, nonatomic, assign) AFSSLPinningMode SSLPinningMode;

/**
 The certificates used to evaluate server trust according to the SSL pinning mode. 

  By default, this property is set to any (`.cer`) certificates included in the target compiling AFNetworking. Note that if you are using AFNetworking as embedded framework, no certificates will be pinned by default. Use `certificatesInBundle` to load certificates from your target, and then create a new policy by calling `policyWithPinningMode:withPinnedCertificates`.
 
 Note that if pinning is enabled, `evaluateServerTrust:forDomain:` will return true if any pinned certificate matches.
 保存着所有的可用做校验的证书的集合。只要在证书集合中任何一个校验通过，evaluateServerTrust:forDomain: 就会返回true，即通过校验。
 */
@property (nonatomic, strong, nullable) NSSet <NSData *> *pinnedCertificates;

/**
 Whether or not to trust servers with an invalid or expired SSL certificates. Defaults to `NO`.
 使用允许无效或过期的证书，默认是NO不允许。
 */
@property (nonatomic, assign) BOOL allowInvalidCertificates;

/**
 Whether or not to validate the domain name in the certificate's CN field. Defaults to `YES`.
 是否验证证书中的域名domain，默认是YES。
 */
@property (nonatomic, assign) BOOL validatesDomainName;

///-----------------------------------------
/// @name Getting Certificates from the Bundle
///-----------------------------------------

/**
 Returns any certificates included in the bundle. If you are using AFNetworking as an embedded framework, you must use this method to find the certificates you have included in your app bundle, and use them when creating your security policy by calling `policyWithPinningMode:withPinnedCertificates`.
 返回指定bundle中的证书。如果使用AFNetworking的证书验证 ，就必须实现此方法，并且使用policyWithPinningMode:withPinnedCertificates方法来创建security policy。

 @return The certificates included in the given bundle.
 */
+ (NSSet <NSData *> *)certificatesInBundle:(NSBundle *)bundle;

///-----------------------------------------
/// @name Getting Specific Security Policies
///-----------------------------------------

/**
 Returns the shared default security policy, which does not allow invalid certificates, validates domain name, and does not validate against pinned certificates or public keys.

 @return The default security policy.
 默认的security policy。其认证设置为：不允许无效或过期的证书；验证domain域名；不对证书和公钥进行验证。
 */
+ (instancetype)defaultPolicy;

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns a security policy with the specified pinning mode.

 @param pinningMode The SSL pinning mode.

 @return A new security policy.
 */
+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode;

/**
 Creates and returns a security policy with the specified pinning mode.

 @param pinningMode The SSL pinning mode.
 @param pinnedCertificates The certificates to pin against.

 @return A new security policy.
 */
+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode withPinnedCertificates:(NSSet <NSData *> *)pinnedCertificates;

///------------------------------
/// @name Evaluating Server Trust
///------------------------------

/**
 Whether or not the specified server trust should be accepted, based on the security policy.
 根据安全策略是否接受指定的服务器信任。

 This method should be used when responding to an authentication challenge from a server.
 响应来自服务器的身份验证质询时应使用此方法。

 @param serverTrust The X.509 certificate trust of the server.
 @param domain The domain of serverTrust. If `nil`, the domain will not be validated.

 @return Whether or not to trust the server.
 
 第一个参数：serverTrust是服务器发放的X.509信任证书；
 第二个参数：domain是发放信任证书的服务器域名。
 这个方法是基于security policy来验证指定的服务器是否可信任。这个方法应该在响应服务器身份验证挑战时使用。
 属于核心方法
 */
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(nullable NSString *)domain;

@end

NS_ASSUME_NONNULL_END

///----------------
/// @name Constants
///----------------

/**
 ## SSL Pinning Modes SSL固定模式

 The following constants are provided by `AFSSLPinningMode` as possible SSL pinning modes.

 enum {
 AFSSLPinningModeNone,
 AFSSLPinningModePublicKey,
 AFSSLPinningModeCertificate,
 }

 `AFSSLPinningModeNone`
 Do not used pinned certificates to validate servers.

 `AFSSLPinningModePublicKey`
 Validate host certificates against public keys of pinned certificates.

 `AFSSLPinningModeCertificate`
 Validate host certificates against pinned certificates.
*/
