// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./Crowdsale.sol";
import "./validation/CappedCrowdsale.sol";
import "../vesting/DefiYieldTokenVesting.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DefiYieldCrowdsale is CappedCrowdsale {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  enum State { None, Open, Closed }

  struct Round {
    bool defined;
    State state;
    uint256 price;
    uint256 investment;
    uint256 totalSupply;
    uint8 pool;
  }

  State private _state;
  Round[] private _rounds;
  uint256 private _activeRound;
  uint256 private _tokensSold;
  uint256 private _tokensWithdrawn;
  uint256 private _directWithdrawPercentage;

  DefiYieldTokenVesting private _vesting;
  mapping(address => mapping(uint256 => uint256)) private _balances;

  event SaleStateUpdated(State state);
  event RoundOpened(uint256 indexed index);
  event RoundClosed(uint256 indexed index);
  event RoundAdded(uint256 price, uint256 totalSupply);
  event RoundUpdated(uint256 indexed index, uint256 price, uint256 totalSupply);
  event RoundTotalSupplyUpdated(uint256 indexed index, uint256 totalSupply);

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen() {
    require(isOpen(), "DefiYieldCrowdsale: not open");
    _;
  }

  constructor(address wallet_, IERC20 token_, IERC20 collateral_, DefiYieldTokenVesting vesting_)
    Crowdsale(1, wallet_, token_, collateral_)
  {
    _vesting = vesting_;
    token_.safeApprove(address(_vesting), 2**256 - 1);
  }

  /**
   * @dev Returns vesting contract address.
   */
  function getVestingAddress()
    external
    view
    returns (DefiYieldTokenVesting)
  {
    return _vesting;
  }

  /**
   * @dev Returns total tokens sold.
   */
  function getTokensSold()
    external
    view
    returns (uint256)
  {
    return _tokensSold;
  }

  /**
   * @dev Returns total tokens withdrawn.
   */
  function getTokensWithdrawn()
    external
    view
    returns (uint256)
  {
    return _tokensWithdrawn;
  }

  /**
   * @dev Returns active round.
   */
  function getActiveRound()
    external
    view
    returns (uint256)
  {
    return _activeRound;
  }

  /**
   * @dev Returns round by index.
   * @param index_  round index.
   */
  function getRound(uint256 index_)
    external
    view 
    returns (Round memory) 
  {
    return _rounds[index_];
  }

  /**
   * @dev Returns vesting pool.
   */
  function getVestingPool(uint256 index_)
    external 
    view returns (uint8)
  {
    return _rounds[index_].pool;
  }

  /**
   * @dev Returns sale token balance.
   */
  function tokenBalance()
    public
    view
    returns (uint256)
  {
    return getToken().balanceOf(address(this));
  }

  /**
   * @dev Returns direct withdraw percentage.
   */
  function directWithdrawPercentage()
    external
    view
    returns (uint256)
  {
    return _directWithdrawPercentage;
  }

  /**
   * @dev Sets direct withdraw percentage.
   * @param percentage_  percentage of tokens available to withdraw after sale is closed.
   */
  function setDirectWithdrawPercentage(uint256 percentage_)
    external
    onlyAdmin
  {
    require(percentage_ >= 0 && percentage_ <= 100, "DefiYieldCrowdsale::setDirectWithdrawPercentage: withdraw percentage should be >= 0 and <= 100");
    _directWithdrawPercentage = percentage_;
  }

  /**
   * @return True if the crowdsale is open, false otherwise.
   */
  function isOpen()
    public
    view
    returns (bool)
  {
    return _state == State.Open;
  }

  /**
   * @dev True if the crowdsale is closed, false otherwise.
   */
  function isClosed()
    public
    view
    returns (bool)
  {
    return _state == State.Closed;
  }

  /**
   * @dev Opens the sale.
   */
  function openSale()
    external
    onlyAdmin
  {
    require(_state == State.None, "DefiYieldCrowdsale::openSale: sales is already open or closed");
    _state = State.Open;

    emit SaleStateUpdated(_state);
  }

  /**
   * @dev Closes the sale.
   */
  function closeSale()
    external
    onlyAdmin
  {
    require(_state == State.Open, "DefiYieldCrowdsale::closeSale: sales is already closed or not open");
    _state = State.Closed;

    emit SaleStateUpdated(_state);
  }

  /**
   * @dev Adds new round.
   * @param price_  price per token unit.
   * @param totalSupply_  max amount of tokens available in round.
   * @param pool_  vesting pool.
   */
  function addRound(uint256 price_, uint256 totalSupply_, uint8 pool_)
    external
    onlyAdmin
  {
    require(_state != State.Closed, "DefiYieldCrowdsale::addRound: sales is already closed");

    _rounds.push(
      Round({
        defined: true,
        state: State.None,
        price: price_,
        investment: 0,
        totalSupply: totalSupply_,
        pool: pool_
      })
    );
    emit RoundAdded(price_, totalSupply_);
  }

  /**
   * @dev Updates round parameters.
   * @param index_  round index.
   * @param price_  price per token unit.
   * @param totalSupply_  max amount of tokens available in round.
   * @param pool_  vesting pool.
   */
  function updateRound(uint256 index_, uint256 price_, uint256 totalSupply_, uint8 pool_) 
    external
    onlyAdmin
  {
    require(_rounds[index_].defined, "DefiYieldCrowdsale::updateRound: no round with provided index");
    require(_state != State.Closed, "DefiYieldCrowdsale::updateRound: sales is already closed");

    _rounds[index_].price = price_;
    _rounds[index_].totalSupply = totalSupply_;
    _rounds[index_].pool = pool_;

    emit RoundUpdated(index_, price_, totalSupply_);
  }

  /**
   * @dev Opens round for investment.
   * @param index_  round index.
   */
  function openRound(uint256 index_)
    external
    onlyAdmin 
  {
    require(_state == State.Open, "DefiYieldCrowdsale::openRound: sales is not open yet");
    require(_rounds[index_].defined, "DefiYieldCrowdsale::openRound: no round with provided index");
    require(_rounds[index_].state == State.None, "DefiYieldCrowdsale::openRound: round is already open or closed");

    if (_rounds[_activeRound].state == State.Open) {
      _rounds[_activeRound].state = State.Closed;
    }
    _rounds[index_].state = State.Open;
    _activeRound = index_;

    emit RoundOpened(index_);
  }

  /**
   * @dev Closes round for investment.
   * @param index_  round index.
   */
  function closeRound(uint256 index_)
    external
    onlyAdmin 
  {
    require(_state == State.Open, "DefiYieldCrowdsale::closeRound: sales is not open yet");
    require(_rounds[index_].defined, "DefiYieldCrowdsale::closeRound: no round with provided index");
    require(_rounds[index_].state == State.Open, "DefiYieldCrowdsale::closeRound: round is not open");

    _rounds[index_].state = State.Closed;

    emit RoundClosed(index_);
  }

  /**
   * @return the price value and decimals.
   */
  function getPrice()
    public
    view
    virtual
    override
    returns (uint256)
  {
    if (_rounds[_activeRound].state == State.Open) {
      return _rounds[_activeRound].price;
    }
    return 0;
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   * @param beneficiary_  whose tokens will be withdrawn.
   */
  function withdrawTokens(address beneficiary_)
    external
  {
    require(isClosed(), "DefiYieldCrowdsale::withdrawTokens: sales is not closed yet");
    uint256 roundsLength = _rounds.length;
    for (uint256 i; i < roundsLength; i++) {
      uint256 amount = _balances[beneficiary_][i];

      if (amount == 0) {
        continue;
      }

      _balances[beneficiary_][i] = 0;
      _tokensWithdrawn = _tokensWithdrawn + amount;
      uint256 directWithdrawAmount = (amount * _directWithdrawPercentage) / 100;
      uint256 vestingAmount = amount - directWithdrawAmount;

      if (directWithdrawAmount > 0) {
        getToken().safeTransfer(beneficiary_, directWithdrawAmount);
      }

      if (vestingAmount > 0) {
        _vesting.addBeneficiary(_rounds[i].pool, beneficiary_, vestingAmount);
      }
    }
  }

  /**
   * @return the balance of an account.
   * @param round_  round of sale.
   * @param account_  participant of round.
   */
  function balanceOf(uint256 round_, address account_)
    public
    view
    returns (uint256)
  {
    return _balances[account_][round_];
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period.
   * @param beneficiary_  token purchaser.
   * @param collateralAmount_  amount of collateral tokens involved in the purchase.
   */
  function _preValidatePurchase(address beneficiary_, uint256 collateralAmount_)
    internal
    view
    override
    onlyWhileOpen
  {
    require(_state == State.Open, "DefiYieldCrowdsale::_preValidatePurchase: sales is not open yet");
    require(_rounds[_activeRound].state == State.Open, "DefiYieldCrowdsale::_preValidatePurchase: sales round is not open yet");
    require(
      _rounds[_activeRound].totalSupply >= _rounds[_activeRound].investment + _getTokenAmount(collateralAmount_),
      "DefiYieldCrowdsale::_preValidatePurchase: exceeded round total supply"
    );

    super._preValidatePurchase(beneficiary_, collateralAmount_);
  }

  /**
   * @dev Overrides parent by updating round investment.
   * @param beneficiary_  token purchaser.
   * @param tokenAmount_  amount of tokens purchased.
   */
  function _processPurchase(address beneficiary_, uint256 tokenAmount_)
    internal
    virtual
    override
  {
    require(tokenBalance() >= (_tokensSold + tokenAmount_) - _tokensWithdrawn, "DefiYieldCrowdsale::_processPurchase: not enough tokens to buy");

    _rounds[_activeRound].investment = _rounds[_activeRound].investment + tokenAmount_;
    _balances[beneficiary_][_activeRound] = _balances[beneficiary_][_activeRound] + tokenAmount_;
    _tokensSold = _tokensSold + tokenAmount_;

    super._processPurchase(beneficiary_, tokenAmount_);
  }

  /**
   * @dev Source of tokens. Overridden so tokens are not transferred.
   * @param beneficiary_  address performing the token purchase.
   * @param tokenAmount_  number of tokens to be emitted.
   */
  function _deliverTokens(address beneficiary_, uint256 tokenAmount_)
    internal
    virtual
    override
  {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Allows to recover ERC20 from contract.
   * @param token_  ERC20 token address.
   * @param amount_  ERC20 token amount.
   */
  function recoverERC20(address token_, uint256 amount_)
    external
    onlyAdmin
  {
    if (address(getToken()) == token_) {
      // We don't allow to withdraw tokens already sold to investors
      uint256 tokensLocked = _tokensSold - _tokensWithdrawn;
      uint256 tokensAfterAdminWithdrawal = tokenBalance() - amount_;
      require(tokensAfterAdminWithdrawal >= tokensLocked, "DefiYieldCrowdsale::recoverERC20: cannot withdraw already sold tokens");
    }

    IERC20(token_).safeTransfer(getWallet(), amount_);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context {
  using SafeMath for uint8;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // The token being sold
  IERC20 private _token;

  // The token used as a payment
  IERC20 private _collateral;

  // Address where funds are collected
  address private _wallet;

  uint256 public constant PRICE_DECIMALS = 10 ** 5;
  uint256 private _price;

  // Amount of wei raised.
  uint256 private _collateralRaised;

  /**
   * Event for token purchase logging.
   * @param purchaser  who paid for the tokens.
   * @param beneficiary  who got the tokens.
   * @param value  collateral tokens paid for purchase.
   * @param amount  amount of tokens purchased.
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param price_ price of a token.
   * @param wallet_  address where collected funds will be forwarded to.
   * @param token_  address of the token being sold.
   * @param collateral_  address of the payment token.
   */
  constructor(uint256 price_, address wallet_, IERC20 token_, IERC20 collateral_) {
    require(price_ > 0, "Crowdsale: price value is 0");
    require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
    require(address(token_) != address(0), "Crowdsale: token is the zero address");
    require(address(collateral_) != address(0), "Crowdsale: collateral is the zero address");

    _price = price_;
    _wallet = wallet_;
    _token = token_;
    _collateral = collateral_;
  }

  /**
   * @return the token being sold.
   */
  function getToken()
    public
    view
    returns (IERC20)
  {
    return _token;
  }

  /**
   * @return the token being used as a payment.
   */
  function getCollateral()
    public
    view
    returns (IERC20)
  {
    return _collateral;
  }

  /**
   * @return the address where funds are collected.
   */
  function getWallet()
    public
    view
    returns (address)
  {
    return _wallet;
  }

  /**
   * @return price per token unit.
   */
  function getPrice()
    public
    view
    virtual
    returns (uint256)
  {
    return _price;
  }

  /**
   * @return the amount of collateral tokens raised.
   */
  function collateralRaised()
    external
    view
    returns (uint256)
  {
    return _collateralRaised;
  }

  /**
   * @dev Low level token purchase ***DO NOT OVERRIDE***
   * @param beneficiary_  recipient of the token purchase.
   * @param collateralAmount_  amount of collateral tokens involved in the purchase.
   */
  function buyTokens(address beneficiary_, uint256 collateralAmount_)
    external
  {
    _preValidatePurchase(beneficiary_, collateralAmount_);

    // transfer collateral tokens
    _collateral.safeTransferFrom(_msgSender(), address(this), collateralAmount_);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(collateralAmount_);

    // update state
    _collateralRaised = _collateralRaised + collateralAmount_;

    _processPurchase(beneficiary_, tokens);
    emit TokensPurchased(_msgSender(), beneficiary_, collateralAmount_, tokens);

    _updatePurchasingState(_msgSender(), collateralAmount_);

    _forwardFunds(collateralAmount_);
    _postValidatePurchase(beneficiary_, collateralAmount_);
  }

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
   * Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol's _preValidatePurchase method:
   *     super._preValidatePurchase(beneficiary, collateralAmount);
   *     require(collateralRaised().add(collateralAmount) <= cap);
   * @param beneficiary_  address performing the token purchase.
   * @param collateralAmount_  amount of collateral tokens involved in the purchase.
   */
  function _preValidatePurchase(address beneficiary_, uint256 collateralAmount_)
    internal
    view
    virtual
  {
    require(beneficiary_ != address(0), "Crowdsale::_preValidatePurchase: beneficiary is the zero address");
    require(collateralAmount_ != 0, "Crowdsale::_preValidatePurchase: collateralAmount is 0");

    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
   * conditions are not met.
   * @param beneficiary_  address performing the token purchase.
   * @param collateralAmount_  amount of collateral tokens involved in the purchase.
   */
  function _postValidatePurchase(address beneficiary_, uint256 collateralAmount_)
    internal
    view
    virtual
  {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
   * its tokens.
   * @param beneficiary_  address performing the token purchase.
   * @param tokenAmount_  number of tokens to be emitted.
   */
  function _deliverTokens(address beneficiary_, uint256 tokenAmount_)
    internal
    virtual
  {
    _token.safeTransfer(beneficiary_, tokenAmount_);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
   * tokens.
   * @param beneficiary_  address receiving the tokens
   * @param tokenAmount_  number of tokens to be purchased
   */
  function _processPurchase(address beneficiary_, uint256 tokenAmount_)
    internal
    virtual
  {
    _deliverTokens(beneficiary_, tokenAmount_);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions etc.)
   * @param beneficiary_  address receiving the tokens.
   * @param collateralAmount_  amount of collateral tokens involved in the purchase.
   */
  function _updatePurchasingState(address beneficiary_, uint256 collateralAmount_)
    internal
    virtual
  {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param collateralAmount_  amount of collateral tokens to be converted into tokens.
   * @return number of tokens that can be purchased with the specified collateralAmount.
   */
  function _getTokenAmount(uint256 collateralAmount_)
    internal
    view
    virtual
    returns (uint256)
  {
    uint8 tokenDecimals = IERC20Metadata(address(_token)).decimals();
    uint8 collateralDecimals = IERC20Metadata(address(_collateral)).decimals();
    if(tokenDecimals >= collateralDecimals) {
      return collateralAmount_
        .mul(PRICE_DECIMALS)
        .mul(10 ** tokenDecimals.sub(collateralDecimals))
        .div(getPrice());
    }
    return collateralAmount_
      .mul(PRICE_DECIMALS)
      .div(10 ** collateralDecimals.sub(tokenDecimals))
      .div(getPrice());
  }

  /**
   * @dev Determines how collateral tokens are stored/forwarded on purchases.
   * @param collateralAmount_  amount of collateral tokens to be stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 collateralAmount_)
    internal
    virtual
  {
    _collateral.safeTransfer(_wallet, collateralAmount_);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "../Crowdsale.sol";
import "../roles/KycRole.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale where users can contribute within cap validation.
 */
abstract contract CappedCrowdsale is Crowdsale, KycRole {
  uint256 private _minInvestment;
  mapping (KycLevel => uint256) private _cap;
  mapping(address => uint256) internal _investments;

  event MinInvestmentSet(uint256 minInvestment);
  event CapSet(KycLevel indexed level, uint256 cap);

  /**
   * @dev Returns min investment amount.
   */
  function getMinInvestment()
    public
    view
    returns (uint256)
  {
    return _minInvestment;
  }

  /**
   * @dev Sets min investment amount.
   * @param minInvestment_  investment amount.
   */
  function setMinInvestment(uint256 minInvestment_)
    external
    onlyAdmin
  {
    _minInvestment = minInvestment_;

    emit MinInvestmentSet(minInvestment_);
  }

  /**
   * @dev Returns KYC level cap.
   * @param level_  KYC level.
   */
  function getCap(KycLevel level_)
    public
    view
    returns (uint256)
  {
    return _cap[level_];
  }

  /**
   * @dev Returns cap according to KYC level.
   * @param account_  account to check.
   */
  function capOf(address account_)
    public
    view
    returns (uint256)
  {
    uint256 investments = _investments[account_];
    if(investments > _cap[kycLevelOf(account_)]) {
      return 0;
    }
    return _cap[kycLevelOf(account_)] - investments;
  }

  /**
   * @dev Sets cap per KYC level.
   * @param level_  KYC level.
   * @param cap_  new cap value.
   */
  function setCap(KycLevel level_, uint256 cap_)
    external
    onlyAdmin
  {
    if(level_ == KycLevel.low) {
      require(_cap[KycLevel.medium] >= cap_, "CappedCrowdsale::setCap: cap higher than medium cap");
    }
    if(level_ == KycLevel.medium) {
      require(_cap[KycLevel.high] >= cap_, "CappedCrowdsale::setCap: cap higher than high cap");
    }    
    _cap[level_] = cap_;
  
    emit CapSet(level_, cap_);
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be whitelisted. Note that no
   * restriction is imposed on the account sending the transaction.
   * @param beneficiary_ token beneficiary.
   * @param collateralAmount_ amount of collateral tokens involved in the purchase.
   */
  function _preValidatePurchase(address beneficiary_, uint256 collateralAmount_)
    internal
    view
    virtual
    override
  {
    require(_minInvestment <= collateralAmount_, "CappedCrowdsale::_preValidatePurchase: investment amount too low");
    require(capOf(beneficiary_) >= collateralAmount_, "CappedCrowdsale::_preValidatePurchase: exceeded cap");

    super._preValidatePurchase(beneficiary_, collateralAmount_);
  }

  /**
   * @dev Updating investment balance to check for limits.
   * @param beneficiary_  address receiving the tokens.
   * @param collateralAmount_  amount of collateral tokens involved in the purchase.
   */
  function _updatePurchasingState(address beneficiary_, uint256 collateralAmount_)
    internal
    virtual
    override
  {
    _investments[beneficiary_] = _investments[beneficiary_] + collateralAmount_;

    super._updatePurchasingState(beneficiary_, collateralAmount_);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DefiYieldTokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 lockedAmount;
    uint256 withdrawn;
  }

  struct PoolInfo {
    uint8 index;
    string name;
    uint256 startTime;
    uint256 endTime;
    uint256 totalLocked;
    uint256 initialStartTime;
    uint256 initialEndTime;
  }

  uint256 public constant ALLOWED_VESTING_UPDATE_THRESHOLD = 120 days;

  IERC20 public token;
  PoolInfo[] public lockPools;
  mapping(uint8 => mapping(address => UserInfo)) internal userInfo;

  event BeneficiaryAdded(uint8 indexed pid, address indexed beneficiary, uint256 value);
  event Claimed(uint8 indexed pid, address indexed beneficiary, uint256 value);
  event VestingPoolInitiated(uint8 indexed pid, string name, uint256 startTime, uint256 endTime);
  event VestingPoolUpdated(uint8 indexed pid, string name, uint256 startTime, uint256 endTime);
  event ERC20Recovered(address token, uint256 amount);
  event EtherRecovered(uint256 amount);

  constructor(address token_) {
    token = IERC20(token_);
  }

  /**
   * @dev Allows to recover erc20 tokens.
   * @param token_  token address.
   * @param amount_  amount to be recovered.
   */
  function recoverErc20(address token_, uint256 amount_) external onlyOwner {
    require(token_ != address(token), "DefiYieldTokenVesting::recoverErc20: cannot recover vesting tokens");
    IERC20(token_).safeTransfer(_msgSender(), amount_);

    emit ERC20Recovered(token_, amount_);
  }

  /**
   * @dev Allows to recover ether from contract.
   */
  function recoverEther() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool success, ) = _msgSender().call{value: balance}("");
    require(success, "DefiYieldTokenVesting::recoverEther: failed to send Ether");

    emit EtherRecovered(balance);
  }

  /**
   * @dev Initialize new vesting pool.
   * @param name_  name of pool.
   * @param startTime_  pool start time.
   * @param endTime_  pool end time.
   */
  function initVestingPool(string calldata name_, uint256 startTime_, uint256 endTime_)
    external
    onlyOwner 
    returns (uint8) 
  {
    require(block.timestamp < startTime_, "DefiYieldTokenVesting::initVestingPool: invalid pool start time");
    require(startTime_ < endTime_, "DefiYieldTokenVesting::initVestingPool: invalid pool end time");

    uint8 pid = (uint8)(lockPools.length);

    lockPools.push(
      PoolInfo({
        name: name_,
        startTime: startTime_,
        endTime: endTime_,
        initialStartTime: startTime_,
        initialEndTime: endTime_,
        totalLocked: 0,
        index: pid
      })
    );

    emit VestingPoolInitiated(pid, name_, startTime_, endTime_);
    return pid;
  }

  /**
   * @dev Sets new parameters to the vesting pool.
   * @param pid_  pool id.
   * @param name_  name of pool.
   * @param startTime_  pool start time.
   * @param endTime_  pool end time.
   */
  function setVestingPool(uint8 pid_, string calldata name_, uint256 startTime_, uint256 endTime_)
    external
    onlyOwner
  {
    require(lockPools[pid_].startTime != 0, "DefiYieldTokenVesting::setVestingPool: pool does not exist");
    require(lockPools[pid_].startTime > block.timestamp, "DefiYieldTokenVesting::setVestingPool: pool is already running");
    require(startTime_ > block.timestamp, "DefiYieldTokenVesting::setVestingPool: invalid pool start time");
    require(startTime_ < endTime_,"DefiYieldTokenVesting::setVestingPool: invalid pool end time");
    require(lockPools[pid_].initialStartTime.add(ALLOWED_VESTING_UPDATE_THRESHOLD) >= startTime_,
      "DefiYieldTokenVesting::setVestingPool: new start date is to large"
    );
    require(lockPools[pid_].initialStartTime.sub(ALLOWED_VESTING_UPDATE_THRESHOLD) <= startTime_,
      "DefiYieldTokenVesting::setVestingPool: new start date is to small"
    );
    require(lockPools[pid_].initialEndTime.add(ALLOWED_VESTING_UPDATE_THRESHOLD) >= endTime_,
      "DefiYieldTokenVesting::setVestingPool: new end date is to large"
    );
    require(lockPools[pid_].initialEndTime.sub(ALLOWED_VESTING_UPDATE_THRESHOLD) <= endTime_,
      "DefiYieldTokenVesting::setVestingPool: new end date is to small"
    );

    lockPools[pid_].name = name_;
    lockPools[pid_].startTime = startTime_;
    lockPools[pid_].endTime = endTime_;

    emit VestingPoolUpdated(pid_, name_, startTime_, endTime_);
  }

  /**
   * @dev Adds new beneficiary to the pool.
   * @param pid_  pool id.
   * @param beneficiary_  new beneficiary.
   * @param lockedAmount_  amount to be locked for distribution.
   */
  function addBeneficiary(uint8 pid_, address beneficiary_, uint256 lockedAmount_)
    external
  {
    require(pid_ < lockPools.length, "DefiYieldTokenVesting::addBeneficiary: non existing pool");

    token.safeTransferFrom(_msgSender(), address(this), lockedAmount_);
    userInfo[pid_][beneficiary_].lockedAmount = userInfo[pid_][beneficiary_].lockedAmount.add(lockedAmount_);
    lockPools[pid_].totalLocked = lockPools[pid_].totalLocked.add(lockedAmount_);

    emit BeneficiaryAdded(pid_, beneficiary_, lockedAmount_);
  }

  /**
   * @dev Adds new beneficiaries to the pool.
   * @param pid_  pool id.
   * @param beneficiaries_  array of beneficiaries.
   * @param lockedAmounts_  array of amounts to be locked for distribution.
   */
  function addBeneficiaryBatches(uint8 pid_, address[] calldata beneficiaries_, uint256[] calldata lockedAmounts_)
    external
  {
    require(beneficiaries_.length == lockedAmounts_.length, "DefiYieldTokenVesting::addBeneficiaryBatches: params invalid length");
    require(pid_ < lockPools.length, "DefiYieldTokenVesting::addBeneficiaryBatches: non existing pool");

    uint256 totalLockedAmounts;
    for (uint8 i = 0; i < lockedAmounts_.length; i++) {
      totalLockedAmounts = totalLockedAmounts.add(lockedAmounts_[i]);
    }
    token.safeTransferFrom(_msgSender(), address(this), totalLockedAmounts);

    uint256 beneficiariesLength = beneficiaries_.length;
    for (uint8 i = 0; i < beneficiariesLength; i++) {
      address beneficiary = beneficiaries_[i];
      uint256 lockedAmount = lockedAmounts_[i];

      userInfo[pid_][beneficiary].lockedAmount = userInfo[pid_][beneficiary].lockedAmount.add(lockedAmount);
      lockPools[pid_].totalLocked = lockPools[pid_].totalLocked.add(lockedAmount);

      emit BeneficiaryAdded(pid_, beneficiary, lockedAmount);
    }
  }

  /**
   * @dev Allows to claim beneficiary locked amount.
   * @param pid_  pool id.
   */
  function claim(uint8 pid_) external returns (uint256 amount) {
    amount = getReleasableAmount(pid_, _msgSender());
    require(amount > 0, "DefiYieldTokenVesting::claim: can't claim 0 amount");

    userInfo[pid_][_msgSender()].withdrawn = userInfo[pid_][_msgSender()].withdrawn.add(amount);
    token.safeTransfer(_msgSender(), amount);

    emit Claimed(pid_, _msgSender(), amount);
  }

  /**
   * @dev Returns amount of releasable funds per beneficiary.
   * @param pid_  pool id.
   * @param beneficiary_  beneficiary address.
   */
  function getReleasableAmount(uint8 pid_, address beneficiary_)
    public
    view
    returns (uint256)
  {
    return getVestedAmount(pid_, beneficiary_, block.timestamp).sub(userInfo[pid_][beneficiary_].withdrawn);
  }

  /**
   * @dev Returns amount of available for vesting token per beneficiary and time.
   * @param pid_  pool id.
   * @param beneficiary_  beneficiary address.
   * @param time_  time of vesting.
   */
  function getVestedAmount(uint8 pid_, address beneficiary_, uint256 time_)
    public
    view
    returns (uint256)
  {
    if (pid_ >= lockPools.length) { return 0; }
    if (time_ < lockPools[pid_].startTime) { return 0; }

    uint256 lockedAmount = userInfo[pid_][beneficiary_].lockedAmount;
    if (lockedAmount == 0) { return 0; }

    uint256 vestingDuration = lockPools[pid_].endTime.sub(lockPools[pid_].startTime);
    uint256 timeDuration = time_.sub(lockPools[pid_].startTime);
    uint256 amount = lockedAmount.mul(timeDuration).div(vestingDuration);

    if (amount > lockedAmount) {
      amount = lockedAmount;
    }
    return amount;
  }

  /**
   * @dev Returns beneficiary details per pool.
   * @param pid_  pool id.
   * @param beneficiary_  beneficiary address.
   */
  function getBeneficiaryInfo(uint8 pid_, address beneficiary_)
    external
    view
    returns (
      address beneficiary,
      uint256 totalLocked,
      uint256 withdrawn,
      uint256 releasableAmount,
      uint256 currentTime
    )
  {
    beneficiary = beneficiary_;
    currentTime = block.timestamp;

    if (pid_ < lockPools.length) {
      totalLocked = userInfo[pid_][beneficiary_].lockedAmount;
      withdrawn = userInfo[pid_][beneficiary_].withdrawn;
      releasableAmount = getReleasableAmount(pid_, beneficiary_);
    }
  }

  /**
   * @dev Returns amount of pools
   */
  function getPoolsCount() external view returns (uint256 poolsCount) {
    return lockPools.length;
  }

  /**
   * @dev Returns pool details
   * @param pid_  pool id
   */
  function getPoolInfo(uint8 pid_)
    external
    view
    returns (
      string memory name,
      uint256 totalLocked,
      uint256 startTime,
      uint256 endTime
    )
  {
    if (pid_ < lockPools.length) {
      name = lockPools[pid_].name;
      totalLocked = lockPools[pid_].totalLocked;
      startTime = lockPools[pid_].startTime;
      endTime = lockPools[pid_].endTime;
    }
  }

  /**
   * @dev Returns total locked funds
   */
  function getTotalLocked()
    external
    view
    returns (uint256 totalLocked)
  {
    for (uint8 i = 0; i < lockPools.length; i++) {
      totalLocked = totalLocked.add(lockPools[i].totalLocked);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./Roles.sol";
import "./AdminRole.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title KycRole
 * @dev Kyc accounts have been approved by the admin to perform certain actions (e.g. participate in a crowdsale).
 * This role is special in that the only accounts that can add it are admins (who can also remove it).
 */
contract KycRole is Context, AdminRole {
  using Roles for Roles.Role;

  enum KycLevel { low, medium, high }
  mapping(address => KycLevel) private _kycAccounts;

  event KycLevelSet(address indexed account, KycLevel levels);

  /**
   * @dev Returns account's KYC level.
   * @param account_  account to check.
   */
  function kycLevelOf(address account_)
    public
    view
    returns (KycLevel)
  {
    return _kycAccounts[account_];
  }

  /**
   * @dev Sets account's KYC level.
   * @param account_  account to set level for.
   * @param level_  KYC level.
   */
  function setKyc(address account_, KycLevel level_)
    public
    onlyAdmin
  {
    _kycAccounts[account_] = level_;

    emit KycLevelSet(account_, level_);
  }

  /**
   * @dev Sets KYC levels to accounts in batches.
   * @param accounts_  accounts array to set level for.
   * @param levels_  KYC levels.
   */
  function setKycBatches(address[] calldata accounts_, KycLevel[] calldata levels_)
    external
    onlyAdmin
  {
    require(accounts_.length == levels_.length, "KycRole::setKycBatches: mismatch in accounts and levels length");

    uint256 length = accounts_.length;
    for (uint256 index = 0; index < length; index++) {
      _kycAccounts[accounts_[index]] = levels_[index];

      emit KycLevelSet(accounts_[index], levels_[index]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role_, address account_)
    internal
  {
    require(!has(role_, account_), "Roles::add: account already has role");
    role_.bearer[account_] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role_, address account_)
    internal
  {
    require(has(role_, account_), "Roles::remove: account does not have role");
    role_.bearer[account_] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role_, address account_)
    internal
    view
    returns (bool)
  {
    require(account_ != address(0), "Roles::has: account is the zero address");
    return role_.bearer[account_];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./Roles.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title AdminRole
 * @dev Admins are responsible for assigning and removing whitelisted/capped accounts.
 */
contract AdminRole is Context {
  using Roles for Roles.Role;

  Roles.Role private _admins;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  constructor() {
    _addAdmin(_msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(_msgSender()), "AdminRole: caller does not have the admin role");
    _;
  }

  /**
   * @dev Checks if an account is admin.
   * @param account_  account to check.
   */
  function isAdmin(address account_)
    public
    view
    returns (bool)
  {
    return _admins.has(account_);
  }

  /**
   * @dev Grants admin role to account.
   * @param account_  account to add role to.
   */
  function addAdmin(address account_)
    external
    onlyAdmin
  {
    _addAdmin(account_);
  }

  /**
   * @dev Renounces admin role.
   */
  function renounceAdmin()
    external
  {
    _removeAdmin(_msgSender());
  }

  function _addAdmin(address account_)
    internal
  {
    _admins.add(account_);
    emit AdminAdded(account_);
  }

  function _removeAdmin(address account_)
    internal
  {
    _admins.remove(account_);
    emit AdminRemoved(account_);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}