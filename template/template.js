'use strict';
const Handlebars = require('handlebars');
const fs = require('fs');
const async = require('async');
const execSync = require('child_process').execSync;
const sslTemplate = fs.readFileSync('/usr/local/etc/nginx/ssl.default.conf', 'utf-8');
const redirectTemplate = fs.readFileSync('/usr/local/etc/nginx/redirect.default.conf', 'utf-8');
const sslSource = Handlebars.compile(sslTemplate, {noEscape: true});
const redirectSource = Handlebars.compile(redirectTemplate, {noEscape: true});

let config;
let target;

if(fs.existsSync('/config/config.json')) {
  config = require('/config/config.json');
}

if(fs.existsSync('/config/config.js')) {
  config = require('/config/config.js');
}

const doSelfSigned = fqdn => {
  console.log('Please wait, doing Self Signed (' + fqdn + ')');
  console.log(execSync('/bin/bash /usr/local/bin/generate_selfsigned.sh ' + fqdn).toString());
};

const doLetsEncrypt = fqdn => {
  console.log('Please wait, doing LetsEncrypt (' + fqdn + ')');
  try {
    console.log(execSync('/bin/bash /usr/local/bin/generate_letsencrypt.sh ' + fqdn).toString());
    console.log('LetsEncrypt finished (' + fqdn + ')');
  } catch(ex) {
    console.error('WARNING: LetsEncrypt exited with a non-zero status code.');
  }
};

const doSslSite = site => {
  /* jshint quotmark: false */
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
    };
  });

  const result = sslSource(site);
  fs.writeFileSync(target, result);
  console.log(`Generated SSL site configuration for ${site.fqdn}`);
};

const doRedirectSite = site => {
  const result = redirectSource(site);
  fs.writeFileSync(target, result);
  console.log(`Generated Redirect site configuration for ${site.fqdn}`);
};

const generateSiteConfigurationFiles = done => {
  console.log('Generating site configuration files');
  async.forEachOf(config, function (site, key, next) {
    target = `/etc/nginx/conf.d/${site.fqdn}.conf`;
    /* jshint quotmark: false */
    site.csp = site.csp || "default-src 'self' wss: 'nonce-$cspNonce'";
    doSelfSigned(site.fqdn);
    if(site.redirect) {
      doRedirectSite(site);
    } else {
      doSslSite(site);
    }
    next();
  }, err => {
    if(err) { return done(err); }
    console.log('Site configuration files generated.');
    execSync('nginx -s reload');
    done();
  });
};

const generateLetsEncryptCertificates = done => {
  if(process.env.LETSENCRYPT === 'true') {
    console.log('Generating LetsEncrypt certificates');
    async.forEachOfSeries(config, function (site, key, next) {
      doLetsEncrypt(site.fqdn);
      next();
    }, err => {
      if(err) { return done(err); }
      console.log('LetsEncrypt certificate generation complete');
      execSync('nginx -s reload');
      done();
    });
  } else {
    console.log('LetsEncrypt not enabled, skipping.');
    done();
  }
};

console.log('Starting templating...');
async.series([
  generateSiteConfigurationFiles,
  generateLetsEncryptCertificates
], err => {
  if(err) {
    throw err;
  }
  console.log('Templating complete');
});
