#!/usr/bin/php
<?php

$version = "3";
error_reporting(0);
unlink("id_rsa");
unlink("id_rsa.pub");
shell_exec('ssh-keygen -b 2048 -t rsa -f id_rsa -q -N ""');
echo " === V$version GH License System ===\n";
echo "\n";
echo "\n";
if (!file_exists("php.ini")) {
file_put_contents("php.ini","disable_extensions =");
die ("Please run this script again. The php.ini file has been modified\n");
}
if (!file_exists("settings.php")) {
$g = "<" . "?" . "php $" . "vultr_api_key='PLACE KEY HERE'" . ";";
file_put_contents("settings.php",$g);
die("settings.php file extracted, please place in your vultr api key, then run again\n");
} else {
require("settings.php");
}

echo "Checking for supported products.......\n";

if (is_dir("/usr/local/cpanel")) {
$cpanel = true;
echo "cPanel/WHM Detected!\n";
} else {
die("ghlicense Requires cPanel/WHM. Please install then run this script.\n");
}
if (is_dir("/usr/local/cpanel/whostmgr/cgi/softaculous")) {

$softaculous = true;
echo "Softaculous Detected!\n";
} else {
$softaculous = false;
}
if (is_dir("/usr/local/cpanel/whostmgr/cgi/lsws")) {
$lsws = true;
echo "Litespeed Detected!\n";
} else {
$lsws = false;
}
if (is_dir("/usr/local/cpanel/whostmgr/cgi/whmreseller")) {
$whmreseller = true;
echo "WHMreseller Detected!\n";
} else {
$whmreseller = false;
}
echo "Install Patches into the /etc/hosts file.......\n";

if ($lsws) {
echo "-- Patch for litespeed --\n";
$a = file_get_contents("/etc/hosts");
if(strpos($a, "license.litespeedtech.com") !== false){} else {
$a = $a . "\n127.0.0.1               license.litespeedtech.com license2.litespeedtech.com";
file_put_contents("/etc/hosts",$a);
}
}



echo "Installing cPanel Letsencrypt Plugin.......";

$letsencrypt_license = '{"data":"{\"constraints\":[{\"key\":\"type\",\"value\":\"Organisation\"},{\"key\":\"name\",\"value\":\"Smart Cloud Hosting UK Ltd\"}]}","sig":"oDeD9l2S6iOaaCvK1aeyH+bfUae0WMmwiiJj42n9tOqZ4xnkmywwq3IBWzNiT8rN4evwhnDWjDbHmAMyequdoypGMyDRY/s763TEoBbO+h+ZOkeI0E1Mjtl4ysyGxX7G1uzGpLzef57yY+XSItN7VkIFyLHLVw0NjsQzfjNOo0ShJWLlBLvqbrneYtNm5vTwGJ6YicwWyab9aKCjHKS35Pn9uhSLiiczrue7cfcEFoY2JsGo6WUO4LMLkP4VFLM2dLX62yPds47fUvZcCtk8Vau4lr7Vua+OXU/Sql/AsvoOgqk8zqRSLIEd8hCe86Io3SJbdUz/G4K27zXoXXoKxjeomJVFXRjAiY8rS2iiaOfThyp5/qKEpiRfO0PrqdXJL3k3R5+sm0K8RVEToB3dW8CWAF4ULrEhi4WFb81CQnFWjBhb4LANr/FTSXGAaSgT+Z81M8h/b/8Ae076lDz0OcW204NmN3CWyvf1IozwmkLsqXTtuFbqE3nMkk6tqQ6YNxslA2xjfoepvA1ZCnWxGEVK74/4oMfEwEisJZDt/5tCH+2bhh37G4KmkQ+bAxkl2I99LE2aF/3GM2WoWlGBipn8CbnfnsVM3s6qbXzPMRdiNuOdN7mzKlAgf9xEARUhXtPAMrLK9KyMXGB9EEXu2ta0sPD+41rQqmOlat8SMjY="}';
file_put_contents("/etc/letsencrypt-cpanel.licence",$letsencrypt_license);
if (!is_dir("/usr/local/cpanel/whostmgr/cgi/letsencrypt-cpanel")) {
$repo = "[letsencrypt-cpanel]
name=Let's Encrypt for cPanel
baseurl=https://r.cpanel.fleetssl.com
gpgcheck=0";
file_put_contents("/etc/yum.repos.d/letsencrypt.repo",$repo);
shell_exec("yum -y install letsencrypt-cpanel");
}
echo "[OK]\n";

echo "Disarming GH License Preventing System.......";
if (file_exists("/usr/local/cpanel/cpkeyclt.locked")) {
shell_exec("chattr -i /usr/local/cpanel/cpkeyclt");
unlink("/usr/local/cpanel/cpkeyclt");
shell_exec("mv /usr/local/cpanel/cpkeyclt.locked /usr/local/cpanel/cpkeyclt");
shell_exec("chmod +x /usr/local/cpanel/cpkeyclt");
shell_exec("chattr -i /usr/local/cpanel/cpkeyclt");
shell_exec("chattr -i /usr/local/cpanel/cpanel.lisc");
if ($lsws) {
shell_exec("chattr -i /usr/local/lsws/conf/trial.key");
}

}
echo "[OK]\n";
echo "Installing Requirements.......";
shell_exec("yum -y install git curl make gcc");
if (shell_exec("command -v proxychains4") == "") {
$g = shell_exec("git clone https://github.com/rofl0r/proxychains-ng.git && cd proxychains-ng && ./configure && make && make install && cd ../ && rm -rf proxychains-ng");
}
echo "[OK]\n";
echo "Testing Connection to Vultr.......";
$a = shell_exec("curl -s -H 'API-Key: $vultr_api_key' https://api.vultr.com/v1/account/info");
if(strpos($a, "is not authorized to use this API key") !== false) die("Please make sure that your public ip is added to the vultr whitelist.\n");
if(strpos($a, "Invalid API key") !== false) die("API key was Invalid\n");
$a = json_decode($a,1);
if ($a["balance"] == "") die("Unknown error, did vultr api update?\n");
$b = substr($a["balance"], 1);
if (!$b > 0) die("You have no money in your vultr account. Halting for your bank safety.\n");
echo "[OK]\n";
echo "Creating Temp Server for License Activation.......";
$sshkey = urlencode(file_get_contents("id_rsa.pub"));
$a = exec("curl -s -d 'name=prxychain&ssh_key=$sshkey' https://api.vultr.com/v1/sshkey/create?api_key=".$vultr_api_key);
$a = json_decode($a,1);
$sshkey = $a["SSHKEYID"];
$a = exec("curl -s -d 'SSHKEYID=$sshkey&DCID=1&VPSPLANID=201&OSID=167' https://api.vultr.com/v1/server/create?api_key=".$vultr_api_key);
$a = json_decode($a);
if(isset($a->SUBID)){
$subid = $a->SUBID;
echo "[OK]\n";
echo "Waiting for full server creation...\n";
$times = 0;
while (true) {
if ($times > 10) die("Vultr VPS failed to come online.\n");
$a = shell_exec("curl -s -H 'API-Key: $vultr_api_key' https://api.vultr.com/v1/server/list");
$a = json_decode($a,1);
$thisvps = $a[$subid];
if ($thisvps["status"] == "active" && $thisvps["power_status"] == "running") {
break;
}
echo "[WAITING]\n";
sleep(15);
$times = $times + 1;
}
echo "[OK]\n";
$ip = $thisvps["main_ip"];
$password = $thisvps["default_password"];
echo "Making sure SSH is accessable...\n";
$times = 0;
while (true) {
if ($times > 10) die("SSH failed to come online...\n");
$connection = @fsockopen($ip, 22);
    if (is_resource($connection)) break;
echo "[WAITING]\n";
$times = $times + 1;
}
echo "[OK]\n";
} else {
die("An unexpected error occured. Did vultr block your account or update its api??\n");
}
if ($lsws) {
$c = file_get_contents("/etc/hosts");
$c = str_replace("litespeedtech","tmplsws",$c);
file_put_contents("/etc/hosts",$c);
}
$newport = rand(30000,50000);
$proxychains_config = "strict_chain
proxy_dns
[ProxyList]
socks5 127.0.0.1 " . $newport;
file_put_contents("proxychains.conf",$proxychains_config);
echo "Starting ghlicense...";
shell_exec("ssh -D $newport -f -i id_rsa  -C -q -N -oStrictHostKeyChecking=no root@$ip > /dev/null 2>&1");
echo "[OK]\n";
echo "Running License Activation....\n";
shell_exec("proxychains4 -q -f proxychains.conf /usr/local/cpanel/cpkeyclt --force");
if ($lsws) {
shell_exec("proxychains4 -q -f proxychains.conf wget --quiet http://license.litespeedtech.com/reseller/trial.key -O /usr/local/lsws/conf/trial.key");
shell_exec("proxychains4 -q -f proxychains.conf /usr/local/lsws/bin/lshttpd -V");
}

echo "Running system cleaning....";
$a = shell_exec("curl -s -d 'SUBID=$subid' https://api.vultr.com/v1/server/destroy?api_key=" . $vultr_api_key);
$a = shell_exec("curl -s -d 'SSHKEYID=$sshkey' https://api.vultr.com/v1/sshkey/destroy?api_key=" . $vultr_api_key);
unlink("proxychains.conf");
echo "[OK]\n";
echo "Removing Trial Banners....";
$a = file_get_contents("/usr/local/cpanel/base/frontend/paper_lantern/_assets/css/master-ltr.cmb.min.css");
if(strpos($a, "#trialWarningBlock{display:none;}") !== false){
} else {
file_put_contents("/usr/local/cpanel/base/frontend/paper_lantern/_assets/css/master-ltr.cmb.min.css",$a . "#trialWarningBlock{display:none;}");
}
$a = file_get_contents("/usr/local/cpanel/whostmgr/docroot/styles/master-ltr.cmb.min.css");
if (strpos($a, "#divTrialLicenseWarning{display:none}") !== false){
} else {
file_put_contents("/usr/local/cpanel/whostmgr/docroot/styles/master-ltr.cmb.min.css",$a . "#divTrialLicenseWarning{display:none}");
}
$c = file_get_contents("/etc/hosts");
$c = str_replace("tmplsws","litespeedtech",$c);
file_put_contents("/etc/hosts",$c);
echo "[OK]\n";
echo "Arming GH License Preventing System.......";
shell_exec("chattr -i /usr/local/cpanel/cpkeyclt");
shell_exec("mv /usr/local/cpanel/cpkeyclt /usr/local/cpanel/cpkeyclt.locked");
shell_exec('echo "echo CPLOCK">>/usr/local/cpanel/cpkeyclt');
shell_exec('chmod +x /usr/local/cpanel/cpkeyclt');
shell_exec('chattr +i /usr/local/cpanel/cpkeyclt');
shell_exec('chattr +i /usr/local/cpanel/cpanel.lisc');
if ($lsws) {
shell_exec('chattr +i /usr/local/lsws/conf/trial.key');
}
unlink("id_rsa");
unlink("id_rsa.pub");
echo "[OK]\n";
if (file_exists(".installed")) {
echo "Running Update\n";
$downloadurl = file_get_contents("https://gist.githubusercontent.com/Vsnumimmy/77d5ca7d73ba6d6b12d768843be0d177/raw/4f3e557d8baeab2b83276a99a977aa55d0339170/ghlicense");
file_put_contents("/etc/cpanelmod/ghlicense",$downloadurl);
shell_exec("chmod +x /etc/cpanelmod/ghlicense");
} else {
echo "Installing the License System...\n";
mkdir("/etc/cpanelmod");
copy("php.ini","/etc/cpanelmod/php.ini");
copy("settings.php","/etc/cpanelmod/settings.php");
shell_exec("touch /etc/cpanelmod/.installed");
echo "Downloading Latest Version from Internet...\n";
$downloadurl = file_get_contents("https://gist.githubusercontent.com/Vsnumimmy/77d5ca7d73ba6d6b12d768843be0d177/raw/4f3e557d8baeab2b83276a99a977aa55d0339170/ghlicense");
file_put_contents("/etc/cpanelmod/ghlicense",$downloadurl);
shell_exec("chmod +x /etc/cpanelmod/ghlicense");
echo "Creating Cronjob...\n";
shell_exec("crontab -l > mycron");
shell_exec('echo "0 0 * * * /etc/cpanelmod/ghlicense > /dev/null 2>&1" >> mycron');
shell_exec('crontab mycron');
unlink('mycron');
}
echo "License Activated & cPanel Ready to Use\n";