/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: MIT
// by Francisco Martín - copiado ;P
pragma solidity ^0.6.8;

//import "github.com/Arachnid/solidity-stringutils/strings.sol";

contract EscribirEnLaBlockchain{
    
    string ultimaVisita;
    
    function Escribir(string memory _ultima) public{
        
        // string memory temp; // esta variable al declararla dentro de la funcion, es una variable de memoria y no se escribe en la BlockChain
        
        if (keccak256(abi.encodePacked(_ultima)) == keccak256(abi.encodePacked("Bob"))) 
        {
            ultimaVisita = 'Bob estuvo aqui la última vez...';
        }
        else
        {
            ultimaVisita =  _ultima;
        }
    }
    
    function Leer() public view returns(string memory){
        return ultimaVisita;
    }
    
    function getLen() public view returns(uint){
        bytes memory sb = bytes(ultimaVisita);
        return sb.length;
    }
}