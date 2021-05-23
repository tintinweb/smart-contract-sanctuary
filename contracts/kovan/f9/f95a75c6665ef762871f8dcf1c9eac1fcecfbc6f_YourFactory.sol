pragma solidity >=0.6.0 <0.7.0; 
// SPDX-License-Identifier: UNLICENSED
import "./anak.sol"; 
contract YourFactory { 
    event ContractDeployed(address sender, string nama, address newContract); 
    function newYourContract(string memory _nama) public { 
       YourContract x = new YourContract(msg.sender,_nama); 
        emit ContractDeployed(msg.sender, _nama, address(x)); 
    }
    
}