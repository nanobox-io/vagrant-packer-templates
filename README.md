# vagrant-packer-templates

Packer templates to create Vagrant boxes

## Instructions

    $ git clone https://github.com/pagodabox/vagrant-packer-templates.git
    $ cd vagrant-packer-templates
    $ packer build template.json

If you want to build only virtualbox or vmware.

    $ packer build -only=virtualbox-iso template.json
    $ packer build -only=vmware-iso template.json
    $ packer build -only=parallels-iso template.json

Parallel builds can be run on 0.6.0 or latest packer version.

    $ packer build -parallel=true template.json

## Credit

Concepts, templates, and scripts originated from:

- https://github.com/puphpet/packer-templates
- https://github.com/smerrill/packer-templates
