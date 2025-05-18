---
title: "{{ replace .Name "-" " " | title }}" # Title of the blog post.
date: {{ .Date }} # Date of post creation.
summary: "" # Summary that will display on the list page
description: "" # Description used for search engine.
featured: false # Sets if post is a featured post, making appear on the home page side bar.
draft: true # Sets whether to render this page. Draft of true will not be rendered.
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
# comment: false # Disable comment if false.
---

{{% contactfooter %}}
