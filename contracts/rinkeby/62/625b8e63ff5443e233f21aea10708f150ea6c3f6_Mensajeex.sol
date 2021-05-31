/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.4.24;

contract Mensajeex {

string public mensaje;

constructor () public{
    mensaje = "Hello world";
}
    function setter (string memory _message) public {
        mensaje = _message;
    }
    
    function getter () public view returns (string memory _resultado) {
        _resultado = mensaje;
    }
    
}