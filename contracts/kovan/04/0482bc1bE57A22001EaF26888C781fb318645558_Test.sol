/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

contract Test {

    function payMe() external payable {}

    function get() external pure returns(string memory res) {
        res = "Dao Maker";
    }

}