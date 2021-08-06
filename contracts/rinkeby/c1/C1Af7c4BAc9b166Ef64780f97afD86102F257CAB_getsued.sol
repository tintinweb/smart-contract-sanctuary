/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract getsued{
    
    string youhavebeensued = "This address has been sued";
    
    function Sue(address AddressToSue) public view returns (string memory){
        
        AddressToSue;
        return youhavebeensued;
    }
}