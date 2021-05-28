/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.5.7;
 
contract DNI {
    mapping(address=>string) DNIs;
    
    constructor()public {
    }
    
    function asignarDNI(string memory _DNI)public {
        DNIs[msg.sender] = _DNI;
    }
     function getDNI() public view returns (string memory _DNI)  {
         _DNI = DNIs[msg.sender];
     }
}