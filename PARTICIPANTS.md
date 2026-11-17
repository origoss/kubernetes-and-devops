# Participants

| GitHub user | Repository |
|---|---|
| bzbrn | https://github.com/bzbrn/hello |
| Marci0224 | https://github.com/Marci0224/hello |
| MarkusIfquil | https://github.com/MarkusIfquil/Kubernetes-course |
| RobertNagy299 | https://github.com/RobertNagy299/kubernetes-course-origoss-personal |

## Add yourself

Send a pull request. It is good practice for the homework workflow:

```bash
gh repo fork origoss/kubernetes-and-devops --clone
cd kubernetes-and-devops
git switch -c add-<your-github-user>
# add one row to the table above, keep it sorted by GitHub user
git commit -am "Add <your-github-user> to participants"
git push -u origin add-<your-github-user>
gh pr create --repo origoss/kubernetes-and-devops --base main --fill
```

Your repository link should point at the repo where you submit your homework.
