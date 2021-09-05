/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

pragma solidity ^0.4.11;

//MY atadatem
//MY atadatem

contract Greetings {
     string message;

     function Greetings() {
          message = "I am ready!";
     }

     function setGreetings(string _message) public {
          message = _message;
     }

     function getGreetings() constant returns (string) {
          return message;
     }
}