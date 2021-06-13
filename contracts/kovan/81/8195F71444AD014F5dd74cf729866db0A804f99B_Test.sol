/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.21;

// import "./CNS_contract.sol";

contract Test {
    function hi() view public returns (uint16) {
        // HW3 hw3 = HW3(0x31877e75Ad477579A885Ca5006A208E0058cE58B);
        uint timestamp = 1620856964;
        uint blonumber = 24804000;
        uint16 c2Ans = uint16(keccak256(blockhash(blonumber), timestamp));
        // hw3.guessRandomNumber("b06901087", c2Ans);
        // uint16 i = 0;
        // do {
        //     hw3.guessRandomNumber("b06901087", i);
        //     ++i;
        // } while (i != 0);
        return c2Ans;
    }
}