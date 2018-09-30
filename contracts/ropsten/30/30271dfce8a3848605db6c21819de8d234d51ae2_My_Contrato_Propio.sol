pragma solidity ^0.4.25;

contract My_Contrato_Propio{
    mapping(address => uint256) private documentos;
    
    constructor() public{
        
    }
    
    function asignarDni(uint256 dni) public {
        documentos[msg.sender] = dni;
    }
    
    function getDni() public view returns (uint256){
        return documentos[msg.sender];
    }
}