# Working with branches and pull requests

In a team, nobody pushes straight to `main`. Every change travels the same road:

```
branch  →  commits  →  push  →  pull request  →  review  →  merge
```

Why bother when you work alone?

- **`main` always works.** Half-finished work lives on a branch; `main` holds only reviewed changes.
- **Review happens next to the code.** A reviewer comments on exact lines, you answer and push fixes, and the whole conversation stays with the change.
- **History tells a story.** One pull request per feature or homework shows what changed and why.
- **CI hooks in here.** In session 2, tests and image builds run automatically on every pull request, before anything reaches `main`.

## The workflow, step by step

### 1. Start from an up-to-date `main`

```bash
git switch main
git pull
```

### 2. Create a branch

Name it after the work, e.g. the homework:

```bash
git switch -c hw1-twelve-factor
```

`git branch` shows the branch you are on, marked with `*`.

### 3. Commit in small steps

```bash
git status                      # what changed?
git add main.go dep.yml         # stage what belongs together
git commit -m "Add readiness probe on /readyz"
```

A good commit message says **what** changed, and **why** if that is not obvious:

| Instead of | Write |
|---|---|
| `fix` | `Fix crash when REDIS_ADDR is empty` |
| `asd` | `Add Redis Deployment and Service` |
| `changes` | `Pin image tag so rollbacks are reproducible` |

Before committing, check that nothing slips in that does not belong in a repository: compiled binaries, `.DS_Store`, passwords or tokens. List them in `.gitignore`.

### 4. Push the branch

The first push of a new branch needs `-u` to link it to GitHub:

```bash
git push -u origin hw1-twelve-factor
```

Later pushes on the same branch are just `git push`.

### 5. Open a pull request

```bash
gh pr create --base main --title "Homework 1: twelve-factor server" --body "Self-check output: ..."
```

Or on GitHub: after a push, a yellow **Compare & pull request** banner appears on your repository page. Click it, check that **base** is `main` and **compare** is your branch, write a description, and click **Create pull request**. Then add your instructor under **Reviewers**.

### 6. Answer the review

Your reviewer comments on lines in the **Files changed** tab. For each comment:

1. Fix it on the **same branch**: edit, commit, `git push`. The pull request updates itself; no new pull request needed.
2. Reply to the comment ("Fixed in a1b2c3d", or a question back if you disagree). Discussion is welcome.

### 7. Merge

When the review is approved, click **Merge pull request** on GitHub, then bring your local `main` up to date:

```bash
git switch main
git pull
git branch -d hw1-twelve-factor     # the branch is merged, delete it
```

## Already pushed to `main`?

No problem, nothing is lost. Two ways forward:

- **Next time, start with step 2.** Your existing work stays on `main` as it is.
- **If your reviewer opened a pull request for you** (a branch called `review/...` with suggestions), open its **Files changed** tab, read the comments, and reply. Merge it if you agree, or close it and make the changes yourself on a new branch of your own.

## Quick reference

| Task | Command |
|---|---|
| Which branch am I on? | `git branch` |
| New branch | `git switch -c <name>` |
| Switch branch | `git switch <name>` |
| What changed? | `git status`, `git diff` |
| Commit | `git add <files>` then `git commit -m "<message>"` |
| First push of a branch | `git push -u origin <name>` |
| Open pull request | `gh pr create` |
| Update `main` | `git switch main && git pull` |

## Sources

- [GitHub Docs: About pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
- [GitHub Docs: GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow)
- [Pro Git: Branches in a nutshell](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell)
- [GitHub CLI: gh pr create](https://cli.github.com/manual/gh_pr_create)
