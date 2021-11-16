/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ne{
    address[] public add;
    
    function ad(address _add) public {
        add.push(_add);
    }
    function v(uint256 i) public view returns(address){
        return add[i];
    } 
}