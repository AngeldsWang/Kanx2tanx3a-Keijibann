Kanx2tanx3a-Keijibann
==========================

### Description
A Simple bbs 'Harmonies', a web app based on [Dancer2](http://perldancer.org/), which is a light web framework for Perl. Supporting user session and full CRUD operation.

### Dependencies
* Module: File::Slurper, DBD::SQLite, Dancer2::Plugin::Captcha
* Tamplate engine: template_toolkit.
* Theme: bootstrap 3 + fontawesome

### Deploy

#### Step 1. 
Copy the database file (in '/db' dir) to the parent dir, avoiding the server autorestart when the database file is updated.

#### Step 2.
```perl
$  plackup -R . bin/app.psgi
```

Using the built-in http server, visit the address: [http://localhost:5000](http://localhost:5000), have fun.

