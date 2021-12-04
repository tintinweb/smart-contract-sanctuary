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
        require (msg.sender.balance > 0.0999999 ether);
        
        numeroSorteado = numeroInicial;
        dono = msg.sender;
        contadorDeSorteios = 1;
        
        if (msg.sender.balance > 20 ether) {
            donoRico = true;
        }
        else {
           donoRico = false; 
        }
    }
        
        function set(uint enviado) public {
            numeroSorteado = enviado;
            contadorDeSorteios++;

        }
        function get () public view returns (uint) {
            return numeroSorteado;
        }

        function getContador () public view returns (uint) {
            return contadorDeSorteios;
        }

        function getDono() public view returns (address) {
        return dono;
        }

        function getRico() public view returns (bool){
            return donoRico;
        }


    }