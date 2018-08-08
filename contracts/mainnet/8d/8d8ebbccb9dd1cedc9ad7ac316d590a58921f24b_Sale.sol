pragma solidity ^0.4.15;

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

// File: contracts/GRAD.sol

contract GRAD {
    using SafeMath for uint256;

    string public name = "Gadus";

    string public symbol = "GRAD";

    uint public decimals = 18;

    uint256 public totalSupply;

    address owner;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

    event Mint (address indexed to, uint256  amount);

    event Transfer(address indexed from, address indexed to, uint256 value);

    // construtor
    function GRAD() public{
        owner = msg.sender;
    }

     /**
      * @dev Mint token to tagret parametred
      * @param _to address The address which you want to mint to
      * @param _value uint256 the amout of tokens to be transfered
      */

    function mint(address _to, uint256 _value) onlyOwner public returns (bool){
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        Mint(_to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
  function approve(address _spender, uint256 _value) public returns (bool) {

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
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

// File: contracts/Sale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end block, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Sale is Ownable{
  using SafeMath for uint256;

  // The token being sold
  GRAD public token;

  // start and end block where investments are allowed (both inclusive)
  uint256 public startBlock;
  uint256 public endBlock;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  bool private isSaleActive;
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Sale(uint256 _startBlock, uint256 _rate, address _wallet) public {
    require(_startBlock >= block.number);
    require(_rate > 0);
    require(_wallet != 0x0);

    owner = msg.sender;
    token = createTokenContract();
    startBlock = _startBlock;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (GRAD) {
    return new GRAD();
  }


  // fallback function can be used to buy tokens
  function () payable public {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable public {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    uint256 bonus = calclulateBonus(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens.add(bonus));
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens.add(bonus));

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  //
  function calclulateBonus(uint256 _weiAmount) internal pure returns (uint256) {
    uint256 weiAmount = _weiAmount;
    // 7% over 10 eth
    // 5% over 5 eth
    // 3 over 2.5 eth
    if (weiAmount >= 1e18 * 10) {
      return (weiAmount.mul(7)).div(100);
    } else if (weiAmount >= 1e18 * 5) {
      return (weiAmount.mul(5)).div(100);
    } else if (weiAmount >= 1e17 * 25) {
      return (weiAmount.mul(3)).div(100);
    } else {
      return 0;
    }

  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    uint256 current = block.number;
    bool withinPeriod = current >= startBlock;
    bool withinSaleRunning = isSaleActive;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinSaleRunning;
  }


  //disable if enabled
  function disableSale() onlyOwner() public returns (bool) {
    require(isSaleActive == true);
    isSaleActive = false;
    return true;
  }

  // enable if diabled
  function enableSale()  onlyOwner() public returns (bool) {
    require(isSaleActive == false);
    isSaleActive = true;
    return true;
  }

  // retruns true if sale is currently active
  function saleStatus() public constant returns (bool){
    return isSaleActive;
  }

}