pragma solidity ^0.4.23;

// File: contracts/TokenSale.sol

contract TokenSale {
    /**
    * Buy tokens for the beneficiary using paid Ether.
    * @param beneficiary the beneficiary address that will receive the tokens.
    */
    function buyTokens(address beneficiary) public payable;
}

// File: contracts/WhitelistableConstraints.sol

/**
 * @title WhitelistableConstraints
 * @dev Contract encapsulating the constraints applicable to a Whitelistable contract.
 */
contract WhitelistableConstraints {

    /**
     * @dev Check if whitelist with specified parameters is allowed.
     * @param _maxWhitelistLength The maximum length of whitelist. Zero means no whitelist.
     * @param _weiWhitelistThresholdBalance The threshold balance triggering whitelist check.
     * @return true if whitelist with specified parameters is allowed, false otherwise
     */
    function isAllowedWhitelist(uint256 _maxWhitelistLength, uint256 _weiWhitelistThresholdBalance)
        public pure returns(bool isReallyAllowedWhitelist) {
        return _maxWhitelistLength > 0 || _weiWhitelistThresholdBalance > 0;
    }
}

// File: contracts/Whitelistable.sol

/**
 * @title Whitelistable
 * @dev Base contract implementing a whitelist to keep track of investors.
 * The construction parameters allow for both whitelisted and non-whitelisted contracts:
 * 1) maxWhitelistLength = 0 and whitelistThresholdBalance > 0: whitelist disabled
 * 2) maxWhitelistLength > 0 and whitelistThresholdBalance = 0: whitelist enabled, full whitelisting
 * 3) maxWhitelistLength > 0 and whitelistThresholdBalance > 0: whitelist enabled, partial whitelisting
 */
contract Whitelistable is WhitelistableConstraints {

    event LogMaxWhitelistLengthChanged(address indexed caller, uint256 indexed maxWhitelistLength);
    event LogWhitelistThresholdBalanceChanged(address indexed caller, uint256 indexed whitelistThresholdBalance);
    event LogWhitelistAddressAdded(address indexed caller, address indexed subscriber);
    event LogWhitelistAddressRemoved(address indexed caller, address indexed subscriber);

    mapping (address => bool) public whitelist;

    uint256 public whitelistLength;

    uint256 public maxWhitelistLength;

    uint256 public whitelistThresholdBalance;

    constructor(uint256 _maxWhitelistLength, uint256 _whitelistThresholdBalance) internal {
        require(isAllowedWhitelist(_maxWhitelistLength, _whitelistThresholdBalance), "parameters not allowed");

        maxWhitelistLength = _maxWhitelistLength;
        whitelistThresholdBalance = _whitelistThresholdBalance;
    }

    /**
     * @return true if whitelist is currently enabled, false otherwise
     */
    function isWhitelistEnabled() public view returns(bool isReallyWhitelistEnabled) {
        return maxWhitelistLength > 0;
    }

    /**
     * @return true if subscriber is whitelisted, false otherwise
     */
    function isWhitelisted(address _subscriber) public view returns(bool isReallyWhitelisted) {
        return whitelist[_subscriber];
    }

    function setMaxWhitelistLengthInternal(uint256 _maxWhitelistLength) internal {
        require(isAllowedWhitelist(_maxWhitelistLength, whitelistThresholdBalance),
            "_maxWhitelistLength not allowed");
        require(_maxWhitelistLength != maxWhitelistLength, "_maxWhitelistLength equal to current one");

        maxWhitelistLength = _maxWhitelistLength;

        emit LogMaxWhitelistLengthChanged(msg.sender, maxWhitelistLength);
    }

    function setWhitelistThresholdBalanceInternal(uint256 _whitelistThresholdBalance) internal {
        require(isAllowedWhitelist(maxWhitelistLength, _whitelistThresholdBalance),
            "_whitelistThresholdBalance not allowed");
        require(whitelistLength == 0 || _whitelistThresholdBalance > whitelistThresholdBalance,
            "_whitelistThresholdBalance not greater than current one");

        whitelistThresholdBalance = _whitelistThresholdBalance;

        emit LogWhitelistThresholdBalanceChanged(msg.sender, _whitelistThresholdBalance);
    }

    function addToWhitelistInternal(address _subscriber) internal {
        require(_subscriber != address(0), "_subscriber is zero");
        require(!whitelist[_subscriber], "already whitelisted");
        require(whitelistLength < maxWhitelistLength, "max whitelist length reached");

        whitelistLength++;

        whitelist[_subscriber] = true;

        emit LogWhitelistAddressAdded(msg.sender, _subscriber);
    }

    function removeFromWhitelistInternal(address _subscriber, uint256 _balance) internal {
        require(_subscriber != address(0), "_subscriber is zero");
        require(whitelist[_subscriber], "not whitelisted");
        require(_balance <= whitelistThresholdBalance, "_balance greater than whitelist threshold");

        assert(whitelistLength > 0);

        whitelistLength--;

        whitelist[_subscriber] = false;

        emit LogWhitelistAddressRemoved(msg.sender, _subscriber);
    }

    /**
     * @param _subscriber The subscriber for which the balance check is required.
     * @param _balance The balance value to check for allowance.
     * @return true if the balance is allowed for the subscriber, false otherwise
     */
    function isAllowedBalance(address _subscriber, uint256 _balance) public view returns(bool isReallyAllowed) {
        return !isWhitelistEnabled() || _balance <= whitelistThresholdBalance || whitelist[_subscriber];
    }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
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

// File: contracts/Crowdsale.sol

/**
 * @title Crowdsale 
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end block, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
contract Crowdsale is TokenSale, Pausable, Whitelistable {
    using AddressUtils for address;
    using SafeMath for uint256;

    event LogStartBlockChanged(uint256 indexed startBlock);
    event LogEndBlockChanged(uint256 indexed endBlock);
    event LogMinDepositChanged(uint256 indexed minDeposit);
    event LogTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 indexed amount, uint256 tokenAmount);

    // The token being sold
    MintableToken public token;

    // The start and end block where investments are allowed (both inclusive)
    uint256 public startBlock;
    uint256 public endBlock;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of raised money in wei
    uint256 public raisedFunds;

    // Amount of tokens already sold
    uint256 public soldTokens;

    // Balances in wei deposited by each subscriber
    mapping (address => uint256) public balanceOf;

    // The minimum balance for each subscriber in wei
    uint256 public minDeposit;

    modifier beforeStart() {
        require(block.number < startBlock, "already started");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "already ended");
        _;
    }

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rate,
        uint256 _minDeposit,
        uint256 maxWhitelistLength,
        uint256 whitelistThreshold
    )
    Whitelistable(maxWhitelistLength, whitelistThreshold) internal
    {
        require(_startBlock >= block.number, "_startBlock is lower than current block.number");
        require(_endBlock >= _startBlock, "_endBlock is lower than _startBlock");
        require(_rate > 0, "_rate is zero");
        require(_minDeposit > 0, "_minDeposit is zero");

        startBlock = _startBlock;
        endBlock = _endBlock;
        rate = _rate;
        minDeposit = _minDeposit;
    }

    /*
    * @return true if crowdsale event has started
    */
    function hasStarted() public view returns (bool started) {
        return block.number >= startBlock;
    }

    /*
    * @return true if crowdsale event has ended
    */
    function hasEnded() public view returns (bool ended) {
        return block.number > endBlock;
    }

    /**
     * Change the crowdsale start block number.
     * @param _startBlock The new start block
     */
    function setStartBlock(uint256 _startBlock) external onlyOwner beforeStart {
        require(_startBlock >= block.number, "_startBlock < current block");
        require(_startBlock <= endBlock, "_startBlock > endBlock");
        require(_startBlock != startBlock, "_startBlock == startBlock");

        startBlock = _startBlock;

        emit LogStartBlockChanged(_startBlock);
    }

    /**
     * Change the crowdsale end block number.
     * @param _endBlock The new end block
     */
    function setEndBlock(uint256 _endBlock) external onlyOwner beforeEnd {
        require(_endBlock >= block.number, "_endBlock < current block");
        require(_endBlock >= startBlock, "_endBlock < startBlock");
        require(_endBlock != endBlock, "_endBlock == endBlock");

        endBlock = _endBlock;

        emit LogEndBlockChanged(_endBlock);
    }

    /**
     * Change the minimum deposit for each subscriber. New value shall be lower than previous.
     * @param _minDeposit The minimum deposit for each subscriber, expressed in wei
     */
    function setMinDeposit(uint256 _minDeposit) external onlyOwner beforeEnd {
        require(0 < _minDeposit && _minDeposit < minDeposit, "_minDeposit is not in [0, minDeposit]");

        minDeposit = _minDeposit;

        emit LogMinDepositChanged(minDeposit);
    }

    /**
     * Change the maximum whitelist length. New value shall satisfy the #isAllowedWhitelist conditions.
     * @param maxWhitelistLength The maximum whitelist length
     */
    function setMaxWhitelistLength(uint256 maxWhitelistLength) external onlyOwner beforeEnd {
        setMaxWhitelistLengthInternal(maxWhitelistLength);
    }

    /**
     * Change the whitelist threshold balance. New value shall satisfy the #isAllowedWhitelist conditions.
     * @param whitelistThreshold The threshold balance (in wei) above which whitelisting is required to invest
     */
    function setWhitelistThresholdBalance(uint256 whitelistThreshold) external onlyOwner beforeEnd {
        setWhitelistThresholdBalanceInternal(whitelistThreshold);
    }

    /**
     * Add the subscriber to the whitelist.
     * @param subscriber The subscriber to add to the whitelist.
     */
    function addToWhitelist(address subscriber) external onlyOwner beforeEnd {
        addToWhitelistInternal(subscriber);
    }

    /**
     * Removed the subscriber from the whitelist.
     * @param subscriber The subscriber to remove from the whitelist.
     */
    function removeFromWhitelist(address subscriber) external onlyOwner beforeEnd {
        removeFromWhitelistInternal(subscriber, balanceOf[subscriber]);
    }

    // fallback function can be used to buy tokens
    function () external payable whenNotPaused {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable whenNotPaused {
        require(beneficiary != address(0), "beneficiary is zero");
        require(isValidPurchase(beneficiary), "invalid purchase by beneficiary");

        balanceOf[beneficiary] = balanceOf[beneficiary].add(msg.value);

        raisedFunds = raisedFunds.add(msg.value);

        uint256 tokenAmount = calculateTokens(msg.value);

        soldTokens = soldTokens.add(tokenAmount);

        distributeTokens(beneficiary, tokenAmount);

        emit LogTokenPurchase(msg.sender, beneficiary, msg.value, tokenAmount);

        forwardFunds(msg.value);
    }

    /**
     * @dev Overrides Whitelistable#isAllowedBalance to add minimum deposit logic.
     */
    function isAllowedBalance(address beneficiary, uint256 balance) public view returns (bool isReallyAllowed) {
        bool hasMinimumBalance = balance >= minDeposit;
        return hasMinimumBalance && super.isAllowedBalance(beneficiary, balance);
    }

    /**
     * @dev Determine if the token purchase is valid or not.
     * @return true if the transaction can buy tokens
     */
    function isValidPurchase(address beneficiary) internal view returns (bool isValid) {
        bool withinPeriod = startBlock <= block.number && block.number <= endBlock;
        bool nonZeroPurchase = msg.value != 0;
        bool isValidBalance = isAllowedBalance(beneficiary, balanceOf[beneficiary].add(msg.value));

        return withinPeriod && nonZeroPurchase && isValidBalance;
    }

    // Calculate the token amount given the invested ether amount.
    // Override to create custom fund forwarding mechanisms
    function calculateTokens(uint256 amount) internal view returns (uint256 tokenAmount) {
        return amount.mul(rate);
    }

    /**
     * @dev Distribute the token amount to the beneficiary.
     * @notice Override to create custom distribution mechanisms
     */
    function distributeTokens(address beneficiary, uint256 tokenAmount) internal {
        token.mint(beneficiary, tokenAmount);
    }

    // Send ether amount to the fund collection wallet.
    // override to create custom fund forwarding mechanisms
    function forwardFunds(uint256 amount) internal;
}

// File: contracts/NokuPricingPlan.sol

/**
* @dev The NokuPricingPlan contract defines the responsibilities of a Noku pricing plan.
*/
contract NokuPricingPlan {
    /**
    * @dev Pay the fee for the service identified by the specified name.
    * The fee amount shall already be approved by the client.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @param client The client of the target service.
    * @return true if fee has been paid.
    */
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

    /**
    * @dev Get the usage fee for the service identified by the specified name.
    * The returned fee amount shall be approved before using #payFee method.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @return The amount to approve before really paying such fee.
    */
    function usageFee(bytes32 serviceName, uint256 multiplier) public view returns(uint fee);
}

// File: contracts/NokuCustomToken.sol

contract NokuCustomToken is Ownable {

    event LogBurnFinished();
    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers for using Noku services
    NokuPricingPlan public pricingPlan;

    // The entity acting as Custom Token service provider i.e. Noku
    address public serviceProvider;

    // Flag indicating if Custom Token burning has been permanently finished or not.
    bool public burningFinished;

    /**
    * @dev Modifier to make a function callable only by service provider i.e. Noku.
    */
    modifier onlyServiceProvider() {
        require(msg.sender == serviceProvider, "caller is not service provider");
        _;
    }

    modifier canBurn() {
        require(!burningFinished, "burning finished");
        _;
    }

    constructor(address _pricingPlan, address _serviceProvider) internal {
        require(_pricingPlan != 0, "_pricingPlan is zero");
        require(_serviceProvider != 0, "_serviceProvider is zero");

        pricingPlan = NokuPricingPlan(_pricingPlan);
        serviceProvider = _serviceProvider;
    }

    /**
    * @dev Presence of this function indicates the contract is a Custom Token.
    */
    function isCustomToken() public pure returns(bool isCustom) {
        return true;
    }

    /**
    * @dev Stop burning new tokens.
    * @return true if the operation was successful.
    */
    function finishBurning() public onlyOwner canBurn returns(bool finished) {
        burningFinished = true;

        emit LogBurnFinished();

        return true;
    }

    /**
    * @dev Change the pricing plan of service fee to be paid in NOKU tokens.
    * @param _pricingPlan The pricing plan of NOKU token to be paid, zero means flat subscription.
    */
    function setPricingPlan(address _pricingPlan) public onlyServiceProvider {
        require(_pricingPlan != 0, "_pricingPlan is 0");
        require(_pricingPlan != address(pricingPlan), "_pricingPlan == pricingPlan");

        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: contracts/NokuTokenBurner.sol

contract BurnableERC20 is ERC20 {
    function burn(uint256 amount) public returns (bool burned);
}

/**
* @dev The NokuTokenBurner contract has the responsibility to burn the configured fraction of received
* ERC20-compliant tokens and distribute the remainder to the configured wallet.
*/
contract NokuTokenBurner is Pausable {
    using SafeMath for uint256;

    event LogNokuTokenBurnerCreated(address indexed caller, address indexed wallet);
    event LogBurningPercentageChanged(address indexed caller, uint256 indexed burningPercentage);

    // The wallet receiving the unburnt tokens.
    address public wallet;

    // The percentage of tokens to burn after being received (range [0, 100])
    uint256 public burningPercentage;

    // The cumulative amount of burnt tokens.
    uint256 public burnedTokens;

    // The cumulative amount of tokens transferred back to the wallet.
    uint256 public transferredTokens;

    /**
    * @dev Create a new NokuTokenBurner with predefined burning fraction.
    * @param _wallet The wallet receiving the unburnt tokens.
    */
    constructor(address _wallet) public {
        require(_wallet != address(0), "_wallet is zero");
        
        wallet = _wallet;
        burningPercentage = 100;

        emit LogNokuTokenBurnerCreated(msg.sender, _wallet);
    }

    /**
    * @dev Change the percentage of tokens to burn after being received.
    * @param _burningPercentage The percentage of tokens to be burnt.
    */
    function setBurningPercentage(uint256 _burningPercentage) public onlyOwner {
        require(0 <= _burningPercentage && _burningPercentage <= 100, "_burningPercentage not in [0, 100]");
        require(_burningPercentage != burningPercentage, "_burningPercentage equal to current one");
        
        burningPercentage = _burningPercentage;

        emit LogBurningPercentageChanged(msg.sender, _burningPercentage);
    }

    /**
    * @dev Called after burnable tokens has been transferred for burning.
    * @param _token THe extended ERC20 interface supported by the sent tokens.
    * @param _amount The amount of burnable tokens just arrived ready for burning.
    */
    function tokenReceived(address _token, uint256 _amount) public whenNotPaused {
        require(_token != address(0), "_token is zero");
        require(_amount > 0, "_amount is zero");

        uint256 amountToBurn = _amount.mul(burningPercentage).div(100);
        if (amountToBurn > 0) {
            assert(BurnableERC20(_token).burn(amountToBurn));
            
            burnedTokens = burnedTokens.add(amountToBurn);
        }

        uint256 amountToTransfer = _amount.sub(amountToBurn);
        if (amountToTransfer > 0) {
            assert(BurnableERC20(_token).transfer(wallet, amountToTransfer));

            transferredTokens = transferredTokens.add(amountToTransfer);
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/TokenVesting.sol

/* solium-disable security/no-block-members */

pragma solidity ^0.4.23;






/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts 
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

// File: contracts/NokuCustomERC20.sol

/**
* @dev The NokuCustomERC20Token contract is a custom ERC20-compliant token available in the Noku Service Platform (NSP).
* The Noku customer is able to choose the token name, symbol, decimals, initial supply and to administer its lifecycle
* by minting or burning tokens in order to increase or decrease the token supply.
*/
contract NokuCustomERC20 is NokuCustomToken, DetailedERC20, MintableToken, BurnableToken {
    using SafeMath for uint256;

    event LogNokuCustomERC20Created(
        address indexed caller,
        string indexed name,
        string indexed symbol,
        uint8 decimals,
        uint256 transferableFromBlock,
        uint256 lockEndBlock,
        address pricingPlan,
        address serviceProvider
    );
    event LogMintingFeeEnabledChanged(address indexed caller, bool indexed mintingFeeEnabled);
    event LogInformationChanged(address indexed caller, string name, string symbol);
    event LogTransferFeePaymentFinished(address indexed caller);
    event LogTransferFeePercentageChanged(address indexed caller, uint256 indexed transferFeePercentage);

    // Flag indicating if minting fees are enabled or disabled
    bool public mintingFeeEnabled;

    // Block number from which tokens are initially transferable
    uint256 public transferableFromBlock;

    // Block number from which initial lock ends
    uint256 public lockEndBlock;

    // The initially locked balances by address
    mapping (address => uint256) public initiallyLockedBalanceOf;

    // The fee percentage for Custom Token transfer or zero if transfer is free of charge
    uint256 public transferFeePercentage;

    // Flag indicating if fee payment in Custom Token transfer has been permanently finished or not. 
    bool public transferFeePaymentFinished;

    // Address of optional Timelock smart contract, otherwise 0x0
    TokenTimelock public timelock;

    // Address of optional Vesting smart contract, otherwise 0x0
    TokenVesting public vesting;

    bytes32 public constant BURN_SERVICE_NAME     = "NokuCustomERC20.burn";
    bytes32 public constant MINT_SERVICE_NAME     = "NokuCustomERC20.mint";
    bytes32 public constant TIMELOCK_SERVICE_NAME = "NokuCustomERC20.timelock";
    bytes32 public constant VESTING_SERVICE_NAME  = "NokuCustomERC20.vesting";

    modifier canTransfer(address _from, uint _value) {
        require(block.number >= transferableFromBlock, "token not transferable");

        if (block.number < lockEndBlock) {
            uint256 locked = lockedBalanceOf(_from);
            if (locked > 0) {
                uint256 newBalance = balanceOf(_from).sub(_value);
                require(newBalance >= locked, "_value exceeds locked amount");
            }
        }
        _;
    }

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _transferableFromBlock,
        uint256 _lockEndBlock,
        address _pricingPlan,
        address _serviceProvider
    )
    NokuCustomToken(_pricingPlan, _serviceProvider)
    DetailedERC20(_name, _symbol, _decimals) public
    {
        require(bytes(_name).length > 0, "_name is empty");
        require(bytes(_symbol).length > 0, "_symbol is empty");
        require(_lockEndBlock >= _transferableFromBlock, "_lockEndBlock lower than _transferableFromBlock");

        transferableFromBlock = _transferableFromBlock;
        lockEndBlock = _lockEndBlock;
        mintingFeeEnabled = true;

        emit LogNokuCustomERC20Created(
            msg.sender,
            _name,
            _symbol,
            _decimals,
            _transferableFromBlock,
            _lockEndBlock,
            _pricingPlan,
            _serviceProvider
        );
    }

    function setMintingFeeEnabled(bool _mintingFeeEnabled) public onlyOwner returns(bool successful) {
        require(_mintingFeeEnabled != mintingFeeEnabled, "_mintingFeeEnabled == mintingFeeEnabled");

        mintingFeeEnabled = _mintingFeeEnabled;

        emit LogMintingFeeEnabledChanged(msg.sender, _mintingFeeEnabled);

        return true;
    }

    /**
    * @dev Change the Custom Token detailed information after creation.
    * @param _name The name to assign to the Custom Token.
    * @param _symbol The symbol to assign to the Custom Token.
    */
    function setInformation(string _name, string _symbol) public onlyOwner returns(bool successful) {
        require(bytes(_name).length > 0, "_name is empty");
        require(bytes(_symbol).length > 0, "_symbol is empty");

        name = _name;
        symbol = _symbol;

        emit LogInformationChanged(msg.sender, _name, _symbol);

        return true;
    }

    /**
    * @dev Stop trasfer fee payment for tokens.
    * @return true if the operation was successful.
    */
    function finishTransferFeePayment() public onlyOwner returns(bool finished) {
        require(!transferFeePaymentFinished, "transfer fee finished");

        transferFeePaymentFinished = true;

        emit LogTransferFeePaymentFinished(msg.sender);

        return true;
    }

    /**
    * @dev Change the transfer fee percentage to be paid in Custom tokens.
    * @param _transferFeePercentage The fee percentage to be paid for transfer in range [0, 100].
    */
    function setTransferFeePercentage(uint256 _transferFeePercentage) public onlyOwner {
        require(0 <= _transferFeePercentage && _transferFeePercentage <= 100, "_transferFeePercentage not in [0, 100]");
        require(_transferFeePercentage != transferFeePercentage, "_transferFeePercentage equal to current value");

        transferFeePercentage = _transferFeePercentage;

        emit LogTransferFeePercentageChanged(msg.sender, _transferFeePercentage);
    }

    function lockedBalanceOf(address _to) public view returns(uint256 locked) {
        uint256 initiallyLocked = initiallyLockedBalanceOf[_to];
        if (block.number >= lockEndBlock) return 0;
        else if (block.number <= transferableFromBlock) return initiallyLocked;

        uint256 releaseForBlock = initiallyLocked.div(lockEndBlock.sub(transferableFromBlock));
        uint256 released = block.number.sub(transferableFromBlock).mul(releaseForBlock);
        return initiallyLocked.sub(released);
    }

    /**
    * @dev Get the fee to be paid for the transfer of NOKU tokens.
    * @param _value The amount of NOKU tokens to be transferred.
    */
    function transferFee(uint256 _value) public view returns(uint256 usageFee) {
        return _value.mul(transferFeePercentage).div(100);
    }

    /**
    * @dev Check if token transfer is free of any charge or not.
    * @return true if transfer is free of any charge.
    */
    function freeTransfer() public view returns (bool isTransferFree) {
        return transferFeePaymentFinished || transferFeePercentage == 0;
    }

    /**
    * @dev Override #transfer for optionally paying fee to Custom token owner.
    */
    function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns(bool transferred) {
        if (freeTransfer()) {
            return super.transfer(_to, _value);
        }
        else {
            uint256 usageFee = transferFee(_value);
            uint256 netValue = _value.sub(usageFee);

            bool feeTransferred = super.transfer(owner, usageFee);
            bool netValueTransferred = super.transfer(_to, netValue);

            return feeTransferred && netValueTransferred;
        }
    }

    /**
    * @dev Override #transferFrom for optionally paying fee to Custom token owner.
    */
    function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns(bool transferred) {
        if (freeTransfer()) {
            return super.transferFrom(_from, _to, _value);
        }
        else {
            uint256 usageFee = transferFee(_value);
            uint256 netValue = _value.sub(usageFee);

            bool feeTransferred = super.transferFrom(_from, owner, usageFee);
            bool netValueTransferred = super.transferFrom(_from, _to, netValue);

            return feeTransferred && netValueTransferred;
        }
    }

    /**
    * @dev Burn a specific amount of tokens, paying the service fee.
    * @param _amount The amount of token to be burned.
    */
    function burn(uint256 _amount) public canBurn {
        require(_amount > 0, "_amount is zero");

        super.burn(_amount);

        require(pricingPlan.payFee(BURN_SERVICE_NAME, _amount, msg.sender), "burn fee failed");
    }

    /**
    * @dev Mint a specific amount of tokens, paying the service fee.
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns(bool minted) {
        require(_to != 0, "_to is zero");
        require(_amount > 0, "_amount is zero");

        super.mint(_to, _amount);

        if (mintingFeeEnabled) {
            require(pricingPlan.payFee(MINT_SERVICE_NAME, _amount, msg.sender), "mint fee failed");
        }

        return true;
    }

    /**
    * @dev Mint new locked tokens, which will unlock progressively.
    * @param _to The address that will receieve the minted locked tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mintLocked(address _to, uint256 _amount) public onlyOwner canMint returns(bool minted) {
        initiallyLockedBalanceOf[_to] = initiallyLockedBalanceOf[_to].add(_amount);

        return mint(_to, _amount);
    }

    /**
     * @dev Mint the specified amount of timelocked tokens.
     * @param _to The address that will receieve the minted locked tokens.
     * @param _amount The amount of tokens to mint.
     * @param _releaseTime The token release time as timestamp from Unix epoch.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime) public onlyOwner canMint
    returns(bool minted)
    {
        require(timelock == address(0), "TokenTimelock already activated");

        timelock = new TokenTimelock(this, _to, _releaseTime);

        minted = mint(timelock, _amount);

        require(pricingPlan.payFee(TIMELOCK_SERVICE_NAME, _amount, msg.sender), "timelock fee failed");
    }

    /**
    * @dev Mint the specified amount of vested tokens.
    * @param _to The address that will receieve the minted vested tokens.
    * @param _amount The amount of tokens to mint.
    * @param _startTime When the vesting starts as timestamp in seconds from Unix epoch.
    * @param _duration The duration in seconds of the period in which the tokens will vest.
    * @return A boolean that indicates if the operation was successful.
    */
    function mintVested(address _to, uint256 _amount, uint256 _startTime, uint256 _duration) public onlyOwner canMint
    returns(bool minted)
    {
        require(vesting == address(0), "TokenVesting already activated");

        vesting = new TokenVesting(_to, _startTime, 0, _duration, true);

        minted = mint(vesting, _amount);

        require(pricingPlan.payFee(VESTING_SERVICE_NAME, _amount, msg.sender), "vesting fee failed");
    }

    /**
     * @dev Release vested tokens to the beneficiary. Anyone can release vested tokens.
    * @return A boolean that indicates if the operation was successful.
     */
    function releaseVested() public returns(bool released) {
        require(vesting != address(0), "TokenVesting not activated");

        vesting.release(this);

        return true;
    }

    /**
     * @dev Revoke vested tokens. Just the token can revoke because it is the vesting owner.
    * @return A boolean that indicates if the operation was successful.
     */
    function revokeVested() public onlyOwner returns(bool revoked) {
        require(vesting != address(0), "TokenVesting not activated");

        vesting.revoke(this);

        return true;
    }
}

// File: contracts/TokenCappedCrowdsale.sol

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowsdale with a max amount of funds raised
 */
contract TokenCappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    // The maximum token cap, should be initialized in derived contract
    uint256 public tokenCap;

    // Overriding Crowdsale#hasEnded to add tokenCap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = soldTokens >= tokenCap;
        return super.hasEnded() || capReached;
    }

    // Overriding Crowdsale#isValidPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function isValidPurchase(address beneficiary) internal view returns (bool isValid) {
        uint256 tokenAmount = calculateTokens(msg.value);
        bool withinCap = soldTokens.add(tokenAmount) <= tokenCap;
        return withinCap && super.isValidPurchase(beneficiary);
    }
}

// File: contracts/NokuCustomCrowdsale.sol

/**
 * @title NokuCustomCrowdsale
 * @dev Extension of TokenCappedCrowdsale using values specific for Noku Custom ICO crowdsale
 */
contract NokuCustomCrowdsale is TokenCappedCrowdsale {
    using AddressUtils for address;
    using SafeMath for uint256;

    event LogNokuCustomCrowdsaleCreated(
        address sender,
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        address indexed wallet
    );
    event LogThreePowerAgesChanged(
        address indexed sender,
        uint256 indexed platinumAgeEndBlock,
        uint256 indexed goldenAgeEndBlock,
        uint256 silverAgeEndBlock,
        uint256 platinumAgeRate,
        uint256 goldenAgeRate,
        uint256 silverAgeRate
    );
    event LogTwoPowerAgesChanged(
        address indexed sender,
        uint256 indexed platinumAgeEndBlock,
        uint256 indexed goldenAgeEndBlock,
        uint256 platinumAgeRate,
        uint256 goldenAgeRate
    );
    event LogOnePowerAgeChanged(address indexed sender, uint256 indexed platinumAgeEndBlock, uint256 indexed platinumAgeRate);

    // The end block of the &#39;platinum&#39; age interval
    uint256 public platinumAgeEndBlock;

    // The end block of the &#39;golden&#39; age interval
    uint256 public goldenAgeEndBlock;

    // The end block of the &#39;silver&#39; age interval
    uint256 public silverAgeEndBlock;

    // The conversion rate of the &#39;platinum&#39; age
    uint256 public platinumAgeRate;

    // The conversion rate of the &#39;golden&#39; age
    uint256 public goldenAgeRate;

    // The conversion rate of the &#39;silver&#39; age
    uint256 public silverAgeRate;

    // The wallet address or contract
    address public wallet;

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rate,
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        address _token,
        uint256 _tokenMaximumSupply,
        address _wallet
    )
    Crowdsale(
        _startBlock,
        _endBlock,
        _rate,
        _minDeposit,
        _maxWhitelistLength,
        _whitelistThreshold
    )
    public {
        require(_token.isContract(), "_token is not contract");
        require(_tokenMaximumSupply > 0, "_tokenMaximumSupply is zero");

        platinumAgeRate = _rate;
        goldenAgeRate = _rate;
        silverAgeRate = _rate;

        token = NokuCustomERC20(_token);
        wallet = _wallet;

        // Assume predefined token supply has been minted and calculate the maximum number of tokens that can be sold
        tokenCap = _tokenMaximumSupply.sub(token.totalSupply());

        emit LogNokuCustomCrowdsaleCreated(msg.sender, startBlock, endBlock, _wallet);
    }

    function setThreePowerAges(
        uint256 _platinumAgeEndBlock,
        uint256 _goldenAgeEndBlock,
        uint256 _silverAgeEndBlock,
        uint256 _platinumAgeRate,
        uint256 _goldenAgeRate,
        uint256 _silverAgeRate
    )
    external onlyOwner beforeStart
    {
        require(startBlock <= _platinumAgeEndBlock, "_platinumAgeEndBlock lower than start block");
        require(_platinumAgeEndBlock <= _goldenAgeEndBlock, "_platinumAgeEndBlock greater than _goldenAgeEndBlock");
        require(_goldenAgeEndBlock <= _silverAgeEndBlock, "_silverAgeEndBlock lower than _goldenAgeEndBlock");
        require(_silverAgeEndBlock <= endBlock, "_silverAgeEndBlock greater than end block");
        require(_platinumAgeRate >= _goldenAgeRate, "_platinumAgeRate lower than _goldenAgeRate");
        require(_goldenAgeRate >= _silverAgeRate, "_goldenAgeRate lower than _silverAgeRate");
        require(_silverAgeRate >= rate, "_silverAgeRate lower than nominal rate");

        platinumAgeEndBlock = _platinumAgeEndBlock;
        goldenAgeEndBlock = _goldenAgeEndBlock;
        silverAgeEndBlock = _silverAgeEndBlock;

        platinumAgeRate = _platinumAgeRate;
        goldenAgeRate = _goldenAgeRate;
        silverAgeRate = _silverAgeRate;

        emit LogThreePowerAgesChanged(
            msg.sender,
            _platinumAgeEndBlock,
            _goldenAgeEndBlock,
            _silverAgeEndBlock,
            _platinumAgeRate,
            _goldenAgeRate,
            _silverAgeRate
        );
    }

    function setTwoPowerAges(
        uint256 _platinumAgeEndBlock,
        uint256 _goldenAgeEndBlock,
        uint256 _platinumAgeRate,
        uint256 _goldenAgeRate
    )
    external onlyOwner beforeStart
    {
        require(startBlock <= _platinumAgeEndBlock, "_platinumAgeEndBlock lower than start block");
        require(_platinumAgeEndBlock <= _goldenAgeEndBlock, "_platinumAgeEndBlock greater than _goldenAgeEndBlock");
        require(_goldenAgeEndBlock <= endBlock, "_goldenAgeEndBlock greater than end block");
        require(_platinumAgeRate >= _goldenAgeRate, "_platinumAgeRate lower than _goldenAgeRate");
        require(_goldenAgeRate >= rate, "_goldenAgeRate lower than nominal rate");

        platinumAgeEndBlock = _platinumAgeEndBlock;
        goldenAgeEndBlock = _goldenAgeEndBlock;

        platinumAgeRate = _platinumAgeRate;
        goldenAgeRate = _goldenAgeRate;

        emit LogTwoPowerAgesChanged(
            msg.sender,
            _platinumAgeEndBlock,
            _goldenAgeEndBlock,
            _platinumAgeRate,
            _goldenAgeRate
        );
    }

    function setOnePowerAge(uint256 _platinumAgeEndBlock, uint256 _platinumAgeRate)
    external onlyOwner beforeStart
    {
        require(startBlock <= _platinumAgeEndBlock, "_platinumAgeEndBlock lower than start block");
        require(_platinumAgeEndBlock <= endBlock, "_platinumAgeEndBlock greater than end block");
        require(_platinumAgeRate >= rate, "_platinumAgeRate lower than nominal rate");

        platinumAgeEndBlock = _platinumAgeEndBlock;
        platinumAgeRate = _platinumAgeRate;

        emit LogOnePowerAgeChanged(msg.sender, _platinumAgeEndBlock, _platinumAgeRate);
    }

    // Overriding Crowdsale#calculateTokens to apply age discounts to token calculus.
    function calculateTokens(uint256 amount) internal view returns(uint256 tokenAmount) {
        uint256 conversionRate = block.number <= platinumAgeEndBlock ? platinumAgeRate :
            block.number <= goldenAgeEndBlock ? goldenAgeRate :
            block.number <= silverAgeEndBlock ? silverAgeRate :
            rate;

        return amount.mul(conversionRate);
    }

    /**
     * @dev Overriding Crowdsale#distributeTokens to apply age rules to token distributions.
     */
    function distributeTokens(address beneficiary, uint256 tokenAmount) internal {
        if (block.number <= platinumAgeEndBlock) {
            NokuCustomERC20(token).mintLocked(beneficiary, tokenAmount);
        }
        else {
            super.distributeTokens(beneficiary, tokenAmount);
        }
    }

    /**
     * @dev Overriding Crowdsale#forwardFunds to split net/fee payment.
     */
    function forwardFunds(uint256 amount) internal {
        wallet.transfer(amount);
    }
}

// File: contracts/NokuCustomService.sol

contract NokuCustomService is Pausable {
    using AddressUtils for address;

    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers
    NokuPricingPlan public pricingPlan;

    constructor(address _pricingPlan) internal {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");

        pricingPlan = NokuPricingPlan(_pricingPlan);
    }

    function setPricingPlan(address _pricingPlan) public onlyOwner {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");
        require(NokuPricingPlan(_pricingPlan) != pricingPlan, "_pricingPlan equal to current");
        
        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: contracts/NokuCustomCrowdsaleService.sol

/**
 * @title NokuCustomCrowdsaleService
 * @dev Extension of NokuCustomService adding the fee payment in NOKU tokens.
 */
contract NokuCustomCrowdsaleService is NokuCustomService {
    event LogNokuCustomCrowdsaleServiceCreated(address indexed caller);

    bytes32 public constant SERVICE_NAME = "NokuCustomERC20.crowdsale";
    uint256 public constant CREATE_AMOUNT = 1 * 10**18;

    constructor(address _pricingPlan) NokuCustomService(_pricingPlan) public {
        emit LogNokuCustomCrowdsaleServiceCreated(msg.sender);
    }

    function createCustomCrowdsale(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rate,
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        address _token,
        uint256 _tokenMaximumSupply,
        address _wallet
    )
    public returns(NokuCustomCrowdsale customCrowdsale)
    {
        customCrowdsale = new NokuCustomCrowdsale(
            _startBlock,
            _endBlock,
            _rate,
            _minDeposit,
            _maxWhitelistLength,
            _whitelistThreshold,
            _token,
            _tokenMaximumSupply,
            _wallet
        );

        // Transfer NokuCustomCrowdsale ownership to the client
        customCrowdsale.transferOwnership(msg.sender);

        require(pricingPlan.payFee(SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }
}