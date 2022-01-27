/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Accord{
    address owner1;
    address owner2;
    uint owner1_ratio;

    constructor(address own1, address own2, uint own1_ratio){
		owner1 = own1;
		owner2 = own2;
		owner1_ratio = (own1_ratio << 24) / 1000;
	}
     
    function changeOwner(address newOwner) public{
		if(msg.sender == owner1){
			owner1 = newOwner;
		}
		else if(msg.sender == owner2){
			owner2 = newOwner;
		}	
	}

    function withdraw() public{
		payable(address(owner1)).transfer((address(this).balance * owner1_ratio) >> 24);
		payable(address(owner2)).transfer(address(this).balance);		
	}

    function getOwner1() public view returns(address){
        return owner1;
    }

    function getOwner2() public view returns(address){
        return owner2;
    }

    fallback() external payable {}
    receive() external payable {}
}