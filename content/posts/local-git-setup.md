+++
title = "Gitting setup with multiple git profiles: A letter to myself next time I setup a new development computer"
date = "2024-04-19"
+++

This is one of those topics that I never remember and always google. By the time I have it setup I happily work away and forget specifics.

So for my future self here is a basic setup to multiple git profiles.

## Creating a base `.gitconfig`

Create a base `.gitconfig` in your home folder. The config will specify sub config files that correspond to work envrionments contained in folders.

So for example we have the folder structure:

```tree
code
 ├── work
 │    ├── some-repo
 │    └── another-repo
 └── personal
      ├── stuff-you-shouldnt-work-on-at-work
      └── personal-project-worth-millions
```

The corresponding `.gitconfig` will be mapped to directory specific `.gitconfigs` also located in the home folder. So we'll expect something like the following in the parent `.gitconfig`.

```commandline
[includeIf "gitdir:~/code/work/"]
  path = ~/.gitconfig-work
[includeIf "gitdir:~/code/personal/"]
  path = ~/.gitconfig-personal
```

## Configuring the `.gitconfig` as a profile

So now I have split my work and personal git profiles. Or N profiles however may I need, nested under directory mappings.

Next I can setup different profiles for git `user`, `init`, and other configurations. User configurations are the most basic and essential for getting started.

```bash
[user]
 name = kolasniwash
 email = kolasniwash@gmail.com
```

Also because we aren't slave drivers, calling our main branch `master` is archaic. So please set the default branch to main. 

```[init]
 defaultBranch = main
```

Last, because we are using multiple profiles it's also likely we have multiple ssh keys setup. One ssh key corresponding to one profile, and one github/gitlab account.

This creates and annoying problem where when pulling/pushing to a repo we'll need to replace `github.com` with `github.com-personal` or `github.com-work` depending on the profile.

To improve this because I'm lazy and want to save the 27 secons it takes to add `-personal` or `-work` to the url I can add a `url` configuration to the `.gitconfig`. See the example below.

```bash
[url "git@github.com-kolasniwash:"]
 insteadOf = git:github.com:
 ```

## What did I just do?
All this does some pure magic for us. Now when we call `git init` we get a new repo with `main` as the default branch.

When I call a `git clone` on a repo I'll see that `github.com` is automatically interpreted as the url associated with the profile I'm working in.

This also applies to the remote url when calling `git push` type actions.
