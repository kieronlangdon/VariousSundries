#!/bin/bash
set -e
readonly TOKEN=${1}
readonly ORG=${2}


are_vars_defined()
{
  if [[ -z $TOKEN || -z $ORG ]];
  then
    echo "[ERROR] - Missing mandatory arguments: TOKEN, ORG"
    echo "[INFO]  - Usage: ./getRepos.sh [TOKEN] [ORG]"
    exit 1
  fi
}

authenticate()
{
  echo "[INFO]  - Authenticating using Token"
  curl -H 'Authorization: token '${TOKEN}'' https://api.github.com/api/v3
}

generate_list()
{
  echo "[INFO]  - Grabbing repos from Org ${ORG} adding to temp file Repos.log, We loop 4 times at the page limit of 100, assuming that an org won't have over 400 repos"
  echo "[INFO]  - Removing Repos.log if existent"
  rm -rf Repos.log
  for i in $(seq 1 4);
  do
    curl -H 'Authorization: token '${TOKEN}'' 'https://api.github.com/api/v3/orgs/'${ORG}'/repos?per_page=100&page='${i}'' | grep 'ssh_url": "' | sed 's/^.*: //' | sed 's/.$//' | sed 's/"//g'  >> Repos.log
  done
}

generate_html_links()
{
  echo "[INFO]  - Grabbing repos html links from Org ${ORG} adding to temp file RepoNames.log, We loop 4 times at the page limit of 100, assuming that an org won't have over 400 repos"
  echo "[INFO]  - Removing RepoNames.log if existent"
  rm -rf RepoNames.log
  curl -H 'Authorization: token '${TOKEN}'' 'https://api.github.com/api/v3/orgs/'${ORG}'/repos?per_page=100&page='${i}'' | grep html_url >> RepoNames.log
}

download_all_repos()
{
  echo "[INFO] - Downloading all repos from Repos.log"
  while read line; do
   git clone -v $line
   done < Repos.log
}

zip_all_folders()
{
  echo "[INFO] - Zipping all folders in dir $PWD"
  for i in */; do zip -0 -r "${i%/}.zip" "$i" & done; wait
}

main()
{
 are_vars_defined
 authenticate
 generate_list
 generate_html_links
 download_all_repos
 zip_all_folders
}

main
