/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
contract Base {
    uint256 internal val = 0;
}

contract New is Base {
    
    function setVal(uint256 _newVal) public {
        val = _newVal;
    }

    function getVal(uint256 _newVal) external pure returns(uint256) {
        return _newVal;
    }
}