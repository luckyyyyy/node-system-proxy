/**
 * This file is part of the William Chan.
 * @author William Chan <root@williamchan.me>
 */

#include <stdio.h>
#include <assert.h>
#include <Windows.h>
#include <WinInet.h>
#include <node_api.h>

#pragma comment(lib, "Wininet.lib")

/**
 * set proxy for windows
 * @param host
 * @param port
 * @return BOOL
 */
BOOL enable_proxy(char* host, uint32_t port) {
    char proxy_host[256];
    sprintf(proxy_host, "http://%s:%d", host, port);
    // printf("proxy_host: %s\n", proxy_host);

    INTERNET_PER_CONN_OPTION_LIST list;
    BOOL bReturn;
    DWORD dwBufSize = sizeof(list);
    list.dwSize = sizeof(list);
    // NULL == LAN, otherwise connectoid name.
    list.pszConnection = NULL;

    // Set three options.
    list.dwOptionCount = 3;
    INTERNET_PER_CONN_OPTION Option[3];
    list.pOptions = Option;

    // Set flags.
    list.pOptions[0].dwOption = INTERNET_PER_CONN_FLAGS;
    list.pOptions[0].Value.dwValue = PROXY_TYPE_PROXY;

    // Set proxy name.
    list.pOptions[1].dwOption = INTERNET_PER_CONN_PROXY_SERVER;
    list.pOptions[1].Value.pszValue = proxy_host;

    // Set proxy override.
    list.pOptions[2].dwOption = INTERNET_PER_CONN_PROXY_BYPASS;
    list.pOptions[2].Value.pszValue = TEXT("");

    // Set the options on the connection.
    bReturn = InternetSetOption(NULL, INTERNET_OPTION_PER_CONNECTION_OPTION, &list, dwBufSize);
    return bReturn;
}

/**
 * close proxy for windows
 * @return BOOL
 */
BOOL disable_proxy() {
    INTERNET_PER_CONN_OPTION_LIST list;
    BOOL bReturn;
    DWORD dwBufSize = sizeof(list);
    list.dwSize = sizeof(list);
    // NULL == LAN, otherwise connectoid name.
    list.pszConnection = NULL;
    // Set three options.
    list.dwOptionCount = 3;
    INTERNET_PER_CONN_OPTION Option[3];
    list.pOptions = Option;

    // Set flags.
    list.pOptions[0].dwOption = INTERNET_PER_CONN_FLAGS;
    list.pOptions[0].Value.dwValue = PROXY_TYPE_DIRECT;

    // Set proxy name.
    list.pOptions[1].dwOption = INTERNET_PER_CONN_PROXY_SERVER;
    list.pOptions[1].Value.pszValue = TEXT("");

    // Set proxy override.
    list.pOptions[2].dwOption = INTERNET_PER_CONN_PROXY_BYPASS;
    list.pOptions[2].Value.pszValue = TEXT("");

    // Set the options on the connection.
    bReturn = InternetSetOption(NULL, INTERNET_OPTION_PER_CONNECTION_OPTION, &list, dwBufSize);
    return bReturn;
}

/**
 * nodejs call api
 * @param env
 * @param info
 * @return napi_value
 */
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
    char* host;
    host = (char*)calloc(str_size + 1, sizeof(char));
    str_size = str_size + 1;
    napi_get_value_string_utf8(env, args[0], host, str_size, &str_size_read);

    uint32_t port;
    status = napi_get_value_uint32(env, args[1], &port);
    assert(status == napi_ok);
    BOOL bReturn = enable_proxy(host, port);
    if (!bReturn) {
        napi_throw_error(env, NULL, "Enable proxy failed");
        return NULL;
    }
    return NULL;
}

/**
 * nodejs call api
 * @param env
 * @param info
 * @return napi_value
 */
static napi_value Disable(napi_env env, napi_callback_info info) {
    BOOL bReturn = disable_proxy();
    if (!bReturn) {
        napi_throw_error(env, NULL, "Disable proxy failed");
        return NULL;
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
