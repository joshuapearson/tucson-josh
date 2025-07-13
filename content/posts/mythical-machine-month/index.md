---
title: "The Mythical Machine-Month Paradox"
date: 2025-07-01
summary: "" # Summary that will display on the list page
description: "" # Description used for search engine.
featured: false # Sets if post is a featured post, making appear on the home page side bar.
draft: true # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
usePageBundles: true # Set to true to group assets like images in the same folder as this post.
featureImage: "mythical-machine-hero.jpg"
#featureImageCap: "This is the featured image." # Caption (optional).
featureImageAlt: "A wooden drawing mannequin posed against a dark background" # Alternative text for featured image.
thumbnail: "mythical-machine-thumb.jpg"
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
# comment: false # Disable comment if false.
# codeMaxLines: 25
---

The software industry is in the midst of an identity crisis. The biggest
companies in the field are laying off experienced workers by the thousands and
new college grads are struggling to even land interviews. A profession which had
only experienced growth for more than two decades now fears a bleak future and
sees question marks over where it's headed. The catalyst for all of this is the
rise of generative AI, with some big corporate leaders making
[claims](https://www.businessinsider.com/microsoft-cto-ai-generated-code-software-developer-job-change-2025-4)
that 95% of code will be written by AI by the end of the decade. Could this come
to pass, and if so, where does that leave software engineers?

### The Siren Song

There's a clear reason why generative AI is such a hot topic in the software
industry right now: it can spin out huge amounts of novel source code in very
little time. More tempting still, the interface to this whole process is just
plain old English (or whatever language you speak that the system understands).
You just tell the AI that you want a program that does some particular thing and
it returns back code that is supposed to do said thing.

If you put yourself into the shoes of an executive, this may not seem very
different from how software has been made for decades, so long as you consider
the actual software creation process as a black box. In the eyes of our
executive, however, this new black box has two potential advantages. Most
obvious is the fact that it cuts back on expensive software engineers. More
subtly, though, this theoretical AI software black box places the executive
closer to the end product and promises to allow them to express their
requirements without the misunderstandings that arise from communicating down
the chain of command.

Proponents of generative AI for software creation promise that you'll be able
to roll out products faster and cheaper than ever before. They anticipate the
arrival of unicorn SaaS companies with only a single employee empowered by an
army of agentic AI bots. How well does this vision stand up to the reality of
a complex software system, though?

### The Soul of the Machine

At some level every piece of software is entirely made up of a collection of
source code. This reductive approach, however, offers no insight into what makes
one product valuable and another useless. Source code exists merely as the
projection of a more theoretical model for solving a problem. The fact that
the model is theoretical, however, does not mean that it is simple. Rather,
it must be precise and account for all of the details in the problem at hand. It
is this theoretical model at the heart of software which provides actual value.

Importantly, a model exists for all software, whether well-designed or arrived
at simply by chance and luck. This is what makes it possible to port a
codebase written in one programming language to another. The model can be
inferred from the original software and then expressed again in a different
language.

Perhaps unsurprisingly, the definition of a correct theoretical model and its
subsequent refinement is the most time-consuming and challenging part of
software development. The model must account for edge cases, failure modes,
interactions with other systems and with users. Good software development
practices also document the model extensively in a variety of ways from
diagrams and written requirements to unit tests and integration tests. All of
this is done to maximize the correctness of the model for the problem that is
being solved as well as to provide a clear pathway for future maintenance and
debugging.

Expressing the model in source code is generally one of the most straightforward
aspects of the software development process, but this isn't necessarily obvious
to an outside observer because most engineers develop the theoretical model
iteratively in conjunction with writing the code. Concrete implementation serves
to clarify ideas and explore implications for a work in progress.

### How the Sausage is Made

Thoughtful observers have been documenting the challenges of software engineering for many
years, even codifying best practices for developing software system products.

Does the advent of tools that can produce source code at superhuman speed threaten the
continued existence of programmers, or will we see some evolved version of
Brook's law governing the addition of AI agents to software projects?

The question that needs to be answered is whether the shaking we feel in the
ground is an earthquake releasing pressure built up along these fault lines or
if it's a shockwave from Chicxulub and we are the dinosaurs in our last days.

### AI vs Compiled Languages

You aren't asked to check the assembly produced by your compiler.

### The Idea Guy

### Execution Matters

{{% contactfooter %}}#
