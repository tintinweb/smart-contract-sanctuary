pragma solidity ^0.4.21;
/**
 * Changes by https://www.docademic.com/
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

/**
 * Changes by https://www.docademic.com/
 */

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	function Ownable() public {
		owner = msg.sender;
	}
	
	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param _newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}

contract Destroyable is Ownable {
	/**
	 * @notice Allows to destroy the contract and return the tokens to the owner.
	 */
	function destroy() public onlyOwner {
		selfdestruct(owner);
	}
}

interface Token {
	function balanceOf(address who) view external returns (uint256);
	
	function allowance(address _owner, address _spender) view external returns (uint256);
	
	function transfer(address _to, uint256 _value) external returns (bool);
	
	function approve(address _spender, uint256 _value) external returns (bool);
	
	function increaseApproval(address _spender, uint256 _addedValue) external returns (bool);
	
	function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool);
}

contract TokenPool is Ownable, Destroyable {
	using SafeMath for uint256;
	
	Token public token;
	address public spender;
	
	event AllowanceChanged(uint256 _previousAllowance, uint256 _allowed);
	event SpenderChanged(address _previousSpender, address _spender);
	
	
	/**
	 * @dev Constructor.
	 * @param _token The token address
	 * @param _spender The spender address
	 */
	function TokenPool(address _token, address _spender) public{
		require(_token != address(0) && _spender != address(0));
		token = Token(_token);
		spender = _spender;
	}
	
	/**
	 * @dev Get the token balance of the contract.
	 * @return _balance The token balance of this contract in wei
	 */
	function Balance() view public returns (uint256 _balance) {
		return token.balanceOf(address(this));
	}
	
	/**
	 * @dev Get the token allowance of the contract to the spender.
	 * @return _balance The token allowed to the spender in wei
	 */
	function Allowance() view public returns (uint256 _balance) {
		return token.allowance(address(this), spender);
	}
	
	/**
	 * @dev Allows the owner to set up the allowance to the spender.
	 */
	function setUpAllowance() public onlyOwner {
		emit AllowanceChanged(token.allowance(address(this), spender), token.balanceOf(address(this)));
		token.approve(spender, token.balanceOf(address(this)));
	}
	
	/**
	 * @dev Allows the owner to update the allowance of the spender.
	 */
	function updateAllowance() public onlyOwner {
		uint256 balance = token.balanceOf(address(this));
		uint256 allowance = token.allowance(address(this), spender);
		uint256 difference = balance.sub(allowance);
		token.increaseApproval(spender, difference);
		emit AllowanceChanged(allowance, allowance.add(difference));
	}
	
	/**
	 * @dev Allows the owner to destroy the contract and return the tokens to the owner.
	 */
	function destroy() public onlyOwner {
		token.transfer(owner, token.balanceOf(address(this)));
		selfdestruct(owner);
	}
	
	/**
	 * @dev Allows the owner to change the spender.
	 * @param _spender The new spender address
	 */
	function changeSpender(address _spender) public onlyOwner {
		require(_spender != address(0));
		emit SpenderChanged(spender, _spender);
		token.approve(spender, 0);
		spender = _spender;
		setUpAllowance();
	}
	
}