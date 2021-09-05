/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

library Libr {
    struct iteratr {
        uint x;
    }

    function iterate (iteratr storage i) external {
        i.x = i.x + 1;
    }
}

pragma solidity 0.8.4;

contract Test {
    using Libr for Libr.iteratr;
    Libr.iteratr public x;

    constructor () {
        x.iterate();
    }
}