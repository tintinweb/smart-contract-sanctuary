/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Counter{
    uint public count = 0;

    function increment() public returns(uint){
        count+=1;
        return count;
    }
}