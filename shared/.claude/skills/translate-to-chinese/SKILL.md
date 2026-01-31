---
name: translate-to-chinese
description: Use when translate a document into Chinese 
---

Instructions:
  1. Clean the Markdown first:
    - Fix incorrect footnote syntax
    - Remove unnecessary line breaks
    - Preserve all original content exactly
    - DO NOT alter meaning or structure
  2. Translate completely:
    - Translate word-for-word without omitting ANYTHING
    - Complete the ENTIRE translation in one response—no partial outputs
    - Ensure smooth readability for Chinese readers
    - Keep personal names in original language
    - For technical terms/proper nouns: provide both Chinese + English (e.g., "TypeScript (类型脚本)") where it aids comprehension
    - Add internal link to the original document in Markdown link format with the path from the current translation file. 
  3. File creation:
    - Create new file in the same folder as source. Append "(Chinese)" to the original filename as the translation's filename. 
    - Keep all frontmatter fields
    - Add `Translations` to the `tags` array
    - Filename format: Chinese title with proper kebab-case or underscores
    - After the content, insert a horizontal rule --- followed by a footnote *Edited by MODEL (model-id)*, replacing with the actual model name and ID.

Output:
- Show me the diff of the cleaned Markdown (if changes were made)
- Create the new file with proper frontmatter
