let Handlebars = require('handlebars');
let fs = require('fs');
let sslTemplate = fs.readFileSync('/usr/local/etc/nginx/ssl.default.conf', 'utf-8');
let redirectTemplate = fs.readFileSync('/usr/local/etc/nginx/redirect.default.conf', 'utf-8');
let sslSource = Handlebars.compile(sslTemplate, {noEscape: true});
let redirectSource = Handlebars.compile(redirectTemplate, {noEscape: true});
let config;

if(fs.existsSync('/config/config.json')) {
  config = require('/config/config.json');
};

if(fs.existsSync('/config/config.js')) {
  config = require('/config/config.js');
};

let execSync = require('child_process').execSync;
let target;
let doSelfSigned = fqdn => {
  console.log(execSync("/bin/bash /usr/local/bin/generate_selfsigned.sh " + fqdn).toString());
};

let doLetsEncrypt = fqdn => {
  console.log('Please wait, doing LetsEncrypt');
  try {
    console.log(execSync("/bin/bash /usr/local/bin/generate_letsencrypt.sh " + fqdn).toString());
  } catch(ex) {
    console.error('WARNING: LetsEncrypt failed');
  }
};

let doSslSite = site => {
  site.nameserver = execSync("cat /etc/resolv.conf | grep nameserver | head -n 1 | awk '{print $2}'").toString().replace('\n', '');
  site.upstreams = Object.keys(site.upstreams).map(key => {
    return {
      name: key,
      address: site.upstreams[key]
    };
  });

  site.paths = Object.keys(site.paths).map(route => {
    return {
      path: route,
      upstream: site.paths[route],
      fqdn: site.fqdn
    }
  });

  let result = sslSource(site);
  fs.writeFileSync(target, result);
};

let doRedirectSite = site => {
  let result = redirectSource(site);
  fs.writeFileSync(target, result);
};

Object.keys(config).forEach(key => {
  let site = config[key];
  target = "/etc/nginx/conf.d/" + site.fqdn + ".conf";
  site.csp = site.csp || "default-src 'self' wss: 'nonce-$cspNonce'";
  doSelfSigned(site.fqdn);
  if(site.redirect) {
    doRedirectSite(site);
  }else {
    doSslSite(site);
  }
  execSync('nginx -s reload');
  if(process.env.LETSENCRYPT === 'true') {
    doLetsEncrypt(site.fqdn);
    execSync('nginx -s reload');
  } else {
    console.log('Skipping LetsEncrypt');
  }
});
