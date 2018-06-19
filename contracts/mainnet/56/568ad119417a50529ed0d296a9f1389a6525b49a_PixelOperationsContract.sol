pragma solidity ^0.4.18;

contract PixelOperationsContract {	
	address public owner;

	uint256 private pixelsSold = 0;

	struct pixelBlock {		
		uint256 blockPrice;
		address blockOwner;
		bool isValue;
	}

 	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	mapping(bytes32 => address) public pixelsOwned;
	mapping(bytes32 => pixelBlock) public pixelsOnSale;

	function PixelOperationsContract() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
    		require(msg.sender == owner);
    		_;
  	}
	
	function transferOwnership(address newOwner) onlyOwner public {
   		require(newOwner != address(0));
    		OwnershipTransferred(owner, newOwner);
    		owner = newOwner;
  	}

	function buyFreePixels(uint256 tX, uint256 tY, uint256 bX, uint256 bY) public payable returns(bool) {
		
		bytes32 pxHash = keccak256(tX,tY,bX,bY);
		uint256 pxCount = (bX-tX) * (bY-tY);
		uint256 blockPrice = getQuotes() * pxCount;

		require(msg.value >= blockPrice);
		require(pixelsOwned[pxHash] == 0x0000000000000000000000000000000000000000);
		
		owner.transfer(msg.value);
		pixelsOwned[pxHash] = msg.sender;
		pixelsSold = pixelsSold + pxCount;		

		return true;
	}

	function buyOwnedPixels(bytes32 pxHash) public payable returns(bool) {
		require(pixelsOnSale[pxHash].isValue == true);
		require(msg.value >= pixelsOnSale[pxHash].blockPrice);

		address blockOwner = pixelsOwned[pxHash];
		blockOwner.transfer(msg.value);
		pixelsOwned[pxHash] = msg.sender;
		
		pixelsOnSale[pxHash].isValue = false;

		return true;
	}

	function sendPixelsToMarket(bytes32 pxHash, uint256 pxPrice) public returns(bool) {
		
		require(pixelsOwned[pxHash] == msg.sender);
		pixelsOnSale[pxHash].blockPrice = pxPrice;
		pixelsOnSale[pxHash].blockOwner = msg.sender;
		pixelsOnSale[pxHash].isValue = true;

		return true;
	}

	function removePixelsFromMarket(bytes32 pxHash) public returns(bool) {
		require(pixelsOnSale[pxHash].blockOwner == msg.sender);		
		pixelsOnSale[pxHash].isValue = false;
	}
	
	function getPixels(bytes32 pxHash) public view returns (address) {
		return pixelsOwned[pxHash];
	}
	
	function getQuotes() internal returns(uint256) {
	    	uint256 pixelPrice = 0;
	    
	    	if (pixelsSold <= 100000) {
            		pixelPrice = 1000000000000000;
		}
		else if (pixelsSold <= 200000) {
			pixelPrice = 2000000000000000;
		}
		else if (pixelsSold <= 300000) {
			pixelPrice = 2500000000000000;
		}
		else if (pixelsSold <= 400000) {
			pixelPrice = 3500000000000000;
		}
		else if (pixelsSold <= 500000) {
			pixelPrice = 4000000000000000;
		}
		else if (pixelsSold <= 600000) {
			pixelPrice = 4500000000000000;
		}
		else if (pixelsSold <= 700000) {
			pixelPrice = 5000000000000000;
		}
		else if (pixelsSold <= 800000) {
			pixelPrice = 5500000000000000;
		}
		else if (pixelsSold <= 900000) {
			pixelPrice = 10000000000000000;
		}
		else {
			pixelPrice = 10000000000000000; 
		}

		return pixelPrice;
	}
}