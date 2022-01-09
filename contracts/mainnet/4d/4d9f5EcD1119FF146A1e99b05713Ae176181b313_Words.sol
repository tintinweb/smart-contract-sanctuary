// contracts/BaseballWords.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Words  {

    uint256 private _wordNonce = 0;

    //Map word id to string
    mapping(uint256 => string) public word;

    //Map word string to id
    mapping(string => uint256) public wordId;


    function createWord(string calldata text) external {

        require(bytes(text).length > 0, "Text is empty");
        require(wordId[text] == 0, "Word already exists");

        uint256 id = ++_wordNonce;

        //Map id to name
        wordId[text] = id;

        //Map id by name
        word[id] = text;

    }

    function createWords(string[] calldata texts) external {

        for (uint256 i=0; i < texts.length; i++) {
            this.createWord(texts[i]);
        }

    }



}