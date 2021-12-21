/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Asciiart {
    string private text;

    constructor(string memory _text) {
        text = _text;
    }
    
    function getArt() public view returns (string memory) {
        return text;
    }

    function setGreeting(string memory _text) public {
        text = _text;
    }
}