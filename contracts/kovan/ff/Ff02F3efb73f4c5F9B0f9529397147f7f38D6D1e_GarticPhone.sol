/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract GarticPhone {
    mapping (address => bool) played;

    address owner;
    string[] words;
    string public lastWord;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function addWord(string memory _word) public {
        require (words.length > 0 || msg.sender == owner);
        require (played[msg.sender] == false, 'You already sent a word');
        require (keccak256(bytes(lastWord)) != keccak256(bytes(_word)), "you can't send the same word");

        words.push(_word);
        lastWord = _word;
        played[msg.sender] = true;
    }

    function firstWord() view public onlyOwner returns (string memory){
        return words[0];
    }

    // function lWord() view public onlyOwner returns (string memory){
    //     return words[words.length];                               
    // }

    function getWords() view public onlyOwner returns (string[] memory) {
        return words;
    }

    function win() view public returns(bool){
        return keccak256(bytes(words[0])) == keccak256(bytes(lastWord));
    }
}