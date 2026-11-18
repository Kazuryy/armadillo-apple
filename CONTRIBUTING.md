## Contributing

Contributions are welcome! Open an issue or pull request on this repository.

### Branch workflow

`main` and `develop` are protected: no direct pushes, force-pushes, or branch deletion, even for admins. All changes go through a pull request:

```bash
git checkout -b <branch>
git push -u origin <branch>
gh pr create --base develop   # or main
gh pr merge --squash
```

Merges are squash-only and delete the head branch automatically, so reset local branches afterward with `git reset --hard origin/<branch>` instead of pulling.

### Licensing

This project is licensed under AGPL-3.0 (see [LICENSE](LICENSE)). By submitting a contribution, you agree that it will be distributed under the same license.
