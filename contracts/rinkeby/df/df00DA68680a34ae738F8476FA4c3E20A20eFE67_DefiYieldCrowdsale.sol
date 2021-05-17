// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // The token being sold
  IERC20 private _token;

  // The token used as a payment
  IERC20 private _collateral;

  // Address where funds are collected
  address payable private _wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 private _rate;

  // Amount of wei raised
  uint256 private _collateralRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value collateral tokens paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param rate Number of token units a buyer gets per wei
   * @dev The rate is the conversion between wei and the smallest and indivisible
   * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
   * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
   * @param wallet Address where collected funds will be forwarded to
   * @param token Address of the token being sold
   * @param collateral Address of the payment token
   */
  constructor (uint256 rate, address payable wallet, IERC20 token, IERC20 collateral) {
    require(rate > 0, "Crowdsale: rate is 0");
    require(wallet != address(0), "Crowdsale: wallet is the zero address");
    require(address(token) != address(0), "Crowdsale: token is the zero address");
    require(address(collateral) != address(0), "Crowdsale: collateral is the zero address");

    _rate = rate;
    _wallet = wallet;
    _token = token;
    _collateral = collateral;
  }

  /**
   * @return the token being sold.
   */
  function getToken() public view returns (IERC20) {
    return _token;
  }

  /**
   * @return the token being used as a payment.
   */
  function getCollateral() public view returns (IERC20) {
    return _collateral;
  }

  /**
   * @return the address where funds are collected.
   */
  function getWallet() public view returns (address payable) {
    return _wallet;
  }

  /**
   * @return the number of token units a buyer gets per wei.
   */
  function getRate() public virtual view returns (uint256) {
    return _rate;
  }

  /**
  * @return the amount of collateral tokens raised.
  */
  function collateralRaised() public view returns (uint256) {
    return _collateralRaised;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param beneficiary Recipient of the token purchase
   * @param collateralAmount Amount of collateral tokens involved in the purchase
   */
  function buyTokens(address beneficiary, uint256 collateralAmount) public {
    _preValidatePurchase(beneficiary, collateralAmount);

    // transfer collateral tokens
    _collateral.safeTransferFrom(_msgSender(), address(this), collateralAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(collateralAmount);

    // update state
    _collateralRaised = _collateralRaised.add(collateralAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(_msgSender(), beneficiary, collateralAmount, tokens);

    _updatePurchasingState(beneficiary, collateralAmount);

    _forwardFunds(collateralAmount);
    _postValidatePurchase(beneficiary, collateralAmount);
  }

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
   * Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol's _preValidatePurchase method:
   *     super._preValidatePurchase(beneficiary, collateralAmount);
   *     require(collateralRaised().add(collateralAmount) <= cap);
   * @param beneficiary Address performing the token purchase
   * @param collateralAmount Amount of collateral tokens involved in the purchase
   */
  function _preValidatePurchase(address beneficiary, uint256 collateralAmount) virtual internal view {
    require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
    require(collateralAmount != 0, "Crowdsale: collateralAmount is 0");
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
   * conditions are not met.
   * @param beneficiary Address performing the token purchase
   * @param collateralAmount Amount of collateral tokens involved in the purchase
   */
  function _postValidatePurchase(address beneficiary, uint256 collateralAmount) virtual internal view {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
   * its tokens.
   * @param beneficiary Address performing the token purchase
   * @param tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address beneficiary, uint256 tokenAmount) virtual internal {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
   * tokens.
   * @param beneficiary Address receiving the tokens
   * @param tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address beneficiary, uint256 tokenAmount) virtual internal {
    _deliverTokens(beneficiary, tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions,
   * etc.)
   * @param beneficiary Address receiving the tokens
   * @param collateralAmount Amount of collateral tokens involved in the purchase
   */
  function _updatePurchasingState(address beneficiary, uint256 collateralAmount) virtual internal {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param collateralAmount Amount of collateral tokens to be converted into tokens
   * @return Number of tokens that can be purchased with the specified collateralAmount
   */
  function _getTokenAmount(uint256 collateralAmount) virtual internal view returns (uint256) {
    return collateralAmount.mul(getRate());
  }

  /**
   * @dev Determines how collateral tokens are stored/forwarded on purchases.
   * @param collateralAmount Amount of collateral tokens to be stored/forwarded on purchases
   */
  function _forwardFunds(uint256 collateralAmount) virtual internal {
    _collateral.safeTransfer(_wallet, collateralAmount);
  }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.3;

import "./Crowdsale.sol";
import "../vesting/TokenVesting.sol";
import "./validation/WhitelistCrowdsale.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DefiYieldCrowdsale is WhitelistCrowdsale {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  enum State {
    None,
    Open,
    Closed
  }

  struct Round {
    bool defined;
    State state;
    uint256 rate;
    uint256 investment;
    uint256 totalSupply;
  }

  uint8 private _pool;
  TokenVesting private _vesting;

  mapping(address => uint256) private _balances;

  State private _state;
  Round[] private _rounds;
  uint256 private _activeRound;

  uint256 private _tokensSold;
  uint256 private _tokensWithdrawn;

  event SaleStateUpdated(State state);
  event RoundOpened(uint256 indexed index);
  event RoundClosed(uint256 indexed index);
  event RoundAdded(uint256 rate, uint256 totalSupply);
  event RoundUpdated(uint256 indexed index, uint256 rate, uint256 totalSupply);
  event RoundTotalSupplyUpdated(uint256 indexed index, uint256 totalSupply);

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(isOpen(), "DefiYieldCrowdsale: not open");
    _;
  }

  constructor(address payable wallet, IERC20 token, IERC20 collateral, TokenVesting vesting, uint8 pool)
    Crowdsale(1, wallet, token, collateral) {

    _vesting = vesting;
    _pool = pool;

    token.approve(address(_vesting), 2**256 - 1);
  }

  /**
   * @dev Returns vesting contract address
   */
  function getVestingAddress() external view returns (TokenVesting) {
    return _vesting;
  }

  /**
   * @dev Returns total tokens sold
   */
  function getTokensSold() external view returns (uint256) {
    return _tokensSold;
  }

  /**
   * @dev Returns total tokens withdrawn
   */
  function getTokensWithdrawn() external view returns (uint256) {
    return _tokensWithdrawn;
  }

  /**
   * @dev Returns active round
   */
  function getActiveRound() external view returns (uint256) {
    return _activeRound;
  }

  /**
   * @dev Returns round by index
   * @param index Round index
   */
  function getRound(uint256 index) external view returns (Round memory) {
    return _rounds[index];
  }

  /**
   * @dev Returns vesting pool
   */
  function getVestingPool() external view returns (uint8) {
    return _pool;
  }

  /**
   * @dev Returns sale token balance
   */
  function tokenBalance() public view returns (uint256) {
    return getToken().balanceOf(address(this));
  }

  /**
   * @return True if the crowdsale is open, false otherwise.
   */
  function isOpen() public view returns (bool) {
    return _state == State.Open;
  }

  /**
   * @dev True if the crowdsale is closed, false otherwise.
   */
  function hasClosed() public view returns (bool) {
    return _state == State.Closed;
  }

  /**
   * @dev Opens the sale
   */
  function openSale() external onlyAdmin {
    require(_state == State.None, "DefiYieldCrowdsale: sales is already open or closed");
    _state = State.Open;

    emit SaleStateUpdated(_state);
  }

  /**
   * @dev Closes the sale
   */
  function closeSale() external onlyAdmin {
    require(_state == State.Open, "DefiYieldCrowdsale: sales is already closed or not open");
    _state = State.Closed;

    emit SaleStateUpdated(_state);
  }

  /**
   * @dev Adds new round
   * @param rate Number of token units a buyer gets per wei
   * @param totalSupply Max amount of tokens available in round
   */
  function addRound(uint256 rate, uint256 totalSupply) external onlyAdmin {
    require(_state == State.None, "DefiYieldCrowdsale: sales is already open or closed");

    _rounds.push(Round({
      defined: true,
      state: State.None,
      rate: rate,
      investment: 0,
      totalSupply: totalSupply
    }));

    emit RoundAdded(rate, totalSupply);
  }

  /**
   * @dev Updates round parameters
   * @param index Round index
   * @param rate Number of token units a buyer gets per wei
   * @param totalSupply Max amount of tokens available in round
   */
  function updateRound(uint256 index, uint256 rate, uint256 totalSupply) external onlyAdmin {
    require(_state == State.None, "DefiYieldCrowdsale: sales is already open or closed");
    require(_rounds[index].defined, "DefiYieldCrowdsale: no round with provided index");

    _rounds[index].rate = rate;
    _rounds[index].totalSupply = totalSupply;

    emit RoundUpdated(index, rate, totalSupply);
  }

  /**
   * @dev Updates round total supply
   * @param index Round index
   * @param totalSupply Max amount of tokens available in round
   */
  function updateRoundTotalSupply(uint256 index, uint256 totalSupply) external onlyAdmin {
    require(_rounds[index].defined, "DefiYieldCrowdsale: no round with provided index");
    _rounds[index].totalSupply = totalSupply;

    emit RoundTotalSupplyUpdated(index, totalSupply);
  }

  /**
   * @dev Opens round for investment
   * @param index Round index
   */
  function openRound(uint256 index) external onlyAdmin {
    require(_state == State.Open, "DefiYieldCrowdsale: sales is not open yet");
    require(_rounds[index].defined, "DefiYieldCrowdsale: no round with provided index");

    if(_rounds[_activeRound].state == State.Open) {
      _rounds[_activeRound].state = State.Closed;
    }
    _rounds[index].state = State.Open;
    _activeRound = index;

    emit RoundOpened(index);
  }

  /**
   * @dev Closes round for investment
   * @param index Round index
   */
  function closeRound(uint256 index) external onlyAdmin {
    require(_state == State.Open, "DefiYieldCrowdsale: sales is not open yet");
    require(_rounds[index].defined, "DefiYieldCrowdsale: no round with provided index");

    _rounds[index].state = State.Closed;

    emit RoundClosed(index);
  }

  /**
   * @return the number of token units a buyer gets per wei.
   */
  function getRate() public virtual override view returns (uint256) {
    if(_rounds[_activeRound].state == State.Open) {
      return _rounds[_activeRound].rate;
    }
    return 0;
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   * @param beneficiary Whose tokens will be withdrawn.
   */
  function withdrawTokens(address beneficiary) public virtual {
    require(hasClosed(), "DefiYieldCrowdsale: sales is not closed yet");
    uint256 amount = _balances[beneficiary];
    require(amount > 0, "DefiYieldCrowdsale: beneficiary is not due any tokens");

    _balances[beneficiary] = 0;
    _tokensWithdrawn = _tokensWithdrawn.add(amount);
    _vesting.addBeneficiary(_pool, beneficiary, amount);
  }

  /**
   * @return the balance of an account.
   */
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period.
   * @param beneficiary Token purchaser
   * @param collateralAmount Amount of collateral tokens involved in the purchase
   */
  function _preValidatePurchase(address beneficiary, uint256 collateralAmount) internal override onlyWhileOpen view {
    require(_state == State.Open, "DefiYieldCrowdsale: sales is not open yet");
    require(_rounds[_activeRound].state == State.Open, "DefiYieldCrowdsale: sales round is not open yet");
    require(_rounds[_activeRound].totalSupply >= _rounds[_activeRound].investment.add(_getTokenAmount(collateralAmount)), "DefiYieldCrowdsale: exceeded round total supply");

    super._preValidatePurchase(beneficiary, collateralAmount);
  }

  /**
   * @dev Overrides parent by updating round investment.
   * @param beneficiary Token purchaser
   * @param tokenAmount Amount of tokens purchased
   */
  function _processPurchase(address beneficiary, uint256 tokenAmount) internal virtual override {
    require(tokenBalance() >= _tokensSold.add(tokenAmount).sub(_tokensWithdrawn), "DefiYieldCrowdsale: not enough tokens to buy");

    _rounds[_activeRound].investment = _rounds[_activeRound].investment.add(tokenAmount);
    _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    _tokensSold = _tokensSold.add(tokenAmount);

    super._processPurchase(beneficiary, tokenAmount);
  }

  /**
   * @dev Allows to recover ether from contract
   */
  function recoverEther() external onlyAdmin {
    (bool success,) = getWallet().call{value: address(this).balance}('');
    require(success, "DefiYieldCrowdsale: Failed to send Ether");
  }

  /**
   * @dev Allows to recover ERC20 from contract
   * @param token ERC20 token address
   * @param amount ERC20 token amount
   */
  function recoverERC20(address token, uint256 amount) external onlyAdmin {
    if (address(getToken()) == token) {
      // We don't allow to withdraw tokens already sold to investors
      uint256 tokensLocked = _tokensSold.sub(_tokensWithdrawn);
      uint256 tokensAfterAdminWithdrawal = tokenBalance().sub(amount);
      require(tokensLocked >= tokensAfterAdminWithdrawal, "DefiYieldCrowdsale: Cannot withdraw already sold tokens");
    }

    IERC20(token).safeTransfer(getWallet(), amount);
  }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.3;

import "./Roles.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title AdminRole
 * @dev Admins are responsible for assigning and removing whitelisted/capped accounts.
 */
contract AdminRole is Context {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _addAdmin(_msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(_msgSender()), "AdminRole: caller does not have the admin role");
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(_msgSender());
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.3;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal {
    require(!has(role, account), "Roles: account already has role");
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal {
    require(has(role, account), "Roles: account does not have role");
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "Roles: account is the zero address");
    return role.bearer[account];
  }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.3;

import "./Roles.sol";
import "./AdminRole.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a admin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are admins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, AdminRole {
  using Roles for Roles.Role;

  event WhitelistedAdded(address indexed account);
  event WhitelistedRemoved(address indexed account);

  Roles.Role private _whitelisteds;

  modifier onlyWhitelisted() {
    require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
    _;
  }

  function isWhitelisted(address account) public view returns (bool) {
    return _whitelisteds.has(account);
  }

  function addWhitelisted(address account) public onlyAdmin {
    _addWhitelisted(account);
  }

  function removeWhitelisted(address account) public onlyAdmin {
    _removeWhitelisted(account);
  }

  function renounceWhitelisted() public {
    _removeWhitelisted(_msgSender());
  }

  function _addWhitelisted(address account) internal {
    _whitelisteds.add(account);
    emit WhitelistedAdded(account);
  }

  function _removeWhitelisted(address account) internal {
    _whitelisteds.remove(account);
    emit WhitelistedRemoved(account);
  }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.3;

import "../Crowdsale.sol";
import "../roles/WhitelistedRole.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title WhitelistCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
abstract contract WhitelistCrowdsale is Crowdsale, WhitelistedRole {
  using SafeMath for uint256;

  bool private _optional;
  uint256 private _maxWhitelistAmount;

  mapping(address => uint256) internal _investments;

  event WhitelistOptionalUpdated(bool optional);
  event MaxWhitelistAmountUpdated(uint256 maxWhitelistAmount);

  /**
   * @return is whitelist optional
   */
  function isWhitelistOptional() external view returns (bool) {
    return _optional;
  }

  /**
   * @return returns max whitelist amount without whitelist required
   */
  function getMaxWhitelistAmount() external view returns (uint256) {
    return _maxWhitelistAmount;
  }

  /**
   * @dev Sets whitelist optional
   * @param optional New value
   */
  function setWhitelistOptional(bool optional) onlyAdmin external {
    _optional = optional;

    emit WhitelistOptionalUpdated(_optional);
  }

  /**
   * @dev Sets max investment amount without whitelist
   * @param maxWhitelistAmount New value
   */
  function setMaxWhitelistAmount(uint256 maxWhitelistAmount) onlyAdmin external {
    _maxWhitelistAmount = maxWhitelistAmount;

    emit MaxWhitelistAmountUpdated(_maxWhitelistAmount);
  }

  /**
   * @dev Adds whitelisted accounts in batches
   * @param accounts Accounts array
   */
  function addWhitelistedBatches(address[] calldata accounts) external onlyAdmin {
    for (uint256 index = 0; index < accounts.length; index++) {
      _addWhitelisted(accounts[index]);
    }
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be whitelisted. Note that no
   * restriction is imposed on the account sending the transaction.
   * @param beneficiary Token beneficiary
   * @param collateralAmount Amount of collateral tokens involved in the purchase
   */
  function _preValidatePurchase(address beneficiary, uint256 collateralAmount) virtual override internal view {
    require(
      _optional
      || _maxWhitelistAmount >= _investments[beneficiary].add(collateralAmount) 
      || isWhitelisted(beneficiary),
      "WhitelistCrowdsale: beneficiary doesn't have the Whitelisted role or max investment amount without whitelist exceeded");
    
    super._preValidatePurchase(beneficiary, collateralAmount);
  }

  /**
   * @dev Updating investment balance to check for limits
   * @param beneficiary Address receiving the tokens
   * @param collateralAmount Amount of collateral tokens involved in the purchase
   */
  function _updatePurchasingState(address beneficiary, uint256 collateralAmount) virtual override internal {
    _investments[beneficiary] = _investments[beneficiary].add(collateralAmount);

    super._updatePurchasingState(beneficiary, collateralAmount);
  }
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
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
  }

  IERC20 public token;
  PoolInfo[] public lockPools;
  mapping (uint8 => mapping (address => UserInfo)) internal userInfo;

  event BeneficiaryAdded(uint8 indexed pid, address indexed beneficiary, uint256 value);
  event Claimed(uint8 indexed pid, address indexed beneficiary, uint256 value);
  event VestingPoolInitiated(uint8 indexed pid, string name, uint256 startTime, uint256 endTime);
  event VestingPoolUpdated(uint8 indexed pid, string name, uint256 startTime, uint256 endTime);
  event ERC20Recovered(address token, uint256 amount);
  event EtherRecovered(uint256 amount);

  constructor(address _token) {
    token = IERC20(_token);
  }

  /**
   * @param _token  token address
   * @param _amount amount to be recovered
   *
   * @dev method allows to recover erc20 tokens
   */
  function recoverERC20(address _token, uint256 _amount) external onlyOwner {
    require(_token != address(token), "TokenVesting: cannot recover vesting tokens");
    IERC20(_token).safeTransfer(_msgSender(), _amount);

    emit ERC20Recovered(_token, _amount);
  }

  /**
   * @dev Allows to recover ether from contract
   */
  function recoverEther() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool success,) = _msgSender().call{value: balance}('');
    require(success, "TokenVesting: Failed to send Ether");

    emit EtherRecovered(balance);
  }

  /**
   * @param _name       name of pool
   * @param _startTime  pool start time
   * @param _endTime    pool end time
   *
   * @dev method initialize new vesting pool
   */
  function initVestingPool(string calldata _name, uint256 _startTime, uint256 _endTime) external onlyOwner returns(uint8) {
    require(block.timestamp < _startTime, "TokenVesting: invalid pool start time");
    require(_startTime < _endTime, "TokenVesting: invalid pool end time");

    uint8 pid = (uint8)(lockPools.length);

    lockPools.push(PoolInfo({
      name: _name,
      startTime: _startTime,
      endTime: _endTime,
      totalLocked: 0,
      index: pid
    }));

    emit VestingPoolInitiated(pid, _name, _startTime, _endTime);

    return pid;
  }

  /**
   * @param _pid        pool id
   * @param _name       name of pool
   * @param _startTime  pool start time
   * @param _endTime    pool end time
   *
   * @dev method sets new parameters to the vesting pool
   */
  function setVestingPool(uint8 _pid, string calldata _name, uint256 _startTime, uint256 _endTime) external onlyOwner {
    require(lockPools[_pid].startTime != 0, "TokenVesting: pool does not exist");
    require(lockPools[_pid].startTime > block.timestamp, "TokenVesting: pool is already running");
    require(_startTime > block.timestamp, "TokenVesting: invalid pool start time");
    require(_startTime < _endTime, "TokenVesting: invalid pool end time");

    lockPools[_pid].name = _name;
    lockPools[_pid].startTime = _startTime;
    lockPools[_pid].endTime = _endTime;

    emit VestingPoolUpdated(_pid, _name, _startTime, _endTime);
  }

  /**
   * @param _pid            pool id
   * @param _beneficiary    new beneficiary
   * @param _lockedAmount   amount to be locked for distribution
   *
   * @dev method adds new beneficiary to the pool
   */
  function addBeneficiary(uint8 _pid, address _beneficiary, uint256 _lockedAmount) external {
    require(_pid < lockPools.length, "TokenVesting: non existing pool");

    token.safeTransferFrom(_msgSender(), address(this), _lockedAmount);
    userInfo[_pid][_beneficiary].lockedAmount = userInfo[_pid][_beneficiary].lockedAmount.add(_lockedAmount);
    lockPools[_pid].totalLocked = lockPools[_pid].totalLocked.add(_lockedAmount);

    emit BeneficiaryAdded(_pid, _beneficiary, _lockedAmount);
  }

  /**
   * @param _pid            pool id
   * @param _beneficiaries  array of beneficiaries
   * @param _lockedAmounts   array of amounts to be locked for distribution
   *
   * @dev method adds new beneficiaries to the pool
   */
  function addBeneficiaryBatches(uint8 _pid, address[] calldata _beneficiaries, uint256[] calldata _lockedAmounts) external {
    require(_beneficiaries.length == _lockedAmounts.length, "TokenVesting: params invalid length");
    require(_pid < lockPools.length, "TokenVesting: non existing pool");

    uint256 totalLockedAmounts;
    for(uint8 i = 0; i < _lockedAmounts.length; i++) {
      totalLockedAmounts = totalLockedAmounts.add(_lockedAmounts[i]);
    }
    token.safeTransferFrom(_msgSender(), address(this), totalLockedAmounts);

    for(uint8 i = 0; i < _beneficiaries.length; i++) {
      address beneficiary = _beneficiaries[i];
      uint256 lockedAmount = _lockedAmounts[i];

      userInfo[_pid][beneficiary].lockedAmount = userInfo[_pid][beneficiary].lockedAmount.add(lockedAmount);
      lockPools[_pid].totalLocked = lockPools[_pid].totalLocked.add(lockedAmount);

      emit BeneficiaryAdded(_pid, beneficiary, lockedAmount);
    }
  }

  /**
   * @param _pid  pool id
   *
   * @dev method allows to claim beneficiary locked amount
   */
  function claim(uint8 _pid) external returns(uint256 amount) {
    amount = getReleasableAmount(_pid, _msgSender());
    require (amount > 0, "TokenVesting: can't claim 0 amount");

    userInfo[_pid][_msgSender()].withdrawn = userInfo[_pid][_msgSender()].withdrawn.add(amount);
    token.safeTransfer(_msgSender(), amount);
    
    emit Claimed(_pid, _msgSender(), amount);
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   *
   * @dev method returns amount of releasable funds per beneficiary
   */
  function getReleasableAmount(uint8 _pid, address _beneficiary) public view returns(uint256) {
    return getVestedAmount(_pid, _beneficiary, block.timestamp).sub(userInfo[_pid][_beneficiary].withdrawn);
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   * @param _time         time of vesting
   *
   * @dev method returns amount of available for vesting token per beneficiary and time
   */
  function getVestedAmount(uint8 _pid, address _beneficiary, uint256 _time) public view returns(uint256) {
    if (_pid >= lockPools.length) {
      return 0;
    }
    
    if(_time < lockPools[_pid].startTime) {
      return 0;
    }

    uint256 lockedAmount = userInfo[_pid][_beneficiary].lockedAmount;
    if (lockedAmount == 0) {
      return 0;
    }

    uint256 vestingDuration = lockPools[_pid].endTime.sub(lockPools[_pid].startTime);
    uint256 timeDuration = _time.sub(lockPools[_pid].startTime);
    uint256 amount = lockedAmount.mul(timeDuration).div(vestingDuration);

    if (amount > lockedAmount){
      amount = lockedAmount;
    }
    return amount;
  }

  /**
   * @param _pid          pool id
   * @param _beneficiary  beneficiary address
   *
   * @dev method returns beneficiary details per pool
   */
  function getBeneficiaryInfo(uint8 _pid, address _beneficiary) external view
    returns(address beneficiary, uint256 totalLocked, uint256 withdrawn, uint256 releasableAmount, uint256 currentTime) {
      beneficiary = _beneficiary;
      currentTime = block.timestamp;

      if (_pid < lockPools.length) {
        totalLocked = userInfo[_pid][_beneficiary].lockedAmount;
        withdrawn = userInfo[_pid][_beneficiary].withdrawn;
        releasableAmount = getReleasableAmount(_pid, _beneficiary);
      }
  }

  /**
   *
   * @dev method returns amount of pools
   */
  function getPoolsCount() external view returns(uint256 poolsCount) {
    return lockPools.length;
  }

  /**
   * @param _pid pool id
   *
   * @dev method returns pool details
   */
  function getPoolInfo(uint8 _pid) external view 
    returns(string memory name, uint256 totalLocked, uint256 startTime, uint256 endTime) {
      if(_pid < lockPools.length) {
        name = lockPools[_pid].name;
        totalLocked = lockPools[_pid].totalLocked;
        startTime = lockPools[_pid].startTime;
        endTime = lockPools[_pid].endTime;
      }
  }

  /**
   *
   * @dev method returns total locked funds
   */
  function getTotalLocked() external view returns(uint256 totalLocked) {
    for(uint8 i = 0; i < lockPools.length; i++) {
      totalLocked = totalLocked.add(lockPools[i].totalLocked);
    }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 9999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}