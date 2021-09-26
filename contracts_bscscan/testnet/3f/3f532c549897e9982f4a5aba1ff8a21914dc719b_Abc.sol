/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

contract Abc {
    uint256[] private investments = [1,3,4,5];
    uint256[] private result;
    constructor() public {}
    
    function getBlockTimestamp() public returns (uint256[] memory) {
        for(uint i=0; i<investments.length;i++){
            if(investments[i] > 2 && false) result.push(investments[i]);
        }
        return result;
    }
    
    function viewa() public view returns (uint256[] memory) {
        return result;
    }
    
    function update(uint256[] memory _investments) public {
        investments = _investments;
    }
}