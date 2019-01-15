pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/Administrable.sol

/**
 * @title Administrable
 * @dev Base contract extending Ownable with support for administration capabilities.
 */
contract Administrable is Ownable {

    event LogAdministratorAdded(address indexed caller, address indexed administrator);
    event LogAdministratorRemoved(address indexed caller, address indexed administrator);

    mapping (address => bool) private administrators;

    modifier onlyAdministrator() {
        require(administrators[msg.sender], "caller is not administrator");
        _;
    }

    constructor() internal {
        administrators[msg.sender] = true;

        emit LogAdministratorAdded(msg.sender, msg.sender);
    }

    /**
     * Add a new administrator to the list.
     * @param newAdministrator The administrator address to add.
     */
    function addAdministrator(address newAdministrator) public onlyOwner {
        require(newAdministrator != address(0), "newAdministrator is zero");
        require(!administrators[newAdministrator], "newAdministrator is already present");

        administrators[newAdministrator] = true;

        emit LogAdministratorAdded(msg.sender, newAdministrator);
    }

    /**
     * Remove an existing administrator from the list.
     * @param oldAdministrator The administrator address to remove.
     */
    function removeAdministrator(address oldAdministrator) public onlyOwner {
        require(oldAdministrator != address(0), "oldAdministrator is zero");
        require(administrators[oldAdministrator], "oldAdministrator is not present");

        administrators[oldAdministrator] = false;

        emit LogAdministratorRemoved(msg.sender, oldAdministrator);
    }

    /**
     * @return true if target address has administrator privileges, false otherwise
     */
    function isAdministrator(address target) public view returns(bool isReallyAdministrator) {
        return administrators[target];
    }

    /**
     * Transfer ownership taking administration privileges into account.
     * @param newOwner The new contract owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        administrators[msg.sender] = false;
        emit LogAdministratorRemoved(msg.sender, msg.sender);

        administrators[newOwner] = true;
        emit LogAdministratorAdded(msg.sender, newOwner);

        Ownable.transferOwnership(newOwner);
    }
}

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/MultipleBidReservation.sol

/**
 * A multiple-bid Reservation Contract (RC) for early deposit collection and manual token bid during
 * the Initial Coin Offering (ICO) crowdsale events.
 * The RC implements the following spec:
 * - investors allowed to simply send ethers to the RC address
 * - investors allowed to get refunded after ICO event if RC failed
 * - multiple bids using investor addresses performed by owner or authorized administator
 * - maximum cap on the total balance
 * - minimum threshold on each subscriber balance
 * - maximum number of subscribers
 * - optional whitelist with max deposit threshold for non-whitelisted subscribers
 * - kill switch callable by owner or authorized administator
 * - withdraw pattern for refunding
 * Just the RC owner or an authorized administator is allowed to shutdown the lifecycle halting the
 * RC; no bounties are provided.
 */
contract MultipleBidReservation is Administrable, Whitelistable {
    using SafeMath for uint256;

    event LogMultipleBidReservationCreated(
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        uint256 maxSubscribers,
        uint256 maxCap,
        uint256 minDeposit,
        uint256 maxWhitelistLength,
        uint256 indexed whitelistThreshold
    );
    event LogStartBlockChanged(uint256 indexed startBlock);
    event LogEndBlockChanged(uint256 indexed endBlock);
    event LogMaxCapChanged(uint256 indexed maxCap);
    event LogMinDepositChanged(uint256 indexed minDeposit);
    event LogMaxSubscribersChanged(uint256 indexed maxSubscribers);
    event LogCrowdsaleAddressChanged(address indexed crowdsale);
    event LogAbort(address indexed caller);
    event LogDeposit(
        address indexed subscriber,
        uint256 indexed amount,
        uint256 indexed balance,
        uint256 raisedFunds
    );
    event LogBuy(address caller, uint256 indexed from, uint256 indexed to);
    event LogRefund(address indexed subscriber, uint256 indexed amount, uint256 indexed raisedFunds);

    // The block interval [start, end] where investments are allowed (both inclusive)
    uint256 public startBlock;
    uint256 public endBlock;

    // RC maximum cap (expressed in wei)
    uint256 public maxCap;

    // RC minimum balance per subscriber (expressed in wei)
    uint256 public minDeposit;

    // RC maximum number of allowed subscribers
    uint256 public maxSubscribers;

    // Crowdsale public address
    TokenSale public crowdsale;

    // RC current raised balance expressed in wei
    uint256 public raisedFunds;

    // ERC20-compliant token issued during ICO
    ERC20 public token;

    // Reservation balances (expressed in wei) deposited by each subscriber
    mapping (address => uint256) public balances;

    // The list of subscribers in incoming order
    address[] public subscribers;

    // Flag indicating if reservation has been forcibly terminated
    bool public aborted;

    // The maximum value for whitelist threshold in wei
    uint256 constant public MAX_WHITELIST_THRESHOLD = 2**256 - 1;

    modifier beforeStart() {
        require(block.number < startBlock, "already started");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "already ended");
        _;
    }

    modifier whenReserving() {
        require(!aborted, "aborted");
        _;
    }

    modifier whenAborted() {
        require(aborted, "not aborted");
        _;
    }

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxSubscribers,
        uint256 _maxCap,
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold
    )
    Whitelistable(_maxWhitelistLength, _whitelistThreshold) public
    {
        require(_startBlock >= block.number, "_startBlock < current block");
        require(_endBlock >= _startBlock, "_endBlock < _startBlock");
        require(_maxSubscribers > 0, "_maxSubscribers is 0");
        require(_maxCap > 0, "_maxCap is 0");
        require(_minDeposit > 0, "_minDeposit is 0");

        startBlock = _startBlock;
        endBlock = _endBlock;
        maxSubscribers = _maxSubscribers;
        maxCap = _maxCap;
        minDeposit = _minDeposit;

        emit LogMultipleBidReservationCreated(
            startBlock,
            endBlock,
            maxSubscribers,
            maxCap,
            minDeposit,
            _maxWhitelistLength,
            _whitelistThreshold
        );
    }

    function hasStarted() public view returns(bool started) {
        return block.number >= startBlock;
    }

    function hasEnded() public view returns(bool ended) {
        return block.number > endBlock;
    }

    /**
     * @return The current number of RC subscribers
     */
    function numSubscribers() public view returns(uint256 numberOfSubscribers) {
        return subscribers.length;
    }

    /**
     * Change the RC start block number.
     * @param _startBlock The start block
     */
    function setStartBlock(uint256 _startBlock) external onlyOwner beforeStart whenReserving {
        require(_startBlock >= block.number, "_startBlock < current block");
        require(_startBlock <= endBlock, "_startBlock > endBlock");
        require(_startBlock != startBlock, "_startBlock == startBlock");

        startBlock = _startBlock;

        emit LogStartBlockChanged(_startBlock);
    }

    /**
     * Change the RC end block number.
     * @param _endBlock The end block
     */
    function setEndBlock(uint256 _endBlock) external onlyOwner beforeEnd whenReserving {
        require(_endBlock >= block.number, "_endBlock < current block");
        require(_endBlock >= startBlock, "_endBlock < startBlock");
        require(_endBlock != endBlock, "_endBlock == endBlock");

        endBlock = _endBlock;

        emit LogEndBlockChanged(_endBlock);
    }

    /**
     * Change the RC maximum cap. New value shall be at least equal to raisedFunds.
     * @param _maxCap The RC maximum cap, expressed in wei
     */
    function setMaxCap(uint256 _maxCap) external onlyOwner beforeEnd whenReserving {
        require(_maxCap > 0 && _maxCap >= raisedFunds, "invalid _maxCap");

        maxCap = _maxCap;

        emit LogMaxCapChanged(maxCap);
    }

    /**
     * Change the minimum deposit for each RC subscriber. New value shall be lower than previous.
     * @param _minDeposit The minimum deposit for each RC subscriber, expressed in wei
     */
    function setMinDeposit(uint256 _minDeposit) external onlyOwner beforeEnd whenReserving {
        require(_minDeposit > 0 && _minDeposit < minDeposit, "_minDeposit not in (0, minDeposit)");

        minDeposit = _minDeposit;

        emit LogMinDepositChanged(minDeposit);
    }

    /**
     * Change the maximum number of accepted RC subscribers. New value shall be at least equal to the current
     * number of subscribers.
     * @param _maxSubscribers The maximum number of subscribers
     */
    function setMaxSubscribers(uint256 _maxSubscribers) external onlyOwner beforeEnd whenReserving {
        require(_maxSubscribers > 0 && _maxSubscribers >= subscribers.length, "invalid _maxSubscribers");

        maxSubscribers = _maxSubscribers;

        emit LogMaxSubscribersChanged(maxSubscribers);
    }

    /**
     * Change the ICO crowdsale address.
     * @param _crowdsale The ICO crowdsale address
     */
    function setCrowdsaleAddress(address _crowdsale) external onlyOwner whenReserving {
        require(_crowdsale != address(0), "_crowdsale is 0");

        crowdsale = TokenSale(_crowdsale);

        emit LogCrowdsaleAddressChanged(_crowdsale);
    }

    /**
     * Change the maximum whitelist length. New value shall satisfy the #isAllowedWhitelist conditions.
     * @param _maxWhitelistLength The maximum whitelist length
     */
    function setMaxWhitelistLength(uint256 _maxWhitelistLength) external onlyOwner beforeEnd whenReserving {
        setMaxWhitelistLengthInternal(_maxWhitelistLength);
    }

    /**
     * Change the whitelist threshold balance. New value shall satisfy the #isAllowedWhitelist conditions.
     * @param _whitelistThreshold The threshold balance (in wei) above which whitelisting is required to invest
     */
    function setWhitelistThresholdBalance(uint256 _whitelistThreshold) external onlyOwner beforeEnd whenReserving {
        setWhitelistThresholdBalanceInternal(_whitelistThreshold);
    }

    /**
     * Add the subscriber to the whitelist.
     * @param _subscriber The subscriber to add to the whitelist.
     */
    function addToWhitelist(address _subscriber) external onlyOwner beforeEnd whenReserving {
        addToWhitelistInternal(_subscriber);
    }

    /**
     * Removed the subscriber from the whitelist.
     * @param _subscriber The subscriber to remove from the whitelist.
     */
    function removeFromWhitelist(address _subscriber) external onlyOwner beforeEnd whenReserving {
        removeFromWhitelistInternal(_subscriber, balances[_subscriber]);
    }

    /**
     * Abort the contract before the ICO start time. An administrator is allowed to use this &#39;kill switch&#39;
     * to deactivate any contract function except the investor refunding.
     */
    function abort() external onlyAdministrator whenReserving {
        aborted = true;

        emit LogAbort(msg.sender);
    }

    /**
     * Let the caller invest its money before the ICO start time.
     */
    function invest() external payable whenReserving {
        deposit(msg.sender, msg.value);
    }

    /**
     * Execute a batch of multiple bids into the ICO crowdsale.
     * @param _from The subscriber index, included, from which the batch starts.
     * @param _to The subscriber index, excluded, to which the batch ends.
     */
    function buy(uint256 _from, uint256 _to) external onlyAdministrator whenReserving {
        require(_from < _to, "_from >= _to");
        require(crowdsale != address(0), "crowdsale not set");
        require(subscribers.length > 0, "subscribers size is 0");
        require(hasEnded(), "not ended");

        uint to = _to > subscribers.length ? subscribers.length : _to;

        for (uint256 i=_from; i<to; i++) {
            address subscriber = subscribers[i];

            uint256 subscriberBalance = balances[subscriber];

            if (subscriberBalance > 0) {
                balances[subscriber] = 0;

                crowdsale.buyTokens.value(subscriberBalance)(subscriber);
            }
        }

        emit LogBuy(msg.sender, _from, _to);
    }

    /**
     * Refund the invested money to the caller after the RC termination.
     */
    function refund() external whenAborted {
        // Read the calling subscriber balance once
        uint256 subscriberBalance = balances[msg.sender];

        // Withdraw is allowed IFF the calling subscriber has not zero balance
        require(subscriberBalance > 0, "caller balance is 0");

        // Withdraw is allowed IFF the contract has some token balance
        require(raisedFunds > 0, "token balance is 0");

        // Safely decrease the total balance
        raisedFunds = raisedFunds.sub(subscriberBalance);

        // Clear the subscriber balance before transfer to prevent re-entrant attacks
        balances[msg.sender] = 0;

        emit LogRefund(msg.sender, subscriberBalance, raisedFunds);

        // Transfer the balance back to the calling subscriber or throws on error
        msg.sender.transfer(subscriberBalance);
    }

    /**
     * Allow investing by just sending money to the contract address.
     */
    function () external payable whenReserving {
        deposit(msg.sender, msg.value);
    }

    /**
     * Deposit the money amount for the beneficiary when RC is running.
     */
    function deposit(address beneficiary, uint256 amount) internal {
        // Deposit is allowed IFF the RC is currently running
        require(startBlock <= block.number && block.number <= endBlock, "not open");

        uint256 newRaisedFunds = raisedFunds.add(amount);

        // Deposit is allowed IFF the contract balance will not reach its maximum cap
        require(newRaisedFunds <= maxCap, "over max cap");

        uint256 currentBalance = balances[beneficiary];
        uint256 finalBalance = currentBalance.add(amount);

        // Deposit is allowed IFF investor deposit shall be at least equal to the minimum deposit threshold
        require(finalBalance >= minDeposit, "deposit < min deposit");

        // Balances over whitelist threshold are allowed IFF the sender is in whitelist
        require(isAllowedBalance(beneficiary, finalBalance), "balance not allowed");

        // Increase the subscriber count if sender does not have a balance yet
        if (currentBalance == 0) {
            // New subscribers are allowed IFF the contract has not yet the max number of subscribers
            require(subscribers.length < maxSubscribers, "max subscribers reached");

            subscribers.push(beneficiary);
        }

        // Add the received amount to the subscriber balance
        balances[beneficiary] = finalBalance;

        raisedFunds = newRaisedFunds;

        emit LogDeposit(beneficiary, amount, finalBalance, newRaisedFunds);
    }
}

// File: contracts/NokuCustomReservation.sol

/**
 * @title NokuCustomReservation
 * @dev Extension of MultipleBidReservation.
 */
contract NokuCustomReservation is MultipleBidReservation {
    event LogNokuCustomReservationCreated();

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxSubscribers,
        uint256 _maxCap,
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold
    )
    MultipleBidReservation(
        _startBlock,
        _endBlock,
        _maxSubscribers,
        _maxCap,
        _minDeposit,
        _maxWhitelistLength,
        _whitelistThreshold
    )
    public {
        emit LogNokuCustomReservationCreated();
    }
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
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
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
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
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

// File: contracts/NokuCustomReservationService.sol

/**
 * @title NokuCustomReservationService
 * @dev Extension of NokuCustomService adding the fee payment in NOKU tokens.
 */
contract NokuCustomReservationService is NokuCustomService {
    event LogNokuCustomReservationServiceCreated(address indexed caller);

    bytes32 public constant SERVICE_NAME = "NokuCustomERC20.reservation";
    uint256 public constant CREATE_AMOUNT = 1 * 10**18;

    constructor(address _pricingPlan) NokuCustomService(_pricingPlan) public {
        emit LogNokuCustomReservationServiceCreated(msg.sender);
    }

    function createCustomReservation(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxSubscribers,
        uint256 _maxCap,
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold
    )
    public returns(NokuCustomReservation customReservation)
    {
        customReservation = new NokuCustomReservation(
            _startBlock,
            _endBlock,
            _maxSubscribers,
            _maxCap,
            _minDeposit,
            _maxWhitelistLength,
            _whitelistThreshold
        );

        // Transfer NokuCustomReservation ownership to the client
        customReservation.transferOwnership(msg.sender);

        require(pricingPlan.payFee(SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }
}