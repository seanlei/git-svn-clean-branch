#!/usr/bin/env bash

# Delete references to SVN branches that no longer exist
# Usage (this will not execute without asking you to confirm the list):
# bin/git-svn-prune.sh

# Started with 

# Set your SVN prefix
GIT_SVN_PREFIX="svn/"

SVN_REPO=$(git config --get svn-remote.svn.url)
GIT_SVN_PREFIX_SED=$(echo "$GIT_SVN_PREFIX" | sed -e 's/[\/&]/\\&/g')
SVN_BRANCHES_URL="$SVN_REPO"/branches
TEMP_DIR=$(mktemp -d -t git-svn-prune)
SVN_BRANCHES_FILE="$TEMP_DIR/svn-branches"
GIT_BRANCHES_FILE="$TEMP_DIR/git-branches"
OLD_BRANCHES_FILE="$TEMP_DIR/old-branches"

svn ls "$SVN_BRANCHES_URL" | sed 's|^[[:space:]]*||' | sed 's|/$||' > "$SVN_BRANCHES_FILE"

if [[ ! -s "$SVN_BRANCHES_FILE" ]]
then
    echo "No remote SVN branches found at \"$SVN_BRANCHES_URL\". Check configuration."
    exit 1
fi

git branch -r | sed 's|^[[:space:]]*||' > "$GIT_BRANCHES_FILE"
if [[ $GIT_SVN_PREFIX ]]
then
    sed -i -e 's/^'"$GIT_SVN_PREFIX_SED"'//' "$GIT_BRANCHES_FILE"
fi
sed -i -e '/^tags/d;/\//d;/trunk/d' "$GIT_BRANCHES_FILE"

if [[ ! -s "$GIT_BRANCHES_FILE" ]]
then
    echo "Your local git repository contains no references to any SVN branches at all, deleted or not. Check configuration."
    exit 1
fi

diff -u "$GIT_BRANCHES_FILE" "$SVN_BRANCHES_FILE" | grep '^-' | sed 's|^-||' | grep -v '^--' > "$OLD_BRANCHES_FILE"
if [[ $GIT_SVN_PREFIX ]]
then
    sed -i -e 's/^/'"$GIT_SVN_PREFIX_SED"'/' "$OLD_BRANCHES_FILE"
fi

if [[ -s "$OLD_BRANCHES_FILE" ]]
then
    echo "References to deleted SVN branches were found in your local git repository:"
    echo
    cat "$OLD_BRANCHES_FILE" | sed 's/^/   - /'
    echo
    read -p 'Delete the references from local git respository? Press "y" or "n" ' -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo
        for BRANCH in `cat "$OLD_BRANCHES_FILE"`

        do
            echo "Deleting $BRANCH ..."
            git branch -d -r "$BRANCH"
            rm -rf .git/svn/refs/remotes/"$BRANCH"
        done
   fi
else
    echo "Your local git repository contains no references to deleted SVN branches."
fi ;
