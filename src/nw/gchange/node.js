// require('nw.gui').Window.get().showDevTools()

// Rename "require" to avoid conflicts with pure JS libraries
requireNodejs = require
require = undefined

const expectedCurrency = "g1";

/**** NODEJS MODULES ****/

const fs = requireNodejs('fs');
const path = requireNodejs('path');
const yaml = requireNodejs('js-yaml');
const bs58 = requireNodejs('bs58');
const clc = requireNodejs('cli-color');
const gui = requireNodejs('nw.gui');

Base58 = {
  encode: (bytes) => bs58.encode(new Buffer(bytes)),
  decode: (data) => new Uint8Array(bs58.decode(data))
};

/**** Program ****/

const HOME = requireNodejs('os').homedir();
const DUNITER_HOME = path.resolve(HOME, '.config/duniter/duniter_default');
const DUNITER_CONF = path.resolve(DUNITER_HOME, 'conf.json');
const DEFAULT_GCHANGE_SETTINGS = {
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
  },
  "node": {
    "host": local_host,
    "port": local_port
  }
};


function isSdkMode () {
  return gui && (window.navigator.plugins.namedItem('Native Client') !== null);
}

/**** Process command line args ****/
var commands = gui && gui.App && gui.App.argv;
var debug = false;
if (commands && commands.length) {
  for (i in commands) {
    if (commands[i] === "--debug") {
      console.log("[NW] Enabling debug mode (--debug)");
      debug = true;

      // Open the DEV tool (need a SDK version of NW)
      if (isSdkMode()) {
        gui.Window.get().showDevTools();
      }
    }
  }
}

/**** Re-routing console log ****/
var oldConsole = {
  log: console.log,
  debug: console.debug,
  info: console.info,
  warn: console.warn,
  error: console.error,
}
if (debug) {
  console.debug = function (message) {
    process.stdout.write(clc.green("[DEBUG] ") + message + "\n");
    oldConsole.debug.apply(this, arguments);
  };
  console.log = function(message) {
    process.stdout.write(clc.blue("[CONSOLE] ") + message + "\n");
    oldConsole.log.apply(this, arguments);
  }
}
console.info = function(message) {
  process.stdout.write(clc.blue("[INFO]  ") + message + "\n");
  oldConsole.info.apply(this, arguments);
};
console.warn = function(message) {
  process.stdout.write(clc.yellow("[WARN]  ") + message + "\n");
  oldConsole.warn.apply(this, arguments);
};
console.error = function(message) {
  if (typeof message == "object") {
    process.stderr.write(clc.red("[ERROR] ") + JSON.stringify(message) + "\n");
  }
  else {
    process.stderr.write(clc.red("[ERROR] ") + message + "\n");
  }
  oldConsole.error.apply(this, arguments);
};

/**** Starting ****/
let settingsStr = window.localStorage.getItem('GCHANGE_SETTINGS');
let settings = settingsStr && JSON.parse(settingsStr);

console.info("[NW] Starting. User home is {" + HOME + "}");

const duniterConf = fs.existsSync(DUNITER_CONF) && requireNodejs(path.resolve(DUNITER_HOME, 'conf.json'));
const local_host = duniterConf && duniterConf.ipv4;
const local_port = duniterConf && duniterConf.port;


if (duniterConf &&
  duniterConf.currency === expectedCurrency
  && (!settings
  || settings.node.host != local_host
  || settings.node.port != local_port)) {
  // Detect locale
  const locale = (settings && settings.locale && settings.locale.id).split('-')[0] || 'en';
  console.debug('[NW] Using locale: ' + locale);
  const confirmationMessage = (locale === 'fr') ?
    'Un nœud pour la monnaie ' + expectedCurrency + ' a été détecté sur cet ordinateur, voulez-vous que Gchange s\'y connecte ?' :
    'A node for currency ' + expectedCurrency + ' has been detected on this computer. Do you want Gchange to connect it?';

  if (settings && settings.askLocalNodeKeyring === false) {
    // Nothing to do
    console.debug('[NW] Skipping Duniter local node confirmation (already asked)');

  }
  else if (confirm(confirmationMessage)) {
    settings = settings || DEFAULT_GCHANGE_SETTINGS;
    console.debug('[NW] Configuring Gchange on Duniter local node...');
    settings.node = {
      "host": local_host,
      "port": local_port
    };
    settings.plugins = {
      "es": {
        "enable": true,
        "askEnable": false,
        "host": "data.gchange.fr",
        "port": "443"
      }
    };
    window.localStorage.setItem('GCHANGE_SETTINGS', JSON.stringify(settings));
  }
  // User does NOT confirm: Not ask it again
  else {
    console.debug('[NW] User not need to connect on Duniter local node. Configuring Gchange to remember this choice...');
    settings = settings || DEFAULT_CESIUM_SETTINGS;
    settings.askLocalNodeKeyring = false;
    window.localStorage.setItem('GCHANGE_SETTINGS', JSON.stringify(settings));
  }
}
