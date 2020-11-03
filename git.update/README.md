# Update git repository by Cron-Script

**Caution:** All local changes are discarded if not excluded by [.gitignore](https://git-scm.com/docs/gitignore).

* change path to git.list in git.update.sh
* chmod +x git.update.sh
* fill git.list with git repository
* copy git.update.cron.d to /etc/cron.d/
* chmod +x /etc/cron.d/git.update.cron.d

# Example of git.list

The git directory is separated by ":" from the branch-name.
```
/path/to/git/root/:branch
/git/home/directory/:main
```
