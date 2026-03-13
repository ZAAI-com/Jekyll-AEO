---
title: "Code Examples"
description: "Testing content stripping with various code and Liquid constructs"
layout: page
permalink: /code-examples/
---

# Code Examples

## Fenced Code Block

```python
def hello():
    print("Hello, World!")
    # This should be preserved exactly
```

## Liquid Tags in Content

{% if true %}
This content between if/endif should be preserved.
{% endif %}

{% comment %}
This entire block should be stripped (tags + content).
{% endcomment %}

## Raw Block

{% raw %}
These Liquid-like tags {{ should_not_be_stripped }} are protected.
{% endraw %}

## Indented Code Block

    def indented_example():
        return "This should be protected with protect_indented_code: true"

## Kramdown Attributes

A paragraph with an attribute.
{: .special-class }

Regular paragraph after kramdown IAL.
