/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

// hevm: flattened sources of src/contract.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12;

////// src/Math.sol

/* pragma solidity 0.6.12; */

library Math {
    function pi() public pure returns (uint256) {
        return 5;
    }
}

////// src/contract.sol

/* pragma solidity 0.6.12; */

/* import "./Math.sol"; */

contract c {
    uint256 public id = 4;
    function f() public pure returns (uint256) {
        return Math.pi();
    }
}