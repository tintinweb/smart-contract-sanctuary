/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

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
 * @title PIM token
 **/
 contract PIM is StandardBurnableToken, PausableToken {
     
    using SafeMath for uint256;
    string public constant name = "Pimride";
    string public constant symbol = "PIM";
    uint8 public constant decimals = 8;
    uint256 public constant INITIAL_SUPPLY = 1e9 * (10 ** uint256(decimals));
    uint constant LOCK_TOKEN_COUNT = 1000;
    
    struct LockedUserInfo{
        uint256 _releaseTime;
        uint256 _amount;
    }

    mapping(address => LockedUserInfo[]) private lockedUserEntity;
    mapping(address => bool) private supervisorEntity;
    mapping(address => bool) private lockedWalletEntity;

    modifier onlySupervisor() {
        require(owner == msg.sender || supervisorEntity[msg.sender]);
        _;
    }

    event Lock(address indexed holder, uint256 value, uint256 releaseTime);
    event Unlock(address indexed holder, uint256 value);
 
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
    
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        require(!isLockedWalletEntity(msg.sender));
        require(msg.sender != to,"Check your address!!");
        
        if (lockedUserEntity[msg.sender].length > 0 ) {
            _autoUnlock(msg.sender);            
        }
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused  returns (bool) {
        require(!isLockedWalletEntity(from) && !isLockedWalletEntity(msg.sender));
        if (lockedUserEntity[from].length > 0) {
            _autoUnlock(from);            
        }
        return super.transferFrom(from, to, value);
    }
    
    function transferWithLock(address holder, uint256 value, uint256 releaseTime) public onlySupervisor whenNotPaused returns (bool) {
        require(releaseTime > now && value > 0, "Check your values!!;");
        if(lockedUserEntity[holder].length >= LOCK_TOKEN_COUNT){
            return false;
        }
        transfer(holder, value);
        _lock(holder,value,releaseTime);
        return true;
    }
      
    function _lock(address holder, uint256 value, uint256 releaseTime) internal returns(bool) {
        balances[holder] = balances[holder].sub(value);
        lockedUserEntity[holder].push( LockedUserInfo(releaseTime, value) );
        
        emit Lock(holder, value, releaseTime);
        return true;
    }
    
    function _unlock(address holder, uint256 idx) internal returns(bool) {
        LockedUserInfo storage lockedUserInfo = lockedUserEntity[holder][idx];
        uint256 releaseAmount = lockedUserInfo._amount;

        delete lockedUserEntity[holder][idx];
        lockedUserEntity[holder][idx] = lockedUserEntity[holder][lockedUserEntity[holder].length.sub(1)];
        lockedUserEntity[holder].length -=1;
        
        emit Unlock(holder, releaseAmount);
        balances[holder] = balances[holder].add(releaseAmount);
        
        return true;
    }
    
    function _autoUnlock(address holder) internal returns(bool) {
        for(uint256 idx =0; idx < lockedUserEntity[holder].length ; idx++ ) {
            if (lockedUserEntity[holder][idx]._releaseTime <= now) {
                // If lockupinfo was deleted, loop restart at same position.
                if( _unlock(holder, idx) ) {
                    idx -=1;
                }
            }
        }
        return true;
    } 
    
    function setLockTime(address holder, uint idx, uint256 releaseTime) onlySupervisor public returns(bool){
        require(holder !=address(0) && idx >= 0 && releaseTime > now);
        require(lockedUserEntity[holder].length >= idx);
         
        lockedUserEntity[holder][idx]._releaseTime = releaseTime;
        return true;
    }
    
    function getLockedUserInfo(address _address) view public returns (uint256[], uint256[]){
        require(msg.sender == _address || msg.sender == owner || supervisorEntity[msg.sender]);
        uint256[] memory _returnAmount = new uint256[](lockedUserEntity[_address].length);
        uint256[] memory _returnReleaseTime = new uint256[](lockedUserEntity[_address].length);
        
        for(uint i = 0; i < lockedUserEntity[_address].length; i ++){
            _returnAmount[i] = lockedUserEntity[_address][i]._amount;
            _returnReleaseTime[i] = lockedUserEntity[_address][i]._releaseTime;
        }
        return (_returnAmount, _returnReleaseTime);
    }
    
    function burn(uint256 _value) onlySupervisor public {
        super._burn(msg.sender, _value);
    }
    
    function burnFrom(address _from, uint256 _value) onlySupervisor public {
        super.burnFrom(_from, _value);
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        
        uint256 totalBalance = super.balanceOf(owner);
        if( lockedUserEntity[owner].length >0 ){
            for(uint i=0; i<lockedUserEntity[owner].length;i++){
                totalBalance = totalBalance.add(lockedUserEntity[owner][i]._amount);
            }
        }
        
        return totalBalance;
    }

    function setSupervisor(address _address) onlyOwner public returns (bool){
        require(_address !=address(0) && !supervisorEntity[_address]);
        supervisorEntity[_address] = true;
        emit PrintLog(_address, "isSupervisor",  1);
        return true;
    }

    function removeSupervisor(address _address) onlyOwner public returns (bool){
        require(_address !=address(0) && supervisorEntity[_address]);
        delete supervisorEntity[_address];
        emit PrintLog(_address, "isSupervisor",  0);
        return true;
    }

    function setLockedWalletEntity(address _address) onlySupervisor public returns (bool){
        require(_address !=address(0) && !lockedWalletEntity[_address]);
        lockedWalletEntity[_address] = true;
        emit PrintLog(_address, "isLockedWalletEntity",  1);
        return true;
    }

    function removeLockedWalletEntity(address _address) onlySupervisor public returns (bool){
        require(_address !=address(0) && lockedWalletEntity[_address]);
        delete lockedWalletEntity[_address];
        emit PrintLog(_address, "isLockedWalletEntity",  0);
        return true;
    }

    function isSupervisor(address _address) view onlyOwner public returns (bool){
        return supervisorEntity[_address];
    }

    function isLockedWalletEntity(address _from) view private returns (bool){
        return lockedWalletEntity[_from];
    }

}