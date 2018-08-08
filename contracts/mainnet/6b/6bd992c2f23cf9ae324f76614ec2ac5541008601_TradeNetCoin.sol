pragma solidity ^0.4.17;

/**
 * @title ERC20Basic interface for TradeNetCoin token.
 * @dev Simpler version of ERC20 interface.
 * @dev See https://github.com/ethereum/EIPs/issues/179.
 */
contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface for TradeNetCoin token.
 * @dev See https://github.com/ethereum/EIPs/issues/20.
 */
contract ERC20 is ERC20Basic {
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath.
 * @dev Math operations with safety checks that throw on error.
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0.
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold.
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
 * @dev Implementation of ERC20Basic interface for TradeNetCoin token.
 * @dev Simpler version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	/**
	* @dev Function transfers token for a specified address.
	* @param _to is the address to transfer to.
	* @param _value is The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Function gets the balance of the specified address.
	* @param _owner is the address to query the the balance of.
	* @dev Function returns an uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}
}


/**
 * @dev Implementation of ERC20 interface for TradeNetCoin token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) allowed;


	/**
	* @dev Function transfers tokens from one address to another.
	* @param _from is the address which you want to send tokens from.
	* @param _to is the address which you want to transfer to.
	* @param _value is the amout of tokens to be transfered.
	*/
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		uint256 _allowance = allowed[_from][msg.sender];

		// Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
		// require (_value <= _allowance);

		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	/**
	* @dev Function approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
	* @param _spender is the address which will spend the funds.
	* @param _value is the amount of tokens to be spent.
	*/
	function approve(address _spender, uint256 _value) public returns (bool) {

		// To change the approve amount you first have to reduce the addresses`
		//  allowance to zero by calling `approve(_spender, 0)` if it is not
		//  already 0 to mitigate the race condition described here:
		//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));

		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	* @dev Function is to check the amount of tokens that an owner allowed to a spender.
	* @param _owner is the address which owns the funds.
	* @param _spender is the address which will spend the funds.
	* @dev Function returns a uint256 specifing the amount of tokens still avaible for the spender.
	*/
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
}


/**
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;

	/**
	* @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
	*/
	function Ownable() public {
		owner = msg.sender;
	}

	/**
	* @dev Modifier throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	* @dev Function allows the current owner to transfer control of the contract to a newOwner.
	* @param newOwner is the address to transfer ownership to.
	*/
	function transferOwnership(address newOwner) onlyOwner public {
		if (newOwner != address(0)) {
			owner = newOwner;
		}
	}
}


/**
 * @title BurnableToken for TradeNetCoin token.
 * @dev Token that can be irreversibly burned.
 */
contract BurnableToken is StandardToken, Ownable {

	/**
	* @dev Function burns a specific amount of tokens.
	* @param _value The amount of token to be burned.
	*/
	function burn(uint _value) public onlyOwner {
		require(_value > 0);
		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply = totalSupply.sub(_value);
		Burn(burner, _value);
	}
	event Burn(address indexed burner, uint indexed value);
}


/**
 * @title TradeNetCoin token.
 * @dev Total supply is 16 million tokens. No opportunity for additional minting of coins.
 * @dev All unsold and unused tokens can be burned in order to more increase token price.
 */
contract TradeNetCoin is BurnableToken {
	string public constant name = "TradeNetCoin";
	string public constant symbol = "TNC";
	uint8 public constant decimals = 2;
	uint256 public constant INITIAL_SUPPLY = 16000000 *( 10 ** uint256(decimals)); // 16,000,000 tokens

	function TradeNetCoin() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}
}