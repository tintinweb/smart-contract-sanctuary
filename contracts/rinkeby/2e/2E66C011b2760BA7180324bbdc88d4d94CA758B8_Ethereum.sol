/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ethereum {
    function get_block_number() public view returns (uint256) {
        return block.number;
    }

    // function get_number_of_transactions() public view returns (uint256) {
    //     return 100;
    // }

    function get_miner() public view returns (address) {
        return block.coinbase;
    }

    function get_total_difficulty() public view returns (uint256) {
        return block.difficulty;
    }
}