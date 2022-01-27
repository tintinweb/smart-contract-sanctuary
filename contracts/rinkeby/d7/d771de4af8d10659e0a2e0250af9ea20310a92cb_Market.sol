/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract Market {

    string public _symbol = "TM";
    uint256 public MAX_OFFSET = 18;

    function name() public pure returns(string memory) {
        return "test 2";
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }
}