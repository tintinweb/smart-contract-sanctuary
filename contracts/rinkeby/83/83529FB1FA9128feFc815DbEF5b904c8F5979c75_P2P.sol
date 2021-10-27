/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract P2P {
    address ownerAddress;

    constructor(){
	    ownerAddress = msg.sender ;
    }
   
    uint256 jumlah;
	
	function amountSell(uint256 _amount) external payable {
	require(msg.sender == ownerAddress, "Only Owner");
    require(msg.value > 1e17, "Minimum 0.1 USDT IS REQUIRED");	
    jumlah = _amount;
	}



    function withdraw() public {
        require(msg.sender == ownerAddress, "Only Owner");

        uint amount = address(this).balance;

        (bool success, ) = ownerAddress.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}