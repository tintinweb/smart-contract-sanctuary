pragma solidity ^0.4.24;

/*
 Author: vkoskiv
 A simple sale contract. Disposable, and can be used
 to arbitrate a sale of goods or services between two
 individuals.
 
 Version 2.0 changelog:
 -Set buyerApproves, sellerApproves,
 currentBalance and saleStarted to public
 -Add events
 -Remove SafeMath
 */

contract SimpleSale {
	
	//Current approval status
	bool public buyerApproves;
	bool public sellerApproves;
	
	//Sale participants
	address public buyer;
	address public seller;
	address public arbitrator;
	
	//Sale data
	//Current bid
	uint256 public currentBalance;
	//Sale start time (we just use block ts for this)
	uint256 public saleStarted;
	
	//Events
	event SaleCanceled();
	event SaleSucceeded();
	event BuyerApproved();
	event SellerApproved();
	
	constructor(address buyerAddress, address sellerAddress) public {
	    saleStarted = block.timestamp;
	    arbitrator = msg.sender;
	    buyer = buyerAddress;
	    seller = sellerAddress;
	}
	
	function approve() public {
	    if (msg.sender == seller) {
	        sellerApproves = true;
	        emit SellerApproved();
	    } else if (msg.sender == buyer) {
	        buyerApproves = true;
	        emit BuyerApproved();
	    }
	    
	    //Finish sale if both approve
	    if (sellerApproves && buyerApproves) {
	        finishSale();
	    } else if (!sellerApproves && buyerApproves && block.timestamp > saleStarted + 30 days) {
	        //Cancel this sale and return funds to buyer if no consensus is reached within a month
	        selfdestruct(buyer);
	    }
	}
	
	function disapprove() public {
	    if (msg.sender == seller) {
	        sellerApproves = false;
	    } else if (msg.sender == buyer) {
	        buyerApproves = false;
	    }
	}
	
	function finishSale() private {
	    if (seller.send(currentBalance)) {
	        currentBalance = 0;
	        emit SaleSucceeded();
	    } else {
	        revert();
	    }
	}
	
	function depositFunds() public payable {
	    require(msg.sender == buyer);
	    currentBalance += msg.value;
	}
	
	//Arbitrator can cancel the sale at any time
	function abortSale() public {
	    if (msg.sender == arbitrator) {
	        //Return funds to buyer
	        selfdestruct(buyer);
	    }
	}
	
	//Buyer + seller can also agree to cancel the sale
	function cancelSale() public {
	    if (msg.sender == seller) {
	        sellerApproves = false;
	    } else if (msg.sender == buyer) {
	        buyerApproves = false;
	    }
	    if (!sellerApproves && !buyerApproves) {
	        emit SaleCanceled();
	        selfdestruct(buyer);
	    }
	}
}