/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.5.16;

contract HelloWorld{
    string public word = "Hello World!";

    function changeWord(string memory _newWord) public {
        word = _newWord;
    }
}