// Rename "require" to avoid conflicts with pure JS libraries
requireNodejs = require;
require = undefined;

/**** NODEJS MODULES ****/

const fs = requireNodejs('fs'),
  path = requireNodejs('path'),
  yaml = requireNodejs('js-yaml'),
  bs58 = requireNodejs('bs58'),
  clc = requireNodejs('cli-color'),
  gui = requireNodejs('nw.gui');

Base58 = {
  encode: (bytes) => bs58.encode(new Buffer(bytes)),
  decode: (data) => new Uint8Array(bs58.decode(data))
};

/**** Program ****/
const APP_ID = "gchange";
const APP_NAME = "Gchange"; // WARN: must be same as manifest.json title
const HOME = requireNodejs('os').homedir();
const APP_HOME = path.resolve(HOME, path.join('.config', APP_ID));
const APP_KEYRING = path.resolve(APP_HOME, 'keyring.yml');
const HAS_SPLASH_SCREEN = false;
const SPLASH_SCREEN_TITLE = APP_NAME + " loading...";
const DEFAULT_SETTINGS = {
  "useRelative": false,
  "timeWarningExpire": 2592000,
  "useLocalStorage": true,
  "rememberMe": true,
  "useRemoteStorage": true,
  "plugins": {
    "es": {
      "enable": true,
      "askEnable": false,
      "host": "data.gchange.fr",
      "port": "443"
    }
  }
};

// Current window
const win = gui && gui.Window && gui.Window.get();

function isSdkMode () {
  return gui && typeof win.showDevTools === 'function';
}
function isMainWin(win) {
  return win && win.title === APP_NAME && true;
}
function isSplashScreen(win) {
  return (win && win.title === SPLASH_SCREEN_TITLE);
}

/**
 * Read process command line args
 *
 * @returns {{debug: boolean, menu: boolean}}
 */
function getArgs() {
  const options = {
    verbose: false,
    debug: false
  };
  const commands = gui && gui.App && gui.App.argv;
  if (commands && commands.length) {
    for (let i in commands) {
      switch (commands[i]) {
        case "--verbose":
          options.verbose = true;
          break;
          break;
        case "--debug":
          options.debug = true && isSdkMode();
          break;
      }
    }
  }

  options.home = HOME;
  return options;
}

/**
 * Re-routing console log
 * */
function consoleToStdout(options) {
  const superConsole = {
    log: console.log,
    debug: console.debug,
    info: console.info,
    warn: console.warn,
    error: console.error,
  }
  const printArguments = function(arguments) {
    if (arguments.length > 0) {

      for (let i = 0; i < arguments.length; i++) {

        if (i === 1) process.stdout.write('\t');

        const argument = arguments[i];
        if (typeof argument === "object" && argument.stack) {
          process.stdout.write(argument.stack);
        }
        else if (typeof argument === "string") {
          process.stdout.write(argument);
        }
        else {
          process.stdout.write(JSON.stringify(argument));
        }
      }
    }
    process.stdout.write('\n');
  };

  if (options && options.debug) {
    console.debug = function (message) {
      process.stdout.write(clc.green("[DEBUG] "));
      printArguments(arguments);
      superConsole.debug.apply(this, arguments);
    };
    console.log = function(message) {
      process.stdout.write(clc.green("[CONSOLE] "));
      printArguments(arguments);
      superConsole.log.apply(this, arguments);
    }
  }
  console.info = function(message) {
    process.stdout.write(clc.blue("[INFO]  "));
    printArguments(arguments);
    superConsole.info.apply(this, arguments);
  };
  console.warn = function(message) {
    process.stdout.write(clc.yellow("[WARN]  "));
    printArguments(arguments);
    superConsole.warn.apply(this, arguments);
  };
  console.error = function() {
    process.stderr.write(clc.red("[ERROR] "));
    printArguments(arguments);
    superConsole.error.apply(this, arguments);
  };
}


function initLogger(options) {
  options = options || getArgs();

  if (options.verbose) {
    if (options.debug) {
      // SDK enable: not need to redirect debug
    }
    else {
      // Re-routing console log
      consoleToStdout(options);
    }
  }
  else {
    // Re-routing console log
    consoleToStdout(options);
  }
}

function openDebugger(subWin) {
  subWin = subWin || win;
  if (isSdkMode()) {
    try {
      console.info("[desktop] Opening debugger...");
      subWin.showDevTools();
    }
    catch(err) {
      console.error("[desktop] Cannot open debugger:", err);
    }
  }
}

function loadSettings(options) {
  if (options && options.settings) return; // Skip, already filled

  console.debug("[desktop] Getting settings from the local storage...");

  let settingsStr = window.localStorage.getItem('settings');
  options.settings = (settingsStr && JSON.parse(settingsStr));
  const localeId = options.settings && options.settings.locale && options.settings.locale.id;
  options.locale = localeId && localeId.split('-')[0] || options.locale || 'en';
}

function prepareSettings(options) {
  console.info("[desktop] Preparing settings...");
  options = options || getArgs();

  let settings = options.settings;
  let locale = options.locale || 'en';

  /**** Checking app keyring file ****/
  let keyringRaw, keyring, keyPairOK;
  const rememberMe = (!settings && DEFAULT_SETTINGS.rememberMe) || settings.rememberMe == true;
  const keyringFile = settings && settings.keyringFile || APP_KEYRING;
  if (rememberMe && fs.existsSync(keyringFile)) {
    console.debug("[desktop] Keyring file detected at {" + keyringFile + "}...");

    keyringRaw = fs.readFileSync(keyringFile);
    keyring = yaml.safeLoad(keyringRaw);

    keyPairOK = keyring.pub && keyring.sec && true;
    if (!keyPairOK) {
      console.warn("[desktop] Invalid keyring file: missing 'pub' or 'sec' field! Skipping auto-login.");
      // Store settings
      settings = settings || DEFAULT_SETTINGS;
      if (settings.keyringFile) {
        delete settings.keyringFile;
        window.localStorage.setItem('settings', JSON.stringify(settings));
      }
    } else {
      console.debug("[desktop] Auto-login user on {" + keyring.pub + "}");
      window.localStorage.setItem('pubkey', keyring.pub);
      const keepAuthSession = !settings || (settings.keepAuthIdle == 9999);
      if (keepAuthSession) {
        console.debug("[desktop] Auto-authenticate on account (using keyring file)");
        window.sessionStorage.setItem('seckey', keyring.sec);
      }

      // Store settings
      settings = settings || DEFAULT_SETTINGS;
      if (!settings.keyringFile || settings.keyringFile !== keyringFile) {
        settings.keyringFile = keyringFile;
        window.localStorage.setItem('settings', JSON.stringify(settings));
      }
    }
  } else if (settings && settings.keyringFile) {
    console.warn("[desktop] Unable to found keyring file define in settings. Skipping auto-login");
    // Store settings
    settings = settings || DEFAULT_SETTINGS;
    if (settings.keyringFile) {
      delete settings.keyringFile;
      window.localStorage.setItem('settings', JSON.stringify(settings));
    }
  }

}

function openNewWindow(options, callback) {
  options = {
    title: APP_NAME,
    position: 'center',
    width: 1300,
    height: 800,
    min_width: 750,
    min_height: 400,
    frame: true,
    focus: true,
    ...options
  };
  console.debug("[desktop] Opening window {id: '"+ options.id + "', title: '"+ options.title +"'} ...");
  gui.Window.open('gchange/index.html', {
    id: options.id,
    title: options.title,
    position: options.position,
    width:  options.width,
    height:  options.height,
    min_width:  options.min_width,
    min_height:  options.min_height,
    frame:  options.frame,
    focus:  options.focus,
  }, callback);
}

function openMainWindow(options, callback) {
  openNewWindow({
    id: APP_ID,
    ...options
  }, callback);
}

function openSecondaryWindow(options, callback) {
  openNewWindow({
    id: APP_ID + "-secondary",
    ...options
  }, callback);
}


/****
 * Main PROCESS
 */
function startApp(options) {
  options = options || getArgs();

  if (options.debug) {
    openDebugger(win);
  }

  try {
    console.info("[desktop] Launching "+ APP_NAME + "...", options);

    loadSettings(options);

    console.info("[desktop] User home:  ", options.home);
    console.info("[desktop] User locale:", options.locale);

    prepareSettings(options);

    // If app was started using the splash screen, launch the main window
    if (HAS_SPLASH_SCREEN === true) {
      openMainWindow(options);

      // Close the splash screen, after 1s
      setTimeout(() => win.close(), 1000);
    }
  }
  catch (err) {
    console.error("[desktop] Error while trying to launch: " + (err && err.message || err || ''), err);

    if (options.debug) {
      // Keep open, if debugger open
    }
    else {
      // If app was started using the splash screen, close it
      if (HAS_SPLASH_SCREEN) {
        // Close the splash screen
        setTimeout(() => win.close());
      }
    }
  }


}

// -- MAIN --

// Get command args
const options = getArgs();
// Init logger
initLogger(options);

// Splash screen: start the app
if (isSplashScreen(win)) {
  setTimeout(() => startApp(options), 1000);
}

// Main window
else if (isMainWin(win)) {

  // If App not already start : do it
  if (HAS_SPLASH_SCREEN === false) {
    startApp(options)
  }

  // Else (if started) just open the debugger
  else if (options.debug) {
    openDebugger(win);
  }
}
else {
  console.warn("[desktop] Unknown window title: " + (win && win.title || 'undefined'));
}

