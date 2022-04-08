/**
 * This file is part of the William Chan.
 * @author William Chan <root@williamchan.me>
 */

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#include <objc/runtime.h>
#include <node_api.h>

AuthorizationRef CreateAuthRef() {
    static AuthorizationRef authRef;
    static AuthorizationFlags authFlags;
    authFlags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize;
    OSStatus authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, &authRef);
    if (authErr != noErr) {
        authRef = nil;
        NSLog(@"Error when create authorization");
        return NULL;
    } else {
        if (authRef == NULL) {
            NSLog(@"No authorization has been granted to modify network configuration.");
            return NULL;
        }
    }
    return authRef;
}


static napi_value Enable(napi_env env, napi_callback_info info) {
    napi_status status;

    size_t argc = 2;
    napi_value args[2];
    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    assert(status == napi_ok);

    if (argc < 2) {
        napi_throw_type_error(env, NULL, "Wrong number of arguments");
        return NULL;
    }

    napi_valuetype valuetype0;
    status = napi_typeof(env, args[0], &valuetype0);
    assert(status == napi_ok);

    napi_valuetype valuetype1;
    status = napi_typeof(env, args[1], &valuetype1);
    assert(status == napi_ok);

    if (valuetype0 != napi_string || valuetype1 != napi_number) {
        napi_throw_type_error(env, NULL, "Wrong arguments");
        return NULL;
    }

    size_t str_size;
    size_t str_size_read;
    napi_get_value_string_utf8(env, args[0], NULL, 0, &str_size);
    char* buf;
    buf = (char*)calloc(str_size + 1, sizeof(char));
    str_size = str_size + 1;
    napi_get_value_string_utf8(env, args[0], buf, str_size, &str_size_read);

    uint32_t port;
    status = napi_get_value_uint32(env, args[1], &port);
    assert(status == napi_ok);

    NSInteger privoxyPort = [NSNumber numberWithInt:port].integerValue;
    // NSString *privoxyListenAddress = @"127.0.0.1";
    NSString *privoxyListenAddress = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
    // NSLog(@"%ld", privoxyPort);

    static AuthorizationRef authRef;
    authRef = CreateAuthRef();
    if (authRef != NULL) {

        SCPreferencesRef prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("node-system-proxy"), nil, authRef);

        NSDictionary *sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);

        NSMutableDictionary *proxies = [[NSMutableDictionary alloc] init];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPSEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
        [proxies setObject:@[] forKey:(NSString *)kCFNetworkProxiesExceptionsList];

        // 遍历系统中的网络设备列表，设置 AirPort 和 Ethernet 的代理
        for (NSString *key in [sets allKeys]) {
            NSMutableDictionary *dict = [sets objectForKey:key];
            NSString *interfaceType = [dict valueForKeyPath:@"Interface.Type"];
            NSString* prefPath = [NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices, key, kSCEntNetProxies];
            // NSLog(@"%@", interfaceType);
            // NSLog(@"%@", prefPath);
            // set http proxy
            [proxies setObject:privoxyListenAddress forKey:(NSString *) kCFNetworkProxiesHTTPProxy];
            [proxies setObject:[NSNumber numberWithInteger:privoxyPort] forKey:(NSString*) kCFNetworkProxiesHTTPPort];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString*) kCFNetworkProxiesHTTPEnable];
            // set https proxy
            [proxies setObject:privoxyListenAddress forKey:(NSString *) kCFNetworkProxiesHTTPSProxy];
            [proxies setObject:[NSNumber numberWithInteger:privoxyPort] forKey:(NSString*) kCFNetworkProxiesHTTPSPort];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString*) kCFNetworkProxiesHTTPSEnable];
            SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)prefPath, (__bridge CFDictionaryRef)proxies);

        }

        SCPreferencesCommitChanges(prefRef);
        SCPreferencesApplyChanges(prefRef);
        SCPreferencesSynchronize(prefRef);

        AuthorizationFree(authRef, kAuthorizationFlagDefaults);
    } else {
        napi_throw_error(env, NULL, "No authorization has been granted to modify network configuration.");
    }
    return NULL;
}

static napi_value Disable(napi_env env, napi_callback_info info) {
    napi_status status;

    static AuthorizationRef authRef;
    authRef = CreateAuthRef();
    if (authRef != NULL) {
        SCPreferencesRef prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("node-system-proxy"), nil, authRef);
        NSDictionary *sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);
        NSMutableDictionary *proxies = [[NSMutableDictionary alloc] init];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPSEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
        [proxies setObject:@[] forKey:(NSString *)kCFNetworkProxiesExceptionsList];
        for (NSString *key in [sets allKeys]) {
            NSMutableDictionary *dict = [sets objectForKey:key];
            NSString *interfaceType = [dict valueForKeyPath:@"Interface.Type"];
            NSString* prefPath = [NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices, key, kSCEntNetProxies];
            SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)prefPath, (__bridge CFDictionaryRef)proxies);
        }
        SCPreferencesCommitChanges(prefRef);
        SCPreferencesApplyChanges(prefRef);
        SCPreferencesSynchronize(prefRef);
        AuthorizationFree(authRef, kAuthorizationFlagDefaults);
    } else {
        napi_throw_error(env, NULL, "No authorization has been granted to modify network configuration.");
    }

    return NULL;
}

#define DECLARE_NAPI_METHOD(name, func)                                        \
    { name, 0, func, 0, 0, 0, napi_default, 0 }

napi_value Init(napi_env env, napi_value exports) {
    napi_status status;

    napi_property_descriptor desc[] = {
        DECLARE_NAPI_METHOD("enable", Enable),
        DECLARE_NAPI_METHOD("disable", Disable),
    };
    status = napi_define_properties(env, exports, sizeof(desc) / sizeof(*desc), desc);

    assert(status == napi_ok);
    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)