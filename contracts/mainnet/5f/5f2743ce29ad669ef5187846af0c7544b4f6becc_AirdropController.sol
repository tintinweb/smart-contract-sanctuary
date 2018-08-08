pragma solidity ^0.4.21;


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
	 * @param newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract ERC20Basic {
	function totalSupply() public view returns (uint256);

	function balanceOf(address who) public view returns (uint256);

	function transfer(address to, uint256 value) public returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);

	function transferFrom(address from, address to, uint256 value) public returns (bool);

	function approve(address spender, uint256 value) public returns (bool);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Airdrop Controller
 * @dev Controlls ERC20 token airdrop
 * @notice Token Contract Must send enough tokens to this contract to be distributed before aidrop
 */
contract AirdropController is Ownable {
	using SafeMath for uint;

	uint public totalClaimed;

	bool public airdropAllowed;

	ERC20 public token;

	mapping(address => bool) public tokenReceived;

	modifier isAllowed() {
		require(airdropAllowed == true);
		_;
	}

	function AirdropController() public {
		airdropAllowed = true;
	}

	function airdrop(address[] _recipients, uint[] _amounts) public onlyOwner isAllowed {
		for (uint i = 0; i < _recipients.length; i++) {
			require(_recipients[i] != address(0));
			require(tokenReceived[_recipients[i]] == false);
			require(token.transfer(_recipients[i], _amounts[i]));
			tokenReceived[_recipients[i]] = true;
			totalClaimed = totalClaimed.add(_amounts[i]);
		}
	}

	function airdropManually(address _holder, uint _amount) public onlyOwner isAllowed {
		require(_holder != address(0));
		require(tokenReceived[_holder] == false);
		if (!token.transfer(_holder, _amount)) revert();
		tokenReceived[_holder] = true;
		totalClaimed = totalClaimed.add(_amount);
	}

	function setTokenAddress(address _token) public onlyOwner {
		require(_token != address(0));
		token = ERC20(_token);
	}

	function remainingTokenAmount() public view returns (uint) {
		return token.balanceOf(this);
	}

	function setAirdropEnabled(bool _allowed) public onlyOwner {
		airdropAllowed = _allowed;
	}
}