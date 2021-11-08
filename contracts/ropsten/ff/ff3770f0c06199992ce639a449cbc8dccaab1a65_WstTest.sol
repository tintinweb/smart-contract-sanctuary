/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

//SPDX-License-Identifier:GPL-3.0

pragma solidity ^0.8.7;

contract WstTest {
    
    uint256 v;
    
    function setv(uint256 nv) public {
        v = nv;
    }
    
    function getv() public view returns(uint256){
        return v;
    }
    
}