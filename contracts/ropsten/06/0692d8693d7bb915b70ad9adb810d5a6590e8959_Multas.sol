/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.4;

contract Multas {
    
    struct Multa { 
        address agente;
        address infractor;
        uint importe;
        uint fecha;
        string motivo;
        bool pagada;
    }
    
    mapping(uint => Multa) public multas;
    
    function alta_multa(address infractor, string memory motivo, uint importe, uint identificador) public{
        multas[identificador] = Multa(msg.sender, infractor, importe, block.timestamp, motivo, false);
    }
    
    function pagar_multa(uint identificador) public payable{
        require(multas[identificador].pagada == false);
        require(multas[identificador].importe == msg.value);
        multas[identificador].pagada = true;
    }
    
    function estado_multa(uint identificador) public view returns(address, address, uint, uint, string memory , bool){
        return (multas[identificador].agente,
        multas[identificador].infractor,
        multas[identificador].importe,
        multas[identificador].fecha,
        multas[identificador].motivo,
        multas[identificador].pagada); 
    }

}