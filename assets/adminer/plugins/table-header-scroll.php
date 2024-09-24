<?php
/**
 * Adminer Table header scroll plugin.
 *
 * Copyright (C) 2016 Jonathan Vollebregt <jnvsor@gmail.com>.
 *
 * LICENSE:
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
class AdminerTableHeaderScroll
{
    public function head()
    {
        ?>

<script<?php echo nonce(); ?>>
function tableHeaderPositionUpdate(){
    // If your theme has a fixed position header, change these for compatibility
    var offset = -1;
    var zindex = 10000;

    // Find tables in the content
    var tables = document.getElementById('content').getElementsByTagName('table');
    for (var i = 0; i < tables.length; i++) {
        var table = tables[i];

        // Find the table header
        var tableHeader = table.getElementsByTagName('thead');
        if (tableHeader.length) {
            tableHeader = tableHeader[0];
        } else {
            continue;
        }

        // Calculate the distance from the top and bottom
        var tableTop = table.getBoundingClientRect().top - offset;
        var tableBottom = table.getBoundingClientRect().bottom - offset - tableHeader.offsetHeight;

        // Set the relative position based on the distance
        if (tableTop < 0 && tableBottom > 0){
            tableHeader.style['z-index'] = zindex;
            tableHeader.style.position = 'relative';

            if (typeof tableHeader.style.transform === 'undefined') {
                tableHeader.style.top = -tableTop + 'px';
            } else {
                tableHeader.style.transform = 'translateY(' + -tableTop + 'px)';
            }
        } else {
            tableHeader.style.position = 'static';
            tableHeader.style.transform = 'none';
        }
    }
}

if (window.addEventListener) {
    window.addEventListener('scroll', tableHeaderPositionUpdate);
}
</script>

    <?php
        return true;
    }
}
