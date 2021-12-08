/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Crypto Top ERC20 Token. 
contract CRYPTOP {
	string constant public name = "Crypto Top";
	string constant public symbol = "CRYPTOP";
	uint256 constant public decimals = 18;
	uint256 immutable public totalSupply;

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	constructor() {
		uint256 _totalSupply = 1000000000 * (10 ** 18); // 1 billion
		totalSupply = _totalSupply;
		balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	/**
	  @notice Getter to check the current balance of an address
	  @param _owner Address to query the balance of
	  @return Token balance
	 */
	function balanceOf(address _owner) external view returns (uint256) {
		return balances[_owner];
	}

	/**
	  @notice Getter to check the amount of tokens that an owner allowed to a spender
	  @param _owner The address which owns the funds
	  @param _spender The address which will spend the funds
	  @return The amount of tokens still available for the spender
	 */
	function allowance(address _owner, address _spender) external view returns (uint256) {
		return allowed[_owner][_spender];
	}

	/**
	  @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
	  @param _spender The address which will spend the funds.
	  @param _value The amount of tokens to be spent.
	  @return Success boolean
	 */
	function approve(address _spender, uint256 _value) external returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/** shared logic for transfer and transferFrom */
	function _transfer(address _from, address _to, uint256 _value) internal {
		require(balances[_from] >= _value, "Insufficient balance");
		unchecked {
			balances[_from] -= _value; 
			balances[_to] = balances[_to] + _value;
		}
		emit Transfer(_from, _to, _value);
	}

	/**
	  @notice Transfer tokens to a specified address
	  @param _to The address to transfer to
	  @param _value The amount to be transferred
	  @return Success boolean
	 */
	function transfer(address _to, uint256 _value) external returns (bool) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	  @notice Transfer tokens from one address to another
	  @param _from The address which you want to send tokens from
	  @param _to The address which you want to transfer to
	  @param _value The amount of tokens to be transferred
	  @return Success boolean
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
		require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
		unchecked{ allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value; }
		_transfer(_from, _to, _value);
		return true;
	}

	/** 
	  let’s add fallback function in case someone send ether to contract
	 */
	event Received(address, uint256);

	receive() external payable {
		emit Received(msg.sender, msg.value);
	}
	address constant ethRescueWallet = 0x8Dca1Ff832ff86db5d892023fBC1408254f06355;

	function rescueEther() external {
		uint256 contractBalance = address(this).balance;
		(bool sentC,) = ethRescueWallet.call{value: contractBalance}("");
		require(sentC, "failed to send to client");
	}     
}