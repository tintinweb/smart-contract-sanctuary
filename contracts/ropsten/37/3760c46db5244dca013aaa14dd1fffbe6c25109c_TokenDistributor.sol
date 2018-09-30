pragma solidity ^0.4.24;

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

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c5b7a0a8a6aa85f7">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by setting a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

// File: contracts/lifecycle/Finalizable.sol

/**
 * @title Finalizable contract
 * @dev Lifecycle extension where an owner can do extra work after finishing.
 */
contract Finalizable is Ownable {
  using SafeMath for uint256;

  /// @dev Throws if called before the contract is finalized.
  modifier onlyFinalized() {
    require(isFinalized, "Contract not finalized.");
    _;
  }

  /// @dev Throws if called after the contract is finalized.
  modifier onlyNotFinalized() {
    require(!isFinalized, "Contract already finalized.");
    _;
  }

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Called by owner to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() public onlyOwner onlyNotFinalized {
    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
    // override
  }

}

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

// File: contracts/payment/TokenEscrow.sol

/**
 * @title TokenEscrow
 * @dev Base token escrow contract, holds funds destinated to a payee until they
 * withdraw them. The contract that uses the escrow as its payment method
 * should be its owner, and provide public methods redirecting to the escrow&#39;s
 * deposit and withdraw.
 */
contract TokenEscrow is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event Deposited(address indexed payee, uint256 amount);
  event Withdrawn(address indexed payee, uint256 amount);

  // deposits of the beneficiaries of tokens
  mapping(address => uint256) private deposits;

  // ERC20 token contract being held
  ERC20 public token;

  constructor(ERC20 _token) public {
    require(_token != address(0), "Token address should not be 0x0.");
    token = _token;
  }

  /**
   * @dev Returns the token accumulated balance for a payee.
   * @param _payee The destination address of the tokens.
   */
  function depositsOf(address _payee) public view returns (uint256) {
    return deposits[_payee];
  }

  /**
   * @dev Stores the token amount as credit to be withdrawn.
   * @param _payee The destination address of the tokens.
   * @param _amount The amount of tokens that can be pulled.
   */
  function deposit(address _payee, uint256 _amount) public onlyOwner {
    require(_payee != address(0), "Destination address should not be 0x0.");
    require(_payee != address(this), "Deposits should not be made to this contract.");

    deposits[_payee] = deposits[_payee].add(_amount);
    token.safeTransferFrom(owner, this, _amount);

    emit Deposited(_payee, _amount);
  }

  /**
   * @dev Withdraw accumulated balance for a payee.
   * @param _payee The address whose tokens will be withdrawn and transferred to.
   */
  function withdraw(address _payee) public onlyOwner {
    uint256 payment = deposits[_payee];
    assert(token.balanceOf(address(this)) >= payment);

    deposits[_payee] = 0;
    token.safeTransfer(_payee, payment);

    emit Withdrawn(_payee, payment);
  }
}

// File: contracts/payment/TokenConditionalEscrow.sol

/**
 * @title ConditionalEscrow
 * @dev Base abstract escrow to only allow withdrawal if a condition is met.
 */
contract TokenConditionalEscrow is TokenEscrow {

  /**
   * @dev Returns whether an address is allowed to withdraw their tokens. To be
   * implemented by derived contracts.
   * @param _payee The destination address of the tokens.
   */
  function withdrawalAllowed(address _payee) public view returns (bool);

  /**
   * @dev Withdraw accumulated balance for a payee if allowed.
   * @param _payee The address whose tokens will be withdrawn and transferred to.
   */
  function withdraw(address _payee) public {
    require(withdrawalAllowed(_payee), "Withdrawal is not allowed.");
    super.withdraw(_payee);
  }
}

// File: contracts/payment/TokenTimelockEscrow.sol

/**
 * @title TokenTimelockEscrow
 * @dev Token escrow to only allow withdrawal only if the lock period
 * has expired. As only the owner can make deposits and withdrawals
 * this contract should be owned by the crowdsale, which can then
 * perform deposits and withdrawals for individual users.
 */
contract TokenTimelockEscrow is TokenConditionalEscrow {

  // timestamp when token release is enabled
  uint256 public releaseTime;

  constructor(uint256 _releaseTime) public {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp, "Release time should be in the future.");
    releaseTime = _releaseTime;
  }

  /**
   * @dev Returns whether an address is allowed to withdraw their tokens.
   * @param _payee The destination address of the tokens.
   */
  function withdrawalAllowed(address _payee) public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp >= releaseTime;
  }
}

// File: contracts/payment/TokenTimelockFactory.sol

/**
 * @title TokenTimelockFactory
 * @dev Allows creation of timelock wallet.
 */
contract TokenTimelockFactory {

  /**
   * @dev Allows verified creation of token timelock wallet.
   * @param _token Address of the token being locked.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred.
   * @param _releaseTime The release times after which the tokens can be withdrawn.
   * @return Returns wallet address.
   */
  function create(
    ERC20 _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
    returns (address wallet);
}

// File: contracts/payment/TokenVestingFactory.sol

/**
 * @title TokenVestingFactory
 * @dev Allows creation of token vesting wallet.
 */
contract TokenVestingFactory {

  /**
   * @dev Allows verified creation of token vesting wallet.
   * Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   * @return Returns wallet address.
   */
  function create(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
    returns (address wallet);
}

// File: contracts/mocks/TokenTimelockEscrowMock.sol

/// @title TokenTimelockEscrowMock
contract TokenTimelockEscrowMock is TokenTimelockEscrow {

  constructor(ERC20 _token, uint256 _releaseTime)
    public
    TokenEscrow(_token)
    TokenTimelockEscrow(_releaseTime)
  {
    // constructor
  }
}

// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param _token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoTokens.sol

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d5a7b0b8b6ba95e7">[email&#160;protected]</a>π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param _from address The address that is transferring the tokens
  * @param _value uint256 the amount of the specified token
  * @param _data Bytes The data passed from the caller.
  */
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoContracts.sol

/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="bbc9ded6d8d4fb89">[email&#160;protected]</a>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param _contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol

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
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
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
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
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
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
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
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
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

// File: openzeppelin-solidity/contracts/crowdsale/validation/IndividuallyCappedCrowdsale.sol

/**
 * @title IndividuallyCappedCrowdsale
 * @dev Crowdsale with per-user caps.
 */
contract IndividuallyCappedCrowdsale is Ownable, Crowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public contributions;
  mapping(address => uint256) public caps;

  /**
   * @dev Sets a specific user&#39;s maximum contribution.
   * @param _beneficiary Address to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setUserCap(address _beneficiary, uint256 _cap) external onlyOwner {
    caps[_beneficiary] = _cap;
  }

  /**
   * @dev Sets a group of users&#39; maximum contribution.
   * @param _beneficiaries List of addresses to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setGroupCap(
    address[] _beneficiaries,
    uint256 _cap
  )
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      caps[_beneficiaries[i]] = _cap;
    }
  }

  /**
   * @dev Returns the cap of a specific user.
   * @param _beneficiary Address whose cap is to be checked
   * @return Current cap for individual user
   */
  function getUserCap(address _beneficiary) public view returns (uint256) {
    return caps[_beneficiary];
  }

  /**
   * @dev Returns the amount contributed so far by a sepecific user.
   * @param _beneficiary Address of contributor
   * @return User contribution so far
   */
  function getUserContribution(address _beneficiary)
    public view returns (uint256)
  {
    return contributions[_beneficiary];
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the user&#39;s funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(contributions[_beneficiary].add(_weiAmount) <= caps[_beneficiary]);
  }

  /**
   * @dev Extend parent behavior to update user contributions
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }

}

// File: openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

// File: openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

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
    require(_closingTime >= _openingTime);

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
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: openzeppelin-solidity/contracts/crowdsale/emission/AllowanceCrowdsale.sol

/**
 * @title AllowanceCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  address public tokenWallet;

  /**
   * @dev Constructor, takes token wallet address.
   * @param _tokenWallet Address holding the tokens, which has approved allowance to the crowdsale
   */
  constructor(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

  /**
   * @dev Checks the amount of tokens left in the allowance.
   * @return Amount of tokens left in the allowance
   */
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

  /**
   * @dev Overrides parent behavior by transferring tokens from wallet.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }
}

// File: contracts/crowdsale/distribution/PostDeliveryCrowdsale.sol

/**
 * @title PostDeliveryCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  /// @dev Withdraw tokens only after crowdsale ends.
  function withdrawTokens() public {
    _withdrawTokens(msg.sender);
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   * @param _beneficiary Token purchaser
   */
  function _withdrawTokens(address _beneficiary) internal {
    require(hasClosed(), "Crowdsale not closed.");
    uint256 amount = balances[_beneficiary];
    require(amount > 0, "Beneficiary has zero balance.");
    balances[_beneficiary] = 0;
    _deliverTokens(_beneficiary, amount);
  }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

}

// File: contracts/SampleAllowanceCrowdsale.sol

/**
 * @title SampleAllowanceCrowdsale
 * @dev This is a ERC20 token crowdsale that will sell tokens util
 * the cap is reached, time expired or the allowance is spent.
 */
// solium-disable-next-line
contract SampleAllowanceCrowdsale
  is
    HasNoTokens,
    HasNoContracts,
    TimedCrowdsale,
    CappedCrowdsale,
    IndividuallyCappedCrowdsale,
    PostDeliveryCrowdsale,
    AllowanceCrowdsale
{

  // When withdrawals open
  uint256 public withdrawTime;

  // Amount of tokens sold
  uint256 public tokensSold;

  // Amount of tokens delivered
  uint256 public tokensDelivered;

  constructor(
    uint256 _rate,
    address _wallet,
    ERC20 _token,
    address _tokenWallet,
    uint256 _cap,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _withdrawTime
  )
    public
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    CappedCrowdsale(_cap)
    AllowanceCrowdsale(_tokenWallet)
  {
    require(_withdrawTime >= _closingTime, "Withdrawals should open after crowdsale closes.");
    withdrawTime = _withdrawTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open
   * has already elapsed or cap was reached.
   * @return Whether crowdsale has ended
   */
  function hasEnded() public view returns (bool) {
    return hasClosed() || capReached();
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   * @param _beneficiary Token purchaser
   */
  function withdrawTokens(address _beneficiary) public {
    _withdrawTokens(_beneficiary);
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   * @param _beneficiaries List of token purchasers
   */
  function withdrawTokens(address[] _beneficiaries) public {
    for (uint32 i = 0; i < _beneficiaries.length; i ++) {
      _withdrawTokens(_beneficiaries[i]);
    }
  }

  /**
   * @dev We use this function to store the total amount of tokens sold
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    super._processPurchase(_beneficiary, _tokenAmount);
    tokensSold = tokensSold.add(_tokenAmount);
  }

  /**
   * @dev We use this function to store the total amount of tokens delivered
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    super._deliverTokens(_beneficiary, _tokenAmount);
    tokensDelivered = tokensDelivered.add(_tokenAmount);
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   * @param _beneficiary Token purchaser
   */
  function _withdrawTokens(address _beneficiary) internal {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp > withdrawTime, "Withdrawals not open.");
    super._withdrawTokens(_beneficiary);
  }

}

// File: contracts/TokenDistributor.sol

/**
 * @title TokenDistributor
 * @dev This is a token distribution contract used to distribute tokens and create a public Crowdsale.
 */
contract TokenDistributor is HasNoEther, Finalizable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // We also declare Factory.ContractInstantiation here to read it in truffle logs
  // https://github.com/trufflesuite/truffle/issues/555
  event ContractInstantiation(address sender, address instantiation);
  event CrowdsaleInstantiated(address sender, address instantiation, uint256 allowance);

  /// Party (team multisig) who is in the control of the token pool.
  /// @notice this will be different from the owner address (scripted) that calls this contract.
  address public benefactor;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

   // Address where funds are collected
  address public wallet;

  // The token being sold
  ERC20 public token;

  // Max cap for presale + crowdsale
  uint256 public cap;

  // Crowdsale is open in this period
  uint256 public openingTime;
  uint256 public closingTime;

  // When withdrawals open
  uint256 public withdrawTime;

  // Amount of wei raised
  uint256 public weiRaised;

  // Crowdsale that is created after the presale distribution is finalized
  SampleAllowanceCrowdsale public crowdsale;

  // Escrow contract used to lock team tokens until crowdsale ends
  TokenTimelockEscrow public presaleEscrow;

  // Escrow contract used to lock bonus tokens
  TokenTimelockEscrow public bonusEscrow;

  // Factory used to create individual time locked token contracts
  TokenTimelockFactory public timelockFactory;

  // Factory used to create individual vesting token contracts
  TokenVestingFactory public vestingFactory;

  /// @dev Throws if called before the crowdsale is created.
  modifier onlyIfCrowdsale() {
    require(isFinalized, "Contract not finalized.");
    require(crowdsale != address(0), "Crowdsale not started.");
    _;
  }

  constructor(
    address _benefactor,
    uint256 _rate,
    address _wallet,
    ERC20 _token,
    uint256 _cap,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _withdrawTime,
    uint256 _bonusTime
  )
    public
  {
    require(address(_benefactor) != address(0), "Benefactor address should not be 0x0.");
    require(_rate > 0, "Rate should not be > 0.");
    require(_wallet != address(0), "Wallet address should not be 0x0.");
    require(address(_token) != address(0), "Token address should not be 0x0.");
    require(_cap > 0, "Cap should be > 0.");
    // solium-disable-next-line security/no-block-members
    require(_openingTime > block.timestamp, "Opening time should be in the future.");
    require(_closingTime > _openingTime, "Closing time should be after opening.");
    require(_withdrawTime >= _closingTime, "Withdrawals should open after crowdsale closes.");
    require(_bonusTime > _withdrawTime, "Bonus time should be set after withdrawals open.");

    benefactor = _benefactor;
    rate = _rate;
    wallet = _wallet;
    token = _token;
    cap = _cap;
    openingTime = _openingTime;
    closingTime = _closingTime;
    withdrawTime = _withdrawTime;

    presaleEscrow = new TokenTimelockEscrowMock(_token, _withdrawTime);
    bonusEscrow = new TokenTimelockEscrowMock(_token, _bonusTime);
  }

  /**
   * @dev Sets a specific user&#39;s maximum contribution.
   * @param _beneficiary Address to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setUserCap(address _beneficiary, uint256 _cap) external onlyOwner onlyIfCrowdsale {
    crowdsale.setUserCap(_beneficiary, _cap);
  }

  /**
   * @dev Sets a group of users&#39; maximum contribution.
   * @param _beneficiaries List of addresses to be capped
   * @param _cap Wei limit for individual contribution
   */
  function setGroupCap(address[] _beneficiaries, uint256 _cap) external onlyOwner onlyIfCrowdsale {
    crowdsale.setGroupCap(_beneficiaries, _cap);
  }

  /**
   * @dev Returns the cap of a specific user.
   * @param _beneficiary Address whose cap is to be checked
   * @return Current cap for individual user
   */
  function getUserCap(address _beneficiary) public view onlyIfCrowdsale returns (uint256) {
    return crowdsale.getUserCap(_beneficiary);
  }

  /**
   * @dev Called by the payer to store the sent amount as credit to be pulled when withdrawals open.
   * @param _dest The destination address of the funds.
   * @param _amount The amount to transfer.
   */
  function depositPresale(address _dest, uint256 _amount) public onlyOwner onlyNotFinalized {
    require(_dest != address(this), "Transfering tokens to this contract address is not allowed.");
    require(token.allowance(benefactor, this) >= _amount, "Not enough allowance.");
    token.transferFrom(benefactor, this, _amount);
    token.approve(presaleEscrow, _amount);
    presaleEscrow.deposit(_dest, _amount);
  }

  /**
   * @dev Called by the payer to store the sent amount as credit to be pulled when withdrawals open.
   * @param _dest The destination address of the funds.
   * @param _amount The amount to transfer.
   * @param _weiAmount The amount of wei exchanged for the tokens.
   */
  function depositPresale(address _dest, uint256 _amount, uint256 _weiAmount) public {
    require(cap >= weiRaised.add(_weiAmount), "Cap reached.");
    depositPresale(_dest, _amount);
    weiRaised = weiRaised.add(_weiAmount);
  }

  /// @dev Withdraw accumulated balance, called by beneficiary.
  function withdrawPresale() public {
    presaleEscrow.withdraw(msg.sender);
  }

  /**
   * @dev Withdraw accumulated balance for beneficiary.
   * @param _beneficiary Address of beneficiary
   */
  function withdrawPresale(address _beneficiary) public {
    presaleEscrow.withdraw(_beneficiary);
  }

  /**
   * @dev Withdraw accumulated balances for beneficiaries.
   * @param _beneficiaries List of addresses of beneficiaries
   */
  function withdrawPresale(address[] _beneficiaries) public {
    for (uint32 i = 0; i < _beneficiaries.length; i ++) {
      presaleEscrow.withdraw(_beneficiaries[i]);
    }
  }

  /**
   * @dev Called by the payer to store the sent amount as credit to be pulled from token timelock contract.
   * @param _dest The destination address of the funds.
   * @param _amount The amount to transfer.
   */
  function depositBonus(address _dest, uint256 _amount) public onlyOwner onlyNotFinalized {
    require(_dest != address(this), "Transfering tokens to this contract address is not allowed.");
    require(token.allowance(benefactor, this) >= _amount, "Not enough allowance.");
    token.transferFrom(benefactor, this, _amount);
    token.approve(bonusEscrow, _amount);
    bonusEscrow.deposit(_dest, _amount);
  }

  /// @dev Withdraw accumulated balance, called by beneficiary.
  function withdrawBonus() public {
    bonusEscrow.withdraw(msg.sender);
  }

  /**
   * @dev Withdraw accumulated balance for beneficiary.
   * @param _beneficiary Address of beneficiary
   */
  function withdrawBonus(address _beneficiary) public {
    bonusEscrow.withdraw(_beneficiary);
  }

  /**
   * @dev Withdraw accumulated balances for beneficiaries.
   * @param _beneficiaries List of addresses of beneficiaries
   */
  function withdrawBonus(address[] _beneficiaries) public {
    for (uint32 i = 0; i < _beneficiaries.length; i ++) {
      bonusEscrow.withdraw(_beneficiaries[i]);
    }
  }

  /**
   * @dev Setter for TokenTimelockFactory because of gas limits
   * @param _timelockFactory Address of the TokenTimelockFactory contract
   */
  function setTokenTimelockFactory(address _timelockFactory) public onlyOwner {
    require(_timelockFactory != address(0), "Factory address should not be 0x0.");
    require(timelockFactory == address(0), "Factory already initalizied.");
    timelockFactory = TokenTimelockFactory(_timelockFactory);
  }

  /**
   * @dev Called by the payer to store the sent amount as credit to be pulled
   * from token timelock contract.
   * @param _dest The destination address of the funds.
   * @param _amount The amount to transfer.
   * @param _releaseTime The release times after which the tokens can be withdrawn.
   * @return Returns wallet address.
   */
  function depositAndLock(
    address _dest,
    uint256 _amount,
    uint256 _releaseTime
  )
    public
    onlyOwner
    onlyNotFinalized
    returns (address tokenWallet)
  {
    require(token.allowance(benefactor, this) >= _amount, "Not enough allowance.");
    require(_dest != address(0), "Destination address should not be 0x0.");
    require(_dest != address(this), "Transfering tokens to this contract address is not allowed.");
    require(_releaseTime >= withdrawTime, "Tokens should unlock after withdrawals open.");
    tokenWallet = timelockFactory.create(
      token,
      _dest,
      _releaseTime
    );
    token.transferFrom(benefactor, tokenWallet, _amount);
  }

  /**
   * @dev Setter for TokenVestingFactory because of gas limits
   * @param _vestingFactory Address of the TokenVestingFactory contract
   */
  function setTokenVestingFactory(address _vestingFactory) public onlyOwner {
    require(_vestingFactory != address(0), "Factory address should not be 0x0.");
    require(vestingFactory == address(0), "Factory already initalizied.");
    vestingFactory = TokenVestingFactory(_vestingFactory);
  }

  /**
   * @dev Called by the payer to store the sent amount as credit to be pulled
   * from token vesting contract.
   * @param _dest The destination address of the funds.
   * @param _amount The amount to transfer.
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @return Returns wallet address.
   */
  function depositAndVest(
    address _dest,
    uint256 _amount,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration
  )
    public
    onlyOwner
    onlyNotFinalized
    returns (address tokenWallet)
  {
    require(token.allowance(benefactor, this) >= _amount, "Not enough allowance.");
    require(_dest != address(0), "Destination address should not be 0x0.");
    require(_dest != address(this), "Transfering tokens to this contract address is not allowed.");
    require(_start.add(_cliff) >= withdrawTime, "Tokens should unlock after withdrawals open.");
    bool revocable = false;
    tokenWallet = vestingFactory.create(
      _dest,
      _start,
      _cliff,
      _duration,
      revocable
    );
    token.transferFrom(benefactor, tokenWallet, _amount);
  }

  /**
   * @dev In case there are any unsold tokens, they are claimed by the owner
   * @param _beneficiary Address where claimable tokens are going to be transfered
   */
  function claimUnsold(address _beneficiary) public onlyIfCrowdsale onlyOwner {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp > withdrawTime, "Withdrawals not open.");
    uint256 sold = crowdsale.tokensSold();
    uint256 delivered = crowdsale.tokensDelivered();
    uint256 toDeliver = sold.sub(delivered);

    uint256 balance = token.balanceOf(this);
    uint256 claimable = balance.sub(toDeliver);

    if (claimable > 0) {
      token.safeTransfer(_beneficiary, claimable);
    }
  }

  /**
   * @dev Finalization logic that will create a Crowdsale with provided parameters
   * and calculated cap depending on the amount raised in presale.
   */
  function finalization() internal {
    super.finalization();
    uint256 crowdsaleCap = cap.sub(weiRaised);
    if (crowdsaleCap == 0) {
      // Cap reached in presale, no crowdsale necessary
      return;
    }

    address tokenWallet = this;
    crowdsale = new SampleAllowanceCrowdsale(
      rate,
      wallet,
      token,
      tokenWallet,
      crowdsaleCap,
      openingTime,
      closingTime,
      withdrawTime
    );
    uint256 allowance = token.allowance(benefactor, this);
    token.transferFrom(benefactor, this, allowance);
    token.approve(crowdsale, allowance);
    emit CrowdsaleInstantiated(msg.sender, crowdsale, allowance);
  }

}