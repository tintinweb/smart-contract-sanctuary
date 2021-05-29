/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0; //VERSION EN LA QUE SE VA A PROGRAMAR EL CODIGO

contract JKCONTRACT{
    
    string nombre; //Variable utilizada para el texto que almacenamos
    //calldata significa que es una variable que proviene de una funcion
    
    function Nombre(string calldata _nombre) public{
        
        nombre = _nombre; //Funcion para pedirle al usuario el texto que quiere introducir en la blockchain
        
        
    }
    
    
    //Una variable view significa que no vaa modificar nada, sino que es solamente para ver. 
    
    function LeerNombre() public view returns(string memory){
        
        return nombre; //funcion para leer el texto que se ha introducido en la blockchain
    }
    
    
    
    
}