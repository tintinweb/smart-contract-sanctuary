/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract WriteInBlockchain{
    string text;
    
    // public para que el write se pueda llamar desde fuera del contrato por otros users
    function Write(string calldata _text) public {
        text = _text;
    }
    
    // view es para decir que solo vamos a leer cosas. memory indica que el string esta en memoria
    function Read() public view returns(string memory){
        return text;
    }
        
    
}