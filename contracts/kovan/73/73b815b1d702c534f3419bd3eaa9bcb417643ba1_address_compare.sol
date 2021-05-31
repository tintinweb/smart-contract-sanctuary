/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


contract address_compare {
    function get_time() public view returns (uint) {
        return block.timestamp;
    }
    function get_number() public view returns(uint) {
        return block.number;
    }
}