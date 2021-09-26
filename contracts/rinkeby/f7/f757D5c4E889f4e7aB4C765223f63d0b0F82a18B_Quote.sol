/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity 0.8.0;

contract Quote {
    
    string favoriteQuote;
    
    function setQuote(string memory _quote) public {
        favoriteQuote = _quote;
        //
    }
    
}