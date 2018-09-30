pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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

// File: openzeppelin-solidity/contracts/payment/Escrow.sol

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds destinated to a payee until they
 * withdraw them. The contract that uses the escrow as its payment method
 * should be its owner, and provide public methods redirecting to the escrow&#39;s
 * deposit and withdraw.
 */
contract Escrow is Ownable {
  using SafeMath for uint256;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) private deposits;

  function depositsOf(address _payee) public view returns (uint256) {
    return deposits[_payee];
  }

  /**
  * @dev Stores the sent amount as credit to be withdrawn.
  * @param _payee The destination address of the funds.
  */
  function deposit(address _payee) public onlyOwner payable {
    uint256 amount = msg.value;
    deposits[_payee] = deposits[_payee].add(amount);

    emit Deposited(_payee, amount);
  }

  /**
  * @dev Withdraw accumulated balance for a payee.
  * @param _payee The address whose funds will be withdrawn and transferred to.
  */
  function withdraw(address _payee) public onlyOwner {
    uint256 payment = deposits[_payee];
    assert(address(this).balance >= payment);

    deposits[_payee] = 0;

    _payee.transfer(payment);

    emit Withdrawn(_payee, payment);
  }
}

// File: openzeppelin-solidity/contracts/payment/ConditionalEscrow.sol

/**
 * @title ConditionalEscrow
 * @dev Base abstract escrow to only allow withdrawal if a condition is met.
 */
contract ConditionalEscrow is Escrow {
  /**
  * @dev Returns whether an address is allowed to withdraw their funds. To be
  * implemented by derived contracts.
  * @param _payee The destination address of the funds.
  */
  function withdrawalAllowed(address _payee) public view returns (bool);

  function withdraw(address _payee) public {
    require(withdrawalAllowed(_payee));
    super.withdraw(_payee);
  }
}

// File: openzeppelin-solidity/contracts/payment/RefundEscrow.sol

/**
 * @title RefundEscrow
 * @dev Escrow that holds funds for a beneficiary, deposited from multiple parties.
 * The contract owner may close the deposit period, and allow for either withdrawal
 * by the beneficiary, or refunds to the depositors.
 */
contract RefundEscrow is Ownable, ConditionalEscrow {
  enum State { Active, Refunding, Closed }

  event Closed();
  event RefundsEnabled();

  State public state;
  address public beneficiary;

  /**
   * @dev Constructor.
   * @param _beneficiary The beneficiary of the deposits.
   */
  constructor(address _beneficiary) public {
    require(_beneficiary != address(0));
    beneficiary = _beneficiary;
    state = State.Active;
  }

  /**
   * @dev Stores funds that may later be refunded.
   * @param _refundee The address funds will be sent to if a refund occurs.
   */
  function deposit(address _refundee) public payable {
    require(state == State.Active);
    super.deposit(_refundee);
  }

  /**
   * @dev Allows for the beneficiary to withdraw their funds, rejecting
   * further deposits.
   */
  function close() public onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
  }

  /**
   * @dev Allows for refunds to take place, rejecting further deposits.
   */
  function enableRefunds() public onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @dev Withdraws the beneficiary&#39;s funds.
   */
  function beneficiaryWithdraw() public {
    require(state == State.Closed);
    beneficiary.transfer(address(this).balance);
  }

  /**
   * @dev Returns whether refundees can withdraw their deposits (be refunded).
   */
  function withdrawalAllowed(address _payee) public view returns (bool) {
    return state == State.Refunding;
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
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropriate to concatenate
 * behavior.
 */
contract Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    // Amount tokens Sold
    uint256 public tokensSold;
    
    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
    * @param _rate Number of token units a buyer gets per wei
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    */
    constructor(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        _preValidatePurchase(_beneficiary, weiAmount, tokens);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _updatePurchasingState(_beneficiary, weiAmount, tokens);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount, tokens);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
    * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method: 
    *   super._preValidatePurchase(_beneficiary, _weiAmount);
    *   require(weiRaised.add(_weiAmount) <= cap);
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    * @param _tokenAmount Value in token involved in the purchase
    */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
    * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    * @param _tokenAmount Value in token involved in the purchase
    */
    function _postValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        // optional override
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
    * @param _beneficiary Address receiving the tokens
    * @param _weiAmount Value in wei involved in the purchase
    * @param _tokenAmount Value in token involved in the purchase
    */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        // optional override
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return _weiAmount.mul(rate);
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

// File: contracts/crowdsale/validation/TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

    /**
    * @dev Reverts if not in crowdsale time range.
    */
    modifier onlyWhileOpen {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

    /**
    * @dev Constructor, takes crowdsale opening and closing times.
    * @param _openingTime Crowdsale opening time
    * @param _closingTime Crowdsale closing time
    */
    constructor(uint256 _openingTime, uint256 _closingTime) public {
        // solium-disable-next-line security/no-block-members
        require(_openingTime >= block.timestamp);
        require(_closingTime > _openingTime);

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
    * @dev Checks whether the period in which the crowdsale is open has already elapsed.
    * @return Whether crowdsale period has elapsed
    */
    function hasClosed() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > closingTime;
    }

    /**
    * @dev Extend parent behavior requiring to be within contributing period
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    * @param _tokenAmount Amount of token purchased
    */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
        onlyWhileOpen
    {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
    }

}

// File: contracts/crowdsale/validation/MilestoneCrowdsale.sol

/**
 * @title MilestoneCrowdsale
 * @dev Crowdsale with multiple milestones separated by time and cap
 * @author Nikola Wyatt <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="66080f0d090a0748111f07121226000909020807120f0908480f09">[email&#160;protected]</a>>
 */
contract MilestoneCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    uint256 public constant MAX_MILESTONE = 10;

    /**
    * Define pricing schedule using milestones.
    */
    struct Milestone {

        // Milestone index in array
        uint256 index;

        // UNIX timestamp when this milestone starts
        uint256 startTime;

        // Amount of tokens sold in milestone
        uint256 tokensSold;

        // Maximum amount of Tokens accepted in the current Milestone.
        uint256 cap;

        // How many tokens per wei you will get after this milestone has been passed
        uint256 rate;

    }

    /**
    * Store milestones in a fixed array, so that it can be seen in a blockchain explorer
    * Milestone 0 is always (0, 0)
    * (TODO: change this when we confirm dynamic arrays are explorable)
    */
    Milestone[10] public milestones;

    // How many active milestones have been created
    uint256 public milestoneCount = 0;


    bool public milestoningFinished = false;

    constructor(        
        uint256 _openingTime,
        uint256 _closingTime
        ) 
        TimedCrowdsale(_openingTime, _closingTime)
        public 
        {
        }

    /**
    * @dev Contruction, setting a list of milestones
    * @param _milestoneStartTime uint[] milestones start time 
    * @param _milestoneCap uint[] milestones cap 
    * @param _milestoneRate uint[] milestones price 
    */
    function setMilestonesList(uint256[] _milestoneStartTime, uint256[] _milestoneCap, uint256[] _milestoneRate) public {
        // Need to have tuples, length check
        require(!milestoningFinished);
        require(_milestoneStartTime.length > 0);
        require(_milestoneStartTime.length == _milestoneCap.length && _milestoneCap.length == _milestoneRate.length);
        require(_milestoneStartTime[0] == openingTime);
        require(_milestoneStartTime[_milestoneStartTime.length-1] < closingTime);

        for (uint iterator = 0; iterator < _milestoneStartTime.length; iterator++) {
            if (iterator > 0) {
                assert(_milestoneStartTime[iterator] > milestones[iterator-1].startTime);
            }
            milestones[iterator] = Milestone({
                index: iterator,
                startTime: _milestoneStartTime[iterator],
                tokensSold: 0,
                cap: _milestoneCap[iterator],
                rate: _milestoneRate[iterator]
            });
            milestoneCount++;
        }
        milestoningFinished = true;
    }

    /**
    * @dev Iterate through milestones. You reach end of milestones when rate = 0
    * @return tuple (time, rate)
    */
    function getMilestoneTimeAndRate(uint256 n) public view returns (uint256, uint256) {
        return (milestones[n].startTime, milestones[n].rate);
    }

    /**
    * @dev Checks whether the cap of a milestone has been reached.
    * @return Whether the cap was reached
    */
    function capReached(uint256 n) public view returns (bool) {
        return milestones[n].tokensSold >= milestones[n].cap;
    }

    /**
    * @dev Checks amount of tokens sold in milestone.
    * @return Amount of tokens sold in milestone
    */
    function getTokensSold(uint256 n) public view returns (uint256) {
        return milestones[n].tokensSold;
    }

    function getFirstMilestone() private view returns (Milestone) {
        return milestones[0];
    }

    function getLastMilestone() private view returns (Milestone) {
        return milestones[milestoneCount-1];
    }

    function getFirstMilestoneStartsAt() public view returns (uint256) {
        return getFirstMilestone().startTime;
    }

    function getLastMilestoneStartsAt() public view returns (uint256) {
        return getLastMilestone().startTime;
    }

    /**
    * @dev Get the current milestone or bail out if we are not in the milestone periods.
    * @return {[type]} [description]
    */
    function getCurrentMilestoneIndex() internal view onlyWhileOpen returns  (uint256) {
        uint256 index;

        // Found the current milestone by evaluating time. 
        // If (now < next start) the current milestone is the previous
        // Stops loop if finds current
        for(uint i = 0; i < milestoneCount; i++) {
            index = i;
            // solium-disable-next-line security/no-block-members
            if(block.timestamp < milestones[i].startTime) {
                index = i - 1;
                break;
            }
        }

        // For the next code, you may ask why not assert if last milestone surpass cap...
        // Because if its last and it is capped we would like to finish not sell any more tokens 
        // Check if the current milestone has reached it&#39;s cap
        if (milestones[index].tokensSold > milestones[index].cap) {
            index = index + 1;
        }

        return index;
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect the funding cap from the currentMilestone.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    * @param _tokenAmount Amount of token purchased
    
    */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(milestones[getCurrentMilestoneIndex()].tokensSold.add(_tokenAmount) <= milestones[getCurrentMilestoneIndex()].cap);
    }

    /**
    * @dev Extend parent behavior to update current milestone state and index
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    * @param _tokenAmount Amount of token purchased
    */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        super._updatePurchasingState(_beneficiary, _weiAmount, _tokenAmount);
        milestones[getCurrentMilestoneIndex()].tokensSold = milestones[getCurrentMilestoneIndex()].tokensSold.add(_tokenAmount);
    }

    /**
    * @dev Get the current price.
    * @return The current price or 0 if we are outside milestone period
    */
    function getCurrentRate() internal view returns (uint result) {
        return milestones[getCurrentMilestoneIndex()].rate;
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return _weiAmount.mul(getCurrentRate());
    }

}

// File: contracts/price/USDPrice.sol

/**
* @title USDPrice
* @dev Contract that calculates the price of tokens in USD cents.
* Note that this contracts needs to be updated
*/
contract USDPrice is Ownable {

    using SafeMath for uint256;

    // PRICE of 1 ETHER in USD in cents
    // So, if price is: $271.90, the value in variable will be: 27190
    uint256 public ETHUSD;

    // Time of Last Updated Price
    uint256 public updatedTime;

    // Historic price of ETH in USD in cents
    mapping (uint256 => uint256) public priceHistory;

    event PriceUpdated(uint256 price);

    constructor() public {
    }

    function getHistoricPrice(uint256 time) public view returns (uint256) {
        return priceHistory[time];
    } 

    function updatePrice(uint256 price) public onlyOwner {
        require(price > 0);

        priceHistory[updatedTime] = ETHUSD;

        ETHUSD = price;
        // solium-disable-next-line security/no-block-members
        updatedTime = block.timestamp;

        emit PriceUpdated(ETHUSD);
    }

    /**
    * @dev Override to extend the way in which ether is converted to USD.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return The value of wei amount in USD cents
    */
    function getPrice(uint256 _weiAmount)
        public view returns (uint256)
    {
        return _weiAmount.mul(ETHUSD);
    }
    
}

// File: contracts/PreSale.sol

interface MintableERC20 {
    function mint(address _to, uint256 _amount) public returns (bool);
}
/**
 * @title PreSale
 * @dev Crowdsale accepting contributions only within a time frame, 
 * having milestones defined, the price is defined in USD
 * having a mechanism to refund sales if soft cap not capReached();
 * And an escrow to support the refund.
 */
contract PreSale is Ownable, Crowdsale, MilestoneCrowdsale {
    using SafeMath for uint256;

    /// Max amount of tokens to be contributed
    uint256 public cap;

    /// Minimum amount of wei per contribution
    uint256 public minimumContribution;

    /// minimum amount of funds to be raised in weis
    uint256 public goal;
    
    bool public isFinalized = false;

    /// refund escrow used to hold funds while crowdsale is running
    RefundEscrow private escrow;

    USDPrice private usdPrice; 

    event Finalized();

    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _goal,
        uint256 _cap,
        uint256 _minimumContribution,
        USDPrice _usdPrice
    )
        Crowdsale(_rate, _wallet, _token)
        MilestoneCrowdsale(_openingTime, _closingTime)
        public
    {  
        require(_cap > 0);
        require(_minimumContribution > 0);
        require(_goal > 0);
        
        cap = _cap;
        minimumContribution = _minimumContribution;

        escrow = new RefundEscrow(wallet);
        goal = _goal;
        usdPrice = _usdPrice;
    }


    /**
    * @dev Checks whether the cap has been reached.
    * @return Whether the cap was reached
    */
    function capReached() public view returns (bool) {
        return tokensSold >= cap;
    }

    /**
    * @dev Investors can claim refunds here if crowdsale is unsuccessful
    */
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        escrow.withdraw(msg.sender);
    }

    /**
    * @dev Checks whether funding goal was reached.
    * @return Whether funding goal was reached
    */
    function goalReached() public view returns (bool) {
        return tokensSold >= goal;
    }

    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() public onlyOwner {
        require(!isFinalized);
        require(goalReached() || hasClosed());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return usdPrice.getPrice(_weiAmount).div(getCurrentRate());
    }

    /**
    * @dev Extend parent behavior sending heartbeat to token.
    * @param _beneficiary Address receiving the tokens
    * @param _weiAmount Value in wei involved in the purchase
    * @param _tokenAmount Value in token involved in the purchase
    */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        super._updatePurchasingState(_beneficiary, _weiAmount, _tokenAmount);
    }
    
    /**
    * @dev Overrides delivery by minting tokens upon purchase. - MINTED Crowdsale
    * @param _beneficiary Token purchaser
    * @param _tokenAmount Number of tokens to be minted
    */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        // Potentially dangerous assumption about the type of the token.
        require(MintableERC20(address(token)).mint(_beneficiary, _tokenAmount));
    }


    /**
    * @dev Extend parent behavior requiring purchase to respect the funding cap.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    * @param _tokenAmount Amount of token purchased
    */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokenAmount
    )
        internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(_weiAmount >= minimumContribution);
        require(tokensSold.add(_tokenAmount) <= cap);
    }

    /**
    * @dev escrow finalization task, called when owner calls finalize()
    */
    function finalization() internal {
        if (goalReached()) {
            escrow.close();
            escrow.beneficiaryWithdraw();
        } else {
            escrow.enableRefunds();
        }
    }

    /**
    * @dev Overrides Crowdsale fund forwarding, sending funds to escrow.
    */
    function _forwardFunds() internal {
        escrow.deposit.value(msg.value)(msg.sender);
    }

}