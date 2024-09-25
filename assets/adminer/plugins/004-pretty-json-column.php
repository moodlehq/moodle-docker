<?php
require_once('plugins/pretty-json-column.php');
$adminer = new AdminerPlugin([]);
return new AdminerPrettyJsonColumn($adminer);           