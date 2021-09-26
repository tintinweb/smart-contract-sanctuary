/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Quote {
    
    // hello world, hey guys! this would be my first smartcontact here
    // String = Text
    
    string favoriteQuote;
    
    function setQuote(string memory _quote) public {
        // internal working code, memory = collect this data on momory 
        favoriteQuote = _quote;
    }
    
}