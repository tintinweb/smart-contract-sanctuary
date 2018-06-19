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
	
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
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


contract AuctusBonusDistribution is ContractReceiver {
	using SafeMath for uint256;

	address public auctusTokenAddress = 0xc12d099be31567add4e4e4d0D45691C3F58f5663;
	address public auctusPreSaleAddress = 0x84D45E60f7036F0DE7dF8ed68E1Ee50471B963BA;
	uint256 public escrowedTokens;
	mapping(address => bool) public authorized;
	mapping(address => bool) public redeemed;

	event Escrow(address indexed from, uint256 value);
	event Redeem(address indexed to, uint256 value);

	modifier isAuthorized() {
		require(authorized[msg.sender]);
		_;
	}

	function AuctusBonusDistribution() public {
		authorized[msg.sender] = true;
	}

	function setAuthorization(address _address, bool _authorized) isAuthorized public {
		require(_address != address(0) && _address != msg.sender);
		authorized[_address] = _authorized;
	}

	function drainAUC(uint256 value) isAuthorized public {
		assert(AuctusToken(auctusTokenAddress).transfer(msg.sender, value));
	}

	function tokenFallback(address from, uint256 value, bytes) public {
		require(msg.sender == auctusTokenAddress);
		escrowedTokens = escrowedTokens.add(value);
		emit Escrow(from, value);
	}

	function sendPreSaleBonusMany(address[] _addresses) isAuthorized public {
		for (uint256 i = 0; i < _addresses.length; i++) {
			sendPreSaleBonus(_addresses[i]);
		}
	}

	function sendPreSaleBonus(address _address) public returns (bool) {
		if (!redeemed[_address]) {
			uint256 value = AuctusPreSale(auctusPreSaleAddress).getTokenAmount(_address).mul(12).div(100);
			if (value > 0) {
				redeemed[_address] = true;
				sendBonus(_address, value);
				return true;
			}
		}
		return false;
	}

	function sendBonusMany(address[] _addresses, uint256[] _values) isAuthorized public {
		for (uint256 i = 0; i < _addresses.length; i++) {
			sendBonus(_addresses[i], _values[i]);
		}
	}

	function sendBonus(address _address, uint256 value) internal {
		escrowedTokens = escrowedTokens.sub(value);
		assert(AuctusToken(auctusTokenAddress).transfer(_address, value));
		emit Redeem(_address, value);
	}
}