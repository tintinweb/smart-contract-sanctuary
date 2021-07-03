/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ControlFichaje{    
    
    address private propietario;
    mapping (address => uint[]) private registrosEmpleados;
    
    constructor() {        
        propietario = msg.sender;
    }
    
   function Registro() public{
       registrosEmpleados[msg.sender].push(block.timestamp);
   }   
  
   function GetMisRegistros() public view returns (uint[] memory){
       
       uint[] memory result = new uint[] (registrosEmpleados[msg.sender].length);
       for (uint i = 0;i < registrosEmpleados[msg.sender].length; i++) {
           result[i] = registrosEmpleados[msg.sender][i];    
       }
        
        return result;
    }    
}