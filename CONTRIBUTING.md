# How to contribute to Net::HTTP

Many thanks for taking the time to contribute!

These are some guidelines intended to help you contribute to `Net::HTTP`.

In general, if you want to submit code and/or documentation changes, first
[fork the
project](https://docs.github.com/en/get-started/quickstart/fork-a-repo) and
provide your contribution as a [pull
request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request).

## Setting up the development environment

It is recommended that you install [perlbrew](https://perlbrew.pl/) and so
that your Perl distribution and any modules you install are local to your
user account and hence don't conflict with any system-wide programs and
modules which may already be on your computer.

### perlbrew quick start guide

Assuming a Linux-like environment and the `bash` shell, here is how to get
your `perlbrew` environment up and running quickly.

Install `perlbrew` by running the following command:

```
\curl -L https://install.perlbrew.pl | bash
```

Add the `perlbrew` environment setup script to your shell's startup files so
that `perlbrew` is available each time you start a shell:

```
echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.profile
```

To initialise the `perlbrew` environment directly, run:

```
source ~/perl5/perlbrew/etc/bashrc
```

Ensure that you install
[`cpanm`](https://metacpan.org/dist/App-cpanminus/view/bin/cpanm) to make
module installation easier:

```
perlbrew install-cpanm
```

Now you can install your very on local Perl version.  To see which Perl
versions are available to install, use the `available` subcommand:

```
perlbrew available
```

To install a given Perl version specify the version when invoking the
`install` subcommand, e.g.:

```
perlbrew install 5.34.1
```

Note that it will take several minutes for Perl to build, test and be
installed.

Now you can `switch` permanently to your new Perl version:

```
perlbrew switch 5.34.1
```

### Installing `Dist::Zilla`

[`Dist::Zilla`](https://metacpan.org/pod/Dist::Zilla) is a distribution
builder and is used in this project to handle upstream module dependencies
as well as run the test suite.  To install `Dist::Zilla` run:

```
cpanm --notest Dist::Zilla
```

You should now find that the `dzil` command is available, e.g.:

```
dzil --help
```

## Building and testing the distribution

Clone your fork of the repository to your local development environment and
change into the directory this creates:

```
git clone git@github.com:<username>/Net-HTTP.git
cd Net-HTTP
```

Now install any dependencies that are missing from your local Perl
installation with the `dzil` command:

```
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm
```

To run the test suite use `dzil test`:

```
dzil test
```

If you see a message at the end of the output similar to this:

```
All tests successful.
Files=6, Tests=29,  1 wallclock secs ( 0.07 usr  0.02 sys +  0.85 cusr  0.11 csys =  1.05 CPU)
Result: PASS
```

then the test suite has passed and you've now got a good foundation upon
which you can base your contribution.

## Contributing a change to the code and/or documentation

Code and documentation contributions are prepared on branches which are
pushed to your remote fork on GitHub (also known by the name `origin`) and
are submitted as pull requests.  A good pull request will focus on one
specific topic such as a fix for a particular bug or a typo fix in the
documentation.  Please do not submit pull requests which mix different kinds
of changes together.  For instance, don't submit a bug fix which also fixes
an unrelated typo in a comment and reformats a separate part of the code:
these should be submitted in separate pull requests.

### Call the upstream repository 'upstream'

When keeping your local repository up to date with the state of the upstream
project's remote repository, it is useful to refer to it as simply
`upstream`.  Note that you only need to do this step *once*: you do not
need to do this for each contribution.  To give the remote repository of the
upstream project the name `upstream` use the following `git` command:

```
git remote add upstream git@github.com:libwww-perl/Net-HTTP.git
```

### Update local `master` branch with `upstream`'s `master` branch

Before working on a contribution it is important that you have the most up
to date state of the `upstream` project's `master` branch.  First fetch the
state of the upstream `master` branch, and then merge this into your local
`master` branch so that your local repository is completely up to date:

```
git fetch upstream master
git merge upstream/master
```

### Create an appropriately-named branch

Using a good name for your branch makes it much easier to refer to your
contribution.  Suppose you provide a fix for the [issue that using HTTP
proxy hangs](https://github.com/libwww-perl/Net-HTTP/issues/25); you could
name your branch something like `http-proxy-hang-fix`.  To create a branch
with this name and immediately switch to the new branch, use `git checkout`
with the `-b` option:

```
git checkout -b http-proxy-hang-fix
```

### Make the change

Now that you have checked out your feature branch, you're ready to implement
your fix (or whatever change you wish to contribute).  Now comes the fun
part: hacking the code!  Commit your changes and prepare your branch for
submission.

### Ensure the test suite passes

Before submitting any change, please ensure that the test suite passes:

```
dzil test
```

### Push your branch to your repository's origin

If you're satisfied with the code changes and the test suite still passes,
you can push the changes on your feature branch to your remote fork on
GitHub (also known by the name `origin`):

```
git push
```

### Create a pull request

Now you're ready to create a [pull
request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork)
to submit your proposed changes.  Using the GitHub web interface, prepare a
pull request which compares the changes in your fork's feature branch with
the `master` branch of the main project.

Please provide a concise yet descriptive title for the change you are
proposing.  Also provide a full description of the changes in your pull
request within the description field and why these changes solve a
particular problem as well as any background information which might be
relevant.

As soon as you're ready, click on the "Create pull request" button to submit
your pull request, and you're done!

Many thanks for your contribution!
