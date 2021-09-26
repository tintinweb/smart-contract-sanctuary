/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT 

pragma solidity 0.8.0;

contract Quote {
    
    //this is to keep my fave quote 
    //String = Text 
    string favoritQuote; 
    
    function setQuote(string memory _quote) public {
        //internal working code
        favoritQuote = _quote;
        }
        
}