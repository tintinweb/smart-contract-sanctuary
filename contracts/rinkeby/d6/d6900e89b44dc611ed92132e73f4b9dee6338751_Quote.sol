/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Quote {
   
    // this is to keep my favorite quote
    // String = Text
    string favoriteQuote;
   
    function setQuote(string memory _quote) public {
        // Internal working code
        favoriteQuote = _quote;
    }
}