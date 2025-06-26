---
title: "Creating Ergonomic Error Types for Rust Traits"
date: 2025-06-17T16:15:57-07:00 # Date of post creation.
summary: "How can we craft errors for traits that are both easy to use from
  calling code as well as expressive for the implementors?"
description: "" # Description used for search engine.
featured: false # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
usePageBundles: true # Set to true to group assets like images in the same folder as this post.
#featureImage: "/images/path/file.jpg" # Sets featured image on blog post.
#featureImageCap: "This is the featured image." # Caption (optional).
#featureImageAlt: "Description of image" # Alternative text for featured image.
#thumbnail: "/images/path/thumbnail.png" # Sets thumbnail image appearing inside card on homepage.
#showShare: false # Uncomment to not show share buttons on each post. Also available in each post's front matter.
#shareImage: "/images/path/share.png" # Designate a separate image for social media sharing.
#showDate: false
#showReadTime: false
#sidebar: false
#singleColumn: true
#figurePositionShow: true # Override global value for showing the figure label.
#showRelatedInArticle: false # Override global value for showing related posts in this series at the end of the content.
categories:
  - Software Engineering
tags:
  - Rust
  - Architecture
  - Traits
# comment: false # Disable comment if false.
# codeMaxLines: 25
---

Failure is a fact of life. When we create software we must constantly contend
with processes that can either succeed or fail. In fact, for many use cases
there are far more ways that something can go wrong than it can go right.
Networks drop packets, credentials expire, drives fill up, etc. Ironically, many
languages choose to treat failure as an afterthought and merely handle error
cases with scaffolding around the expected successful path via try catch
mechanisms that introduce an alternate flow of control for error cases.

Rust's approach to fallible operations is to maintain a single flow of control
and instead express success or failure through the type system. The idiomatic
solution is to have functions return a `Result<T, E>` enum which will contain
either the desired `T` or an error `E` which should inform the caller about what
went wrong. This solution puts the reality of failure front and center for the
programmer, encouraging thoughtful handling of both possible outcomes.

Importantly, `Result` is not just generic over the success type `T`, but also
over the error type `E`. The definition puts absolutely no restrictions on what
`E` can be:

```rust
pub enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

This gives us tremendous flexibility in how we can implement and use the
idiomatic error handling pattern. Let's explore the reasons why we might need
flexibility in our error types and how it all comes together when crafting
usable traits.

### A Simple Error for a Simple Use Case

We'll start off by creating a simple key-value utility that uses a `String` for
both the key and the value. We will enforce that all keys must not be an empty
string, though, which will be our only error case. The implementation will be a
very thin wrapper around the standard library's `HashMap`:

```rust
pub struct SimpleKVStore {
    store: HashMap<String, String>,
}

impl SimpleKVStore {
    pub fn insert(
        &mut self,
        key: impl AsRef<str>,
        value: impl AsRef<str>,
    ) -> Result<Option<String>, Something> {
        if key.as_ref().is_empty() {
            Err(Something{ ... })
        } else {
            Ok(self.store.insert(key.as_ref().into(), value.as_ref().into()))
        }
    }

    pub fn get(&self, key: impl AsRef<str>) -> Result<Option<&str>, Something> {
        // Snip
    }

    pub fn remove(&mut self, key: impl AsRef<str>) -> Result<Option<String>, Something> {
        // Snip
    }
}
```

Our implementation leaves open the question of what type will be used for the
error case in our `Result`, though, by just putting in a placeholder `Something`
type that we've not defined. As we saw above, there are zero restrictions on
what type `E` can be for `Err(E)`, including the unit type `()`, although
specifying the unit type will produce a
[clippy warning](https://rust-lang.github.io/rust-clippy/master/index.html#result_unit_err).

Since the idea behind providing an error type is to communicate to the caller
what has gone wrong, let's use the type system and actually create a meaningful
error type:

```rust
pub struct EmptyKeyError {}

impl SimpleKVStore {
    pub fn insert(
        &mut self,
        key: impl AsRef<str>,
        value: impl AsRef<str>,
    ) -> Result<Option<String>, EmptyKeyError> {
        if key.as_ref().is_empty() {
            Err(EmptyKeyError {})
        } else {
            Ok(self.store.insert(key.as_ref().into(), value.as_ref().into()))
        }
    }
    // Snip
}
```

We now have a dedicated type, `EmptyKeyError`, that conveys information to the
caller about why and how an error can arise when using our `SimpleKVStore`
struct. Of course errors aren't simply there for the programmer who calls our
code, they frequently end up getting logged and displayed, so we really should
help out our users by implementing both `Debug` and `Display` for our error. The
rust standard library agrees on this point, and those two traits are all that is
required for a type to implement the `error::Error` trait as well:

```rust
#[derive(Debug)]
pub struct EmptyKeyError {}

impl std::fmt::Display for EmptyKeyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "invalid key requested: empty string not allowed for key")
    }
}

impl std::error::Error for InvalidKeyError {}
```

Unfortunately, the real world is rarely so simple as our contrived example. Most
processes can fail in more than one way, so we have to be prepared to
communicate that complexity to the user.

### Enumerating Failure

Let's introduce a second rule for our `SimpleKVStore`: all values kept in our
store must also be a non-empty string

In order to enforce this new rule, we simply check whether or not the value
being set or returned is an empty string. But we now have a problem in our
return type. If we return an `Err(EmptyKeyError)` when the value string is
empty, we are being neither honest nor helpful for our user. We need some way to
communicate both sorts of error, which is exactly what `enum` can do for us.

```rust
#[derive(Debug)]
pub enum SimpleKVError {
    InvalidKey,
    InvalidValue,
}

impl std::fmt::Display for SimpleKVError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let display_str = match *self {
            Self::InvalidKey => "invalid key requested: empty string not allowed for key",
            Self::InvalidValue => "invalid value: empty string not allowed for value",
        };
        write!(f, "{}", display_str)
    }
}

impl std::error::Error for SimpleKVError {}
```

Our new `SimpleKVError` enum allows us to give users of the `SimpleKVStore`
accurate, meaningful feedback when an error is encountered.

```rust
impl SimpleKVStore {
    pub fn insert(
        &mut self,
        key: impl AsRef<str>,
        value: impl AsRef<str>,
    ) -> Result<Option<String>, SimpleKVError> {
        if key.as_ref().is_empty() {
            Err(SimpleKVError::InvalidKey)
        } else if value.as_ref().is_empty() {
            Err(SimpleKVError::InvalidValue)
        } else {
            Ok(self.store.insert(key.as_ref().into(), value.as_ref().into()))
        }
    }
    // Snip
}
```

Using simple enums for errors is often sufficient when you are creating a
library. As the use cases grow and you add new constraints, you can add
corresponding variants to the enum with the knowledge that users will be aware
of these new failure modes because of rust's support for enforcing exhaustive
matches (just make sure you indicate this with corresponding SemVer updates).

Unfortunately, this simple approach to specifying errors can start to fall apart
when we start describing behavior through traits.

### Decoupling Systems with Traits

Our earlier `SimpleKVStore` is great for illustrative purposes, but such a thin
wrapper on rust's `HashMap` isn't really a very useful tool. Key-value stores,
however, are a crucial component in many distributed system architectures as a
place to hold state, a common cache among nodes and much more. Because of this
prevalence in system architectures there are also many different options to
choose from for your key-value store backend: redis, memcached, Cloudflare
Workers KV, and many more. If we want to write software that can work with any
of these solutions we'll need to generalize their operation through a trait that
sets out common behavior.

Let's keep this simple and ponder what would need to change from our
`SimpleKVStore` implementation above. The most obvious change is to make all of
the functions async:

```rust
pub trait KVStore {
    fn insert(
        key: impl AsRef<str>,
        value: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Something>> + Send;

    fn get(key: impl AsRef<str>) -> impl Future<Output = Result<Option<&str>, Something>> + Send;

    fn remove(
        key: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Something>> + Send;
}
```

Our new `KVStore` trait now generalizes the three operations that the
`SimpleKVStore` implemented as async functions, but the return type remains a
question. What should `Something` be in the `Result::Err` returned by each of our
methods?

{{% contactfooter %}}
