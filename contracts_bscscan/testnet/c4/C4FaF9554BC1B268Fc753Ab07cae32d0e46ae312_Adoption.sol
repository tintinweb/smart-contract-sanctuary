/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

/// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract Adoption {
    address[16] public adopters;

    // Adopting a pet
    function adopt(uint petId) public returns (uint){
        require(petId>=0 && petId<=15,"Pet id should be greater than or equal to zero and less than or equal to 15");
        adopters[petId] = msg.sender;
        return petId;
    }

    // Retrieving the adopters
    function getAdopters() public view returns (address[16] memory){
        return adopters;
    }
}