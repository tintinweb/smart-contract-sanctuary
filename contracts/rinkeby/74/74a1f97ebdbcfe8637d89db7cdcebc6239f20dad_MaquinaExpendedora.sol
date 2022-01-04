/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

///SPDX-License-Identifier:  MIT
pragma solidity ^0.8.0;

contract MaquinaExpendedora{
     
    //estructura que se usa para unificar los atributos.
    struct refresco{
        string nombreRefresco;
        uint256 precioRefresco;
        bool estadoPagado;      
    }
    //se crea este mapping para agregar los refrescos a una lista
    mapping(uint => refresco) refrescos;

    function CrearRefresco(uint256 idRefresco, string memory _nombreRefresco, uint256 precioRefresco)public{
        refresco storage nuevoRefresco = refrescos[idRefresco]; 
        nuevoRefresco.nombreRefresco = _nombreRefresco;
        nuevoRefresco.precioRefresco = precioRefresco;
        nuevoRefresco.estadoPagado = false;        
    }
     
     function pagarRefresco(uint256 idRefresco) payable public{
         require(msg.value == refrescos[idRefresco].precioRefresco, "Tiene que pagar con el importe exacto ETH");
         
         refrescos[idRefresco].estadoPagado = true;
         //me paga el cliente con su wallet
         payable(msg.sender).transfer(msg.value);
     }

     function getEstadoRefresco(uint256 idRefresco)public view returns(refresco memory infoRefresco){
         infoRefresco = refrescos[idRefresco];
         return infoRefresco;

     }
}