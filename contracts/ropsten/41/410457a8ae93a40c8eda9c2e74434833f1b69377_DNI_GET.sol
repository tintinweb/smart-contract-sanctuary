pragma solidity ^0.4.25;
contract DNI_GET {
mapping(address=>uint256) public DNI;
   function set_dni(uint _dni) public {
       DNI[msg.sender] = _dni;
   }
   function get_my_dni() view returns (uint256){
       return DNI[msg.sender];
   }   
   
    
    
}