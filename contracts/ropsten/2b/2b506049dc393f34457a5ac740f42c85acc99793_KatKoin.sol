/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

pragma solidity ^0.4.24;

contract ERC20Interface {

	// Stateless functions
    function totalSupply() public view returns (uint);

    function balanceOf(address who) public view returns (uint);

    function allowance(address owner, address spender) public view returns (uint);

    // Stateful functions
    function transfer(address to, uint value) public returns (bool);

    function approve(address spender, uint value) public returns (bool);

    function transferFrom(address from, address to, uint value) public returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

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
  constructor() public {
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
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract FundsFreezable is Ownable {

    mapping (address => bool) internal frozenAccount;
    
    event FrozenFunds(address indexed target);
    event UnFrozenFunds(address indexed target);

    function freezeAccount(address target) onlyOwner public returns (bool){
        frozenAccount[target] = true;
        emit FrozenFunds(target);
        return true;
    }

    function unFreezeAccount(address target) onlyOwner public returns (bool){
        frozenAccount[target] = false;
        emit UnFrozenFunds(target);
        return true;
    }

	modifier unFrozenAccount(address addr) {
	    require(!frozenAccount[addr]);
	    _;
	}

	function isFrozen(address addr) public view returns (bool) {
		return frozenAccount[addr];
	}

	function freezeMultipleAccount(address[] addrs) onlyOwner public returns(bool success) {
		for (uint256 i = 0; i < addrs.length; i++) {
		  if (freezeAccount(addrs[i])) {
		    success = true;
		  }
		}
	}

	function unFreezeMultipleAccount(address[] addrs) onlyOwner public returns(bool success) {
		for (uint256 i = 0; i < addrs.length; i++) {
		  if (unFreezeAccount(addrs[i])) {
		    success = true;
		  }
		}
	}

}

contract KatKoin is ERC20Interface, Ownable, FundsFreezable, Pausable {

	using SafeMath for uint256;

	event AddressAddedToBalancesArray(address indexed _address);

	mapping(address => uint256) internal balances; // Balances of users
	mapping(address => mapping (address => uint256)) internal allowed; // Allowed array. Named approval in talenthon, but allowed in ERC20 std, thus naming allowed.

	address public owner;

	uint256 public decimals = 18;
	uint256 internal supply = 1000000000 * 10**decimals;
	string public name = "KatKoin";
	
	string public symbol = "KAT";

	// Constructor. Will be called the first time while deploying the contract.
	constructor() public {
	    balances[msg.sender] = supply;
	    owner = msg.sender;
	    emit Transfer(address(0), msg.sender, supply);
	}

	/**
	* @dev Total number of tokens in existence
	*/
	function totalSupply() public view returns (uint256) {
		return supply;
	}

	/**
	  * @dev Gets the balance of the specified address.
	  * @param _owner The address to query the the balance of.
	  * @return An uint256 representing the amount owned by the passed address.
	  */
	function balanceOf(address _owner) public view returns (uint256) {
	    return balances[_owner];
	}

	/**
	  * @dev Transfer token for a specified address
	  * @param _to The address to transfer to.
	  * @param _value The amount to be transferred.
	  */
	  function transfer(address _to, uint256 _value) public returns (bool) {

	    require(_value <= balances[msg.sender] && _value > 0 && supply >= _value);
	    require(_to != address(0));
	    require(!frozenAccount[msg.sender]);
	    require(!frozenAccount[_to]);  // Check if recipient is frozen

	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    emit Transfer(msg.sender, _to, _value);
	    return true;
	}

	/**
	   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	   * Beware that changing an allowance with this method brings the risk that someone may use both the old
	   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
	   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
	   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	   * @param _spender The address which will spend the funds.
	   * @param _value The amount of tokens to be spent.
	   */
	  function approve(address _spender, uint256 _value) public returns (bool) {
	  	require(_spender != address(0));
	  	require(!frozenAccount[msg.sender]);  // Check if sender is frozen
	  	require(!frozenAccount[_spender]);  // Check if recipient is frozen
	  	require(_value <= balances[msg.sender] && _value > 0 && supply >= _value);

	    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    emit Approval(msg.sender, _spender, _value);
	    return true;
	}

	/**
	   * @dev Transfer tokens from one address to another
	   * @param _from address The address which you want to send tokens from
	   * @param _to address The address which you want to transfer to
	   * @param _value uint256 the amount of tokens to be transferred
	   */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
	    require(_value <= balances[_from] && _value > 0);
	    require(_value <= allowed[_from][msg.sender]);
	    require(_to != address(0) && _from != address(0));
	    require(!frozenAccount[msg.sender]);
	  	require(!frozenAccount[_from]); 
	  	require(!frozenAccount[_to]); 

	    // balances[_from] = balances[_from].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	    emit Transfer(_from, _to, _value);
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