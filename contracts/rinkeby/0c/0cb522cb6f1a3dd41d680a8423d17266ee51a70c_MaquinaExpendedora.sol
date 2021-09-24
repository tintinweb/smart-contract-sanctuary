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
        require(msg.value == refrescos[idRefresco].precioRefresco, "Tienes que enviar la cantidad exacta de ETH");
        
        refrescos[idRefresco].estaPagado = true;
        payable(msg.sender).transfer(msg.value);
    }
    
    function getEstadoRefresco(uint256 idRefresco) public view returns(refresco memory infoRefresco){
        infoRefresco = refrescos[idRefresco];
        return infoRefresco;
    }
    
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}