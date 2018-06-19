pragma solidity ^0.4.21;


library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(a <= c);
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(a >= b);
		return a - b;
	}
}


contract AuctusToken {
	function transfer(address to, uint256 value) public returns (bool);
}


contract AuctusPreSale {
	function getTokenAmount(address who) constant returns (uint256);
}


contract ContractReceiver {
	function tokenFallback(address from, uint256 value, bytes data) public;
}


contract AuctusPreSaleDistribution is ContractReceiver {
	using SafeMath for uint256;

	address public auctusTokenAddress = 0xc12d099be31567add4e4e4d0D45691C3F58f5663;
	address public auctusPreSaleAddress = 0x84D45E60f7036F0DE7dF8ed68E1Ee50471B963BA;
	uint256 public escrowedTokens;
	address public owner;
	mapping(address => bool) public redeemed;

	event Escrow(address indexed from, uint256 value);
	event Redeem(address indexed to, uint256 value);

	function AuctusPreSaleDistribution() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(owner == msg.sender);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		owner = newOwner;
	}

	function tokenFallback(address from, uint256 value, bytes) public {
		require(msg.sender == auctusTokenAddress);
		escrowedTokens = escrowedTokens.add(value);
		emit Escrow(from, value);
	}

	function redeemMany(address[] _addresses) onlyOwner public {
		for (uint256 i = 0; i < _addresses.length; i++) {
			redeemPreSale(_addresses[i]);
		}
	}

	function redeemPreSale(address _address) public returns (bool) {
		if (!redeemed[_address]) {
			uint256 value = AuctusPreSale(auctusPreSaleAddress).getTokenAmount(_address);
			if (value > 0) {
				redeemed[_address] = true;
				escrowedTokens = escrowedTokens.sub(value);
				assert(AuctusToken(auctusTokenAddress).transfer(_address, value));
				emit Redeem(_address, value);
				return true;
			}
		}
		return false;
	}
}