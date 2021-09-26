/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.0;

contract Hello_world {
    //This is my first smart contract by solidity
    string quote;
    function setQuote(string memory _quote) public{
        //internal working code (function)
        quote = _quote;
    }
}