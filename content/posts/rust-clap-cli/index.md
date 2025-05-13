---
title: "It's Types All the Way Down - Rust CLI with Clap" # Title of the blog post.
date: 2025-04-22 # Date of post creation.
description: "Using rust's strong typing to specify command line interfaces using the clap crate"
featured: true # Sets if post is a featured post, making it appear on the sidebar. A featured post won't be listed on the sidebar if it's the current page
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
usePageBundles: true # Set to true to group assets like images in the same folder as this post.
featureImage: "cli-hero.jpg" # Sets featured image on blog post.
# featureImageAlt: 'Description of image' # Alternative text for featured image.
# featureImageCap: 'This is the featured image.' # Caption (optional).
# thumbnail: "/images/path/thumbnail.png" # Sets thumbnail image appearing inside card on homepage.
# showShare: false # Uncomment to not show share buttons on each post. Also available in each post's front matter.
# shareImage: "/images/path/share.png" # Designate a separate image for social media sharing.
# figurePositionShow: true # Override global value for showing the figure label.
# showRelatedInArticle: false # Override global value for showing related posts in this series at the end of the content.
categories:
  - Software Engineering
tags:
  - rust
  - clap
  - cli
codeMaxLines: 25
---

### Types Define Interfaces

Types are important. In fact, I'd guess that the expressive type system in rust
is the single biggest reason why so many developers love the language. Types
allow us to have a contract between parts of the system about our data and how
to interact with it. All programming languages have the concept of types, but
these exist along several dimensions. Strongly typed vs weakly typed as well as
static vs dynamic typing. Rust stakes out its place as a statically,
strongly typed language.

Many languages that are go-to solutions for creating custom command line tools
fall in the opposite quadrant with weak, dynamic typing. Whether looking at
currently popular tooling like python and node.js or more traditional solutions
like awk and perl, they tend to favor a loose approach to types. Perhaps this
is the result of an iterative approach to designing CLI tools that might favor
flexibility. Or it could just be that those languages are already popular,
leading to an abundance of such programs. Regardless of the reasons, I feel that
there is tremendous value for both the developer and user which can arise from
interacting with the command line via the sort of strict contract that rust's
type system enables.

{{% notice note "Note" %}}
I assume that if you're already a rust developer, or at least rust-curious, then
I don't need to convince you of the general value of strong, static typing.
Rather, this is a call to use this same approach for interacting with a command
line user as you would when developing a library or service API.
{{% /notice %}}

### How Programs Interact with the Command Line

At the very lowest level rust exposes command line arguments through the
`std::env::args` function that returns an `Args` struct, an `Iterator` for the
`String` arguments passed to start the program. This is illustrated in the Rust 
Book's section on
[accepting command line arguments](https://doc.rust-lang.org/book/ch12-01-accepting-command-line-arguments.html):

```rust
use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();

    let query = &args[1];
    let file_path = &args[2];

    println!("Searching for {query}");
    println!("In file {file_path}");
}
```

The naive approach seen above obviously lacks robustness as it relies entirely
on argument positioning and also makes a number of other assumptions about the
results. Perhaps for very simple tools this solution can work but as the number
and types of arguments increases, it seems unlikely that a developer would want
to try and rely on just argument position for the interface to their program.
One approach would be to examine all of the arguments passed in and parse these
for patterns that would allow customary `-x` and `--x_long` style options. Doing
this by hand for every CLI tool would be error-prone and tedious, but
fortunately some awesome folks have done that for you with the excellent
[clap](https://github.com/clap-rs/clap) crate.

### The Sound of One Hand Clapping

The Command Line Argument Parser for Rust, or clap, is one of the most
widely-used crates in the rust ecosystem. GitHub shows that there are over 445k
repos which depend on clap at the time of writing. Adding clap to your project
will allow you to avoid writing your own parsing logic to interact with the
command line:

```fish
❯ cargo add clap
```

Out of the box clap offers a builder pattern approach that can be used to
get arguments from the command line without the hassle of parsing an `Iterator`
of `String` values:

```rust
use clap::{Command, arg};

fn main() {
    let cmd = Command::new("clap_test")
        .arg(arg!([main_arg] "The main argument, with no flags"))
        .arg(arg!(-x --x_long "Enable x long mode"));
    let matches = cmd.get_matches();
    if let Some(main_arg) = matches.get_one::<String>("main_arg") {
        println!("Main argument: {main_arg}");
    } else {
        println!("No main argument passed in");
    }
    if matches.get_flag("x_long") {
        println!("x long mode: enabled");
    } else {
        println!("x long mode: not enabled");
    }
}
```

Your users can now invoke the above `clap_test` program from the command line
and pass in the main argument and optionally enable your x long mode:

```fish
❯ clap_test foo -x
Main argument: foo
x long mode: enabled
```

Clap offers a lot more than just parsing arguments, though. It can also reject
options and arguments that are not specified by the programmer and it provides
built-in help:

```fish
❯ clap_test -h
Usage: clap_test [OPTIONS] [main_arg]

Arguments:
  [main_arg]  The main argument, with no flags

Options:
  -x, --x_long  Enable x long mode
  -h, --help    Print help
```

Okay, so I think we can all agree that clap has some nice features and is far
more robust than trying to roll your own command line argument parser, but this
post started off talking about rust's type system and how that can be used as an
interface with the command line user. And that is where clap's `derive` feature
comes in.

### Defining Your CLI Interactions with `derive`

Clap offers a much more ergonomic way to specify your program's arguments than
the builder method shown above, but first you need to include the `derive`
feature in your dependencies:

```fish
❯ cargo add clap -F derive
```

You can now define rust types in your program which will be translated into an
interface contract for your program when called from the command line:

```rust
use clap::Parser;

/// Program to illustrate clap usage
#[derive(Parser)]
pub struct Args {
    /// The main argument, with no flags
    pub main_arg: Option<String>,
    /// Enable x long mode
    #[arg(short, long, default_value_t = false)]
    pub x_long: bool,
}

fn main() {
    let args = Args::parse();
    if let Some(main_arg) = args.main_arg {
        println!("Main argument: {main_arg}");
    } else {
        println!("No main argument passed in");
    }
    if args.x_long {
        println!("x long mode: enabled");
    } else {
        println!("x long mode: not enabled");
    }
}
```

The above program behaves identically to the builder version from the previous
section, with a `-h` help option and all the other features that clap offers.
The key difference is that we are now using the type system to define the
interface rather than imperative calls to a builder. Note that the doc
comments for the `Args` struct are used to build the `-h` help subcommand for
the resulting program.

Clap isn't limited to simple structs for the definition of the interface either.
As shown above, `Option` works just as you would expect. To build up truly
complex command line interactions you can use enums to define subcommand syntax 
with configuration options for each different subcommand via associated values 
(think `git` or `npm` subcommands). Clap is well suited to building complex
command line applications.

There are tons of great features in clap that can be found in the
[docs](https://docs.rs/clap/latest/clap/index.html), but rather than get into
the specifics of this crate, I want to discuss how type-driven design
can elevate command line interfaces to be on equal footing with published
libraries and service APIs. What can be gained from specifying your
software's command line interactions via the rust type system?

### Advantage 1: Code Maintainability and Readability

Perhaps the most obvious benefit of using explicit rust types to define your
command line interface is that it provides a clear, concise definition of what
input the program accepts. If you peel away the clap macro calls which annotate
the type, it looks just like any other data structure that you would expect to
pass between portions of the program. Because clap builds help from the doc
comments the developer documentation for the type also transcends the command
line boundary to help users understand how to properly use your software. There
are no[**](#good-for-the-environment-too) hidden inputs that will affect your
program. This helps new developers on a project to understand a codebase and
also assists maintainers down the road when they need to add new features, as
there is a single entry point from which they can start designing their changes.

Alternative approaches such as using the builder pattern or a custom parsing of
`std::env::args` don't offer this same clarity. At best, these solutions would
be contained in one or more functions that abstract away the interface logic. At
worst these could be scattered across the codebase as each portion of the
program tries to interact directly with the arguments passed in.

As software grows in complexity the case grows stronger for type-driven CLI
specification. Imagine that we are creating a tool which will interact with a
key-value store and allow the user to add, remove and list the entries of the
store, all of which also require an access token to validate the user. We could
use the following to model the interface:

```rust
pub struct Args {
    pub token: String,
    pub action: Action,
}

pub enum Action {
    Add {
        key: String,
        value: String,
    },
    Remove {
        key: String,
    },
    List,
}
```

The `Args` type that we've outlined above allows us to clearly express that a
token is always required for all actions, but the `key` argument is only needed,
and indeed only allowed, when the user is either adding or removing entries. The
type that we have created is concise and removes the complexity one would have
to deal with if command line arguments were being handled imperatively.

### Advantage 2: Reduced Test Surface Area and Mock Support

Using a crate like clap can eliminate huge swathes of imperative code that would
otherwise be necessary to parse, validate and consume arguments from the command
line. Every line of code that you don't write saves time on tests that don't
need to be created as well. Moving your interaction with the command line from
imperative functions to a declarative description of possible states moves the
testing burden upstream to the maintainers of the clap crate, which is widely
used and well supported.

Type-driven command line interaction does more for us than just reducing the
surface area, though. It also provides a foundation for more complete unit tests
by providing the simplest possible mock for an actual command line interaction.
Imagine that our key-value client above delegates each of the top-level actions
(add, remove, list) to one function each, where more complex operations are
orchestrated. Something like the following:

```rust
pub enum KVStoreError {
    InvalidRequest,
    NetworkError,
}

fn add_item(add_req: &Args) -> Result<String, KVStoreError> {
    let Action::Add { key, value } = &add_req.action else {
        return Err(KVStoreError::InvalidRequest);
    };
    // ... complicated things happening ...
    Ok(key_returned_from_server)
}
```

Some obvious tests of the above method might involve asserting that `add_item`
would return an `Err` wrapping a `KVStoreError::InvalidRequest` if we call the
function with `Action::List`, for instance. We could also verify that the key
returned by the server matches the key we requested to add:

```rust
#[test]
fn verify_add_test_key_match() {
    let add_args = Args {
        token: "ABC_123".to_owned(),
        action: Action::Add {
            key: "foo".to_owned(),
            value: "bar".to_owned(),
        },
    };
    let Ok(returned_key) = add_item(&add_args) else {
        panic!("Error adding entry with add_item");
    };
    assert_eq!(returned_key, "foo", "Key mismatch in add_item");
}
```

The above test is simplistic, but it is representative of the way data must be
structured from an actual user because of the strict typing. This approach gives
us a high fidelity mock of a command line interaction.

### Advantage 3: Semantic Versioning: Not Just for Libraries

Semantic versioning, or SemVer, is a widely-used framework for determining how
software creators should version their releases so that downstream users of that
code can confidently know what versions are safe to upgrade to from other
versions. It leads to the familiar three-part version number consisting of
*Major.Minor.Patch* where each component conveys different levels of change and
potential upgrade risk. The rust core team follows SemVer for rust releases and
even have an extensive
[section](https://doc.rust-lang.org/cargo/reference/semver.html) about the topic
in the Cargo Book.

Library maintainers generally follow SemVer so that other developers who depend
on their crate can understand when it is safe to upgrade without needing to
delve into the release notes of every single release. Authors of binary tools,
however, have been less likely to strictly follow SemVer, as illustrated by the
[rustup 1.28.0](https://blog.rust-lang.org/2025/03/04/Rustup-1.28.1/) adventure,
wherein a minor release ended up breaking CI for many rust projects.

Perhaps the reason why authors of binary CLI tools are less likely to follow
SemVer is because they have an image in their head of the user being a person
who can adapt to changes between versions. The reality, however, is that any
sufficiently useful CLI tool will eventually be integrated into an automated
toolchain that expects input and output to be consistent across versions. Good
CLI tools end up operating very similarly to a library. Unlike libraries,
though, upgrading a binary version doesn't get a chance to throw compiler
errors. Worse yet, CLI tools are often integrated in parts of the stack where
observability is poor and errors are only discovered when catastrophic failure
has already occurred.

So, how can a strictly-typed approach to command line arguments help us to
better follow SemVer with CLI applications? The answer to this is through
tooling that already exists,
[cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks). This
cargo tool examines your source code and compares it against a prior release
in order to determine if your changes constitute major, minor or merely
patch level changes. Importantly, though, you should begin to think of your
command line program more like a library in order to help cargo-semver-checks
to analyze the importance of changes. Your CLI argument types should be made
`pub` even if this level isn't required for your program to run properly.
They are, after all, truly the most public part of the software. A similar
approach is also reasonable with the types that might represent your program's
output, whether they are used to write back to the shell, to files or some other
form of output. Once you've done this, start versioning your binaries
accordingly. If cargo-semver-checks warns you that a change is major and you
only thought that it was a patch, that's a big warning. Did you really intend to
make a major, breaking change? If you did, then don't hesitate to change the
major version number.

Merely knowing about a tool like cargo-semver-checks and having it installed
is nice, but we all know that things like this are best when they become an
automated part of our workflow. It's easy to add a GitHub Action to run a SemVer
check automatically:

```yaml
- name: Check semver
  uses: obi1kenobi/cargo-semver-checks-action@v2
```

Now, even if you forget to run your SemVer check manually, you probably won't
push out a binary release that breaks some dependency in a completely hidden
way.

### Good for the Environment Too

There is a loose end that may have been nagging at some readers going over the
previous sections: *What about environment variables?* After all, many command
line programs can also look at the shell's environment variables as a source of
input. We see this particularly around secrets or omnipresent settings.
Fortunately clap has us covered here too with the crate feature `env` that lets
you specify an environment variable which will be queried when a given argument
was not specified as part of the command invocation.

```fish
❯ cargo add clap -F env
```

Let's use this to flesh out the code from our key-value store client example in
the [maintainability](#advantage-1-code-maintainability-and-readability) section
above. In that example, it would make a lot of sense to make `token` an argument
which can be stored in an environment variable as well as be overridden from the
command line.

```rust
use clap::{Parser, Subcommand};

/// Simple client for a key value store
#[derive(Parser)]
pub struct Args {
    /// Access token
    #[arg(short, long, env = "ACCESS_TOKEN")]
    pub token: String,
    /// Action
    #[command(subcommand)]
    pub action: Action,
}

/// Modes of operation for this key value client
#[derive(Subcommand)]
pub enum Action {
    /// Add a new entry
    Add {
        /// Key used for new entry
        #[arg(short, long)]
        key: String,
        /// Value to be inserted
        #[arg(short, long)]
        value: String,
    },
    /// Remove an entry by key
    Remove {
        /// Key to find and remove from the store
        #[arg(short, long)]
        key: String,
    },
    /// List the keys present in the store
    List,
}

fn main() {
    let args = Args::parse();
    let token = args.token.clone();
    println!("Access token: {token}");
    match args.action {
        Action::Add { key, value } => {
            println!("Add called with ({key}, {value})");
        }
        Action::Remove { key } => {
            println!("Remove called for key {key}");
        }
        Action::List => {
            println!("List called");
        }
    }
}
```

All that was required (aside from adding the `env` feature to our dependencies)
was to add `env = "ACCESS_TOKEN"` on line 7. The user can now either pass in the
token via `-t FOOBAR` or by setting the environment variable `ACCESS_TOKEN`. The
generated help will automatically pick this up and educate the user about this
option (line 13 below):

```fish
❯ clap_test help
Simple client for a key value store

Usage: clap_test --token <TOKEN> <COMMAND>

Commands:
  add     Add a new entry
  remove  Remove an entry by key
  list    List the keys present in the store
  help    Print this message or the help of the given subcommand(s)

Options:
  -t, --token <TOKEN>  Access token [env: ACCESS_TOKEN=]
  -h, --help           Print help
```

We are now able to have a fully type-driven specification of our command line
interface that seamlessly incorporates both the arguments passed in as well as
environment variables from the shell. What's not to love?
