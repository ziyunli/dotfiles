---
description: Translate the source file to Chinese
argument-hint: ["filepath"]
---

  1. Locate the file referenced as $ARGUMENTS.
  2. Preprocess:
      - Retain the entire frontmatter; append Translations to its tags list (create the list if missing).
      - Normalize Markdown: fix footnotes, remove stray line breaks, ensure proper list/heading spacing, keep original meaning intact.
  3. Translation:
      - Translate the full body content to Chinese in one continuous pass; do not omit or rearrange text.
      - Preserve personal names in their original language.
      - For each technical term or proper noun, present both Chinese and English (e.g., 超文本传输协议 (HTTP)), unless that harms readability.
      - Keep frontmatter untouched except for the tags addition.
      - Set the document title (first visible heading) to the file name rendered in Chinese.
  4. Output:
      - Create the translated document in the same directory as $ARGUMENTS. Use a new filename that clearly indicates it is the Chinese version (e.g.,
        append .zh.md).
      - Ensure Markdown structure mirrors the cleaned source.
      - After the content, insert a horizontal rule --- followed by a footnote *Edited by MODEL (model-id)*, replacing with the actual model name and ID.
  5. Verification:
      - Confirm no sentences were skipped.
      - Ensure the translation reads naturally in Chinese while honoring all above constraints.
