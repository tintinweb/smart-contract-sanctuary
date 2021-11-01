/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract P2P {
    address ownerAddress;
    address payable buyerAddress;
    address payable sellerAddress;

    constructor(){
	    ownerAddress = msg.sender ;
    }
   
    uint256 jumlah;
    address payable juragan = payable(0x4c21d91b5fe56e5829f7A3930f4042309cd056E5);
    bool public _claim = false;
    bool public _approve = false;
    
	function Deposit(uint256 _amount) external payable {
	    sellerAddress = (payable (msg.sender));
	//require(msg.sender == ownerAddress, "Only Owner");
    jumlah = _amount;
	}

	function transferToAddressETH(address payable recipient, uint256 amount) public {
        recipient.transfer(amount);
    }

    function withdraw() public {
        require(msg.sender == sellerAddress, "Only Owner");

        uint amount = address(this).balance;

        (bool success, ) = ownerAddress.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    


	function approve() external {
	    sellerAddress = (payable (msg.sender));
        _approve = true;
        
        uint amount = address(this).balance;
        
        uint fintransfer = amount*99/100;
        uint pajak = amount/100;
        
		//condition if buyer and seller click

		if (_claim && _approve) {
				
			transferToAddressETH(buyerAddress, fintransfer);
			transferToAddressETH(juragan, pajak);
				
			}
		
		
        
    } 


	function claim() external {
	    buyerAddress = (payable (msg.sender));
        _claim = true;
    } 

    
    function showAcc() public view returns (bool) {
        return _approve;
    }

    function showClaim() public view returns (bool) {
        return _claim;
    }
    
    function showBuyer() public view returns (address) {
        return buyerAddress;
    }
    
    function showSeller() public view returns (address) {
        return sellerAddress;
    }
}