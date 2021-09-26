/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Quote {
    
    //this is to kepp my favorite Quote
    //string = Text
    // ABC
    
    string favoritequote;
    
    function setQuote(string memory _quote) public {
        //Internal working code
        favoritequote = _quote;
        
    }
    
}