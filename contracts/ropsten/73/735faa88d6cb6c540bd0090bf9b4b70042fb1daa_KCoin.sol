pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
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
  function transfer(address _to, uint256 _value) public returns (bool) {
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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


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
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
    returns (bool)
  {
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
    returns (bool)
  {
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
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */

contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
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
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

/**
 * @title Kcon token
 **/
contract KCoin is StandardBurnableToken, PausableToken {
    using SafeMath for uint256;
    string public constant name = "KCon";
    string public constant symbol = "KCN";
    uint8 public constant decimals = 8;
    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals));
    
    struct lockedUserInfo{
        address lockedUserAddress;
        uint firstUnlockTime;
        uint secondUnlockTime;
        uint thirdUnlockTime;
        uint256 firstUnlockValue;
        uint256 secondUnlockValue;
        uint256 thirdUnlockValue;
    }

    mapping(address => lockedUserInfo) private lockedUserEntity;
    mapping(address => bool) private supervisorEntity;

    modifier onlySupervisor() {
        require(owner == msg.sender || supervisorEntity[msg.sender]);
        _;
    }

    event Unlock( 
        address indexed lockedUser,
        uint lockPeriod,
        uint256 firstUnlockValue,
        uint256 secondUnlockValueUnlockValue,
        uint256 thirdUnlockValue
    );
    
    event PrintLog(
        address indexed sender, 
        string _logName, 
        uint256 _value
    );

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    
    function transfer( address _to, uint256 _value ) public whenNotPaused returns (bool) {
        require(msg.sender != _to,"Check your address!!");
        uint256 availableValue = getAvailableWithdrawableCount(msg.sender, _value);
        emit PrintLog(_to, "availableResultValue", availableValue);
        require(availableValue > 0);
        return super.transfer(_to, availableValue);
    }

    function burn(uint256 _value) onlySupervisor public {
        super._burn(msg.sender, _value);
    }
    
    function transferToLockedBalance(
        address _to,
        uint _firstUnlockTime,
        uint256 _firstUnlockValue,
        uint _secondUnlockTime,
        uint256 _secondUnlockValue,
        uint _thirdUnlockTime,
        uint256 _thirdUnlockValue
    ) onlySupervisor whenNotPaused public returns (bool) {
        require(msg.sender != _to,"Check your address!!");
        require(_firstUnlockTime > now && _firstUnlockValue > 0, "Check your First input values!!;");

        uint256 totalLockSendCount = totalLockSendCount.add(_firstUnlockValue);

        if(_secondUnlockTime > now && _secondUnlockValue > 0){
            require(_secondUnlockTime > _firstUnlockTime, "Second Unlock time must be greater than First Unlock Time!!");
                    
            totalLockSendCount = totalLockSendCount.add(_secondUnlockValue);
        }
    
        if(_thirdUnlockTime > now && _thirdUnlockValue > 0){
            require(_thirdUnlockTime > _secondUnlockTime && _secondUnlockTime > now &&  _secondUnlockValue > 0,
                    "Check your third Unlock Time or Second input values!!");
            totalLockSendCount = totalLockSendCount.add(_thirdUnlockValue);
        }
    
        if (transfer(_to, totalLockSendCount)) {
            lockedUserEntity[_to].lockedUserAddress = _to;
            lockedUserEntity[_to].firstUnlockTime = _firstUnlockTime;
            lockedUserEntity[_to].firstUnlockValue = _firstUnlockValue;
    
            if(_secondUnlockTime > now && _secondUnlockValue > 0){
                lockedUserEntity[_to].secondUnlockTime = _secondUnlockTime;
                lockedUserEntity[_to].secondUnlockValue = _secondUnlockValue;
            }
    
            if(_thirdUnlockTime > now && _thirdUnlockValue > 0){
                lockedUserEntity[_to].thirdUnlockTime  = _thirdUnlockTime;
                lockedUserEntity[_to].thirdUnlockValue = _thirdUnlockValue;
            }
    
            return true;
        }
    }
  
    function setLockTime(address _to, uint _time, uint256 _lockTime) onlySupervisor public returns(bool){
        require(_to !=0 && _time > 0 && _time < 4 && _lockTime > now);
      
        (   uint firstUnlockTime, 
            uint secondUnlockTime, 
            uint thirdUnlockTime 
        ) = getLockedTimeUserInfo(_to);
          
        if(_time == 1 && firstUnlockTime !=0){
            if(secondUnlockTime ==0 || _lockTime < secondUnlockTime){
                lockedUserEntity[_to].firstUnlockTime = _lockTime;
                return true;
            }
        }else if(_time == 2 && secondUnlockTime !=0){
            if(_lockTime > firstUnlockTime && (thirdUnlockTime ==0 || _lockTime < thirdUnlockTime)){
                lockedUserEntity[_to].secondUnlockTime = _lockTime;
                return true;
            }
        }else if(_time == 3 && thirdUnlockTime !=0 && _lockTime > secondUnlockTime){
            lockedUserEntity[_to].thirdUnlockTime = _lockTime;
            return true;
        }
        return false;
    }  
     
    function getLockedUserInfo(address _address) view public returns (uint,uint256,uint,uint256,uint,uint256){
        require(msg.sender == _address || msg.sender == owner || supervisorEntity[msg.sender]);
        return (
                    lockedUserEntity[_address].firstUnlockTime,
                    lockedUserEntity[_address].firstUnlockValue,
                    lockedUserEntity[_address].secondUnlockTime,
                    lockedUserEntity[_address].secondUnlockValue,
                    lockedUserEntity[_address].thirdUnlockTime,
                    lockedUserEntity[_address].thirdUnlockValue
                );
    }

    function setSupervisor(address _address) onlyOwner public returns (bool){
        require(_address !=0 && !supervisorEntity[_address]);
        supervisorEntity[_address] = true;
    }

    function removeSupervisor(address _address) onlyOwner public returns (bool){
        delete supervisorEntity[_address];
    }
    
    function getLockedTimeUserInfo(address _address) view private returns (uint,uint,uint){
        require(msg.sender == _address || msg.sender == owner || supervisorEntity[msg.sender]);
        return (
                    lockedUserEntity[_address].firstUnlockTime,
                    lockedUserEntity[_address].secondUnlockTime,
                    lockedUserEntity[_address].thirdUnlockTime
                );
    }

    function isSupervisor() view onlyOwner private returns (bool){
        return supervisorEntity[msg.sender];
    }

    function getAvailableWithdrawableCount( address _from , uint256 _sendOrgValue) private returns (uint256) {
        uint256 availableValue = 0;
    
        if(lockedUserEntity[_from].lockedUserAddress == address(0)){
            availableValue = _sendOrgValue;
        }else{
                (   
                    uint firstUnlockTime, uint256 firstUnlockValue,
                    uint secondUnlockTime, uint256 secondUnlockValue,
                    uint thirdUnlockTime, uint256 thirdUnlockValue
                ) = getLockedUserInfo(_from);
    
                if(now < firstUnlockTime) {
                    availableValue = balances[_from].sub(firstUnlockValue.add(secondUnlockValue).add(thirdUnlockValue));
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue = _sendOrgValue;
                    }
                }else if(firstUnlockTime <= now && secondUnlockTime ==0){
                    availableValue = balances[_from];
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue = _sendOrgValue;
                        delete lockedUserEntity[_from];
                        emit Unlock(_from, 1, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }else if(firstUnlockTime <= now && secondUnlockTime !=0 && now < secondUnlockTime){
                    availableValue = balances[_from].sub(secondUnlockValue.add(thirdUnlockValue));
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{ 
                        availableValue = _sendOrgValue;
                        lockedUserEntity[_from].firstUnlockValue = 0;
                        emit Unlock(_from, 1, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }else if(secondUnlockTime !=0 && secondUnlockTime <= now && thirdUnlockTime ==0){
                    availableValue = balances[_from];
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue =_sendOrgValue;
                        delete lockedUserEntity[_from];
                        emit Unlock(_from, 2, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }else if(secondUnlockTime !=0 && secondUnlockTime <= now && thirdUnlockTime !=0 && now < thirdUnlockTime){
                    availableValue = balances[_from].sub(thirdUnlockValue);
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else{
                        availableValue = _sendOrgValue;
                        lockedUserEntity[_from].firstUnlockValue = 0;
                        lockedUserEntity[_from].secondUnlockValue = 0;
                        emit Unlock(_from, 2, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }else if(thirdUnlockTime !=0 && thirdUnlockTime <= now){
                    availableValue = balances[_from];
                    if(_sendOrgValue > availableValue){
                        availableValue = 0;
                    }else if(_sendOrgValue <= availableValue){
                        availableValue = _sendOrgValue;
                        delete lockedUserEntity[_from];
                        emit Unlock(_from, 3, firstUnlockValue, secondUnlockValue, thirdUnlockValue);
                    }
                }
        }
        return availableValue;
    }
 
}