pragma solidity 0.4.18;

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

contract MintableToken is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);

  event MintFinished();

  bool public mintingFinished = false;

  address public saleAgent;

  modifier notLocked() {
    require(msg.sender == owner || msg.sender == saleAgent || mintingFinished);
    _;
  }

  function setSaleAgent(address newSaleAgnet) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgnet;
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require(msg.sender == saleAgent && !mintingFinished);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
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

  function transfer(address _to, uint256 _value) public notLocked returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked returns (bool) {
    return super.transferFrom(from, to, value);
  }

}

// File: contracts/WBBToken.sol

contract WBBToken is MintableToken {

  string public constant name = "WIBCOIN";

  string public constant symbol = "WBB";

  uint32 public constant decimals = 18;

}

// File: contracts/PercentRateProvider.sol

contract PercentRateProvider is Ownable {

  uint public percentRate = 100;

  function setPercentRate(uint newPercentRate) public onlyOwner {
    percentRate = newPercentRate;
  }

}

// File: contracts/CommonSale.sol

contract CommonSale is PercentRateProvider {

  using SafeMath for uint;

  address public wallet;

  address public directMintAgent;

  uint public price;

  uint public start;

  uint public minInvestedLimit;

 WBBToken public token;

  uint public hardcap;

  uint public invested;

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

  function setWallet(address newWallet) public onlyOwner {
    wallet = newWallet;
  }

  function setPrice(uint newPrice) public onlyOwner {
    price = newPrice;
  }

  function setToken(address newToken) public onlyOwner {
    token = WBBToken(newToken);
  }

  function calculateTokens(uint _invested) internal returns(uint);

  function mintTokensExternal(address to, uint tokens) public onlyDirectMintAgentOrOwner {
    mintTokens(to, tokens);
  }

  function mintTokens(address to, uint tokens) internal {
    token.mint(this, tokens);
    token.transfer(to, tokens);
  }

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

// File: contracts/InputAddressFeature.sol

contract InputAddressFeature {

  function bytesToAddress(bytes source) internal pure returns(address) {
    uint result;
    uint mul = 1;
    for(uint i = 20; i > 0; i--) {
      result += uint8(source[i-1])*mul;
      mul = mul*256;
    }
    return address(result);
  }

  function getInputAddress() internal pure returns(address) {
    if(msg.data.length == 20) {
      return bytesToAddress(bytes(msg.data));
    }
    return address(0);
  }

}

// File: contracts/ReferersRewardFeature.sol

contract ReferersRewardFeature is InputAddressFeature, CommonSale {

  uint public refererPercent;

  uint public referalsMinInvestLimit;

  function setReferalsMinInvestLimit(uint newRefereralsMinInvestLimit) public onlyOwner {
    referalsMinInvestLimit = newRefereralsMinInvestLimit;
  }

  function setRefererPercent(uint newRefererPercent) public onlyOwner {
    refererPercent = newRefererPercent;
  }

  function fallback() internal returns(uint) {
    uint tokens = super.fallback();
    if(msg.value >= referalsMinInvestLimit) {
      address referer = getInputAddress();
      if(referer != address(0)) {
        require(referer != address(token) && referer != msg.sender && referer != address(this));
        mintTokens(referer, tokens.mul(refererPercent).div(percentRate));
      }
    }
    return tokens;
  }

}

// File: contracts/RetrieveTokensFeature.sol

contract RetrieveTokensFeature is Ownable {

  function retrieveTokens(address to, address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

}

// File: contracts/ValueBonusFeature.sol

contract ValueBonusFeature is PercentRateProvider {

  using SafeMath for uint;

  struct ValueBonus {
    uint from;
    uint bonus;
  }

  ValueBonus[] public valueBonuses;

  function addValueBonus(uint from, uint bonus) public onlyOwner {
    valueBonuses.push(ValueBonus(from, bonus));
  }

  function getValueBonusTokens(uint tokens, uint _invested) public view returns(uint) {
    uint valueBonus = getValueBonus(_invested);
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

// File: contracts/WBB.sol

contract WBBCommonSale is ValueBonusFeature, RetrieveTokensFeature, ReferersRewardFeature {


}

// File: contracts/StagedCrowdsale.sol

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

// File: contracts/Mainsale.sol

contract Mainsale is StagedCrowdsale, WBBCommonSale {

  address public foundersTokensWallet;

  address public marketingTokensWallet;

  address public bountyTokensWallet;

  uint public foundersTokensPercent;

  uint public marketingTokensPercent;

  uint public bountyTokensPercent;

  function setFoundersTokensPercent(uint newFoundersTokensPercent) public onlyOwner {
    foundersTokensPercent = newFoundersTokensPercent;
  }

  function setMarketingTokensPercent(uint newMarketingTokensPercent) public onlyOwner {
    marketingTokensPercent = newMarketingTokensPercent;
  }

  function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner {
    bountyTokensPercent = newBountyTokensPercent;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) public onlyOwner {
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function setMarketingTokensWallet(address newMarketingTokensWallet) public onlyOwner {
    marketingTokensWallet = newMarketingTokensWallet;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }

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

  function finish() public onlyOwner {
    uint summaryTokensPercent = bountyTokensPercent.add(foundersTokensPercent).add(marketingTokensPercent);
    uint mintedTokens = token.totalSupply();
    uint allTokens = mintedTokens.mul(percentRate).div(percentRate.sub(summaryTokensPercent));
    uint foundersTokens = allTokens.mul(foundersTokensPercent).div(percentRate);
    uint marketingTokens = allTokens.mul(marketingTokensPercent).div(percentRate);
    uint bountyTokens = allTokens.mul(bountyTokensPercent).div(percentRate);
    mintTokens(foundersTokensWallet, foundersTokens);
    mintTokens(marketingTokensWallet, marketingTokens);
    mintTokens(bountyTokensWallet, bountyTokens);
    token.finishMinting();
  }

  function endSaleDate() public view returns(uint) {
    return lastSaleDate(start);
  }

}

// File: contracts/Presale.sol

contract Presale is WBBCommonSale {

  Mainsale public mainsale;

  uint public period;

  function calculateTokens(uint _invested) internal returns(uint) {
    uint tokens = _invested.mul(price).div(1 ether);
    return tokens.add(getValueBonusTokens(tokens, _invested));
  }

  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

  function setMainsale(address newMainsale) public onlyOwner {
    mainsale = Mainsale(newMainsale);
  }

  function finish() public onlyOwner {
    token.setSaleAgent(mainsale);
  }

  function endSaleDate() public view returns(uint) {
    return start.add(period * 1 days);
  }

}

// File: contracts/Configurator.sol

contract Configurator is Ownable {

  WBBToken public token;

  Presale public presale;

  Mainsale public mainsale;

  function deploy() public onlyOwner {
    //owner = 0x41FEa3861abCd7c769feAe7E84c03E3C84A68174;

    token = new WBBToken();

    presale = new Presale();

    presale.setWallet(0x619B63f9b9aC6570AB86bc4fB232Ac04Bc47618E);
    presale.setStart(1524441600);
    presale.setPeriod(65);
    presale.setPrice(370000000000000000000);
    presale.setHardcap(42000000000000000000000);
    token.setSaleAgent(presale);
    commonConfigure(presale, token);

    mainsale = new Mainsale();

    mainsale.addMilestone(7, 20);
    mainsale.addMilestone(7, 15);
    mainsale.addMilestone(7, 10);
    mainsale.addMilestone(100, 0);
    mainsale.setPrice(370000000000000000000);
    mainsale.setWallet(0x619B63f9b9aC6570AB86bc4fB232Ac04Bc47618E);
    mainsale.setFoundersTokensWallet(0x9C93e79E17Fb9B187E5Edf264c571081289E4814);
    mainsale.setMarketingTokensWallet(0x47497893408D3a0f6F3cDb70EdfbdaB18b8e9EC7);
    mainsale.setBountyTokensWallet(0x535cc5A392D805e707086da7EAfF5C1bD2Ec3Ed9);
    mainsale.setStart(1535760000);
    mainsale.setHardcap(830000000000000000000000);
    mainsale.setFoundersTokensPercent(15);
    mainsale.setMarketingTokensPercent(10);
    mainsale.setBountyTokensPercent(5);
    commonConfigure(mainsale, token);

    presale.setMainsale(mainsale);

    token.transferOwnership(owner);
    presale.transferOwnership(owner);
    mainsale.transferOwnership(owner);
  }

  function commonConfigure(address saleAddress, address _token) internal {
     WBBCommonSale sale = WBBCommonSale(saleAddress);
     sale.addValueBonus(800000000000000000, 10);
     sale.addValueBonus(4000000000000000000, 15);
     sale.addValueBonus(8000000000000000000, 20);
     sale.addValueBonus(40000000000000000000, 25);
     sale.setReferalsMinInvestLimit(1000000000000000000);
     sale.setRefererPercent(5);
     sale.setMinInvestedLimit(100000000000000000);
     sale.setToken(_token);
  }

}