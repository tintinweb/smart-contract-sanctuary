/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.7.1;

contract qiuyuTest {
    
    uint private number;
    
    function store(uint num) public {
        number=num;
    }
    
    function retreive() public view returns (uint256 num){
        return number;
    }
    
}