/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0; 

contract ContratoPagamentoV2 {
    
    uint preco = 1 ether;
    address payable dono = payable(msg.sender);
    
    function pagar() payable public {
        require(msg.value >= preco, "Valor insuficiente");
        if(msg.value > preco) {
            uint troco = msg.value - preco;
            address payable comprador = payable(msg.sender);
            comprador.transfer(troco);
        }
    }
    
    function saldo() view public returns(uint valor) {
        return address(this).balance;
    }
    
    function resgatar() public {
        require(msg.sender == dono, "Somente dono pode resgatar.");
        uint valor = saldo();
        dono.transfer(valor);
    }
    
}