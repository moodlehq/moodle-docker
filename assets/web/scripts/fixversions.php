<?php

define('CLI_SCRIPT', true);
require(getcwd().'/config.php');
require_once($CFG->libdir.'/clilib.php');
require("$CFG->dirroot/version.php");

cli_separator();
cli_heading('Resetting all version numbers');

$manager = core_plugin_manager::instance();

// Purge caches to make sure we have the fresh information about versions.
$manager::reset_caches();
$configcache = cache::make('core', 'config');
$configcache->purge();
$needsupgrade = false;
$wasdowngraded = false;

$plugininfo = $manager->get_plugins();
foreach ($plugininfo as $type => $plugins) {
    foreach ($plugins as $name => $plugin) {
        if ($plugin->get_status() !== core_plugin_manager::PLUGIN_STATUS_DOWNGRADE) {
            $needsupgrade = $needsupgrade || $plugin->get_status() !== core_plugin_manager::PLUGIN_STATUS_UPTODATE;
            continue;
        }

        $frankenstyle = sprintf("%s_%s", $type, $name);

        mtrace("Updating {$frankenstyle} from {$plugin->versiondb} to {$plugin->versiondisk}");
        $DB->set_field('config_plugins', 'value', $plugin->versiondisk, array('name' => 'version', 'plugin' => $frankenstyle));
        $wasdowngraded = true;
    }
}

// Check that the main version hasn't changed.
if ((float) $CFG->version > $version) {
    set_config('version', $version);
    mtrace("Updated main version from {$CFG->version} to {$version}");
    $wasdowngraded = true;
} else if ('' . $CFG->version !== '' . $version) {
    $needsupgrade = true;
}

if ($wasdowngraded && !$needsupgrade) {
    // Update version hash so Moodle doesn't think that we need to run upgrade.
    $manager::reset_caches();
    set_config('allversionshash', core_component::get_all_versions_hash());
}

// Purge relevant caches again.
$manager::reset_caches();
$configcache->purge();