/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
contract counter{
    uint256 count;
    
    function getCount() public view returns(uint){
        return count;
    }
    
    function increment() public{
        count +=1;
    }
    
    function decrement() public{
        count -=1;
    }
}