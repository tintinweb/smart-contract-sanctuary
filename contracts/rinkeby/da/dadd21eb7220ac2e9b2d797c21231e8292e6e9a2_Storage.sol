/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
        uint256 number;
     
      address[] addresses; 

function addAddress () public {
	addresses.push(msg.sender); 
} 

function getAddresses() public view returns (address[] memory) { 	
    return addresses; 
}
function store(uint256 num) public{
    number = num;
}
function retrieve() public view returns (uint256){
    return number;
}

}