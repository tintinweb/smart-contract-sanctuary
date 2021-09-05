/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

pragma solidity ^0.4.11;

//Welcome to a test of my first solo contract on Rinkeby!
//Super excited about all this
//This is the newest code
//©2021 46598755

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