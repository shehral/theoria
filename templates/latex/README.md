# Theoria LaTeX Templates

Venue-specific LaTeX templates used by the Theoria writer agent during paper generation.

## Available Templates

| Directory | Venue | Document Class | Notes |
|-----------|-------|----------------|-------|
| `neurips2026/` | NeurIPS 2026 | `article` + `neurips_2026` | Includes Limitations section |
| `icml2026/` | ICML 2026 | `article` + `icml2026` | Two-column, running title |
| `acl2026/` | ACL 2026 | `article` + `acl2026` | Ethics Statement section, ACL AI policy |
| `ieee/` | IEEE (generic) | `IEEEtran` (conference) | Keywords block, IEEE citation style |
| `acm/` | ACM (generic) | `acmart` (sigconf) | CCS classification, ACM authorship policy |
| `generic/` | No venue | `article` | Plain format, natbib, 1-inch margins |

## Placeholder System

Each template contains placeholders that the writer agent replaces during paper generation. Placeholders follow this format:

```
%% THEORIA:PLACEHOLDER_NAME %%
```

### Common Placeholders

These appear in every template:

| Placeholder | Description |
|-------------|-------------|
| `%% THEORIA:TITLE %%` | Paper title |
| `%% THEORIA:AUTHOR %%` | Author name(s) |
| `%% THEORIA:INSTITUTION %%` | Author affiliation(s) |
| `%% THEORIA:EMAIL %%` | Corresponding author email |
| `%% THEORIA:ABSTRACT %%` | Paper abstract |
| `%% THEORIA:INTRODUCTION %%` | Introduction section content |
| `%% THEORIA:RELATED_WORK %%` | Related work / background content |
| `%% THEORIA:METHOD %%` | Methodology content |
| `%% THEORIA:EXPERIMENTS %%` | Experimental setup content |
| `%% THEORIA:RESULTS %%` | Results content |
| `%% THEORIA:CONCLUSION %%` | Conclusion content |
| `%% THEORIA:ACKNOWLEDGMENTS %%` | Acknowledgments (before AI disclosure) |

### Venue-Specific Placeholders

Some templates include additional placeholders:

| Placeholder | Templates | Description |
|-------------|-----------|-------------|
| `%% THEORIA:SHORT_TITLE %%` | ICML | Running header title |
| `%% THEORIA:KEYWORDS %%` | ICML, IEEE, ACM | Keyword list |
| `%% THEORIA:DISCUSSION %%` | NeurIPS, ACM, Generic | Discussion section |
| `%% THEORIA:LIMITATIONS %%` | NeurIPS, ACL, ACM, Generic | Limitations section |
| `%% THEORIA:ANALYSIS %%` | ICML, ACL | Analysis section |
| `%% THEORIA:ETHICS %%` | ACL | Ethics statement content |
| `%% THEORIA:CCS_XML %%` | ACM | ACM CCS classification XML |
| `%% THEORIA:DATE %%` | Generic | Document date |

## AI Disclosure

Every template includes an AI disclosure paragraph in the acknowledgments section. The wording is tailored to each venue's policy:

- **NeurIPS**: Full disclosure of AI assistance scope
- **ICML**: Concise disclosure of AI tool usage
- **ACL**: References ACL policy on AI writing assistance
- **IEEE**: Minimal disclosure of AI assistance
- **ACM**: References ACM Policy on Authorship
- **Generic**: General-purpose disclosure

The researcher can customize or disable the AI disclosure via their taste profile.

## Bibliography

All templates reference a `references.bib` file. The writer agent generates this file alongside the paper. Each venue uses its own bibliography style:

| Template | Style |
|----------|-------|
| NeurIPS | `plain` |
| ICML | `icml2026` |
| ACL | `acl_natbib` |
| IEEE | `IEEEtran` |
| ACM | `ACM-Reference-Format` |
| Generic | `plainnat` |

## Adding a New Template

1. Create a new directory under `templates/latex/` (e.g., `aaai2027/`)
2. Add a `main.tex` with the venue's document class and style
3. Use `%% THEORIA:NAME %%` placeholders for all dynamic content
4. Include the AI disclosure paragraph in acknowledgments
5. Reference `references.bib` for the bibliography
