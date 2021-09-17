/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Base {
    function privateFunc() private pure returns(string memory) {
        return "private function called";
    }
}