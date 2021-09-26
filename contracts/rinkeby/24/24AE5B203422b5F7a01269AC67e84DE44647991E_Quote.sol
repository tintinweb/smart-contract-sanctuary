/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Quote{
    //this is to keep my favorite quote
     
    string favoriteQuote;
    function setQuote(string memory _quote) public{
        //internal working code
        favoriteQuote = _quote;
        
    }
}