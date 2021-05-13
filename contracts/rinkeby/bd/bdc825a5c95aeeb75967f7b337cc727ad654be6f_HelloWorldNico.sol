/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^0.4.24;

contract HelloWorldNico {
    string public mensaje;
    constructor () public {
        mensaje = "Hello World";
    }
    function getter() public view returns (string memory _message) {
        _message = mensaje;
    }
    function setter(string _newMessage) public {
        mensaje = _newMessage;
    }
}