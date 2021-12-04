/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

pragma solidity ^0.4;


contract GuardaLoteria {
    uint numeroSorteado;
    address dono;
    uint contadorDeSorteios = 0;
    bool donoRico = false;
    
    constructor(uint numeroInicial) public {
        require (msg.sender.balance > 0.09999999 ether);
        
        numeroSorteado = numeroInicial;
        dono = msg.sender;
        contadorDeSorteios = 1;
        
        if (msg.sender.balance > 20 ether) {
            donoRico = true;
        }
        
    }
    
    
    
    
    
    
}