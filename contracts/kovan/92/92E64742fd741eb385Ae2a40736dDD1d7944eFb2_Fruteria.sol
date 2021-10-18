/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fruteria {
    
    
    struct fruta
    {
        string nombreFruta;
        uint256 precioFruta;
        bool estaPagado; 
    }
    
    mapping(uint => fruta) frutas;
    
    function crearFruta(uint256 idFruta, string memory _nombreFruta, uint256 _precioFruta) public
    {
        fruta storage nuevaFruta = frutas[idFruta];
        
        nuevaFruta.nombreFruta = _nombreFruta;
        nuevaFruta.precioFruta = _precioFruta;
        nuevaFruta.estaPagado = false;
    }
    
    function comprarFruta (uint256 idFruta) payable public
    {
        require(msg.value == frutas[idFruta].precioFruta, "No tienes ETH suficiente...");
        
        frutas[idFruta].estaPagado = true;
        payable(msg.sender).transfer(msg.value);
    }
    
    function getEstadoFruta (uint256 idFruta) public view returns (fruta memory infoFruta)
    {
        infoFruta = frutas[idFruta];
        return infoFruta;
    }
    
}