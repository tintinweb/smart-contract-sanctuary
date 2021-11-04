/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.16;

contract Adoption {
    address[16] public adopters;

    event Adopted(uint petId, address adopter);


    function adopt(uint petId) public returns (uint) {
        require(petId >= 0 && petId <= 15);

        adopters[petId] = msg.sender;
        emit Adopted(petId, msg.sender);

        return petId;
    }

    function getAdopters() public view returns(address[16] memory) {
        return adopters;
    }

}