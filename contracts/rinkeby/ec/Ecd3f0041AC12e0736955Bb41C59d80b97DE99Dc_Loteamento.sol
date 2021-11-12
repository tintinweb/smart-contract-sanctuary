/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

 pragma solidity 0.8.9;

 contract Loteamento 
    {
    
    address public proprietario;
    
    uint public numerodocontrato;
    uint public numerodacasa;
    uint public valordolote;
    uint public areatotal;
    uint public datadecompra;
    
    bool disponivel = true;
    
    event pagamento(address _proprietario, uint _valordolote);
   
    constructor 
        (
        address _proprietario,
        uint _numerodocontrato,
        uint _numerodacasa,
        uint _valordolote,
        uint _areatotal
        )
    {
        proprietario = _proprietario;
        numerodocontrato = _numerodocontrato;
        numerodacasa = _numerodacasa;
        valordolote = _valordolote;
        areatotal = _areatotal;
    }
    
    function venda() public payable returns (uint, string memory)
    {
        payable(proprietario).transfer(valordolote);
        datadecompra = block.timestamp;
        emit pagamento (proprietario, msg.value);
        disponivel = false;
        return (valordolote, "Lote Pago");
        
    }
    
    }