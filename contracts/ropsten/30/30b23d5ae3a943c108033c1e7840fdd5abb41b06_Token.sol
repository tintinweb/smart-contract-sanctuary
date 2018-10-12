pragma solidity ^0.4.18;


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

contract AddressesFilterFeature is Ownable {

  mapping(address => bool) public allowedAddresses;

  function addAllowedAddress(address allowedAddress) public onlyOwner {
    allowedAddresses[allowedAddress] = true;
  }

  function removeAllowedAddress(address allowedAddress) public onlyOwner {
    allowedAddresses[allowedAddress] = false;
  }

}

contract ValueBonusFeature is Ownable {

  using SafeMath for uint;

  uint percentRate = 1000;

  struct ValueBonus {
    uint from;
    uint bonus;
  }

  ValueBonus[] public valueBonuses;

  function addValueBonus(uint from, uint bonus) public onlyOwner {
    valueBonuses.push(ValueBonus(from, bonus));
  }

  function getValueBonusTokens(uint tokens, uint invested) public view returns(uint) {
    uint valueBonus = getValueBonus(invested);
    if(valueBonus == 0) {
      return 0;
    }
    return tokens.mul(valueBonus).div(percentRate);
  }

  function getValueBonus(uint value) public view returns(uint) {
    uint bonus = 0;
    for(uint i = 0; i < valueBonuses.length; i++) {
      if(value >= valueBonuses[i].from) {
        bonus = valueBonuses[i].bonus;
      } else {
        return bonus;
      }
    }
    return bonus;
  }

}

contract WalletProvider is Ownable {

  address public wallet;

  function setWallet(address newWallet) public onlyOwner {
    wallet = newWallet;
  }

}

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

contract PercentRateProvider {

  uint public percentRate = 100;

}




contract PercentRateFeature is Ownable, PercentRateProvider {

  function setPercentRate(uint newPercentRate) public onlyOwner {
    percentRate = newPercentRate;
  }

}


contract InvestedProvider is Ownable {

  uint public invested;

}

contract ReceivingContractCallback {

  function tokenFallback(address _from, uint _value) public;

}

contract RetrieveTokensFeature is Ownable {

  function retrieveTokens(address to, address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

}

contract StagedCrowdsale is Ownable {

  using SafeMath for uint;

  struct Milestone {
    uint period;
    uint bonus;
  }

  uint public totalPeriod;

  Milestone[] public milestones;

  function milestonesCount() public view returns(uint) {
    return milestones.length;
  }

  function addMilestone(uint period, uint bonus) public onlyOwner {
    require(period > 0);
    milestones.push(Milestone(period, bonus));
    totalPeriod = totalPeriod.add(period);
  }

  function removeMilestone(uint8 number) public onlyOwner {
    require(number < milestones.length);
    Milestone storage milestone = milestones[number];
    totalPeriod = totalPeriod.sub(milestone.period);

    delete milestones[number];

    for (uint i = number; i < milestones.length - 1; i++) {
      milestones[i] = milestones[i+1];
    }

    milestones.length--;
  }

  function changeMilestone(uint8 number, uint period, uint bonus) public onlyOwner {
    require(number < milestones.length);
    Milestone storage milestone = milestones[number];

    totalPeriod = totalPeriod.sub(milestone.period);

    milestone.period = period;
    milestone.bonus = bonus;

    totalPeriod = totalPeriod.add(period);
  }

  function insertMilestone(uint8 numberAfter, uint period, uint bonus) public onlyOwner {
    require(numberAfter < milestones.length);

    totalPeriod = totalPeriod.add(period);

    milestones.length++;

    for (uint i = milestones.length - 2; i > numberAfter; i--) {
      milestones[i + 1] = milestones[i];
    }

    milestones[numberAfter + 1] = Milestone(period, bonus);
  }

  function clearMilestones() public onlyOwner {
    require(milestones.length > 0);
    for (uint i = 0; i < milestones.length; i++) {
      delete milestones[i];
    }
    milestones.length -= milestones.length;
    totalPeriod = 0;
  }

  function lastSaleDate(uint start) public view returns(uint) {
    return start + totalPeriod * 1 days;
  }

  function currentMilestone(uint start) public view returns(uint) {
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


contract TokenProvider is Ownable {

  MintableToken public token;

  function setToken(address newToken) public onlyOwner {
    token = MintableToken(newToken);
  }

}

contract MintableToken is AddressesFilterFeature, StandardToken {

  event Mint(address indexed to, uint256 amount);

  event MintFinished();

  bool public mintingFinished = false;

  address public saleAgent;

  mapping (address => uint) public initialBalances;

  uint public vestingPercent;

  uint public constant percentRate = 100;

  modifier notLocked(address _from, uint _value) {
    if(!(_from == owner || _from == saleAgent || allowedAddresses[_from])) {
      require(mintingFinished);
      if((vestingPercent <= percentRate) && (vestingPercent != 0)) {
        uint minLockedBalance = initialBalances[_from].mul(vestingPercent).div(percentRate);
        require(minLockedBalance <= balances[_from].sub(_value));
      }
    }
    _;
  }

  function setVestingPercent(uint newVestingPercent) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    vestingPercent = newVestingPercent;
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

  function transfer(address _to, uint256 _value) public notLocked(msg.sender, _value)  returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked(from, value) returns (bool) {
    return super.transferFrom(from, to, value);
  }

}

contract Token is MintableToken {

  string public constant name = "Worldopoly";

  string public constant symbol = "WPT";

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

contract MintTokensInterface is TokenProvider {

  function mintTokens(address to, uint tokens) internal;

}

contract MintTokensFeature is MintTokensInterface {

  function mintTokens(address to, uint tokens) internal {
    token.mint(to, tokens);
  }

}

contract CommonSale is PercentRateFeature, InvestedProvider, WalletProvider, RetrieveTokensFeature, MintTokensFeature {

  using SafeMath for uint;

  address public directMintAgent;

  uint public price;

  uint public start;

  uint public minInvestedLimit;

  uint public hardcap;

  modifier isUnderHardcap() {
    require(invested <= hardcap);
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

  function setPrice(uint newPrice) public onlyDirectMintAgentOrOwner {
    price = newPrice;
  }

  function calculateTokens(uint _invested) internal returns(uint);

  function mintTokensExternal(address to, uint tokens) public onlyDirectMintAgentOrOwner {
    mintTokens(to, tokens);
  }

  function endSaleDate() public view returns(uint);

  function mintTokensByETHExternal(address to, uint _invested) public onlyDirectMintAgentOrOwner returns(uint) {
    updateInvested(_invested);
    return mintTokensByETH(to, _invested);
  }

  function mintTokensByETH(address to, uint _invested) internal isUnderHardcap returns(uint) {
    uint tokens = calculateTokens(_invested);
    mintTokens(to, tokens);
    return tokens;
  }

  function transferToWallet(uint value) internal {
    wallet.transfer(value);
  }

  function updateInvested(uint value) internal {
    invested = invested.add(value);
  }

  function fallback() internal minInvestLimited(msg.value) returns(uint) {
    require(now >= start && now < endSaleDate());
    transferToWallet(msg.value);
    updateInvested(msg.value);
    return mintTokensByETH(msg.sender, msg.value);
  }

  function () public payable {
    fallback();
  }

}

contract AssembledCommonSale is ValueBonusFeature, CommonSale {

}



contract DevFeeFeature is CommonSale {

  using SafeMath for uint;

  uint public constant devLimit = 19500000000000000000;

  uint public devBalance;

  address public constant devWallet = 0xEA15Adb66DC92a4BbCcC8Bf32fd25E2e86a2A770;

  function transferToWallet(uint value) internal {
    uint toDev = devLimit - devBalance;
    if(toDev > 0) {
      if(toDev > value) {
        toDev = value;
      } else { 
        wallet.transfer(value.sub(toDev));
      }
      devWallet.transfer(toDev);
      devBalance = devBalance.add(toDev);
    } else {
      wallet.transfer(value);
    }
  }

}

contract ERC20Cutted {
    
  function balanceOf(address who) public constant returns (uint256);
  
  function transfer(address to, uint256 value) public returns (bool);
  
}

contract ExtendedWalletsMintTokensFeature is MintTokensInterface, WalletsPercents {

  using SafeMath for uint;

  uint public percentRate = 1000;

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

contract ByteBallWallet is Ownable {
    
    address public target = 0x7E5f0D4070a55EbCf0a8A7D6F7abCEf96312C129;
    
    uint public locked;
    
    address public token;
    
    function setToken(address _token) public onlyOwner {
        token = _token;
    }
    
    function setLocked(uint _locked) public onlyOwner {
        locked = _locked;
    }
    
    function setTarget(address _target) public onlyOwner {
        target = _target;
    }
    
    function retreiveTokens() public {
        require(now > locked);
        ERC20Basic(token).transfer(target, ERC20Basic(token).balanceOf(this));
    }
    
}

contract ITO is ExtendedWalletsMintTokensFeature, AssembledCommonSale {

  uint public period;

  uint public firstBonusPercent;

  uint public firstBonusLimitPercent;
  
  ByteBallWallet public bbwallet = new ByteBallWallet();

  function setFirstBonusPercent(uint newFirstBonusPercent) public onlyOwner {
    firstBonusPercent = newFirstBonusPercent;
  }

  function setFirstBonusLimitPercent(uint newFirstBonusLimitPercent) public onlyOwner {
    firstBonusLimitPercent = newFirstBonusLimitPercent;
  }

  function calculateTokens(uint _invested) internal returns(uint) {
    uint tokens = _invested.mul(price).div(1 ether);
    uint valueBonusTokens = getValueBonusTokens(tokens, _invested);
    if(invested < hardcap.mul(firstBonusLimitPercent).div(percentRate)) {
      tokens = tokens.add(tokens.mul(firstBonusPercent).div(percentRate));
    }
    return tokens.add(valueBonusTokens);
  }

  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

  function endSaleDate() public view returns(uint) {
    return start.add(period * 1 days);
  }

  function finish() public onlyOwner {
     mintExtendedTokens();
     bbwallet.setToken(token);
     mintTokens(address(bbwallet),5000000000000000000000000);
     bbwallet.transferOwnership(owner);
     token.finishMinting();
  }

}


contract NextSaleAgentFeature is Ownable {

  address public nextSaleAgent;

  function setNextSaleAgent(address newNextSaleAgent) public onlyOwner {
    nextSaleAgent = newNextSaleAgent;
  }

}


contract PreITO is DevFeeFeature, NextSaleAgentFeature, StagedCrowdsale, AssembledCommonSale {

  function calculateTokens(uint _invested) internal returns(uint) {
    uint milestoneIndex = currentMilestone(start);
    Milestone storage milestone = milestones[milestoneIndex];
    uint tokens = _invested.mul(price).div(1 ether);
    uint valueBonusTokens = getValueBonusTokens(tokens, _invested);
    if(milestone.bonus > 0) {
      tokens = tokens.add(tokens.mul(milestone.bonus).div(percentRate));
    }
    return tokens.add(valueBonusTokens);
  }

  function endSaleDate() public view returns(uint) {
    return lastSaleDate(start);
  }

  function finish() public onlyOwner {
    token.setSaleAgent(nextSaleAgent);
  }

}


contract Configurator is Ownable {

  Token public token;

  PreITO public preITO;

  ITO public ito;

  function deploy() public onlyOwner {

    address manager = 0xB8A4799a4E2f10e4b30b6C6E9F762833C13eCDF4;

    token = new Token();

    preITO = new PreITO();
    ito = new ITO();

    commonConfigure(preITO);
    commonConfigure(ito);

    preITO.setWallet(0x28D1e6eeBf60b5eb747E2Ee7a185472Ae073Ab7e);
    preITO.setStart(1524441600);
    preITO.addMilestone(10, 200);
    preITO.addMilestone(10, 150);
    preITO.addMilestone(10, 100);
    preITO.setHardcap(6282000000000000000000);

    token.setSaleAgent(preITO);
    token.setVestingPercent(0);

    ito.setWallet(0x029fa7ef4E852Bb53CcbafA2308eE728320A5B8d);
    ito.setStart(1527206400);
    ito.setPeriod(44);
    ito.setFirstBonusPercent(50);
    ito.setFirstBonusLimitPercent(200);
    ito.setHardcap(37697000000000000000000);

    ito.addWallet(0xd4Dde5011e330f8bFB246ce60d163AA5900ba71E, 150);
    ito.addWallet(0x752A9D3d59b8DFbd0798C70c59CAf4A95b5D896e, 50);
    ito.addWallet(0xae3182c9B850843773714dC5384A38116F6ec135, 50);

    preITO.setNextSaleAgent(ito);

    token.transferOwnership(manager);
    preITO.transferOwnership(manager);
    ito.transferOwnership(manager);
  }

  function commonConfigure(AssembledCommonSale sale) internal {
    sale.setPercentRate(1000);
    sale.setMinInvestedLimit(20000000000000000);
    sale.setPrice(3184000000000000000000);
    sale.addValueBonus(3000000000000000000, 10);
    sale.addValueBonus(6000000000000000000, 15);
    sale.addValueBonus(9000000000000000000, 20);
    sale.addValueBonus(12000000000000000000, 25);
    sale.addValueBonus(15000000000000000000, 30);
    sale.addValueBonus(21000000000000000000, 40);
    sale.addValueBonus(30000000000000000000, 50);
    sale.addValueBonus(48000000000000000000, 60);
    sale.addValueBonus(75000000000000000000, 70);
    sale.addValueBonus(120000000000000000000, 80);
    sale.addValueBonus(150000000000000000000, 90);
    sale.addValueBonus(225000000000000000000, 100);
    sale.addValueBonus(300000000000000000000, 110);
    sale.addValueBonus(450000000000000000000, 120);
    sale.addValueBonus(600000000000000000000, 130);
    sale.addValueBonus(900000000000000000000, 150);
    sale.setToken(token);
  }

}