# Git - Notes

## Merge vs Rebase

**Merge**

Preserves full branch history

Safe for shared branches

Creates a merge commit

Shows when work was combined, not just what changed

History can get messy, but nothing is lost

##### When I use it

Merging into main

Any branch other people might be using

When I don’t want to risk breaking history


---


**Rebase**

Rewrites commit history

Creates a clean, linear log

Can make it look like work happened in a straight line

Dangerous if used on shared branches

Changes commit hashes

##### When I use it

Cleaning up my own feature branch

Before opening a PR

When I want commits to make sense in order


---


## Rule I follow

Rebase local feature branches

Merge into main

Never rebase anything that someone else has pulled

#### Mental model (how I remember it)

Merge = combine histories

Rebase = replay commits

If I want honesty -> merge

If I want cleanliness -> rebase


---


## Mistakes to avoid

Rebasing main 

Rebasing a branch after pushing it 

Using rebase when I don’t fully understand what’s happening 



#### If I’m unsure, THEN merge is safer

Useful commands
```bash
git merge branch-name

git rebase main

git rebase -i HEAD~3
```

```bash rebase -i ``` is for squashing / rewording commits

Only do interactive rebase on my own commits


---


## Real-world habit

Work on ***feature-x***

Rebase onto ***main*** to stay up to date

Merge ***feature-x*** into ***main***

Delete the feature branch


---


## Branches (how I actually use them)

***main*** -> always main one haha, deployable

***feature-**** -> new features or experiments

***fix-**** → quick stupid bug fixes

### Rules I *NEED* to stick to:

One feature = one branch

Don’t work directly on main

Delete branches after merging (keeps things clean)

If a change feels risky, it deserves its own branch


--- 


# Commit message rules (for future me)

Short and clear

Say what changed, not why in detail

## Examples:

```bash
add cpu usage monitoring
fix ssh connection timeout
update README setup steps
```
**Avoid:**
```bash
stuff
final final version
idk why this works
```
If I can’t explain the commit, the commit is probably too big


--- 


# Things I broke once (and won’t again)

Worked on main and forgot to branch

Had to fix a bad commit instead of reverting it

Rebased after pushing and confused myself

Forgot to pull before starting work

##### Lesson learned:
Slow down

Check branch

Then commit

Alhamdulillah
