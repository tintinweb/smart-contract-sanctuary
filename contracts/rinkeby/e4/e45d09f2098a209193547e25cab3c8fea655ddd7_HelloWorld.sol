/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.4.24;

contract HelloWorld {
    string public mensaje; 
    constructor () public {
        mensaje = "HelloWorld";
    }
    function getter () public view returns (string memory _message) {
       _message = mensaje; 
    }
    function setter (string _NewMessage) public {
        mensaje = _NewMessage;
    } 
}