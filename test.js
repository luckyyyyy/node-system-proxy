/**
 * This file is part of the William Chan.
 * @author William Chan <root@williamchan.me>
 */

const proxy = require('./main');

proxy.enable('127.0.0.1', 8080);
proxy.disable();
