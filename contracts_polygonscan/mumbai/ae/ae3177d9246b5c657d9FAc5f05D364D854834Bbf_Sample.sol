/**
 *Submitted for verification at polygonscan.com on 2021-11-13
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Sample.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.9 <0.9.0;
pragma experimental ABIEncoderV2;

////// src/Sample.sol

// Add polygon mumbai support

/* pragma solidity ^0.8.9; */
/* pragma experimental ABIEncoderV2; */

contract Sample {
    string public text;

    constructor() {}

    function setText(string memory input) public {
        text = input;
    }
}