pragma solidity ^0.4.18;

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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


contract StandardToken is ERC20 {
  using SafeMath for uint256;

  uint256 public totalSupply;

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

    /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * Internal transfer, only can be called by this contract
   */
  function _transfer(address _from, address _to, uint _value) internal {
    require(_value > 0);
    require(balances[_from] >= _value);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
  }
  
  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    _transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require (_value <= allowed[_from][msg.sender]);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
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
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}



contract SEXNToken is StandardToken, Ownable {
  using SafeMath for uint256;

  string public constant name = "SexChain";
  string public constant symbol = "SEXN";
  uint8 public constant decimals = 18;

  struct lockInfo {
    uint256 amount;            // Total number of token locks
    uint256 start;             // The time when the lock was started.
    uint256 transfered;        // The number of tokens that have been unlocked.
    uint256 duration;          // The lock time for each cycle.
    uint256 releaseCount;      // locking cycle.
  }

  mapping(address => lockInfo) internal _lockInfo;
  // Query locked balance
  mapping(address => uint256) internal _lockupBalances;

  bool public preSaleFinished = false;

  // start and end timestamps where investments are allowed (both inclusive) 
  uint256 public startTime;
  uint256 public endTime;

  // how many token units a buyer gets per wei
  uint256 public rate;

  //The number of locks for each round of presale. eg: 5 is 5 days
  uint256 public lockCycle;

  // The length of one lock cycle, 
  uint256 public constant DURATION = 24 * 3600;  // a day

  /* The maximum amount of single users for pre-sales in the first period is 20,000. */
  uint256 public constant CAT_FIRST = 20000 * (10 ** 18);

  enum PresaleAction {
    Ready,
    FirstPresaleActivity,
    SecondPresaleActivity,
    ThirdPresaleActivity,
    END
  }

  PresaleAction public saleAction = PresaleAction.Ready;


  address private PRESALE_ADDRESS = 0xFD8C2759Fcf6E0BB57128d5dFCf1747AE9C7e3a1;         // Presale         
  address private FOUNDATION_ADDRESS = 0x096D756888F725ab56eA5bD2002102d10271BEc3;      // Community rewards 
  address private COMMERCIAL_PLAN_ADDRESS = 0x51bE0d2Ed867cB68450Bee2Fcbf11a5960843bbd; // commercial plan  
  address private POS_ADDRESS = 0x17c5fD5915DfaDe37EC0C04f1D70Ee495d6957af;             // DPOS                     
  address private TEAM_ADDRESS = 0xE38e1dB1fD7915D2ed877E8cE53697E57EC2417e;            // Technical team   
  address private COMMUNITY_TEAM_ADDRESS = 0xa34C472688D92511beb8fCDA42269a0526CfCCf0;  // community team   

  address public wallet = 0xDcE9E02972fDfEd54F4b307C75bd0755067cBc90;


  /////////////////
  /// Event
  /////////////////

  event UnLock(address indexed beneficiary, uint256 amount);
  event SellTokens(address indexed recipient, uint256 sellTokens, uint256 rate);

  /////////////////
  /// Modifier
  /////////////////

  /* check presale is active */
  modifier beginSaleActive() {
    require(now >= startTime && now <= endTime);
    _;
  }

  /* check presale is not active */
  modifier notpreSaleActive() {
    require(now <= startTime || now >= endTime);
    _;
  }

  /* For security reasons, need to change the wallet address */
  function changeWallet(address _newWallet) public {
      require(_newWallet != address(0x0));
      require(msg.sender == wallet);
      
      wallet = _newWallet;
  }

  /* Query the number of tokens for which an address is locked. */
  function getLockBalance(address _owner) public view returns(uint256){
    return _lockupBalances[_owner];
  }

  /* Check the remaining quantity of presale in this round. */
  function getRemainingPreSalesAmount() public view returns(uint256){
    return balances[PRESALE_ADDRESS];
  }

  /*Gets the unlocked time of the specified address. */
  function getLockTime(address _owner) public view returns(uint256){
    // start + ( lockCycle * duration )
    return _lockInfo[_owner].start.add(
        _lockInfo[_owner].releaseCount.mul(_lockInfo[_owner].duration));
  }

  /**
   * @dev Set the time and amount of presale for each period.
   * @param _round uint8  The number of presale activities
   * @param _startTime uint256  The current round of presales begins.
   * @param _stopTime uint256  The end of the round of presales.
   * @param _rate uint256   How many token units a buyer gets per wei.
   * @param _amount uint256  The number of presale tokens.
   */
  function setSaleInfo(uint8 _round ,uint256 _startTime, uint256 _stopTime, uint256 _rate, uint256 _amount) external notpreSaleActive onlyOwner {
    require(_round == 1 || _round == 2 || _round == 3);
    require(_startTime < _stopTime);
    require(_rate != 0 && _amount >= 0);
    require(_startTime > now); 
    require(!preSaleFinished);

    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[PRESALE_ADDRESS] = balances[PRESALE_ADDRESS].add(_amount);

    startTime = _startTime;
    endTime = _stopTime;
    rate = _rate;
    _caluLocktime(_round);
  }

  function _caluLocktime(uint8 _round) internal {
    require(_round == 1 || _round == 2 || _round == 3);
    if (_round == 1 ){
      saleAction = PresaleAction.FirstPresaleActivity;
      lockCycle = 200;        // 200 days
    }

    if (_round == 2){
      saleAction = PresaleAction.SecondPresaleActivity;
      lockCycle = 150;        // 150 days
    }

    if (_round == 3){
      saleAction = PresaleAction.ThirdPresaleActivity;
      lockCycle = 120;        // 120 days
    }
  }


  /* End the setup of presale activities. */
  function closeSale() public onlyOwner notpreSaleActive {
    preSaleFinished = true;
    saleAction = PresaleAction.END;
  }


  /**
   * @dev Distribute tokens from presale address to an address.
   * @param _to address  The address which you want to distribute to
   * @param _amount uint256  The amount of tokens to be distributed
   * @param _lockCycle uint256  Token locking cycle.
   * @param _duration uint256  The lock time for each cycle.
   */
  function _distribute(address _to, uint256 _amount, uint256 _lockCycle, uint256 _duration) internal returns(bool)  {
    ////Do not allow multiple distributions of the same address. Avoid locking time reset.
    require(_lockInfo[_to].amount == 0 );
    require(_lockupBalances[_to] == 0);

    _lockInfo[_to].amount = _amount;
    _lockInfo[_to].releaseCount = _lockCycle;
    _lockInfo[_to].start = now;
    _lockInfo[_to].transfered = 0;
    _lockInfo[_to].duration = _duration;
    
    //Easy to query locked balance
    _lockupBalances[_to] = _amount;

    return true;
  }


  /* Distribute tokens from presale address to an address. */
  function distribute(address _to, uint256 _amount, uint256 _lockCycle, uint256 _duration) public onlyOwner beginSaleActive {
    require(_to != 0x0);
    require(_amount != 0 && _lockCycle != 0 && _duration != 0);
    
    _distribute(_to, _amount,_lockCycle, _duration * DURATION);
    
    balances[PRESALE_ADDRESS] = balances[PRESALE_ADDRESS].sub(_amount);
    emit Transfer(PRESALE_ADDRESS, _to, _amount);
  }



  /* Calculate the unlockable balance */
  function _releasableAmount(address _owner, uint256 time) internal view returns (uint256){
    lockInfo storage userLockInfo = _lockInfo[_owner]; 
    if (userLockInfo.transfered == userLockInfo.amount){
      return 0;
    }

    // Unlockable tokens per cycle.
    uint256 amountPerRelease = userLockInfo.amount.div(userLockInfo.releaseCount); //amount/cnt
    // Total unlockable balance.
    uint256 amount = amountPerRelease.mul((time.sub(userLockInfo.start)).div(userLockInfo.duration));

    if (amount > userLockInfo.amount){
      amount = userLockInfo.amount;
    }
    // 
    amount = amount.sub(userLockInfo.transfered);

    return amount;
  }


  /* Unlock locked tokens */
  function relaseLock() internal returns(uint256){
    uint256 amount = _releasableAmount(msg.sender, now);
    if (amount > 0){
      _lockInfo[msg.sender].transfered = _lockInfo[msg.sender].transfered.add(amount);
      balances[msg.sender] = balances[msg.sender].add(amount);
      _lockupBalances[msg.sender] = _lockupBalances[msg.sender].sub(amount);
      emit UnLock(msg.sender, amount);
    }
    return 0;
  }


  function _initialize() internal {

    uint256 PRESALE_SUPPLY = totalSupply.mul(20).div(100);          // 20% for presale
    uint256 DPOS_SUPPLY = totalSupply.mul(30).div(100);             // 30% for DPOS
    uint256 COMMUNITY_REWARDS_SUPPLY = totalSupply.mul(20).div(100);// 20% for community rewards
    uint256 COMMUNITY_TEAM_SUPPLY = totalSupply.mul(10).div(100);   // 10% for community team
    uint256 COMMERCIAL_PLAN_SUPPLY = totalSupply * 10 / 100;        // 10% for commercial plan
    uint256 TEAM_SUPPLY = totalSupply.mul(10).div(100);             // 10% for technical team 

    balances[msg.sender] = PRESALE_SUPPLY;
    balances[FOUNDATION_ADDRESS] = COMMUNITY_REWARDS_SUPPLY;
    balances[POS_ADDRESS] = DPOS_SUPPLY;
    balances[COMMERCIAL_PLAN_ADDRESS] = COMMERCIAL_PLAN_SUPPLY;

    //This part of the token locks for one year。
    _distribute(COMMUNITY_TEAM_ADDRESS, COMMUNITY_TEAM_SUPPLY, 1, 365 days);

    //This part of the token is locked until August 1, divided into 2 phases to unlock.
    _distribute(0x7C88a1EC1D25c232464549ea9eF72B9bDc2a010A, TEAM_SUPPLY.mul(20).div(100), 2, 70 days); //0801

    // This part of the token locks for one year。
    _distribute(TEAM_ADDRESS, TEAM_SUPPLY.mul(80).div(100), 1, 365 days);

  }



  function SEXNToken() public {
    totalSupply = 580000000 * (10 ** 18); // 580 million
    _initialize();
  }


  /**
   * Fallback function
   * 
   * The function without name is the default function that is called whenever anyone sends funds to a contract
   * sell tokens automatic
   */
  function () external payable beginSaleActive {
      sellTokens();
  }


  /**
   * @dev Sell tokens to msg.sender
   *
   */
  function sellTokens() public payable beginSaleActive {
    require(msg.value > 0);

    uint256 amount = msg.value;
    uint256 tokens = amount.mul(rate);

    // check there are tokens for sale;
    require(tokens <= balances[PRESALE_ADDRESS]);

    if (saleAction == PresaleAction.FirstPresaleActivity){
      // The maximum amount of single users for presales in the first period is 20,000.
      require (tokens <= CAT_FIRST);
    }

    // send tokens to buyer
    _distribute(msg.sender, tokens, lockCycle, DURATION);

    
    balances[PRESALE_ADDRESS] = balances[PRESALE_ADDRESS].sub(tokens);

    emit Transfer(PRESALE_ADDRESS, msg.sender, tokens);
    emit SellTokens(msg.sender, tokens, rate);

    forwardFunds();
  }


  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
      wallet.transfer(msg.value);
  }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner].add(_lockupBalances[_owner]);
  }


  function transfer(address _to, uint256 _value) public returns (bool) {
    if (_lockupBalances[msg.sender] > 0){
      relaseLock();
    }

    return  super.transfer( _to, _value);
  }

}