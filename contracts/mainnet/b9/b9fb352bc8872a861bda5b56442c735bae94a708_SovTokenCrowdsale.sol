/*
NOBLE NATION SOVEREIGN TOKEN - ISSUANCE POLICIES & TERMS OF SERVICE
Background

Noble Nation is a global social, economic and political movement based around a revolutionary new crypto-block-chain technology and platform called Chakra. This platform is a cohesive and self sustaining society, economy and a governance framework bound by universal moral principles. Our technology and principles have the potential to bring about enormous positive change in our world and correct many of its existing flaws.

Purpose of this Initial Coin Offering

The funds raised from this ICO is to be utilized for the furtherance of the goals and objectives of our movement as detailed in our program white paper. SVT Tokens are granted to you purely as a reward for contributing to our cause and also to encourage you to be an active participant in the Noble Society, Economy and Government. 

What Sovereign Tokens (SVT) and Sovereigns (SOV) ARE and ARE NOT

Ownership of Sovereign tokens or the Sovereign currency implies that the holder is a member of the Noble Nation’s society and has all rights and privileges to operate within the Noble Nation platform in accordance with the constitution of the Noble Nation, including:
1. Participation in the noble society and the merit framework;
2. Participation and trade in the noble economy;
3. Participation in the direct democracy;
4. Participation in all other frameworks of Noble Nation as may be applicable.

The acquisition of Sovereign tokens or currency and/or the participation in any of the above activities implies that the individual has pledged to abide and uphold the principles and the constitution of Noble Nation.

Ownership of Sovereign tokens or the Sovereign currency DOES NOT in any way grant the holder any:
1. Ownership interest in any legal entity;
2. Equity interest;
3. Share of profits and/or losses, or assets and/or liabilities;
4. Status as a creditor or lender;
5. Claim in bankruptcy as equity interest holder or creditor;
6. Repayment/refund obligation from the system or the legal entity issuer.

The Inherent Risks of the Noble Nation Project

While the founding members have committed their lives to the cause of Noble Nation and they will endeavor to the best of their human ability to fulfill this vision, it is not possible to make any guarantee as to the final outcome of our vision and goals.

We do not make any guarantees or representations as to the Token’s/Sovereign’s tradeability, reliability or fitness for a financial transaction – these are all dependent on market conditions within and outside the Noble Nation and the technical maturity of the platform.

In summary, your primary motivation for participating in this ICO should be to support the vision and mission of Noble Nation and to participate in the Noble Economy, Society and Government.

Nationals from all Countries are Welcome to Participate in the Noble Nation ICO

However, you should not participate in this ICO if you live in a country where basic political and economic expression is suppressed and the acquisition of these tokens may violate any laws or regulations you are subject to.

We do not screen participants by nationality as we cannot practically be expected to keep track of regulations in over 200 national jurisdictions across the the world.

Noble Nation Network is engaged in Social, Political and Economic action in conformance with the political and economic rights guaranteed by the universal declaration of human rights while adhering to very high standards of ethics, morality and natural justice. But you are responsible for making sure that you are in conformance with applicable laws in your jurisdiction.

Converting Sovereign Tokens (SVT) to Sovereigns in the Noble Economy

When the beta Noble Nation platform is functional, SVT token holders will be provided instructions on creating an Identity in the Noble Nation, and how to convert SVT tokens into Sovereigns. All trade within the Noble Nation platform will utilize the currency of the Noble Economy, the Sovereign.

To create an identity on the Noble Nation platform, the token holder must agree to honor and uphold the principles of Noble Nation. Each human individual may hold only a single Identity in the Noble Nation. At this stage, they will be required to provide identity details conforming to generally accepted KYC/AML requirements. Unlike other platforms though these details will be cryptographically protected by the privacy framework backed by the 3rd root law of the Noble Nation. 

By contributing to this ICO, all participants confirm that:

1. You are 18 years or above at the date of contribution.
2. You are not under any restrictions to use the website and participate in this ICO.
3. You have never been engaged in any illegal activity including but not limited to money laundering, financing of terrorism or any other activity deemed illegal by applicable law.
4. You further confirm that you will not be using this website, SVT Tokens or any other system or aspect of Noble Nation for any illegal activity whatsoever.
5. You are the absolute owner of the ethereum address and/or the crypto currency wallet used to contribute to this ICO and have full control over the same.
6. The address provided is a ERC-20 wallet (not an “exchange” wallet).

Apart from the above, all participants are bound by the general Terms of Service (https://www.noblenation.net/tos) & Privacy Policy (https://www.noblenation.net/privacy-policy) of the Noble Nation Network.
*/

/* This file is a flattened version of OpenZeppelin (https://github.com/OpenZeppelin) 
 * SafeMath.sol so as to fix the code base and simplify compilation in Remix etc..
 * with no external dependencies.
 */
 
 pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/* This file is a flattened version of OpenZeppelin (https://github.com/OpenZeppelin) 
 * Ownable.sol so as to fix the code base and simplify compilation in Remix etc..
 * with no external dependencies. 
 */
 
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

/* This file is a flattened version of OpenZeppelin (https://github.com/OpenZeppelin) 
 * MintableToken.sol so as to fix the code base and simplify compilation in Remix etc..
 * with no external dependencies. 
 */

/****************************************************************************************
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

/***************************************************************************************
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/***************************************************************************************
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

/***************************************************************************************
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

/***************************************************************************************
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
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract SovToken is MintableToken {
  string public name = "Noble Nation Sovereign Token";
  string public symbol = "SVT";
  uint256 public decimals = 18;

  uint256 private constant _tradeableDate = 1529776800; // 2018 23rd June 18:00h
  
  //please update the following addresses before deployment
  address private constant CONVERT_ADDRESS = 0x9376B2Ff3E68Be533bAD507D99aaDAe7180A8175; 
  address private constant POOL = 0xE06be458ad8E80d8b8f198579E0Aa0Ce5f571294;
  
  event Burn(address indexed burner, uint256 value);

  function transfer(address _to, uint256 _value) public returns (bool) 
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    // reject transaction if the transfer is before tradeable date and
    // the transfer is not from or to the pool
    require(now > _tradeableDate || _to == POOL || msg.sender == POOL);
    
    // if the transfer address is the conversion address - burn the tokens
    if (_to == CONVERT_ADDRESS)
    {   
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    else
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
  }
}

/* This file is a flattened version of OpenZeppelin (https://github.com/OpenZeppelin) 
 * Crowdsale.sol so as to fix the code base and simplify compilation in Remix etc..
 * with no external dependencies. 
 */

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, MintableToken _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
}

contract SovTokenCrowdsale is Crowdsale {
  uint private constant TIME_UNIT = 86400;    // in seconds - set at 60 (1 min) for testing and change to 86400 (1 day) for release
  uint private constant TOTAL_TIME = 84;
  uint private constant RATE = 10000;
  uint256 private constant START_TIME = 1522519200; // 2018 March 31 18:00h
  uint256 private constant HARD_CAP = 100000*1000000000000000000;    // in wei - 100K Eth
  
  //please update the following addresses before deployment
  address private constant WALLET = 0x04Fb0BbC4f95F5681138502094f8FD570AA2CB9F;
  address private constant POOL = 0xE06be458ad8E80d8b8f198579E0Aa0Ce5f571294;

  function SovTokenCrowdsale() public
        Crowdsale(START_TIME, START_TIME + (TIME_UNIT * TOTAL_TIME), RATE, WALLET, SovToken(0x5Ab08341AcDb5d79b21b5D2fb021ac9545b705B4))
  {    }
  
  // low level token purchase function
  function buyTokens(address beneficiary) public payable 
  {
    require(beneficiary != address(0));
    require(validPurchase());
    
    uint256 weiAmount = msg.value;

    // validate if hardcap reached
    require(weiRaised.add(weiAmount) < HARD_CAP);

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    // for every token given away, half a token is minted to the treasury pool
    token.mint(POOL, tokens/2);

    forwardFunds();
  }

  // Overriden to calculate bonuses
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) 
  {
    uint256 tokens =  weiAmount.mul(rate);
    uint256 bonus = 100;

    // determine bonus according to pre-sale period age
    if (now >= endTime)
      bonus = 0;
    else if (now <= startTime + (7 * TIME_UNIT))
      bonus += 35;
    else if (now <= startTime + (14 * TIME_UNIT))
      bonus += 30;
    else if (now <= startTime + (21 * TIME_UNIT))
      bonus += 25;
    else if (now <= startTime + (28 * TIME_UNIT))
      bonus += 20;
    else if (now <= startTime + (35 * TIME_UNIT))
      bonus += 15;
    else if (now <= startTime + (42 * TIME_UNIT))
      bonus += 10;
    else if (now <= startTime + (49 * TIME_UNIT))
      bonus += 5;
    else
      bonus = 100;

    tokens = tokens * bonus / 100;

    bonus = 100;
    
    //determine applicable amount bonus
    // 1 - 10 ETH 10%, >10 ETH 20%
    if (weiAmount >= 1000000000000000000 && weiAmount < 10000000000000000000)
      bonus += 10;
    else if (weiAmount >= 10000000000000000000)
      bonus += 20;

    tokens = tokens * bonus / 100;
      
    return tokens;
  }  
}