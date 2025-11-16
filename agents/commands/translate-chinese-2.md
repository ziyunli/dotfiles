---
description: Translate the source file to Chinese with Instructions
argument-hint: ["source_file"]
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
    - The Chinese title becomes the filename
  3. File creation:
    - Create new file in the same folder as source
    - Keep all frontmatter fields
    - Add Translations to the tags array
    - Filename format: Chinese title with proper kebab-case or underscores

Output:
- Show me the cleaned Markdown (if changes were made)
- Provide the complete Chinese translation
- Create the new file with proper frontmatter

$ARGUMENTS
