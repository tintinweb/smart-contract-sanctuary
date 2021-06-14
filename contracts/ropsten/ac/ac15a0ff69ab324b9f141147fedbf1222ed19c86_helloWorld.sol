/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.22;

contract helloWorld {
    string phrase;
    function setPhrase(string p) public {
         phrase = p;
    }
    function getPhrase() public constant returns(string){
         return phrase;
    }
}