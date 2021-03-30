/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract TestBlock {

    function getBlockhash() public view returns(uint256) {
        return uint256(blockhash(block.number));
    }
}