pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
//   function renounceOwnership() public onlyOwner {
//     emit OwnershipRenounced(owner);
//     owner = address(0);
//   }

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

contract Token96D is StandardToken, Ownable {
  using SafeERC20 for ERC20Basic;
  string public name = "96D";
  string public symbol = "96D";
  uint public decimals = 18;
  uint INITIAL_SUPPLY = (1000000000)*(10**decimals);
  bool public mintingFinished = false;
  event RegretdToOwner();
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event MintStarted();
  
  
  constructor() public{
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    owner = msg.sender;
  }
  
  function regretToOwner(ERC20Basic token) public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(balance > 0);
    token.safeTransfer(owner, balance);
    emit RegretdToOwner();
  }
  
  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }
  
  function burnFrom(address _from, uint256 _value) public onlyOwner {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
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
  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }
  
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
  function finishMinting() public onlyOwner returns (bool) {
    if (mintingFinished) {
        mintingFinished = false;
        emit MintStarted();
    }
    else {
        mintingFinished = true;
        emit MintFinished();
    }
    return true;
  }
}



contract Vault is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;
  string public name;
  event Released(uint256 amount);
  event Revoked();
  event RegretdToOwner();
  event RegretdToBeneficiary();

  // beneficiary of tokens after they are released
  address public beneficiary;

  mapping (address => uint256) public released;
  uint256 public firstReleaseTime = 1577836800;
  uint256 secondReleaseTime = 1609459200;
  uint256 thirdReleaseTime = 1640995200;
  uint256 fourthReleaseTime = 1672531200;
  uint256 fifthReleaseTime = 1704067200;
  mapping (address => mapping (uint256 => bool)) public hasReleased;
  uint256[5] public allReleaseTime = [firstReleaseTime, secondReleaseTime, thirdReleaseTime, fourthReleaseTime, fifthReleaseTime];
  constructor(
    address _beneficiary,
    string _name
  )
    public
  {
    require(_beneficiary != address(0x0));
    beneficiary = _beneficiary;
    name = _name;
  }
  
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);
    if (now >= firstReleaseTime && now < secondReleaseTime) {
        return hasReleased[token][firstReleaseTime] ? 0 : totalBalance.div(5);
    }
    else if (now >= secondReleaseTime && now < thirdReleaseTime) {
        return hasReleased[token][secondReleaseTime] ? 0 : totalBalance.div(5);
    }
    else if (now >= thirdReleaseTime && now < fourthReleaseTime) {
        return hasReleased[token][thirdReleaseTime] ? 0 : totalBalance.div(5);
    }
    else if (now >= fourthReleaseTime && now < fifthReleaseTime) {
        return hasReleased[token][fourthReleaseTime] ? 0 : totalBalance.div(5);
    }
    else if (now >= fifthReleaseTime) {
        return hasReleased[token][fifthReleaseTime] ? 0 : totalBalance.div(5);
    }
    return 0;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public onlyOwner {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);
    updateReleasedState(token);
    emit Released(unreleased);
  }
  
  function updateReleasedState(ERC20Basic token) internal {
    if (now >= firstReleaseTime && now < secondReleaseTime && !hasReleased[token][firstReleaseTime]) {
        hasReleased[token][firstReleaseTime] = true;
    }
    else if (now >= secondReleaseTime && now < thirdReleaseTime && !hasReleased[token][secondReleaseTime]) {
        hasReleased[token][secondReleaseTime] = true;
    }
    else if (now >= thirdReleaseTime && now < fourthReleaseTime && !hasReleased[token][thirdReleaseTime]) {
        hasReleased[token][thirdReleaseTime] = true;
    }
    else if (now >= fourthReleaseTime && now < fifthReleaseTime && !hasReleased[token][fourthReleaseTime]) {
        hasReleased[token][fourthReleaseTime] = true;
    }
    else if (now >= fifthReleaseTime && !hasReleased[token][fifthReleaseTime]) {
        hasReleased[token][fifthReleaseTime] = true;
    }
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    uint256 balance = token.balanceOf(this);
    uint256 count = 0;
    require(balance > 0);
    for (uint i=0; i<allReleaseTime.length; i++) {
        if (now >= allReleaseTime[i] && !hasReleased[token][allReleaseTime[i]]) {
            count++;
            hasReleased[token][allReleaseTime[i]] = true;
        }
    }
    uint256 shouldRevoke = balance.add(released[token]);
    shouldRevoke = shouldRevoke.div(5).mul(count);
    released[token] = released[token].add(shouldRevoke);

    token.safeTransfer(owner, shouldRevoke);
    emit Revoked();
  }
  
  function revokableAmount(ERC20Basic token) view public onlyOwner returns(uint256) {
    uint256 balance = token.balanceOf(this);
    uint256 count = 0;
    for (uint i=0; i<allReleaseTime.length; i++) {
        if (now >= allReleaseTime[i] && !hasReleased[token][allReleaseTime[i]]) {
            count++;
        }
    }
    uint256 shouldRevoke = balance.add(released[token]);
    shouldRevoke = shouldRevoke.div(5).mul(count);
    return shouldRevoke;
  }
  
  function regretToOwner(ERC20Basic token) public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(balance > 0);
    token.safeTransfer(owner, balance);
    emit RegretdToOwner();
  }
  
  function regretToBeneficiary(ERC20Basic token) public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(balance > 0);
    token.safeTransfer(beneficiary, balance);
    emit RegretdToBeneficiary();
  }
}