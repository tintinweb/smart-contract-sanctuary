pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
 * @title Ownable
 * The Ownable contract has an owner address, and provides basic authorization control
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * Allows the current owner to transfer control of the contract to a newOwner.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

  /**
   * called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}

 
/**
 * @title ERC20 interface
 */
contract ERC20 is Ownable {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, Pausable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

 mapping(address => bool) frozen;

  /**
   * check if given address is frozen. Freeze works only if moderator role is active
   */
  function isFrozen(address _addr) constant returns (bool){
      return frozen[_addr];
  }

  /**
   * Freezes address (no transfer can be made from or to this address).
   */
  function freeze(address _addr) onlyOwner {
      frozen[_addr] = true;
  }

  /**
   * Unfreezes frozen address.
   */
  function unfreeze(address _addr) onlyOwner {
      frozen[_addr] = false;
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
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

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
    var _allowance = allowed[_from][msg.sender];
    require(_to != address(0));
    require (_value <= _allowance);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
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
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * Pausable token with moderator role and freeze address implementation
 **/
contract ModToken is StandardToken {

  mapping(address => bool) frozen;

  /**
   * check if given address is frozen. Freeze works only if moderator role is active
   */
  function isFrozen(address _addr) constant returns (bool){
      return frozen[_addr];
  }

  /**
   * Freezes address (no transfer can be made from or to this address).
   */
  function freeze(address _addr) onlyOwner {
      frozen[_addr] = true;
  }

  /**
   * Unfreezes frozen address.
   */
  function unfreeze(address _addr) onlyOwner {
      frozen[_addr] = false;
  }

  /**
   * Declines transfers from/to frozen addresses.
   */
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    require(!isFrozen(msg.sender));
    require(!isFrozen(_to));
    return super.transfer(_to, _value);
  }

  /**
   * Declines transfers from/to/by frozen addresses.
   */
  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    require(!isFrozen(msg.sender));
    require(!isFrozen(_from));
    require(!isFrozen(_to));
    return super.transferFrom(_from, _to, _value);
  }
}


contract SieChain is ModToken {
   uint256 _initialAmount = 1000000000;
    uint8 constant public decimals = 8;
    uint public totalSupply = _initialAmount * 10 ** uint256(decimals);
    string constant public name = "Sie Chain";
    string constant public symbol = "sie";
    
  function SieChain() public {
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
  }
}