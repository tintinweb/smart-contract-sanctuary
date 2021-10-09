/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract data{
    string public val;
    function value(string memory _val) public {
        val = _val;
    }
    
     function show() public view returns(string memory)
        {
            return val;
        }
    
}