# Typescript Migration
Bash script to help with your javascript to typescript migration

It will check the changed files for your branch against a base branch (usually master) and if it finds any files still end in .js or .jsx it will exit with code 1.  If used in a CI/CD pipeline it will protect your team from touching or adding new javascript files without converting them to typescript. 

## Usage
`./main.sh <BASE_BRANCH> <APP_DIRECTORY> <BLACKLIST_DIRECTORY>`

* BASE_BRANCH - this is the base branch that you plan on merging into.  For many teams this is going to be master
* APP_DIRECTORY - this is the relative path to where your application JS code is located.  Additional directories can be separated with a comma delimiter.
* BLACKLIST_DIRECTORY - (optional) this is the relative path to directories that you wish to ignore for the JS rule enforcement.  Additional directories can be separated with a comma delimiter.

The script will segment the changed files by their git diff filter: added, renamed, changed type, etc.  Please see example output below. 

### Example
`./main.sh master app1/,app2 app1/scripts/`

`./main.sh production app/`

### Example output
```
Started typescript file check
  Added:
      app/api/booger.js
  Modified:
      app/api/collectionService.js
  Renamed:
      app/api/NotesService.js

error: JS(X)? files detected, be sure to update the files above before proceeding
Exiting with code: 1
```