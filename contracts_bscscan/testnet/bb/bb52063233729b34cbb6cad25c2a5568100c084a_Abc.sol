/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

contract Abc {
    uint256[] private investments = [1,3,4,5];
    constructor() public {}

    function viewa() public view returns (uint256[] memory) {
        return investments;
    }
    
    function update(uint256[] memory _investments) public {
        investments = _investments;
    }
}