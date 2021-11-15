// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaquinaExpendedora{
    
    struct refresco{
        string nombreRefresco;
        uint256 precioRefresco;
        bool estaPagado;
    }
    
    mapping(uint => refresco) refrescos;

    function crearRefresco(uint256 idRefresco, string memory _nombreRefresco, uint256 _precioRefresco) public{
        refresco storage nuevoRefresco = refrescos[idRefresco];
        nuevoRefresco.nombreRefresco = _nombreRefresco;
        nuevoRefresco.precioRefresco = _precioRefresco;
        nuevoRefresco.estaPagado = false;
    }
    
    function comprarRefresco(uint256 idRefresco) payable public{
        require(msg.value == refrescos[idRefresco].precioRefresco, "El ETH enviado debe ser el mismo que el precio del refresco");
        payable(msg.sender).transfer(msg.value);
        refrescos[idRefresco].estaPagado = true;
    }
    
    function getEstadoRefresco(uint256 idRefresco) public view returns(refresco memory infoRefresco){
        infoRefresco = refrescos[idRefresco];
        return infoRefresco;
    }
}

