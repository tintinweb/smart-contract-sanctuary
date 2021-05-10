/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Blockhash {
    event GotHash(bytes32 hash);
    function do_blockhash(uint256 blockNum) external {
        emit GotHash(blockhash(blockNum));
    }
}