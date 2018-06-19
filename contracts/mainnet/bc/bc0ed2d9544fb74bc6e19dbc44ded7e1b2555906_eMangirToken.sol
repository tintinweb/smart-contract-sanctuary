pragma solidity 0.4.23;

/**
 * eMangir Token
 * www.emangir.com
*/


// @title Abstract ERC20 token interface
contract AbstractToken {
	function balanceOf(address owner) public view returns (uint256 balance);
	function transfer(address to, uint256 value) public returns (bool success);
	function transferFrom(address from, address to, uint256 value) public returns (bool success);
	function approve(address spender, uint256 value) public returns (bool success);
	function allowance(address owner, address spender) public view returns (uint256 remaining);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

// @title SafeMath contract - Math operations with safety checks.
// @author OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
contract SafeMath {
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

	/**
	* @dev Raises `a` to the `b`th power, throws on overflow.
	*/
	function pow(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a ** b;
		assert(c >= a);
		return c;
	}
}

/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
contract StandardToken is AbstractToken, Owned, SafeMath {

	/*
	 *  Data structures
	 */
	mapping (address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	/*
	 *  Read and write storage functions
	 */
	/// @dev Transfers sender&#39;s tokens to a given address. Returns success.
	/// @param _to Address of token receiver.
	/// @param _value Number of tokens to transfer.
	function transfer(address _to, uint256 _value) public returns (bool success) {
		return _transfer(msg.sender, _to, _value);
	}

	/// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
	/// @param _from Address from where tokens are withdrawn.
	/// @param _to Address to where tokens are sent.
	/// @param _value Number of tokens to transfer.
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(allowed[_from][msg.sender] >= _value);
		allowed[_from][msg.sender] -= _value;

		return _transfer(_from, _to, _value);
	}

	/// @dev Returns number of tokens owned by given address.
	/// @param _owner Address of token owner.
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	/// @dev Sets approved amount of tokens for spender. Returns success.
	/// @param _spender Address of allowed account.
	/// @param _value Number of approved tokens.
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/*
	 * Read storage functions
	 */
	/// @dev Returns number of allowed tokens for given address.
	/// @param _owner Address of token owner.
	/// @param _spender Address of token spender.
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	/**
	* @dev Private transfer, can only be called by this contract.
	* @param _from The address of the sender.
	* @param _to The address of the recipient.
	* @param _value The amount to send.
	* @return success True if the transfer was successful, or throws.
	*/
	function _transfer(address _from, address _to, uint256 _value) private returns (bool success) {
		require(_to != address(0));
		require(balances[_from] >= _value);
		balances[_from] -= _value;
		balances[_to] = add(balances[_to], _value);
		emit Transfer(_from, _to, _value);
		return true;
	}
}

/// @title Token contract - Implements Standard ERC20 with additional features.
contract eMangirToken is StandardToken {

	// Time of the contract creation
	uint256 public creationTime;
   // Token MetaData
	string constant public name = &#39;eMangir&#39;;
	string constant public symbol = &#39;EMG&#39;;
	uint8  public decimals = 18;
	uint256 public totalSupply = 1000000000e18;

	constructor() public {
		/* solium-disable-next-line security/no-block-members */
		creationTime = now;
		balances[msg.sender] = totalSupply;
	}

	/// @dev Owner can transfer out any accidentally sent ERC20 tokens
	function transferERC20Token(AbstractToken _token, address _to, uint256 _value)
		public
		onlyOwner
		returns (bool success)
	{
		require(_token.balanceOf(address(this)) >= _value);
		uint256 receiverBalance = _token.balanceOf(_to);
		require(_token.transfer(_to, _value));

		uint256 receiverNewBalance = _token.balanceOf(_to);
		assert(receiverNewBalance == add(receiverBalance, _value));

		return true;
	}

	/// @dev Increases approved amount of tokens for spender. Returns success.
	function increaseApproval(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender], _value);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/// @dev Decreases approved amount of tokens for spender. Returns success.
	function decreaseApproval(address _spender, uint256 _value) public returns (bool success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_value > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = sub(oldValue, _value);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}