pragma solidity ^0.4.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by requiring a state.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted = false;

  modifier inNormalState {
    require(!halted);
    _;
  }

  modifier inEmergencyState {
    require(halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner inNormalState {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner inEmergencyState {
    halted = false;
  }
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

/**
 * @title Burnable
 *
 * @dev Standard ERC20 token
 */
contract Burnable is StandardToken {
  using SafeMath for uint;

  /* This notifies clients about the amount burnt */
  event Burn(address indexed from, uint value);

  function burn(uint _value) returns (bool success) {
    require(_value > 0 && balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint _value) returns (bool success) {
    require(_from != 0x0 && _value > 0 && balances[_from] >= _value);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Burn(_from, _value);
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    require(_to != 0x0); //use burn

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    require(_to != 0x0); //use burn

    return super.transferFrom(_from, _to, _value);
  }
}

/**
 * @title MyPizzaPieToken
 *
 * @dev Burnable Ownable ERC20 token
 */
contract MyPizzaPieToken is Burnable, Ownable {

  string public constant name = "MyPizzaPie Token";
  string public constant symbol = "PZA";
  uint8 public constant decimals = 18;
  uint public constant INITIAL_SUPPLY = 81192000 * 1 ether;

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
    _;
  }

  /** The function can be called only before or after the tokens have been released */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }


  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  function MyPizzaPieToken() {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }


  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  function release() onlyReleaseAgent inReleaseState(false) public {
    released = true;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);
    transferAgents[addr] = state;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call Burnable.transfer()
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call Burnable.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

  function burn(uint _value) onlyOwner returns (bool success) {
    return super.burn(_value);
  }

  function burnFrom(address _from, uint _value) onlyOwner returns (bool success) {
    return super.burnFrom(_from, _value);
  }
}

contract InvestorWhiteList is Ownable {
  mapping (address => bool) public investorWhiteList;

  mapping (address => address) public referralList;

  function InvestorWhiteList() {

  }

  function addInvestorToWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 && !investorWhiteList[investor]);
    investorWhiteList[investor] = true;
  }

  function removeInvestorFromWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 && investorWhiteList[investor]);
    investorWhiteList[investor] = false;
  }

  //when new user will contribute ICO contract will automatically send bonus to referral
  function addReferralOf(address investor, address referral) external onlyOwner {
    require(investor != 0x0 && referral != 0x0 && referralList[investor] == 0x0 && investor != referral);
    referralList[investor] = referral;
  }

  function isAllowed(address investor) constant external returns (bool result) {
    return investorWhiteList[investor];
  }

  function getReferralOf(address investor) constant external returns (address result) {
    return referralList[investor];
  }
}

contract PriceReceiver {
  address public ethPriceProvider;

  address public btcPriceProvider;

  modifier onlyEthPriceProvider() {
    require(msg.sender == ethPriceProvider);
    _;
  }

  modifier onlyBtcPriceProvider() {
    require(msg.sender == btcPriceProvider);
    _;
  }

  function receiveEthPrice(uint ethUsdPrice) external;

  function receiveBtcPrice(uint btcUsdPrice) external;

  function setEthPriceProvider(address provider) external;

  function setBtcPriceProvider(address provider) external;
}

contract MyPizzaPieTokenPreSale is Haltable, PriceReceiver {
  using SafeMath for uint;

  string public constant name = "MyPizzaPie Token PreSale";
  uint public VOLUME_70 = 2000 ether;
  uint public VOLUME_60 = 1000 ether;
  uint public VOLUME_50 = 100 ether;
  uint public VOLUME_25 = 1 ether;
  uint public VOLUME_5 = 0.1 ether;

  MyPizzaPieToken public token;
  InvestorWhiteList public investorWhiteList;

  address public beneficiary;

  uint public hardCap;
  uint public softCap;

  uint public ethUsdRate;
  uint public btcUsdRate;

  uint public tokenPriceUsd;
  uint public totalTokens;//in wei

  uint public collected = 0;
  uint public tokensSold = 0;
  uint public investorCount = 0;
  uint public weiRefunded = 0;

  uint public startTime;
  uint public endTime;

  bool public softCapReached = false;
  bool public crowdsaleFinished = false;

  mapping (address => bool) refunded;
  mapping (address => uint) public deposited;

  event SoftCapReached(uint softCap);
  event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);
  event Refunded(address indexed holder, uint amount);
  event Deposited(address indexed holder, uint amount);
  event Amount(uint amount);
  event Timestamp(uint time);

  modifier preSaleActive() {
    require(now >= startTime && now < endTime);
    _;
  }

  modifier preSaleEnded() {
    require(now >= endTime);
    _;
  }

  modifier inWhiteList() {
    require(investorWhiteList.isAllowed(msg.sender));
    _;
  }

  function MyPizzaPieTokenPreSale(
    uint _hardCapETH,
    uint _softCapETH,

    address _token,
    address _beneficiary,
    address _investorWhiteList,

    uint _totalTokens,
    uint _tokenPriceUsd,

    uint _baseEthUsdPrice,
    uint _baseBtcUsdPrice,

    uint _startTime,
    uint _endTime
  ) {
    ethUsdRate = _baseEthUsdPrice;
    btcUsdRate = _baseBtcUsdPrice;
    tokenPriceUsd = _tokenPriceUsd;

    totalTokens = _totalTokens.mul(1 ether);

    hardCap = _hardCapETH.mul(1 ether);
    softCap = _softCapETH.mul(1 ether);

    token = MyPizzaPieToken(_token);
    investorWhiteList = InvestorWhiteList(_investorWhiteList);
    beneficiary = _beneficiary;

    startTime = _startTime;
    endTime = _endTime;

    Timestamp(block.timestamp);
    Timestamp(startTime);
  }

  function() payable inWhiteList {
    doPurchase(msg.sender);
  }

  function refund() external preSaleEnded inNormalState {
    require(softCapReached == false);
    require(refunded[msg.sender] == false);

    uint refund = deposited[msg.sender];
    require(refund > 0);

    msg.sender.transfer(refund);
    deposited[msg.sender] = 0;
    refunded[msg.sender] = true;
    weiRefunded = weiRefunded.add(refund);
    Refunded(msg.sender, refund);
  }

  function withdraw() external onlyOwner {
    require(softCapReached);
    beneficiary.transfer(collected);
    token.transfer(beneficiary, token.balanceOf(this));
    crowdsaleFinished = true;
  }

  function receiveEthPrice(uint ethUsdPrice) external onlyEthPriceProvider {
    require(ethUsdPrice > 0);
    ethUsdRate = ethUsdPrice;
  }

  function receiveBtcPrice(uint btcUsdPrice) external onlyBtcPriceProvider {
    require(btcUsdPrice > 0);
    btcUsdRate = btcUsdPrice;
  }

  function setEthPriceProvider(address provider) external onlyOwner {
    require(provider != 0x0);
    ethPriceProvider = provider;
  }

  function setBtcPriceProvider(address provider) external onlyOwner {
    require(provider != 0x0);
    btcPriceProvider = provider;
  }

  function setNewWhiteList(address newWhiteList) external onlyOwner {
    require(newWhiteList != 0x0);
    investorWhiteList = InvestorWhiteList(newWhiteList);
  }

  function doPurchase(address _owner) private preSaleActive inNormalState {
    require(!crowdsaleFinished);
    require(collected.add(msg.value) <= hardCap);
    require(totalTokens >= tokensSold + msg.value.mul(ethUsdRate).div(tokenPriceUsd));

    if (!softCapReached && collected < softCap && collected.add(msg.value) >= softCap) {
      softCapReached = true;
      SoftCapReached(softCap);
    }

    uint tokens = msg.value.mul(ethUsdRate).div(tokenPriceUsd);
    uint bonus = calculateBonus(msg.value);
    
    if (bonus > 0) {
      tokens = tokens + tokens.mul(bonus).div(100);
    }

    if (token.balanceOf(msg.sender) == 0) investorCount++;

    collected = collected.add(msg.value);

    token.transfer(msg.sender, tokens);

    tokensSold = tokensSold.add(tokens);
    deposited[msg.sender] = deposited[msg.sender].add(msg.value);
    
    NewContribution(_owner, tokens, msg.value);
  }

  function calculateBonus(uint value) private returns (uint bonus) {
    if (value >= VOLUME_70) {
      return 70;
    } else if (value >= VOLUME_60) {
      return 60;
    } else if (value >= VOLUME_50) {
      return 50;
    } else if (value >= VOLUME_25) {
      return 25;
    }else if (value >= VOLUME_5) {
      return 5;
    }

    return 0;
  }
}