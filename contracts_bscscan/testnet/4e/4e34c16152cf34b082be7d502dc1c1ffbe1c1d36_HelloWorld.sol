/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

pragma solidity >=0.4.22 <0.7.0;

contract HelloWorld {
 
    string private message;
    
    function contructor(string memory mes) public {
        message = mes;
    }
    
    function setMessage(string memory mes) public {
        message = mes;
    }
    
    function getMessage() view public returns(string memory) {
        return message;
    }
    
}