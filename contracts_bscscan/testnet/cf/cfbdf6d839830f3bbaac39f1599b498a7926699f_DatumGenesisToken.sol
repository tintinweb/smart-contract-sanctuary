/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * @title DatumGenesisToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator. 
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract DatumGenesisToken is StandardToken, Ownable {

  string public name = "DAT Genesis Token";           //The Token's name: e.g. Dat Genesis Tokens
  uint8 public decimals = 18;                         //Number of decimals of the smallest unit
  string public symbol = "DATG";                             //An identifier: e.g. REP
                                           
  uint256 public constant INITIAL_SUPPLY = 75000000 ether;

  // Flag that determines if the token is transferable or not.
  bool public transfersEnabled = false;

  /**
   * @dev Contructor that gives msg.sender all of existing tokens. 
   */
  function DatumGenesisToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }


   /// @notice Enables token holders to transfer their tokens freely if true
   /// @param _transfersEnabled True if transfers are allowed in the clone
   function enableTransfers(bool _transfersEnabled) onlyOwner {
      transfersEnabled = _transfersEnabled;
   }

  function transferFromContract(address _to, uint256 _value) onlyOwner returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    require(transfersEnabled);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(transfersEnabled);
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) returns (bool) {
      require(transfersEnabled);
      return super.approve(_spender, _value);
  }
}



/**
 * @title  
 * @dev DatCrowdSale is a contract for managing a token crowdsale.
 * DatCrowdSale have a start and end date, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a refundable valut 
 * as they arrive.
 */
contract DatCrowdPreSale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  DatumGenesisToken public token;

  // start and end date where investments are allowed (both inclusive)
  uint256 public startDate = 1502460000; //Fri, 11 Aug 2017 14:00:00 +00:00
  uint256 public endDate = 1505138400; //Mon, 11 Sep 2017 14:00:00 +00:00

  // Minimum amount to participate
  uint256 public minimumParticipationAmount = 100000000000000000 wei; //0.1 ether

  // Maximum amount to participate
  uint256 public maximalParticipationAmount = 1000000000000000000000 wei; //1000 ether

  // address where funds are collected
  address wallet;

  // how many token units a buyer gets per ether
  uint256 rate = 15000;

  // amount of raised money in wei
  uint256 public weiRaised;

  //flag for final of crowdsale
  bool public isFinalized = false;

  //cap for the sale
  uint256 public cap = 5000000000000000000000 wei; //5000 ether
 



  event Finalized();

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);



  /**
  * @notice Log an event for each funding contributed during the public phase
  * @notice Events are not logged when the constructor is being executed during
  *         deployment, so the preallocations will not be logged
  */
  event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);


  
  function DatCrowdPreSale(address _wallet) {
    token = createTokenContract();
    wallet = _wallet;
  }


// creates the token to be sold. 
  // override this method to have crowdsale of a specific datum token.
  function createTokenContract() internal returns (DatumGenesisToken) {
    return new DatumGenesisToken();
}

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    //get ammount in wei
    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    //purchase tokens and transfer to beneficiary
    token.transferFromContract(beneficiary, tokens);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    //Token purchase event
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    //forward funds to wallet
    forwardFunds();
  }

  //send tokens to the given address used for investors with other conditions, only contract owner can call this
  function transferTokensManual(address beneficiary, uint256 amount) onlyOwner {
    require(beneficiary != 0x0);
    require(amount != 0);
    require(weiRaised.add(amount) <= cap);

    //transfer tokens
    token.transferFromContract(beneficiary, amount);

    // update state
    weiRaised = weiRaised.add(amount);

    //Token purchase event
    TokenPurchase(wallet, beneficiary, 0, amount);

  }

   /// @notice Enables token holders to transfer their tokens freely if true
   /// @param _transfersEnabled True if transfers are allowed in the clone
   function enableTransfers(bool _transfersEnabled) onlyOwner {
      token.enableTransfers(_transfersEnabled);
   }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // should be called after crowdsale ends or to emergency stop the sale
  function finalize() onlyOwner {
    require(!isFinalized);
    Finalized();
    isFinalized = true;
  }


  // @return true if the transaction can buy tokens
  // check for valid time period, min amount and within cap
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = startDate <= now && endDate >= now;
    bool nonZeroPurchase = msg.value != 0;
    bool minAmount = msg.value >= minimumParticipationAmount;
    bool withinCap = weiRaised.add(msg.value) <= cap;

    return withinPeriod && nonZeroPurchase && minAmount && !isFinalized && withinCap;
  }

    // @return true if the goal is reached
  function capReached() public constant returns (bool) {
    return weiRaised >= cap;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return isFinalized;
  }

}