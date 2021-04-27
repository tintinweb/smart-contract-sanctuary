/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ropsten {
    function xorme(bytes32 input) public pure returns (bytes32){
        require(input == 0x2900589b5020796113b6523a70510a062e367249e348e873a83b1531e26c38af, "Invalid solution");
        return 0x40632cfd2b42150e78d53a5b193f55654158063b822b9c2ccb54784197185dd2;
    }
}