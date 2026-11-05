# Neurvo rich text editor build

The editor in `frontend/src/vendor/ckeditor/` is a prebuilt CKEditor 5 bundle from
[opf/commonmark-ckeditor-build](https://github.com/opf/commonmark-ckeditor-build). Neurvo rebuilds it with
open-source (GPL) CKEditor plugins only; no premium features.

- Base: commit `2a7c6fe` (CKEditor 48, matches OpenProject 17.9.6).
- Our changes: `neurvo-editor.patch` (apply with `git apply` on that commit).

## Rebuild

```bash
git clone https://github.com/opf/commonmark-ckeditor-build && cd commonmark-ckeditor-build
git checkout 2a7c6fe && git apply /path/to/neurvo/docs/neurvo/editor/neurvo-editor.patch
npm install
OPENPROJECT_CORE=/path/to/neurvo npm run build
```

## What changed

- The code block is CKEditor's in-place `CodeBlock` (type inside the block, language picker, 27 languages), replacing
  the modal code editor. Saved as fenced Markdown (` ```ts `), so storage is unchanged.
- A delete (trash) button on each code block in the editor; only the left language label is shown.
- Find and replace, horizontal rule in the toolbar, regrouped toolbar.
- Display side: `frontend/src/global_styles/neurvo/_code.sass` (language label, token colours that follow dark mode) and
  `frontend/src/common/code-block-copy.ts` (Copy button).
