node-system-proxy
====================

Set up windows and macOS proxies via OS API, usually used in Electron.
An example of writing a nodejs plugin using objective-c and C.

## Support

* macOS >= 10.10
* Windows >= NT 6.0

## Example

```js
import proxy from 'node-system-proxy';

proxy.enable('127.0.0.1', 8080);
proxy.disable();

```