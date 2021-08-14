/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Quote {
    string public name = "Quote";
    string public quote;
    address public owner;

    function setQuote(string memory _quote) public {
        quote = _quote;
        owner = msg.sender;
    }

    function getQuote() public view returns (string memory currentQuote, address currentOwner) {
        currentQuote = quote;
        currentOwner = owner;
    }
}