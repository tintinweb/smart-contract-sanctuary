/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Quote {
    //comment pim arai kor dai dont effect any thing
    
    string FavoriteQuote;
    function setQuote(string memory _quote) public{
        //Internal working code public = everybody can call  
        //String = Text  when type string nexto write memory
        // = Assigment
        FavoriteQuote = _quote;
    } 
}