#!/bin/sh

set -e

SVN_REPO=<repo_path>
GIT_REPO=<repo_path>
TMP_DIR=$(pwd)/tmp
#https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git
USERS_LIST=$(pwd)/users.txt

mkdir -p ${TMP_DIR}

cd ${SVN_REPO}
revs_list=$(svn log -r1:HEAD | grep "^r" | cut -d\| -f1)

for r in ${revs_list}; do
    cd ${SVN_REPO}
    echo -n "${r}: make patch;"
#   svn log --diff -${r}
    if [ ! -f ${TMP_DIR}/${r}.patch ]; then
        svn log --diff -${r} > ${TMP_DIR}/${r}.patch 2>&1
        svn log -${r} | tail -n +2 | head -n -1 > ${TMP_DIR}/${r}.log
        svn log -${r} | tail -n +4 | head -n -1 > ${TMP_DIR}/${r}.comment
    fi
    svn_author=$(cat ${TMP_DIR}/${r}.log | grep "^r" | cut -d\| -f2 | sed "s/ //g")
    git_author=$(cat ${USERS_LIST} | grep "^${svn_author}" | cut -d= -f2 | sed "s/^ //g")
    commit_date=$(cat ${TMP_DIR}/${r}.log | grep "^r" | cut -d\| -f3 | awk -F' ' '{print $1" "$2" "$3}')
    cd ${GIT_REPO}
    echo -n " apply patch;"
    patch -p0 < ${TMP_DIR}/${r}.patch
    echo -n " add to git;"
    git add .
    echo -n " commit;"
    GIT_COMMITTER_DATE="{$commit_date}" git commit -F ${TMP_DIR}/${r}.comment --author="${git_author}"
    GIT_COMMITTER_DATE="{$commit_date}" git commit --amend --no-edit --date="{$commit_date}"
    echo " done"
done
