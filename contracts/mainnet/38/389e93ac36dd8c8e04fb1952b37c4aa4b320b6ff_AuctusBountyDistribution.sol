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


contract ContractReceiver {
	function tokenFallback(address from, uint256 value, bytes data) public;
}


contract AuctusToken {
	function transfer(address to, uint256 value) public returns (bool);
}


contract AuctusBountyDistribution is ContractReceiver {
	using SafeMath for uint256;

	address public auctusTokenAddress = 0xc12d099be31567add4e4e4d0D45691C3F58f5663;
	address public owner;
	uint256 public escrowedTokens;
	mapping(address => bool) public redeemed;

	event Escrow(address indexed from, uint256 value);
	event Redeem(address indexed to, uint256 value);

	function AuctusBountyDistribution() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(owner == msg.sender);
		_;
	}

	modifier isValidMessage(uint256 value, uint256 timelimit, uint8 v, bytes32 r, bytes32 s) {
		require(owner == ecrecover(keccak256("\x19Ethereum Signed Message:\n32", keccak256(this, msg.sender, value, timelimit)), v, r, s));
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

	function redeemBounty(
		uint256 value,
		uint256 timelimit,
		uint8 v,
		bytes32 r,
		bytes32 s
	)
		isValidMessage(value, timelimit, v, r, s)
		public 
	{
		require(timelimit >= now);
		require(!redeemed[msg.sender]);
		redeemed[msg.sender] = true;
		internalRedeem(msg.sender, value);
	}

	function forcedRedeem(address to, uint256 value) onlyOwner public {
		internalRedeem(to, value);
	}

	function internalRedeem(address to, uint256 value) private {
		escrowedTokens = escrowedTokens.sub(value);
		assert(AuctusToken(auctusTokenAddress).transfer(to, value));
		emit Redeem(to, value);
	}
}