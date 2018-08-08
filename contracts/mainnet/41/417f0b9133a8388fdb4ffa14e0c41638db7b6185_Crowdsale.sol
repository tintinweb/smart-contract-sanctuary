pragma solidity ^0.4.13;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
  
}

contract INCToken is MintableToken {	
    
  string public constant name = "Instacoin";
   
  string public constant symbol = "INC";
    
  uint32 public constant decimals = 18;

  bool public transferAllowed = false;

  modifier whenTransferAllowed() {
    require(transferAllowed || msg.sender == owner);
    _;
  }

  function allowTransfer() onlyOwner {
    transferAllowed = true;
  }

  function transfer(address _to, uint256 _value) whenTransferAllowed returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) whenTransferAllowed returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
    
}


contract StagedCrowdsale is Pausable {

  using SafeMath for uint;

  struct Milestone {
    uint period;
    uint bonus;
  }

  uint public start;

  uint public totalPeriod;

  uint public invested;

  uint public hardCap;
 
  Milestone[] public milestones;

  function milestonesCount() constant returns(uint) {
    return milestones.length;
  }

  function setStart(uint newStart) onlyOwner {
    start = newStart;
  }

  function setHardcap(uint newHardcap) onlyOwner {
    hardCap = newHardcap;
  }

  function addMilestone(uint period, uint bonus) onlyOwner {
    require(period > 0);
    milestones.push(Milestone(period, bonus));
    totalPeriod = totalPeriod.add(period);
  }

  function removeMilestone(uint8 number) onlyOwner {
    require(number < milestones.length);
    Milestone storage milestone = milestones[number];
    totalPeriod = totalPeriod.sub(milestone.period);

    delete milestones[number];

    for (uint i = number; i < milestones.length - 1; i++) {
      milestones[i] = milestones[i+1];
    }

    milestones.length--;
  }

  function changeMilestone(uint8 number, uint period, uint bonus) onlyOwner {
    require(number < milestones.length);
    Milestone storage milestone = milestones[number];

    totalPeriod = totalPeriod.sub(milestone.period);    

    milestone.period = period;
    milestone.bonus = bonus;

    totalPeriod = totalPeriod.add(period);    
  }

  function insertMilestone(uint8 numberAfter, uint period, uint bonus) onlyOwner {
    require(numberAfter < milestones.length);

    totalPeriod = totalPeriod.add(period);

    milestones.length++;

    for (uint i = milestones.length - 2; i > numberAfter; i--) {
      milestones[i + 1] = milestones[i];
    }

    milestones[numberAfter + 1] = Milestone(period, bonus);
  }

  function clearMilestones() onlyOwner {
    require(milestones.length > 0);
    for (uint i = 0; i < milestones.length; i++) {
      delete milestones[i];
    }
    milestones.length -= milestones.length;
    totalPeriod = 0;
  }

  modifier saleIsOn() {
    require(milestones.length > 0 && now >= start && now < lastSaleDate());
    _;
  }
  
  modifier isUnderHardCap() {
    require(invested <= hardCap);
    _;
  }
  
  function lastSaleDate() constant returns(uint) {
    require(milestones.length > 0);
    return start + totalPeriod * 1 days;
  }

  function currentMilestone() saleIsOn constant returns(uint) {
    uint previousDate = start;
    for(uint i=0; i < milestones.length; i++) {
      if(now >= previousDate && now < previousDate + milestones[i].period * 1 days) {
        return i;
      }
      previousDate = previousDate.add(milestones[i].period * 1 days);
    }
    revert();
  }

}

/**
 * @title PreSale
 * @dev The PreSale contract stores balances investors of pre sale stage.
 */
contract PreSale is Pausable {
    
  event Invest(address, uint);

  using SafeMath for uint;
    
  address public wallet;

  uint public start;
  
  uint public total;
  
  uint16 public period;

  mapping (address => uint) balances;

  mapping (address => bool) invested;
  
  address[] public investors;
  
  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }
  
  function totalInvestors() constant returns (uint) {
    return investors.length;
  }
  
  function balanceOf(address investor) constant returns (uint) {
    return balances[investor];
  }
  
  function setStart(uint newStart) onlyOwner {
    start = newStart;
  }
  
  function setPeriod(uint16 newPeriod) onlyOwner {
    period = newPeriod;
  }
  
  function setWallet(address newWallet) onlyOwner {
    require(newWallet != address(0));
    wallet = newWallet;
  }

  function invest() saleIsOn whenNotPaused payable {
    wallet.transfer(msg.value);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    bool isInvested = invested[msg.sender];
    if(!isInvested) {
        investors.push(msg.sender);    
        invested[msg.sender] = true;
    }
    total = total.add(msg.value);
    Invest(msg.sender, msg.value);
  }

  function() external payable {
    invest();
  }

}

contract Crowdsale is StagedCrowdsale {

  address public multisigWallet;
  
  address public foundersTokensWallet;
  
  address public bountyTokensWallet;

  uint public foundersTokensPercent;
  
  uint public bountyTokensPercent;
 
  uint public price;

  uint public percentRate = 100;

  uint public earlyInvestorsBonus;

  PreSale public presale;

  bool public earlyInvestorsMintedTokens = false;

  INCToken public token = new INCToken();

  function setPrice(uint newPrice) onlyOwner {
    price = newPrice;
  }

  function setPresaleAddress(address newPresaleAddress) onlyOwner {
    presale = PreSale(newPresaleAddress);
  }

  function setFoundersTokensPercent(uint newFoundersTokensPercent) onlyOwner {
    foundersTokensPercent = newFoundersTokensPercent;
  }
  
  function setEarlyInvestorsBonus(uint newEarlyInvestorsBonus) onlyOwner {
    earlyInvestorsBonus = newEarlyInvestorsBonus;
  }

  function setBountyTokensPercent(uint newBountyTokensPercent) onlyOwner {
    bountyTokensPercent = newBountyTokensPercent;
  }
  
  function setMultisigWallet(address newMultisigWallet) onlyOwner {
    multisigWallet = newMultisigWallet;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) onlyOwner {
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }

  function createTokens() whenNotPaused isUnderHardCap saleIsOn payable {
    require(msg.value > 0);
    uint milestoneIndex = currentMilestone();
    Milestone storage milestone = milestones[milestoneIndex];
    multisigWallet.transfer(msg.value);
    invested = invested.add(msg.value);
    uint tokens = msg.value.mul(1 ether).div(price);
    uint bonusTokens = tokens.mul(milestone.bonus).div(percentRate);
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.mint(this, tokensWithBonus);
    token.transfer(msg.sender, tokensWithBonus);
  }

  function mintTokensToEralyInvestors() onlyOwner {
    require(!earlyInvestorsMintedTokens);
    for(uint i  = 0; i < presale.totalInvestors(); i++) {
      address investorAddress = presale.investors(i);
      uint invested = presale.balanceOf(investorAddress);
      uint tokens = invested.mul(1 ether).div(price);
      uint bonusTokens = tokens.mul(earlyInvestorsBonus).div(percentRate);
      uint tokensWithBonus = tokens.add(bonusTokens);
      token.mint(this, tokensWithBonus);
      token.transfer(investorAddress, tokensWithBonus);
    }
    earlyInvestorsMintedTokens = true;
  }

  function finishMinting() public whenNotPaused onlyOwner {
    uint issuedTokenSupply = token.totalSupply();
    uint summaryTokensPercent = bountyTokensPercent + foundersTokensPercent;
    uint summaryFoundersTokens = issuedTokenSupply.mul(summaryTokensPercent).div(percentRate - summaryTokensPercent);
    uint totalSupply = summaryFoundersTokens + issuedTokenSupply;
    uint foundersTokens = totalSupply.mul(foundersTokensPercent).div(percentRate);
    uint bountyTokens = totalSupply.mul(bountyTokensPercent).div(percentRate);
    token.mint(this, foundersTokens);
    token.transfer(foundersTokensWallet, foundersTokens);
    token.mint(this, bountyTokens);
    token.transfer(bountyTokensWallet, bountyTokens);
    token.finishMinting();
    token.allowTransfer();
    token.transferOwnership(owner);
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(multisigWallet, token.balanceOf(this));
  }

}