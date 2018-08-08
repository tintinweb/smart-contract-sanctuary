pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/StandardToken.sol

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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

// File: zeppelin-solidity/contracts/token/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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

// File: zeppelin-solidity/contracts/token/MintableToken.sol

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

// File: zeppelin-solidity/contracts/token/CappedToken.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: contracts/DateCoin.sol

contract DateCoin is CappedToken, BurnableToken {

  string public constant name = "DateCoin ICO Token";
  string public constant symbol = "DTC";
  uint256 public constant decimals = 18;

  function DateCoin(uint256 _cap) public CappedToken(_cap) {
  }
}

// File: zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
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


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
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
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
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

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

// File: contracts/DateCoinCrowdsale.sol

// DateCoin


// Zeppelin



contract DateCoinCrowdsale is Crowdsale, Ownable {
  enum ManualState {
    WORKING, READY, NONE
  }

  uint256 public decimals;
  uint256 public emission;

  // Discount border-lines
  mapping(uint8 => uint256) discountTokens;
  mapping(address => uint256) pendingOrders;

  uint256 public totalSupply;
  address public vault;
  address public preSaleVault;
  ManualState public manualState = ManualState.NONE;
  bool public disabled = true;

  function DateCoinCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _tokenContractAddress, address _vault, address _preSaleVault) public
    Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
    require(_vault != address(0));

    vault = _vault;
    preSaleVault = _preSaleVault;

    token = DateCoin(_tokenContractAddress);
    decimals = DateCoin(token).decimals();

    totalSupply = token.balanceOf(vault);

    defineDiscountBorderLines();
  }

  // overriding Crowdsale#buyTokens
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    if (disabled) {
      pendingOrders[msg.sender] = pendingOrders[msg.sender].add(msg.value);
      forwardFunds();
      return;
    }

    uint256 weiAmount = msg.value;
    uint256 sold = totalSold();

    uint256 tokens;

    if (sold < _discount(25)) {
      tokens = _calculateTokens(weiAmount, 25, sold);
    }
    else if (sold >= _discount(25) && sold < _discount(20)) {
      tokens = _calculateTokens(weiAmount, 20, sold);
    }
    else if (sold >= _discount(20) && sold < _discount(15)) {
      tokens = _calculateTokens(weiAmount, 15, sold);
    }
    else if (sold >= _discount(15) && sold < _discount(10)) {
      tokens = _calculateTokens(weiAmount, 10, sold);
    }
    else if (sold >= _discount(10) && sold < _discount(5)) {
      tokens = _calculateTokens(weiAmount, 5, sold);
    }
    else {
      tokens = weiAmount.mul(rate);
    }

    // Check limit
    require(sold.add(tokens) <= totalSupply);

    weiRaised = weiRaised.add(weiAmount);
    token.transferFrom(vault, beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function totalSold() public view returns(uint256) {
    return totalSupply.sub(token.balanceOf(vault));
  }

  /**
    * @dev This method is allowed to transfer tokens to _to account
    * @param _to target account address
    * @param _amount amout of buying tokens
    */
  function transferTokens(address _to, uint256 _amount) public onlyOwner {
    require(!hasEnded());
    require(_to != address(0));
    require(_amount != 0);
    require(token.balanceOf(vault) >= _amount);

    token.transferFrom(vault, _to, _amount);
  }

  function transferPreSaleTokens(address _to, uint256 tokens) public onlyOwner {
    require(_to != address(0));
    require(tokens != 0);
    require(tokens < token.balanceOf(preSaleVault));

    token.transferFrom(preSaleVault, _to, tokens);
  }


  function transferOwnership(address _newOwner) public onlyOwner {
    token.transferOwnership(_newOwner);
  }

  // This method is used for definition of discountTokens borderlines
  function defineDiscountBorderLines() internal onlyOwner {
    discountTokens[25] = 95 * (100000 ether);
    discountTokens[20] = 285 * (100000 ether);
    discountTokens[15] = 570 * (100000 ether);
    discountTokens[10] = 950 * (100000 ether);
    discountTokens[5] = 1425 * (100000 ether);
  }

  /**
    * @dev overriding Crowdsale#validPurchase to add extra sale limit logic
    * @return true if investors can buy at the moment
    */
  function validPurchase() internal view returns(bool) {
    uint256 weiValue = msg.value;

    bool defaultCase = super.validPurchase();
    bool capCase = token.balanceOf(vault) > 0;
    bool extraCase = weiValue != 0 && capCase && manualState == ManualState.WORKING;
    return defaultCase && capCase || extraCase;
  }

  /**
    * @dev overriding Crowdsale#hasEnded to add sale limit logic
    * @return true if crowdsale event has ended
    */
  function hasEnded() public view returns (bool) {
    if (manualState == ManualState.WORKING) {
      return false;
    }
    else if (manualState == ManualState.READY) {
      return true;
    }
    bool icoLimitReached = token.balanceOf(vault) == 0;
    return super.hasEnded() || icoLimitReached;
  }

  /**
    * @dev this method allows to finish crowdsale prematurely
    */
  function finishCrowdsale() public onlyOwner {
    manualState = ManualState.READY;
  }


  /**
    * @dev this method allows to start crowdsale prematurely
    */
  function startCrowdsale() public onlyOwner {
    manualState = ManualState.WORKING;
  }

  /**
    * @dev this method allows to drop manual state of contract
    */
  function dropManualState() public onlyOwner {
    manualState = ManualState.NONE;
  }

  /**
    * @dev disable automatically seller
    */
  function disableAutoSeller() public onlyOwner {
    disabled = true;
  }

  /**
    * @dev enable automatically seller
    */
  function enableAutoSeller() public onlyOwner {
    disabled = false;
  }

  /**
    * @dev this method is used for getting information about account pending orders
    * @param _account which is checked
    * @return has or not
    */
  function hasAccountPendingOrders(address _account) public view returns(bool) {
    return pendingOrders[_account] > 0;
  }

  /**
    * @dev this method is used for getting account pending value
    * @param _account which is checked
    * @return if account doesn&#39;t have any pending orders, it will return 0
    */
  function getAccountPendingValue(address _account) public view returns(uint256) {
    return pendingOrders[_account];
  }

  function _discount(uint8 _percent) internal view returns (uint256) {
    return discountTokens[_percent];
  }

  function _calculateTokens(uint256 _value, uint8 _off, uint256 _sold) internal view returns (uint256) {
    uint256 withoutDiscounts = _value.mul(rate);
    uint256 byDiscount = withoutDiscounts.mul(100).div(100 - _off);
    if (_sold.add(byDiscount) > _discount(_off)) {
      uint256 couldBeSold = _discount(_off).sub(_sold);
      uint256 weiByDiscount = couldBeSold.div(rate).div(100).mul(100 - _off);
      uint256 weiLefts = _value.sub(weiByDiscount);
      uint256 withoutDiscountLeft = weiLefts.mul(rate);
      uint256 byNextDiscount = withoutDiscountLeft.mul(100).div(100 - _off + 5);
      return couldBeSold.add(byNextDiscount);
    }
    return byDiscount;
  }
}