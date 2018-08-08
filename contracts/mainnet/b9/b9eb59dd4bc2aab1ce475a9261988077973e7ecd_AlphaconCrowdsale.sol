pragma solidity ^0.4.24;


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
 * @title HolderBase
 * @notice HolderBase handles data & funcitons for token or ether holders.
 * HolderBase contract can distribute only one of ether or token.
 */
contract HolderBase is Ownable {
  using SafeMath for uint256;

  uint8 public constant MAX_HOLDERS = 64; // TODO: tokyo-input should verify # of holders
  uint256 public coeff;
  bool public distributed;
  bool public initialized;

  struct Holder {
    address addr;
    uint96 ratio;
  }

  Holder[] public holders;

  event Distributed();

  function HolderBase(uint256 _coeff) public {
    require(_coeff != 0);
    coeff = _coeff;
  }

  function getHolderCount() public view returns (uint256) {
    return holders.length;
  }

  function initHolders(address[] _addrs, uint96[] _ratios) public onlyOwner {
    require(!initialized);
    require(holders.length == 0);
    require(_addrs.length != 0);
    require(_addrs.length <= MAX_HOLDERS);
    require(_addrs.length == _ratios.length);

    uint256 accRatio;

    for(uint8 i = 0; i < _addrs.length; i++) {
      if (_addrs[i] != address(0)) {
        // address will be 0x00 in case of "crowdsale".
        holders.push(Holder(_addrs[i], _ratios[i]));
      }

      accRatio = accRatio.add(uint256(_ratios[i]));
    }

    require(accRatio <= coeff);

    initialized = true;
  }

  /**
   * @dev Distribute ether to `holder`s according to ratio.
   * Remaining ether is transfered to `wallet` from the close
   * function of RefundVault contract.
   */
  function distribute() internal {
    require(!distributed, "Already distributed");
    uint256 balance = this.balance;

    require(balance > 0, "No ether to distribute");
    distributed = true;

    for (uint8 i = 0; i < holders.length; i++) {
      uint256 holderAmount = balance.mul(uint256(holders[i].ratio)).div(coeff);

      holders[i].addr.transfer(holderAmount);
    }

    emit Distributed(); // A single log to reduce gas
  }

  /**
   * @dev Distribute ERC20 token to `holder`s according to ratio.
   */
  function distributeToken(ERC20Basic _token, uint256 _targetTotalSupply) internal {
    require(!distributed, "Already distributed");
    distributed = true;

    for (uint8 i = 0; i < holders.length; i++) {
      uint256 holderAmount = _targetTotalSupply.mul(uint256(holders[i].ratio)).div(coeff);
      deliverTokens(_token, holders[i].addr, holderAmount);
    }

    emit Distributed(); // A single log to reduce gas
  }

  // Override to distribute tokens
  function deliverTokens(ERC20Basic _token, address _beneficiary, uint256 _tokens) internal {}
}


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


/**
 * @title Locker
 * @notice Locker holds tokens and releases them at a certain time.
 */
contract Locker is Ownable {
  using SafeMath for uint;
  using SafeERC20 for ERC20Basic;

  /**
   * It is init state only when adding release info is possible.
   * beneficiary only can release tokens when Locker is active.
   * After all tokens are released, locker is drawn.
   */
  enum State { Init, Ready, Active, Drawn }

  struct Beneficiary {
    uint ratio;             // ratio based on Locker&#39;s initial balance.
    uint withdrawAmount;    // accumulated tokens beneficiary released
    bool releaseAllTokens;
  }

  /**
   * @notice Release has info to release tokens.
   * If lock type is straight, only two release infos is required.
   *
   *     |
   * 100 |                _______________
   *     |              _/
   *  50 |            _/
   *     |         . |
   *     |       .   |
   *     |     .     |
   *     +===+=======+----*----------> time
   *     Locker  First    Last
   *  Activated  Release  Release
   *
   *
   * If lock type is variable, the release graph will be
   *
   *     |
   * 100 |                                 _________
   *     |                                |
   *  70 |                      __________|
   *     |                     |
   *  30 |            _________|
   *     |           |
   *     +===+=======+---------+----------*------> time
   *     Locker   First        Second     Last
   *  Activated   Release      Release    Release
   *
   *
   *
   * For the first straight release graph, parameters would be
   *   coeff: 100
   *   releaseTimes: [
   *     first release time,
   *     second release time
   *   ]
   *   releaseRatios: [
   *     50,
   *     100,
   *   ]
   *
   * For the second variable release graph, parameters would be
   *   coeff: 100
   *   releaseTimes: [
   *     first release time,
   *     second release time,
   *     last release time
   *   ]
   *   releaseRatios: [
   *     30,
   *     70,
   *     100,
   *   ]
   *
   */
  struct Release {
    bool isStraight;        // lock type : straight or variable
    uint[] releaseTimes;    //
    uint[] releaseRatios;   //
  }

  uint public activeTime;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  uint public coeff;
  uint public initialBalance;
  uint public withdrawAmount; // total amount of tokens released

  mapping (address => Beneficiary) public beneficiaries;
  mapping (address => Release) public releases;  // beneficiary&#39;s lock
  mapping (address => bool) public locked; // whether beneficiary&#39;s lock is instantiated

  uint public numBeneficiaries;
  uint public numLocks;

  State public state;

  modifier onlyState(State v) {
    require(state == v);
    _;
  }

  modifier onlyBeneficiary(address _addr) {
    require(beneficiaries[_addr].ratio > 0);
    _;
  }

  event StateChanged(State _state);
  event Locked(address indexed _beneficiary, bool _isStraight);
  event Released(address indexed _beneficiary, uint256 _amount);

  function Locker(address _token, uint _coeff, address[] _beneficiaries, uint[] _ratios) public {
    require(_token != address(0));
    require(_beneficiaries.length == _ratios.length);

    token = ERC20Basic(_token);
    coeff = _coeff;
    numBeneficiaries = _beneficiaries.length;

    uint accRatio;

    for(uint i = 0; i < numBeneficiaries; i++) {
      require(_ratios[i] > 0);
      beneficiaries[_beneficiaries[i]].ratio = _ratios[i];

      accRatio = accRatio.add(_ratios[i]);
    }

    require(coeff == accRatio);
  }

  /**
   * @notice beneficiary can release their tokens after activated
   */
  function activate() external onlyOwner onlyState(State.Ready) {
    require(numLocks == numBeneficiaries); // double check : assert all releases are recorded

    initialBalance = token.balanceOf(this);
    require(initialBalance > 0);

    activeTime = now; // solium-disable-line security/no-block-members

    // set locker as active state
    state = State.Active;
    emit StateChanged(state);
  }

  function getReleaseType(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (bool)
  {
    return releases[_beneficiary].isStraight;
  }

  function getTotalLockedAmounts(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint)
  {
    return getPartialAmount(beneficiaries[_beneficiary].ratio, coeff, initialBalance);
  }

  function getReleaseTimes(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint[])
  {
    return releases[_beneficiary].releaseTimes;
  }

  function getReleaseRatios(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint[])
  {
    return releases[_beneficiary].releaseRatios;
  }

  /**
   * @notice add new release record for beneficiary
   */
  function lock(address _beneficiary, bool _isStraight, uint[] _releaseTimes, uint[] _releaseRatios)
    external
    onlyOwner
    onlyState(State.Init)
    onlyBeneficiary(_beneficiary)
  {
    require(!locked[_beneficiary]);
    require(_releaseRatios.length != 0);
    require(_releaseRatios.length == _releaseTimes.length);

    uint i;
    uint len = _releaseRatios.length;

    // finally should release all tokens
    require(_releaseRatios[len - 1] == coeff);

    // check two array are ascending sorted
    for(i = 0; i < len - 1; i++) {
      require(_releaseTimes[i] < _releaseTimes[i + 1]);
      require(_releaseRatios[i] < _releaseRatios[i + 1]);
    }

    // 2 release times for straight locking type
    if (_isStraight) {
      require(len == 2);
    }

    numLocks = numLocks.add(1);

    // create Release for the beneficiary
    releases[_beneficiary].isStraight = _isStraight;

    // copy array of uint
    releases[_beneficiary].releaseTimes = _releaseTimes;
    releases[_beneficiary].releaseRatios = _releaseRatios;

    // lock beneficiary
    locked[_beneficiary] = true;
    emit Locked(_beneficiary, _isStraight);

    //  if all beneficiaries locked, change Locker state to change
    if (numLocks == numBeneficiaries) {
      state = State.Ready;
      emit StateChanged(state);
    }
  }

  /**
   * @notice transfer releasable tokens for beneficiary wrt the release graph
   */
  function release() external onlyState(State.Active) onlyBeneficiary(msg.sender) {
    require(!beneficiaries[msg.sender].releaseAllTokens);

    uint releasableAmount = getReleasableAmount(msg.sender);
    beneficiaries[msg.sender].withdrawAmount = beneficiaries[msg.sender].withdrawAmount.add(releasableAmount);

    beneficiaries[msg.sender].releaseAllTokens = beneficiaries[msg.sender].withdrawAmount == getPartialAmount(
      beneficiaries[msg.sender].ratio,
      coeff,
      initialBalance);

    withdrawAmount = withdrawAmount.add(releasableAmount);

    if (withdrawAmount == initialBalance) {
      state = State.Drawn;
      emit StateChanged(state);
    }

    token.transfer(msg.sender, releasableAmount);
    emit Released(msg.sender, releasableAmount);
  }

  function getReleasableAmount(address _beneficiary) internal view returns (uint) {
    if (releases[_beneficiary].isStraight) {
      return getStraightReleasableAmount(_beneficiary);
    } else {
      return getVariableReleasableAmount(_beneficiary);
    }
  }

  /**
   * @notice return releaseable amount for beneficiary in case of straight type of release
   */
  function getStraightReleasableAmount(address _beneficiary) internal view returns (uint releasableAmount) {
    Beneficiary memory _b = beneficiaries[_beneficiary];
    Release memory _r = releases[_beneficiary];

    // total amount of tokens beneficiary can release
    uint totalReleasableAmount = getTotalLockedAmounts(_beneficiary);

    uint firstTime = _r.releaseTimes[0];
    uint lastTime = _r.releaseTimes[1];

    // solium-disable security/no-block-members
    require(now >= firstTime); // pass if can release
    // solium-enable security/no-block-members

    if(now >= lastTime) { // inclusive to reduce calculation
      releasableAmount = totalReleasableAmount;
    } else {
      // releasable amount at first time
      uint firstAmount = getPartialAmount(
        _r.releaseRatios[0],
        coeff,
        totalReleasableAmount);

      // partial amount without first amount
      releasableAmount = getPartialAmount(
        now.sub(firstTime),
        lastTime.sub(firstTime),
        totalReleasableAmount.sub(firstAmount));
      releasableAmount = releasableAmount.add(firstAmount);
    }

    // subtract already withdrawn amounts
    releasableAmount = releasableAmount.sub(_b.withdrawAmount);
  }

  /**
   * @notice return releaseable amount for beneficiary in case of variable type of release
   */
  function getVariableReleasableAmount(address _beneficiary) internal view returns (uint releasableAmount) {
    Beneficiary memory _b = beneficiaries[_beneficiary];
    Release memory _r = releases[_beneficiary];

    // total amount of tokens beneficiary will receive
    uint totalReleasableAmount = getTotalLockedAmounts(_beneficiary);

    uint releaseRatio;

    // reverse order for short curcit
    for(uint i = _r.releaseTimes.length - 1; i >= 0; i--) {
      if (now >= _r.releaseTimes[i]) {
        releaseRatio = _r.releaseRatios[i];
        break;
      }
    }

    require(releaseRatio > 0);

    releasableAmount = getPartialAmount(
      releaseRatio,
      coeff,
      totalReleasableAmount);
    releasableAmount = releasableAmount.sub(_b.withdrawAmount);
  }

  /// https://github.com/0xProject/0x.js/blob/05aae368132a81ddb9fd6a04ac5b0ff1cbb24691/packages/contracts/src/current/protocol/Exchange/Exchange.sol#L497
  /// @notice Calculates partial value given a numerator and denominator.
  /// @param numerator Numerator.
  /// @param denominator Denominator.
  /// @param target Value to calculate partial of.
  /// @return Partial value of target.
  function getPartialAmount(uint numerator, uint denominator, uint target) public pure returns (uint) {
    return numerator.mul(target).div(denominator);
  }
}


/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @param _wallet Vault address
   */
  constructor(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}


/**
 * @title MultiHolderVault
 * @dev This contract distribute ether to multiple address.
 */
contract MultiHolderVault is HolderBase, RefundVault {
  using SafeMath for uint256;

  function MultiHolderVault(address _wallet, uint256 _ratioCoeff)
    public
    HolderBase(_ratioCoeff)
    RefundVault(_wallet)
  {}

  function close() public onlyOwner {
    require(state == State.Active);
    require(initialized);

    super.distribute(); // distribute ether to holders
    super.close(); // transfer remaining ether to wallet
  }
}


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


contract BaseCrowdsale is HolderBase, Pausable {
  using SafeMath for uint256;

  Locker public locker;     // token locker

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // how many token units a buyer gets per wei
  // use coeff ratio from HolderBase
  uint256 public rate;


  // amount of raised money in wei
  uint256 public weiRaised;

  // ratio of tokens for crowdsale
  uint256 public crowdsaleRatio;

  bool public isFinalized = false;

  uint256 public cap;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  MultiHolderVault public vault;

  address public nextTokenOwner;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Finalized();
  event ClaimTokens(address indexed _token, uint256 _amount);

  function BaseCrowdsale(uint256 _coeff) HolderBase(_coeff) public {}

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    uint256 toFund = calculateToFund(beneficiary, weiAmount);
    require(toFund > 0);

    uint256 toReturn = weiAmount.sub(toFund);

    buyTokensPreHook(beneficiary, toFund);

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(toFund);

    // update state
    weiRaised = weiRaised.add(toFund);

    if (toReturn > 0) {
      msg.sender.transfer(toReturn);
    }

    buyTokensPostHook(beneficiary, tokens, toFund);

    generateTokens(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, toFund, tokens);
    forwardFunds(toFund);
  }

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    emit Finalized();

    isFinalized = true;
  }


  // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (goalReached()) {
      finalizationSuccessHook();
    } else {
      finalizationFailHook();
    }
  }

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

  /// @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || now > endTime; // solium-disable-line security/no-block-members
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

  /**
   * @notice forwardd ether to vault
   */
  function forwardFunds(uint256 toFund) internal {
    vault.deposit.value(toFund)(msg.sender);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime; // solium-disable-line security/no-block-members
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  /**
   * @notice calculate fund wrt sale cap. Override this function to control ether cap.
   * @param _beneficiary address address to receive tokens
   * @param _weiAmount uint256 amount of ether in wei
   */
  function calculateToFund(address _beneficiary, uint256 _weiAmount) internal view returns (uint256) {
    uint256 toFund;
    uint256 postWeiRaised = weiRaised.add(_weiAmount);

    if (postWeiRaised > cap) {
      toFund = cap.sub(weiRaised);
    } else {
      toFund = _weiAmount;
    }
    return toFund;
  }

  /**
   * @notice interface to initialize crowdsale parameters.
   * init should be implemented by Crowdsale Generator.
   */
  function init(bytes32[] args) public;

  /**
   * @notice pre hook for buyTokens function
   * @param _beneficiary address address to receive tokens
   * @param _toFund uint256 amount of ether in wei
   */
  function buyTokensPreHook(address _beneficiary, uint256 _toFund) internal {}

  /**
   * @notice post hook for buyTokens function
   * @param _beneficiary address address to receive tokens
   * @param _tokens uint256 amount of tokens to receive
   * @param _toFund uint256 amount of ether in wei
   */
  function buyTokensPostHook(address _beneficiary, uint256 _tokens, uint256 _toFund) internal {}

  function finalizationFailHook() internal {
    vault.enableRefunds();
  }

  function finalizationSuccessHook() internal {
    // calculate target total supply including all token holders
    uint256 targetTotalSupply = getTotalSupply().mul(coeff).div(crowdsaleRatio);
    ERC20Basic token = ERC20Basic(getTokenAddress());

    super.distributeToken(token, targetTotalSupply);
    afterGeneratorHook();

    locker.activate();
    vault.close();

    transferTokenOwnership(nextTokenOwner);
  }

  function afterGeneratorHook() internal {}

  /**
   * @notice common interfaces for both of MiniMe and Mintable token.
   */
  function generateTokens(address _beneficiary, uint256 _tokens) internal;
  function transferTokenOwnership(address _to) internal;
  function getTotalSupply() internal returns (uint256);
  function finishMinting() internal returns (bool);
  function getTokenAddress() internal returns (address);

  /**
   * @notice helper function to generate tokens with ratio
   */
  function generateTargetTokens(address _beneficiary, uint256 _targetTotalSupply, uint256 _ratio) internal {
    uint256 tokens = _targetTotalSupply.mul(_ratio).div(coeff);
    generateTokens(_beneficiary, tokens);
  }

  /**
   * @notice claim ERC20Basic compatible tokens
   */
  function claimTokens(ERC20Basic _token) external onlyOwner {
    require(isFinalized);
    uint256 balance = _token.balanceOf(this);
    _token.transfer(owner, balance);
    emit ClaimTokens(_token, balance);
  }

  /**
   * @notice Override HolderBase.deliverTokens
   * @param _token ERC20Basic token contract
   * @param _beneficiary Address to receive tokens
   * @param _tokens Amount of tokens
   */
  function deliverTokens(ERC20Basic _token, address _beneficiary, uint256 _tokens) internal {
    generateTokens(_beneficiary, _tokens);
  }

}


/**
 * @title BlockIntervalCrowdsale
 * @notice BlockIntervalCrowdsale limit purchaser to take participate too frequently.
 */
contract BlockIntervalCrowdsale is BaseCrowdsale {
  uint256 public blockInterval;
  mapping (address => uint256) public recentBlock;

  function BlockIntervalCrowdsale(uint256 _blockInterval) public {
    require(_blockInterval != 0);
    blockInterval = _blockInterval;
  }

  /**
   * @return true if the block number is over the block internal.
   */
  function validPurchase() internal view returns (bool) {
    bool withinBlock = recentBlock[msg.sender].add(blockInterval) < block.number;
    return withinBlock && super.validPurchase();
  }

  /**
   * @notice save the block number
   */
  function buyTokensPreHook(address _beneficiary, uint256 _toFund) internal {
    recentBlock[msg.sender] = block.number;
    super.buyTokensPreHook(_beneficiary, _toFund);
  }
}


// https://github.com/bitclave/crowdsale/blob/master/contracts/BonusCrowdsale.sol

pragma solidity ^0.4.24;





/**
* @dev Parent crowdsale contract with support for time-based and amount based bonuses
* Based on references from OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity
*
*/
contract BonusCrowdsale is BaseCrowdsale {

  // Constants
  // The following will be populated by main crowdsale contract
  uint32[] public BONUS_TIMES;
  uint32[] public BONUS_TIMES_VALUES;
  uint128[] public BONUS_AMOUNTS;
  uint32[] public BONUS_AMOUNTS_VALUES;

  /**
  * @dev Retrieve length of bonuses by time array
  * @return Bonuses by time array length
  */
  function bonusesForTimesCount() public view returns(uint) {
    return BONUS_TIMES.length;
  }

  /**
  * @dev Sets bonuses for time
  */
  function setBonusesForTimes(uint32[] times, uint32[] values) public onlyOwner {
    require(times.length == values.length);
    for (uint i = 0; i + 1 < times.length; i++) {
      require(times[i] < times[i+1]);
    }

    BONUS_TIMES = times;
    BONUS_TIMES_VALUES = values;
  }

  /**
  * @dev Retrieve length of bonuses by amounts array
  * @return Bonuses by amounts array length
  */
  function bonusesForAmountsCount() public view returns(uint) {
    return BONUS_AMOUNTS.length;
  }

  /**
  * @dev Sets bonuses for USD amounts
  */
  function setBonusesForAmounts(uint128[] amounts, uint32[] values) public onlyOwner {
    require(amounts.length == values.length);
    for (uint i = 0; i + 1 < amounts.length; i++) {
      require(amounts[i] > amounts[i+1]);
    }

    BONUS_AMOUNTS = amounts;
    BONUS_AMOUNTS_VALUES = values;
  }

  /**
  * @notice Overrided getTokenAmount function of parent Crowdsale contract
    to calculate the token with time and amount bonus.
  * @param weiAmount walelt of investor to receive tokens
  */
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    // Compute time and amount bonus
    uint256 bonus = computeBonus(weiAmount);
    uint256 rateWithBonus = rate.mul(coeff.add(bonus)).div(coeff);
    return weiAmount.mul(rateWithBonus);
  }

  /**
  * @dev Computes overall bonus based on time of contribution and amount of contribution.
  * The total bonus is the sum of bonus by time and bonus by amount
  * @return bonus percentage scaled by 10
  */
  function computeBonus(uint256 weiAmount) public view returns(uint256) {
    return computeAmountBonus(weiAmount).add(computeTimeBonus());
  }

  /**
  * @dev Computes bonus based on time of contribution relative to the beginning of crowdsale
  * @return bonus percentage scaled by 10
  */
  function computeTimeBonus() public view returns(uint256) {
    require(now >= startTime); // solium-disable-line security/no-block-members

    for (uint i = 0; i < BONUS_TIMES.length; i++) {
      if (now <= BONUS_TIMES[i]) { // solium-disable-line security/no-block-members
        return BONUS_TIMES_VALUES[i];
      }
    }

    return 0;
  }

  /**
  * @dev Computes bonus based on amount of contribution
  * @return bonus percentage scaled by 10
  */
  function computeAmountBonus(uint256 weiAmount) public view returns(uint256) {
    for (uint i = 0; i < BONUS_AMOUNTS.length; i++) {
      if (weiAmount >= BONUS_AMOUNTS[i]) {
        return BONUS_AMOUNTS_VALUES[i];
      }
    }

    return 0;
  }

}


/**
 * @title FinishMintingCrowdsale
 * @notice FinishMintingCrowdsale prevents token generation after sale ended.
 */
contract FinishMintingCrowdsale is BaseCrowdsale {
  function afterGeneratorHook() internal {
    require(finishMinting());
    super.afterGeneratorHook();
  }
}


/**
 * @title KYC
 * @dev KYC contract handles the white list for PLCCrowdsale contract
 * Only accounts registered in KYC contract can buy PLC token.
 * Admins can register account, and the reason why
 */
contract KYC is Ownable {
  // check the address is registered for token sale
  mapping (address => bool) public registeredAddress;

  // check the address is admin of kyc contract
  mapping (address => bool) public admin;

  event Registered(address indexed _addr);
  event Unregistered(address indexed _addr);
  event SetAdmin(address indexed _addr, bool indexed _isAdmin);

  /**
   * @dev check whether the msg.sender is admin or not
   */
  modifier onlyAdmin() {
    require(admin[msg.sender]);
    _;
  }

  function KYC() public {
    admin[msg.sender] = true;
  }

  /**
   * @dev set new admin as admin of KYC contract
   * @param _addr address The address to set as admin of KYC contract
   */
  function setAdmin(address _addr, bool _isAdmin)
    public
    onlyOwner
  {
    require(_addr != address(0));
    admin[_addr] = _isAdmin;

    emit SetAdmin(_addr, _isAdmin);
  }

  /**
   * @dev register the address for token sale
   * @param _addr address The address to register for token sale
   */
  function register(address _addr)
    public
    onlyAdmin
  {
    require(_addr != address(0));

    registeredAddress[_addr] = true;

    emit Registered(_addr);
  }

  /**
   * @dev register the addresses for token sale
   * @param _addrs address[] The addresses to register for token sale
   */
  function registerByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0));

      registeredAddress[_addrs[i]] = true;

      emit Registered(_addrs[i]);
    }
  }

  /**
   * @dev unregister the registered address
   * @param _addr address The address to unregister for token sale
   */
  function unregister(address _addr)
    public
    onlyAdmin
  {
    registeredAddress[_addr] = false;

    emit Unregistered(_addr);
  }

  /**
   * @dev unregister the registered addresses
   * @param _addrs address[] The addresses to unregister for token sale
   */
  function unregisterByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      registeredAddress[_addrs[i]] = false;

      emit Unregistered(_addrs[i]);
    }
  }
}


/**
 * @title KYCCrowdsale
 * @notice KYCCrowdsale checks kyc information and
 */
contract KYCCrowdsale is BaseCrowdsale {

  KYC kyc;

  function KYCCrowdsale (address _kyc) public {
    require(_kyc != 0x0);
    kyc = KYC(_kyc);
  }

  function registered(address _addr) public view returns (bool) {
    return kyc.registeredAddress(_addr);
  }
}


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


contract MintableBaseCrowdsale is BaseCrowdsale {

  MintableToken token;

  function MintableBaseCrowdsale (address _token) public {
    require(_token != address(0));
    token = MintableToken(_token);
  }


  function generateTokens(address _beneficiary, uint256 _tokens) internal {
    token.mint(_beneficiary, _tokens);
  }

  function transferTokenOwnership(address _to) internal {
    token.transferOwnership(_to);
  }

  function getTotalSupply() internal returns (uint256) {
    return token.totalSupply();
  }

  function finishMinting() internal returns (bool) {
    require(token.finishMinting());
    return true;
  }

  function getTokenAddress() internal returns (address) {
    return address(token);
  }
}


/**
 * @title StagedCrowdsale
 * @notice StagedCrowdsale seperates sale period with start time & end time.
 * For each period, seperate max cap and kyc could be setup.
 * Both startTime and endTime are inclusive.
 */
contract StagedCrowdsale is KYCCrowdsale {

  uint8 public numPeriods;

  Stage[] public stages;

  struct Stage {
    uint128 cap;
    uint128 maxPurchaseLimit;
    uint128 minPurchaseLimit;
    uint128 weiRaised; // stage&#39;s weiAmount raised
    uint32 startTime;
    uint32 endTime;
    bool kyc;
  }

  function StagedCrowdsale(uint _numPeriods) public {
    numPeriods = uint8(_numPeriods);
    require(numPeriods > 0);
  }

  function initStages(
    uint32[] _startTimes,
    uint32[] _endTimes,
    uint128[] _capRatios,
    uint128[] _maxPurchaseLimits,
    uint128[] _minPurchaseLimits,
    bool[] _kycs)
    public
  {
    uint len = numPeriods;

    require(stages.length == 0);
    // solium-disable
    require(len == _startTimes.length &&
      len == _endTimes.length &&
      len == _capRatios.length &&
      len == _maxPurchaseLimits.length &&
      len == _minPurchaseLimits.length &&
      len == _kycs.length);
    // solium-enable

    for (uint i = 0; i < len; i++) {
      require(_endTimes[i] >= _startTimes[i]);

      uint stageCap;

      if (_capRatios[i] != 0) {
        stageCap = cap.mul(uint(_capRatios[i])).div(coeff);
      } else {
        stageCap = 0;
      }

      stages.push(Stage({
        startTime: _startTimes[i],
        endTime: _endTimes[i],
        cap: uint128(stageCap),
        maxPurchaseLimit: _maxPurchaseLimits[i],
        minPurchaseLimit: _minPurchaseLimits[i],
        kyc: _kycs[i],
        weiRaised: 0
      }));
    }

    require(validPeriods());
  }

  /**
   * @notice if period is on sale, return index of the period.
   */
  function getStageIndex() public view returns (uint8 currentStage, bool onSale) {
    onSale = true;
    Stage memory p;

    for (currentStage = 0; currentStage < stages.length; currentStage++) {
      p = stages[currentStage];
      if (p.startTime <= now && now <= p.endTime) {
        return;
      }
    }

    onSale = false;
  }

  /**
   * @notice return if all period is finished.
   */
  function saleFinished() public view returns (bool) {
    require(stages.length == numPeriods);
    return stages[stages.length - 1].endTime < now;
  }


  function validPeriods() internal view returns (bool) {
    if (stages.length != numPeriods) {
      return false;
    }

    // check stages are overlapped.
    for (uint8 i = 0; i < stages.length - 1; i++) {
      if (stages[i].endTime >= stages[i + 1].startTime) {
        return false;
      }
    }

    return true;
  }

  /**
   * @notice Override BaseCrowdsale.calculateToFund function.
   * Check if period is on sale and apply cap if needed.
   */
  function calculateToFund(address _beneficiary, uint256 _weiAmount) internal view returns (uint256) {
    uint256 weiAmount = _weiAmount;
    uint8 currentStage;
    bool onSale;

    (currentStage, onSale) = getStageIndex();

    require(onSale);

    Stage memory p = stages[currentStage];

    // Check kyc if needed for this period
    if (p.kyc) {
      require(super.registered(_beneficiary));
    }

    // check min purchase limit of the period
    require(weiAmount >= uint(p.minPurchaseLimit));

    // reduce up to max purchase limit of the period
    if (p.maxPurchaseLimit != 0 && weiAmount > uint(p.maxPurchaseLimit)) {
      weiAmount = uint(p.maxPurchaseLimit);
    }

    // pre-calculate `toFund` with the period&#39;s cap
    if (p.cap > 0) {
      uint256 postWeiRaised = uint256(p.weiRaised).add(weiAmount);

      if (postWeiRaised > p.cap) {
        weiAmount = uint256(p.cap).sub(p.weiRaised);
      }
    }

    // get `toFund` with the cap of the sale
    return super.calculateToFund(_beneficiary, weiAmount);
  }

  function buyTokensPreHook(address _beneficiary, uint256 _toFund) internal {
    uint8 currentStage;
    bool onSale;

    (currentStage, onSale) = getStageIndex();

    require(onSale);

    Stage storage p = stages[currentStage];

    p.weiRaised = uint128(_toFund.add(uint256(p.weiRaised)));
    super.buyTokensPreHook(_beneficiary, _toFund);
  }
}


pragma solidity^0.4.18;








contract AlphaconCrowdsale is BaseCrowdsale, MintableBaseCrowdsale, BonusCrowdsale, BlockIntervalCrowdsale, KYCCrowdsale, StagedCrowdsale, FinishMintingCrowdsale {

  bool public initialized;

  // constructor parameters are left padded bytes32.

  function AlphaconCrowdsale(bytes32[5] args) 
    BaseCrowdsale(
      parseUint(args[0]))
    MintableBaseCrowdsale(
      parseAddress(args[1]))
    BonusCrowdsale()
    BlockIntervalCrowdsale(
      parseUint(args[2]))
    KYCCrowdsale(
      parseAddress(args[3]))
    StagedCrowdsale(
      parseUint(args[4]))
    FinishMintingCrowdsale() public {}
  

  function parseBool(bytes32 b) internal pure returns (bool) {
    return b == 0x1;
  }

  function parseUint(bytes32 b) internal pure returns (uint) {
    return uint(b);
  }

  function parseAddress(bytes32 b) internal pure returns (address) {
    return address(b & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff);
  }

  function init(bytes32[] args) public {
    uint _startTime = uint(args[0]);
    uint _endTime = uint(args[1]);
    uint _rate = uint(args[2]);
    uint _cap = uint(args[3]);
    uint _goal = uint(args[4]);
    uint _crowdsaleRatio = uint(args[5]);
    address _vault = address(args[6]);
    address _locker = address(args[7]);
    address _nextTokenOwner = address(args[8]);

    require(_endTime > _startTime);
    require(_rate > 0);
    require(_cap > 0);
    require(_goal > 0);
    require(_cap > _goal);
    require(_crowdsaleRatio > 0);
    require(_vault != address(0));
    require(_locker != address(0));
    require(_nextTokenOwner != address(0));
    
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    cap = _cap;
    goal = _goal;
    crowdsaleRatio = _crowdsaleRatio;
    vault = MultiHolderVault(_vault);
    locker = Locker(_locker);
    nextTokenOwner = _nextTokenOwner;
  }
}