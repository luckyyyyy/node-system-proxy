{
  "targets": [{
    "target_name": "proxy",
    "conditions" : [
      [
        'OS=="mac"', {
          "sources": [
            "src/mac.m",
          ],
          'xcode_settings': {
            'OTHER_CFLAGS': [
                '-fobjc-arc', '-fmodules'
            ]
          },
          "link_settings": {
            "libraries": [
              "/System/Library/Frameworks/SystemConfiguration.framework",
              "/System/Library/Frameworks/Security.framework",
              "/System/Library/Frameworks/CFNetwork.framework",
              "/System/Library/Frameworks/Foundation.framework"
            ]
          }
        },
        'OS=="win"', {
          "sources": [
            "src/windows.c",
          ],
          "cflags!": [ '-fno-exceptions' ],
        },
      ],
    ],
  }]
}
