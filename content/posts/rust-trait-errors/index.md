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
`E` can be.

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

We'll start off by creating a simple key-value utility that uses `String` for
both the key and the value. We will enforce that all keys must not be an empty
string, though, which will be our only error case. The implementation will be a
very thin wrapper around the standard library's `HashMap`.

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

    pub fn get(&self, key: impl AsRef<str>) -> Result<Option<String>, Something> {
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
error type.

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
required for a type to implement the
[error::Error](https://doc.rust-lang.org/std/error/trait.Error.html) trait as
well.

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
when we move to describing behavior through traits.

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
the functions async.

```rust
pub trait KVStore {
    fn insert(
        &mut self,
        key: impl AsRef<str>,
        value: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Something>> + Send;

    fn get(
        &self,
        key: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Something>> + Send;

    fn remove(
        &mut self,
        key: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Something>> + Send;
}
```

Our new `KVStore` trait now generalizes the three operations that the
`SimpleKVStore` implemented as async functions. This allows us to write code
that does not rely on any specific implementation of the trait. We could have
a test version of this code that is simply backed by a `HashMap`, another which
utilizes redis and a third that uses a custom Postgres implementation. Any of
these could be swapped for another and the calling code would not need to
change.

A question remains, however. What should `Something` be in the `Result::Err`
returned by each of our methods? Surely there are more modes of failure than we
account for with our `SimpleKVError` enum, what with the possibility of network
failures, timeouts and more. Of course, the value of the enum is that it can
have many more variants, but when designing a trait will we be able to foresee
all of the possible modes of failure in advance? Remember that we want our error
type to convey enough information to the user that they can make an informed
decision about whether recovery is possible and if so, how should it be done.

Ideally we would like to give as much information back to the user as we get
from the underlying library on which we build our implementation. The redis
crate, for instance, defines the
[RedisError](https://docs.rs/redis/latest/redis/struct.RedisError.html) type
which gives detailed data about any failures that occur. How can we get this
level of reporting back to callers of our trait?

### Associated types to the rescue?

If we want to offer the full fidelity of underlying errors, one solution could
be to update our trait to include an associated type that specifies the error
type that will be returned:

```rust
pub trait KVStore {
    type StoreError;

    fn insert(
        &mut self,
        key: impl AsRef<str>,
        value: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Self::StoreError>> + Send;

    fn get(
        &self,
        key: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Self::StoreError>> + Send;

    fn remove(
        &mut self,
        key: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Self::StoreError>> + Send;
}
```

Implementing this trait for a redis-backed version might then look something
like the following:

```rust
impl KVStore for RedisKVStore {
    type StoreError = RedisError;

    async fn insert(
            &mut self,
            key: impl AsRef<str>,
            value: impl AsRef<str>,
        ) -> Result<Option<String>, Self::StoreError> {
        // snip
    }
    // snip
}
```

This approach has two glaring problems, however. The first is that by simply
using `RedisError` we would have no way of communicating domain errors that
are not strictly arising within the redis stack. Secondly, the use of an
associated type in our return values now means that we have lost the decoupling
that we originally sought. We cannot swap out a redis-based implementation for
a memcached-based version unless our code strictly ignores all of the
values returned in the `Err` variant, which defeats the whole point of providing
meaningful errors. Associated types are powerful tools, but are wholely
inappropriate for this sort of problem.

### Traits for Trait Errors?

Programmers coming from languages like Java might wonder if the right solution
is akin to the following interface definition, which specifies that the method
can throw an `IOException`, including all of its subclasses, which could be
examined via reflection:

```java
interface I {
    void f() throws IOException;
}
```

Given that rust has no concept of subclasses, the closest analog would be to
specify that the error must implement a given trait. The standard library even
has a trait, `Error`, specifically meant for error types that was mentioned
above. And we can narrow down the possibilities for error types by creating our
own custom error trait which requires `Error` as a supertrait.

```rust
pub trait KVError: Error {
    // Methods useful for understanding KVError implementations
}

pub trait KVStore {
    fn insert(
        &mut self,
        key: impl AsRef<str>,
        value: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Box<dyn KVError>>> + Send;

    fn get(
        &self,
        key: impl AsRef<str>
    ) -> impl Future<Output = Result<Option<String>, Box<dyn KVError>>> + Send;

    fn remove(
        &mut self,
        key: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, Box<dyn KVError>>> + Send;
}
```

Traits can only specify behavior for implementations, though, so we would really
need to figure out what methods are important for understanding the sort of
failure that has occurred. It would also be beneficial if we could get back any
underlying error that is the root cause. Unfortunately, the burden for actually
writing these methods falls on the implementors of the trait. In fact, it's
work that will have to be duplicated for every single implementation.

What we really need is something that offers the elegance and simplicity of the
earlier enum-based approach combined with an ability to also expose details
that might be implementation-specific.

### Composition to the Rescue

We need to decouple the broader category of error from the underlying details.
We'll do this by explicitly enumerating the variety of errors that we think may
be encountered in a key-value store, including a catch-all `Other` variant.
Importantly, we mark this enum as
[non_exhaustive](https://rust-lang.github.io/rfcs/2008-non-exhaustive.html),
indicating that the number of variants could grow and that matches against this
type must always include a wildcard match arm. This is particularly important
because new error kinds could be added which may never affect existing
implementations.

```rust
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
#[non_exhaustive]
pub enum KVErrorKind {
    Authentication,
    InvalidKey,
    InvalidValue,
    // snip
    TimedOut,
    Other,
}

impl std::fmt::Display for KVErrorKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        use KVErrorKind::*;
        let disp = match *self {
            Authentication => "authentication",
            InvalidKey => "invalid key",
            InvalidValue => "invalid value",
            // snip
            TimedOut => "timed out",
            Other => "other",
        };
        write!(f, "{}", disp)
    }
}
```

In order to expose implementation-specific details of an error, we want to store
any underlying errors as well. We'll do this using the same `Box<dyn Error>`
approach we took with the method signatures earlier.

```rust
#[derive(Debug)]
pub struct KVError {
    kind: KVErrorKind,
    inner: Box<dyn Error + Send + Sync>,
}
```

Since we've kept the fields of `KVError` private we provide methods that will be
needed to create and interact with the type.

```rust
impl KVError {
    pub fn new<E>(kind: KVErrorKind, err: E) -> Self
    where
        E: Into<Box<dyn Error + Send + Sync>>,
    {
        Self {
            kind,
            inner: err.into(),
        }
    }

    pub fn kind(&self) -> KVErrorKind {
        self.kind
    }

    pub fn get_inner_mut(&mut self) -> &mut (dyn Error + Send + Sync) {
        &mut *self.inner
    }

    pub fn get_inner_ref(&self) -> &(dyn Error + Send + Sync) {
        &*self.inner
    }

    pub fn into_inner(self) -> Box<dyn Error + Send + Sync> {
        self.inner
    }

    pub fn downcast_inner<E>(self) -> Result<E, Self>
    where
        E: Error + Send + Sync + 'static,
    {
        if self.inner.is::<E>() {
            let ok = self.inner.downcast::<E>();
            Ok(*ok.unwrap())
        } else {
            Err(self)
        }
    }
}
```

Finally, let's round this out by implementing both `Display` and `Error` for the
`KVError` type. Note that we are explicitly implementing the `source` method for
the `Error` trait, rather than relying on the default implementation which
returns `None`. You should always do this when possible so that a full picture
of failure modes can be presented to the user.

```rust
impl fmt::Display for KVError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.kind)
    }
}

impl Error for KVError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        Some(&*self.inner)
    }
}
```

Updating the `KVStore` trait to use our new error type yields the following.

```rust
pub trait KVStore {
    fn insert(
        &mut self,
        key: impl AsRef<str>,
        value: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, KVError>> + Send;

    fn get(
        &mut self,
        key: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, KVError>> + Send;

    fn remove(
        &mut self,
        key: impl AsRef<str>,
    ) -> impl Future<Output = Result<Option<String>, KVError>> + Send;
}
```

What has all of this achieved for us? We now have an error type for our trait
which has the simplicity of an enum error type, but also the ability to expose
implementation-specific details when desired. It's easy for trait implementors
to provide concise, expressive errors. Users of an implementation are free to
write idiomatic code matching on the `KVErrorType` and only delve into the
details when they deem it necessary.

```rust
    // Implementation
    return Err(KVError::new(KVErrorKind::Authentication, authentication_error_from_lib));

    // ...

    // User
    match kv_error_from_result.kind() {
        KVErrorKind::Authentication => tracing::error!(
            "Encountered authentication error for key-value store: {}",
            kv_error_from_result.get_inner_ref()
        ),
        // snip
    }
```

The approach outlined above is not new. An excellent real-world example can be
found in the rust standard library's implementation of the
[std::io::Error](https://doc.rust-lang.org/std/io/struct.Error.html) struct
([source](https://doc.rust-lang.org/src/std/io/error.rs.html)).

{{% contactfooter %}}
