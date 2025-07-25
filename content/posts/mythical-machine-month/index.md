---
title: "The Mythical Machine-Month Paradox"
date: 2025-07-01
summary: "" # Summary that will display on the list page
description: "" # Description used for search engine.
featured: false # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
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
  - AI
# comment: false # Disable comment if false.
# codeMaxLines: 25
---

The software industry is in the midst of an identity crisis. The biggest
companies in the field are laying off experienced workers by the thousands and
new college grads are struggling to even land interviews. A profession which had
only experienced growth for more than two decades now fears a bleak future and
sees question marks over where it's headed. The catalyst for all of this is the
rise of generative AI, with some big corporate leaders making
[claims that 95% of code will be written by AI by the end of the decade.](https://www.businessinsider.com/microsoft-cto-ai-generated-code-software-developer-job-change-2025-4)
Could this come to pass, and if so, where does that leave software engineers?

### The siren song

There's a clear reason why generative AI is such a hot topic in the software
industry right now: it can spin out huge amounts of novel source code in very
little time. More tempting still, the interface to this whole process is just
plain old English (or whatever language you speak that the system accepts).
You just tell the AI that you want a program that does some particular thing and
it returns back code that is supposed to do said thing.

If you put yourself into the shoes of an executive, this may not seem very
different from how software has been made for decades, so long as you consider
the actual software creation process as a black box. In the eyes of our
executive, however, this new black box has two potential advantages. Most
obvious is the fact that it cuts back on highly paid programmers. More
subtly, though, this theoretical AI software black box places the executive
closer to the end product and promises to allow them to express their
desires without the misunderstandings that arise from communicating down the
chain of command.

Consequently, the most enthusiastic proponents of generative AI promise that
companies will be able to roll out products faster and cheaper than ever before.
They anticipate the arrival of unicorn SaaS companies with only a single
employee empowered by an army of agentic AI bots. How well does this vision
stand up to the reality of complex software systems, though?

### Soul of the machine

At some level every piece of software is entirely made up of a collection of
source code. This reductive approach, however, offers no insight into what makes
one product valuable and another useless. Source code exists merely as the
projection of a more theoretical model for solving a problem. The fact that
the model is theoretical, however, does not mean that it is simple. Rather,
it must be precise and account for all of the details in the problem at hand. It
is this theoretical model at the heart of the system which provides actual
value.

Importantly, such a model exists for all software, whether carefully designed or
arrived at simply by trial and error. This is what makes it possible to port a
codebase written in one programming language to another. The model can be
inferred from the original software and then expressed again in a different
language.

Perhaps unsurprisingly, defining the correct theoretical model is one of
the most time-consuming and challenging parts of software development. The model
must account for edge cases, failure modes, interactions with other systems and
with users. Good software development practices also document the model
extensively in a variety of ways from diagrams and written requirements to tests
and developer documentation. All of this is done to maximize the correctness of
the model for the problem that is being solved as well as to provide a clear
pathway for future enhancement, maintenance and debugging.

Expressing the model in source code is generally one of the most straightforward
aspects of the software development process, but this isn't necessarily obvious
to an outside observer because most engineers develop the theoretical model
iteratively in conjunction with writing the source code. Concrete implementation
serves to clarify ideas and explore implications for a work in progress. Every
iteration helps to refine the model and ends up materialized as source code
and other model artifacts like tests and documentation.

In order for generative AI to deliver the level of productivity gains that its
most enthusiastic proponents prophesy it would need to do far more than just
write code. It would also need to extrapolate complex models from far simpler
prompts that the user is submitting. It would need somehow to derive the user's
unstated intent, possibly including intentions that they themselves are not yet
aware are significant to solving the problem at hand. If it cannot do this, then
the process of prompting the AI would have to convey the same level of
complexity and specificity that the theoretical model requires. There is a
certain essential complexity that must exist in order to solve any given
problem.

### In theory, there is no difference between practice and theory. In practice, there is.

Software may be born of source code, but it grows up by going through testing.
Real-world situations inevitably find deficiencies in either the theoretical
model that has been crafted or in the implementation of that model via the
source code. All software will go through testing, the question is whether it
happens at the hands of unwitting users or as part of a structured engineering
workflow.

The actual process of testing encompasses a wide range of activities from
verifying individual components for correctness, program-wide validation in
which the interactions between components are explored, all the way up to
inter-system testing where dependencies outside of the software are brought
together. Each level of testing can reveal different kinds of flaws in software
and often uncover emergent behavior that was not expected when designing and
implementing the model and code.

The responsibility for testing has never been as clear-cut as the responsibility
for creating the model and writing code. This is because there are certain kinds
of tests that are most natural for the engineer developing the software
to conduct and other tests where a broader knowledge of other systems might make
subject matter experts the most appropriate. Regardless, though, the nature
of testing is not simply a linear step in the process of releasing software, but
is instead a point at which whole new development cycles may be spawned in
order to address test findings. These new development cycles inevitably must
involve the engineer who designed the model and wrote the source code. The
intimate knowledge of that engineer about the system they created is crucial to
minimize the time and effort needed in these refinement cycles.

What role do the most energetic proponents of generative AI see for these tools
during the testing cycles of software development? Is the AI writing unit tests,
conducting integration tests and more? What about the bug fix development
cycles? If 95% of the code was generated by AI, then what effect does this have
on narrowing down the source of bugs in either the model itself or in the code?
Software engineers can intuit the source of errors because the model for the
system is well-established in their minds as a result of meticulously crafting
it. When the model is instead constructed by AI then this ability is lost.
Projects that are reliant on AI to generate software will inevitably be even
more beholden to the tooling for finding and fixing bugs. If we are to have a
future in which most software is written by AI, then we will also need AI which
is capable of understanding bug reports and updating the code accordingly.

### Software is like a brontosaurus: it has a long tail and is usually pretty old

Visions of startups creating _the next big thing_ often dominate how we discuss
software development, but the reality is that most engineers spend the majority
of their time working within existing codebases that may have been around for
years or even decades. Even the much vaunted startup will end up with legacy
systems pretty quickly if they are successful enough to survive a few years. Any
approach which promises to revolutionize software engineering must offer at
least as much value to existing codebases as it does for new systems.

Typically, the overall cost of a software system is dominated by long-term
maintenance and updates, not the initial implementation. This makes sense when
you consider that the initial release of a software system is likely the
simplest version of the software that will ever exist. Over time software
systems accumulate both necessary complexity as well as accidental complexity.
The actual cost doesn't come from that complexity, but rather from the personnel
that must be retained to conduct maintenance and enhancements.

Importantly, the personnel requirement isn't just that _some_ engineers are
needed to do this work, but rather that specific developers who already
understand the system are required, those developers who either created the
theoretical model or who have spent time and effort to learn it from the code
and other artifacts. The time and expense of bringing new engineers into an
existing project has been well-documented over the years. There is a period of
time over which new additions to a project team are not only unproductive, they
also end up reducing the productivity of the existing team members who already
know the system. Those experienced people have to spend effort educating and
communicating with the new members to get them up to speed. Therefore, retaining
knowledgeable team members has been crucial to managing the overall cost of a
software system.

A second source of the long-term expense of software arises from the fact that
deployed, operational systems are performing the duties for which they were
written. Assumedly, these duties are essential to the success of the business
and thus are critical to incoming revenue. In many cases the rate of revenue
loss for system downtime dwarfs the comparative cost of developing the software
in the first place. If a single day of downtime results in the loss of $100k of
revenue, then the expense of preventing or minimizing failures must be
weighed against that potential loss.

Decades of software engineering have given us several tools to minimize the
likelihood of system failures. These tools largely fall into two intertwined
categories: processes and people. For example, requiring code reviews for all
changes necessitates that competent, knowledgeable people be available to
conduct the review. The reviewers need to have an understanding of the existing
model for the software, but also a broader set of experiences to help anticipate
new problems that might be introduced by a given change. Every process developed
to deliver reliable software has a reliance on people at its heart.

Any future in which 95% of new code is written by AI would need to have a
corresponding solution for the roles that programmers fulfill now during the
long lifetime of a software system. The challenge here is that AI would have to
immediately offer the value of an experienced engineer who already understands
the theoretical model of the software in their mind, not merely the ability to
write code quickly combined with the knowledge of a complete novice to the
project. The value of the experienced engineer goes beyond just their knowledge
of the system, though, and includes problem-solving techniques like using a
debugger to look for performance problems or race conditions.
Either the AI itself will need to determine the source of problems or else the
remaining people on a project will have to go over unfamiliar source code like
programmer archaeologists attempting to divine the inner workings, all while
under the time pressure of lost revenue piling up.

### Are we looking at the arrival of Chicxulub or merely the return of Halley's Comet?

Back to that identity crisis question. Is generative AI going to wipe out the
software engineering profession? In order to deliver on the loftiest of promises
it would need to offer many orders of magnitude more capability than we
currently see. An AI system that allows simple prompts to generate more complex
software by inferring intention will likely be plagued by the fact that this is
dangerously close to the dreaded hallucination problem that current LLMs
exhibit. How would such a system walk this fine line? Then there's the challenge
of ingesting an existing, substantial codebase and subsequently exhibiting an
ability to modify that code in meaningful, correct ways. What's perhaps even
more difficult to imagine is what recourse an AI-reliant organization has when
a bug arises which the AI cannot solve. What if the bug is in an open source
library that the system is dependent on? Does the AI create a patch for that
package and submit a PR to the maintainer? This is the sort of task that
experienced developers understand and engage in. Who does this critical work in
a future of AI agents? For that matter, who writes the open source libraries on
which all of this AI code will depend?

I don't think that we're headed towards a world in which the vast majority of
source code is written by AIs. Over the long lifetime of a software system this
model is only viable if generative AI systems become superhuman in their ability
to turn abstract concepts into concrete implementations and vice versa, all while
remaining cheaper than the humans that they are meant to replace. The danger is
that only the initial implementation costs of software are considered and we end
up with important code generated primarily by AI and no one who can steward
that software into the truly expensive remainder of its life.

Rather than an extinction-level event for the profession, I think that
generative AI instead represents a new class of tools which can offer
productivity improvements for certain tasks. It also opens the door for more
people to create software, much like low-code and no-code tools have done in the
past. I believe that the most significant result of generative AI on the field
will be continued march of software eating the world. More programs will be
written to do more things. This will mean more need for excellent libraries and
toolkits, probably written by humans.

### One more thing...

Execution still matters. Most of the previous innovations in software
development which increased productivity also improved code quality or were at
worst neutral in their effects. Nothing about IDEs, package managers, high-level
languages or other advancements threatened to reduce code quality as a tradeoff
for gaining productivity. Many of these innovations like high-level programming
languages demonstrably improved quality and long-term maintainability of
software systems. The same cannot currently be said for generative AI. While
AI tools sometimes produce excellent code, other times they generate code that
is deeply flawed and it is solely the responsibility of the user to detect and
correct these issues. Imagine if the output of your C compiler had to be checked
to make sure that the binary it produces matches the instructions in your code.
Worse, imagine that your only way to correct the mistake was to update the
actual generated binary file. If we combine this lurking danger with lax
languages like JavaScript and Python that don't work hard to protect the
programmer from common kinds of mistakes then a future full of security
vulnerabilities feels inevitable.

Some folks blow this concern off and claim that they primarily use AI to develop
quick little scripts to solve one-off problems. The issue with that assertion
is that quick little tools have an annoying habit of becoming load-bearing
components in a system. When code quality is sacrificed a debt is incurred whose
price will only be known in the future. If generative AI is to truly
revolutionize the software industry, then reliable, secure output must be the
default result of its usage. Otherwise the future for software engineering will
probably be an endless series of zero-day security fixes.

{{% contactfooter %}}
