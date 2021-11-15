/**
 *Submitted for verification at Etherscan.io on 2018-03-21
*/
//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.3;

import "../utils/SafeMath.sol";
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address who) public virtual view returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public virtual view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
  function approve(address spender, uint256 value) public virtual returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * CashBetCoin ERC20 token
 * Based on the OpenZeppelin Standard Token
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/StandardToken.sol
 */

abstract contract MigrationSource {
  function vacate(address _addr) public virtual returns (uint256 o_balance,
                                                 uint256 o_lock_value,
                                                 uint256 o_lock_endTime,
                                                 bytes32 o_operatorId,
                                                 bytes32 o_playerId);
}

contract CashBetCoin is MigrationSource, ERC20 {
  using SafeMath for uint256;

  string public constant name = "CashBetCoin";
  string public constant symbol = "CBC";
  uint8 public constant decimals = 8;
  uint internal totalSupply_;

  address public owner;

  mapping(bytes32 => bool) public operators;
  mapping(address => User) public users;
  mapping(address => mapping(bytes32 => bool)) public employees;
  
  MigrationSource public migrateFrom;
  address public migrateTo;

  struct User {
    uint256 balance;
    uint256 lock_value;
    uint256 lock_endTime;
    bytes32 operatorId;
    bytes32 playerId;
      
    mapping(address => uint256) authorized;
  }

  modifier only_owner(){
    require(msg.sender == owner);
    _;
  }

  modifier only_employees(address _user){
    require(employees[msg.sender][users[_user].operatorId]);
    _;
  }

  // PlayerId may only be set if operatorId is set too.
  modifier playerid_iff_operatorid(bytes32 _opId, bytes32 _playerId){
    require(_opId != bytes32(0) || _playerId == bytes32(0));
    _;
  }

  // Value argument must be less than unlocked balance.
  modifier value_less_than_unlocked_balance(address _user, uint256 _value){
    User storage user = users[_user];
    require(user.lock_endTime < block.timestamp ||
            _value <= user.balance - user.lock_value);
    require(_value <= user.balance);
    _;
  }

  event LockIncrease(address indexed user, uint256 amount, uint256 time);
  event LockDecrease(address indexed user, address employee,  uint256 amount, uint256 time);

  event Associate(address indexed user, address agent, bytes32 indexed operatorId, bytes32 playerId);
  
  event Burn(address indexed owner, uint256 value);

  event OptIn(address indexed owner, uint256 value);
  event Vacate(address indexed owner, uint256 value);

  event Employee(address indexed empl, bytes32 indexed operatorId, bool allowed);
  event Operator(bytes32 indexed operatorId, bool allowed);

  constructor(uint _totalSupply) public {
    totalSupply_ = _totalSupply;
    owner = msg.sender;
    User storage user = users[owner];
    user.balance = totalSupply_;
    user.lock_value = 0;
    user.lock_endTime = 0;
    user.operatorId = bytes32(0);
    user.playerId = bytes32(0);
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply() public view override returns (uint256){
    return totalSupply_;
  }

  function balanceOf(address _addr) public view override returns (uint256 balance) {
    return users[_addr].balance;
  }

  function transfer(address _to, uint256 _value) public override value_less_than_unlocked_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[msg.sender];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public override value_less_than_unlocked_balance(_from, _value) returns (bool success) {
    User storage user = users[_from];
    user.balance = user.balance.sub(_value);
    users[_to].balance = users[_to].balance.add(_value);
    user.authorized[msg.sender] = user.authorized[msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public override returns (bool success){
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (users[msg.sender].authorized[_spender] == 0));
    users[msg.sender].authorized[_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _user, address _spender) public view override returns (uint256){
    return users[_user].authorized[_spender];
  }

  // Returns the number of locked tokens at the specified address.
  //
  function lockedValueOf(address _addr) public view returns (uint256 value) {
    User storage user = users[_addr];
    // Is the lock expired?
    if (user.lock_endTime < block.timestamp) {
      // Lock is expired, no locked value.
      return 0;
    } else {
      return user.lock_value;
    }
  }

  // Returns the unix time that the current token lock will expire.
  //
  function lockedEndTimeOf(address _addr) public view returns (uint256 time) {
    return users[_addr].lock_endTime;
  }

  // Lock the specified number of tokens until the specified unix
  // time.  The locked value and expiration time are both absolute (if
  // the account already had some locked tokens the count will be
  // increased to this value.)  If the user already has locked tokens
  // the locked token count and expiration time may not be smaller
  // than the previous values.
  //
  function increaseLock(uint256 _value, uint256 _time) public returns (bool success) {
    User storage user = users[msg.sender];

    // Is there a lock in effect?
    if (block.timestamp < user.lock_endTime) {
      // Lock in effect, ensure nothing gets smaller.
      require(_value >= user.lock_value);
      require(_time >= user.lock_endTime);
      // Ensure something has increased.
      require(_value > user.lock_value || _time > user.lock_endTime);
    }

    // Things we always require.
    require(_value <= user.balance);
    require(_time > block.timestamp);

    user.lock_value = _value;
    user.lock_endTime = _time;
    emit LockIncrease(msg.sender, _value, _time);
    return true;
  }

  // Employees of CashBet may decrease the locked token value and/or
  // decrease the locked token expiration date.  These values may not
  // ever be increased by an employee.
  //
  function decreaseLock(uint256 _value, uint256 _time, address _user) public only_employees(_user) returns (bool success) {
    User storage user = users[_user];

    // We don't modify expired locks (they are already 0)
    require(user.lock_endTime > block.timestamp);
    // Ensure nothing gets bigger.
    require(_value <= user.lock_value);
    require(_time <= user.lock_endTime);
    // Ensure something has decreased.
    require(_value < user.lock_value || _time < user.lock_endTime);

    user.lock_value = _value;
    user.lock_endTime = _time;
    emit LockDecrease(_user, msg.sender, _value, _time);
    return true;
  }

  function associate(bytes32 _opId, bytes32 _playerId) public playerid_iff_operatorid(_opId, _playerId) returns (bool success) {
    User storage user = users[msg.sender];

    // Players can associate their playerId once while the token is
    // locked.  They can't change this association until the lock
    // expires ...
    require(user.lock_value == 0 ||
            user.lock_endTime < block.timestamp ||
            user.playerId == 0);

    // OperatorId argument must be empty or in the approved operators set.
    require(_opId == bytes32(0) || operators[_opId]);

    user.operatorId = _opId;
    user.playerId = _playerId;
    emit Associate(msg.sender, msg.sender, _opId, _playerId);
    return true;
  }

  function associationOf(address _addr) public view returns (bytes32 opId, bytes32 playerId) {
    return (users[_addr].operatorId, users[_addr].playerId);
  }

  function setAssociation(address _user, bytes32 _opId, bytes32 _playerId) public only_employees(_user) playerid_iff_operatorid(_opId, _playerId) returns (bool success) {
    User storage user = users[_user];

    // Employees may only set opId to empty or something they are an
    // employee of.
    require(_opId == bytes32(0) || employees[msg.sender][_opId]);
    
    user.operatorId = _opId;
    user.playerId = _playerId;
    emit Associate(_user, msg.sender, _opId, _playerId);
    return true;
  }
  
  function setEmployee(address _addr, bytes32 _opId, bool _allowed) public only_owner {
    employees[_addr][_opId] = _allowed;
    emit Employee(_addr, _opId, _allowed);
  }

  function setOperator(bytes32 _opId, bool _allowed) public only_owner {
    operators[_opId] = _allowed;
    emit Operator(_opId, _allowed);
  }

  function setOwner(address _addr) public only_owner {
    owner = _addr;
  }

  function burnTokens(uint256 _value) public value_less_than_unlocked_balance(msg.sender, _value) returns (bool success) {
    User storage user = users[msg.sender];
    user.balance = user.balance.sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

  // Sets the contract address that this contract will migrate
  // from when the optIn() interface is used.
  //
  function setMigrateFrom(address _addr) public only_owner {
    require(migrateFrom == MigrationSource(address(0)));
    migrateFrom = MigrationSource(_addr);
  }

  // Sets the contract address that is allowed to call vacate on this
  // contract.
  //
  function setMigrateTo(address _addr) public only_owner {
    migrateTo = _addr;
  }

  // Called by a token holding address, this method migrates the
  // tokens from an older version of the contract to this version.
  // The migrated tokens are merged with any existing tokens in this
  // version of the contract, resulting in the locked token count
  // being set to the sum of locked tokens in the old and new
  // contracts and the lock expiration being set the longest lock
  // duration for this address in either contract.  The playerId is
  // transferred unless it was already set in the new contract.
  //
  // NOTE - allowances (approve) are *not* transferred.  If you gave
  // another address an allowance in the old contract you need to
  // re-approve it in the new contract.
  //
  function optIn() public returns (bool success) {
    require(migrateFrom == MigrationSource(address(0)));
    User storage user = users[msg.sender];
    uint256 balance;
    uint256 lock_value;
    uint256 lock_endTime;
    bytes32 opId;
    bytes32 playerId;
    (balance, lock_value, lock_endTime, opId, playerId) =
        migrateFrom.vacate(msg.sender);

    emit OptIn(msg.sender, balance);
    
    user.balance = user.balance.add(balance);

    bool lockTimeIncreased = false;
    user.lock_value = user.lock_value.add(lock_value);
    if (user.lock_endTime < lock_endTime) {
      user.lock_endTime = lock_endTime;
      lockTimeIncreased = true;
    }
    if (lock_value > 0 || lockTimeIncreased) {
      emit LockIncrease(msg.sender, user.lock_value, user.lock_endTime);
    }

    if (user.operatorId == bytes32(0) && opId != bytes32(0)) {
      user.operatorId = opId;
      user.playerId = playerId;
      emit Associate(msg.sender, msg.sender, opId, playerId);
    }

    totalSupply_ = totalSupply_.add(balance);

    return true;
  }

  // The vacate method is called by a newer version of the CashBetCoin
  // contract to extract the token state for an address and migrate it
  // to the new contract.
  //
  function vacate(address _addr) public override returns (uint256 o_balance,
                                                 uint256 o_lock_value,
                                                 uint256 o_lock_endTime,
                                                 bytes32 o_opId,
                                                 bytes32 o_playerId) {
    require(msg.sender == migrateTo);
    User storage user = users[_addr];
    require(user.balance > 0);

    o_balance = user.balance;
    o_lock_value = user.lock_value;
    o_lock_endTime = user.lock_endTime;
    o_opId = user.operatorId;
    o_playerId = user.playerId;

    totalSupply_ = totalSupply_.sub(user.balance);

    user.balance = 0;
    user.lock_value = 0;
    user.lock_endTime = 0;
    user.operatorId = bytes32(0);
    user.playerId = bytes32(0);

    emit Vacate(_addr, o_balance);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

