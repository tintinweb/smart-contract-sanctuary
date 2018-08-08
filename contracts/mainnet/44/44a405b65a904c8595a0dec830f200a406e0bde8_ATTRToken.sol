pragma solidity ^0.4.23;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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



/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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
    hasMintPermission
    canMint
    public
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
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
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
    // onlyOwner
    canMint
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}



contract ATTRToken is CappedToken, DetailedERC20 {

  using SafeMath for uint256;

  uint256 public constant TOTAL_SUPPLY       = uint256(1000000000);
  uint256 public constant TOTAL_SUPPLY_ACES  = uint256(1000000000000000000000000000);
  uint256 public constant CROWDSALE_MAX_ACES = uint256(500000000000000000000000000);

  address public crowdsaleContract;
  uint256 public crowdsaleMinted = uint256(0);

  uint256 public releaseTime = uint256(1536278399); // &#39;2018-09-06T23:59:59Z&#39;.unix()
  bool    public fundingLowcapReached = false;
  bool    public isReleased = false;

  mapping (address => bool) public agents;

  mapping (address => bool) public transferWhitelist;

  constructor() public 
    CappedToken(TOTAL_SUPPLY_ACES) 
    DetailedERC20("Attrace", "ATTR", uint8(18)) {
    transferWhitelist[msg.sender] = true;
    agents[msg.sender] = true;
  }
  
  // **********
  // VALIDATION
  // **********
  modifier isInitialized() {
    require(crowdsaleContract != address(0));
    require(releaseTime > 0);
    _;
  }

  // ********
  // CONTROLS
  // ********
  function setAgent(address _address, bool _status) public onlyOwner {
    require(_address != address(0));
    agents[_address] = _status;
  }

  modifier onlyAgents() {
    require(agents[msg.sender] == true);
    _;
  }

  function setCrowdsaleContract(address _crowdsaleContract) public onlyAgents {
    require(_crowdsaleContract != address(0));
    crowdsaleContract = _crowdsaleContract;
  }

  function setTransferWhitelist(address _address, bool _canTransfer) public onlyAgents {
    require(_address != address(0));
    transferWhitelist[_address] = _canTransfer;
  }

  function setReleaseTime(uint256 _time) public onlyAgents {
    require(_time > block.timestamp);
    require(isReleased == false);
    releaseTime = _time;
  }

  function setFundingLowcapReached(uint256 _verification) public onlyAgents {
    require(_verification == uint256(20234983249), "wrong verification code");
    fundingLowcapReached = true;
  }

  function markReleased() public {
    if (isReleased == false && _now() > releaseTime) {
      isReleased = true;
    }
  }

  // *******
  // MINTING
  // *******
  modifier hasMintPermission() {
    require(msg.sender == crowdsaleContract || agents[msg.sender] == true);
    _;
  }

  function mint(address _to, uint256 _aces) public canMint hasMintPermission returns (bool) {
    if (msg.sender == crowdsaleContract) {
      require(crowdsaleMinted.add(_aces) <= CROWDSALE_MAX_ACES);
      crowdsaleMinted = crowdsaleMinted.add(_aces);
    }
    return super.mint(_to, _aces);
  }

  // ********
  // TRANSFER
  // ********
  modifier canTransfer(address _from) {
    if (transferWhitelist[_from] == false) {
      require(block.timestamp >= releaseTime);
      require(fundingLowcapReached == true);
    }
    _;
  }

  function transfer(address _to, uint256 _aces) 
    public
    isInitialized
    canTransfer(msg.sender) 
    tokensAreUnlocked(msg.sender, _aces)
    returns (bool) {
      markReleased();
      return super.transfer(_to, _aces);
    }

  function transferFrom(address _from, address _to, uint256 _aces) 
    public
    isInitialized
    canTransfer(_from) 
    tokensAreUnlocked(_from, _aces)
    returns (bool) {
      markReleased();
      return super.transferFrom(_from, _to, _aces);
    }

  // *******
  // VESTING
  // *******
  struct VestingRule {
    uint256 aces;
    uint256 unlockTime;
    bool    processed;
  }

  // Controls the amount of locked tokens
  mapping (address => uint256) public lockedAces;

  modifier tokensAreUnlocked(address _from, uint256 _aces) {
    if (lockedAces[_from] > uint256(0)) {
      require(balanceOf(_from).sub(lockedAces[_from]) >= _aces);
    }
    _;
  }

  // Dynamic vesting rules
  mapping (address => VestingRule[]) public vestingRules;

  function processVestingRules(address _address) public onlyAgents {
    _processVestingRules(_address);
  }

  function processMyVestingRules() public {
    _processVestingRules(msg.sender);
  }

  function addVestingRule(address _address, uint256 _aces, uint256 _unlockTime) public {
    require(_aces > 0);
    require(_address != address(0));
    require(_unlockTime > _now());
    if (_now() < releaseTime) {
      require(msg.sender == owner);
    } else {
      require(msg.sender == crowdsaleContract || msg.sender == owner);
      require(_now() < releaseTime.add(uint256(2592000)));
    }
    vestingRules[_address].push(VestingRule({ 
      aces: _aces,
      unlockTime: _unlockTime,
      processed: false
    }));
    lockedAces[_address] = lockedAces[_address].add(_aces);
  }

  // Loop over vesting rules, bail if date not yet passed.
  // If date passed, unlock aces and disable rule
  function _processVestingRules(address _address) internal {
    for (uint256 i = uint256(0); i < vestingRules[_address].length; i++) {
      if (vestingRules[_address][i].processed == false && vestingRules[_address][i].unlockTime < _now()) {
        lockedAces[_address] = lockedAces[_address].sub(vestingRules[_address][i].aces);
        vestingRules[_address][i].processed = true;
      }
    }
  }

  // *******
  // TESTING 
  // *******
  function _now() internal view returns (uint256) {
    return block.timestamp;
  }
}