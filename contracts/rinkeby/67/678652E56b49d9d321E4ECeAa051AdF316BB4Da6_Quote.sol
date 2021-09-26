/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Quote {
    // this is to kept my favourtine quote
    
    string favouriteQuote;
   
    
    function setQuote(string memory _quote) public {
        // Internal working code
        favouriteQuote = _quote;
    }
    
}