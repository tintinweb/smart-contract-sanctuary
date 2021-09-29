/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

library Lib {
    struct iteratr {
        uint x;
    }

    function iterate (iteratr storage j) external {
        j.x = j.x + 5;
    }
}

pragma solidity 0.8.4;

contract Test {
    using Lib for Lib.iteratr;
    Lib.iteratr public it;

    constructor () {
        it.iterate();
    }
    
    
    function iterate() external {
        it.iterate();
    }
    
    
}