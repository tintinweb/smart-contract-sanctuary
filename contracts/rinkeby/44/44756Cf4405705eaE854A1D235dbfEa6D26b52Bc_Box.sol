// SPDX-License-Identifier: MIT

// proviamo a vedere se allo stesso address a un certo
// punto possiamo eseguire la funzione increment il che
// vuol dire che il contratto Ã¨ stato upgradato

// per fare il proxy usiamo il codeice gia pronto da openzeppelin 

pragma solidity ^0.8.0;

contract Box {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve () public view returns (uint256) {
        return value;
    }
}