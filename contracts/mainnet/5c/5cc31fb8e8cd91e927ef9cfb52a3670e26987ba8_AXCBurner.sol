/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IAXCToken {
    function exemptSelf() external returns (bool);
}

contract AXCBurner {
    IAXCToken public AXCToken;

    constructor(address AXCTokenAddress) {
        AXCToken = IAXCToken(AXCTokenAddress);
        AXCToken.exemptSelf();
    }
}