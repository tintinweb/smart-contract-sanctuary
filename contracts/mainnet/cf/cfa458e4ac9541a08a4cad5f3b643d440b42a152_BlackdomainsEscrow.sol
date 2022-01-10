pragma solidity >=0.6.0 <0.9.0;

import "./IERC20.sol";

contract BlackdomainsEscrow {
	address private mediator;

	IERC20 public erc20_token;
	address private fee_address;
	uint private refund_minimum_block_number;
	bytes32 private release_funds_hash;

	address private seller_address;
	uint private price;
	uint private fee;

	constructor(address _erc20_contract, address _fee_address) {
		mediator = msg.sender;

		erc20_token = IERC20(_erc20_contract);
		fee_address = _fee_address;
	}

	function prepare(address _seller_address, uint _price, uint _fee, bytes32 _release_funds_hash) public {
		require(msg.sender == mediator, "Caller is not authorized.");
		require(erc20_token.balanceOf(address(this)) == 0, "Balance must be 0.");

		seller_address = _seller_address;
		price = _price;
		fee = _fee;
		refund_minimum_block_number = block.number + 40320;
		release_funds_hash = _release_funds_hash;
	}

	function releaseFunds(string memory _release_funds_key) public {
		require(keccak256(abi.encodePacked(_release_funds_key)) == release_funds_hash, "Caller is not authorized.");
		uint balance = erc20_token.balanceOf(address(this));

		require(balance >= price, "Not enough funds.");

		erc20_token.transfer(fee_address, balance - (price - fee));
		erc20_token.transfer(seller_address, price - fee);
	}

	function refundTo(address _to) public {
		require(msg.sender == mediator, "Caller is not authorized.");
		require(block.number >= refund_minimum_block_number, "Caller is not authorized.");

		erc20_token.transfer(_to, erc20_token.balanceOf(address(this)));
	}
}