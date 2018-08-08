pragma solidity ^0.4.21;



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
 * @title ERC223 interface
 * @dev see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223 is ERC20 {
	function transfer(address to, uint256 value, bytes data) public returns (bool);
	event ERC223Transfer(address indexed from, address indexed to, uint256 value, bytes data);
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
 * @title  Basic controller contract for basic UKT token
 * @author  Oleg Levshin <levshin@ucoz-team.net>
 */
contract UKTTokenController is Ownable {
	
	using SafeMath for uint256;
	using AddressTools for address;
	
	bool public isFinalized = false;
	
	// address of the controlled token
	UKTTokenBasic public token;
	// finalize function type. One of two values is possible: "transfer" or "burn"
	bytes32 public finalizeType = "transfer";
	// address type where finalize function will transfer undistributed tokens
	bytes32 public finalizeTransferAddressType = "";
	// maximum quantity of addresses to distribute
	uint8 internal MAX_ADDRESSES_FOR_DISTRIBUTE = 100;
	// list of locked initial allocation addresses
	address[] internal lockedAddressesList;
	
	
	// fires when tokens distributed to holder
	event Distributed(address indexed holder, bytes32 indexed trackingId, uint256 amount);
	// fires when tokens distribution is finalized
	event Finalized();
	
	/**
	 * @dev The UKTTokenController constructor
	 */
	function UKTTokenController(
		bytes32 _finalizeType,
		bytes32 _finalizeTransferAddressType
	) public {
		require(_finalizeType == "transfer" || _finalizeType == "burn");
		
		if (_finalizeType == "transfer") {
			require(_finalizeTransferAddressType != "");
		} else if (_finalizeType == "burn") {
			require(_finalizeTransferAddressType == "");
		}
		
		finalizeType = _finalizeType;
		finalizeTransferAddressType = _finalizeTransferAddressType;
	}
	
	
	/**
	 * @dev Sets controlled token
	 */
	function setToken (
		address _token
	) public onlyOwner returns (bool) {
		require(token == address(0));
		require(_token.isContract());
		
		token = UKTTokenBasic(_token);
		
		return true;
	}
	
	
	/**
	 * @dev Configures controlled token params
	 */
	function configureTokenParams(
		string _name,
		string _symbol,
		uint _totalSupply
	) public onlyOwner returns (bool) {
		require(token != address(0));
		return token.setConfiguration(_name, _symbol, _totalSupply);
	}
	
	
	/**
	 * @dev Allocates initial ICO balances (like team, advisory tokens and others)
	 */
	function allocateInitialBalances(
		address[] addresses,
		bytes32[] addressesTypes,
		uint[] amounts
	) public onlyOwner returns (bool) {
		require(token != address(0));
		return token.setInitialAllocation(addresses, addressesTypes, amounts);
	}
	
	
	/**
	 * @dev Locks given allocation address
	 */
	function lockAllocationAddress(
		address allocationAddress
	) public onlyOwner returns (bool) {
		require(token != address(0));
		token.setInitialAllocationLock(allocationAddress);
		lockedAddressesList.push(allocationAddress);
		return true;
	}
	
	
	/**
	 * @dev Unlocks given allocation address
	 */
	function unlockAllocationAddress(
		address allocationAddress
	) public onlyOwner returns (bool) {
		require(token != address(0));
		
		token.setInitialAllocationUnlock(allocationAddress);
		
		for (uint idx = 0; idx < lockedAddressesList.length; idx++) {
			if (lockedAddressesList[idx] == allocationAddress) {
				lockedAddressesList[idx] = address(0);
				break;
			}
		}
		
		return true;
	}
	
	
	/**
	 * @dev Unlocks all allocation addresses
	 */
	function unlockAllAllocationAddresses() public onlyOwner returns (bool) {
		for(uint a = 0; a < lockedAddressesList.length; a++) {
			if (lockedAddressesList[a] == address(0)) {
				continue;
			}
			unlockAllocationAddress(lockedAddressesList[a]);
		}
		
		return true;
	}
	
	
	/**
	 * @dev Locks given allocation address with timestamp
	 */
	function timelockAllocationAddress(
		address allocationAddress,
		uint32 timelockTillDate
	) public onlyOwner returns (bool) {
		require(token != address(0));
		return token.setInitialAllocationTimelock(allocationAddress, timelockTillDate);
	}
	
	
	
	/**
	 * @dev Distributes tokens to holders (investors)
	 */
	function distribute(
		address[] addresses,
		uint[] amounts,
		bytes32[] trackingIds
	) public onlyOwner returns (bool) {
		require(token != address(0));
		// quantity of addresses should be less than MAX_ADDRESSES_FOR_DISTRIBUTE
		require(addresses.length < MAX_ADDRESSES_FOR_DISTRIBUTE);
		// the array of addresses should be the same length as the array of amounts
		require(addresses.length == amounts.length && addresses.length == trackingIds.length);
		
		for(uint a = 0; a < addresses.length; a++) {
			token.transfer(addresses[a], amounts[a]);
			emit Distributed(addresses[a], trackingIds[a], amounts[a]);
		}
		
		return true;
	}
	
	
	/**
	 * @dev Finalizes the ability to use the controller and destructs it
	 */
	function finalize() public onlyOwner {
		
		if (finalizeType == "transfer") {
			// transfer all undistributed tokens to particular address
			token.transfer(
				token.allocationAddressesTypes(finalizeTransferAddressType),
				token.balanceOf(this)
			);
		} else if (finalizeType == "burn") {
			// burn all undistributed tokens
			token.burn(token.balanceOf(this));
		}
		
		require(unlockAllAllocationAddresses());
		
		removeOwnership();
		
		isFinalized = true;
		emit Finalized();
	}
	
}