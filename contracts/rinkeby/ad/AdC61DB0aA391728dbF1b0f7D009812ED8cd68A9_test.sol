/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract test{
        
        string a = unicode"Hello 😃 \n this is cool!";
        
        function dostuff() public view returns(string memory){
            
            return a;
        }
        
}