pragma solidity ^0.4.24;

/*
 Author: vkoskiv
 A simple sale contract. Disposable, and can be used
 to arbitrate a sale of goods or services between two
 individuals.
 */

contract SimpleSale {
	
	//Current approval status
	bool buyerApproves;
	bool sellerApproves;
	
	//Sale participants
	address public buyer;
	address public seller;
	address public arbitrator;
	
	//Sale data
	//Current bid
	uint256 currentBalance;
	//Sale start time (we just use block ts for this)
	uint256 saleStarted;
	
	constructor(address buyerAddress, address sellerAddress) public {
	    saleStarted = block.timestamp;
	    arbitrator = msg.sender;
	    buyer = buyerAddress;
	    seller = sellerAddress;
	}
	
	function approve() public {
	    if (msg.sender == seller) {
	        sellerApproves = true;
	    } else if (msg.sender == buyer) {
	        buyerApproves = true;
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
	        selfdestruct(buyer);
	    }
	}
}

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}