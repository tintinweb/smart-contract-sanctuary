pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

contract Ownable {
  address public owner;


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
   *
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract ParticipantToken is StandardToken, Pausable {
  uint16 public totalParticipants = 0;
  mapping(address => bool) internal participants;

  modifier onlyParticipant() {
    require(isParticipant(msg.sender));
    _;
  }

  constructor() public {
    addParticipant(owner);
  }
  
  function transfer(address _to, uint256 _value) public onlyParticipant whenNotPaused returns (bool) {
    require(isParticipant(_to));
    
    super.transfer(_to, _value);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public onlyParticipant whenNotPaused returns (bool) {
    require(isParticipant(_from));
    require(isParticipant(_to));
    
    super.transferFrom(_from, _to, _value);
  }
  
  function isParticipant(address _address) public view returns (bool) {
    return participants[_address] == true;
  }
  
  function addParticipant(address _address) public onlyOwner whenNotPaused {
    require(isParticipant(_address) == false);
    
    participants[_address] = true;
    totalParticipants++;
  }
  
  function removeParticipant(address _address) public onlyOwner whenNotPaused {
    require(isParticipant(_address));
    require(balances[_address] == 0);
    
    participants[_address] = false;
    totalParticipants--;
  }
}

contract DistributionToken is ParticipantToken {
  uint256 public tokenDistributionDuration = 30 days;
  uint256 public currentDistributionAmount;
  uint256 public tokenDistributionStartTime;
  uint256 public tokenDistributionEndTime;
  address public tokenDistributionPool;
  
  mapping(address => uint256) private unclaimedTokens;
  mapping(address => uint256) private lastUnclaimedTokenUpdates;
  
  event TokenDistribution(address participant, uint256 value);
  
  constructor() public {
    tokenDistributionPool = owner;
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require((_to != tokenDistributionPool && msg.sender != tokenDistributionPool) || now >= tokenDistributionEndTime);
    
    super.transfer(_to, _value);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require((_to != tokenDistributionPool && _from != tokenDistributionPool) || now >= tokenDistributionEndTime);
    
    super.transferFrom(_from, _to, _value);
  }
  
  function claimTokens() public onlyParticipant whenNotPaused returns (bool) {
    require(tokenDistributionEndTime > 0 && now < tokenDistributionEndTime);
    require(msg.sender != tokenDistributionPool);
    require(lastUnclaimedTokenUpdates[msg.sender] < tokenDistributionStartTime);
    
    unclaimedTokens[msg.sender] = calcClaimableTokens();
    lastUnclaimedTokenUpdates[msg.sender] = now;
    
    uint256 value = unclaimedTokens[msg.sender];
    unclaimedTokens[msg.sender] = 0;
    
    balances[tokenDistributionPool] = balances[tokenDistributionPool].sub(value);
    balances[msg.sender] = balances[msg.sender].add(value);
    emit TokenDistribution(msg.sender, value);
    return true;
  }
  
  function claimableTokens() public view onlyParticipant returns (uint256) {
    if (lastUnclaimedTokenUpdates[msg.sender] >= tokenDistributionStartTime) {
      return unclaimedTokens[msg.sender];
    }
    
    return calcClaimableTokens();
  }
  
  function setTokenDistributionPool(address _tokenDistributionPool) public onlyOwner whenNotPaused returns (bool) {
    require(tokenDistributionEndTime < now);
    require(isParticipant(_tokenDistributionPool));
    
    tokenDistributionPool = _tokenDistributionPool;
    return true;
  }
  
  function startTokenDistribution() public onlyOwner whenNotPaused returns(bool) {
    require(tokenDistributionEndTime < now);
    require(balanceOf(tokenDistributionPool) > 0);
    
    currentDistributionAmount = balanceOf(tokenDistributionPool);
    tokenDistributionEndTime = now.add(tokenDistributionDuration);
    tokenDistributionStartTime = now;
    return true;
  }

  function calcClaimableTokens() private view onlyParticipant returns(uint256) {
    return (currentDistributionAmount.mul(balanceOf(msg.sender))).div(totalSupply_);
  }
}

contract DividendToken is DistributionToken {
  uint256 public dividendDistributionDuration = 30 days;
  uint256 public currentDividendAmount;
  uint256 public dividendDistributionStartTime;
  uint256 public dividendDistributionEndTime;
  address public dividendDistributionPool;
  
  mapping(address => uint256) private unclaimedDividends;
  mapping(address => uint256) private lastUnclaimedDividendUpdates;
  mapping(address => uint256) private unclaimedOCDividends;
  mapping(address => uint256) private lastUnclaimedOCDividendUpdates;
  
  event DividendDistribution(address participant, uint256 value);
  event OCDividendClaim(address participant, uint256 value);
  event OCDividendDistribution(address participant, uint256 value);
  
  constructor() public {
    dividendDistributionPool = owner;
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require((_to != dividendDistributionPool && msg.sender != dividendDistributionPool) || now >= dividendDistributionEndTime);
    
    super.transfer(_to, _value);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require((_to != dividendDistributionPool && _from != dividendDistributionPool) || now >= dividendDistributionEndTime);
    
    super.transferFrom(_from, _to, _value);
  }
  
  function claimDividend() public onlyParticipant whenNotPaused returns (bool) {
    require(dividendDistributionEndTime > 0 && now < dividendDistributionEndTime);
    require(msg.sender != dividendDistributionPool);
    
    updateUnclaimedDividend();
    
    uint256 value = unclaimedDividends[msg.sender];
    unclaimedDividends[msg.sender] = 0;
    
    balances[dividendDistributionPool] = balances[dividendDistributionPool].sub(value);
    balances[msg.sender] = balances[msg.sender].add(value);
    emit DividendDistribution(msg.sender, value);
    return true;
  }
  
  function claimableDividend() public view onlyParticipant returns (uint256) {
    if (lastUnclaimedDividendUpdates[msg.sender] >= dividendDistributionStartTime) {
      return unclaimedDividends[msg.sender];
    }
    
    return calcDividend();
  }
  
  function claimOCDividend() public onlyParticipant whenNotPaused returns (bool) {
    require(dividendDistributionEndTime > 0 && now < dividendDistributionEndTime);
    require(msg.sender != dividendDistributionPool);
    
    updateUnclaimedDividend();
    
    uint256 value = unclaimedDividends[msg.sender];
    unclaimedDividends[msg.sender] = 0;
    
    unclaimedOCDividends[msg.sender] = value;
    lastUnclaimedOCDividendUpdates[msg.sender] = now;
    
    balances[dividendDistributionPool] = balances[dividendDistributionPool].sub(value);
    balances[owner] = balances[owner].add(value);
    emit OCDividendClaim(msg.sender, value);
    return true;
  }
  
  function claimableOCDividend(address _address) public view onlyOwner returns (uint256) {
    if (isParticipant(_address) == false) {
      return 0;
    }
    
    if (dividendDistributionEndTime <= 0 || now >= dividendDistributionEndTime) {
      return 0;
    }
    
    if (lastUnclaimedOCDividendUpdates[_address] < dividendDistributionStartTime) {
      return 0;
    }
    
    return unclaimedOCDividends[_address];
  }
  
  function payoutOCDividend(address _address) public onlyOwner whenNotPaused returns (bool) {
    require(isParticipant(_address));
    require(dividendDistributionEndTime > 0 && now < dividendDistributionEndTime);
    require(unclaimedOCDividends[_address] > 0);
    
    uint256 value = unclaimedOCDividends[_address];
    unclaimedOCDividends[_address] = 0;
    emit OCDividendDistribution(_address, value);
    return true;
  }
  
  function setDividendDistributionPool(address _dividendDistributionPool) public onlyOwner whenNotPaused returns (bool) {
    require(dividendDistributionEndTime < now);
    require(isParticipant(_dividendDistributionPool));
    
    dividendDistributionPool = _dividendDistributionPool;
    return true;
  }
  
  function startDividendDistribution() public onlyOwner whenNotPaused returns(bool) {
    require(dividendDistributionEndTime < now);
    require(balanceOf(dividendDistributionPool) > 0);
    
    currentDividendAmount = balanceOf(dividendDistributionPool);
    dividendDistributionEndTime = now.add(dividendDistributionDuration);
    dividendDistributionStartTime = now;
    return true;
  }

  function calcDividend() private view onlyParticipant returns(uint256) {
    return (currentDividendAmount.mul(balanceOf(msg.sender))).div(totalSupply_);
  }
  
  function updateUnclaimedDividend() private whenNotPaused {
    require(lastUnclaimedDividendUpdates[msg.sender] < dividendDistributionStartTime);
    
    unclaimedDividends[msg.sender] = calcDividend();
    lastUnclaimedDividendUpdates[msg.sender] = now;
  }
}

contract ThisToken is DividendToken {
  string public name = "ThisToken";
  string public symbol = "THIS";
  uint8 public decimals = 18;

  function setTotalSupply(uint256 _totalSupply) public onlyOwner whenNotPaused {
    require(_totalSupply != totalSupply_);

    uint256 diff;

    if (_totalSupply < totalSupply_) {
      diff = totalSupply_.sub(_totalSupply);
      balances[owner] = balances[owner].sub(diff);
    } else {
      diff = _totalSupply.sub(totalSupply_);
      balances[owner] = balances[owner].add(diff);
    }

    totalSupply_ = _totalSupply;
  }
}