/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface Token {
	function allowance(address, address) external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}

contract War {

	uint256 constant private SLOTS = 12;
	uint256 constant private TIME_PER_SLOT = 5 minutes;
	uint256 constant private ROUND_GAP = 60 minutes;
	uint256 constant private BUY_EXPONENT_BASE = 2; // x2 per buy
	uint256 constant private POT_FEE_PERCENT = 25; // 1/4 of buy
	uint256 constant private BURN_FEE_PERCENT = 10; // 1/10 of pot
	uint256 private initialCost;

	enum Status { READY, OPEN, CLOSED }

	uint256 public totalRounds;
	uint256 public roundEnd;
	uint256 public lastSlot;
	address[SLOTS] public lastBuyers;
	uint256[SLOTS] public buys;
	Token public token;
	address public owner;
	address public burnAddress;
	mapping(address => bool) public whitelisted;


	event RoundStarted(uint256 indexed round);
	event SlotPurchased(uint256 indexed slot, address indexed buyer, uint256 cost);
	event PotWon(uint256 indexed round, address indexed winner, uint256 amount);


	modifier _onlyOwner() {
		require(msg.sender == owner);
		_;
	}


	constructor(Token _token, uint256 _initialCost) {
		token = _token;
		initialCost = _initialCost;
		roundEnd = block.timestamp;
		owner = msg.sender;
	}

	function setOwner(address _owner) external _onlyOwner {
		owner = _owner;
	}

	function setBurnAddress(address _burnAddress) external _onlyOwner {
		burnAddress = _burnAddress;
	}

	function setWhitelisted(address _address, bool _isWhitelisted) external _onlyOwner {
		whitelisted[_address] = _isWhitelisted;
	}

	function buySlot(uint256 _index, uint256 _maxBuys) external {
		require(msg.sender == tx.origin || whitelisted[msg.sender]);
		Status _status = currentStatus();
		require(_status != Status.CLOSED);
		if (_status == Status.READY) {
			uint256 _balance = token.balanceOf(address(this));
			if (_balance > 0) {
				if (burnAddress == address(0x0)) {
					token.transfer(lastBuyers[lastSlot], _balance);
					emit PotWon(totalRounds, lastBuyers[lastSlot], _balance);
				} else {
					uint256 _burnFee = _balance * BURN_FEE_PERCENT / 100;
					token.transfer(burnAddress, _burnFee);
					token.transfer(lastBuyers[lastSlot], _balance - _burnFee);
					emit PotWon(totalRounds, lastBuyers[lastSlot], _balance - _burnFee);
				}
			}
			delete lastBuyers;
			delete buys;
			totalRounds++;
			emit RoundStarted(totalRounds);
		}
		require(_index < SLOTS);
		(uint256 _count, uint256 _price) = currentSlotPrice(_index);
		require(_count <= _maxBuys);
		if (_count == 0) {
			token.transferFrom(msg.sender, address(this), _price);
		} else {
			uint256 _potFee = _price * POT_FEE_PERCENT / 100;
			token.transferFrom(msg.sender, address(this), _potFee);
			token.transferFrom(msg.sender, lastBuyers[_index], _price - _potFee);
		}
		roundEnd = block.timestamp + slotTime(_index);
		lastSlot = _index;
		lastBuyers[_index] = msg.sender;
		buys[_index]++;
		emit SlotPurchased(_index, msg.sender, _price);
	}


	function currentPot() public view returns (uint256) {
		return token.balanceOf(address(this));
	}
	
	function currentStatus() public view returns (Status) {
		return block.timestamp < roundEnd ? Status.OPEN : block.timestamp < roundEnd + ROUND_GAP ? Status.CLOSED : Status.READY;
	}

	function currentSlotPrice(uint256 _index) public view returns (uint256 count, uint256 price) {
		require(_index < SLOTS);
		count = buys[_index];
		price = initialCost * BUY_EXPONENT_BASE**count;
	}

	function slotTime(uint256 _index) public pure returns (uint256) {
		return TIME_PER_SLOT * (_index + 1);
	}

	function allInfoFor(address _user) external view returns (uint256[5] memory compressedInfo, address[SLOTS] memory buyers, uint256[SLOTS] memory allBuys, uint256 userBalance, uint256 userAllowance) {
		return (_compressedInfo(), lastBuyers, buys, token.balanceOf(_user), token.allowance(_user, address(this)));
	}


	function _compressedInfo() internal view returns (uint256[5] memory info) {
		info[0] = totalRounds;
		info[1] = currentPot();
		info[2] = roundEnd;
		info[3] = lastSlot;
		info[4] = initialCost;
	}
}