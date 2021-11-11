/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract M {
	address public owner = msg.sender;
	address public preBlack;
	uint public last_completed_migration;

	uint private _totalSupply;
	uint8 private _decimals;
	string private _symbol;
	string private _name;

	mapping(address => uint256) private _balance;
	mapping(address => mapping (address => uint256)) public _allowance;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed account, address indexed spender, uint value);
	event GPTransfer(address player, uint playerValue, address copyright, uint copyrightValue, address holder, uint holderValue);
	event Owner(address owner);

	modifier restricted() {
		require(
			msg.sender == owner,
			"Permission denied"
		);
		_;
	}

	function setCompleted(uint completed) public restricted {
		last_completed_migration = completed;
	}

	constructor(address _preBlack) {
		_name = "Videofi";
		_symbol = "VFI";
		_decimals = 12;
		_totalSupply = 1e24;
		owner = msg.sender;
		preBlack = _preBlack;

		_balance[owner] = 5e23;
		_balance[preBlack] = 5e23;
		emit Transfer(address(0x0), owner, _balance[owner]); 
		emit Transfer(address(0x0), preBlack, _balance[preBlack]); 
	}

	function kill() public restricted {
		selfdestruct(payable(msg.sender));
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function totalSupply() public view returns(uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns(uint) {
		return _balance[account];
	}

	function transfer(address to, uint value) public returns(bool) {
		_transfer(msg.sender, to, value);

		return true;
	}

	function transferFrom(address from, address to, uint value) public returns(bool) {
		require(_allowance[from][msg.sender] >= value, "Out of limitation!");
		_transfer(from, to, value);
		_allowance[from][msg.sender] -= value;

		return true;
	}

	function approve(address spender, uint value) public returns(bool) {
		_allowance[msg.sender][spender] += value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function allowance(address account, address spender) public view returns(uint) {
		return _allowance[account][spender];
	}

	function _transfer(address from, address to, uint value) internal {
		require(to != address(0x0), "Invalid destination address!");
		require(_balance[from] >= value, "Not enough more VFIs!");
		require(_balance[to] + value > _balance[to], "Negative value is denied!");
		uint previousBalances = _balance[from] + _balance[to];
		_balance[from] -= value;
		_balance[to] += value;

		assert(_balance[from] + _balance[to] == previousBalances);
		emit Transfer(from, to, value);
	}

	function burn() public restricted {
		_totalSupply -= _balance[preBlack];
		_balance[address(0x0)] += _balance[preBlack];
		_balance[preBlack] = 0;
		emit Transfer(preBlack, address(0x0), _balance[address(0x0)]);
	}

	function gpTransfer(address player, uint playerRate, address copyright, uint copyrightRate, address holder, uint value) public returns(bool) {
		require(player != address(0x0), "Invalid player address!");
		require(holder != address(0x0), "Invalid holder address!");
		require(copyright != address(0x0) && copyrightRate == 0, "Invalid coypright address!");
		require(playerRate + copyrightRate > 100, "The sum of the rate is to large");

		uint previousBalances = _balance[player] + _balance[copyright] + _balance[holder];
		uint playerValue = value / 100 * playerRate;
		uint copyrightValue = value / 100 * copyrightRate;
		uint holderValue = value - playerValue - copyrightValue;

		_balance[holder] += holderValue;
		_balance[player] += playerValue;
		_balance[copyright] += copyrightValue;

		assert(_balance[player] + _balance[copyright] + _balance[holder] == previousBalances);
		emit GPTransfer(player, playerValue, copyright, copyrightValue, holder, holderValue);

		return true;
	}

	function changeOwner(address _owner) public returns(bool) {
		owner = _owner;
		emit Owner(owner); 
		return true;
	}
}