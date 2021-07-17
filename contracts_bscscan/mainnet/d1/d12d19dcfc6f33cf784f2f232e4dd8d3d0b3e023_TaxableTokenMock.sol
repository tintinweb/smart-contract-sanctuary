/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// File: contracts/CappedToken.sol


// File: zeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


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

// File: contracts/HasWhiteList.sol

pragma solidity ^0.4.18;

/* 
* @title HasWhiteList
* @dev allow the contracts that inherit from this to have a whitelist
*/
contract HasWhiteList is Ownable{
    //events
    event LogAddressAdded(address sender,address added);
    event LogAddressDeleted(address sender,address removed);    
    event AddressMinimunFeeChanged(address sender,uint256 oldFee,uint256 newFee);
    event AddressPercentageChanged(address sender,uint256 oldPercentage,uint256 newPercentage);
    //mappings
    mapping (address => bool) isInWhitelist;
    mapping (address => uint8) whitelistPercentage;
    mapping (address => uint256) whitelistMinimunFee;
    /**
    * @dev check if a given account is in the whitelist
    * @param acc address to chek.
    */
    function isInTheWhiteList(address acc) public constant returns(bool){
        return isInWhitelist[acc];
    }
    /**
    * @dev return the minimunFee assigned to a given account.
    * @param acc address to check.
    */
    function getWhitelistedMinimunFee(address acc) public constant returns(uint256){
        return whitelistMinimunFee[acc];
    }
    /**
    * @dev return the percentage assigned to a given account.
    * @param acc address to chek.
    */
    function getWhitelistedPercentage(address acc) public constant returns(uint256){
        return whitelistPercentage[acc];
    }
    /**
    * @dev add a new account in the whitelist.
    * @param acc address to add.
    * @param _percentage the percentage that has to be assigned to that account
    * @param _minimunFee the minimunFee that has to be assigned to that account
    */
    function addWhitelistedAccount(address acc,uint8 _percentage,uint256 _minimunFee) onlyOwner public returns(bool){
        require(!isInWhitelist[acc]);
        require(acc != 0);
        isInWhitelist[acc] = true;
        whitelistPercentage[acc] = _percentage;
        whitelistMinimunFee[acc] = _minimunFee;
        LogAddressAdded(msg.sender,acc);
        return true;
    }
    /**
    * @dev delete an account from the whitelist.
    * @param acc address to delete.
    */
    function deleteWhitelistedAccount(address acc) onlyOwner public returns(bool){
        require(isInWhitelist[acc]);
        isInWhitelist[acc] = false;
        whitelistPercentage[acc] = 0;
        whitelistMinimunFee[acc] = 0;
        LogAddressDeleted(msg.sender,acc);
        return true;
    }
    /**
    * @dev assign a new minimun fee to a whitelisted address;
    * @param acc address that have tobe modified.
    * @param amount the new minimun fee.
    */
    function changeWhitelistedMinimunFee(address acc,uint256 amount) onlyOwner public returns(bool){
        require(isInWhitelist[acc]);
        require(whitelistMinimunFee[acc] != amount);
        AddressMinimunFeeChanged(msg.sender,whitelistMinimunFee[acc],amount);
        whitelistMinimunFee[acc] = amount;
        return true;
    }
    /**
    * @dev assign a new percentage to a whitelisted address;
    * @param acc address that have to be modified.
    * @param amount the new percentage.
    */
    function changeWhitelistedPercentage(address acc,uint8 amount) onlyOwner public returns(bool){
        require(isInWhitelist[acc]);
        require(amount < 100);
        require(whitelistPercentage[acc] != amount);
        AddressPercentageChanged(msg.sender,whitelistPercentage[acc],amount);
        whitelistPercentage[acc] = amount;
        return true;
    }
}
// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;



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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol


// File: zeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol
pragma solidity ^0.4.24;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

pragma solidity ^0.4.24;




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

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
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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



// File: zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

pragma solidity ^0.4.24;



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
// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

pragma solidity ^0.4.24;




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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

pragma solidity ^0.4.24;




/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

pragma solidity ^0.4.11;



/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    return super.mint(_to, _amount);
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/PausableToken.sol

pragma solidity ^0.4.24;




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

// File: contracts/TaxableToken.sol

pragma solidity ^0.4.18;



// import "./Taxable.sol";


/**
 * @title ERC888 Token
 * @dev ERC20 Token with fee on sending
 */
contract TaxableToken is PausableToken,CappedToken,BurnableToken,HasWhiteList{
   //state variables
   string public name;
   string public symbol;
   uint8 public decimals;
       uint8 public percentage;
    uint256 public minimunFee;
  /**
  * @dev transfer token for a specified address burning a fee.
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    //required variables
    uint requiredPercentage;
    uint requiredMinimunFee; 
    if(isInWhitelist[msg.sender]){
        requiredPercentage = whitelistPercentage[msg.sender];
        requiredMinimunFee = whitelistMinimunFee[msg.sender];
    }else{
        requiredPercentage = percentage;
        requiredMinimunFee = minimunFee;
    }
    require(_value > requiredMinimunFee);
    //expected fee
    uint fee = (_value * requiredPercentage)/100;
    //substraction
    balances[msg.sender] = balances[msg.sender].sub(_value);
    //check if the fee can be accepted
    if(fee < requiredMinimunFee){
        totalSupply_ -= requiredMinimunFee;
        _value -= requiredMinimunFee;
    }
    else{
        totalSupply_ -= fee;
        _value -= fee; 
    }
    //transfer
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
   /**
   * @dev Transfer tokens from one address to another burning a fee.
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    //required variables
    uint requiredPercentage;
    uint requiredMinimunFee; 
    if(isInWhitelist[msg.sender]){
        requiredPercentage = whitelistPercentage[msg.sender];
        requiredMinimunFee = whitelistMinimunFee[msg.sender];
    }else{
        requiredPercentage = percentage;
        requiredMinimunFee = minimunFee;
    }
    require(_value > requiredMinimunFee);
    //expected fee
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    uint fee = (_value * requiredPercentage)/100;
    //substraction
    balances[_from] = balances[_from].sub(_value);
    //check if the fee can be accepted
    if(fee < requiredMinimunFee){
        totalSupply_ -= requiredMinimunFee;
        _value -= requiredMinimunFee;
    }
    else{
        totalSupply_ -= fee;
        _value -= fee; 
    }
    //transfer
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }
}
// File: contracts/Kuromi.sol



contract TaxableTokenMock is TaxableToken{
    function TaxableTokenMock(uint256 supply, uint256 _minimunFee, uint8 _percentage,string _name,string _symbol,uint8 _decimals) public{
        require(_percentage < 100);
        require(supply > 0);
        require(_decimals < 18);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        minimunFee = _minimunFee;
        percentage = _percentage;
        totalSupply_ = supply;
        cap = supply;
        balances[msg.sender] = supply;
    }
}