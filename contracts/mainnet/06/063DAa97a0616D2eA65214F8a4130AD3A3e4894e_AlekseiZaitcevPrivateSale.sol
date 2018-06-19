pragma solidity ^0.4.20;


library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(a <= c);
		return c;
	}
	
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}
}


contract AlekseiZaitcevPrivateSale {
	using SafeMath for uint256;

	uint256 public tokenPurchased;
	uint256 public amountPurchasedWithDecimals;
	uint256 public weiToReceive;
	uint256 public pricePerEther;
	uint256 public timeLimit; 
	address public buyerAddress;
	address public owner;
	bool public purchaseHalted;
	
	event Buy(address indexed recipient, uint256 tokenAmountWithDecimals, uint256 price);
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function AlekseiZaitcevPrivateSale(
	    uint256 amount,
		uint256 price,
		uint256 limit,
		address buyer) 
		public
	{
		owner = msg.sender;
		purchaseHalted = false;
		weiToReceive = amount * (1 ether);
		pricePerEther = price;
		timeLimit = limit;
		buyerAddress = buyer;
	}
	
	function() 
		payable 
		public
	{
		require(!purchaseHalted);
		require(weiToReceive == msg.value);
		require(buyerAddress == msg.sender);
		require(now <= timeLimit);
		
		uint256 currentPurchase = msg.value.mul(pricePerEther);
		amountPurchasedWithDecimals = amountPurchasedWithDecimals.add(currentPurchase);
		tokenPurchased = tokenPurchased.add(currentPurchase.div(1 ether));
		purchaseHalted = true;
		owner.transfer(msg.value);

		Buy(msg.sender, currentPurchase, pricePerEther);
	}
	
	function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
	
	function setPrivateSaleHalt(bool halted) onlyOwner public {
		purchaseHalted = halted;
	}
	
	function setTimeLimit(uint256 newTimeLimit) onlyOwner public {
		timeLimit = newTimeLimit;
	}
	
	function setAmountToReceive(uint256 newAmountToReceive) onlyOwner public {
		weiToReceive = newAmountToReceive * (1 ether);
	}
	
	function setPrice(uint256 newPrice) onlyOwner public {
		pricePerEther = newPrice;
	}
	
	function setBuyerAddress(address newBuyerAddress) onlyOwner public {
		buyerAddress = newBuyerAddress;
	}
}