/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT

//Le decimos a solidity que queremos que se compile con una versión como mínimo 0.7.0 y como máximo 0.7.99
pragma solidity >=0.7.0 <0.8.0;

contract WriteOnTheBlockchain {
    string text;

// write es el nombre de la función
// calldata le indica que _text va ser una variable de uso local dentro de la función
// public que es una función que podremos llamar desde fuera del contrato.

    function write(string calldata _text) public {
         text = _text;
    }

    // una función view será aquella que no modifique nada en la blockchain. Por ejemplo si queremos saber cuanto saldo tiene un usuario en su cuenta.
    // returns(string memory) decimos que devolverá un string que está almacenado en memoria
    function read() public view returns(string memory) {
        return text;
    }
}