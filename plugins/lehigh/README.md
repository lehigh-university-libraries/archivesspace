# ArchivesSpace Lehigh UI Plugin

Custom public UI plugin for the Lehigh University Libraries ArchivesSpace instance.

## What it does

- Custom header and footer matching Lehigh Libraries branding
- Custom homepage (welcome view)
- Lehigh logo and favicon
- Custom CSS/JS for site styling
- Hosts EAD exports at `/assets/ATexports/` for external harvesters (e.g., UPenn)

## Installation

1. Place this directory in your ArchivesSpace `plugins/` folder as `lehigh`:
   `/opt/archivesspace/plugins/lehigh/`
   Or for Docker, mount it into the container at `/archivesspace/plugins/lehigh`.

2. Add to `config/config.rb`:
```ruby
   AppConfig[:plugins] = ['lehigh', ...]
```

3. Restart ArchivesSpace.

## EAD Exports

The `public/assets/ATexports/` directory holds EAD XML files generated nightly
by a cron job (separate from this plugin). External harvesters fetch them at:

`https://archivesspace.lib.lehigh.edu/assets/ATexports/MSnnnn_ead.xml`

The directory is `.gitignore`d — files are generated, not version-controlled.

## Compatibility

- Tested with ArchivesSpace 3.5
- Target: ArchivesSpace 4.2 (in progress)
