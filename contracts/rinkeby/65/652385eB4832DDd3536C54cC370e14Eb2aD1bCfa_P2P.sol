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
    address payable buyer;
    address payable seller;	
    address payable juragan = payable(0x4c21d91b5fe56e5829f7A3930f4042309cd056E5);
    bool public _claim = false;
    bool public _approve = false;
    
	function Deposit(uint256 _amount) external payable {
	//require(msg.sender == ownerAddress, "Only Owner");
    jumlah = _amount;
	}

	function transferToAddressETH(address payable recipient, uint256 amount) public {
        recipient.transfer(amount);
    }

    /*** function transfer(address _buyer) public {
        buyer = payable(_buyer);
		
        uint amount = address(this).balance;
        
        uint fintransfer = amount*99/100;
        uint pajak = amount/100;
        
		//condition if buyer and seller click

		if (_claim && _approve) {
				
			transferToAddressETH(buyer, fintransfer);
			transferToAddressETH(juragan, pajak);
				
			}
	    //withdraw();
	} */

    //function claim() public returns (bool) {
    //    ownerAddress = msg.sender ;
        //buyer = ownerAddress;
        //storage user = [msg.sender];
		//user [msg.sender] = address buyer;
		//address buyer = msg.sender;
		//_claim = true;
	//	return true;
    //}

    //function approve() public returns (bool) {
    //    ownerAddress = msg.sender;
        //seller = ownerAddress;
        //require(msg.sender == seller, "Only Seller");
        //user [msg.sender] = address seller;
		//msg.sender = seller;
	//	return true;
    //}

    function withdraw() public {
        require(msg.sender == buyerAddress, "Only Owner");

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
				
			transferToAddressETH(sellerAddress, fintransfer);
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