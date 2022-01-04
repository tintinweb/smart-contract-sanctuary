/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

contract SimpleTest {
    bool public _flag;

    function setFlag(bool flag) public {
        _flag = flag;
    }
    
    function getFlag() public view returns(bool) {
        return _flag;
    }
}