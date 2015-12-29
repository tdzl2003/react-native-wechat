import { DeviceEventEmitter, NativeModules } from 'react-native';
import promisify from 'es6-promisify';

let isAppRegistered = false;
const WeChat = NativeModules.WeChat;

// Used only with promisify. Transform callback to promise result.
function translateError(err, result) {
  if (!err) {
    return this.resolve(result);
  }
  if (typeof err === 'object') {
    if (err instanceof Error) {
      return this.reject(ret);
    }
    return this.reject(Object.assign(new Error(err.message), { errCode: err.errCode }));
  } else if (typeof err === 'string') {
    return this.reject(new Error(err));
  }
  this.reject(Object.assign(new Error(), { origin: err }));
}

// Save callback and wait for future event.
let savedCallback = undefined;
function waitForResponse(type) {
  return new Promise((resolve, reject) => {
    if (savedCallback) {
      savedCallback('User canceled.');
    }
    savedCallback = result => {
      if (result.type !== type) {
        return;
      }
      savedCallback = undefined;
      if (result.errCode !== 0) {
        const err = new Error(result.errMsg);
        err.errCode = result.errCode;
        reject(err);
      } else {
        resolve(result);
      }
    };
  });
}

DeviceEventEmitter.addListener('WeChat_Resp', resp => {
  const callback = savedCallback;
  savedCallback = undefined;
  callback && callback(resp);
});

function wrapRegisterApp(nativeFunc) {
  if (!nativeFunc) {
    return undefined;
  }
  const promisified = promisify(nativeFunc, translateError);
  return (...args) => {
    if (isAppRegistered) {
      return Promise.reject(new Error('App is already registered.'));
    }
    isAppRegistered = true;
    return promisified(...args);
  };
}

function wrapApi(nativeFunc) {
  if (!nativeFunc) {
    return undefined;
  }
  const promisified = promisify(nativeFunc, translateError);
  return (...args) => {
    if (!isAppRegistered) {
      return Promise.reject(new Error('registerApp required.'));
    }
    return promisified(...args);
  };
}

export const registerApp = wrapRegisterApp(WeChat.registerApp);

export const registerAppWithDescription = wrapRegisterApp(WeChat.registerAppWithDescription);

export const isWXAppInstalled = wrapApi(WeChat.isWXAppInstalled);

export const isWXAppSupportApi = wrapApi(WeChat.isWXAppSupportApi);

export const getWXAppInstallUrl = wrapApi(WeChat.getWXAppInstallUrl);

export const getApiVersion = wrapApi(WeChat.getApiVersion);

export const openWXApp = wrapApi(WeChat.openWXApp);

const nativeShareToTimelineRequest = wrapApi(WeChat.shareToTimeline);

const nativeShareToSessionRequest = wrapApi(WeChat.shareToSession);

const nativeSendAuthRequest = wrapApi(WeChat.sendAuthRequest);

export function sendAuthRequest(scopes, state) {
  // Generate a random, unique state if not provided.
  let _scopes = scopes || 'snsapi_userinfo';
  if (Array.isArray(_scopes)) {
    _scopes = _scopes.join(',');
  }
  const _state = state || Math.random().toString(16).substr(2) + '_' + new Date().getTime();
  return Promise.all([nativeSendAuthRequest(_scopes, _state), waitForResponse('SendAuth.Resp')]).then(v=>v[1]);
}

export function shareToTimelineRequest(data) {
  return Promise.all([waitForResponse('SendMessageToWX.Resp'), nativeShareToTimelineRequest(data)]).then(v=>v[1]);
}

export function shareToSessionRequest(data) {
  return Promise.all([waitForResponse('SendMessageToWX.Resp'), nativeShareToSessionRequest(data)]).then(v=>v[1]);
}
