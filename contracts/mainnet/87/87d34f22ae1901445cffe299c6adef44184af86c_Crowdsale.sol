pragma solidity ^0.4.23;
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
contract BasicToken is ERC20Basic, Ownable {
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {
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


contract LTE is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "LTE";
  string public constant symbol = "LTE";
  uint32 public constant decimals = 18;
  address public addressBounty;
  address public addressAirdrop;
  address public addressTeam;
  address public addressAdvisors;
  address public addressDividendReserve;
  address public addressPrivateSale;
  uint256 public summBounty;
  uint256 public summAirdrop;
  uint256 public summTeam;
  uint256 public summAdvisors;
  uint256 public summDividendReserve;
  uint256 public summPrivateSale;

  function LTE() public {
    addressBounty = 0xe70D1a8D548aFCdB4B5D162DaF8668E1E97796FB; 
    addressAirdrop = 0x024d96Ad09a076A88F0EA716B38EdB36B8A636DD;
    addressTeam = 0xCe1932A41aaC4D8d838a41f2D10E4b154f719Eb1; 
    addressAdvisors = 0x9f3D002255B96F39F96961F40FdD2a1C3d40B919; 
    addressDividendReserve = 0xB647e8157270cCc5dB202FFa7C5CC80992645Ec7; 
    addressPrivateSale = 0x953b3f258f441BC49d0a6f21f41E86E5ab9e6715; 

    // Token distribution
    summBounty = 779600 * (10 ** uint256(decimals));
    summAirdrop = 779600 * (10 ** uint256(decimals));
    summTeam = 9745000 * (10 ** uint256(decimals));
    summAdvisors = 1949000 * (10 ** uint256(decimals));
    summDividendReserve = 12160400 * (10 ** uint256(decimals));
    summPrivateSale = 8000000 * (10 ** uint256(decimals));

    // Founders and supporters initial Allocations
    mint(addressBounty, summBounty);
    mint(addressAirdrop, summAirdrop);
    mint(addressTeam, summTeam);
    mint(addressAdvisors, summAdvisors);
    mint(addressDividendReserve, summDividendReserve);
    mint(addressPrivateSale, summPrivateSale);
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where Contributors can make
 * token Contributions and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  LTE public token;
  
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public   startPreICOStage1;
  uint256 public   endPreICOStage1;
  uint256 public   startPreICOStage2;
  uint256 public   endPreICOStage2;  
  uint256 public   startPreICOStage3;
  uint256 public   endPreICOStage3;   
  uint256 public   startICOStage1;
  uint256 public   endICOStage1;
  uint256 public   startICOStage2;
  uint256 public   endICOStage2; 
  
  //token distribution
  // uint256 public maxIco;
  uint256 public  sumPreICO1;
  uint256 public  sumPreICO2;
  uint256 public  sumPreICO3;
  uint256 public  sumICO1;
  uint256 public  sumICO2;
  
  //Hard cap
  uint256 public  sumHardCapPreICO1;
  uint256 public  sumHardCapPreICO2;
  uint256 public  sumHardCapPreICO3;
  uint256 public  sumHardCapICO1;
  uint256 public  sumHardCapICO2;
  
  uint256 public totalSoldTokens;
  //uint256 public minimumContribution;
  // how many token units a Contributor gets per wei
  uint256 public rateIco;  
  // address where funds are collected
  address public wallet;
  
/**
* event for token Procurement logging
* @param contributor who Pledged for the tokens
* @param beneficiary who got the tokens
* @param value weis Contributed for Procurement
* @param amount amount of tokens Procured
*/
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
    
    token = createTokenContract();
    // rate;
    rateIco = 2286;	
    // start and end timestamps where investments are allowed
    //start/end for stage of ICO
    startPreICOStage1 = 1532908800; // July      30 2018 00:00:00 +0000
    endPreICOStage1   = 1533859200; // August    10 2018 00:00:00 +0000
    startPreICOStage2 = 1533859200; // August    10 2018 00:00:00 +0000
    endPreICOStage2   = 1534723200; // August    20 2018 00:00:00 +0000
    startPreICOStage3 = 1534723200; // August    20 2018 00:00:00 +0000
    endPreICOStage3   = 1535587200; // August    30 2018 00:00:00 +0000
    startICOStage1    = 1535587200; // August    30 2018 00:00:00 +0000
    endICOStage1      = 1536105600; // September 5 2018 00:00:00 +0000
    startICOStage2    = 1536105600; // September 5 2018 00:00:00 +0000
    endICOStage2      = 1536537600; // September 10 2018 00:00:00 +0000    

    sumHardCapPreICO1 = 3900000 * 1 ether;
    sumHardCapPreICO2 = 5000000 * 1 ether;
    sumHardCapPreICO3 = 5750000 * 1 ether;
    sumHardCapICO1 = 9900000 *  1 ether;
    sumHardCapICO2 = 20000000 * 1 ether;

    // address where funds are collected
    wallet = 0x6e9f5B0E49A7039bD1d4bdE84e4aF53b8194287d;
  }

  function setRateIco(uint _rateIco) public onlyOwner  {
    rateIco = _rateIco;
  }   

  // fallback function can be used to Procure tokens
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function createTokenContract() internal returns (LTE) {
    return new LTE();
  }

  function getRateIcoWithBonus() public view returns (uint256) {
    uint256 bonus;
    //PreICO   
    if (now >= startPreICOStage1 && now < endPreICOStage1){
      bonus = 30;    
    }     
    if (now >= startPreICOStage2 && now < endPreICOStage2){
      bonus = 25;    
    }        
    if (now >= startPreICOStage3 && now < endPreICOStage3){
      bonus = 15;    
    }
    if (now >= startICOStage1 && now < endICOStage1){
      bonus = 10;    
    }    
    if (now >= startICOStage2 && now < endICOStage2){
      bonus = 0;    
    }      
    return rateIco + rateIco.mul(bonus).div(100);
  }  
  
  function checkHardCap(uint256 _value) public {
    //PreICO   
    if (now >= startPreICOStage1 && now < endPreICOStage1){
      require(_value.add(sumPreICO1) <= sumHardCapPreICO1);
      sumPreICO1 = sumPreICO1.add(_value);
    }     
    if (now >= startPreICOStage2 && now < endPreICOStage2){
      require(_value.add(sumPreICO2) <= sumHardCapPreICO2);
      sumPreICO2 = sumPreICO2.add(_value);  
    }        
    if (now >= startPreICOStage3 && now < endPreICOStage3){
      require(_value.add(sumPreICO3) <= sumHardCapPreICO3);
      sumPreICO3 = sumPreICO3.add(_value);    
    }
    if (now >= startICOStage1 && now < endICOStage1){
      require(_value.add(sumICO1) <= sumHardCapICO1);
      sumICO1 = sumICO1.add(_value);  
    }    
    if (now >= startICOStage2 && now < endICOStage2){
      require(_value.add(sumICO2) <= sumHardCapICO2);
      sumICO2 = sumICO2.add(_value);   
    }      
  } 
  function procureTokens(address _beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 rate;
    address _this = this;
    require(now >= startPreICOStage1);
    require(now <= endICOStage2);
    require(_beneficiary != address(0));
    rate = getRateIcoWithBonus();
    tokens = weiAmount.mul(rate);
    checkHardCap(tokens);
    //totalSoldTokens = totalSoldTokens.add(tokens);
    wallet.transfer(_this.balance);
    token.mint(_beneficiary, tokens);
    emit TokenProcurement(msg.sender, _beneficiary, weiAmount, tokens);
  }
}