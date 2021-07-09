/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface iERC20 {

	function balanceOf(address who) external view returns (uint256 balance);

	function allowance(address owner, address spender) external view returns (uint256 remaining);

	function transfer(address to, uint256 value) external returns (bool success);

	function approve(address spender, uint256 value) external returns (bool success);

	function transferFrom(address from, address to, uint256 value) external returns (bool success);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Context {
	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this;
		return msg.data;
	}
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a - b;
		assert(b <= a && c <= a);
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a && c>=b);
		return c;
	}
}

library SafeERC20 {
	function safeTransfer(iERC20 _token, address _to, uint256 _value) internal {
		require(_token.transfer(_to, _value));
	}
}

contract Controllable is Context {
    mapping (address => bool) public controllers;

	constructor () {
		address msgSender = _msgSender();
		controllers[msgSender] = true;
	}

	modifier onlyController() {
		require(controllers[_msgSender()], "Controllable: caller is not a controller");
		_;
	}

    function addController(address _address) public onlyController {
        controllers[_address] = true;
    }

    function removeController(address _address) public onlyController {
        delete controllers[_address];
    }
}

contract Pausable is Controllable {
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() public onlyController whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyController whenPaused {
		paused = false;
		emit Unpause();
	}
}

contract MNW is Controllable, Pausable, iERC20 {
	using SafeMath for uint256;
	using SafeERC20 for iERC20;

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;
	mapping (address => bool) public frozenAccount;

	uint256 public totalSupply;
	string public constant name = "Morpheus.Network";
	uint8 public constant decimals = 18;
	string public constant symbol = "MNW";
	uint256 public constant initialSupply = 47897218 * 10 ** uint(decimals);

	constructor() {
		totalSupply = initialSupply;
		balances[msg.sender] = totalSupply;
    	controllers[msg.sender] = true;
		emit Transfer(address(0),msg.sender,initialSupply);
	}

	function receiveEther() public payable {
		revert();
	}

	function transfer(address _to, uint256 _value) external override whenNotPaused returns (bool success) {
		require(_to != msg.sender,"T1- Recipient can not be the same as sender");
		require(_to != address(0),"T2- Please check the recipient address");
		require(balances[msg.sender] >= _value,"T3- The balance of sender is too low");
		require(!frozenAccount[msg.sender],"T4- The wallet of sender is frozen");
		require(!frozenAccount[_to],"T5- The wallet of recipient is frozen");

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) external override whenNotPaused returns (bool success) {
		require(_to != address(0),"TF1- Please check the recipient address");
		require(balances[_from] >= _value,"TF2- The balance of sender is too low");
		require(allowed[_from][msg.sender] >= _value,"TF3- The allowance of sender is too low");
		require(!frozenAccount[_from],"TF4- The wallet of sender is frozen");
		require(!frozenAccount[_to],"TF5- The wallet of recipient is frozen");

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);

		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

		emit Transfer(_from, _to, _value);

		return true;
	}

	function balanceOf(address _owner) public override view returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) external override whenNotPaused returns (bool success) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0),"A1- Reset allowance to 0 first");

		allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function increaseApproval(address _spender, uint256 _addedValue) external whenNotPaused returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) external whenNotPaused returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_subtractedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function transferToken(address tokenAddress, uint256 amount) external onlyController {
		iERC20(tokenAddress).safeTransfer(msg.sender,amount);
	}

	function flushToken(address tokenAddress) external onlyController {
		uint256 amount = iERC20(tokenAddress).balanceOf(address(this));
		iERC20(tokenAddress).safeTransfer(msg.sender,amount);
	}

	function burn(uint256 _value) external onlyController returns (bool) {
		require(_value <= balances[msg.sender],"B1- The balance of burner is too low");

		balances[msg.sender] = balances[msg.sender].sub(_value);
		totalSupply = totalSupply.sub(_value);

		emit Burn(msg.sender, _value);

		emit Transfer(msg.sender, address(0), _value);

		return true;
	}

	function freeze(address _address, bool _state) external onlyController returns (bool) {
		frozenAccount[_address] = _state;

		emit Freeze(_address, _state);

		return true;
	}

	event Burn(address indexed burner, uint256 value);
	event Freeze(address target, bool frozen);
}