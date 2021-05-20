/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity >=0.4.22 <0.6.0;

contract A {
    
    
    mapping (address => uint256) public direccion_dni;
    mapping (uint256 => address) public dni_direccion;
    
    
    function asignarDNI(address direccion, uint256 DNI){
        direccion_dni[direccion] = DNI;
        dni_direccion[DNI] = direccion;
    } 
    function getDireccion(uint256 DNI) public returns (address direccion){
    
        direccion = dni_direccion[DNI];
    } 
    
}