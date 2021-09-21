/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

library Libra {
    struct iteratr {
        uint x;
    }

    function iterate (iteratr storage i) external {
        i.x = i.x + 1;
    }
}

pragma solidity 0.8.4;

contract Test {
    using Libra for Libra.iteratr;
    Libra.iteratr public x;
    uint y = x.x;

    constructor () {
        x.iterate();
        y = x.x;
    }
    
    
    function iterate() external {
        x.iterate();
        y = x.x;
    }
    
}