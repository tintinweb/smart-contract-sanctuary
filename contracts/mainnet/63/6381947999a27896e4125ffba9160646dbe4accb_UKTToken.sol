pragma solidity ^0.4.21;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	
	address public owner;
	address public potentialOwner;
	
	
	event OwnershipRemoved(address indexed previousOwner);
	event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);
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
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyPotentialOwner() {
		require(msg.sender == potentialOwner);
		_;
	}
	
	
	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param newOwner The address of potential new owner to transfer ownership to.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransfer(owner, newOwner);
		potentialOwner = newOwner;
	}
	
	
	/**
	 * @dev Allow the potential owner confirm ownership of the contract.
	 */
	function confirmOwnership() public onlyPotentialOwner {
		emit OwnershipTransferred(owner, potentialOwner);
		owner = potentialOwner;
		potentialOwner = address(0);
	}
	
	
	/**
	 * @dev Remove the contract owner permanently
	 */
	function removeOwnership() public onlyOwner {
		emit OwnershipRemoved(owner);
		owner = address(0);
	}
	
}

/**
 * @title AddressTools
 * @dev Useful tools for address type
 */
library AddressTools {
	
	/**
	* @dev Returns true if given address is the contract address, otherwise - returns false
	*/
	function isContract(address a) internal view returns (bool) {
		if(a == address(0)) {
			return false;
		}
		
		uint codeSize;
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			codeSize := extcodesize(a)
		}
		
		if(codeSize > 0) {
			return true;
		}
		
		return false;
	}
	
}

/**
* @title Contract that will work with ERC223 tokens
*/
contract ERC223Reciever {
	
	/**
	 * @dev Standard ERC223 function that will handle incoming token transfers
	 *
	 * @param _from address  Token sender address
	 * @param _value uint256 Amount of tokens
	 * @param _data bytes  Transaction metadata
	 */
	function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
	
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
		uint256 c = a / b;
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
	
	
	/**
	* @dev Powers the first number to the second, throws on overflow.
	*/
	function pow(uint a, uint b) internal pure returns (uint) {
		if (b == 0) {
			return 1;
		}
		uint c = a ** b;
		assert(c >= a);
		return c;
	}
	
	
	/**
	 * @dev Multiplies the given number by 10**decimals
	 */
	function withDecimals(uint number, uint decimals) internal pure returns (uint) {
		return mul(number, pow(10, decimals));
	}
	
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
	
	using SafeMath for uint256;
	
	mapping(address => uint256) public balances;
	
	uint256 public totalSupply_;
	
	
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
		emit Transfer(msg.sender, _to, _value);
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
	
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {
	
	event Burn(address indexed burner, uint256 value);
	
	/**
	 * @dev Burns a specific amount of tokens.
	 * @param _value The amount of token to be burned.
	 */
	function burn(uint256 _value) public {
		require(_value <= balances[msg.sender]);
		// no need to require value <= totalSupply, since that would imply the
		// sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
		
		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn(burner, _value);
		emit Transfer(burner, address(0), _value);
	}
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
	
	mapping (address => mapping (address => uint256)) internal allowed;
	
	
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
		emit Transfer(_from, _to, _value);
		return true;
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
		emit Approval(msg.sender, _spender, _value);
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
	
	/**
	 * @dev Increase the amount of tokens that an owner allowed to a spender.
	 *
	 * approve should be called when allowed[_spender] == 0. To increment
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * @param _spender The address which will spend the funds.
	 * @param _addedValue The amount of tokens to increase the allowance by.
	 */
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	
	
	/**
	 * @dev Decrease the amount of tokens that an owner allowed to a spender.
	 *
	 * approve should be called when allowed[_spender] == 0. To decrement
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * @param _spender The address which will spend the funds.
	 * @param _subtractedValue The amount of tokens to decrease the allowance by.
	 */
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

/**
 * @title ERC223 interface
 * @dev see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223 is ERC20 {
	function transfer(address to, uint256 value, bytes data) public returns (bool);
	event ERC223Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

/**
 * @title (Not)Reference implementation of the ERC223 standard token.
 */
contract ERC223Token is ERC223, StandardToken {
	
	using AddressTools for address;
	
	
	/**
	 * @dev Transfer the specified amount of tokens to the specified address.
	 *      Invokes the `tokenFallback` function if the recipient is a contract.
	 *      The token transfer fails if the recipient is a contract
	 *      but does not implement the `tokenFallback` function
	 *      or the fallback function to receive funds.
	 *
	 * @param _to    Receiver address
	 * @param _value Amount of tokens that will be transferred
	 * @param _data  Transaction metadata
	 */
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
		return executeTransfer(_to, _value, _data);
	}
	
	
	/**
	 * @dev Transfer the specified amount of tokens to the specified address.
	 *      This function works the same with the previous one
	 *      but doesn"t contain `_data` param.
	 *      Added due to backwards compatibility reasons.
	 *
	 * @param _to    Receiver address
	 * @param _value Amount of tokens that will be transferred
	 */
	function transfer(address _to, uint256 _value) public returns (bool) {
		bytes memory _data;
		
		return executeTransfer(_to, _value, _data);
	}
	
	
	/**
	 * @dev Makes execution of the token fallback method from if reciever address is contract
	 */
	function executeTokenFallback(address _to, uint256 _value, bytes _data) private returns (bool) {
		ERC223Reciever receiver = ERC223Reciever(_to);
		
		return receiver.tokenFallback(msg.sender, _value, _data);
	}
	
	
	/**
	 * @dev Makes execution of the tokens transfer method from super class
	 */
	function executeTransfer(address _to, uint256 _value, bytes _data) private returns (bool) {
		require(super.transfer(_to, _value));
		
		if(_to.isContract()) {
			require(executeTokenFallback(_to, _value, _data));
			emit ERC223Transfer(msg.sender, _to, _value, _data);
		}
		
		return true;
	}
	
}

/**
 * @title UKTTokenBasic
 * @dev UKTTokenBasic interface
 */
contract UKTTokenBasic is ERC223, BurnableToken {
	
	bool public isControlled = false;
	bool public isConfigured = false;
	bool public isAllocated = false;
	
	// mapping of string labels to initial allocated addresses
	mapping(bytes32 => address) public allocationAddressesTypes;
	// mapping of addresses to time lock period
	mapping(address => uint32) public timelockedAddresses;
	// mapping of addresses to lock flag
	mapping(address => bool) public lockedAddresses;
	
	
	function setConfiguration(string _name, string _symbol, uint _totalSupply) external returns (bool);
	function setInitialAllocation(address[] addresses, bytes32[] addressesTypes, uint[] amounts) external returns (bool);
	function setInitialAllocationLock(address allocationAddress ) external returns (bool);
	function setInitialAllocationUnlock(address allocationAddress ) external returns (bool);
	function setInitialAllocationTimelock(address allocationAddress, uint32 timelockTillDate ) external returns (bool);
	
	// fires when the token contract becomes controlled
	event Controlled(address indexed tokenController);
	// fires when the token contract becomes configured
	event Configured(string tokenName, string tokenSymbol, uint totalSupply);
	event InitiallyAllocated(address indexed owner, bytes32 addressType, uint balance);
	event InitiallAllocationLocked(address indexed owner);
	event InitiallAllocationUnlocked(address indexed owner);
	event InitiallAllocationTimelocked(address indexed owner, uint32 timestamp);
	
}

/**
 * @title  Basic UKT token contract
 * @author  Oleg Levshin <levshin@ucoz-team.net>
 */
contract UKTToken is UKTTokenBasic, ERC223Token, Ownable {
	
	using AddressTools for address;
	
	string public name;
	string public symbol;
	uint public constant decimals = 18;
	
	// address of the controller contract
	address public controller;
	
	
	modifier onlyController() {
		require(msg.sender == controller);
		_;
	}
	
	modifier onlyUnlocked(address _address) {
		address from = _address != address(0) ? _address : msg.sender;
		require(
			lockedAddresses[from] == false &&
			(
				timelockedAddresses[from] == 0 ||
				timelockedAddresses[from] <= now
			)
		);
		_;
	}
	
	
	/**
	 * @dev Sets the controller contract address and removes token contract ownership
	 */
	function setController(
		address _controller
	) public onlyOwner {
		// cannot be invoked after initial setting
		require(!isControlled);
		// _controller should be an address of the smart contract
		require(_controller.isContract());
		
		controller = _controller;
		removeOwnership();
		
		emit Controlled(controller);
		
		isControlled = true;
	}
	
	
	/**
	 * @dev Sets the token contract configuration
	 */
	function setConfiguration(
		string _name,
		string _symbol,
		uint _totalSupply
	) external onlyController returns (bool) {
		// not configured yet
		require(!isConfigured);
		// not empty name of the token
		require(bytes(_name).length > 0);
		// not empty ticker symbol of the token
		require(bytes(_symbol).length > 0);
		// pre-defined total supply
		require(_totalSupply > 0);
		
		name = _name;
		symbol = _symbol;
		totalSupply_ = _totalSupply.withDecimals(decimals);
		
		emit Configured(name, symbol, totalSupply_);
		
		isConfigured = true;
		
		return isConfigured;
	}
	
	
	/**
	 * @dev Sets initial balances allocation
	 */
	function setInitialAllocation(
		address[] addresses,
		bytes32[] addressesTypes,
		uint[] amounts
	) external onlyController returns (bool) {
		// cannot be invoked after initial allocation
		require(!isAllocated);
		// the array of addresses should be the same length as the array of addresses types
		require(addresses.length == addressesTypes.length);
		// the array of addresses should be the same length as the array of allocating amounts
		require(addresses.length == amounts.length);
		// sum of the allocating balances should be equal to totalSupply
		uint balancesSum = 0;
		for(uint b = 0; b < amounts.length; b++) {
			balancesSum = balancesSum.add(amounts[b]);
		}
		require(balancesSum.withDecimals(decimals) == totalSupply_);
		
		for(uint a = 0; a < addresses.length; a++) {
			balances[addresses[a]] = amounts[a].withDecimals(decimals);
			allocationAddressesTypes[addressesTypes[a]] = addresses[a];
			emit InitiallyAllocated(addresses[a], addressesTypes[a], balanceOf(addresses[a]));
		}
		
		isAllocated = true;
		
		return isAllocated;
	}
	
	
	/**
	 * @dev Sets lock for given allocation address
	 */
	function setInitialAllocationLock(
		address allocationAddress
	) external onlyController returns (bool) {
		require(allocationAddress != address(0));
		
		lockedAddresses[allocationAddress] = true;
		
		emit InitiallAllocationLocked(allocationAddress);
		
		return true;
	}
	
	
	/**
	 * @dev Sets unlock for given allocation address
	 */
	function setInitialAllocationUnlock(
		address allocationAddress
	) external onlyController returns (bool) {
		require(allocationAddress != address(0));
		
		lockedAddresses[allocationAddress] = false;
		
		emit InitiallAllocationUnlocked(allocationAddress);
		
		return true;
	}
	
	
	/**
	 * @dev Sets time lock for given allocation address
	 */
	function setInitialAllocationTimelock(
		address allocationAddress,
		uint32 timelockTillDate
	) external onlyController returns (bool) {
		require(allocationAddress != address(0));
		require(timelockTillDate >= now);
		
		timelockedAddresses[allocationAddress] = timelockTillDate;
		
		emit InitiallAllocationTimelocked(allocationAddress, timelockTillDate);
		
		return true;
	}
	
	
	/**
	 * @dev Allows transfer of the tokens after locking conditions checking
	 */
	function transfer(
		address _to,
		uint256 _value
	) public onlyUnlocked(address(0)) returns (bool) {
		require(super.transfer(_to, _value));
		return true;
	}
	
	
	/**
	 * @dev Allows transfer of the tokens (with additional _data) after locking conditions checking
	 */
	function transfer(
		address _to,
		uint256 _value,
		bytes _data
	) public onlyUnlocked(address(0)) returns (bool) {
		require(super.transfer(_to, _value, _data));
		return true;
	}
	
	
	/**
	 * @dev Allows transfer of the tokens after locking conditions checking
	 */
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	) public onlyUnlocked(_from) returns (bool) {
		require(super.transferFrom(_from, _to, _value));
		return true;
	}
	
}