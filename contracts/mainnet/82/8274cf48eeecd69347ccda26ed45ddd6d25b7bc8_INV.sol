pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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
  function transferOwnership(address newOwner) onlyOwner public {
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
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
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

contract INV is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "Invest";
  string public constant symbol = "INV";
  uint32 public constant decimals = 18;

  address public addressTeam; // address of vesting smart contract
  address public addressReserve;
  address public addressAdvisors;
  address public addressBounty;

  uint public summTeam;
  uint public summReserve;
  uint public summAdvisors;
  uint public summBounty;
  
  function INV() public {
    summTeam =     42000000 * 1 ether;
    summReserve =  27300000 * 1 ether;
    summAdvisors = 10500000 * 1 ether;
    summBounty =    4200000 * 1 ether;  

    addressTeam =     0xE347C064D8535b2f7D7C0f7bc5d6763125FC2Dc6;
    addressReserve =  0xB7C8163F7aAA51f1836F43d76d263e72529413ad;
    addressAdvisors = 0x461361e2b78F401db76Ea1FD4E0125bF3c56a222;
    addressBounty =   0x4060F9bf893fa563C272F5E4d4E691e84eF983CA;

    //Founders and supporters initial Allocations
    mint(addressTeam, summTeam);
    mint(addressReserve, summReserve);
    mint(addressAdvisors, summAdvisors);
    mint(addressBounty, summBounty);
  }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
}

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
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  // totalTokens
  uint256 public totalTokens;
  // total all stage
  uint256 public totalAllStage;
  // The token being sold
  INV public token;
  // start and end timestamps where investments are allowed (both inclusive)
    //start
  uint256 public startSeedStage;
  uint256 public startPrivateSaleStage;
  uint256 public startPreSaleStage;
  uint256 public startPublicSaleStage; 
    //end
  uint256 public endSeedStage;
  uint256 public endPrivateSaleStage;
  uint256 public endPreSaleStage;
  uint256 public endPublicSaleStage;    

  
  // the maximum number of tokens that can 
  // be allocated at the current stage of the ICO
  uint256 public maxSeedStage;
  uint256 public maxPrivateSaleStage;
  uint256 public maxPreSaleStage;
  uint256 public maxPublicSaleStage;   
  // the total number of tokens distributed at the current stage of the ICO
  uint256 public totalSeedStage;
  uint256 public totalPrivateSaleStage;
  uint256 public totalPreSaleStage;
  uint256 public totalPublicSaleStage; 

  // rate
  uint256 public rateSeedStage;
  uint256 public ratePrivateSaleStage;
  uint256 public ratePreSaleStage;
  uint256 public ratePublicSaleStage;   

  // address where funds are collected
  address public wallet;

  // minimum payment
  uint256 public minPayment; 

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
    token = createTokenContract();
    // total number of tokens
    totalTokens = 126000000 * 1 ether;
    // minimum quantity values
    minPayment = 10000000000000000; //0.01 eth
    
  // start and end timestamps where investments are allowed (both inclusive)
    //start
  startSeedStage = 1523275200; //09 Apr 2018 12:00:00 UTC
  startPrivateSaleStage = 1526385600; //15 May 2018 12:00:00 UTC
  startPreSaleStage = 1527336000; //26 May 2018 12:00:00 UTC
  startPublicSaleStage = 1534334400; //15 Aug 2018 08:00:00 UTC
    //end
  endSeedStage = 1525867200; //09 May 2018 12:00:00 UTC
  endPrivateSaleStage = 1526817600; //20 May 2018 12:00:00 UTC
  endPreSaleStage = 1531656000; //15 Jul 2018 12:00:00 UTC
  endPublicSaleStage = 1538308800; //30 Sep 2018 12:00:00 UTC

  // the maximum number of tokens that can 
  // be allocated at the current stage of the ICO
  maxSeedStage = 126000000 * 1 ether;
  maxPrivateSaleStage = 126000000 * 1 ether;
  maxPreSaleStage = 126000000 * 1 ether;
  maxPublicSaleStage = 126000000 * 1 ether;   

  // rate for each stage of the ICO
  rateSeedStage = 10000;
  ratePrivateSaleStage = 8820;
  ratePreSaleStage = 7644;
  ratePublicSaleStage = 4956;   

  // address where funds are collected
  wallet = 0x72b0FeF6BB61732e97AbA95D64B33f1345A7ABf7;  
  
  }

  function createTokenContract() internal returns (INV) {
    return new INV();
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
    //minimum amount in ETH
    require(weiAmount >= minPayment);
    require(totalAllStage < totalTokens);
    //Seed
    if (now >= startSeedStage && now < endSeedStage && totalSeedStage < maxSeedStage){
      tokens = weiAmount.mul(rateSeedStage);
      if (maxSeedStage.sub(totalSeedStage) < tokens){
        tokens = maxSeedStage.sub(totalSeedStage); 
        weiAmount = tokens.div(rateSeedStage);
        backAmount = msg.value.sub(weiAmount);
      }
      totalSeedStage = totalSeedStage.add(tokens);
    }
    //Private Sale
    if (now >= startPrivateSaleStage && now < endPrivateSaleStage && totalPrivateSaleStage < maxPrivateSaleStage){
      tokens = weiAmount.mul(ratePrivateSaleStage);
      if (maxPrivateSaleStage.sub(totalPrivateSaleStage) < tokens){
        tokens = maxPrivateSaleStage.sub(totalPrivateSaleStage); 
        weiAmount = tokens.div(ratePrivateSaleStage);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPrivateSaleStage = totalPrivateSaleStage.add(tokens);
    }    
    //Pre-sale
    if (now >= startPreSaleStage && now < endPreSaleStage && totalPreSaleStage < maxPreSaleStage){
      tokens = weiAmount.mul(ratePreSaleStage);
      if (maxPreSaleStage.sub(totalPreSaleStage) < tokens){
        tokens = maxPreSaleStage.sub(totalPreSaleStage); 
        weiAmount = tokens.div(ratePreSaleStage);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPreSaleStage = totalPreSaleStage.add(tokens);
    }    
    //Public Sale
    if (now >= startPublicSaleStage && now < endPublicSaleStage && totalPublicSaleStage < maxPublicSaleStage){
      tokens = weiAmount.mul(ratePublicSaleStage);
      if (maxPublicSaleStage.sub(totalPublicSaleStage) < tokens){
        tokens = maxPublicSaleStage.sub(totalPublicSaleStage); 
        weiAmount = tokens.div(ratePublicSaleStage);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPublicSaleStage = totalPublicSaleStage.add(tokens);
    }   
    
    require(tokens > 0);
    token.mint(beneficiary, tokens);
    totalAllStage = totalAllStage.add(tokens);
    wallet.transfer(weiAmount);
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
}