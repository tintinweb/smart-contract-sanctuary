/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity "0.8.4";

contract helloWorld{
    string public word;
    
    function setWord(string memory _word) public{
        word = _word;
    }
    
}