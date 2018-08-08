pragma solidity ^0.4.18;

// File: contracts/ownership/Ownable.sol

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/InvestedProvider.sol

contract InvestedProvider is Ownable {

  uint public invested;

}

// File: contracts/AddressesFilterFeature.sol

contract AddressesFilterFeature is Ownable {

  mapping(address => bool) public allowedAddresses;

  function addAllowedAddress(address allowedAddress) public onlyOwner {
    allowedAddresses[allowedAddress] = true;
  }

  function removeAllowedAddress(address allowedAddress) public onlyOwner {
    allowedAddresses[allowedAddress] = false;
  }

}

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/BasicToken.sol

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
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: contracts/token/ERC20.sol

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

// File: contracts/token/StandardToken.sol

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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/MintableToken.sol

contract MintableToken is AddressesFilterFeature, StandardToken {

  event Mint(address indexed to, uint256 amount);

  event MintFinished();

  bool public mintingFinished = false;

  address public saleAgent;

  mapping (address => uint) public initialBalances;

  modifier notLocked(address _from) {
    require(_from == owner || _from == saleAgent || allowedAddresses[_from] || mintingFinished);
    _;
  }

  function setSaleAgent(address newSaleAgnet) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgnet;
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    initialBalances[_to] = balances[_to];

    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    mintingFinished = true;
    MintFinished();
    return true;
  }

  function transfer(address _to, uint256 _value) public notLocked(msg.sender)  returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked(from) returns (bool) {
    return super.transferFrom(from, to, value);
  }

}

// File: contracts/TokenProvider.sol

contract TokenProvider is Ownable {

  MintableToken public token;

  function setToken(address newToken) public onlyOwner {
    token = MintableToken(newToken);
  }

}

// File: contracts/MintTokensInterface.sol

contract MintTokensInterface is TokenProvider {

  function mintTokens(address to, uint tokens) internal;

}

// File: contracts/MintTokensFeature.sol

contract MintTokensFeature is MintTokensInterface {

  function mintTokens(address to, uint tokens) internal {
    token.mint(to, tokens);
  }

}

// File: contracts/PercentRateProvider.sol

contract PercentRateProvider {

  uint public percentRate = 100;

}

// File: contracts/PercentRateFeature.sol

contract PercentRateFeature is Ownable, PercentRateProvider {

  function setPercentRate(uint newPercentRate) public onlyOwner {
    percentRate = newPercentRate;
  }

}

// File: contracts/RetrieveTokensFeature.sol

contract RetrieveTokensFeature is Ownable {

  function retrieveTokens(address to, address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

}

// File: contracts/WalletProvider.sol

contract WalletProvider is Ownable {

  address public wallet;

  function setWallet(address newWallet) public onlyOwner {
    wallet = newWallet;
  }

}

// File: contracts/CommonSale.sol

contract CommonSale is InvestedProvider, WalletProvider, PercentRateFeature, RetrieveTokensFeature, MintTokensFeature {

  using SafeMath for uint;

  address public directMintAgent;

  uint public price;

  uint public start;

  uint public minInvestedLimit;

  //MintableToken public token;

  uint public hardcap;

  modifier isUnderHardcap() {
    require(invested < hardcap);
    _;
  }

  function setHardcap(uint newHardcap) public onlyOwner {
    hardcap = newHardcap;
  }

  modifier onlyDirectMintAgentOrOwner() {
    require(directMintAgent == msg.sender || owner == msg.sender);
    _;
  }

  modifier minInvestLimited(uint value) {
    require(value >= minInvestedLimit);
    _;
  }

  function setStart(uint newStart) public onlyOwner {
    start = newStart;
  }

  function setMinInvestedLimit(uint newMinInvestedLimit) public onlyOwner {
    minInvestedLimit = newMinInvestedLimit;
  }

  function setDirectMintAgent(address newDirectMintAgent) public onlyOwner {
    directMintAgent = newDirectMintAgent;
  }

  function setPrice(uint newPrice) public onlyOwner {
    price = newPrice;
  }

  /*
  function setToken(address newToken) public onlyOwner {
    token = MintableToken(newToken);
  }
  */

  function calculateTokens(uint _invested) internal returns(uint);

  function mintTokensExternal(address to, uint tokens) public onlyDirectMintAgentOrOwner {
    mintTokens(to, tokens);
  }
/*
  function mintTokens(address to, uint tokens) internal {
    token.mint(this, tokens);
    token.transfer(to, tokens);
  }
*/
  function endSaleDate() public view returns(uint);

  function mintTokensByETHExternal(address to, uint _invested) public onlyDirectMintAgentOrOwner returns(uint) {
    return mintTokensByETH(to, _invested);
  }

  function mintTokensByETH(address to, uint _invested) internal isUnderHardcap returns(uint) {
    invested = invested.add(_invested);
    uint tokens = calculateTokens(_invested);
    mintTokens(to, tokens);
    return tokens;
  }

  function fallback() internal minInvestLimited(msg.value) returns(uint) {
    require(now >= start && now < endSaleDate());
    wallet.transfer(msg.value);
    return mintTokensByETH(msg.sender, msg.value);
  }

  function () public payable {
    fallback();
  }

}

// File: contracts/TimeCountBonusFeature.sol

contract TimeCountBonusFeature is CommonSale {

  struct Milestone {
    uint hardcap;
    uint price;
    uint period;
    uint invested;
    uint closed;
  }

  uint public period;

  Milestone[] public milestones;

  function milestonesCount() public constant returns(uint) {
    return milestones.length;
  }

  function addMilestone(uint _hardcap, uint _price, uint _period) public onlyOwner {
    require(_hardcap > 0 && _price > 0 && _period > 0);
    Milestone memory milestone = Milestone(_hardcap.mul(1 ether), _price, _period, 0, 0);
    milestones.push(milestone);
    hardcap = hardcap.add(milestone.hardcap);
    period = period.add(milestone.period);
  }

  function removeMilestone(uint8 number) public onlyOwner {
    require(number >=0 && number < milestones.length);
    Milestone storage milestone = milestones[number];
    hardcap = hardcap.sub(milestone.hardcap);    
    period = period.sub(milestone.period);    
    delete milestones[number];
    for (uint i = number; i < milestones.length - 1; i++) {
      milestones[i] = milestones[i+1];
    }
    milestones.length--;
  }

  function changeMilestone(uint8 number, uint _hardcap, uint _price, uint _period) public onlyOwner {
    require(number >= 0 &&number < milestones.length);
    Milestone storage milestone = milestones[number];
    hardcap = hardcap.sub(milestone.hardcap);    
    period = period.sub(milestone.period);    
    milestone.hardcap = _hardcap.mul(1 ether);
    milestone.price = _price;
    milestone.period = _period;
    hardcap = hardcap.add(milestone.hardcap);    
    period = period.add(milestone.period);    
  }

  function insertMilestone(uint8 numberAfter, uint _hardcap, uint _price, uint _period) public onlyOwner {
    require(numberAfter < milestones.length);
    Milestone memory milestone = Milestone(_hardcap.mul(1 ether), _price, _period, 0, 0);
    hardcap = hardcap.add(milestone.hardcap);
    period = period.add(milestone.period);
    milestones.length++;
    for (uint i = milestones.length - 2; i > numberAfter; i--) {
      milestones[i + 1] = milestones[i];
    }
    milestones[numberAfter + 1] = milestone;
  }

  function clearMilestones() public onlyOwner {
    for (uint i = 0; i < milestones.length; i++) {
      delete milestones[i];
    }
    milestones.length = 0;
    hardcap = 0;
    period = 0;
  }

  function endSaleDate() public view returns(uint) {
    return start.add(period * 1 days);
  }

  function currentMilestone() public constant returns(uint) {
    uint closeTime = start;
    for(uint i=0; i < milestones.length; i++) {
      closeTime += milestones[i].period.mul(1 days);
      if(milestones[i].closed == 0 && now < closeTime) {
        return i;
      }
    }
    revert();
  }

  function calculateTokens(uint _invested) internal returns(uint) {
    uint milestoneIndex = currentMilestone();
    Milestone storage milestone = milestones[milestoneIndex];
    uint tokens = milestone.price.mul(_invested).div(1 ether);

    // update milestone
    milestone.invested = milestone.invested.add(_invested);
    if(milestone.invested >= milestone.hardcap) {
      milestone.closed = now;
    }

    return tokens;
  }


}

// File: contracts/AssembledCommonSale.sol

contract AssembledCommonSale is TimeCountBonusFeature {

}

// File: contracts/WalletsPercents.sol

contract WalletsPercents is Ownable {

  address[] public wallets;

  mapping (address => uint) percents;

  function addWallet(address wallet, uint percent) public onlyOwner {
    wallets.push(wallet);
    percents[wallet] = percent;
  }
 
  function cleanWallets() public onlyOwner {
    wallets.length = 0;
  }


}

// File: contracts/ExtendedWalletsMintTokensFeature.sol

//import &#39;./PercentRateProvider.sol&#39;;

contract ExtendedWalletsMintTokensFeature is /*PercentRateProvider,*/ MintTokensInterface, WalletsPercents {

  using SafeMath for uint;

  uint public percentRate = 100;

  function mintExtendedTokens() public onlyOwner {
    uint summaryTokensPercent = 0;
    for(uint i = 0; i < wallets.length; i++) {
      summaryTokensPercent = summaryTokensPercent.add(percents[wallets[i]]);
    }
    uint mintedTokens = token.totalSupply();
    uint allTokens = mintedTokens.mul(percentRate).div(percentRate.sub(summaryTokensPercent));
    for(uint k = 0; k < wallets.length; k++) {
      mintTokens(wallets[k], allTokens.mul(percents[wallets[k]]).div(percentRate));
    }

  }

}

// File: contracts/SoftcapFeature.sol

contract SoftcapFeature is InvestedProvider, WalletProvider {

  using SafeMath for uint;

  mapping(address => uint) public balances;

  bool public softcapAchieved;

  bool public refundOn;

  bool public feePayed;

  uint public softcap;

  uint public constant devLimit = 7500000000000000000;

  address public constant devWallet = 0xEA15Adb66DC92a4BbCcC8Bf32fd25E2e86a2A770;

  function setSoftcap(uint newSoftcap) public onlyOwner {
    softcap = newSoftcap;
  }

  function withdraw() public {
    require(msg.sender == owner || msg.sender == devWallet);
    require(softcapAchieved);
    if(!feePayed) {
      devWallet.transfer(devLimit);
      feePayed = true;
    }
    wallet.transfer(this.balance);
  }

  function updateBalance(address to, uint amount) internal {
    balances[to] = balances[to].add(amount);
    if (!softcapAchieved && invested >= softcap) {
      softcapAchieved = true;
    }
  }

  function refund() public {
    require(refundOn && balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
  }

  function updateRefundState() internal returns(bool) {
    if (!softcapAchieved) {
      refundOn = true;
    }
    return refundOn;
  }

}

// File: contracts/TeamWallet.sol

contract TeamWallet is Ownable{
	
  address public token;

  address public crowdsale;

  uint public lockPeriod;

  uint public endLock;

  bool public started;

  modifier onlyCrowdsale() {
    require(crowdsale == msg.sender);
    _;
  }

  function setToken (address _token) public onlyOwner{
  	token = _token;
  }

  function setCrowdsale (address _crowdsale) public onlyOwner{
    crowdsale = _crowdsale;
  }

  function setLockPeriod (uint _lockDays) public onlyOwner{
  	require(!started);
  	lockPeriod = 1 days * _lockDays;
  }

  function start () public onlyCrowdsale{
  	started = true;
  	endLock = now + lockPeriod;
  }

  function withdrawTokens (address _to) public onlyOwner{
  	require(now > endLock);
  	ERC20 ERC20token = ERC20(token);
    ERC20token.transfer(_to, ERC20token.balanceOf(this));  
  }
  
}

// File: contracts/ITO.sol

contract ITO is ExtendedWalletsMintTokensFeature, SoftcapFeature, AssembledCommonSale {

  address public teamWallet;

  bool public paused;

  function setTeamWallet (address _teamWallet) public onlyOwner{
    teamWallet = _teamWallet;
  }

  function mintTokensByETH(address to, uint _invested) internal returns(uint) {
    uint _tokens = super.mintTokensByETH(to, _invested);
    updateBalance(to, _invested);
    return _tokens;
  }

  function finish() public onlyOwner {
    if (updateRefundState()) {
      token.finishMinting();
    } else {
      withdraw();
      mintExtendedTokens();
      token.finishMinting();
      TeamWallet tWallet = TeamWallet(teamWallet);
      tWallet.start();
    }
  }

  function fallback() internal minInvestLimited(msg.value) returns(uint) {
    require(now >= start && now < endSaleDate());
    require(!paused);
    return mintTokensByETH(msg.sender, msg.value);
  }

  function pauseITO() public onlyOwner {
    paused = true;
  }

  function continueITO() public onlyOwner {
    paused = false;
  }

}

// File: contracts/ReceivingContractCallback.sol

contract ReceivingContractCallback {

  function tokenFallback(address _from, uint _value) public;

}

// File: contracts/Token.sol

contract Token is MintableToken {

  string public constant name = "HelixHill";

  string public constant symbol = "HILL";

  uint32 public constant decimals = 18;

  mapping(address => bool)  public registeredCallbacks;

  function transfer(address _to, uint256 _value) public returns (bool) {
    return processCallback(super.transfer(_to, _value), msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    return processCallback(super.transferFrom(_from, _to, _value), _from, _to, _value);
  }

  function registerCallback(address callback) public onlyOwner {
    registeredCallbacks[callback] = true;
  }

  function deregisterCallback(address callback) public onlyOwner {
    registeredCallbacks[callback] = false;
  }

  function processCallback(bool result, address from, address to, uint value) internal returns(bool) {
    if (result && registeredCallbacks[to]) {
      ReceivingContractCallback targetCallback = ReceivingContractCallback(to);
      targetCallback.tokenFallback(from, value);
    }
    return result;
  }

}

// File: contracts/Configurator.sol

contract Configurator is Ownable {

  Token public token;
  ITO public ito;
  TeamWallet public teamWallet;

  function deploy() public onlyOwner {

    address manager = 0xd6561BF111dAfe86A896D6c844F82AE4a5bbc707;

    token = new Token();
    ito = new ITO();
    teamWallet = new TeamWallet();

    token.setSaleAgent(ito);

    ito.setStart(1530622800);
    ito.addMilestone(2000, 5000000000000000000000, 146);
    ito.addMilestone(1000, 2000000000000000000000, 30);
    ito.addMilestone(1000, 1950000000000000000000, 30);
    ito.addMilestone(2000, 1800000000000000000000, 30);
    ito.addMilestone(3000, 1750000000000000000000, 30);
    ito.addMilestone(3500, 1600000000000000000000, 30);
    ito.addMilestone(4000, 1550000000000000000000, 30);
    ito.addMilestone(4500, 1500000000000000000000, 30);
    ito.addMilestone(5000, 1450000000000000000000, 30);
    ito.addMilestone(6000, 1400000000000000000000, 30);
    ito.addMilestone(8000, 1000000000000000000000, 30);
    ito.setSoftcap(2000000000000000000000);
    ito.setMinInvestedLimit(100000000000000000);
    ito.setWallet(0x3047e47EfC33cF8f6F9C3bdD1ACcaEda75B66f2A);
    ito.addWallet(0xe129b76dF45bFE35FE4a3fA52986CC8004538C98, 6);
    ito.addWallet(0x26Db091BF1Bcc2c439A2cA7140D76B4e909C7b4e, 2);
    ito.addWallet(teamWallet, 15);
    ito.addWallet(0x2A3b94CB5b9E10E12f97c72d6B5E09BD5A0E6bF1, 12);
    ito.setPercentRate(100);
    ito.setToken(token);
    ito.setTeamWallet(teamWallet);

    teamWallet.setToken(token);
    teamWallet.setCrowdsale(ito);
    teamWallet.setLockPeriod(180);

    token.transferOwnership(manager);
    ito.transferOwnership(manager);
    teamWallet.transferOwnership(manager);
  }

}