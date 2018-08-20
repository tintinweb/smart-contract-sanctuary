pragma solidity ^0.4.24;


contract ERC20Basic {

	// Get the total token supply
	function totalSupply() public view returns (uint256);


	// Get the account balance of another account with address who
	function balanceOf( address who ) public view returns (uint256);


	// Send _value amount of tokens to address _to
	function transfer( address to, uint256 value ) public returns (bool);


	// Triggered when tokens are transferred.
	event Transfer( address indexed from, address indexed to, uint256 value );
}


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
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	/**
	* @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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


/**
 * ownable contract
 */

contract Ownable {

	address public owner;

	event OwnershipRenounced( address indexed previousOwner );
	event OwnershipTransferred( address indexed previousOwner, address indexed newOwner );


	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	constructor() public {
		owner = msg.sender;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require( msg.sender == owner );
		_;
	}

	/**
	 * @dev Allows the current owner to relinquish control of the contract.
	 * @notice Renouncing to ownership will leave the contract without an owner.
	 * It will not be possible to call the functions with the `onlyOwner`
	 * modifier anymore.
	 */
	function renounceOwnership() public onlyOwner {
		emit OwnershipRenounced( owner );
		owner = address(0);
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param _newOwner The address to transfer ownership to.
	 */
	function transferOwnership( address _newOwner ) public onlyOwner {
		_transferOwnership(_newOwner);
	}

	/**
	 * @dev Transfers control of the contract to a newOwner.
	 * @param _newOwner The address to transfer ownership to.
	 */
	function _transferOwnership( address _newOwner ) internal {
		require( _newOwner != address(0) );
		emit OwnershipTransferred( owner, _newOwner );
		owner = _newOwner;
	}
}


/**
 * tradable contract
 */

contract Tradable is Ownable {

	event Untradable();
	event Tradeable();

	bool public canTrade = false;


	/**
	* Enable coin transactions
	*/

	function setTradeable() onlyOwner public  {
		require( !canTrade );
		canTrade = true;
		emit Tradeable();
	}


	/**
	* Disable coin transactions
	*/

	function setUntradeable() onlyOwner whenTradable public  {
		canTrade = false;
		emit Untradable();
	}


	modifier whenTradable() {
		require( canTrade || msg.sender == owner );
		_;
	}

}


/**
 * basic token
 */

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	/**
	* @dev Total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	/**
	* @dev Transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer( address _to, uint256 _value ) public returns (bool) {
		require( _value <= balances[msg.sender] );
		require( _to != address(0) );

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer( msg.sender, _to, _value );
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf( address _owner ) public view returns (uint256) {
		return balances[_owner];
	}

}


contract BurnableToken is BasicToken {

	event Burn( address indexed burner, uint256 value );

	/**
	 * @dev Burns a specific amount of tokens.
	 * @param _value The amount of token to be burned.
	 */

	function burn( uint256 _value ) public {
		_burn( msg.sender, _value );
	}

	function _burn( address _who, uint256 _value ) internal {
		require( _value <= balances[_who] );
		// no need to require value <= totalSupply, since that would imply the
		// sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

		balances[_who] = balances[_who].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn( _who, _value );
		emit Transfer( _who, address(0), _value );
	}
}


/**
 * code of talent token
 */

contract CodeCoin is BurnableToken, Tradable {

	string constant public name		= "CodeOfTalent";
	string constant public symbol	= "CDTLNT";
	uint8  constant public decimals	= 18;


	/**
	* creator contract owns all tokens
	*/

	constructor() public {
		totalSupply_ = 336363636;
		balances[msg.sender] = totalSupply_;
		emit Transfer( address(0), msg.sender, totalSupply_ );
	}


	/**
	* Funds transfer is possible only when trade is allowed for normal accounts
	* Owner can transfer founds anytime ( see whenTradable modifier )
	*/

	function transfer( address receiver, uint amount ) whenTradable public returns (bool) {
		return super.transfer( receiver, amount );
	}

}


/**
 * owning contract
 */

contract CodeTalentContract is Ownable {
	using SafeMath for uint256;

	mapping( address => uint ) public balances;

	CodeCoin public token;          // the token


	/**
	* create the token
	*/

	constructor() public {
		token = new CodeCoin();
	}


	/**
	* Contract owner can send tokens
	*/

	function sendTokens( address to, uint256 amount ) onlyOwner public {
		token.transfer( to, amount );
	}


	/**
	* Enable coin transactions
	*/

	function setTradeable() onlyOwner public  {
		token.setTradeable();
	}


	/**
	* Disable coin transactions
	*/

	function setUntradeable() onlyOwner public  {
		token.setUntradeable();
	}


	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/

	function balanceOf( address _owner ) public view returns ( uint256 balance ) {
		return token.balanceOf( _owner );
	}



	// fallback function can be used to buy tokens
	function() external payable {
		revert("This contract does not accept Ethereum!");
	}

}