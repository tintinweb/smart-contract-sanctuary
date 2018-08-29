pragma solidity ^ 0.4 .24;

// File: node_modules\zeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
   * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: node_modules\zeppelin-solidity\contracts\ownership\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns(uint256);

  function balanceOf(address who) public view returns(uint256);

  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath
  for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
   * @dev Total number of tokens in existence
   */
  function totalSupply() public view returns(uint256) {
    return totalSupply_;
  }

  /**
   * @dev Transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns(bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns(uint256) {
    return balances[_owner];
  }

}

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
  public view returns(uint256);

  function transferFrom(address from, address to, uint256 value)
  public returns(bool);

  function approve(address spender, uint256 value) public returns(bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping(address => mapping(address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
  public
  returns(bool) {
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
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns(bool) {
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
  function allowance(
    address _owner,
    address _spender
  )
  public
  view
  returns(uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
  public
  returns(bool) {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
  public
  returns(bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: node_modules\zeppelin-solidity\contracts\lifecycle\Pausable.sol

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

// File: node_modules\zeppelin-solidity\contracts\token\ERC20\PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
  public
  whenNotPaused
  returns(bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
  public
  whenNotPaused
  returns(bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
  public
  whenNotPaused
  returns(bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
  public
  whenNotPaused
  returns(bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
  public
  whenNotPaused
  returns(bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

// File: contracts\TopPlayerToken.sol

/*****************************************************************************
 *
 *Copyright 2018 TopPlayer
 *
 *Licensed under the Apache License, Version 2.0 (the "License");
 *you may not use this file except in compliance with the License.
 *You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *Unless required by applicable law or agreed to in writing, software
 *distributed under the License is distributed on an "AS IS" BASIS,
 *WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *See the License for the specific language governing permissions and
 *limitations under the License.
 *
 *****************************************************************************/

contract TopPlayerToken is PausableToken {
  using SafeMath
  for uint256;

  // ERC20 constants
  string public name = "Mu Chen Top Players Original";
  string public symbol = "MCTP-ORG";
  string public standard = "ERC20";

  uint8 public constant decimals = 18; // solium-disable-line uppercase

  uint256 public constant INITIAL_SUPPLY = 20 * (10 ** 8) * (10 ** 18);

  event ReleaseTarget(address target);

  mapping(address => TimeLock[]) public allocations;

  address[] public receiptors;

  address[] public froms;
  address[] public tos;
  uint[] public timess;
  uint256[] public balancess;
  uint[] public createTimes;

  struct TimeLock {
    uint time;
    uint256 balance;
    uint createTime;
  }

  /*Here is the constructor function that is executed when the instance is created*/
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }

  function getAllocations() public view returns(address[], address[],  uint[], uint256[], uint[]){
    getInfos();
    return (froms, tos, timess, balancess, createTimes); 
  }

  /**
   * @dev transfer token for a specified address if transfer is open
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns(bool) {
    require(canSubAllocation(msg.sender, _value));

    subAllocation(msg.sender);

    return super.transfer(_to, _value);
  }

  function canSubAllocation(address sender, uint256 sub_value) private constant returns(bool) {
    if (sub_value == 0) {
      return false;
    }

    if (balances[sender] < sub_value) {
      return false;
    }

    uint256 alllock_sum = 0;
    for (uint j = 0; j < allocations[sender].length; j++) {
      if (allocations[sender][j].time >= block.timestamp) {
        alllock_sum = alllock_sum.add(allocations[sender][j].balance);
      }
    }

    uint256 can_unlock = balances[sender].sub(alllock_sum);

    return can_unlock >= sub_value;
  }

  function subAllocation(address sender) private {
    for (uint j = 0; j < allocations[sender].length; j++) {
      if (allocations[sender][j].time < block.timestamp) {
        allocations[sender][j].balance = 0;
      }
    }
  }

  function setAllocation(address _address, uint256 total_value, uint time, uint256 balanceRequire) public onlyOwner returns(bool) {
    uint256 sum = 0;
    sum = sum.add(balanceRequire);

    require(total_value >= sum);

    require(balances[msg.sender] >= sum);

    uint256 createTime;

    if(allocations[_address].length == 0){
      receiptors.push(_address);
    }

    bool find = false;

    for (uint j = 0; j < allocations[_address].length; j++) {
      if (allocations[_address][j].time == time) {
        allocations[_address][j].balance = allocations[_address][j].balance.add(balanceRequire);
        find = true;
        break;
      }
    }

    if (!find) {
      createTime = now;
      allocations[_address].push(TimeLock(time, balanceRequire, createTime));
    }

    bool result = super.transfer(_address, total_value);

    emit Transferred(msg.sender, _address, createTime, total_value, time);

    return result;
  }

  function releaseAllocation(address target) public onlyOwner {
    require(balances[target] > 0);

    for (uint j = 0; j < allocations[target].length; j++) {
      allocations[target][j].balance = 0;
    }

    emit ReleaseTarget(target);
  }

  event Transferred(address from, address to, uint256 createAt, uint256 total_value, uint time);

  function getInfos() public {
    if (msg.sender == owner){
      for (uint i=0; i<receiptors.length; i++){
        for (uint j=0; j<allocations[receiptors[i]].length; j++){
          froms.push(owner);
          tos.push(receiptors[i]);
          timess.push(allocations[receiptors[i]][j].time);
          balancess.push(allocations[receiptors[i]][j].balance);
          createTimes.push(allocations[receiptors[i]][j].createTime);
        }
      }
    }else{
      for (uint k=0; k<allocations[msg.sender].length; k++){
        froms.push(owner);
        tos.push(msg.sender);
        timess.push(allocations[msg.sender][k].time);
        balancess.push(allocations[msg.sender][k].balance);
        createTimes.push(allocations[msg.sender][k].createTime);
      }
    }
  }
}