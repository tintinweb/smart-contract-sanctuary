/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

pragma solidity ^0.5.16;

contract Adoption2 {
    address[16] public adopters;

    function adopt(uint petId) public returns (uint) {
        require(petId >= 0 && petId <= 15);

        adopters[petId] = msg.sender;

        return petId;
    }

    // Retrieving the adopters
    function getAdopters() public view returns (address[16] memory) {
        return adopters;
    }
}