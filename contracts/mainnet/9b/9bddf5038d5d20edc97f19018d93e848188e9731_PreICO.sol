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
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    
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

// File: contracts/PercentRateProvider.sol

contract PercentRateProvider is Ownable {

  uint public percentRate = 100;

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

contract CommonSale is InvestedProvider, WalletProvider, PercentRateProvider, RetrieveTokensFeature {

  using SafeMath for uint;

  address public directMintAgent;

  uint public price;

  uint public start;

  uint public minInvestedLimit;

  MintableToken public token;

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

  function setToken(address newToken) public onlyOwner {
    token = MintableToken(newToken);
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

// File: contracts/NextSaleAgentFeature.sol

contract NextSaleAgentFeature is Ownable {

  address public nextSaleAgent;

  function setNextSaleAgent(address newNextSaleAgent) public onlyOwner {
    nextSaleAgent = newNextSaleAgent;
  }

}

// File: contracts/ValueBonusFeature.sol

contract ValueBonusFeature is PercentRateProvider {

  using SafeMath for uint;

  bool public activeValueBonus = true;

  struct ValueBonus {
    uint from;
    uint bonus;
  }

  ValueBonus[] public valueBonuses;

  modifier checkPrevBonus(uint number, uint from, uint bonus) {
    if(number > 0 && number < valueBonuses.length) {
      ValueBonus storage valueBonus = valueBonuses[number - 1];
      require(valueBonus.from < from && valueBonus.bonus < bonus);
    }
    _;
  }

  modifier checkNextBonus(uint number, uint from, uint bonus) {
    if(number + 1 < valueBonuses.length) {
      ValueBonus storage valueBonus = valueBonuses[number + 1];
      require(valueBonus.from > from && valueBonus.bonus > bonus);
    }
    _;
  }

  function setActiveValueBonus(bool newActiveValueBonus) public onlyOwner {
    activeValueBonus = newActiveValueBonus;
  }

  function addValueBonus(uint from, uint bonus) public onlyOwner checkPrevBonus(valueBonuses.length - 1, from, bonus) {
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
    if(activeValueBonus) {
      for(uint i = 0; i < valueBonuses.length; i++) {
        if(value >= valueBonuses[i].from) {
          bonus = valueBonuses[i].bonus;
        } else {
          return bonus;
        }
      }
    }
    return bonus;
  }

  function removeValueBonus(uint8 number) public onlyOwner {
    require(number < valueBonuses.length);

    delete valueBonuses[number];

    for (uint i = number; i < valueBonuses.length - 1; i++) {
      valueBonuses[i] = valueBonuses[i+1];
    }

    valueBonuses.length--;
  }

  function changeValueBonus(uint8 number, uint from, uint bonus) public onlyOwner checkPrevBonus(number, from, bonus) checkNextBonus(number, from, bonus) {
    require(number < valueBonuses.length);
    ValueBonus storage valueBonus = valueBonuses[number];
    valueBonus.from = from;
    valueBonus.bonus = bonus;
  }

  function insertValueBonus(uint8 numberAfter, uint from, uint bonus) public onlyOwner checkPrevBonus(numberAfter, from, bonus) checkNextBonus(numberAfter, from, bonus) {
    require(numberAfter < valueBonuses.length);

    valueBonuses.length++;

    for (uint i = valueBonuses.length - 2; i > numberAfter; i--) {
      valueBonuses[i + 1] = valueBonuses[i];
    }

    valueBonuses[numberAfter + 1] = ValueBonus(from, bonus);
  }

  function clearValueBonuses() public onlyOwner {
    require(valueBonuses.length > 0);
    for (uint i = 0; i < valueBonuses.length; i++) {
      delete valueBonuses[i];
    }
    valueBonuses.length = 0;
  }

}

// File: contracts/PreICO.sol

contract PreICO is ValueBonusFeature, NextSaleAgentFeature, CommonSale {

  uint public period;

  function calculateTokens(uint _invested) internal returns(uint) {
    uint tokens = _invested.mul(price).div(1 ether);
    uint valueBonusTokens = getValueBonusTokens(tokens, _invested);
    return tokens.add(valueBonusTokens);
  }

  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

  function finish() public onlyOwner {
    token.setSaleAgent(nextSaleAgent);
  }

  function endSaleDate() public view returns(uint) {
    return start.add(period * 1 days);
  }
  
  function fallback() internal minInvestLimited(msg.value) returns(uint) {
    require(now >= start && now < endSaleDate());
    wallet.transfer(msg.value);
    return mintTokensByETH(msg.sender, msg.value);
  }
  
}