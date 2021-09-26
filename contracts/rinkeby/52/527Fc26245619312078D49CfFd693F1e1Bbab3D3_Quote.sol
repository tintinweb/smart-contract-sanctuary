/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Quote {
    // define parameter
    
    string favoriteQuote;
    
    function setQuote(string memory _quote) public {
        // internal working code
        favoriteQuote = _quote;
    }
    
    
    
}