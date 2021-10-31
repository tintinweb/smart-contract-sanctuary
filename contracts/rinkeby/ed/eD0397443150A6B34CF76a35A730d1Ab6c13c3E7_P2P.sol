/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

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
    address payable buyer;
    address payable juragan = payable(0x4c21d91b5fe56e5829f7A3930f4042309cd056E5);
    
	function amountSell(uint256 _amount) external payable {
	require(msg.sender == ownerAddress, "Only Owner");
    require(msg.value > 1e17, "Minimum 0.1 USDT IS REQUIRED");	
    jumlah = _amount;
	}


	function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function transfer(address _buyer) public {
        require(msg.sender == ownerAddress, "Only Owner");
        buyer = payable(_buyer);
        uint amount = address(this).balance;
        
        uint fintransfer = amount*99/100;
        uint pajak = amount/100;
        
        transferToAddressETH(buyer, fintransfer);
        transferToAddressETH(juragan, pajak);
    }


    function withdraw() public {
        require(msg.sender == ownerAddress, "Only Owner");

        uint amount = address(this).balance;

        (bool success, ) = ownerAddress.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}