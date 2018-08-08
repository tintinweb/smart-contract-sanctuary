pragma solidity ^0.4.11;

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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value)public  returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value)public  returns (bool);
  function approve(address spender, uint256 value)public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause()public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value)public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title FFC Token
 * @dev FFC is PausableToken
 */
contract FFCToken is StandardToken, Pausable {

  string public constant name = "FFC";
  string public constant symbol = "FFC";
  uint256 public constant decimals = 18;
  
  // lock
  struct LockToken{
      uint256 amount;
      uint32  time;
  }
  struct LockTokenSet{
      LockToken[] lockList;
  }
  mapping ( address => LockTokenSet ) addressTimeLock;
  mapping ( address => bool ) lockAdminList;
  event TransferWithLockEvt(address indexed from, address indexed to, uint256 value,uint256 lockValue,uint32 lockTime );
  /**
    * @dev Creates a new MPKToken instance
    */
  constructor() public {
    totalSupply = 10 * (10 ** 8) * (10 ** 18);
    balances[msg.sender] = totalSupply;
  }
  
  function transfer(address _to, uint256 _value)public whenNotPaused returns (bool) {
    assert ( balances[msg.sender].sub( getLockAmount( msg.sender ) ) >= _value );
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value)public whenNotPaused returns (bool) {
    assert ( balances[_from].sub( getLockAmount( msg.sender ) ) >= _value );
    return super.transferFrom(_from, _to, _value);
  }
  function getLockAmount( address myaddress ) public view returns ( uint256 lockSum ) {
        uint256 lockAmount = 0;
        for( uint32 i = 0; i < addressTimeLock[myaddress].lockList.length; i ++ ){
            if( addressTimeLock[myaddress].lockList[i].time > now ){
                lockAmount += addressTimeLock[myaddress].lockList[i].amount;
            }
        }
        return lockAmount;
  }
  
  function getLockListLen( address myaddress ) public view returns ( uint256 lockAmount  ){
      return addressTimeLock[myaddress].lockList.length;
  }
  
  function getLockByIdx( address myaddress,uint32 idx ) public view returns ( uint256 lockAmount, uint32 lockTime ){
      if( idx >= addressTimeLock[myaddress].lockList.length ){
        return (0,0);          
      }
      lockAmount = addressTimeLock[myaddress].lockList[idx].amount;
      lockTime = addressTimeLock[myaddress].lockList[idx].time;
      return ( lockAmount,lockTime );
  }
  
  function transferWithLock( address _to, uint256 _value,uint256 _lockValue,uint32 _lockTime )public whenNotPaused {
      if( lockAdminList[msg.sender] != true ){
            return;
      }
      assert( _lockTime > now  );
      assert( _lockValue > 0 && _lockValue <= _value );
      transfer( _to, _value );
      bool needNewLock = true;
      for( uint32 i = 0 ; i< addressTimeLock[_to].lockList.length; i ++ ){
          if( addressTimeLock[_to].lockList[i].time < now ){
              addressTimeLock[_to].lockList[i].time = _lockTime;
              addressTimeLock[_to].lockList[i].amount = _lockValue;
              emit TransferWithLockEvt( msg.sender,_to,_value,_lockValue,_lockTime );
              needNewLock = false;
              break;
          }
      }
      if( needNewLock == true ){
          // add a lock
          addressTimeLock[_to].lockList.length ++ ;
          addressTimeLock[_to].lockList[(addressTimeLock[_to].lockList.length-1)].time = _lockTime;
          addressTimeLock[_to].lockList[(addressTimeLock[_to].lockList.length-1)].amount = _lockValue;
          emit TransferWithLockEvt( msg.sender,_to,_value,_lockValue,_lockTime);
      }
  }
  function setLockAdmin(address _to,bool canUse)public onlyOwner{
      lockAdminList[_to] = canUse;
  }
  function canUseLock()  public view returns (bool){
      return lockAdminList[msg.sender];
  }

}