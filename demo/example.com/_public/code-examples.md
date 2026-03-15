---
title: Code Examples
url: /code-examples/
canonical: https://example.com/code-examples/
description: Testing content stripping with various code and Liquid constructs
last_modified: 2026-03-14
---
> Testing content stripping with various code and Liquid constructs

# Code Examples

## Fenced Code Block

```python
def hello():
    print("Hello, World!")
    # This should be preserved exactly
```

## Liquid Tags in Content

This content between if/endif should be preserved.

## Raw Block

These Liquid-like tags {{ should\_not\_be\_stripped }} are protected.

## Indented Code Block

```plaintext
def indented_example():
    return "This should be protected with protect_indented_code: true"
```

## Kramdown Attributes

A paragraph with an attribute.

Regular paragraph after kramdown IAL.
