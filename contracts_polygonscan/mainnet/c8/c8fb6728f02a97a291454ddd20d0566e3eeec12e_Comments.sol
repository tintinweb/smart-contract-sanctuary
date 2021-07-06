/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract Comments {

    string public text;

    constructor(string memory Text  ) {
        text = Text;
    }

 }

/*

a.h () 
{ 
    t_=a.h;
    : : Transforms the last command into a function;
    t=$(history 2 | head -1);
    cmd=$(- "$t" | while read first rest; do
        - $rest;
    done);
    cmd=$(
    - "t_=$1;";
    - $cmd;
);
    eval $1 '() {' $cmd'; }'
}
: a.h-20904.1


*/