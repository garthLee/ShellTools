#!/bin/bash
current_branch=`git branch --show-current`
ignore_branches=（"master","release/*","\* $current_branch"）
git branch > all_branches.bak

cat all_branches.bak | while read line 
do
    if [[ "${ignore_branches[@]}" =~ "$line" ]] ; then
        echo "======keep branch $line======"
    else
        git branch -D "$line"
    fi
done

rm all_branches.bak