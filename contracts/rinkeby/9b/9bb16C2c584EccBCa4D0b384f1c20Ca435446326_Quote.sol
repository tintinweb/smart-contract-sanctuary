/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: minutes

pragma solidity 0.8.0;

contract Quote {
    // this is to keep my favourite Quote
    //String = Text
    //ABC
    
    
    string favouriteQuote;
    
    function setQuote (string memory _quote) public {
        // Internal working code
        favouriteQuote = _quote;
    }
}