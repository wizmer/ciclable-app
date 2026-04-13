# F-Droid Metadata

This directory contains metadata for F-Droid distribution.

## Structure

- `org.ciclable.app.yml` - Main F-Droid build configuration
- `en-US/` - English language metadata
  - `short_description.txt` - Brief app description (max 80 chars)
  - `full_description.txt` - Detailed app description (max 4000 chars)
  - `title.txt` - App title (usually just "Ciclable")
  - `changelogs/` - Version-specific changelogs (named by version code)

## Submitting to F-Droid

1. Update the YAML file with correct repository URLs
2. Add screenshots to `metadata/en-US/images/phoneScreenshots/`
3. Submit a merge request to [F-Droid Data repository](https://gitlab.com/fdroid/fdroiddata)

## Adding Screenshots

Screenshots should be:
- 320-3840px wide
- Aspect ratio between 16:9 and 2:1
- PNG or JPEG format
- Named sequentially: `1.png`, `2.png`, etc.

Place in: `metadata/en-US/images/phoneScreenshots/`

## Changelogs

For each release, create a changelog file named with the version code:

`metadata/en-US/changelogs/1.txt` - For version code 1
`metadata/en-US/changelogs/2.txt` - For version code 2

Each file should contain a brief description of changes (max 500 chars).
