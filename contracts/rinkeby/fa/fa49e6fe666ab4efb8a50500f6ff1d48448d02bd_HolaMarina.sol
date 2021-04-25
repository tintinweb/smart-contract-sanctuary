/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

//SPDX-License-Identifier: MIT
pragma solidity > 0.5.0;

contract HolaMarina {
    string _message; // se guarda en storage en la blockchain.
    
    
    // se indica memory porque no se persiste.
    // esta funcion necesita gas xq usa blockchain
    function setMessage(string memory message) public {
        _message = message;
    }
    
    // calldata se pone cuando se llama desde otras porciones de codigo.
    // No necesita gas xq no altera blockchain solo la lee => view
    function getMessage() public view returns(string memory) {
        return _message;
    }
}