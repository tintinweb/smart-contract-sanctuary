/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity >= 0.4.7 < 0.8.0;

contract HelloWorld {
    string private word;
    constructor(string memory _initialWord) public {
        word = _initialWord;
    }
    
    function getWord() public view returns(string memory) {
        return word;
    }
    
    function setWord(string memory _word) public {
        word = _word;
    }
}