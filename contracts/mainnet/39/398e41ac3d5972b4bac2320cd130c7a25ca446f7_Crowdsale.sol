pragma solidity ^0.4.21;

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
   * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. 
 *
 * Presales:
 * Certain addresses are allowed to buy at a presale rate during the presale period. The
 * contribution of the investor needs to be of at least 5 ETH. A maximum of 15 million tokens
 * in total can be bought at the presale rate. Once the presale has been instructed to end, it
 * is not possible to enable it again.
 *
 * Sales:
 * Any address can purchase at the regular sale price. Sales can be pauses, resumed, and stopped.
 *
 * Minting:
 * The transferTokens function will mint the tokens in the Token contract. After the minting 
 * is done, the Crowdsale is reset.
 * 
 * Refunds:
 * A investor can be refunded by the owner. Calling the refund function resets the tokens bought
 * to zero for that investor. The Ether refund needs to be processed manually. It is important
 * to record how many tokens the investor had bought before calling refund().
 *
*/
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  StandardToken public token;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // How many token units a buyer gets per wei if entitled to the presale
  uint public presaleRate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Administrator of the sale
  address public owner;

  // How many tokens each address bought at the normal rate
  mapping (address => uint) public regularTokensSold;

  // How many tokens each address bought at the presale rate
  mapping (address => uint) public presaleTokensSold;

  // List of all the investors
  address[] public investors;

  // Whether the sale is active
  bool public inSale = true;

  // Whether the presale is active
  bool public inPresale = true;

  // How many tokens each address can buy at the presale rate
  mapping (address => uint) public presaleAllocations;

  // The total number of tokens bought
  uint256 public totalPresaleTokensSold = 0;

  // The total number of tokens bought
  uint256 public totalRegularTokensSold = 0;

  // The maximum number of tokens which can be sold during presale
  uint256 constant public PRESALETOKENMAXSALES = 15000000000000000000000000;

  // The maximum number of tokens which can be sold during regular sale
  uint256 public regularTokenMaxSales = 16000000000000000000000000;

  // The minimum investment (5 ETH) during presale
  uint256 constant public MINIMUMINVESTMENTPRESALE = 5000000000000000000;

  // The minimum investment (5 ETH) during sale
  uint256 constant public MINIMUMINVESTMENTSALE = 1000000000000000000;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyDuringPresale() {
    require(inPresale);
    _;
  }

  modifier onlyWhenSalesEnabled() {
    require(inSale);
    _;
  }

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   * @param rate the rate at which the tokens were purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 rate);

  /**
   * Constructor for the crowdsale
   * @param _owner owner of the contract, which can call privileged functions, and where every ether
   *        is sent to
   * @param _rate the rate for regular sales
   * @param _rate the rate for presales
   * @param _ownerInitialTokens the number of tokens the owner is allocated initially
   */
  function Crowdsale(
    address _owner, 
    uint256 _rate, 
    uint256 _presaleRate, 
    uint256 _ownerInitialTokens
  ) public payable {
    require(_rate > 0);
    require(_presaleRate > 0);
    require(_owner != address(0));

    rate = _rate;
    presaleRate = _presaleRate;
    owner = _owner;

    investors.push(owner);
    regularTokensSold[owner] = _ownerInitialTokens;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  function () external payable {
    buyTokens();
  }

  /**
   * Sets the address of the Token contract.
   */
  function setToken(StandardToken _token) public onlyOwner {
    token = _token;
  }

  /**
   * Buy a token at presale price. Converts ETH to as much QNT the sender can purchase. Any change
   * is refunded to the sender. Minimum contribution is 5 ETH.
   */
  function buyPresaleTokens() onlyDuringPresale onlyWhenSalesEnabled public payable {
    address _beneficiary = msg.sender;
    uint256 weiAmount = msg.value;

    _preValidatePurchase(_beneficiary);
    require(weiAmount >= MINIMUMINVESTMENTPRESALE);

    uint256 presaleAllocation = presaleAllocations[_beneficiary];

    uint256 presaleTokens = _min256(weiAmount.mul(presaleRate), presaleAllocation);

    _recordPresalePurchase(_beneficiary, presaleTokens);

    // Remove presale tokens allocation
    presaleAllocations[_beneficiary] = presaleAllocations[_beneficiary].sub(presaleTokens);

    uint256 weiCharged = presaleTokens.div(presaleRate);

    // Return any extra Wei to the sender
    uint256 change = weiAmount.sub(weiCharged);
    _beneficiary.transfer(change);

    // Update total number of Wei raised
    weiRaised = weiRaised.add(weiAmount.sub(change));

    emit TokenPurchase(msg.sender, _beneficiary, weiCharged, presaleTokens, presaleRate);

    // Forward the funds to owner
    _forwardFunds(weiCharged);
  }

  /**
   * Buy a token at sale price. Minimum contribution is 1 ETH.
   */
  function buyTokens() onlyWhenSalesEnabled public payable {
    address _beneficiary = msg.sender;
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary);

    require(weiAmount >= MINIMUMINVESTMENTSALE);

    uint256 tokens = weiAmount.mul(rate);

    // Check we haven&#39;t sold too many tokens
    totalRegularTokensSold = totalRegularTokensSold.add(tokens);
    require(totalRegularTokensSold <= regularTokenMaxSales);

    // Update total number of Wei raised
    weiRaised = weiRaised.add(weiAmount);

    investors.push(_beneficiary);

    // Give tokens
    regularTokensSold[_beneficiary] = regularTokensSold[_beneficiary].add(tokens);

    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens, rate);

    // Forward the funds to owner
    _forwardFunds(weiAmount);
  }

  /**
   * Records a purchase which has been completed before the instantiation of this contract.
   * @param _beneficiary the investor
   * @param _presaleTokens the number of tokens which the investor has bought
   */
  function recordPresalePurchase(address _beneficiary, uint256 _presaleTokens) public onlyOwner {
    weiRaised = weiRaised.add(_presaleTokens.div(presaleRate));
    return _recordPresalePurchase(_beneficiary, _presaleTokens);
  }

  function enableSale() onlyOwner public {
    inSale = true;
  }

  function disableSale() onlyOwner public {
    inSale = false;
  }

  function endPresale() onlyOwner public {
    inPresale = false;

    // Convert the unsold presale tokens to regular tokens
    uint256 remainingPresaleTokens = PRESALETOKENMAXSALES.sub(totalPresaleTokensSold);
    regularTokenMaxSales = regularTokenMaxSales.add(remainingPresaleTokens);
  }

  /**
   * Mints the tokens in the Token contract.
   */
  function transferTokens() public onlyOwner {
    for (uint256 i = 0; i < investors.length; i = i.add(1)) {
      address investor = investors[i];

      uint256 tokens = regularTokensSold[investor];
      uint256 presaleTokens = presaleTokensSold[investor];
      
      regularTokensSold[investor] = 0;
      presaleTokensSold[investor] = 0;

      if (tokens > 0) {
        _deliverTokens(token, investor, tokens);
      }

      if (presaleTokens > 0) {
        _deliverTokens(token, investor, presaleTokens);
      }
    }
  }

  /**
   * Mints the tokens in the Token contract. With Offset and Limit
   */
  function transferTokensWithOffsetAndLimit(uint256 offset, uint256 limit) public onlyOwner {
    for (uint256 i = offset; i <  _min256(investors.length,offset+limit); i = i.add(1)) {
      address investor = investors[i];

      uint256 tokens = regularTokensSold[investor];
      uint256 presaleTokens = presaleTokensSold[investor];

      regularTokensSold[investor] = 0;
      presaleTokensSold[investor] = 0;

      if (tokens > 0) {
        _deliverTokens(token, investor, tokens);
      }

      if (presaleTokens > 0) {
        _deliverTokens(token, investor, presaleTokens);
      }
    }
  }


  /**
   * Clears the number of tokens bought by an investor. The ETH refund needs to be processed
   * manually.
   */
  function refund(address investor) onlyOwner public {
    require(investor != owner);

    uint256 regularTokens = regularTokensSold[investor];
    totalRegularTokensSold = totalRegularTokensSold.sub(regularTokens);
    weiRaised = weiRaised.sub(regularTokens.div(rate));

    uint256 presaleTokens = presaleTokensSold[investor];
    totalPresaleTokensSold = totalPresaleTokensSold.sub(presaleTokens);
    weiRaised = weiRaised.sub(presaleTokens.div(presaleRate));

    regularTokensSold[investor] = 0;
    presaleTokensSold[investor] = 0;

    // Manually send ether to the account
  }

  /**
  * Accessor for Index
  */
  function getInvestorAtIndex(uint256 _index) public view returns(address) {
    return investors[_index];
  }

  /**
  * Return the length of the investors array
  */
  function getInvestorsLength() public view returns(uint256) {
    return investors.length;
  }

  /**
   * Get the number of tokens bought at the regular price for an address.
   */
  function getNumRegularTokensBought(address _address) public view returns(uint256) {
    return regularTokensSold[_address];
  }

  /**
   * Get the number of tokens bought at the presale price for an address.
   */
  function getNumPresaleTokensBought(address _address) public view returns(uint256) {
    return presaleTokensSold[_address];
  }

  /**
   * Get the number of tokens which an investor can purchase at presale rate.
   */
  function getPresaleAllocation(address investor) view public returns(uint256) {
    return presaleAllocations[investor];
  }

  /**
   * Set the number of tokens which an investor can purchase at presale rate.
   */
  function setPresaleAllocation(address investor, uint allocation) onlyOwner public {
    presaleAllocations[investor] = allocation;
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   */
  function _preValidatePurchase(address _beneficiary) internal pure {
    require(_beneficiary != address(0));
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(StandardToken _token, address _beneficiary, uint256 _tokenAmount) internal {
    _token.mint(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 amount) internal {
    owner.transfer(amount);
  }

  function _min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * Records a presale purchase.
   * @param _beneficiary the investor
   * @param _presaleTokens the number of tokens which the investor has bought
   */
  function _recordPresalePurchase(address _beneficiary, uint256 _presaleTokens) internal {
    // Check we haven&#39;t sold too many presale tokens
    totalPresaleTokensSold = totalPresaleTokensSold.add(_presaleTokens);
    require(totalPresaleTokensSold <= PRESALETOKENMAXSALES);

    investors.push(_beneficiary);

    // Give presale tokens
    presaleTokensSold[_beneficiary] = presaleTokensSold[_beneficiary].add(_presaleTokens);
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_ = 45467000000000000000000000;

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
    emit Transfer(msg.sender, _to, _value);
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  // Name of the token
  string constant public name = "Quant";
  // Token abbreviation
  string constant public symbol = "QNT";
  // Decimal places
  uint8 constant public decimals = 18;
  // Zeros after the point
  uint256 constant public DECIMAL_ZEROS = 1000000000000000000;

  mapping (address => mapping (address => uint256)) internal allowed;

  address public crowdsale;

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }

  function StandardToken(address _crowdsale) public {
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

  function mint(address _address, uint256 _value) public onlyCrowdsale {
    balances[_address] = balances[_address].add(_value);
    emit Transfer(0, _address, _value);
  }

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