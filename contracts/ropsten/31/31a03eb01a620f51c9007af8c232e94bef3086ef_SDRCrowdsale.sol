/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


abstract contract ERC20Basic {
  constructor() public { }
  function totalSupply() public view virtual returns (uint256);
  function balanceOf(address who) public view virtual returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {
      owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;
  function totalSupply() public view override returns (uint256) {
    return totalSupply_;
  }
  function transfer(address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return balances[_owner];
  }
}

abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view virtual returns (uint256);
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
  function approve(address spender, uint256 value) public virtual returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
    allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public override returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view override returns (uint256) {
    return allowed[_owner][_spender];
  }
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue - _subtractedValue;
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_ + _amount;
    balances[_to] = balances[_to] + _amount;
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  function burnTokens(uint256 _unsoldTokens) onlyOwner public returns (bool) {
    totalSupply_ = SafeMath.sub(totalSupply_, _unsoldTokens);
  }
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal view returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal view returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
contract Crowdsale is Ownable, Pausable {

  using SafeMath for uint256;
  MintableToken private token;

  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  uint256 public tier1BonusGiven;
  uint256 public tier2BonusGiven;
  uint256 public tier3BonusGiven;
  uint256 public tier4BonusGiven;
  uint256 public tier5BonusGiven;

  uint256 public referalBonus;    // 100
  
  address internal wallet;
  uint256 public rate;
  uint256 public weiRaised; // internal
  uint256 public nowTime;
  uint256 public tier1TimeSlot;
  uint256 public tier2TimeSlot;
  uint256 public tier3TimeSlot;
  uint256 public tier4TimeSlot;

  uint256 public totalSupply = SafeMath.mul(2000000000, 1 ether);

  uint256 public publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),60);
  
  uint256 public icoSupply = SafeMath.mul(SafeMath.div(totalSupply,100),60);

  uint256 public teamSupply = SafeMath.mul(SafeMath.div(totalSupply,100),12);  // Team supply of token
  uint256 public bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),3);  // Bounty Supply 
  uint256 public advisorSupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);   // Advisors
  uint256 public charitySupply = SafeMath.mul(SafeMath.div(totalSupply,100),15);  // Charitable
  uint256 public bonusSupply = SafeMath.mul(SafeMath.div(totalSupply,100),5); // Bonus Supply 

  uint256 public tier1ICOSupply = SafeMath.mul(SafeMath.div(icoSupply,100),12);
  uint256 public tier2ICOSupply = SafeMath.mul(SafeMath.div(icoSupply,100),10);
  uint256 public tier3ICOSupply = SafeMath.mul(SafeMath.div(icoSupply,100),8);
  uint256 public tier4ICOSupply = SafeMath.mul(SafeMath.div(icoSupply,100),5);
  uint256 public tier5ICOSupply = SafeMath.mul(SafeMath.div(icoSupply,100),65);

  uint256 public tier1BonusShare = SafeMath.mul(SafeMath.div(bonusSupply,100),50);
  uint256 public tier2BonusShare = SafeMath.mul(SafeMath.div(bonusSupply,100),25);
  uint256 public tier3BonusShare = SafeMath.mul(SafeMath.div(bonusSupply,100),15);
  uint256 public tier4BonusShare = SafeMath.mul(SafeMath.div(bonusSupply,100),10);
  uint256 public tier5BonusShare = SafeMath.mul(SafeMath.div(bonusSupply,100),0);

  uint256 public tier1BonusPercent = SafeMath.mul(SafeMath.div(tier1BonusShare,tier1ICOSupply),100);
  uint256 public tier2BonusPercent = SafeMath.mul(SafeMath.div(tier2BonusShare,tier2ICOSupply),100);
  uint256 public tier3BonusPercent = SafeMath.mul(SafeMath.div(tier3BonusShare,tier3ICOSupply),100);
  uint256 public tier4BonusPercent = SafeMath.mul(SafeMath.div(tier4BonusShare,tier4ICOSupply),100);
  uint256 public tier5BonusPercent = SafeMath.mul(SafeMath.div(tier5BonusShare,tier5ICOSupply),100);

  uint256 public teamTimeLock;
  uint256 public advisorTimeLock;
  bool public checkBurnTokens;
  bool public upgradeICOSupply;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    
    // require(_startTime >= block.timestamp);
    // require(_endTime >= _startTime);
    // require(_rate > 0); 
    // require(_wallet != address(0));
    
    token = createTokenContract();
    ICOstartTime = _startTime;
    ICOEndTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    nowTime = block.timestamp;

    tier1BonusGiven = SafeMath.div(SafeMath.mul(rate,tier1BonusPercent),100);
    tier2BonusGiven = SafeMath.div(SafeMath.mul(rate,tier2BonusPercent),100);
    tier3BonusGiven = SafeMath.div(SafeMath.mul(rate,tier3BonusPercent),100);
    tier4BonusGiven = SafeMath.div(SafeMath.mul(rate,tier4BonusPercent),100);
    tier5BonusGiven = SafeMath.div(SafeMath.mul(rate,tier5BonusPercent),100);
    
    referalBonus  = 100;

    /* ICO bonuses week calculations */
    tier1TimeSlot = SafeMath.add(ICOstartTime, 14 days);
    tier2TimeSlot = SafeMath.add(tier1TimeSlot, 14 days);
    tier3TimeSlot = SafeMath.add(tier2TimeSlot, 14 days);
    tier4TimeSlot = SafeMath.add(tier3TimeSlot, 14 days);


    /* Vested Period calculations for team and advisorships*/
    teamTimeLock = SafeMath.add(ICOstartTime, 365 days);
    advisorTimeLock = SafeMath.add(ICOstartTime, 180 days);
    
    checkBurnTokens = false;
    upgradeICOSupply = false;
  }
  function createTokenContract() internal virtual returns (MintableToken) {
    return new MintableToken();
  }
  // fallback function can be used to buy tokens
  fallback () external payable  {
    buyTokens(msg.sender);
  }
  // High level token purchase function
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != address(0));
    require(validPurchase());
    uint256 weiAmount = msg.value;
    uint256 accessTime = block.timestamp;
    uint256 tokens = 0;
    if (accessTime >= ICOstartTime) 
    {
      if (accessTime <= tier1TimeSlot) 
      { 
        tokens = SafeMath.add(tokens, weiAmount.mul(tier1BonusGiven));
        if(tokens > tier1BonusShare || weiAmount.mul(rate) > tier1ICOSupply ) {
          revert();
        } else {
          tier1BonusShare = tier1BonusShare.sub(tokens);      
          tier1ICOSupply = tier1ICOSupply.sub(weiAmount.mul(rate));      
        }
      } 
      else if (( accessTime <= tier2TimeSlot ) && (accessTime > tier1TimeSlot)) 
      { 
        tokens = SafeMath.add(tokens, weiAmount.mul(tier2BonusGiven));
        if(tokens > tier2BonusShare || weiAmount.mul(rate) > tier2ICOSupply ) {
          revert();
        } else {
          tier2BonusShare = tier2BonusShare.sub(tokens);      
          tier2ICOSupply = tier2ICOSupply.sub(weiAmount.mul(rate));      
        }
      } 
      else if (( accessTime <= tier3TimeSlot ) && (accessTime > tier2TimeSlot)) 
      {  
        tokens = SafeMath.add(tokens, weiAmount.mul(tier3BonusGiven));
        if(tokens > tier3BonusShare || weiAmount.mul(rate) > tier3ICOSupply ) {
          revert();
        } else {
          tier3BonusShare = tier3BonusShare.sub(tokens);      
          tier3ICOSupply = tier3ICOSupply.sub(weiAmount.mul(rate));      
        }
      } 
      else if (( accessTime <= tier4TimeSlot ) && (accessTime > tier3TimeSlot)) 
      {  
        tokens = SafeMath.add(tokens, weiAmount.mul(tier4BonusGiven));
        if(tokens > tier4BonusShare || weiAmount.mul(rate) > tier4ICOSupply ) {
          revert();
        } else {
          tier4BonusShare = tier4BonusShare.sub(tokens);      
          tier4ICOSupply = tier4ICOSupply.sub(weiAmount.mul(rate));      
        }
      } 
      // tokens = SafeMath.add(tokens, weiAmount.mul(tier5Bonus));
      tokens = SafeMath.add(tokens, weiAmount.mul(rate));
      icoSupply = icoSupply.sub(tokens);      
      publicSupply = publicSupply.sub(tokens);  
    } 
    else if ( accessTime < ICOstartTime ) 
    {
      revert();
    }

    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
  function forwardFunds() virtual internal {
    address(uint160(wallet)).transfer(msg.value);
  }
  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = block.timestamp >= ICOstartTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    //   return block.timestamp > ICOEndTime;
      return false;
  }
  function burnToken() onlyOwner  public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    token.burnTokens(icoSupply);
    totalSupply = SafeMath.sub(totalSupply, publicSupply);
    // preicoSupply = 0;
    icoSupply = 0;
    publicSupply = 0; 
    checkBurnTokens = true;
    return true;
  }
  function transferFunds(address[] memory recipients, uint256[] memory values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(publicSupply >= values[i]);
        publicSupply = SafeMath.sub(publicSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  } 
  function bountyFunds(address[] memory recipients, uint256[] memory values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(bountySupply >= values[i]);
        bountySupply = SafeMath.sub(bountySupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  }
  function transferAdvisorFunds(address[] memory recipients, uint256[] memory values) onlyOwner  public {
     require(!checkBurnTokens);
    require((block.timestamp > advisorTimeLock));
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(advisorSupply >= values[i]);
        advisorSupply = SafeMath.sub(advisorSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  }
  function transferTeamTokens(address[] memory recipients, uint256[] memory values) onlyOwner  public {
    require(!checkBurnTokens);
    require((block.timestamp > teamTimeLock));
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(teamSupply >= values[i]);
        teamSupply = SafeMath.sub(teamSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  }
  function transferCharityTokens(address[] memory recipients, uint256[] memory values) onlyOwner  public {
    require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(charitySupply >= values[i]);
        charitySupply = SafeMath.sub(charitySupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  }
}
abstract contract FinalizableCrowdsale is Crowdsale {
  using SafeMath for uint256;

  bool isFinalized = false;

  event Finalized();
  function finalizeCrowdsale() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    
    finalization();
    emit Finalized();
    
    isFinalized = true;
    }
  function finalization() virtual internal {
  }
}

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  constructor(address _wallet) public {
    // require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  function refund(address payable investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

abstract contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;
  uint256 public goal;
  RefundVault public vault;

  constructor(uint256 _goal) public {
    // require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

  // vault finalization task, called when owner calls finalize()
  function finalization() override internal {
    if (goalReached()) {
      // vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }
  function forwardFunds() virtual override internal {
    vault.deposit.value(msg.value)(msg.sender);
  }
}

contract SDR is MintableToken {
  string public constant name = "SDR Token";
  string public constant symbol = "SDR";
  uint8 public constant decimals = 18;

  // TODO --- update token total supply

  uint256 public totalSupplyTokens = SafeMath.mul(2000000000 , 1 ether);
  
  constructor() public { 
    totalSupply_ = totalSupplyTokens;
  }
}


contract SDRCrowdsale is Crowdsale, RefundableCrowdsale {


    uint256 _startTime = 1619853701;                                            // January/15/2019 @ 12:00am (UTC)
    uint256 _endTime = 1651389701;                                              // 05/15/2019 @ 11:59pm (UTC)
    uint256 _rate = 33750;                                                      // 1 ETHER Price :: DAYTA TOKENS ::
    uint256 _goal = 3000 * 1 ether;                                             // SOFT CAP
    address _wallet = 0x8B4BC98453558702449313a221EBbDAd764E9C89;               // WALLET ADDRESS 
 
      function forwardFunds() internal  override (Crowdsale, RefundableCrowdsale) {
      }

    /* Constructor DaytaCrowdsale */
    constructor() public
    FinalizableCrowdsale() 
    RefundableCrowdsale(_goal) 
    Crowdsale(_startTime,_endTime,_rate,_wallet)
    {
    }

    /*Dayta Contract is generating from here */
    function createTokenContract() internal override returns (MintableToken) {
        return new SDR();
    }
}