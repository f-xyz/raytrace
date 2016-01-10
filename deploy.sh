#!/usr/bin/env bash

git pull
git status
git branch -D gh-pages
git branch gh-pages

#npm test

#echo -e "\n"
#echo "Commit message: $1";
#echo "Press any key to commit. Ctrl+C to cancel."
#read -n 1 -s

commitMessage=$1
: ${commitMessage:='.'}

git add --all .
git commit -m "${commitMessage}"
git push --all
