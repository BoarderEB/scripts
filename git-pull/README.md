# Update git repository by Cron-Script

**Caution:** All local changes are discarded if not excluded by [.gitignore](https://git-scm.com/docs/gitignore).

* copy git-pull to /usr/bin/
* copy git.list to /etc/git/
* fill git.list with git repository
* copy git-pull-cron to /etc/cron.d/

# Example of git.list

The git directory is separated by ":" from the branch-name.
```
/path/to/git/root/:branch
/git/home/directory/:main
```
