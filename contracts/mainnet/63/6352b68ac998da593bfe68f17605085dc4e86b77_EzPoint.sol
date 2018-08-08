pragma solidity ^0.4.18;

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
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

/**
*Standard ERC20 Token interface
*/
contract ERC20 {
	// these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external

	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);

}


/**
* @title Standard ERC20 token
*
* @dev Implementation of the basic standard token.
* @dev https://github.com/ethereum/EIPs/issues/20
* @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract StandardToken is ERC20 {

	using SafeMath for uint256;

	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	uint256 totalSupply_;

	/**
	* @dev total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}


	/**
	* @dev Transfer tokens from one address to another
	* @param _from address The address which you want to send tokens from
	* @param _to address The address which you want to transfer to
	* @param _value uint256 the amount of tokens to be transferred
	*/
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}


	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	/**
	* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	*
	* Beware that changing an allowance with this method brings the risk that someone may use both the old
	* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
	* race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
	* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	* @param _spender The address which will spend the funds.
	* @param _value The amount of tokens to be spent.
	*/
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	* @dev Function to check the amount of tokens that an owner allowed to a spender.
	* @param _owner address The address which owns the funds.
	* @param _spender address The address which will spend the funds.
	* @return A uint256 specifying the amount of tokens still available for the spender.
	*/
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}
}


/**
* @title EzPoint ERC20 token
*
*/
contract EzPoint is StandardToken, Ownable{
	using SafeMath for uint256;

	string public name = "EzPoint";
	string public symbol = "EZPT";
	uint8 public constant decimals = 18;

	uint256 private _N = (10 ** uint256(decimals));
	uint256 public INITIAL_SUPPLY = _N.mul(10000000000);

	/**
	* @dev Constructor that gives msg.sender all of existing tokens.
	*/
	function EzPoint() public {
		totalSupply_ = INITIAL_SUPPLY;
		balances[owner] = totalSupply_;
	}

	function setName(string _name)  onlyOwner public {
		name = _name;
	}

	function setSymbol(string _symbol) onlyOwner public {
		symbol = _symbol;
	}
}