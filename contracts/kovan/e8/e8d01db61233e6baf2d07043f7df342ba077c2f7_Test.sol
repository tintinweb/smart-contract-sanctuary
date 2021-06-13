/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.21;

// import "./CNS_contract.sol";

contract Test {
    uint16 c2Ans;
    constructor() public {
        c2Ans = uint16(keccak256(blockhash(25456671 - 1), 1623611776));
    }
    function hi() view public returns (uint16) {
        return c2Ans;
    }
}