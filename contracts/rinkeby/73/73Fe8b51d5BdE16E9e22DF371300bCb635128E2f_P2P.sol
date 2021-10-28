/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract P2P {
    address ownerAddress;

    constructor(){
	    ownerAddress = msg.sender ;
    }
   
    uint256 jumlah;
    //address payable seller;
    address payable seller = payable(0xF0C62957e046b72244a8F28a51b893D7E42437C9);
	
	function amountSell(uint256 _amount) external payable {
	require(msg.sender == ownerAddress, "Only Owner");
    require(msg.value > 1e17, "Minimum 0.1 USDT IS REQUIRED");	
    jumlah = _amount;
	}


	function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }


    function _transfer() public {
        require(msg.sender == ownerAddress, "Only Owner");

        uint amount = address(this).balance;

        transferToAddressETH(seller, amount);
        
    }

    function withdraw() public {
        require(msg.sender == ownerAddress, "Only Owner");

        uint amount = address(this).balance;

        (bool success, ) = ownerAddress.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}