#!/usr/bin/env node
// first, "npm install randomcolor"
random_color = require('randomcolor');

console.log( "\"color\"" );
for (var i=0; i<30000; i++) {
    console.log("\"%d\",\"%s\"", i, random_color() );
}
