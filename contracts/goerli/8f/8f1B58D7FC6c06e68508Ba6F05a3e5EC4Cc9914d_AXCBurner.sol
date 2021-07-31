/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IAXCToken {
    function exemptSelf() external returns (bool);
}

contract AXCBurner {
    constructor(address AXCTokenAddress) {
        IAXCToken AXCToken = IAXCToken(AXCTokenAddress);
        AXCToken.exemptSelf();
    }
}