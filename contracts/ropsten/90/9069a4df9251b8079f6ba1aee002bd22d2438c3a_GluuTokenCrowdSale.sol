pragma solidity ^0.4.18;

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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

// File: contracts/token/MintableToken.sol

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

  // white listing admin - for presale listing
  address public whiteListingAdmin;


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

  function setWhitelistAdmin(address _whitelistAdmin) onlyOwner public {
    whiteListingAdmin = _whitelistAdmin;
  }
}

// File: contracts/GluuToken.sol

contract GluuToken is MintableToken {
    string public constant name = &quot;GluuToken&quot;;

    string public constant symbol = &quot;GLT&quot;;

    uint8 public decimals = 18;

    bool public tradingStarted = false;

    bool public presaleTradingStarted = false;

    // presale list for KYC
    mapping (address => bool) public presaleList;

    /**
     * @dev modifier that throws if trading has not started yet
     */
    modifier hasStartedTrading() {
        require(tradingStarted && validPresaleTrading());
        _;
    }

    // @return true if presaleTradingStarted
    function validPresaleTrading() internal view returns (bool) {

      if (presaleTradingStarted){
        return true;
      }
      if (presaleList[msg.sender] == true){
        return false;
      }
      return true;
    }

    /**
     * @dev Allows the owner to enable the trading.
     */
    function startTrading() onlyOwner public {
        tradingStarted = true;
    }

    /**
     * @dev Allows the owner to enable the presale token trading.
     */
    function startPresaleTrading() onlyOwner public {
        presaleTradingStarted = true;
    }

    /**
    *    @dev Populate the whitelist, only executed by whiteListingAdmin
    *
    */
    function updatePresaleListMapping(address[] _address,bool value) public {
      require(msg.sender == whiteListingAdmin);

      // add the whitelisted addresses to the mapping
      for (uint i = 0; i < _address.length; i++) {
          presaleList[_address[i]] = value;
      }
    }

    /**
     * @dev Allows anyone to transfer the tokens once trading has started
     * @param _to the recipient address of the tokens.
     * @param _value number of tokens to be transfered.
     */
    function transfer(address _to, uint _value) hasStartedTrading public returns (bool){
        return super.transfer(_to, _value);
    }

    /**
     * @dev Allows anyone to transfer the  tokens once trading has started
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint _value) hasStartedTrading public returns (bool){
        return super.transferFrom(_from, _to, _value);
    }

    /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender when not paused.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint256 _value) public hasStartedTrading returns (bool) {
        return super.approve(_spender, _value);
    }

    /**
     * Adding whenNotPaused
     */
    function increaseApproval(address _spender, uint _addedValue) public hasStartedTrading returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * Adding whenNotPaused
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public hasStartedTrading returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

// File: contracts/crowdsale/Crowdsale.sol

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

  // Bonus Token implementation
  uint256 public bonus;
  uint256 public bonusMaxWei;

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

    //initially bonus & bonusMaxWei == 0
    bonus = 0;
    bonusMaxWei = 0;
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
  // overrided to create custom buy
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = calculateBonus(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  //Calculate bonus tokens if there is a bonus structure mentioned
  function calculateBonus(uint256 weiAmount) internal returns (uint256) {
    uint256 tokens = 0;

    if (bonus != 0) {
      uint256 eligibleWei = 0;
      uint256 remainingWei = 0;

      if (weiAmount > bonusMaxWei){
        eligibleWei = bonusMaxWei;
        remainingWei = weiAmount.sub(bonusMaxWei);
      } else {
        eligibleWei = weiAmount;
      }

      uint256 bonusWei = eligibleWei.mul(bonus).div(100);
      uint256 totalWei = bonusWei.add(weiAmount);
      uint256 bonusTokens = totalWei.mul(rate);

      uint256 remainingTokens = remainingWei.mul(rate);

      tokens = bonusTokens.add(remainingTokens);

    } else {
      tokens = weiAmount.mul(1000);
    }

    return tokens;
  }

  // send ether to the fund collection wallet
  // overrided to create custom fund forwarding mechanisms
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

// File: contracts/crowdsale/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal{
  }
}

// File: contracts/modified.crowdsale/RefundVaultWithCommission.sol

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVaultWithCommission is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  address public walletFees;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVaultWithCommission(address _wallet,address _walletFees) public {
    require(_wallet != address(0));
    require(_walletFees != address(0));
    wallet = _wallet;
    walletFees = _walletFees;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();

    //transfer the remaining part
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

// File: contracts/modified.crowdsale/RefundableCrowdsaleWithCommission.sol

/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale&#39;s vault.
 */
contract RefundableCrowdsaleWithCommission is FinalizableCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  RefundVaultWithCommission public vault;

  function RefundableCrowdsaleWithCommission(uint256 _goal,address _walletFees) public {
    require(_goal > 0);
    vault = new RefundVaultWithCommission(wallet,_walletFees);
    goal = _goal;
  }

  // We&#39;re overriding the fund forwarding from Crowdsale.
  // In addition to sending the funds, we want to call
  // the RefundVault deposit function
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}

// File: contracts/GluuTokenCrowdSale.sol

contract GluuTokenCrowdSale is Crowdsale, RefundableCrowdsaleWithCommission {
    using SafeMath for uint256;

    // number of participants
    uint256 public numberOfPurchasers = 0;

    // maximum tokens that can be minted in this crowd sale - initialised later by the constructor
    uint256 public maxTokenSupply = 0;

    // version cache buster
    string public constant version = &quot;v1.3&quot;;

    // pending contract owner - initialised later by the constructor
    address public pendingOwner;

    // Minimum amount to been able to contribute - initialised later by the constructor
    uint256 public minimumAmount = 0;

    // Reserved amount - initialised later by the constructor
    address public reservedAddr;
    uint256 public reservedAmount;

    // white list for KYC
    mapping (address => bool) public whitelist;

    // white listing admin - initialised later by the constructor
    address public whiteListingAdmin;



    function GluuTokenCrowdSale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        uint256 _minimumAmount,
        uint256 _maxTokenSupply,
        address _wallet,
        address _reservedAddr,
        uint256 _reservedAmount,
        address _pendingOwner,
        address _whiteListingAdmin,
        address _walletFees
    )
    FinalizableCrowdsale()
    RefundableCrowdsaleWithCommission(_goal,_walletFees)
    Crowdsale(_startTime, _endTime, _rate, _wallet) public
    {
        require(_pendingOwner != address(0));
        require(_minimumAmount >= 0);
        require(_maxTokenSupply > 0);
        require(_reservedAmount > 0 && _reservedAmount < _maxTokenSupply);

        // make sure that the refund goal is within the max supply, using the default rate,  without the reserved supply
        require(_goal.mul(rate) <= _maxTokenSupply.sub(_reservedAmount));

        pendingOwner = _pendingOwner;
        minimumAmount = _minimumAmount;
        maxTokenSupply = _maxTokenSupply;

        // reserved amount
        reservedAddr = _reservedAddr;
        reservedAmount = _reservedAmount;

        // whitelisting admin
        setWhiteListingAdmin(_whiteListingAdmin);

    }

    /**
    *
    * Create the token on the fly, owner is the contract, not the contract owner yet
    *
    **/
    function createTokenContract() internal returns (MintableToken) {
        return new GluuToken();
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(whitelist[beneficiary] == true);
        //
        require(validPurchase());

        // buying can only begins as soon as the ownership has been transfer to the pendingOwner
        require(owner==pendingOwner);

        uint256 weiAmount = msg.value;

        // Compute the number of tokens per wei
        // bonus structure should be used here, if any
        uint256 tokens = weiAmount.mul(rate);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        // update wei raised and number of purchasers
        weiRaised = weiRaised.add(weiAmount);
        numberOfPurchasers = numberOfPurchasers + 1;

        forwardFunds();
    }

    // overriding Crowdsale#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal view returns (bool) {

        // make sure we accept only the minimum contribution
        bool minAmount = (msg.value >= minimumAmount);

        // cap crowdsaled to a maxTokenSupply
        // make sure we can not mint more token than expected
        bool lessThanMaxSupply = (token.totalSupply() + msg.value.mul(rate)) <= maxTokenSupply;

        // make sure that the purchase follow each rules to be valid
        return super.validPurchase() && minAmount && lessThanMaxSupply;
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = token.totalSupply() >= maxTokenSupply;
        return super.hasEnded() || capReached;
    }
    /**
     *
     * Admin functions only called by owner:
     *
     *
     */

    /**
      *
      * Called when the admin function finalize is called :
      *
      * it mint the remaining amount to have the supply exactly as planned
      * it transfer the ownership of the token to the owner of the smart contract
      *
      */
    function finalization() internal {
        //
        // send back to the owner the remaining tokens before finishing minting
        // it ensure that there is only a exact maxTokenSupply token minted ever
        //
        uint256 remainingTokens = maxTokenSupply - token.totalSupply();

        // mint the remaining amount and assign them to the owner
        token.mint(owner, remainingTokens);
        TokenPurchase(owner, owner, 0, remainingTokens);

        // finalize the refundable inherited contract
        super.finalization();

        // no more minting allowed - immutable
        token.finishMinting();

        // transfer the token owner ship from the contract address to the owner
        token.transferOwnership(owner);
    }

    /**
      *
      * Admin functions only executed by owner:
      * Can change minimum amount
      *
      */
    function changeMinimumAmount(uint256 _minimumAmount) onlyOwner public {
        require(_minimumAmount > 0);
        minimumAmount = _minimumAmount;
    }

     /**
      *
      * Admin functions only executed by owner:
      * Can change rate
      *
      * We do not use an oracle here as oracle need to be paid each time, and if the oracle is not responding
      * or hacked the rate could be detrimentally modified from an contributor perspective.
      *
      */
    function changeRate(uint256 _rate) onlyOwner public {
        require(_rate > 0);
        rate = _rate;
    }

     /**
      *
      * Admin functions only executed by owner:
      * Can change bonus percentage & bonus max wei value.
      *
      * This Bonus implementation is to give bonus tokens to investors when they send ETH
      *
      */
    function changeBonus(uint256 _bonus, uint256 _maxBonus) onlyOwner public {
        bonus = _bonus;
        bonusMaxWei = _maxBonus;
    }

    /**
      *
      * Admin functions only called by owner:
      * Can change event start date
      *
      */
    function changeStartDate(uint256 _startTime) onlyOwner public {
        require(_startTime >= now);
        require(endTime >= _startTime);
        startTime = _startTime;
    }

    /**
      *
      * Admin functions only called by owner:
      * Can change event end date
      *
      */
    function changeEndDate(uint256 _endTime) onlyOwner public {
        require(_endTime >= now);
        require(_endTime >= startTime);
        endTime = _endTime;
    }

    /**
      *
      * Admin functions only called by owner:
      * Can sendPresaleTokens
      *
      */
    function sendPresaleTokens(address receiver, uint256 weiAmount) onlyOwner public {
        require(receiver != address(0));
        require(whitelist[receiver] == true);

        // make sure we accept only the minimum contribution
        bool minAmount = (weiAmount >= minimumAmount);

        // Check for max supply
        bool lessThanMaxSupply = (token.totalSupply() + weiAmount.mul(rate)) <= maxTokenSupply;

        bool withinPeriod = now >= startTime && now <= endTime;

        // make sure that the purchase follow each rules to be valid
        require(withinPeriod && minAmount && lessThanMaxSupply);

        // buying can only begins as soon as the ownership has been transfer to the pendingOwner
        require(owner==pendingOwner);

        // Compute the number of tokens per wei
        // bonus structure should be used here, if any
        uint256 tokens = weiAmount.mul(rate);

        token.mint(receiver, tokens);
        TokenPurchase(receiver, receiver, weiAmount, tokens);

        // update wei raised and number of purchasers
        weiRaised = weiRaised.add(weiAmount);
        numberOfPurchasers = numberOfPurchasers + 1;
    }


    /**
      *
      * Admin functions only executed by pendingOwner
      * Change the owner
      *
      */
    function transferOwnerShipToPendingOwner() public {

        // only the pending owner can change the ownership
        require(msg.sender == pendingOwner);

        // can only be changed one time
        require(owner != pendingOwner);

        // raise the event
        OwnershipTransferred(owner, pendingOwner);

        // change the ownership
        owner = pendingOwner;

        // run the PreMint
        runPreMint();

    }

    // run the pre minting of the reserved token

    function runPreMint() onlyOwner private {

        token.mint(reservedAddr, reservedAmount);
        TokenPurchase(owner, reservedAddr, 0, reservedAmount);

        // update state
        numberOfPurchasers = numberOfPurchasers + 1;
    }


    // add a way to change the whitelistadmin user
    function setWhiteListingAdmin(address _whiteListingAdmin) onlyOwner public {
        whiteListingAdmin=_whiteListingAdmin;
        token.setWhitelistAdmin(_whiteListingAdmin);
    }


    /**
    *    @dev Populate the whitelist, only executed by whiteListingAdmin
    *
    */
    function updateWhitelistMapping(address[] _address,bool value) public {
        require(msg.sender == whiteListingAdmin);
        // Add an event here to keep track

        // add the whitelisted addresses to the mapping
        for (uint i = 0; i < _address.length; i++) {
            whitelist[_address[i]] = value;
        }
    }

}