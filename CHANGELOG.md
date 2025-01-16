# Changelog

## Types of changes

* Added - For any new features that have been added since the last version was released
* Changed - To note any changes to the software's existing functionality
* Deprecated - To note any features that were once stable but are no longer and have thus been removed
* Fixed - Any bugs or errors that have been fixed should be so noted
* Removed - This notes any features that have been deleted and removed from the software
* Security - This acts as an invitation to users who want to upgrade and avoid any software vulnerabilities

## \#7.1 unreleased

* Fixed: Resolved an issue where Feldspar apps were not preloaded in certain edge cases, resulting in excessive user wait times.
* Added: Support for multiple modal views, including background preloading for improved performance.

## \#7 2025-01-07

* Changed: Bump erlang to 27.1.2
* Changed: Bump elixir to 1.17.0
* Fixed: Support for running the app locally in Docker
* Changed: Github release workflow uses Docker
* Changed: Using Debian on production
* Added: Support for sending logging to AppSignal

## \#6.2 2024-11-28

* Added: AppSignal support
* Added: Support for Onyx RIS upload (behind feature flag)

## \#6.1 2024-11-19

* Fixed: Memory issues by temporary removing Sentry support

## \#6 2024-11-15

* Added: Support for activating assignment embedded mode by url query param.
* Changed: Prevent the tool modal view from closing during assignment when in embedded mode with a single task.

## \#5 2024-11-11

* Fixed: Add/Remove people working on a project.

## \#4 2024-11-06

* Added: Open links in new tab.
* Added: Manually activate user account (Admin feature)  .
* Changed: Improve closing of PDF reader.

## \#3 2024-10-24

* Added: Sentry support for crash management
* Added: Snapchat support for assignment tasks
* Added: Confirmation dialog when skipping content pages or consent pages in assignment configuration.

## \#2 2024-10-04

* Added: Possibility to close assignment tasks before completion.
* Added: Project breadcrumbs for easy navigation and hierarchy overview.
* Changed: Format of the filenames in Storages. Also no folders used anymore. This has impact on Data Donation studies.
* Changed: Assignment does not have a Storage association anymore. Projects can have one Storage that is shared between all the project items.
* Added: Storage project item (BuiltIn and Yoda)
* Added: Support for German language in assignments

## \#1 2024-06-12

Initial version
