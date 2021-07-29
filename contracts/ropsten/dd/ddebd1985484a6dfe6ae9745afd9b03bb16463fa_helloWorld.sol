/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

///SPDX-License-Identifier: No-license

pragma solidity "0.8.4";

contract helloWorld{
    string public word;
    
    constructor (string memory _word)    {
        word = _word;
    }
    
    function setWord(string memory _word) public{
      
        word = _word;
    }
    
    function setWordAndREturn(string memory _word) public returns (string memory){
        word = _word;
        return word;
    }
    
    function getWordView() public view returns (string memory){
        return word;
    }
    
    function getWord() public returns (string memory){
        return word;
    }
}