pragma solidity 0.6.12;

import "./Governable.sol";

contract Controllable is Governable {

  constructor(address _storage) Governable(_storage) public {
  }

  modifier onlyController() {
    require(store.isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((store.isController(msg.sender) || store.isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return store.controller();
  }
}

pragma solidity 0.6.12;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

pragma solidity 0.6.12;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

pragma solidity 0.6.12;

import "./Vault.sol";
import "./Controllable.sol";

contract VaultFactory is Controllable {

  event NewVault(address vault);

  constructor(address _storage) Controllable(_storage) public {}

  function createVault(
    address _implementation,
    address _storage,
    address _underlying,
    uint256 _toInvestNumerator,
    uint256 _toInvestDenominator
  ) public onlyGovernance returns(address) {
    Vault(_implementation).initializeVault(_storage,
      _underlying,
      _toInvestNumerator,
      _toInvestDenominator
    );
    emit NewVault(_implementation);
    return _implementation;
  }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IController.sol";
import "./interfaces/IUpgradeSource.sol";
import "./ControllableInit.sol";
import "./VaultStorage.sol";

contract Vault is ERC20Upgradeable, IVault, IUpgradeSource, ControllableInit, VaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);
  event StrategyAnnounced(address newStrategy, uint256 time);
  event StrategyChanged(address newStrategy, address oldStrategy);


  constructor() public {
  }

  // the function is name differently to not cause inheritance clash in truffle and allows tests
  function initializeVault(
    address _storage,
    address _underlying,
    uint256 _toInvestNumerator,
    uint256 _toInvestDenominator
  ) public initializer {
    require(_toInvestNumerator <= _toInvestDenominator, "cannot invest more than 100%");
    require(_toInvestDenominator != 0, "cannot divide by 0");

    __ERC20_init(
      string(abi.encodePacked("VAULTY_", ERC20Upgradeable(_underlying).symbol())),
      string(abi.encodePacked("v", ERC20Upgradeable(_underlying).symbol()))
    );
    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    ControllableInit.initialize(
      _storage
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    uint256 implementationDelay = 12 hours;
    uint256 strategyChangeDelay = 12 hours;
    VaultStorage.initialize(
      _underlying,
      _toInvestNumerator,
      _toInvestDenominator,
      underlyingUnit,
      implementationDelay,
      strategyChangeDelay
    );
  }

  function strategy() public view override returns(address) {
    return _strategy();
  }

  function underlying() public view override returns(address) {
    return _underlying();
  }

  function underlyingUnit() public view returns(uint256) {
    return _underlyingUnit();
  }

  function vaultFractionToInvestNumerator() public view returns(uint256) {
    return _vaultFractionToInvestNumerator();
  }

  function vaultFractionToInvestDenominator() public view returns(uint256) {
    return _vaultFractionToInvestDenominator();
  }

  function nextImplementation() public view returns(address) {
    return _nextImplementation();
  }

  function nextImplementationTimestamp() public view returns(uint256) {
    return _nextImplementationTimestamp();
  }

  function nextImplementationDelay() public view returns(uint256) {
    return _nextImplementationDelay();
  }

  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "Strategy must be defined");
    _;
  }

  // Only smart contracts will be affected by this modifier
  modifier defense() {
    require(
      (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
                                                  // then the requirement will pass
      !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
      "This smart contract has been grey listed"  // make sure that it is not on our greyList.
    );
    _;
  }

  /**
  * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
  * doHardWork on the current strategy. Call this through controller to claim hard rewards.
  */
  function doHardWork() whenStrategyDefined onlyControllerOrGovernance external override {
    // ensure that new funds are invested too
    invest();
    IStrategy(strategy()).doHardWork();
  }

  /*
  * Returns the cash balance across all users in this contract.
  */
  function underlyingBalanceInVault() view public override returns (uint256) {
    return IERC20Upgradeable(underlying()).balanceOf(address(this));
  }

  /* Returns the current underlying (e.g., DAI's) balance together with
   * the invested amount (if DAI is invested elsewhere by the strategy).
  */
  function underlyingBalanceWithInvestment() view public override returns (uint256) {
    if (address(strategy()) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault();
    }
    return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
  }

  function getPricePerFullShare() public view override returns (uint256) {
    return totalSupply() == 0
        ? underlyingUnit()
        : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
  }

  /* get the user's share (in underlying)
  */
  function underlyingBalanceWithInvestmentForHolder(address holder) view external override returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
        .mul(balanceOf(holder))
        .div(totalSupply());
  }

  function futureStrategy() public view returns (address) {
    return _futureStrategy();
  }

  function strategyUpdateTime() public view returns (uint256) {
    return _strategyUpdateTime();
  }

  function strategyTimeLock() public view returns (uint256) {
    return _strategyTimeLock();
  }

  function canUpdateStrategy(address _strategy) public view returns(bool) {
    return strategy() == address(0) // no strategy was set yet
      || (_strategy == futureStrategy()
          && block.timestamp > strategyUpdateTime()
          && strategyUpdateTime() > 0); // or the timelock has passed
  }

  /**
  * Indicates that the strategy update will happen in the future
  */
  function announceStrategyUpdate(address _strategy) public override onlyControllerOrGovernance {
    // records a new timestamp
    uint256 when = block.timestamp.add(strategyTimeLock());
    _setStrategyUpdateTime(when);
    _setFutureStrategy(_strategy);
    emit StrategyAnnounced(_strategy, when);
  }

  /**
  * Finalizes (or cancels) the strategy update by resetting the data
  */
  function finalizeStrategyUpdate() public onlyControllerOrGovernance {
    _setStrategyUpdateTime(0);
    _setFutureStrategy(address(0));
  }

  function setStrategy(address _strategy) public override onlyControllerOrGovernance {
    require(canUpdateStrategy(_strategy),
      "The strategy exists and switch timelock did not elapse yet");
    require(_strategy != address(0), "new _strategy cannot be empty");
    require(IStrategy(_strategy).underlying() == address(underlying()), "Vault underlying must match Strategy underlying");
    require(IStrategy(_strategy).vault() == address(this), "the strategy does not belong to this vault");

    emit StrategyChanged(_strategy, strategy());
    if (address(_strategy) != address(strategy())) {
      if (address(strategy()) != address(0)) { // if the original strategy (no underscore) is defined
        IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
        IStrategy(strategy()).withdrawAllToVault();
      }
      _setStrategy(_strategy);
      IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
      IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
    }
    finalizeStrategyUpdate();
  }

  function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external override onlyGovernance {
    require(denominator > 0, "denominator must be greater than 0");
    require(numerator <= denominator, "denominator must be greater than or equal to the numerator");
    _setVaultFractionToInvestNumerator(numerator);
    _setVaultFractionToInvestDenominator(denominator);
  }

  function rebalance() external onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }

  function availableToInvestOut() public view returns (uint256) {
    uint256 wantInvestInTotal = underlyingBalanceWithInvestment()
        .mul(vaultFractionToInvestNumerator())
        .div(vaultFractionToInvestDenominator());
    uint256 alreadyInvested = IStrategy(strategy()).investedUnderlyingBalance();
    if (alreadyInvested >= wantInvestInTotal) {
      return 0;
    } else {
      uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
      return remainingToInvest <= underlyingBalanceInVault()
        // TODO: we think that the "else" branch of the ternary operation is not
        // going to get hit
        ? remainingToInvest : underlyingBalanceInVault();
    }
  }

  function invest() internal whenStrategyDefined {
    uint256 availableAmount = availableToInvestOut();
    if (availableAmount > 0) {
      IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
      emit Invest(availableAmount);
    }
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares.
  * Approval is assumed.
  */
  function deposit(uint256 amount) external override defense {
    _deposit(amount, msg.sender, msg.sender);
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares
  * assigned to the holder.
  * This facilitates depositing for someone else (using DepositHelper)
  */
  function depositFor(uint256 amount, address holder) public override defense {
    _deposit(amount, msg.sender, holder);
  }

  function withdrawAll() public onlyControllerOrGovernance override whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  function withdraw(uint256 numberOfShares) override external {
    require(totalSupply() > 0, "Vault has no shares");
    require(numberOfShares > 0, "numberOfShares must be greater than 0");
    uint256 totalSupply = totalSupply();
    _burn(msg.sender, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply);
    if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
      // withdraw everything from the strategy to accurately check the share value
      if (numberOfShares == totalSupply) {
        IStrategy(strategy()).withdrawAllToVault();
      } else {
        
        uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
        IStrategy(strategy()).withdrawToVault(missing);
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
          .mul(numberOfShares)
          .div(totalSupply), underlyingBalanceInVault());
    }

    IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

    // update the withdrawal amount for the holder
    emit Withdraw(msg.sender, underlyingAmountToWithdraw);
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(amount > 0, "Cannot deposit 0");
    require(beneficiary != address(0), "holder must be defined");

    if (address(strategy()) != address(0)) {
      require(IStrategy(strategy()).depositArbCheck(), "Too much arb");
    }

    uint256 toMint = totalSupply() == 0
        ? amount
        : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);

    IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

    // update the contribution amount for the beneficiary
    emit Deposit(beneficiary, amount);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function shouldUpgrade() external view override returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  function finalizeUpgrade() external override onlyGovernance {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity 0.6.12;

interface IStrategy {
    
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

pragma solidity 0.6.12;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;
    function announceStrategyUpdate(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

pragma solidity 0.6.12;

interface IController {
    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;
    function doHardWork(address _vault) external;
    function hasVault(address _vault) external returns(bool);

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);

    function feeRewardForwarder() external view returns(address payable);
    function setFeeRewardForwarder(address payable _value) external;
}

pragma solidity 0.6.12;

interface IUpgradeSource {
  function shouldUpgrade() external view returns (bool, address);
  function finalizeUpgrade() external;
}

pragma solidity 0.6.12;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() public {
  }

  function initialize(address _storage) public override initializer {
    GovernableInit.initialize(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract VaultStorage is Initializable {

  bytes32 internal constant _STRATEGY_SLOT = 0xf1a169aa0f736c2813818fdfbdc5755c31e0839c8f49831a16543496b28574ea;
  bytes32 internal constant _UNDERLYING_SLOT = 0x1994607607e11d53306ef62e45e3bd85762c58d9bf38b5578bc4a258a26a7371;
  bytes32 internal constant _UNDERLYING_UNIT_SLOT = 0xa66bc57d4b4eed7c7687876ca77997588987307cb13ecc23f5e52725192e5fff;
  bytes32 internal constant _VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT = 0x39122c9adfb653455d0c05043bd52fcfbc2be864e832efd3abc72ce5a3d7ed5a;
  bytes32 internal constant _VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT = 0x469a3bad2fab7b936c45eecd1f5da52af89cead3e2ed7f732b6f3fc92ed32308;
  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0xb1acf527cd7cd1668b30e5a9a1c0d845714604de29ce560150922c9d8c0937df;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x3bc747f4b148b37be485de3223c90b4468252967d2ea7f9fcbd8b6e653f434c9;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82ddc3be3f0c1a6870327f78f4979a0b37b21b16736ef5be6a7a7a35e530bcf0;
  bytes32 internal constant _STRATEGY_TIME_LOCK_SLOT = 0x6d02338b2e4c913c0f7d380e2798409838a48a2c4d57d52742a808c82d713d8b;
  bytes32 internal constant _FUTURE_STRATEGY_SLOT = 0xb441b53a4e42c2ca9182bc7ede99bedba7a5d9360d9dfbd31fa8ee2dc8590610;
  bytes32 internal constant _STRATEGY_UPDATE_TIME_SLOT = 0x56e7c0e75875c6497f0de657009613a32558904b5c10771a825cc330feff7e72;
  bytes32 internal constant _ALLOW_SHARE_PRICE_DECREASE_SLOT = 0x22f7033891e85fc76735ebd320e0d3f546da431c4729c2f6d2613b11923aaaed;
  bytes32 internal constant _WITHDRAW_BEFORE_REINVESTING_SLOT = 0x4215fbb95dc0890d3e1660fb9089350f2d3f350c0a756934874cae6febf42a79;

  constructor() public {
    assert(_STRATEGY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.strategy")) - 1));
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlying")) - 1));
    assert(_UNDERLYING_UNIT_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlyingUnit")) - 1));
    assert(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.vaultFractionToInvestNumerator")) - 1));
    assert(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.vaultFractionToInvestDenominator")) - 1));
    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextImplementationDelay")) - 1));
    assert(_STRATEGY_TIME_LOCK_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.strategyTimeLock")) - 1));
    assert(_FUTURE_STRATEGY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.futureStrategy")) - 1));
    assert(_STRATEGY_UPDATE_TIME_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.strategyUpdateTime")) - 1));
    assert(_ALLOW_SHARE_PRICE_DECREASE_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.allowSharePriceDecrease")) - 1));
    assert(_WITHDRAW_BEFORE_REINVESTING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.withdrawBeforeReinvesting")) - 1));
  }

  function initialize(
    address _underlying,
    uint256 _toInvestNumerator,
    uint256 _toInvestDenominator,
    uint256 _underlyingUnit,
    uint256 _implementationChangeDelay,
    uint256 _strategyChangeDelay
  ) public initializer {
    _setUnderlying(_underlying);
    _setVaultFractionToInvestNumerator(_toInvestNumerator);
    _setVaultFractionToInvestDenominator(_toInvestDenominator);
    _setUnderlyingUnit(_underlyingUnit);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setStrategyTimeLock(_strategyChangeDelay);
    _setStrategyUpdateTime(0);
    _setFutureStrategy(address(0));
    _setAllowSharePriceDecrease(false);
    _setWithdrawBeforeReinvesting(false);
  }

  function _setStrategy(address _address) internal {
    setAddress(_STRATEGY_SLOT, _address);
  }

  function _strategy() internal view returns (address) {
    return getAddress(_STRATEGY_SLOT);
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function _underlying() internal view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setUnderlyingUnit(uint256 _value) internal {
    setUint256(_UNDERLYING_UNIT_SLOT, _value);
  }

  function _underlyingUnit() internal view returns (uint256) {
    return getUint256(_UNDERLYING_UNIT_SLOT);
  }

  function _setVaultFractionToInvestNumerator(uint256 _value) internal {
    setUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT, _value);
  }

  function _vaultFractionToInvestNumerator() internal view returns (uint256) {
    return getUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT);
  }

  function _setVaultFractionToInvestDenominator(uint256 _value) internal {
    setUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT, _value);
  }

  function _vaultFractionToInvestDenominator() internal view returns (uint256) {
    return getUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT);
  }

  function _setAllowSharePriceDecrease(bool _value) internal {
    setBoolean(_ALLOW_SHARE_PRICE_DECREASE_SLOT, _value);
  }

  function _allowSharePriceDecrease() internal view returns (bool) {
    return getBoolean(_ALLOW_SHARE_PRICE_DECREASE_SLOT);
  }

  function _setWithdrawBeforeReinvesting(bool _value) internal {
    setBoolean(_WITHDRAW_BEFORE_REINVESTING_SLOT, _value);
  }

  function _withdrawBeforeReinvesting() internal view returns (bool) {
    return getBoolean(_WITHDRAW_BEFORE_REINVESTING_SLOT);
  }

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function _nextImplementation() internal view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function _nextImplementationTimestamp() internal view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function _nextImplementationDelay() internal view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function _setStrategyTimeLock(uint256 _value) internal {
    setUint256(_STRATEGY_TIME_LOCK_SLOT, _value);
  }

  function _strategyTimeLock() internal view returns (uint256) {
    return getUint256(_STRATEGY_TIME_LOCK_SLOT);
  }

  function _setFutureStrategy(address _value) internal {
    setAddress(_FUTURE_STRATEGY_SLOT, _value);
  }

  function _futureStrategy() internal view returns (address) {
    return getAddress(_FUTURE_STRATEGY_SLOT);
  }

  function _setStrategyUpdateTime(uint256 _value) internal {
    setUint256(_STRATEGY_UPDATE_TIME_SLOT, _value);
  }

  function _strategyUpdateTime() internal view returns (uint256) {
    return getUint256(_STRATEGY_UPDATE_TIME_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) private view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) private view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public virtual initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract TokenVesting {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using SafeMathUpgradeable for uint128;

    struct VestingPeriod {
        uint128 vestingDays;
        uint128 tokensPerDay;
    }

    struct VestingClaimInfo {
        uint128 lastClaim;
        uint64 periodIndex;
        uint64 daysClaimed;
    }

    //token to be distributed
    IERC20Upgradeable public token;
    //handles setup
    address public setupAdmin;
    //UTC timestamp from which first vesting period begins (i.e. tokens will first be released 30 days after this time)
    uint256 public startTime;
    //total token obligations from all unpaid vesting amounts
    uint256 public totalObligations;
    //tokens can't be claimed for lockingPeriod days
    uint256 public lockingPeriod;
    //keeps track of contract state
    bool public setupComplete;

    //list of all beneficiaries
    address[] public beneficiaries;

    //amount of tokens to be received by each beneficiary
    mapping(address => VestingPeriod[]) public vestingPeriods;
    mapping(address => VestingClaimInfo) public claimInfo;
    //tracks if addresses have already been added as beneficiaries or not
    mapping(address => bool) public beneficiaryAdded;

    event SetupCompleted();
    event BeneficiaryAdded(address indexed user, uint256 totalAmountToClaim);
    event TokensClaimed(address indexed user, uint256 amount);

    modifier setupOnly() {
        require(!setupComplete, "setup already completed");
        _;
    }

    modifier claimAllowed() {
        require(setupComplete, "setup ongoing");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == setupAdmin, "not admin");
        _;
    }

    constructor(
        IERC20Upgradeable _token,
        uint256 _startTime,
        uint256 _lockingPeriod
    ) public {
        token = _token;
        lockingPeriod = _lockingPeriod;
        setupAdmin = msg.sender;
        startTime = _startTime == 0 ? block.timestamp : _startTime;
    }

    // adds a list of beneficiaries
    function addBeneficiaries(address[] memory _beneficiaries, VestingPeriod[][] memory _vestingPeriods)
        external
        onlyAdmin
        setupOnly
    {
        require(_beneficiaries.length == _vestingPeriods.length, "input length mismatch");

        uint256 _totalObligations;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];

            require(!beneficiaryAdded[beneficiary], "beneficiary already added");
            beneficiaryAdded[beneficiary] = true;

            uint256 amountToClaim;

            VestingPeriod[] memory periods = _vestingPeriods[i];
            for (uint256 j = 0; j < periods.length; j++) {
                VestingPeriod memory period = periods[j];
                amountToClaim = amountToClaim.add(
                    uint256(period.vestingDays).mul(
                        uint256(period.tokensPerDay)
                    )
                );
                vestingPeriods[beneficiary].push(period);
            }

            beneficiaries.push(beneficiary);
            _totalObligations = _totalObligations.add(amountToClaim);

            emit BeneficiaryAdded(beneficiary, amountToClaim);
        }

        totalObligations = totalObligations.add(_totalObligations);
        token.safeTransferFrom(msg.sender, address(this), _totalObligations);
    }

    function tokensToClaim(address _beneficiary) public view returns(uint256) {        
        (uint256 tokensAmount,,) = _tokensToClaim(_beneficiary, claimInfo[_beneficiary]);
        return tokensAmount;
    }

    /**
        @dev This function returns tokensAmount available to claim. Calculates it based on several vesting periods if applicable.
     */
    function _tokensToClaim(address _beneficiary, VestingClaimInfo memory claim) private view returns(uint256 tokensAmount, uint256 currentPeriodDaysClaimed, uint64 periodIndex) {
        uint256 lastClaim = claim.lastClaim;
        if (lastClaim == 0) { // first time claim, set it to a contract start time
            lastClaim = startTime;
        }

        if (lastClaim > block.timestamp) {
            // has not started yet
            return (0, 0, 0);
        }

        uint256 daysElapsed = (block.timestamp.sub(lastClaim)).div(1 days);

        if (claim.lastClaim == 0)  { // first time claim
            // check for lock period
            if (daysElapsed > lockingPeriod) {
                // passed beyond locking period, adjust elapsed days by locking period
                daysElapsed = daysElapsed.sub(lockingPeriod);
            } else {
                // tokens are locked
                return (0, 0, 0);
            }
        }

        periodIndex = claim.periodIndex;
        uint256 totalPeriods = vestingPeriods[_beneficiary].length;

        // it's safe to assume that admin won't setup contract in such way, that this loop will be out of gas
        while (daysElapsed > 0 && totalPeriods > periodIndex) {
            VestingPeriod memory vestingPeriod = vestingPeriods[_beneficiary][periodIndex];
            // period is started, overwrite with claimed days from the last claim
            currentPeriodDaysClaimed = claim.daysClaimed;

            uint256 daysInPeriodToClaim = uint256(vestingPeriod.vestingDays).sub(currentPeriodDaysClaimed);
            if (daysInPeriodToClaim > daysElapsed) {
                daysInPeriodToClaim = daysElapsed;
            }

            tokensAmount = tokensAmount.add(
                uint256(vestingPeriod.tokensPerDay).mul(daysInPeriodToClaim)
            );

            daysElapsed = daysElapsed.sub(daysInPeriodToClaim);
            currentPeriodDaysClaimed = currentPeriodDaysClaimed.add(daysInPeriodToClaim);
            // at this point, if any days left to claim, it means that period was consumed
            
            // claimed days in the next period are 0
            claim.daysClaimed = 0;

            // move to the next period
            periodIndex++;
        }
    }

    // claims vested tokens for a given beneficiary
    function claimFor(address _beneficiary) external claimAllowed {
        _processClaim(_beneficiary);
    }

    // convenience function for beneficiaries to call to claim all of their vested tokens
    function claimForSelf() external claimAllowed {
        _processClaim(msg.sender);
    }

    // claims vested tokens for all beneficiaries
    function claimForAll() external claimAllowed {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _processClaim(beneficiaries[i]);
        }
    }

    // complete setup once all obligations are met, to remove the ability to
    // reclaim tokens until vesting is complete, and allow claims to start
    function endSetup() external onlyAdmin setupOnly {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= totalObligations, "obligations not yet met");
        setupComplete = true;
        setupAdmin = address(0);
        emit SetupCompleted();
    }

    // reclaim tokens if necessary prior to finishing setup. otherwise reclaim any
    // extra tokens after the end of vesting
    function reclaimTokens() external onlyAdmin setupOnly {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(setupAdmin, tokenBalance);
    }

    // Calculates the claimable tokens of a beneficiary and sends them.
    function _processClaim(address _beneficiary) internal {
        VestingClaimInfo memory claim = claimInfo[_beneficiary];
        (uint256 amountToClaim, uint256 daysClaimed, uint64 periodIndex) = _tokensToClaim(_beneficiary, claim);

        if (amountToClaim == 0) {
            return;
        }

        claim.daysClaimed = uint64(daysClaimed);
        claim.lastClaim = uint128(block.timestamp);
        claim.periodIndex = uint64(periodIndex.sub(1));
        claimInfo[_beneficiary] = claim;

        _sendTokens(_beneficiary, amountToClaim);

        emit TokensClaimed(_beneficiary, amountToClaim);
    }

    // send tokens to beneficiary and remove obligation
    function _sendTokens(address _beneficiary, uint256 _amountToSend) internal {
        totalObligations = totalObligations.sub(_amountToSend);
        token.safeTransfer(_beneficiary, _amountToSend);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  IERC20Upgradeable public tokenFrom;
  IERC20Upgradeable public tokenTo;

  constructor(IERC20Upgradeable _tokenFrom, IERC20Upgradeable _tokenTo) public {
    tokenFrom = _tokenFrom;
    tokenTo = _tokenTo;
  }

  function swap(uint256 amount) public {
    tokenFrom.safeTransferFrom(msg.sender, address(this), amount);
    tokenTo.safeTransfer(msg.sender, amount);
  }

  function reclaimTokens() public onlyOwner {
    tokenTo.transfer(msg.sender, tokenTo.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

contract TokenSale is Ownable {
  using SafeMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint256 public constant WHITELIST_DURATION = 20 minutes;
  uint256 public constant MIN_RESERVE_SIZE = 100 * (10 ** 18); // 100 BUSD
  uint256 public constant MAX_RESERVE_SIZE = 250 * (10 ** 18); // 250 BUSD
  // uint256 public constant HARD_CAP = 50000 * (10 ** 18); // 50 000 BUSD
  uint256 public constant TOKENS_PER_BUSD = 1.42857 * (10 ** 18);
  uint256 public constant VESTING_AMOUNT = 25; // 25 %
  uint256 public constant VESTING_AMOUNT_TOTAL = 100; // 100 %
  uint256 public constant VESTING_PERIOD = 30 days;
  uint256 public constant RATE_PRECISION = 10 ** 18;
  // IERC20Upgradeable constant BUSD = IERC20Upgradeable(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47); 
  // testnet: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56

  event Reserve(address indexed user, uint256 busd, uint256 totalReserve);
  event TokensClaimed(address indexed user, uint256 amount);

  mapping(address => uint256) public claimed;
  mapping(address => uint256) public claimTime;
  mapping(address => uint256) public reserves;
  mapping(address => bool) public whitelist;

  uint256 public totalReserve;
  IERC20Upgradeable public token;
  IERC20Upgradeable public busd;
  uint256 public hardcap;
  uint256 public startTime;
  uint256 public finishTime;
  bool public cancelled;

  modifier notCancelled() {
    require(!cancelled, "sale is cancelled");
    _;
  }

  modifier isCancelled() {
    require(cancelled, "sale is not cancelled");
    _;
  }

  modifier isStarted() {
    require(startTime != 0, "sale is not started");
    _;
  }

  modifier notStarted() {
    require(startTime == 0, "sale is started");
    _;
  }

  modifier claimAllowed() {
    require(finishTime != 0, "sale is not finished");
    _;
  }

  constructor(IERC20Upgradeable _token, IERC20Upgradeable _busd, uint256 _hardcap) public {
    token = _token;
    busd = _busd;
    hardcap = _hardcap;
  }

  // Admin control 

  function addToWhitelist(address[] memory _participants) external notCancelled onlyOwner {
    // gas is cheap!
    for (uint256 i = 0; i < _participants.length; i++) {
      whitelist[_participants[i]] = true;
    }
  }

  function cancelSale() onlyOwner external {
    cancelled = true;
  }

  // allows users to claim their tokens
  function finishSale() external isStarted onlyOwner {
    finishTime = block.timestamp;
  }

  function startSale() external notStarted onlyOwner {
    startTime = block.timestamp;
  }

  function collectFunds(address to) external claimAllowed onlyOwner {
    busd.transfer(to, busd.balanceOf(address(this)));
  }

  function reserve(uint256 busdAmount) external isStarted notCancelled {
    // if it's still a whitelist timer
    if (block.timestamp - startTime < WHITELIST_DURATION) {
      require(whitelist[msg.sender], "not whitelisted");
    }

    // check hardcap
    uint256 newTotalReserves = totalReserve.add(busdAmount);
    if (newTotalReserves > hardcap) {
      uint256 reservesDelta = newTotalReserves.sub(hardcap);
      if (reservesDelta == busdAmount) {
        // we have no space left
        revert("hardcap reached");
      }
      // we still can fit a bit
      busdAmount = busdAmount.sub(reservesDelta);
      newTotalReserves = newTotalReserves.sub(reservesDelta);
    }

    uint256 currentReserve = reserves[msg.sender];
    uint256 newReserve = currentReserve.add(busdAmount);
    require(newReserve >= MIN_RESERVE_SIZE && newReserve <= MAX_RESERVE_SIZE, "too much or too little");

    reserves[msg.sender] = newReserve;

    totalReserve = newTotalReserves;

    emit Reserve(msg.sender, busdAmount, newTotalReserves);

    busd.transferFrom(msg.sender, address(this), busdAmount);
  }

  // used to get back BUSD if sale was cancelled
  function withdrawFunds() external isCancelled {
    uint256 reserve = reserves[msg.sender];
    reserves[msg.sender] = 0;

    busd.transfer(msg.sender, reserve);
  }

  function tokensToClaim(address _beneficiary) public view returns(uint256) {
    (uint256 tokensAmount, ) = _tokensToClaim(_beneficiary);
    return tokensAmount;
  }

  /**
    @dev This function returns tokensAmount available to claim. Calculates it based on several vesting periods if applicable.
  */
  function _tokensToClaim(address _beneficiary) private view returns(uint256 tokensAmount, uint256 lastClaim) {
      uint256 tokensLeft = reserves[_beneficiary].mul(TOKENS_PER_BUSD).div(RATE_PRECISION);
      if (tokensLeft == 0) {
        return (0, 0);
      }

      lastClaim = claimTime[_beneficiary];
      bool firstClaim = false;

      if (lastClaim == 0) { // first time claim, set it to a sale finish time
          firstClaim = true;
          lastClaim = finishTime;
      }

      if (lastClaim > block.timestamp) {
          // has not started yet
          return (0, 0);
      }

      uint256 tokensClaimed = claimed[_beneficiary];
      uint256 tokensPerPeriod = tokensClaimed.add(tokensLeft).mul(VESTING_AMOUNT).div(VESTING_AMOUNT_TOTAL);
      uint256 periodsPassed = block.timestamp.sub(lastClaim).div(VESTING_PERIOD);

      // align it to period passed
      lastClaim = lastClaim.add(periodsPassed.mul(VESTING_PERIOD));

      if (firstClaim)  { // first time claim, add extra period
        periodsPassed += 1;
      }

      tokensAmount = periodsPassed.mul(tokensPerPeriod);
    }

    // claims vested tokens for a given beneficiary
    function claimFor(address _beneficiary) external claimAllowed {
        _processClaim(_beneficiary);
    }

    // convenience function for beneficiaries to call to claim all of their vested tokens
    function claimForSelf() external claimAllowed {
        _processClaim(msg.sender);
    }

    function claimForMany(address[] memory _beneficiaries) external claimAllowed {
      uint256 length = _beneficiaries.length;
      for (uint256 i = 0; i < length; i++) {
        _processClaim(_beneficiaries[i]);
      }
    }

    // Calculates the claimable tokens of a beneficiary and sends them.
    function _processClaim(address _beneficiary) internal {
        (uint256 amountToClaim, uint256 lastClaim) = _tokensToClaim(_beneficiary);

        if (amountToClaim == 0) {
            return;
        }
        claimTime[_beneficiary] = lastClaim;
        claimed[_beneficiary] = claimed[_beneficiary].add(amountToClaim);
        reserves[_beneficiary] = reserves[_beneficiary].sub(amountToClaim.mul(RATE_PRECISION).div(TOKENS_PER_BUSD));

        _sendTokens(_beneficiary, amountToClaim);

        emit TokensClaimed(_beneficiary, amountToClaim);
    }

    // send tokens to beneficiary and remove obligation
    function _sendTokens(address _beneficiary, uint256 _amountToSend) internal {
        token.safeTransfer(_beneficiary, _amountToSend);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "./VenusInteractorInitializable.sol";
import "../../upgradability/BaseUpgradeableStrategy.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/pancakeswap/IPancakeRouter02.sol";

contract VenusWBNBFoldStrategy is BaseUpgradeableStrategy, VenusInteractorInitializable {

  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  event ProfitNotClaimed();
  event TooLowBalance();

  IBEP20 public xvs;

  address public pancakeswapRouterV2;
  uint256 public suppliedInUnderlying;
  uint256 public borrowedInUnderlying;
  bool public allowEmergencyLiquidityShortage;
  uint256 public collateralFactorNumerator;
  uint256 public collateralFactorDenominator;
  uint256 public folds;

  uint256 public borrowMinThreshold;

  // These tokens cannot be claimed by the controller
  mapping(address => bool) public unsalvagableTokens;

  event Liquidated(
    uint256 amount
  );

  constructor() public BaseUpgradeableStrategy() {
  }

  function initializeStrategy(
    address _storage,
    address _underlying,
    address _vtoken,
    address _vault,
    address _comptroller,
    address _xvs,
    address _pancakeswap,
    address payable _wbnb,
    uint256 _collateralFactorNumerator,
    uint256 _collateralFactorDenominator,
    uint256 _folds
  )
  public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _comptroller,
      _xvs,
      100, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e16, // sell floor
      12 hours // implementation change delay
    );

    VenusInteractorInitializable.initialize(_underlying, _vtoken, _comptroller, _wbnb);

    require(IVault(_vault).underlying() == _underlying, "vault does not support underlying");
    comptroller = ComptrollerInterface(_comptroller);
    xvs = IBEP20(_xvs);
    vtoken = CompleteVToken(_vtoken);
    pancakeswapRouterV2 = _pancakeswap;
    collateralFactorNumerator = _collateralFactorNumerator;
    collateralFactorDenominator = _collateralFactorDenominator;
    folds = _folds;

    // set these tokens to be not salvagable
    unsalvagableTokens[_underlying] = true;
    unsalvagableTokens[_vtoken] = true;
    unsalvagableTokens[_xvs] = true;
  }

  modifier updateSupplyInTheEnd() {
    _;
    suppliedInUnderlying = vtoken.balanceOfUnderlying(address(this));
    borrowedInUnderlying = vtoken.borrowBalanceCurrent(address(this));
  }

  function depositArbCheck() public view returns (bool) {
    // there's no arb here.
    return true;
  }

  /**
  * The strategy invests by supplying the underlying as a collateral.
  */
  function investAllUnderlying() public restricted updateSupplyInTheEnd {
    uint256 balance = IBEP20(underlying()).balanceOf(address(this));
    _supplyBNBInWBNB(balance);
    
    for (uint256 i = 0; i < folds; i++) {
      uint256 borrowAmount = balance.mul(collateralFactorNumerator).div(collateralFactorDenominator);
      _borrowInWBNB(borrowAmount);
      balance = IBEP20(underlying()).balanceOf(address(this));
      _supplyBNBInWBNB(balance);
    }
  }

  /**
  * Exits Venus and transfers everything to the vault.
  */
  function withdrawAllToVault() external restricted updateSupplyInTheEnd {
    if (allowEmergencyLiquidityShortage) {
      withdrawMaximum();
    } else {
      withdrawAllWeInvested();
    }
    if (IBEP20(underlying()).balanceOf(address(this)) > 0) {
      IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
    }
  }

  function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
    withdrawMaximum();
  }

  function withdrawMaximum() internal updateSupplyInTheEnd {
    if (sell()) {
      claimVenus();
      liquidateVenus();
    } else {
      emit ProfitNotClaimed();
    }
    redeemMaximum();
  }

  function withdrawAllWeInvested() internal updateSupplyInTheEnd {
    if (sell()) {
      claimVenus();
      liquidateVenus();
    } else {
      emit ProfitNotClaimed();
    }
    uint256 _currentSuppliedBalance = vtoken.balanceOfUnderlying(address(this));
    uint256 _currentBorrowedBalance = vtoken.borrowBalanceCurrent(address(this));

    mustRedeemPartial(_currentSuppliedBalance.sub(_currentBorrowedBalance));
  }

  function withdrawToVault(uint256 amountUnderlying) external restricted updateSupplyInTheEnd {
    if (amountUnderlying <= IBEP20(underlying()).balanceOf(address(this))) {
      IBEP20(underlying()).safeTransfer(vault(), amountUnderlying);
      return;
    }

    // get some of the underlying
    mustRedeemPartial(amountUnderlying);

    // transfer the amount requested (or the amount we have) back to vault
    IBEP20(underlying()).safeTransfer(vault(), amountUnderlying);

    // invest back to compound
    investAllUnderlying();
  }

  /**
  * Withdraws all assets, liquidates XVS, and invests again in the required ratio.
  */
  function doHardWork() public restricted {
    if (sell()) {
      claimVenus();
      liquidateVenus();
    } else {
      emit ProfitNotClaimed();
    }
    investAllUnderlying();
  }

  /**
  * Redeems maximum that can be redeemed from Venus.
  * Redeem the minimum of the underlying we own, and the underlying that the vToken can
  * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently.
  *
  * DOES NOT ensure that the strategy cUnderlying balance becomes 0.
  */
  function redeemMaximum() internal {
    redeemMaximumWBNBWithLoan(
      collateralFactorNumerator,
      collateralFactorDenominator,
      borrowMinThreshold
    );
  }

  /**
  * Redeems `amountUnderlying` or fails.
  */
  function mustRedeemPartial(uint256 amountUnderlying) internal {
    require(
      vtoken.getCash() >= amountUnderlying,
      "market cash cannot cover liquidity"
    );
    redeemMaximum();
    require(IBEP20(underlying()).balanceOf(address(this)) >= amountUnderlying, "Unable to withdraw the entire amountUnderlying");
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvagable");
    IBEP20(token).safeTransfer(recipient, amount);
  }

  function liquidateVenus() internal {
    uint256 balance = xvs.balanceOf(address(this));
    if (balance < sellFloor() || balance == 0) {
      emit TooLowBalance();
      return;
    }

    // give a profit share to fee forwarder, which re-distributes this to
    // the profit sharing pools
    notifyProfitInRewardToken(balance);

    balance = xvs.balanceOf(address(this));

    emit Liquidated(balance);
    // we can accept 1 as minimum as this will be called by trusted roles only
    uint256 amountOutMin = 1;
    IBEP20(address(xvs)).safeApprove(address(pancakeswapRouterV2), 0);
    IBEP20(address(xvs)).safeApprove(address(pancakeswapRouterV2), balance);
    address[] memory path = new address[](2);
    path[0] = address(xvs);
    path[1] = underlying();

    IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
      balance,
      amountOutMin,
      path,
      address(this),
      block.timestamp
    );
  }

  /**
  * Returns the current balance. Ignores XVS that was not liquidated and invested.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // underlying in this strategy + underlying redeemable from Venus + loan
    return IBEP20(underlying()).balanceOf(address(this))
    .add(suppliedInUnderlying)
    .sub(borrowedInUnderlying);
  }

  function setAllowLiquidityShortage(bool allowed) external restricted {
    allowEmergencyLiquidityShortage = allowed;
  }

  function setBorrowMinThreshold(uint256 threshold) public onlyGovernance {
    borrowMinThreshold = threshold;
  }

  // updating collateral factor
  // note 1: one should settle the loan first before calling this
  // note 2: collateralFactorDenominator is 1000, therefore, for 20%, you need 200
  function setCollateralFactorNumerator(uint256 numerator) public onlyGovernance {
    require(numerator <= 740, "Collateral factor cannot be this high");
    collateralFactorNumerator = numerator;
  }

  function setFolds(uint256 _folds) public onlyGovernance {
    folds = _folds;
  }

  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IVBNB.sol";
import "./interfaces/CompleteVToken.sol";
import "../../interfaces/WBNB.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract VenusInteractorInitializable is Initializable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    IBEP20 public underlyingToken;
    address payable public wbnb; // 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    CompleteVToken public vtoken;
    ComptrollerInterface public comptroller;

    constructor() public {}

    function initialize(
        address _underlying,
        address _vtoken,
        address _comptroller,
        address payable _wbnb
    ) public initializer {
        __ReentrancyGuard_init();

        comptroller = ComptrollerInterface(_comptroller);

        underlyingToken = IBEP20(_underlying);
        wbnb = _wbnb;
        vtoken = CompleteVToken(_vtoken);

        // Enter the market
        address[] memory vTokens = new address[](1);
        vTokens[0] = _vtoken;
        comptroller.enterMarkets(vTokens);
    }

    /**
     * Supplies BNB to Venus
     * Unwraps WBNB to BNB, then invoke the special mint for vBNB
     * We ask to supply "amount", if the "amount" we asked to supply is
     * more than balance (what we really have), then only supply balance.
     * If we the "amount" we want to supply is less than balance, then
     * only supply that amount.
     */
    function _supplyBNBInWBNB(uint256 amountInWBNB) internal nonReentrant {
        // underlying here is WBNB
        uint256 balance = underlyingToken.balanceOf(address(this)); // supply at most "balance"
        if (amountInWBNB < balance) {
            balance = amountInWBNB; // only supply the "amount" if its less than what we have
        }
        WBNB wbnb = WBNB(payable(address(wbnb)));
        wbnb.withdraw(balance); // Unwrapping
        IVBNB(address(vtoken)).mint.value(balance)();
    }

    /**
     * Redeems BNB from Venus
     * receives BNB. Wrap all the BNB that is in this contract.
     */
    function _redeemBNBInvTokens(uint256 amountVTokens) internal nonReentrant {
        _redeemInVTokens(amountVTokens);
        WBNB wbnb = WBNB(payable(address(wbnb)));
        wbnb.deposit.value(address(this).balance)();
    }

    /**
     * Supplies to Venus
     */
    function _supply(uint256 amount) internal returns (uint256) {
        uint256 balance = underlyingToken.balanceOf(address(this));
        if (amount < balance) {
            balance = amount;
        }
        underlyingToken.safeApprove(address(vtoken), 0);
        underlyingToken.safeApprove(address(vtoken), balance);
        uint256 mintResult = vtoken.mint(balance);
        require(mintResult == 0, "Supplying failed");
        return balance;
    }

    /**
     * Borrows against the collateral
     */
    function _borrow(uint256 amountUnderlying) internal {
        // Borrow, check the balance for this contract's address
        uint256 result = vtoken.borrow(amountUnderlying);
        require(result == 0, "Borrow failed");
    }

    /**
     * Borrows against the collateral
     */
    function _borrowInWBNB(uint256 amountUnderlying) internal {
        // Borrow BNB, wraps into WBNB
        uint256 result = vtoken.borrow(amountUnderlying);
        require(result == 0, "Borrow failed");
        WBNB wbnb = WBNB(payable(address(wbnb)));
        wbnb.deposit.value(address(this).balance)();
    }

    /**
     * Repays a loan
     */
    function _repay(uint256 amountUnderlying) internal {
        underlyingToken.safeApprove(address(vtoken), 0);
        underlyingToken.safeApprove(address(vtoken), amountUnderlying);
        vtoken.repayBorrow(amountUnderlying);
        underlyingToken.safeApprove(address(vtoken), 0);
    }

    /**
     * Repays a loan in BNB
     */
    function _repayInWBNB(uint256 amountUnderlying) internal {
        WBNB wbnb = WBNB(payable(address(wbnb)));
        wbnb.withdraw(amountUnderlying); // Unwrapping
        IVBNB(address(vtoken)).repayBorrow.value(amountUnderlying)();
    }

    /**
     * Redeem liquidity in vTokens
     */
    function _redeemInVTokens(uint256 amountVTokens) internal {
        if (amountVTokens > 0) {
            vtoken.redeem(amountVTokens);
        }
    }

    /**
     * Redeem liquidity in underlying
     */
    function _redeemUnderlying(uint256 amountUnderlying) internal {
        if (amountUnderlying > 0) {
            vtoken.redeemUnderlying(amountUnderlying);
        }
    }

    /**
     * Redeem liquidity in underlying
     */
    function redeemUnderlyingInWBNB(uint256 amountUnderlying) internal {
        if (amountUnderlying > 0) {
            _redeemUnderlying(amountUnderlying);
            WBNB wbnb = WBNB(payable(address(wbnb)));
            wbnb.deposit.value(address(this).balance)();
        }
    }

    /**
     * Get XVS
     */
    function claimVenus() public {
        comptroller.claimVenus(address(this));
    }

    /**
     * Redeem the minimum of the WBNB we own, and the WBNB that the vToken can
     * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently
     */
    function redeemMaximumWBNB() internal {
        // amount of WBNB in contract
        uint256 available = vtoken.getCash();
        // amount of WBNB we own
        uint256 owned = vtoken.balanceOfUnderlying(address(this));

        // redeem the most we can redeem
        redeemUnderlyingInWBNB(available < owned ? available : owned);
    }

    function redeemMaximumWithLoan(
        uint256 collateralFactorNumerator,
        uint256 collateralFactorDenominator,
        uint256 borrowMinThreshold
    ) internal {
        // amount of liquidity in Venus
        uint256 available = vtoken.getCash();
        // amount we supplied
        uint256 supplied = vtoken.balanceOfUnderlying(address(this));
        // amount we borrowed
        uint256 borrowed = vtoken.borrowBalanceCurrent(address(this));

        while (borrowed > borrowMinThreshold) {
            uint256 requiredCollateral =
                borrowed.mul(collateralFactorDenominator).add(collateralFactorNumerator.div(2)).div(
                    collateralFactorNumerator
                );

            // redeem just as much as needed to repay the loan
            uint256 wantToRedeem = supplied.sub(requiredCollateral);
            _redeemUnderlying(MathUpgradeable.min(wantToRedeem, available));

            // now we can repay our borrowed amount
            uint256 balance = underlyingToken.balanceOf(address(this));
            _repay(MathUpgradeable.min(borrowed, balance));

            // update the parameters
            available = vtoken.getCash();
            borrowed = vtoken.borrowBalanceCurrent(address(this));
            supplied = vtoken.balanceOfUnderlying(address(this));
        }

        // redeem the most we can redeem
        _redeemUnderlying(MathUpgradeable.min(available, supplied));
    }

    function redeemMaximumWBNBWithLoan(
        uint256 collateralFactorNumerator,
        uint256 collateralFactorDenominator,
        uint256 borrowMinThreshold
    ) internal {
        // amount of liquidity in Venus
        uint256 available = vtoken.getCash();
        // amount of WBNB we supplied
        uint256 supplied = vtoken.balanceOfUnderlying(address(this));
        // amount of WBNB we borrowed
        uint256 borrowed = vtoken.borrowBalanceCurrent(address(this));

        while (borrowed > borrowMinThreshold) {
            uint256 requiredCollateral =
                borrowed.mul(collateralFactorDenominator).add(collateralFactorNumerator.div(2)).div(
                    collateralFactorNumerator
                );

            // redeem just as much as needed to repay the loan
            uint256 wantToRedeem = supplied.sub(requiredCollateral);
            redeemUnderlyingInWBNB(MathUpgradeable.min(wantToRedeem, available));

            // now we can repay our borrowed amount
            uint256 balance = underlyingToken.balanceOf(address(this));
            _repayInWBNB(MathUpgradeable.min(borrowed, balance));

            // update the parameters
            available = vtoken.getCash();
            borrowed = vtoken.borrowBalanceCurrent(address(this));
            supplied = vtoken.balanceOfUnderlying(address(this));
        }

        // redeem the most we can redeem
        redeemUnderlyingInWBNB(MathUpgradeable.min(available, supplied));
    }

    function getLiquidity() external view returns (uint256) {
        return vtoken.getCash();
    }

    function redeemMaximumToken() internal {
        // amount of tokens in vtoken
        uint256 available = vtoken.getCash();
        // amount of tokens we own
        uint256 owned = vtoken.balanceOfUnderlying(address(this));

        // redeem the most we can redeem
        _redeemUnderlying(available < owned ? available : owned);
    }

    receive() external payable {} // this is needed for the WBNB unwrapping
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../ControllableInit.sol";
import "../interfaces/IController.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

contract BaseUpgradeableStrategy is Initializable, ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  uint256 constant MAX_PROFIT_SHARING_NUMERATOR = 100; // setted only once during deployment and can be modified
  event ProfitsNotCollected(bool sell, bool floor);
  event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() public BaseUpgradeableStrategyStorage() {
  }

  function initialize(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _profitSharingNumerator,
    uint256 _profitSharingDenominator,
    bool _sell,
    uint256 _sellFloor,
    uint256 _implementationChangeDelay
  ) public initializer {
    ControllableInit.initialize(
      _storage
    );
    _setUnderlying(_underlying);
    _setVault(_vault);
    _setRewardPool(_rewardPool);
    _setRewardToken(_rewardToken);
    require(_profitSharingNumerator <= MAX_PROFIT_SHARING_NUMERATOR, "profit sharing numerator should be less or equal max value");
    _setProfitSharingNumerator(_profitSharingNumerator);
    _setProfitSharingDenominator(_profitSharingDenominator);

    _setSell(_sell);
    _setSellFloor(_sellFloor);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setPausedInvesting(false);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function _finalizeUpgrade() internal {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  function shouldUpgrade() external view returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  function setProfitSharingNumerator(uint256 _profitSharingNumerator) public onlyGovernance {
    require(_profitSharingNumerator <= MAX_PROFIT_SHARING_NUMERATOR, "profit sharing numerator should be less or equal max value");
    _setProfitSharingNumerator(_profitSharingNumerator);
  }

  // reward notification

  function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
    if( _rewardBalance > 0 ){
      uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator()).div(profitSharingDenominator());
      emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
      IBEP20(rewardToken()).safeApprove(controller(), 0);
      IBEP20(rewardToken()).safeApprove(controller(), feeAmount);

      IController(controller()).notifyFee(
        rewardToken(),
        feeAmount
      );
    } else {
      emit ProfitLogInReward(0, 0, block.timestamp);
    }
  }
}

pragma solidity 0.6.12;

import {IPancakeRouter01} from "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

pragma solidity 0.6.12;

interface IVBNB {
    function mint() external payable;
    function borrow(uint borrowAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint256);
    function balanceOfUnderlying(address account) external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}

pragma solidity 0.6.12;

import "./VTokenInterfaces.sol";

abstract contract CompleteVToken is VBep20Interface, VTokenInterface {}

/**
 *Submitted for verification at BscScan.com on 2020-09-03
*/

pragma solidity 0.6.12;

contract WBNB {
    string public name     = "Wrapped BNB";
    string public symbol   = "WBNB";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

pragma solidity 0.6.12;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";

abstract contract VTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-vToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Initial exchange rate used when minting the first VTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;
}

abstract contract VTokenInterface is VTokenStorage {
    /**
     * @notice Indicator that this is a VToken contract (for inspection)
     */
    bool public constant isVToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address vTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external virtual view returns (uint);
    function balanceOf(address owner) external virtual view returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external virtual view returns (uint);
    function supplyRatePerBlock() external virtual view returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) external virtual view returns (uint);
    function exchangeRateCurrent() external virtual returns (uint);
    function exchangeRateStored() external virtual view returns (uint);
    function getCash() external virtual view returns (uint);
    function accrueInterest() external virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external virtual returns (uint);
    function _acceptAdmin() external virtual returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) external virtual returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external virtual returns (uint);
    function _reduceReserves(uint reduceAmount) external virtual returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) external virtual returns (uint);
}

abstract contract VBep20Storage {
    /**
     * @notice Underlying asset for this VToken
     */
    address public underlying;
}

abstract contract VBep20Interface is VBep20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, VTokenInterface vTokenCollateral) external virtual returns (uint);


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external virtual returns (uint);
}

abstract contract VDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract VDelegatorInterface is VDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) external virtual;
}

abstract contract VDelegateInterface is VDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) external virtual;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() external virtual;
}

pragma solidity ^0.6.12;

abstract contract ComptrollerInterface {
    // implemented, but missing from the interface
    function getAccountLiquidity(address account) external virtual view returns (uint, uint, uint);
    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint redeemTokens,
        uint borrowAmount) external virtual view returns (uint, uint, uint);
    function claimVenus(address holder) external virtual;

    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata vTokens) external virtual returns (uint[] memory);
    function exitMarket(address vToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address vToken, address minter, uint mintAmount) external virtual returns (uint);
    function mintVerify(address vToken, address minter, uint mintAmount, uint mintTokens) external virtual;

    function redeemAllowed(address vToken, address redeemer, uint redeemTokens) external virtual returns (uint);
    function redeemVerify(address vToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;

    function borrowAllowed(address vToken, address borrower, uint borrowAmount) external virtual returns (uint);
    function borrowVerify(address vToken, address borrower, uint borrowAmount) external virtual;

    function repayBorrowAllowed(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount) external virtual returns (uint);
    function repayBorrowVerify(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external virtual;

    function liquidateBorrowAllowed(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external virtual returns (uint);
    function liquidateBorrowVerify(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external virtual;

    function seizeAllowed(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual returns (uint);
    function seizeVerify(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual;

    function transferAllowed(address vToken, address src, address dst, uint transferTokens) external virtual returns (uint);
    function transferVerify(address vToken, address src, address dst, uint transferTokens) external virtual;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint repayAmount) external virtual view returns (uint, uint);

    function mintedVAIOf(address owner) external virtual view returns (uint);
    function setMintedVAIOf(address owner, uint amount) external virtual returns (uint);
    function getVAIMintRate() external virtual view returns (uint);
}

pragma solidity 0.6.12;

/**
  * @title Venus's InterestRateModel Interface
  * @author Venus
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amnount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external virtual view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amnount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external virtual view returns (uint);

}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract BaseUpgradeableStrategyStorage {

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _REWARD_TOKEN_SLOT = 0xdae0aafd977983cb1e78d8f638900ff361dc3c48c43118ca1dd77d1af3f47bbf;
  bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
  bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

  constructor() public {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
    assert(_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardToken")) - 1));
    assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

    assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
    assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public virtual view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setRewardPool(address _address) internal {
    setAddress(_REWARD_POOL_SLOT, _address);
  }

  function rewardPool() public view returns (address) {
    return getAddress(_REWARD_POOL_SLOT);
  }

  function _setRewardToken(address _address) internal {
    setAddress(_REWARD_TOKEN_SLOT, _address);
  }

  function rewardToken() public view returns (address) {
    return getAddress(_REWARD_TOKEN_SLOT);
  }

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public virtual view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function _setProfitSharingNumerator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_NUMERATOR_SLOT, _value);
  }

  function profitSharingNumerator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_NUMERATOR_SLOT);
  }

  function _setProfitSharingDenominator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_DENOMINATOR_SLOT, _value);
  }

  function profitSharingDenominator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_DENOMINATOR_SLOT);
  }

  // upgradeability

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}

pragma solidity 0.6.12;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "./VenusInteractorInitializable.sol";
import "../../upgradability/BaseUpgradeableStrategy.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/pancakeswap/IPancakeRouter02.sol";

contract VenusFoldStrategy is BaseUpgradeableStrategy, VenusInteractorInitializable {

  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  event ProfitNotClaimed();
  event TooLowBalance();

  IBEP20 public xvs;

  address public pancakeswapRouterV2;
  uint256 public suppliedInUnderlying;
  uint256 public borrowedInUnderlying;
  bool public allowEmergencyLiquidityShortage;
  uint256 public collateralFactorNumerator;
  uint256 public collateralFactorDenominator;
  uint256 public folds;
  address [] public liquidationPath;

  uint256 public borrowMinThreshold;

  // These tokens cannot be claimed by the controller
  mapping(address => bool) public unsalvagableTokens;

  event Liquidated(
    uint256 amount
  );

  constructor() public BaseUpgradeableStrategy() {
  }

  function initializeStrategy(
    address _storage,
    address _underlying,
    address _vtoken,
    address _vault,
    address _comptroller,
    address _xvs,
    address _pancakeswap,
    address payable _wbnb,
    uint256 _collateralFactorNumerator,
    uint256 _collateralFactorDenominator,
    uint256 _folds,
    address[] calldata _liquidationPath
  )
  public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _comptroller,
      _xvs,
      100, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e16, // sell floor
      12 hours // implementation change delay
    );

    VenusInteractorInitializable.initialize(_underlying, _vtoken, _comptroller, _wbnb);

    require(IVault(_vault).underlying() == _underlying, "vault does not support underlying");
    comptroller = ComptrollerInterface(_comptroller);
    xvs = IBEP20(_xvs);
    vtoken = CompleteVToken(_vtoken);
    pancakeswapRouterV2 = _pancakeswap;
    collateralFactorNumerator = _collateralFactorNumerator;
    collateralFactorDenominator = _collateralFactorDenominator;
    folds = _folds;
    liquidationPath = _liquidationPath;

    // set these tokens to be not salvagable
    unsalvagableTokens[_underlying] = true;
    unsalvagableTokens[_vtoken] = true;
    unsalvagableTokens[_xvs] = true;
  }

  modifier updateSupplyInTheEnd() {
    _;
    suppliedInUnderlying = vtoken.balanceOfUnderlying(address(this));
    borrowedInUnderlying = vtoken.borrowBalanceCurrent(address(this));
  }

  function depositArbCheck() public view returns (bool) {
    // there's no arb here.
    return true;
  }

  /**
  * The strategy invests by supplying the underlying as a collateral.
  */
  function investAllUnderlying() public restricted updateSupplyInTheEnd {
    uint256 balance = IBEP20(underlying()).balanceOf(address(this));
    _supply(balance);
    for (uint256 i = 0; i < folds; i++) {
      uint256 borrowAmount = balance.mul(collateralFactorNumerator).div(collateralFactorDenominator);
      _borrow(borrowAmount);
      balance = IBEP20(underlying()).balanceOf(address(this));
      _supply(balance);
    }
  }

  /**
  * Exits Venus and transfers everything to the vault.
  */
  function withdrawAllToVault() external restricted updateSupplyInTheEnd {
    if (allowEmergencyLiquidityShortage) {
      withdrawMaximum();
    } else {
      withdrawAllWeInvested();
    }
    if (IBEP20(underlying()).balanceOf(address(this)) > 0) {
      IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
    }
  }

  function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
    withdrawMaximum();
  }

  function withdrawMaximum() internal updateSupplyInTheEnd {
    if (sell()) {
      liquidateVenus();
    } else {
      emit ProfitNotClaimed();
    }
    redeemMaximum();
  }

  function withdrawAllWeInvested() internal updateSupplyInTheEnd {
    if (sell()) {
      liquidateVenus();
    } else {
      emit ProfitNotClaimed();
    }
    uint256 _currentSuppliedBalance = vtoken.balanceOfUnderlying(address(this));
    uint256 _currentBorrowedBalance = vtoken.borrowBalanceCurrent(address(this));

    mustRedeemPartial(_currentSuppliedBalance.sub(_currentBorrowedBalance));
  }

  function withdrawToVault(uint256 amountUnderlying) external restricted updateSupplyInTheEnd {
    if (amountUnderlying <= IBEP20(underlying()).balanceOf(address(this))) {
      IBEP20(underlying()).safeTransfer(vault(), amountUnderlying);
      return;
    }

    // get some of the underlying
    mustRedeemPartial(amountUnderlying);

    // transfer the amount requested (or the amount we have) back to vault()
    IBEP20(underlying()).safeTransfer(vault(), amountUnderlying);

    // invest back to Venus
    investAllUnderlying();
  }

  /**
  * Withdraws all assets, liquidates XVS, and invests again in the required ratio.
  */
  function doHardWork() public restricted {
    if (sell()) {
      liquidateVenus();
    } else {
      emit ProfitNotClaimed();
    }
    investAllUnderlying();
  }

  /**
  * Redeems maximum that can be redeemed from Venus.
  * Redeem the minimum of the underlying we own, and the underlying that the vToken can
  * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently.
  *
  * DOES NOT ensure that the strategy vUnderlying balance becomes 0.
  */
  function redeemMaximum() internal {
    redeemMaximumWithLoan(
      collateralFactorNumerator,
      collateralFactorDenominator,
      borrowMinThreshold
    );
  }

  /**
  * Redeems `amountUnderlying` or fails.
  */
  function mustRedeemPartial(uint256 amountUnderlying) internal {
    require(
      vtoken.getCash() >= amountUnderlying,
      "market cash cannot cover liquidity"
    );
    redeemMaximum();
    require(IBEP20(underlying()).balanceOf(address(this)) >= amountUnderlying, "Unable to withdraw the entire amountUnderlying");
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvagable");
    IBEP20(token).safeTransfer(recipient, amount);
  }

  function liquidateVenus() internal {
    // Calculating rewardBalance is needed for the case underlying = reward token
    uint256 balance = xvs.balanceOf(address(this));
    claimVenus();
    uint256 balanceAfter = xvs.balanceOf(address(this));
    uint256 rewardBalance = balanceAfter.sub(balance);

    if (rewardBalance < sellFloor() || rewardBalance == 0) {
      emit TooLowBalance();
      return;
    }

    // give a profit share to fee forwarder, which re-distributes this to
    // the profit sharing pools
    notifyProfitInRewardToken(rewardBalance);

    balance = xvs.balanceOf(address(this));

    emit Liquidated(balance);

    // no liquidation needed when underlying is reward token
    if (underlying() == address(xvs)) {
      return;
    }

    // we can accept 1 as minimum as this will be called by trusted roles only
    uint256 amountOutMin = 1;
    IBEP20(address(xvs)).safeApprove(address(pancakeswapRouterV2), 0);
    IBEP20(address(xvs)).safeApprove(address(pancakeswapRouterV2), balance);

    IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
      balance,
      amountOutMin,
      liquidationPath,
      address(this),
      block.timestamp
    );
  }

  /**
  * Returns the current balance. Ignores XVS that was not liquidated and invested.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // underlying in this strategy + underlying redeemable from Venus + loan
    return IBEP20(underlying()).balanceOf(address(this))
    .add(suppliedInUnderlying)
    .sub(borrowedInUnderlying);
  }

  function setAllowLiquidityShortage(bool allowed) external restricted {
    allowEmergencyLiquidityShortage = allowed;
  }

  function setBorrowMinThreshold(uint256 threshold) public onlyGovernance {
    borrowMinThreshold = threshold;
  }

  // updating collateral factor
  // note 1: one should settle the loan first before calling this
  // note 2: collateralFactorDenominator is 1000, therefore, for 20%, you need 200
  function setCollateralFactorNumerator(uint256 numerator) public onlyGovernance {
    require(numerator <= 740, "Collateral factor cannot be this high");
    collateralFactorNumerator = numerator;
  }

  function setFolds(uint256 _folds) public onlyGovernance {
    folds = _folds;
  }

  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }
}

pragma solidity >=0.6.0;

import "../../interfaces/IStrategy.sol";

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "../../upgradability/BaseUpgradeableStrategy.sol";
import "../../NoMintRewardPool.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/pancakeswap/IPancakeRouter02.sol";
import "../../interfaces/pancakeswap/IPancakePair.sol";

contract VaultyLPStrategy is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public constant pancakeswapRouterV2 =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // boolean to determine if underlying is single asset or LP token
    bool public isLpToken;

    // this would be reset on each upgrade
    mapping(address => address[]) public pancakeswapRoutes;

    constructor() public BaseUpgradeableStrategy() {}

    function initializeStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address _rewardToken,
        bool _isLpToken
    ) public initializer {
        require(_storage != address(0), "address cannot be zero");
        require(_rewardPool != address(0), "address cannot be zero");
        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            _rewardPool,
            _rewardToken,
            100, // profit sharing numerator
            1000, // profit sharing denominator
            true, // sell
            1e18, // sell floor
            12 hours // implementation change delay
        );

        address _lpt = address(NoMintRewardPool(rewardPool()).lpToken());
        require(_lpt == underlying(), "Pool Info does not match underlying");
        _setIsLpToken(_isLpToken);

        if (isLpToken) {
            address uniLPComponentToken0 = IPancakePair(underlying()).token0();
            address uniLPComponentToken1 = IPancakePair(underlying()).token1();

            // these would be required to be initialized separately by governance
            pancakeswapRoutes[uniLPComponentToken0] = new address[](0);
            pancakeswapRoutes[uniLPComponentToken1] = new address[](0);
        } else {
            pancakeswapRoutes[underlying()] = new address[](0);
        }
    }

    function depositArbCheck() public view returns (bool) {
        return true;
    }

    function rewardPoolBalance() internal view returns (uint256 bal) {
        uint256 balance = NoMintRewardPool(rewardPool()).balanceOf(address(this));
        return balance;
    }

    function exitRewardPool(uint256 bal) internal {
        NoMintRewardPool(rewardPool()).withdraw(bal);
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function enterRewardPool() internal {
        uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));
        IBEP20(underlying()).safeApprove(rewardPool(), 0);
        IBEP20(underlying()).safeApprove(rewardPool(), entireBalance);

        NoMintRewardPool(rewardPool()).stake(entireBalance);
    }

    /*
     *   In case there are some issues discovered about the pool or underlying asset
     *   Governance can exit the pool properly
     *   The function is only used for emergency to exit the pool
     */
    function emergencyExit() public onlyGovernance {
        uint256 bal = rewardPoolBalance();
        exitRewardPool(bal);
        _setPausedInvesting(true);
    }

    /*
     *   Resumes the ability to invest into the underlying reward pools
     */

    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    function setLiquidationPathsOnPancake(
        address[] memory _pancakeswapRouteToToken0,
        address[] memory _pancakeswapRouteToToken1
    ) public onlyGovernance {
        if (isLpToken) {
            address pancakeLPComponentToken0 = IPancakePair(underlying()).token0();
            address pancakeLPComponentToken1 = IPancakePair(underlying()).token1();
            pancakeswapRoutes[pancakeLPComponentToken0] = _pancakeswapRouteToToken0;
            pancakeswapRoutes[pancakeLPComponentToken1] = _pancakeswapRouteToToken1;
        } else {
            pancakeswapRoutes[underlying()] = _pancakeswapRouteToToken0;
        }
    }

    function _claimReward() internal {
        NoMintRewardPool(rewardPool()).getReward();
    }

    // We assume that all the tradings can be done on pancakeswap
    function _liquidateReward() internal {
        uint256 rewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
        if (!sell() || rewardBalance < sellFloor()) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
            return;
        }

        notifyProfitInRewardToken(rewardBalance);
        uint256 remainingRewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
        if (remainingRewardBalance > 0) {
            if (isLpToken) {
                _liquidateLpAssets(remainingRewardBalance);
            } else {
                _liquidateSingleAsset(remainingRewardBalance);
            }
        }
    }

    // Liquidate Cake into the single underlying asset (non-LP tokens), no-op if Cake is the underlying
    function _liquidateSingleAsset(uint256 remainingRewardBalance) internal {
        address[] memory routesToken0 = pancakeswapRoutes[underlying()];

        uint256 amountOutMin = 1;

        // allow PancakeSwap to sell our reward
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

        // sell Uni to token2
        // we can accept 1 as minimum because this is called only by a trusted role
        IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
            remainingRewardBalance,
            amountOutMin,
            routesToken0,
            address(this),
            block.timestamp
        );
    }

    // Liquidate Cake into underlying LP tokens, only do one swap if Cake/WBNB LP is the underlying
    function _liquidateLpAssets(uint256 remainingRewardBalance) internal {
        address uniLPComponentToken0 = IPancakePair(underlying()).token0();
        address uniLPComponentToken1 = IPancakePair(underlying()).token1();

        address[] memory routesToken0 = pancakeswapRoutes[address(uniLPComponentToken0)];
        address[] memory routesToken1 = pancakeswapRoutes[address(uniLPComponentToken1)];

        uint256 amountOutMin = 1;

        // allow PancakeSwap to sell our reward
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

        uint256 token0Amount;
        uint256 token1Amount;

        if (
            uniLPComponentToken0 == rewardToken() && // we are dealing with CAKE/WBNB LP
            routesToken1.length > 1 // we have a route to do the swap
        ) {
            token0Amount = remainingRewardBalance / 2; // 1/2 of CAKE is saved for LP
            uint256 toToken1 = remainingRewardBalance.sub(token0Amount); // other 1/2 is liquidated

            // sell Cake to token1
            // we can accept 1 as minimum because this is called only by a trusted role
            IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
                toToken1,
                amountOutMin,
                routesToken1,
                address(this),
                block.timestamp
            );
            token1Amount = IBEP20(uniLPComponentToken1).balanceOf(address(this));

            // Only approve WBNB, CAKE has already been approved at this point
            IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, 0);
            IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, token1Amount);

            // we provide liquidity to PancakeSwap
            uint256 liquidity;
            (, , liquidity) = IPancakeRouter02(pancakeswapRouterV2).addLiquidity(
                uniLPComponentToken0,
                uniLPComponentToken1,
                token0Amount,
                token1Amount,
                1, // we are willing to take whatever the pair gives us
                1, // we are willing to take whatever the pair gives us
                address(this),
                block.timestamp
            );
        } else if (
            routesToken0.length > 1 && // and we have a route to do the swap
            routesToken1.length > 1 // and we have a route to do the swap
        ) {
            uint256 toToken0 = remainingRewardBalance / 2;
            uint256 toToken1 = remainingRewardBalance.sub(toToken0);

            // sell Cake to token0
            // we can accept 1 as minimum because this is called only by a trusted role
            IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
                toToken0,
                amountOutMin,
                routesToken0,
                address(this),
                block.timestamp
            );
            token0Amount = IBEP20(uniLPComponentToken0).balanceOf(address(this));

            // sell Cake to token1
            // we can accept 1 as minimum because this is called only by a trusted role
            IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
                toToken1,
                amountOutMin,
                routesToken1,
                address(this),
                block.timestamp
            );
            token1Amount = IBEP20(uniLPComponentToken1).balanceOf(address(this));

            // provide liquidity to PancakeSwap
            IBEP20(uniLPComponentToken0).safeApprove(pancakeswapRouterV2, 0);
            IBEP20(uniLPComponentToken0).safeApprove(pancakeswapRouterV2, token0Amount);

            IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, 0);
            IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, token1Amount);

            uint256 liquidity;
            (, , liquidity) = IPancakeRouter02(pancakeswapRouterV2).addLiquidity(
                uniLPComponentToken0,
                uniLPComponentToken1,
                token0Amount,
                token1Amount,
                1, // we are willing to take whatever the pair gives us
                1, // we are willing to take whatever the pair gives us
                address(this),
                block.timestamp
            );
        }
    }

    /*
     *   Stakes everything the strategy holds into the reward pool
     */
    function investAllUnderlying() internal onlyNotPausedInvesting {
        // this check is needed, because most of the SNX reward pools will revert if
        // you try to stake(0).
        if (IBEP20(underlying()).balanceOf(address(this)) > 0) {
            enterRewardPool();
        }
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawAllToVault() public restricted {
        if (address(rewardPool()) != address(0)) {
            uint256 bal = rewardPoolBalance();
            if (bal != 0) {
                exitRewardPool(bal);
            }
        }
        _liquidateReward();
        IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawToVault(uint256 amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));

        if (amount > entireBalance) {
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = amount.sub(entireBalance);
            uint256 toWithdraw = MathUpgradeable.min(rewardPoolBalance(), needToWithdraw);
            NoMintRewardPool(rewardPool()).withdraw(toWithdraw);
        }

        IBEP20(underlying()).safeTransfer(vault(), amount);
    }

    /*
     *   Note that we currently do not have a mechanism here to include the
     *   amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool() == address(0)) {
            return IBEP20(underlying()).balanceOf(address(this));
        }
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        uint256 entireBalance = NoMintRewardPool(rewardPool()).balanceOf(address(this));
        return entireBalance.add(IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Governance or Controller can claim coins that are somehow transferred into the contract
     *   Note that they cannot come in take away coins that are used and defined in the strategy itself
     */
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IBEP20(token).safeTransfer(recipient, amount);
    }

    /*
     *   Get the reward, sell it in exchange for underlying, invest what you got.
     *   It's not much, but it's honest work.
     *
     *   Note that although `onlyNotPausedInvesting` is not added here,
     *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
     *   when the investing is being paused by governance.
     */
    function doHardWork() external onlyNotPausedInvesting restricted {
        uint256 bal = NoMintRewardPool(rewardPool()).earned(address(this));
        if (bal != 0) {
            _claimReward();
            _liquidateReward();
        }
        investAllUnderlying();
    }

    /**
     * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
     * simplest possible way.
     */
    function setSell(bool s) public onlyGovernance {
        _setSell(s);
    }

    /**
     * Sets the minimum amount of CRV needed to trigger a sale.
     */
    function setSellFloor(uint256 floor) public onlyGovernance {
        _setSellFloor(floor);
    }

    function _setIsLpToken(bool _isLpToken) internal {
        isLpToken = _isLpToken;
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
        // reset the liquidation paths
        // they need to be re-set manually
        address uniLPComponentToken0 = IPancakePair(underlying()).token0();
        address uniLPComponentToken1 = IPancakePair(underlying()).token1();

        // these would be required to be initialized separately by governance
        pancakeswapRoutes[uniLPComponentToken0] = new address[](0);
        pancakeswapRoutes[uniLPComponentToken1] = new address[](0);
    }
}

// https://etherscan.io/address/0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92#code

/**
 *Submitted for verification at Etherscan.io on 2020-04-22
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: CurveRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity 0.6.12;

import "./LPTokenWrapper.sol";
import "./RewardDistributionRecipient.sol";
import "./Controllable.sol";
import "./interfaces/IController.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

/*
 *   [Harvest]
 *   This pool doesn't mint.
 *   the rewards should be first transferred to this pool, then get "notified"
 *   by calling `notifyRewardAmount`
 */

contract NoMintRewardPool is LPTokenWrapper, RewardDistributionRecipient, Controllable {
    using AddressUpgradeable for address;

    IBEP20 public rewardToken;
    uint256 public duration; // making it not a constant is less gas efficient, but portable

    uint256 private constant REWARD_PRECISION = 1e18;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => bool) smartContractStakers;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardDenied(address indexed user, uint256 reward);
    event SmartContractRecorded(
        address indexed smartContractAddress,
        address indexed smartContractInitiator
    );

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // [Hardwork] setting the reward, lpToken, duration, and rewardDistribution for each pool
    constructor(
        address _rewardToken,
        address _lpToken,
        uint256 _duration,
        address _rewardDistribution,
        address _storage,
        uint256 _withdrawalDelay,
        uint256 _withdrawalFee
    )
        public
        RewardDistributionRecipient(_rewardDistribution)
        Controllable(_storage) // only used for referencing the grey list
    {
        rewardToken = IBEP20(_rewardToken);
        lpToken = IBEP20(_lpToken);
        duration = _duration;
        setWithdrawalDelay(_withdrawalDelay);
        setWithdrawalFee(_withdrawalFee);

    }

    function setWithdrawalDelay(uint256 delay) public override onlyGovernance {
        super.setWithdrawalDelay(delay);
    }

    function setWithdrawalFee(uint256 fee) public override onlyGovernance {
        super.setWithdrawalFee(fee);
    }

    function setFeeCollector(address collector) public override onlyGovernance {
        super.setFeeCollector(collector);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp > periodFinish ? periodFinish : block.timestamp;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(REWARD_PRECISION)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken()
                .sub(userRewardPerTokenPaid[account]))
                .div(REWARD_PRECISION)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) {
        recordSmartContract();

        stakeTokens(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        uint256 amountAfterFee;
        (amountAfterFee,) = withdrawTokens(amount);
        emit Withdrawn(msg.sender, amountAfterFee);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    /// A push mechanism for accounts that have not claimed their rewards for a long time.
    /// The implementation is semantically analogous to getReward(), but uses a push pattern
    /// instead of pull pattern.
    function pushReward(address recipient) public updateReward(recipient) onlyGovernance {
        uint256 reward = earned(recipient);
        if (reward > 0) {
            rewards[recipient] = 0;
            // If it is a normal user and not smart contract,
            // then the requirement will pass
            // If it is a smart contract, then
            // make sure that it is not on our greyList.
            if (!recipient.isContract() || !IController(controller()).greyList(recipient)) {
                rewardToken.safeTransfer(recipient, reward);
                emit RewardPaid(recipient, reward);
            } else {
                emit RewardDenied(recipient, reward);
            }
        }
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            // If it is a normal user and not smart contract,
            // then the requirement will pass
            // If it is a smart contract, then
            // make sure that it is not on our greyList.
            if (tx.origin == msg.sender || !IController(controller()).greyList(msg.sender)) {
                rewardToken.safeTransfer(msg.sender, reward);
                emit RewardPaid(msg.sender, reward);
            } else {
                emit RewardDenied(msg.sender, reward);
            }
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(
            reward < uint256(-1) / REWARD_PRECISION,
            "the notified reward cannot invoke multiplication overflow"
        );

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    // Harvest Smart Contract recording
    function recordSmartContract() internal {
        if (tx.origin != msg.sender) {
            smartContractStakers[msg.sender] = true;
            emit SmartContractRecorded(msg.sender, tx.origin);
        }
    }
}

pragma solidity 0.6.12;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 public constant FEE_PRECISION = 10**4;

    IBEP20 public lpToken;
    mapping(address => uint256) public stakeTimestamp;
    uint256 public withdrawDelay;
    uint256 public withdrawFee;
    address public feeCollector = address(0);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event WithdrawalFeeChanged(uint256 amount);
    event WithdrawalDelayChanged(uint256 delay);
    event FeeTaken(address indexed user, uint256 amount);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setWithdrawalDelay(uint256 delay) public virtual{
        withdrawDelay = delay;
        emit WithdrawalDelayChanged(delay);
    }

    function setWithdrawalFee(uint256 fee) public virtual{
        require(fee <= FEE_PRECISION);
        withdrawFee = fee;
        emit WithdrawalFeeChanged(fee);
    }

    function setFeeCollector(address _who) public virtual {
        require(address(0) != _who);
        feeCollector = _who;
    }

    function stakeTokens(uint256 amount) internal {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lpToken.safeTransferFrom(msg.sender, address(this), amount);

        stakeTimestamp[msg.sender] = block.timestamp;
    }

    function withdrawTokens(uint256 amount) internal returns (uint256, uint256) {
        require(amount > 0, "Cannot withdraw 0");
        uint256 remainingAmount = amount;
        uint256 fee;
        if (block.timestamp.sub(stakeTimestamp[msg.sender]) < withdrawDelay) {
            // if withdrawal is too early
            if (withdrawFee > 0) {
                // charge fee if set
                fee = amount.mul(withdrawFee).div(FEE_PRECISION);
                remainingAmount = amount.sub(fee);
                if (fee > 0) {
                    emit FeeTaken(msg.sender, fee);
                    lpToken.safeTransfer(feeCollector, fee);
                }
            } else {
                revert("too early");
            }
        }

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lpToken.safeTransfer(msg.sender, remainingAmount);
        return (remainingAmount, fee);
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

abstract contract RewardDistributionRecipient is Ownable {
    address public rewardDistribution;
    
    event RewardDistributuionChanged(address _address);

    constructor(address _rewardDistribution) public {
        require(_rewardDistribution != address(0), 'pool address cannot be zero');
        rewardDistribution = _rewardDistribution;
    }

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution) external onlyOwner {
        require(_rewardDistribution != address(0), 'pool address cannot be zero');
        rewardDistribution = _rewardDistribution;
        emit RewardDistributuionChanged(_rewardDistribution);
    }
}

pragma solidity 0.6.12;

import "./interface/ISmartChef.sol";
import "../../interfaces/IStrategy.sol";

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "../../upgradability/BaseUpgradeableStrategy.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/pancakeswap/IPancakeRouter02.sol";
import "../../interfaces/pancakeswap/IPancakePair.sol";

contract SyrupPoolOptimizeStrategy is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public constant pancakeswapRouterV2 =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address public constant wbnb =
        address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    
    address public constant cake =
        address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);

    // this would be reset on each upgrade
    mapping(address => address[]) public pancakeswapRoutes;

    constructor() public BaseUpgradeableStrategy() {}

    function initializeStrategy(
        address _storage,
        address _vault,
        address _rewardPool, // initial rewardPool (assumed autoCake)
        address _rewardToken // initial rewardToken (assumed CAKE)
    ) public initializer {
        require(_storage != address(0), "address cannot be zero");
        require(_rewardPool != address(0), "address cannot be zero");
        BaseUpgradeableStrategy.initialize(
            _storage,
            cake, // CAKE is always underlying
            _vault,
            _rewardPool,
            _rewardToken, // rewardToken is dynamic
            100, // profit sharing numerator
            1000, // profit sharing denominator
            true, // sell
            1e18, // sell floor
            12 hours // implementation change delay
        );

        pancakeswapRoutes[_rewardToken] = [_rewardToken, wbnb, cake];
    }

    function depositArbCheck() public view returns (bool) {
        return true;
    }

    function rewardPoolBalance() internal view returns (uint256 bal) {
        (bal, ) = ISmartChef(rewardPool()).userInfo(address(this));
    }

    function exitRewardPool(uint256 bal) internal {
        ISmartChef(rewardPool()).withdraw(bal);
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function enterRewardPool() internal {
        uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));
        IBEP20(underlying()).safeApprove(rewardPool(), 0);
        IBEP20(underlying()).safeApprove(rewardPool(), entireBalance);

        ISmartChef(rewardPool()).deposit(entireBalance);
    }

    /*
     *   In case there are some issues discovered about the pool or underlying asset
     *   Governance can exit the pool properly
     *   The function is only used for emergency to exit the pool
     */
    function emergencyExit() public onlyGovernance {
        uint256 bal = rewardPoolBalance();
        exitRewardPool(bal);
        _setPausedInvesting(true);
    }

    /*
     *   Resumes the ability to invest into the underlying reward pools
     */

    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    function setLiquidationPathsOnPancake(
        address _rewardToken,
        address[] memory _route
    ) public onlyGovernance {
        pancakeswapRoutes[_rewardToken] = _route;
    }

    function _claimReward() internal {
        ISmartChef(rewardPool()).withdraw(0);
    }

    // We assume that all the tradings can be done on pancakeswap
    function _liquidateReward() internal {
        uint256 rewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
        if (!sell() || rewardBalance < sellFloor()) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
            return;
        }

        notifyProfitInRewardToken(rewardBalance);
        uint256 remainingRewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
        if (remainingRewardBalance > 0) {
            _liquidateSingleAsset(remainingRewardBalance);
        }
    }

    // Liquidate Cake into the single underlying asset (non-LP tokens), no-op if Cake is the underlying
    function _liquidateSingleAsset(uint256 remainingRewardBalance) internal {
        address[] memory routesToken0 = pancakeswapRoutes[rewardToken()];

        uint256 amountOutMin = 1;

        // allow PancakeSwap to sell our reward
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

        // sell Uni to token2
        // we can accept 1 as minimum because this is called only by a trusted role
        IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
            remainingRewardBalance,
            amountOutMin,
            routesToken0,
            address(this),
            block.timestamp
        );
    }

    /*
     *   Stakes everything the strategy holds into the reward pool
     */
    function investAllUnderlying() internal onlyNotPausedInvesting {
        // this check is needed, because most of the SNX reward pools will revert if
        // you try to stake(0).
        if (IBEP20(underlying()).balanceOf(address(this)) > 0) {
            enterRewardPool();
        }
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawAllToVault() public restricted {
        if (address(rewardPool()) != address(0)) {
            uint256 bal = rewardPoolBalance();
            exitRewardPool(bal);
        }
        _liquidateReward();
        IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawToVault(uint256 amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));

        if (amount > entireBalance) {
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = amount.sub(entireBalance);
            uint256 toWithdraw = MathUpgradeable.min(rewardPoolBalance(), needToWithdraw);
            ISmartChef(rewardPool()).withdraw(toWithdraw);
        }

        IBEP20(underlying()).safeTransfer(vault(), amount);
    }

    /*
     *   Note that we currently do not have a mechanism here to include the
     *   amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool() == address(0)) {
            return IBEP20(underlying()).balanceOf(address(this));
        }
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return rewardPoolBalance().add(IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Governance or Controller can claim coins that are somehow transferred into the contract
     *   Note that they cannot come in take away coins that are used and defined in the strategy itself
     */
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IBEP20(token).safeTransfer(recipient, amount);
    }

    /*
     *   Get the reward, sell it in exchange for underlying, invest what you got.
     *   It's not much, but it's honest work.
     *
     *   Note that although `onlyNotPausedInvesting` is not added here,
     *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
     *   when the investing is being paused by governance.
     */
    function doHardWork() external onlyNotPausedInvesting restricted {
        uint256 bal = rewardPoolBalance();
        if (bal != 0) {
            _claimReward();
            _liquidateReward();
        }

        investAllUnderlying();
    }

    /**
     * Changes syrup pool and reward tokens, also re-stakes all the funds
     */
    function changePool(address _rewardPool, address _rewardToken) public onlyGovernance {
        require(_rewardPool != address(0), "address cannot be zero");
        require(_rewardToken != address(0), "address cannot be zero");
        require(poolIsValid(_rewardPool, _rewardToken) == true, "pool is not valid");

        uint256 bal = rewardPoolBalance();
        exitRewardPool(bal);
        _liquidateReward();

        setRewardToken(_rewardToken);
        setRewardPool(_rewardPool);
        pancakeswapRoutes[_rewardToken] = [_rewardToken, wbnb, underlying()];
        investAllUnderlying();
    }

    function poolIsValid(address _rewardPool, address _rewardToken) internal view returns (bool) {
        return ISmartChef(_rewardPool).rewardToken() == _rewardToken;
    }

    /**
     * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
     * simplest possible way.
     */
    function setSell(bool s) public onlyGovernance {
        _setSell(s);
    }

    /**
     * Sets the minimum amount of CRV needed to trigger a sale.
     */
    function setSellFloor(uint256 floor) public onlyGovernance {
        _setSellFloor(floor);
    }

    /**
     * Sets rewardToken to the new one
     */
    function setRewardToken(address _rewardToken) internal {
        _setRewardToken(_rewardToken);
    }

    /**
     * Sets rewardPool to the new one
     */
    function setRewardPool(address _rewardPool) internal {
        _setRewardPool(_rewardPool);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
        // these would be required to be initialized separately by governance
        pancakeswapRoutes[rewardToken()] = new address[](0);
    }
}

pragma solidity 0.6.12;

interface ISmartChef {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function pendingReward(address _user) external view returns (uint256);
    function userInfo(address _user) external view returns (uint256, uint256);
    function emergencyWithdraw() external;
    function rewardToken() external view returns (address);
}

pragma solidity 0.6.12;

import "./interface/IMasterChef.sol";
import "../../interfaces/IStrategy.sol";

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "../../upgradability/BaseUpgradeableStrategy.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/pancakeswap/IPancakeRouter02.sol";
import "../../interfaces/pancakeswap/IPancakePair.sol";

contract PancakeMasterChefLPStrategy is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public constant pancakeswapRouterV2 =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
    bytes32 internal constant _POOLID_SLOT =
        0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;

    // boolean to determine if underlying is single asset or LP token
    bool public isLpToken;

    // this would be reset on each upgrade
    mapping(address => address[]) public pancakeswapRoutes;

    constructor() public BaseUpgradeableStrategy() {
        assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    }

    function initializeStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address _rewardToken,
        uint256 _poolID,
        bool _isLpToken
    ) public initializer {
        require(_storage != address(0), "address cannot be zero");
        require(_rewardPool != address(0), "address cannot be zero");
        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            _rewardPool,
            _rewardToken,
            100, // profit sharing numerator
            1000, // profit sharing denominator
            true, // sell
            1e18, // sell floor
            12 hours // implementation change delay
        );

        address _lpt;
        (_lpt, , , ) = IMasterChef(rewardPool()).poolInfo(_poolID);
        require(_lpt == underlying(), "Pool Info does not match underlying");
        _setPoolId(_poolID);
        _setIsLpToken(_isLpToken);

        if (isLpToken) {
            address uniLPComponentToken0 = IPancakePair(underlying()).token0();
            address uniLPComponentToken1 = IPancakePair(underlying()).token1();

            // these would be required to be initialized separately by governance
            pancakeswapRoutes[uniLPComponentToken0] = new address[](0);
            pancakeswapRoutes[uniLPComponentToken1] = new address[](0);
        } else {
            pancakeswapRoutes[underlying()] = new address[](0);
        }
    }

    function depositArbCheck() public view returns (bool) {
        return true;
    }

    function rewardPoolBalance() internal view returns (uint256 bal) {
        (bal, ) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
    }

    function exitRewardPool(uint256 bal) internal {
        if (poolId() == 0) {
            IMasterChef(rewardPool()).leaveStaking(bal);
        } else {
            IMasterChef(rewardPool()).withdraw(poolId(), bal);
        }
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function enterRewardPool() internal {
        uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));
        IBEP20(underlying()).safeApprove(rewardPool(), 0);
        IBEP20(underlying()).safeApprove(rewardPool(), entireBalance);

        if (poolId() == 0) {
            IMasterChef(rewardPool()).enterStaking(entireBalance);
        } else {
            IMasterChef(rewardPool()).deposit(poolId(), entireBalance);
        }
    }

    /*
     *   In case there are some issues discovered about the pool or underlying asset
     *   Governance can exit the pool properly
     *   The function is only used for emergency to exit the pool
     */
    function emergencyExit() public onlyGovernance {
        uint256 bal = rewardPoolBalance();
        exitRewardPool(bal);
        _setPausedInvesting(true);
    }

    /*
     *   Resumes the ability to invest into the underlying reward pools
     */

    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    function setLiquidationPathsOnPancake(
        address[] memory _pancakeswapRouteToToken0,
        address[] memory _pancakeswapRouteToToken1
    ) public onlyGovernance {
        if (isLpToken) {
            address pancakeLPComponentToken0 = IPancakePair(underlying()).token0();
            address pancakeLPComponentToken1 = IPancakePair(underlying()).token1();
            pancakeswapRoutes[pancakeLPComponentToken0] = _pancakeswapRouteToToken0;
            pancakeswapRoutes[pancakeLPComponentToken1] = _pancakeswapRouteToToken1;
        } else {
            pancakeswapRoutes[underlying()] = _pancakeswapRouteToToken0;
        }
    }

    function _claimReward() internal {
        if (poolId() == 0) {
            IMasterChef(rewardPool()).leaveStaking(0); // withdraw 0 so that we dont notify fees on basis
        } else {
            IMasterChef(rewardPool()).withdraw(poolId(), 0);
        }
    }

    // We assume that all the tradings can be done on pancakeswap
    function _liquidateReward() internal {
        uint256 rewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
        if (!sell() || rewardBalance < sellFloor()) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
            return;
        }

        notifyProfitInRewardToken(rewardBalance);
        uint256 remainingRewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
        if (remainingRewardBalance > 0) {
            if (isLpToken) {
                _liquidateLpAssets(remainingRewardBalance);
            } else {
                _liquidateSingleAsset(remainingRewardBalance);
            }
        }
    }

    // Liquidate Cake into the single underlying asset (non-LP tokens), no-op if Cake is the underlying
    function _liquidateSingleAsset(uint256 remainingRewardBalance) internal {
        if (poolId() != 0) {
            address[] memory routesToken0 = pancakeswapRoutes[underlying()];

            uint256 amountOutMin = 1;

            // allow PancakeSwap to sell our reward
            IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
            IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

            // sell Uni to token2
            // we can accept 1 as minimum because this is called only by a trusted role
            IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
                remainingRewardBalance,
                amountOutMin,
                routesToken0,
                address(this),
                block.timestamp
            );
        }
    }

    // Liquidate Cake into underlying LP tokens, only do one swap if Cake/WBNB LP is the underlying
    function _liquidateLpAssets(uint256 remainingRewardBalance) internal {
        address uniLPComponentToken0 = IPancakePair(underlying()).token0();
        address uniLPComponentToken1 = IPancakePair(underlying()).token1();

        address[] memory routesToken0 = pancakeswapRoutes[address(uniLPComponentToken0)];
        address[] memory routesToken1 = pancakeswapRoutes[address(uniLPComponentToken1)];

        uint256 amountOutMin = 1;

        // allow PancakeSwap to sell our reward
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

        uint256 token0Amount;
        uint256 token1Amount;

        if (
            uniLPComponentToken0 == rewardToken() && // we are dealing with CAKE/WBNB LP
            routesToken1.length > 1 // we have a route to do the swap
        ) {
            token0Amount = remainingRewardBalance / 2; // 1/2 of CAKE is saved for LP
            uint256 toToken1 = remainingRewardBalance.sub(token0Amount); // other 1/2 is liquidated

            // sell Cake to token1
            // we can accept 1 as minimum because this is called only by a trusted role
            IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
                toToken1,
                amountOutMin,
                routesToken1,
                address(this),
                block.timestamp
            );
            token1Amount = IBEP20(uniLPComponentToken1).balanceOf(address(this));

            // Only approve WBNB, CAKE has already been approved at this point
            IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, 0);
            IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, token1Amount);

            // we provide liquidity to PancakeSwap
            uint256 liquidity;
            (, , liquidity) = IPancakeRouter02(pancakeswapRouterV2).addLiquidity(
                uniLPComponentToken0,
                uniLPComponentToken1,
                token0Amount,
                token1Amount,
                1, // we are willing to take whatever the pair gives us
                1, // we are willing to take whatever the pair gives us
                address(this),
                block.timestamp
            );
        } else if (
            routesToken0.length > 1 && // and we have a route to do the swap
            routesToken1.length > 1 // and we have a route to do the swap
        ) {
            uint256 toToken0 = remainingRewardBalance / 2;
            uint256 toToken1 = remainingRewardBalance.sub(toToken0);

            // sell Cake to token0
            // we can accept 1 as minimum because this is called only by a trusted role
            IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
                toToken0,
                amountOutMin,
                routesToken0,
                address(this),
                block.timestamp
            );
            token0Amount = IBEP20(uniLPComponentToken0).balanceOf(address(this));

            // sell Cake to token1
            // we can accept 1 as minimum because this is called only by a trusted role
            IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
                toToken1,
                amountOutMin,
                routesToken1,
                address(this),
                block.timestamp
            );
            token1Amount = IBEP20(uniLPComponentToken1).balanceOf(address(this));

            // provide liquidity to PancakeSwap
            IBEP20(uniLPComponentToken0).safeApprove(pancakeswapRouterV2, 0);
            IBEP20(uniLPComponentToken0).safeApprove(pancakeswapRouterV2, token0Amount);

            IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, 0);
            IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, token1Amount);
            
            uint256 liquidity;
            (, , liquidity) = IPancakeRouter02(pancakeswapRouterV2).addLiquidity(
                uniLPComponentToken0,
                uniLPComponentToken1,
                token0Amount,
                token1Amount,
                1, // we are willing to take whatever the pair gives us
                1, // we are willing to take whatever the pair gives us
                address(this),
                block.timestamp
            );
        }
    }

    /*
     *   Stakes everything the strategy holds into the reward pool
     */
    function investAllUnderlying() internal onlyNotPausedInvesting {
        // this check is needed, because most of the SNX reward pools will revert if
        // you try to stake(0).
        if (IBEP20(underlying()).balanceOf(address(this)) > 0) {
            enterRewardPool();
        }
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawAllToVault() public restricted {
        if (address(rewardPool()) != address(0)) {
            uint256 bal = rewardPoolBalance();
            exitRewardPool(bal);
        }
        if (poolId() != 0) {
            _liquidateReward();
        }
        IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawToVault(uint256 amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));

        if (amount > entireBalance) {
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = amount.sub(entireBalance);
            uint256 toWithdraw = MathUpgradeable.min(rewardPoolBalance(), needToWithdraw);
            IMasterChef(rewardPool()).withdraw(poolId(), toWithdraw);
        }

        IBEP20(underlying()).safeTransfer(vault(), amount);
    }

    /*
     *   Note that we currently do not have a mechanism here to include the
     *   amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool() == address(0)) {
            return IBEP20(underlying()).balanceOf(address(this));
        }
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return rewardPoolBalance().add(IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Governance or Controller can claim coins that are somehow transferred into the contract
     *   Note that they cannot come in take away coins that are used and defined in the strategy itself
     */
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IBEP20(token).safeTransfer(recipient, amount);
    }

    /*
     *   Get the reward, sell it in exchange for underlying, invest what you got.
     *   It's not much, but it's honest work.
     *
     *   Note that although `onlyNotPausedInvesting` is not added here,
     *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
     *   when the investing is being paused by governance.
     */
    function doHardWork() external onlyNotPausedInvesting restricted {
        uint256 bal = rewardPoolBalance();
        if (bal != 0) {
            _claimReward();
            _liquidateReward();
        }

        investAllUnderlying();
    }

    /**
     * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
     * simplest possible way.
     */
    function setSell(bool s) public onlyGovernance {
        _setSell(s);
    }

    /**
     * Sets the minimum amount of CRV needed to trigger a sale.
     */
    function setSellFloor(uint256 floor) public onlyGovernance {
        _setSellFloor(floor);
    }

    function _setIsLpToken(bool _isLpToken) internal {
        isLpToken = _isLpToken;
    }

    // masterchef rewards pool ID
    function _setPoolId(uint256 _value) internal {
        setUint256(_POOLID_SLOT, _value);
    }

    function poolId() public view returns (uint256) {
        return getUint256(_POOLID_SLOT);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
        // reset the liquidation paths
        // they need to be re-set manually
        address uniLPComponentToken0 = IPancakePair(underlying()).token0();
        address uniLPComponentToken1 = IPancakePair(underlying()).token1();

        // these would be required to be initialized separately by governance
        pancakeswapRoutes[uniLPComponentToken0] = new address[](0);
        pancakeswapRoutes[uniLPComponentToken1] = new address[](0);
    }
}

pragma solidity 0.6.12;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256);
    function massUpdatePools() external;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 amount);
    function pendingPickle(uint256 _pid, address _user) external view returns (uint256 amount);

    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IVBNB.sol";
import "./interfaces/CompleteVToken.sol";
import "../../interfaces/WBNB.sol";

contract VenusInteractor is ReentrancyGuardUpgradeable {

  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  IBEP20 public underlying;
  IBEP20 public wbnb;
  CompleteVToken public vtoken;
  ComptrollerInterface public comptroller;

  constructor(
    address _underlying,
    address _vtoken,
    address _wbnb,
    address _comptroller
  ) public {
    // Comptroller:
    comptroller = ComptrollerInterface(_comptroller);
    wbnb = IBEP20(_wbnb);

    underlying = IBEP20(_underlying);
    vtoken = CompleteVToken(_vtoken);

    // Enter the market
    address[] memory vTokens = new address[](1);
    vTokens[0] = _vtoken;
    comptroller.enterMarkets(vTokens);
  }

  /**
  * Supplies BNB to Venus
  * Unwraps WBNB to BNB, then invoke the special mint for vBNB
  * We ask to supply "amount", if the "amount" we asked to supply is
  * more than balance (what we really have), then only supply balance.
  * If we the "amount" we want to supply is less than balance, then
  * only supply that amount.
  */
  function _supplyBNBInWBNB(uint256 amountInWBNB) internal nonReentrant {
    // underlying here is WBNB
    uint256 balance = underlying.balanceOf(address(this)); // supply at most "balance"
    if (amountInWBNB < balance) {
      balance = amountInWBNB; // only supply the "amount" if its less than what we have
    }
    WBNB wbnb = WBNB(payable(address(wbnb)));
    wbnb.withdraw(balance); // Unwrapping
    IVBNB(address(vtoken)).mint.value(balance)();
  }

  /**
  * Redeems BNB from Venus
  * receives BNB. Wrap all the BNB that is in this contract.
  */
  function _redeemBNBInvTokens(uint256 amountVTokens) internal nonReentrant {
    _redeemInVTokens(amountVTokens);
    WBNB wbnb = WBNB(payable(address(wbnb)));
    wbnb.deposit.value(address(this).balance)();
  }

  /**
  * Supplies to Venus
  */
  function _supply(uint256 amount) internal returns(uint256) {
    uint256 balance = underlying.balanceOf(address(this));
    if (amount < balance) {
      balance = amount;
    }
    underlying.safeApprove(address(vtoken), 0);
    underlying.safeApprove(address(vtoken), balance);
    uint256 mintResult = vtoken.mint(balance);
    require(mintResult == 0, "Supplying failed");
    return balance;
  }

  /**
  * Borrows against the collateral
  */
  function _borrow(uint256 amountUnderlying) internal {
    // Borrow, check the balance for this contract's address
    uint256 result = vtoken.borrow(amountUnderlying);
    require(result == 0, "Borrow failed");
  }

  /**
  * Borrows against the collateral
  */
  function _borrowInWBNB(uint256 amountUnderlying) internal {
    // Borrow BNB, wraps into WBNB
    uint256 result = vtoken.borrow(amountUnderlying);
    require(result == 0, "Borrow failed");
    WBNB wbnb = WBNB(payable(address(wbnb)));
    wbnb.deposit.value(address(this).balance)();
  }

  /**
  * Repays a loan
  */
  function _repay(uint256 amountUnderlying) internal {
    underlying.safeApprove(address(vtoken), 0);
    underlying.safeApprove(address(vtoken), amountUnderlying);
    vtoken.repayBorrow(amountUnderlying);
    underlying.safeApprove(address(vtoken), 0);
  }

  /**
  * Repays a loan in BNB
  */
  function _repayInWBNB(uint256 amountUnderlying) internal {
    WBNB wbnb = WBNB(payable(address(wbnb)));
    wbnb.withdraw(amountUnderlying); // Unwrapping
    IVBNB(address(vtoken)).repayBorrow.value(amountUnderlying)();
  }

  /**
  * Redeem liquidity in vTokens
  */
  function _redeemInVTokens(uint256 amountVTokens) internal {
    if(amountVTokens > 0){
      vtoken.redeem(amountVTokens);
    }
  }

  /**
  * Redeem liquidity in underlying
  */
  function _redeemUnderlying(uint256 amountUnderlying) internal {
    if (amountUnderlying > 0) {
      vtoken.redeemUnderlying(amountUnderlying);
    }
  }

  /**
  * Redeem liquidity in underlying
  */
  function redeemUnderlyingInWBNB(uint256 amountUnderlying) internal {
    if (amountUnderlying > 0) {
      _redeemUnderlying(amountUnderlying);
      WBNB wbnb = WBNB(payable(address(wbnb)));
      wbnb.deposit.value(address(this).balance)();
    }
  }

  /**
  * Get XVS
  */
  function claimVenus() public {
    comptroller.claimVenus(address(this));
  }

  /**
  * Redeem the minimum of the WBNB we own, and the WBNB that the vToken can
  * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently
  */
  function redeemMaximumWBNB() internal {
    // amount of WBNB in contract
    uint256 available = vtoken.getCash();
    // amount of WBNB we own
    uint256 owned = vtoken.balanceOfUnderlying(address(this));

    // redeem the most we can redeem
    redeemUnderlyingInWBNB(available < owned ? available : owned);
  }

  function redeemMaximumWithLoan(uint256 collateralFactorNumerator, uint256 collateralFactorDenominator, uint256 borrowMinThreshold) internal {
    // amount of liquidity in Venus
    uint256 available = vtoken.getCash();
    // amount we supplied
    uint256 supplied = vtoken.balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = vtoken.borrowBalanceCurrent(address(this));

    while (borrowed > borrowMinThreshold) {
      uint256 requiredCollateral = borrowed
        .mul(collateralFactorDenominator)
        .add(collateralFactorNumerator.div(2))
        .div(collateralFactorNumerator);

      // redeem just as much as needed to repay the loan
      uint256 wantToRedeem = supplied.sub(requiredCollateral);
      _redeemUnderlying(MathUpgradeable.min(wantToRedeem, available));

      // now we can repay our borrowed amount
      uint256 balance = underlying.balanceOf(address(this));
      _repay(MathUpgradeable.min(borrowed, balance));

      // update the parameters
      available = vtoken.getCash();
      borrowed = vtoken.borrowBalanceCurrent(address(this));
      supplied = vtoken.balanceOfUnderlying(address(this));
    }

    // redeem the most we can redeem
    _redeemUnderlying(MathUpgradeable.min(available, supplied));
  }

  function redeemMaximumWBNBWithLoan(uint256 collateralFactorNumerator, uint256 collateralFactorDenominator, uint256 borrowMinThreshold) internal {
    // amount of liquidity in Venus
    uint256 available = vtoken.getCash();
    // amount of WBNB we supplied
    uint256 supplied = vtoken.balanceOfUnderlying(address(this));
    // amount of WBNB we borrowed
    uint256 borrowed = vtoken.borrowBalanceCurrent(address(this));

    while (borrowed > borrowMinThreshold) {
      uint256 requiredCollateral = borrowed
        .mul(collateralFactorDenominator)
        .add(collateralFactorNumerator.div(2))
        .div(collateralFactorNumerator);

      // redeem just as much as needed to repay the loan
      uint256 wantToRedeem = supplied.sub(requiredCollateral);
      redeemUnderlyingInWBNB(MathUpgradeable.min(wantToRedeem, available));

      // now we can repay our borrowed amount
      uint256 balance = underlying.balanceOf(address(this));
      _repayInWBNB(MathUpgradeable.min(borrowed, balance));

      // update the parameters
      available = vtoken.getCash();
      borrowed = vtoken.borrowBalanceCurrent(address(this));
      supplied = vtoken.balanceOfUnderlying(address(this));
    }

    // redeem the most we can redeem
    redeemUnderlyingInWBNB(MathUpgradeable.min(available, supplied));
  }

  function getLiquidity() external view returns(uint256) {
    return vtoken.getCash();
  }

  function redeemMaximumToken() internal {
    // amount of tokens in vtoken
    uint256 available = vtoken.getCash();
    // amount of tokens we own
    uint256 owned = vtoken.balanceOfUnderlying(address(this));

    // redeem the most we can redeem
    _redeemUnderlying(available < owned ? available : owned);
  }

  receive() external payable {} // this is needed for the WBNB unwrapping
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./interface/IMasterBelt.sol";
import "./interface/IMultiStrategyToken.sol";

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "../../upgradability/BaseUpgradeableStrategy.sol";
import "../../interfaces/pancakeswap/IPancakeRouter02.sol";

contract BeltSingleStrategy is BaseUpgradeableStrategy {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  address constant public pancakeswapRouterV2 = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _DEPOSITOR_SLOT = 0x7e51443ed339b944018a93b758544b6d25c6c65ccaf25ffca5127da0103d7ddf;
  bytes32 internal constant _DEPOSITOR_UNDERLYING_SLOT = 0xfffae5dac57e2313ef5a16a03f71dacc1da392f7ae9ca598779f29a0ada318c2;

  address[] public pancake_route;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_DEPOSITOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositor")) - 1));
    assert(_DEPOSITOR_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositorUnderlying")) - 1));
  }

  function initialize(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    address _depositHelp,
    address _depositorUnderlying,
    uint256 _poolID
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      100, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e16, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,,) = IMasterBelt(rewardPool()).poolInfo(_poolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolID);
    _setDepositor(_depositHelp);
    _setDepositorUnderlying(_depositorUnderlying);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterBelt(rewardPool()).userInfo(poolId(), address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));
    IBEP20(underlying()).safeApprove(rewardPool(), 0);
    IBEP20(underlying()).safeApprove(rewardPool(), entireBalance);

    IMasterBelt(rewardPool()).deposit(poolId(), entireBalance);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    IMasterBelt(rewardPool()).emergencyWithdraw(poolId());
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function setLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[0] == rewardToken(), "Path should start with rewardToken");
    pancake_route = _route;
  }

  // We assume that all the tradings can be done on Pancakeswap
  function _liquidateReward() internal {
    uint256 rewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
    if (!sell() || rewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
      return;
    }

    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IBEP20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    // allow Pancakeswap to sell our reward
    IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
    IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

    // we can accept 1 as minimum because this is called only by a trusted role
    uint256 amountOutMin = 1;

    IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
      remainingRewardBalance,
      amountOutMin,
      pancake_route,
      address(this),
      block.timestamp
    );
  }

  function claimAndLiquidateReward() internal {
    IMasterBelt(rewardPool()).withdraw(poolId(), 0);
    _liquidateReward();
    if (IBEP20(depositorUnderlying()).balanceOf(address(this)) > 0) {
      getUnderlyingFromDepositor();
    }
  }

  function getUnderlyingFromDepositor() internal {
    uint256 depositorUnderlyingBalance = IBEP20(depositorUnderlying()).balanceOf(address(this));
    if (depositorUnderlyingBalance > 0) {
      IBEP20(depositorUnderlying()).safeApprove(depositor(), 0);
      IBEP20(depositorUnderlying()).safeApprove(depositor(), depositorUnderlyingBalance);

      // we can accept 0 as minimum, this will be called only by trusted roles
      uint256 minimum = 0;
      IMultiStrategyToken(depositor()).deposit(depositorUnderlyingBalance, minimum);
    }
  }


  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IBEP20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool()) != address(0)) {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
        claimAndLiquidateReward();
        IMasterBelt(rewardPool()).withdraw(poolId(), bal);
      }
    }
    IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = MathUpgradeable.min(rewardPoolBalance(), needToWithdraw);
      IMasterBelt(rewardPool()).withdraw(poolId(), toWithdraw);
    }

    IBEP20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IBEP20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IBEP20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IBEP20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    uint256 bal = rewardPoolBalance();
    if (bal != 0) {
      claimAndLiquidateReward();
    }
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function _setDepositor(address _address) internal {
    setAddress(_DEPOSITOR_SLOT, _address);
  }

  function depositor() public virtual view returns (address) {
    return getAddress(_DEPOSITOR_SLOT);
  }

  function _setDepositorUnderlying(address _address) internal {
    setAddress(_DEPOSITOR_UNDERLYING_SLOT, _address);
  }

  function depositorUnderlying() public virtual view returns (address) {
    return getAddress(_DEPOSITOR_UNDERLYING_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMasterBelt {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256, address);
    function massUpdatePools() external;
    function emergencyWithdraw(uint256 _pid) external;
    function withdrawAll(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMultiStrategyToken {
  function deposit(uint256 _amount, uint256 _minShares) external;
  function withdraw(uint256 _shares, uint256 _minAmount) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./BeltSingleStrategy.sol";

contract BeltSingleStrategy_ETH is BeltSingleStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address belt = address(0xE0e514c71282b6f4e823703a39374Cf58dc3eA4f);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address beltETH = address(0xAA20E8Cb61299df2357561C2AC2e1172bC68bc25);
    address eth = address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    address masterBelt = address(0xD4BbC80b9B102b77B21A06cb77E954049605E6c1);
    BeltSingleStrategy.initialize(
      _storage,
      beltETH,
      _vault,
      masterBelt, // stakingPool
      belt,
      beltETH,
      eth,
      8  // Pool id
    );
    pancake_route = [belt, wbnb, eth];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./BeltSingleStrategy.sol";

contract BeltSingleStrategy_BTCB is BeltSingleStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address belt = address(0xE0e514c71282b6f4e823703a39374Cf58dc3eA4f);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address beltBTC = address(0x51bd63F240fB13870550423D208452cA87c44444);
    address btcb = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    address masterBelt = address(0xD4BbC80b9B102b77B21A06cb77E954049605E6c1);
    BeltSingleStrategy.initialize(
      _storage,
      beltBTC,
      _vault,
      masterBelt, // stakingPool
      belt,
      beltBTC,
      btcb,
      7  // Pool id
    );
    pancake_route = [belt, wbnb, btcb];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./interface/IMasterBelt.sol";
import "./interface/IDepositor.sol";

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "../../upgradability/BaseUpgradeableStrategy.sol";
import "../../interfaces/pancakeswap/IPancakeRouter02.sol";

contract BeltMultiStrategy is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public constant pancakeswapRouterV2 = address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    address public constant busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
    bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
    bytes32 internal constant _DEPOSITOR_SLOT = 0x7e51443ed339b944018a93b758544b6d25c6c65ccaf25ffca5127da0103d7ddf;

    address[] public pancake_BELT2BUSD;

    constructor() public BaseUpgradeableStrategy() {
        assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
        assert(_DEPOSITOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositor")) - 1));
    }

    function initializeStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address _rewardToken,
        address _depositHelp,
        uint256 _poolID
    ) internal initializer {
        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            _rewardPool,
            _rewardToken,
            100, // profit sharing numerator
            1000, // profit sharing denominator
            true, // sell
            1e16, // sell floor
            12 hours // implementation change delay
        );

        address _blp;
        (_blp, , , , ) = IMasterBelt(rewardPool()).poolInfo(_poolID);
        require(_blp == underlying(), "Pool Info does not match underlying");
        _setPoolId(_poolID);
        _setDepositor(_depositHelp);
    }

    function depositArbCheck() public pure returns (bool) {
        return true;
    }

    function rewardPoolBalance() internal view returns (uint256 bal) {
        (bal, ) = IMasterBelt(rewardPool()).userInfo(poolId(), address(this));
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function enterRewardPool() internal {
        uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));
        IBEP20(underlying()).safeApprove(rewardPool(), 0);
        IBEP20(underlying()).safeApprove(rewardPool(), entireBalance);

        IMasterBelt(rewardPool()).deposit(poolId(), entireBalance);
    }

    /*
     *   In case there are some issues discovered about the pool or underlying asset
     *   Governance can exit the pool properly
     *   The function is only used for emergency to exit the pool
     */
    function emergencyExit() public onlyGovernance {
        IMasterBelt(rewardPool()).emergencyWithdraw(poolId());
        _setPausedInvesting(true);
    }

    /*
     *   Resumes the ability to invest into the underlying reward pools
     */
    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    function setLiquidationPath(address[] memory _route) public onlyGovernance {
        require(_route[0] == rewardToken(), "Path should start with rewardToken");
        pancake_BELT2BUSD = _route;
    }

    // We assume that all the tradings can be done on Pancakeswap
    function _liquidateReward() internal {
        uint256 rewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
        if (!sell() || rewardBalance < sellFloor()) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
            return;
        }

        notifyProfitInRewardToken(rewardBalance);
        uint256 remainingRewardBalance = IBEP20(rewardToken()).balanceOf(address(this));

        if (remainingRewardBalance == 0) {
            return;
        }

        // allow Pancakeswap to sell our reward
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
        IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

        // we can accept 1 as minimum because this is called only by a trusted role
        uint256 amountOutMin = 1;

        IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
            remainingRewardBalance,
            amountOutMin,
            pancake_BELT2BUSD,
            address(this),
            block.timestamp
        );
    }

    function claimAndLiquidateReward() internal {
        IMasterBelt(rewardPool()).withdraw(poolId(), 0);
        _liquidateReward();
        uint256 busdBalance = IBEP20(busd).balanceOf(address(this));
        if (busdBalance > 0) {
            IBEP20(busd).safeApprove(depositor(), 0);
            IBEP20(busd).safeApprove(depositor(), busdBalance);
            // we can accept 0 as minimum, this will be called only by trusted roles
            uint256 minimum = 0;
            IDepositor(depositor()).add_liquidity([0, 0, 0, busdBalance], minimum); // deposit stablecoin
        }
    }

    /*
     *   Stakes everything the strategy holds into the reward pool
     */
    function investAllUnderlying() internal onlyNotPausedInvesting {
        // this check is needed, because most of the SNX reward pools will revert if
        // you try to stake(0).
        if (IBEP20(underlying()).balanceOf(address(this)) > 0) {
            enterRewardPool();
        }
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawAllToVault() public restricted {
        if (address(rewardPool()) != address(0)) {
            uint256 bal = rewardPoolBalance();
            if (bal != 0) {
                claimAndLiquidateReward();
                IMasterBelt(rewardPool()).withdraw(poolId(), bal);
            }
        }
        IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawToVault(uint256 amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));

        if (amount > entireBalance) {
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = amount.sub(entireBalance);
            uint256 toWithdraw = MathUpgradeable.min(rewardPoolBalance(), needToWithdraw);
            IMasterBelt(rewardPool()).withdraw(poolId(), toWithdraw);
        }

        IBEP20(underlying()).safeTransfer(vault(), amount);
    }

    /*
     *   Note that we currently do not have a mechanism here to include the
     *   amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool() == address(0)) {
            return IBEP20(underlying()).balanceOf(address(this));
        }
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return rewardPoolBalance().add(IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Governance or Controller can claim coins that are somehow transferred into the contract
     *   Note that they cannot come in take away coins that are used and defined in the strategy itself
     */
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IBEP20(token).safeTransfer(recipient, amount);
    }

    /*
     *   Get the reward, sell it in exchange for underlying, invest what you got.
     *   It's not much, but it's honest work.
     *
     *   Note that although `onlyNotPausedInvesting` is not added here,
     *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
     *   when the investing is being paused by governance.
     */
    function doHardWork() external onlyNotPausedInvesting restricted {
        uint256 bal = rewardPoolBalance();
        if (bal != 0) {
            claimAndLiquidateReward();
        }
        investAllUnderlying();
    }

    /**
     * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
     * simplest possible way.
     */
    function setSell(bool s) public onlyGovernance {
        _setSell(s);
    }

    /**
     * Sets the minimum amount needed to trigger a sale.
     */
    function setSellFloor(uint256 floor) public onlyGovernance {
        _setSellFloor(floor);
    }

    // rewards pool ID
    function _setPoolId(uint256 _value) internal {
        setUint256(_POOLID_SLOT, _value);
    }

    function poolId() public view returns (uint256) {
        return getUint256(_POOLID_SLOT);
    }

    function _setDepositor(address _address) internal {
        setAddress(_DEPOSITOR_SLOT, _address);
    }

    function depositor() public view virtual returns (address) {
        return getAddress(_DEPOSITOR_SLOT);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IDepositor {
    function add_liquidity(uint256[4] calldata amounts, uint256 min_amount) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./BeltMultiStrategy.sol";

contract BeltMultiStrategy_4Belt is BeltMultiStrategy {
    constructor() public {}

    function initializeStrategy(address _storage, address _vault) public initializer {
        address underlying = address(0x9cb73F20164e399958261c289Eb5F9846f4D1404); // 4Belt BLP token
        address belt = address(0xE0e514c71282b6f4e823703a39374Cf58dc3eA4f);
        address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        address depositHelp = address(0xF6e65B33370Ee6A49eB0dbCaA9f43839C1AC04d5); // Viper contract where stablecoins are deposited
        address busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        
        BeltMultiStrategy.initializeStrategy(
            _storage,
            underlying,
            _vault,
            address(0xD4BbC80b9B102b77B21A06cb77E954049605E6c1), // Masterchef contract staking pool
            belt, // reward
            depositHelp,
            3 // Pool id for 4Belt
        );
        
        pancake_BELT2BUSD = [belt, wbnb, busd];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./interface/IMasterChef.sol";
import "../../../interfaces/IStrategy.sol";

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "../../../interfaces/IVault.sol";
import "../../../upgradability/BaseUpgradeableStrategy.sol";
import "../../../interfaces/pancakeswap/IPancakePair.sol";
import "../../../interfaces/pancakeswap/IPancakeRouter02.sol";

contract GeneralMasterChefStrategyNewRouter is BaseUpgradeableStrategy {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  address constant public pancakeswapRouterV2 = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _IS_LP_ASSET_SLOT = 0xc2f3dabf55b1bdda20d5cf5fcba9ba765dfc7c9dbaf28674ce46d43d60d58768;

  // this would be reset on each upgrade
  mapping (address => address[]) public pancakeswapRoutes;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_IS_LP_ASSET_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.isLpAsset")) - 1));
  }

  function initializeStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _poolID,
    bool _isLpToken
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      100, // profit sharing numerator
      1000, // profit sharing denominator
      true, // sell
      1e16, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,) = IMasterChef(rewardPool()).poolInfo(_poolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setPoolId(_poolID);

    if (_isLpToken) {
      address uniLPComponentToken0 = IPancakePair(underlying()).token0();
      address uniLPComponentToken1 = IPancakePair(underlying()).token1();

      // these would be required to be initialized separately by governance
      pancakeswapRoutes[uniLPComponentToken0] = new address[](0);
      pancakeswapRoutes[uniLPComponentToken1] = new address[](0);
    } else {
      pancakeswapRoutes[underlying()] = new address[](0);
    }

    setBoolean(_IS_LP_ASSET_SLOT, _isLpToken);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));
    IBEP20(underlying()).safeApprove(rewardPool(), 0);
    IBEP20(underlying()).safeApprove(rewardPool(), entireBalance);

    IMasterChef(rewardPool()).deposit(poolId(), entireBalance);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    uint256 bal = rewardPoolBalance();
    IMasterChef(rewardPool()).withdraw(poolId(), bal);
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function setLiquidationPath(address _token, address [] memory _route) public onlyGovernance {
    require(_route[0] == rewardToken(), "Path should start with rewardToken");
    require(_route[_route.length-1] == _token, "Path should end with given Token");
    pancakeswapRoutes[_token] = _route;
  }

  // We assume that all the tradings can be done on Pancakeswap
  function _liquidateReward(uint256 rewardBalance) internal virtual {
    if (!sell() || rewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
      return;
    }

    notifyProfitInRewardToken(rewardBalance);
    uint256 remainingRewardBalance = IBEP20(rewardToken()).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    // allow Pancakeswap to sell our reward
    IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
    IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

    // we can accept 1 as minimum because this is called only by a trusted role
    uint256 amountOutMin = 1;

    if (isLpAsset()) {
      address uniLPComponentToken0 = IPancakePair(underlying()).token0();
      address uniLPComponentToken1 = IPancakePair(underlying()).token1();

      uint256 toToken0 = remainingRewardBalance.div(2);
      uint256 toToken1 = remainingRewardBalance.sub(toToken0);

      uint256 token0Amount;

      if (pancakeswapRoutes[uniLPComponentToken0].length > 1) {
        // if we need to liquidate the token0
        IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
          toToken0,
          amountOutMin,
          pancakeswapRoutes[uniLPComponentToken0],
          address(this),
          block.timestamp
        );
        token0Amount = IBEP20(uniLPComponentToken0).balanceOf(address(this));
      } else {
        // otherwise we assme token0 is the reward token itself
        token0Amount = toToken0;
      }

      uint256 token1Amount;

      if (pancakeswapRoutes[uniLPComponentToken1].length > 1) {
        // sell reward token to token1
        IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
          toToken1,
          amountOutMin,
          pancakeswapRoutes[uniLPComponentToken1],
          address(this),
          block.timestamp
        );
        token1Amount = IBEP20(uniLPComponentToken1).balanceOf(address(this));
      } else {
        token1Amount = toToken1;
      }

      // we provide liquidity to Pancake
      IBEP20(uniLPComponentToken0).safeApprove(pancakeswapRouterV2, 0);
      IBEP20(uniLPComponentToken0).safeApprove(pancakeswapRouterV2, token0Amount);

      IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, 0);
      IBEP20(uniLPComponentToken1).safeApprove(pancakeswapRouterV2, token1Amount);
      
      uint256 liquidity;
      (,,liquidity) = IPancakeRouter02(pancakeswapRouterV2).addLiquidity(
        uniLPComponentToken0,
        uniLPComponentToken1,
        token0Amount,
        token1Amount,
        1,  // we are willing to take whatever the pair gives us
        1,  // we are willing to take whatever the pair gives us
        address(this),
        block.timestamp
      );
    } else {
      if (underlying() != rewardToken()) {
        IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
          remainingRewardBalance,
          amountOutMin,
          pancakeswapRoutes[underlying()],
          address(this),
          block.timestamp
        );
      }
    }
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IBEP20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(rewardPool()) != address(0)) {
      uint256 bal = rewardPoolBalance();
      if (bal != 0) {
        IMasterChef(rewardPool()).withdraw(poolId(), bal);
      }
    }
    if (underlying() != rewardToken()) {
      uint256 rewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
      _liquidateReward(rewardBalance);
    }
    IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IBEP20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = MathUpgradeable.min(rewardPoolBalance(), needToWithdraw);
      IMasterChef(rewardPool()).withdraw(poolId(), toWithdraw);
    }

    IBEP20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IBEP20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return rewardPoolBalance().add(IBEP20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IBEP20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    uint256 bal = rewardPoolBalance();
    if (bal != 0) {
      uint256 rewardBalanceBefore = IBEP20(rewardToken()).balanceOf(address(this));
      IMasterChef(rewardPool()).withdraw(poolId(), 0);
      uint256 rewardBalanceAfter = IBEP20(rewardToken()).balanceOf(address(this));
      uint256 claimedReward = rewardBalanceAfter.sub(rewardBalanceBefore);
      _liquidateReward(claimedReward);
    }

    investAllUnderlying();
  }

  /**
  * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function isLpAsset() public view returns (bool) {
    return getBoolean(_IS_LP_ASSET_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
    // reset the liquidation paths
    // they need to be re-set manually
    if (isLpAsset()) {
      pancakeswapRoutes[IPancakePair(underlying()).token0()] = new address[](0);
      pancakeswapRoutes[IPancakePair(underlying()).token1()] = new address[](0);
    } else {
      pancakeswapRoutes[underlying()] = new address[](0);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256);
    function massUpdatePools() external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "../base/masterchef/GeneralMasterChefStrategyNewRouter.sol";

contract BeltLPStrategy_BELT_BNB is GeneralMasterChefStrategyNewRouter {

  address public belt_bnb_unused; // just a differentiator for the bytecode

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xF3Bc6FC080ffCC30d93dF48BFA2aA14b869554bb);
    address belt = address(0xE0e514c71282b6f4e823703a39374Cf58dc3eA4f);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    GeneralMasterChefStrategyNewRouter.initializeStrategy(
      _storage,
      underlying,
      _vault,
      address(0xD4BbC80b9B102b77B21A06cb77E954049605E6c1), // master chef contract
      belt, // reward token
      11,  // Pool id
      true // is LP asset
    );

    pancakeswapRoutes[wbnb] = [belt, wbnb];
  }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "./interfaces/IController.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";
import "./FeeRewardForwarder.sol";
import "./Governable.sol";

contract Controller is IController, Governable {
    using SafeBEP20 for IBEP20;
    using Address for address;
    using SafeMath for uint256;

    // external parties
    address payable public override feeRewardForwarder;
    bool public feeForwarding;

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    mapping(address => bool) public override greyList;

    // All vaults that we have
    mapping(address => bool) public vaults;

    uint256 public constant override profitSharingNumerator = 10;
    uint256 public constant override profitSharingDenominator = 100;

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    modifier validVault(address _vault) {
        require(vaults[_vault], "vault does not exist");
        _;
    }

    mapping(address => bool) public hardWorkers;

    modifier onlyHardWorkerOrGovernance() {
        require(
            hardWorkers[msg.sender] || (msg.sender == governance()),
            "only hard worker can call this"
        );
        _;
    }

    constructor(address _storage, address payable _feeRewardForwarder) public Governable(_storage) {
        require(_feeRewardForwarder != address(0), "feeRewardForwarder should not be empty");
        feeRewardForwarder = _feeRewardForwarder;
        enableForwarding();
    }

    function disableForwarding() public onlyGovernance {
        feeForwarding = false;
    }

    function enableForwarding() public onlyGovernance {
        feeForwarding = true;
    }

    function addHardWorker(address _worker) public onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        hardWorkers[_worker] = true;
    }

    function removeHardWorker(address _worker) public onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        hardWorkers[_worker] = false;
    }

    function hasVault(address _vault) external override returns (bool) {
        return vaults[_vault];
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) public onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) public onlyGovernance {
        greyList[_target] = false;
    }

    function setFeeRewardForwarder(address payable _feeRewardForwarder)
        public
        override
        onlyGovernance
    {
        require(_feeRewardForwarder != address(0), "new reward forwarder should not be empty");
        feeRewardForwarder = _feeRewardForwarder;
    }

    function addVaultAndStrategy(address _vault, address _strategy)
        external
        override
        onlyGovernance
    {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(!vaults[_vault], "vault already exists");
        require(_strategy != address(0), "new strategy shouldn't be empty");

        vaults[_vault] = true;
        // adding happens while setting
        IVault(_vault).setStrategy(_strategy);
    }

    function doHardWork(address _vault)
        external
        override
        onlyHardWorkerOrGovernance
        validVault(_vault)
    {
        uint256 oldSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).doHardWork();
        emit SharePriceChangeLog(
            _vault,
            IVault(_vault).strategy(),
            oldSharePrice,
            IVault(_vault).getPricePerFullShare(),
            block.timestamp
        );
    }

    // transfers token in the controller contract to the governance
    function salvage(address _token, uint256 _amount) external override onlyGovernance {
        IBEP20(_token).safeTransfer(governance(), _amount);
    }

    function salvageStrategy(
        address _strategy,
        address _token,
        uint256 _amount
    ) external override onlyGovernance {
        // the strategy is responsible for maintaining the list of
        // salvagable tokens, to make sure that governance cannot come
        // in and take away the coins
        IStrategy(_strategy).salvage(governance(), _token, _amount);
    }

    function notifyFee(address underlying, uint256 fee) external override {
        if (fee > 0 && feeForwarding) {
            IBEP20(underlying).safeTransferFrom(msg.sender, address(this), fee);
            IBEP20(underlying).safeApprove(feeRewardForwarder, 0);
            IBEP20(underlying).safeApprove(feeRewardForwarder, fee);
            FeeRewardForwarder(feeRewardForwarder).poolNotifyFixedTarget(underlying,fee);
        }
    }
}

pragma solidity 0.6.12;

import "./Governable.sol";
import "./interfaces/IRewardPool.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "./interfaces/pancakeswap/IPancakeRouter02.sol";

contract FeeRewardForwarder is Governable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    // yield farming
    address public constant cake = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    address public constant xvs = address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63);

    // wbnb
    address public constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    mapping(address => address[]) public pancakeswapRoutes;

    uint256 public hardworkSupportNumerator = 20; // 20% of profit sharing fee
    uint256 public hardworkSupportDenominator = 100;
    address payable public hardworkerAccount;

    // the targeted reward token to convert everything to
    address public targetToken;
    address public profitSharingPool;

    address public pancakeswapRouterV2; // 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F

    event TokenPoolSet(address token, address pool);

    constructor(
        address _storage,
        address _targetToken,
        address _router,
        address payable _hardworkerAccount
    ) public Governable(_storage) {
        require(_hardworkerAccount != address(0), "pool address cannot be zero");
        targetToken = _targetToken;
        pancakeswapRouterV2 = _router;
        hardworkerAccount = _hardworkerAccount;

        pancakeswapRoutes[cake] = [cake, wbnb, _targetToken];
        pancakeswapRoutes[xvs] = [xvs, wbnb, _targetToken];
    }

    receive() external payable {}

    /*
     *   Set the pool that will receive the reward token
     *   based on the address of the reward Token
     */
    function setEOA(address _eoa) public onlyGovernance {
        require(_eoa != address(0), "address cannot be zero");
        profitSharingPool = _eoa;
        emit TokenPoolSet(targetToken, _eoa);
    }

    /**
     * Sets the path for swapping tokens to the to address
     * The to address is not validated to match the targetToken,
     * so that we could first update the paths, and then,
     * set the new target
     */
    function setConversionPath(address from, address[] memory _pancakeswapRoute)
        public
        onlyGovernance
    {
        require(
            from == _pancakeswapRoute[0],
            "The first token of the Pancakeswap route must be the from token"
        );
        require(
            targetToken == _pancakeswapRoute[_pancakeswapRoute.length - 1],
            "The last token of the Pancakeswap route must be the reward token"
        );

        pancakeswapRoutes[from] = _pancakeswapRoute;
    }

    // Transfers the funds from the msg.sender to the pool
    // under normal circumstances, msg.sender is the strategy
    function poolNotifyFixedTarget(address _token, uint256 _amount) external {
        // it is only used to check that the rewardPool is set.
        if (targetToken == address(0)) {
            return; // a No-op if target pool is not set yet
        }
        uint256 hardworkSupportAmount = _amount.mul(hardworkSupportNumerator).div(
            hardworkSupportDenominator
        );
        uint256 remainingAmount = _amount.sub(hardworkSupportAmount);
        liquidateToBNB(_token, hardworkSupportAmount);
        sendBnbToHardworkAccount();

        if (_token == targetToken) {
            IBEP20(_token).safeTransferFrom(msg.sender, profitSharingPool, remainingAmount);
            IRewardPool(profitSharingPool).notifyRewardAmount(remainingAmount);

        } else {
            require(
                pancakeswapRoutes[_token].length > 1,
                "FeeRewardForwarder: liquidation path doesn't exist"
            );

            // we need to convert _token to FARM
            IBEP20(_token).safeTransferFrom(msg.sender, address(this), remainingAmount);
            uint256 balanceToSwap = IBEP20(_token).balanceOf(address(this));
            liquidate(_token, balanceToSwap);

            // now we can send this token forward
            uint256 convertedRewardAmount = IBEP20(targetToken).balanceOf(address(this));

            IBEP20(targetToken).safeTransfer(profitSharingPool, convertedRewardAmount);
            IRewardPool(profitSharingPool).notifyRewardAmount(convertedRewardAmount);
            // send the token to the cross-chain converter address
        }
    }

    function liquidate(address _from, uint256 balanceToSwap) internal {
        if (balanceToSwap > 0) {
            address router = pancakeswapRouterV2;
            IBEP20(_from).safeApprove(router, 0);
            IBEP20(_from).safeApprove(router, balanceToSwap);

            IPancakeRouter02(router).swapExactTokensForTokens(
                balanceToSwap,
                0,
                pancakeswapRoutes[_from],
                address(this),
                block.timestamp
            );
        }
    }

    function sendBnbToHardworkAccount() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            hardworkerAccount.transfer(balance);
        }
    }

    function liquidateToBNB(address _from, uint256 balanceToSwap) internal {
        address[] memory route = new address[](2);
        route[0] = _from;
        route[1] = wbnb;

        if (balanceToSwap > 0) {
            IBEP20(_from).safeTransferFrom(msg.sender, address(this), balanceToSwap);
            uint256 balance_ = IBEP20(_from).balanceOf(address(this));
            address router = pancakeswapRouterV2;
            IBEP20(_from).safeApprove(router, 0);
            IBEP20(_from).safeApprove(router, balanceToSwap);

            IPancakeRouter02(router).swapExactTokensForETH(
                balanceToSwap,
                0,
                route,
                address(this),
                block.timestamp
            );
        }
    }

    function setHardworkerAccount(address payable _worker) public onlyGovernance {
        require(_worker != address(0), "pool address cannot be zero");
        hardworkerAccount = _worker;
    }

    function setHardworkSupportNumerator(uint256 _amount) public onlyGovernance {
        hardworkSupportNumerator = _amount;
    }
}

pragma solidity 0.6.12;

// Unifying the interface with the Synthetix Reward Pool
interface IRewardPool {
  function rewardToken() external view returns (address);
  function lpToken() external view returns (address);
  function duration() external view returns (uint256);

  function periodFinish() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);

  function stake(uint256 amountWei) external;

  // `balanceOf` would give the amount staked.
  // As this is 1 to 1, this is also the holder's share
  function balanceOf(address holder) external view returns (uint256);
  // total shares & total lpTokens staked
  function totalSupply() external view returns(uint256);

  function withdraw(uint256 amountWei) external;
  function exit() external;

  // get claimed rewards
  function earned(address holder) external view returns (uint256);

  // claim rewards
  function getReward() external;

  // notify
  function notifyRewardAmount(uint256 _amount) external;
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../Governable.sol";
import "../token/Lantti.sol";
import "./VaultyNft.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "../interfaces/IUpgradeSource.sol";
import "../ControllableInit.sol";
import "../upgradability/BaseProxyStorage.sol";

contract NftMarket is ControllableInit, BaseProxyStorage, IUpgradeSource {
    using SafeMath for uint256;

    enum SetKind {
        Unknown,
        Random,
        Redeemable
    }

    event SetAdded(uint256 indexed setId, SetKind kind, uint256 price);
    event SetRemoved(uint256 indexed setId);
    event NftAdded(uint256 indexed setId, uint256[] nftIds, uint256[] amounts);
    event NftRedeemed(address indexed user, uint256 indexed setId, uint256 id, uint256 price);

    struct SetItem {
        uint256 nftId;
        uint256 amountLeft;
    }

    struct Set {
        SetKind kind;
        SetItem[] items;
        uint256 price;
    }

    uint256 public lastSetId;
    VaultyNft public nft;
    Lantti public lantti;
    
    mapping(uint256 => Set) public sets;
    mapping(address => uint256) private seeds; // keep individual seed per address

    constructor() public {}

    function initialize(
        address _storage,
        VaultyNft _nft,
        Lantti _lantti
    ) public initializer {
        ControllableInit.initialize(_storage);
        nft = _nft;
        lantti = _lantti;
    }

    function getSet(uint256 setId) public view returns(Set memory) {
        return sets[setId];
    }

    function removeSet(uint256 setId) public onlyGovernance {
        delete sets[setId];
        emit SetRemoved(setId);
    }

    function addToSet(uint256 setId, uint256[] memory nftIds, uint256[] memory amounts) public onlyGovernance {
        require(amounts.length == nftIds.length, "arrays do not match");

        Set storage set = sets[setId];
        require(set.kind != SetKind.Unknown, "unknown set");

        uint256 length = nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            set.items.push(SetItem({
                nftId: nftIds[i],
                amountLeft: amounts[i]
            }));
        }

        emit NftAdded(setId, nftIds, amounts);
    }

    function createSet(uint256 price, SetKind kind) public onlyGovernance {
        require(kind == SetKind.Random || kind == SetKind.Redeemable, "incorrect kind");

        uint256 setId = lastSetId.add(1);
        lastSetId = setId;

        Set storage set = sets[setId];
        set.price = price;
        set.kind = kind;

        emit SetAdded(setId, kind, price);
    }

    // Mint 1 random nft from set
    function openSetFor(address user, uint256 setId) public {
        Set storage set = sets[setId];
        require(set.kind == SetKind.Random, "kind incorrect");

        uint256 totalItems = set.items.length;
        require(totalItems > 0, "no items");

        uint256 price = set.price;
        require(
            lantti.balanceOf(msg.sender) >= price,
            "not enough LANTTI to redeem nft"
        );

        uint256 nextIndex = nextRandom(user) % totalItems;

        SetItem memory item = set.items[nextIndex];
        
        require(item.amountLeft > 0, "not enough items"); // should never revert here!

        uint256 nftId = item.nftId;
        require(
            nft.totalSupply(nftId).add(1) <= nft.maxSupply(nftId),
            "max nfts minted"
        );

        item.amountLeft = item.amountLeft.sub(1);

        if (item.amountLeft == 0) {
            // delete item
            set.items[nextIndex] = set.items[totalItems - 1];
            set.items.pop();
        } else {
            set.items[nextIndex].amountLeft = item.amountLeft;
        }

        lantti.burn(msg.sender, price);

        if (nft.isNonFungible(nftId)) {
            nft.mintNft(user, nftId, "");
        } else {
            nft.mintFt(user, nftId, 1, "");
        }
        
        emit NftRedeemed(user, setId, nftId, price);
    }

    function nextRandom(address user) private returns(uint256) {
        uint256 seed = seeds[user];
        if (seed == 0) {
            // initialize seed
            seed = uint256(keccak256(abi.encodePacked(user, block.timestamp)));
        }

        uint256 nextSeed = uint256(keccak256(abi.encodePacked(seed, block.timestamp)));

        seeds[user] = nextSeed;

        return nextSeed;
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
            interfaceID == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    function scheduleUpgrade(address impl) public onlyGovernance {
        _setNextImplementation(impl);
        _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
    }

    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0 &&
                block.timestamp > nextImplementationTimestamp() &&
                nextImplementation() != address(0),
            nextImplementation()
        );
    }

    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }
}

pragma solidity 0.6.12;

import "./BEP20.sol";
import "../Governable.sol";
import "../lib/MinterRole.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

contract Lantti is MinterRole, BEP20, Governable {
  using SafeMath for uint256;

  constructor(address _storage)
        public
        BEP20("LANTTI", "LANTTI")
        Governable(_storage)
    {
      renounceOwnership();

      address gov = governance();
      if (!isMinter(gov)) {
        _addMinter(gov);
      }
    }  

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyMinter {
      _burn(account, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
      revert("disabled");
    }
}

pragma solidity 0.6.12;

import "../token/ERC1155.sol";

contract VaultyNft is ERC1155Mintable {
    string private _contractURI;

    constructor(address _proxyRegistryAddress) public ERC1155Mintable("Vaulty NFT", "VaultyNFT", _proxyRegistryAddress) {
        _setBaseMetadataURI("https://api.vaulty.finance/nft/");
    }
    
    /**
         * @dev Ends minting of token
         * @param _id          Token ID for which minting will end
         */
    function endMinting(uint256 _id) external onlyWhitelistAdmin {
        tokenMaxSupply[_id] = tokenSupply[_id];
    }

    function burnFt(address _account, uint256 _id, uint256 _amount) public onlyMinter {
        _burnFungible(_account, _id, _amount);
    }

    function burnNft(address _account, uint256 _id) public onlyMinter {
        _burnNonFungible(_account, _id);
    }

    function airdropFt(uint256 _id, address[] memory _addresses) public onlyMinter {
        require(tokenMaxSupply[_id] - tokenSupply[_id] >= _addresses.length, "cannot mint above max supply");
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintFt(_addresses[i], _id, 1, "");
        }
    }

    function airdropNft(uint256 _type, address[] memory _addresses) public onlyMinter {
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintNft(_addresses[i], _type, "");
        }
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract BaseProxyStorage is Initializable {
  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0xd2e419928330bff46341e233ce76acced45e2a4d72eca0da439ceaad8a810424;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0xcc513a9d9a86885d0dcbd3c0ba0e09e91c988d066a2c3099cb0f0f4104ea0797;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0xc30f2f65a1117bd1d1a12244675384902c0891a5bfbe53e738e28acfb09c8cb0;


  constructor() public {
    assert(_NEXT_IMPLEMENTATION_SLOT == keccak256("eip1967.proxyStorage.nextImplementation"));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == keccak256("eip1967.proxyStorage.nextImplementationTimestamp"));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == keccak256("eip1967.proxyStorage.nextImplementationDelay"));
  }

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  uint256[100] private ______gap;
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol";

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    // function mint(uint256 amount) public virtual onlyOwner returns (bool) {
    //     _mint(_msgSender(), amount);
    //     return true;
    // }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "./Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "not minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

pragma solidity 0.6.12;

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
        require(!has(role, account), "roles: account already has requested role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "roles: account does not have needed role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol";
import "./IERC165.sol";
import "./IERC1155TokenReceiver.sol";
import "../lib/MinterRole.sol";
import "../lib/WhitelistAdminRole.sol";
import "../lib/Strings.sol";
import "./ProxyRegistry.sol";

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC165 {
    using SafeMath for uint256;
    using Address for address;

    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 internal constant TYPE_MASK = uint256(uint128(~0)) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 internal constant NF_INDEX_MASK = uint128(~0);

    uint256 internal constant TYPE_NF_BIT = 1 << 255;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // onReceive function signatures
    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    // Objects balances
    mapping(address => mapping(uint256 => uint256)) internal balances;

    mapping(uint256 => address) public nfOwners;

    // Operator Functions
    mapping(address => mapping(address => bool)) internal operators;

    // Events
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _uri, uint256 indexed _id);

    function getNonFungibleIndex(uint256 _id) public pure returns (uint256) {
        return _id & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _id) public pure returns (uint256) {
        return _id & TYPE_MASK;
    }

    function ownerOf(uint256 _id) public view returns (address) {
        return nfOwners[_id];
    }

    function isNonFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    /***********************************|
    |     Public Transfer Functions     |
    |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "erc1155#safetransferfrom: INVALID_OPERATOR"
        );
        require(_to != address(0), "erc1155#safetransferfrom: INVALID_RECIPIENT");
        // require(_amount >= balances[_from][_id]) is not necessary since checked with safemath operations

        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, _data);
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public {
        // Requirements
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "erc1155#safebatchtransferfrom: INVALID_OPERATOR"
        );
        require(_to != address(0), "erc1155#safebatchtransferfrom: INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
    }

    /***********************************|
    |    Internal Transfer Functions    |
    |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal {
        // Update balances
        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from, "erc1155#_safeTransferFrom: NOT OWNER");
            nfOwners[_id] = _to;
        } else {
            balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
            balances[_to][_id] = balances[_to][_id].add(_amount); // Add amount
        }

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
     */
    function _callonERC1155Received(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Check if recipient is contract
        if (_to.isContract()) {
            bytes4 retval =
                IERC1155TokenReceiver(_to).onERC1155Received(
                    msg.sender,
                    _from,
                    _id,
                    _amount,
                    _data
                );
            require(
                retval == ERC1155_RECEIVED_VALUE,
                "erc1155#_callonerc1155received: INVALID_ON_RECEIVE_MESSAGE"
            );
        }
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     */
    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal {
        require(
            _ids.length == _amounts.length,
            "erc1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH"
        );

        // Number of transfer to execute
        uint256 nTransfer = _ids.length;

        // Executing all transfers
        for (uint256 i = 0; i < nTransfer; i++) {
            uint256 id = _ids[i];

            if (isNonFungible(id)) {
                require(nfOwners[id] == _from, "erc1155#_safeBatchTransferFrom: NOT OWNER");
                nfOwners[id] = _to;
            } else {
                // Update storage balance of previous bin
                balances[_from][id] = balances[_from][id].sub(_amounts[i]);
                balances[_to][id] = balances[_to][id].add(_amounts[i]);
            }
        }

        // Emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
     */
    function _callonERC1155BatchReceived(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        // Pass data if recipient is contract
        if (_to.isContract()) {
            bytes4 retval =
                IERC1155TokenReceiver(_to).onERC1155BatchReceived(
                    msg.sender,
                    _from,
                    _ids,
                    _amounts,
                    _data
                );
            require(
                retval == ERC1155_BATCH_RECEIVED_VALUE,
                "erc1155#_callonerc1155batchreceived: INVALID_ON_RECEIVE_MESSAGE"
            );
        }
    }

    /***********************************|
    |         Operator Functions        |
    |__________________________________*/

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        // Update operator status
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return isOperator True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }

    /***********************************|
    |         Balance Functions         |
    |__________________________________*/

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) public view returns (uint256) {
        return balances[_owner][_id];
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
        public
        view
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length, "erc1155#balanceofbatch: INVALID_ARRAY_LENGTH");

        // Variables
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < _owners.length; i++) {
            batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }

    /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/

    /**
     * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /**
     * INTERFACE_SIGNATURE_ERC1155 =
     * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
     * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
     * bytes4(keccak256("balanceOf(address,uint256)")) ^
     * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
     * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
     * bytes4(keccak256("isApprovedForAll(address,address)"));
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceID  The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `_interfaceID` and
     */
    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        if (
            _interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155
        ) {
            return true;
        }
        return false;
    }
}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {
    using Strings for uint256;

    // URI's default URI prefix
    string internal baseMetadataURI;
    event URI(string _uri, uint256 indexed _id);

    /***********************************|
    |     Metadata Public Function s    |
    |__________________________________*/

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     *      Token IDs are assumed to be represented in their hex format in URIs
     * @return URI string
     */
    function uri(uint256 _id) public view virtual returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, _id.uint2str()));
    }

    /***********************************|
    |    Metadata Internal Functions    |
    |__________________________________*/

    /**
     * @notice Will emit default URI log event for corresponding token _id
     * @param _tokenIDs Array of IDs of tokens to log default URI
     */
    function _logURIs(uint256[] memory _tokenIDs) internal {
        string memory baseURL = baseMetadataURI;
        string memory tokenURI;

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            tokenURI = string(abi.encodePacked(baseURL, _tokenIDs[i].uint2str()));
            emit URI(tokenURI, _tokenIDs[i]);
        }
    }

    /**
     * @notice Will emit a specific URI log event for corresponding token
     * @param _tokenIDs IDs of the token corresponding to the _uris logged
     * @param _URIs    The URIs of the specified _tokenIDs
     */
    function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
        require(
            _tokenIDs.length == _URIs.length,
            "erc1155metadata#_loguris: INVALID_ARRAYS_LENGTH"
        );
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            emit URI(_URIs[i], _tokenIDs[i]);
        }
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
        baseMetadataURI = _newBaseMetadataURI;
    }
}

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
    mapping(uint256 => uint256) maxIndex;

    /****************************************|
    |            Minting Functions           |
    |_______________________________________*/

    /**
     * @notice Mint _amount of tokens of a given id
     * @param _to      The address to mint tokens to
     * @param _id      Token id to mint
     * @param _amount  The amount to be minted
     * @param _data    Data to pass if receiver is contract
     */
    function _mintFungible(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Add _amount
        balances[_to][_id] = balances[_to][_id].add(_amount);

        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
    }

    function _mintNonFungible(
        address _to,
        uint256 _type,
        bytes memory _data
    ) internal returns (uint256) {
        require(isNonFungible(_type), "not nft");

        uint256 index = maxIndex[_type] + 1;
        maxIndex[_type] = index;

        uint256 _id = _type | index;

        nfOwners[_id] = _to;

        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, 1);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(address(0x0), _to, _id, 1, _data);

        return _id;
    }

    /****************************************|
    |            Burning Functions           |
    |_______________________________________*/

    /**
     * @notice Burn _amount of tokens of a given token id
     * @param _from    The address to burn tokens from
     * @param _id      Token id to burn
     * @param _amount  The amount to be burned
     */
    function _burnFungible(
        address _from,
        uint256 _id,
        uint256 _amount
    ) internal {
        //Substract _amount
        balances[_from][_id] = balances[_from][_id].sub(_amount);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
    }

    function _burnNonFungible(address _from, uint256 _id) internal {
        require(nfOwners[_id] == _from);

        nfOwners[_id] = address(0x0);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, 1);
    }
}

/**
 * @title ERC1155Mintable
 * ERC1155Mintable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Mintable is
    ERC1155,
    ERC1155MintBurn,
    ERC1155Metadata,
    Ownable,
    MinterRole,
    WhitelistAdminRole
{
    using Strings for string;

    address proxyRegistryAddress;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyWhitelistAdmin {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @return tokenId The newly created token ID
     */
    function create(
        uint256 _type,
        uint256 _maxSupply,
        uint256 _initialSupply,
        bool isNft,
        string calldata _uri,
        bytes calldata _data
    ) external onlyWhitelistAdmin returns (uint256 tokenId) {
        if (isNft) {
            _type <<= 128;
            _type |= TYPE_NF_BIT;
        }

        require(tokenMaxSupply[_type] == 0, "type exists");
        require(_initialSupply <= _maxSupply, "initial supply cannot be more than max supply");
        require(_maxSupply != 0, "incorrect max supply");

        if (bytes(_uri).length != 0) {
            emit URI(_uri, _type);
        }

        if (_initialSupply != 0) {
            if (isNft) {
                for (uint256 i = 0; i < _initialSupply; ++i) {
                    _mintNonFungible(msg.sender, _type, _data);
                }
            } else {
                _mintFungible(msg.sender, _type, _initialSupply, _data);
            }

            tokenSupply[_type] = _initialSupply;
        }

        tokenMaxSupply[_type] = _maxSupply;
        return _type;
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mintFt(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public onlyMinter {
        uint256 tokenId = _id;

        uint256 newSupply = tokenSupply[tokenId].add(_quantity);
        require(newSupply <= tokenMaxSupply[tokenId], "max supply has reached");

        _mintFungible(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function mintNft(
        address _to,
        uint256 _type,
        bytes memory _data
    ) public onlyMinter returns (uint256) {
        uint256 newSupply = tokenSupply[_type].add(1);
        require(newSupply <= tokenMaxSupply[_type], "max supply has reached");

        uint256 id = _mintNonFungible(_to, _type, _data);
        tokenSupply[_type]++;
        return id;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return tokenMaxSupply[_id] != 0;
    }
}

pragma solidity 0.6.12;

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    virtual
    external
    view
    returns (bool);
}

pragma solidity 0.6.12;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) virtual external returns(bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) virtual external returns(bytes4);

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) virtual external view returns (bool);

}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "not admin");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

pragma solidity 0.6.12;

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity 0.6.12;

import "../Governable.sol";

contract ProxyRegistry is Governable {
  mapping(address => address) public proxies;

  constructor(address _storage) public Governable(_storage) {}

  function addOperator(address _owner, address _operator) public onlyGovernance {
    proxies[_owner] = _operator;
  }

  function removeOperator(address _owner) public onlyGovernance {
    delete proxies[_owner];
  }
}

pragma solidity 0.6.12;

import "../Governable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "../token/Lantti.sol";
import "./VaultyNft.sol";
import "./LanttiPools.sol";
import "./INftHub.sol";
import "../interfaces/IUpgradeSource.sol";
import "../ControllableInit.sol";
import "../upgradability/BaseProxyStorage.sol";

/**
 * @dev Contract for handling the NFT staking and set creation.
 */
contract NftHub is ControllableInit, BaseProxyStorage, IUpgradeSource, INftHub {
    using SafeMath for uint256;

    uint256 constant BONUS_PRECISION = 10**5;
    uint256 internal constant TYPE_MASK = uint256(uint128(~0)) << 128;

    event Stake(address indexed user, uint256[] nftIds);
    event Unstake(address indexed user, uint256[] nftIds);
    event Harvest(address indexed user, uint256 amount);

    struct NftSet {
        uint256[] nftIds;
        uint256 lanttiPerDayPerNft;
        uint256 bonusLanttiMultiplier;
        uint256[] poolBoosts; // Applicable if isBooster is true.Eg: [0,20000] = 0% boost for pool 1, 20% boost for pool 2
        uint256 bonusFullSetBoost; // Gives an additional boost if you stake all boosters of that set.
        bool isRemoved;
        bool isBooster; // False if the nft set doesn't give pool boost at lanttiPools
    }

    VaultyNft public nft;
    Lantti public lantti;
    LanttiPools public lanttiPools;

    uint256[] public nftSetList;
    //SetId mapped to all nft IDs in the set.
    mapping(uint256 => NftSet) public nftSets;
    //NftId to SetId mapping
    mapping(uint256 => uint256) public nftToSetId;
    mapping(uint256 => uint256) public maxNftStake;
    //Status of user's nfts staked mapped to the nftID
    mapping(address => mapping(uint256 => uint256)) public userNfts;
    //Last update time for a user's LANTTI rewards calculation
    mapping(address => uint256) public userLastUpdate;
    //Mapping data of booster of a user in a pool. 100% booster
    mapping(address => uint256) public boosterInfo;

    constructor() public {}

    function initialize(
        address _storage,
        VaultyNft _nft,
        Lantti _lantti
    ) public initializer {
        ControllableInit.initialize(_storage);

        nft = _nft;
        lantti = _lantti;
    }

    function setLanttiPools(LanttiPools _lanttiPools) public onlyGovernance {
        lanttiPools = _lanttiPools;
    }

    function setMultiplierOfAddress(address _address, uint256 _booster) public onlyGovernance {
        boosterInfo[_address] = _booster;
    }

    /**
     * @dev Utility function to check if a value is inside an array
     */
    function _isInArray(uint256 _value, uint256[] storage _array) internal view returns (bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Indexed boolean for whether a nft is staked or not. Index represents the nftId.
     */
    // function getNftsStakedOfAddress(address _user) public view returns (bool[] memory) {
    //     bool[] memory nftsStaked = new bool[](highestNftId + 1);
    //     for (uint256 i = 0; i < highestNftId + 1; ++i) {
    //         nftsStaked[i] = userNfts[_user][i];
    //     }
    //     return nftsStaked;
    // }

    /**
     * @dev Returns the list of nftIds which are part of a set
     */
    function getNftIdListOfSet(uint256 _setId) external view returns (uint256[] memory) {
        return nftSets[_setId].nftIds;
    }

    /**
     * @dev Returns the boosters associated with a nft Id per pool
     */
    function getBoostersOfNft(uint256 _nftId) external view returns (uint256[] memory) {
        return nftSets[nftToSetId[_nftId]].poolBoosts;
    }

    /**
     * @dev Indexed  boolean of each setId for which a user has a full set or not.
     */
    function getFullSetsOfAddress(address _user) public view returns (bool[] memory) {
        uint256 length = nftSetList.length;
        bool[] memory isFullSet = new bool[](length);
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = nftSetList[i];
            if (nftSets[setId].isRemoved) {
                isFullSet[i] = false;
                continue;
            }
            bool _fullSet = true;
            uint256[] memory _nftIds = nftSets[setId].nftIds;

            for (uint256 j = 0; j < _nftIds.length; ++j) {
                if (userNfts[_user][_nftIds[j]] == 0) {
                    _fullSet = false;
                    break;
                }
            }
            isFullSet[i] = _fullSet;
        }
        return isFullSet;
    }

    /**
     * @dev Returns the amount of NFTs staked by an address for a given set
     */
    function getNumOfNftsStakedForSet(address _user, uint256 _setId) public view returns (uint256) {
        uint256 nbStaked = 0;
        NftSet storage set = nftSets[_setId];
        if (set.isRemoved) {
            return 0;
        }

        uint256 length = set.nftIds.length;
        for (uint256 j = 0; j < length; ++j) {
            uint256 nftId = set.nftIds[j];
            if (userNfts[_user][nftId] != 0) {
                nbStaked = nbStaked.add(1);
            }
        }
        return nbStaked;
    }

    /**
     * @dev Returns the total amount of NFTs staked by an address across all sets
     */
    function getNumOfNftsStakedByAddress(address _user) public view returns (uint256) {
        uint256 nbStaked = 0;
        for (uint256 i = 0; i < nftSetList.length; ++i) {
            nbStaked = nbStaked.add(getNumOfNftsStakedForSet(_user, nftSetList[i]));
        }
        return nbStaked;
    }

    /**
     * @dev Returns the total lantti pending for a given address. Can include the bonus from NFT boosters,
     * if second param is set to true.
     */
    function totalPendingLanttiOfAddress(address _user, bool _includeLanttiBooster)
        public
        view
        returns (uint256)
    {
        uint256 totalLanttiPerDay = 0;
        uint256 length = nftSetList.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = nftSetList[i];

            NftSet storage set = nftSets[setId];
            if (set.isRemoved) {
                continue;
            }

            uint256 nftLength = set.nftIds.length;
            bool isFullSet = true;
            uint256 setLanttiPerDay = 0;

            for (uint256 j = 0; j < nftLength; ++j) {
                uint256 nftsStaked = userNfts[_user][set.nftIds[j]];
                if (nftsStaked == 0) {
                    isFullSet = false;
                    continue;
                }
                setLanttiPerDay = setLanttiPerDay.add(set.lanttiPerDayPerNft.mul(nftsStaked));
            }

            if (isFullSet) {
                setLanttiPerDay = setLanttiPerDay
                    .mul(set.bonusLanttiMultiplier.add(BONUS_PRECISION))
                    .div(BONUS_PRECISION);
            }

            totalLanttiPerDay = totalLanttiPerDay.add(setLanttiPerDay);
        }

        if (_includeLanttiBooster) {
            uint256 boostMult = boosterInfo[_user].add(BONUS_PRECISION);
            totalLanttiPerDay = totalLanttiPerDay.mul(boostMult).div(BONUS_PRECISION);
        }

        uint256 lastUpdate = userLastUpdate[_user];
        uint256 blockTime = block.timestamp;

        return blockTime.sub(lastUpdate).mul(totalLanttiPerDay.div(24 hours));
    }

    /**
     * @dev Returns the applicable booster of a user, for a pool, from a staked NFT set.
     */
    function getBoosterForUser(address _user, uint256 _pid)
        external
        view
        override
        returns (uint256)
    {
        _pid = _pid.sub(1);

        uint256 totalBooster = 0;
        uint256 length = nftSetList.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 setId = nftSetList[i];
            NftSet storage set = nftSets[setId];
            if (!set.isBooster) {
                continue;
            }

            if (set.poolBoosts.length < _pid.add(1)) {
                continue;
            }

            if (set.poolBoosts[_pid] == 0) {
                continue;
            }

            uint256 nftLength = set.nftIds.length;
            bool isFullSet = true;
            uint256 setBooster = 0;

            for (uint256 j = 0; j < nftLength; ++j) {
                uint256 nftsStaked = userNfts[_user][set.nftIds[j]];
                if (nftsStaked == 0) {
                    isFullSet = false;
                    continue;
                }

                setBooster = setBooster.add(set.poolBoosts[_pid].mul(maxNftStake[nftsStaked]));
            }

            if (isFullSet) {
                setBooster = setBooster.add(set.bonusFullSetBoost);
            }

            totalBooster = totalBooster.add(setBooster);
        }
        return totalBooster;
    }

    /**
     * @dev Manually sets the highestNftId, if it goes out of sync.
     * Required calculate the range for iterating the list of staked nfts for an address.
     */
    // function setHighestNftId(uint256 _highestId) public onlyGovernance {
    //     require(_highestId > 0, "Set if minimum 1 nft is staked.");
    //     highestNftId = _highestId;
    // }

    /**
     * @dev Adds a nft set with the input param configs. Removes an existing set if the id exists.
     */
    function addNftSet(
        uint256 _setId,
        uint256[] memory _nftIds,
        uint256[] memory _max,
        uint256 _bonusLanttiMultiplier,
        uint256 _lanttiPerDayPerNft,
        uint256[] memory _poolBoosts,
        uint256 _bonusFullSetBoost,
        bool _isBooster
    ) public onlyGovernance {
        require(_nftIds.length == _max.length);

        removeNftSet(_setId);
        uint256 length = _nftIds.length;

        for (uint256 i = 0; i < length; ++i) {
            uint256 nftId = _nftIds[i];

            // Check all nfts to assign arent already part of another set
            require(nftToSetId[nftId] == 0, "Nft already assigned to a set");
            // Assign to set
            nftToSetId[nftId] = _setId;
            maxNftStake[nftId] = _max[i];
        }

        if (!_isInArray(_setId, nftSetList)) {
            nftSetList.push(_setId);
        }

        nftSets[_setId] = NftSet({
            nftIds: _nftIds,
            bonusLanttiMultiplier: _bonusLanttiMultiplier,
            lanttiPerDayPerNft: _lanttiPerDayPerNft,
            poolBoosts: _poolBoosts,
            bonusFullSetBoost: _bonusFullSetBoost,
            isRemoved: false,
            isBooster: _isBooster
        });
    }

    /**
     * @dev Updates the lanttiPerDayPerNft for a nft set.
     */
    function setLanttiRateOfSets(uint256[] memory _setIds, uint256[] memory _lanttiPerDayPerNft)
        public
        onlyGovernance
    {
        require(
            _setIds.length == _lanttiPerDayPerNft.length,
            "_setId and _lanttiPerDayPerNft have different length"
        );

        for (uint256 i = 0; i < _setIds.length; ++i) {
            require(nftSets[_setIds[i]].nftIds.length > 0, "Set is empty");
            nftSets[_setIds[i]].lanttiPerDayPerNft = _lanttiPerDayPerNft[i];
        }
    }

    /**
     * @dev Set the bonusLanttiMultiplier value for a list of Nft sets
     */
    function setBonusLanttiMultiplierOfSets(
        uint256[] memory _setIds,
        uint256[] memory _bonusLanttiMultiplier
    ) public onlyGovernance {
        require(
            _setIds.length == _bonusLanttiMultiplier.length,
            "_setId and _lanttiPerDayPerNft have different length"
        );
        for (uint256 i = 0; i < _setIds.length; ++i) {
            require(nftSets[_setIds[i]].nftIds.length > 0, "Set is empty");
            nftSets[_setIds[i]].bonusLanttiMultiplier = _bonusLanttiMultiplier[i];
        }
    }

    /**
     * @dev Remove a nftSet that has been added.
     * !!!  Warning : if a booster set is removed, users with the booster staked will continue to benefit from the multiplier  !!!
     */
    function removeNftSet(uint256 _setId) public onlyGovernance {
        uint256 length = nftSets[_setId].nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 nftId = nftSets[_setId].nftIds[i];
            nftToSetId[nftId] = 0;
        }
        delete nftSets[_setId].nftIds;
        nftSets[_setId].isRemoved = true;
        nftSets[_setId].isBooster = false;
    }

    /**
     * @dev Harvests the accumulated LANTTI in the contract, for the caller.
     */
    function harvest() public {
        uint256 pendingLantti = totalPendingLanttiOfAddress(msg.sender, true);
        userLastUpdate[msg.sender] = block.timestamp;
        if (pendingLantti > 0) {
            lantti.mint(msg.sender, pendingLantti);
        }
        emit Harvest(msg.sender, pendingLantti);
    }

    /**
     * @dev Stakes the nfts on providing the nft IDs.
     */
    function stake(uint256[] memory _nftIds) public {
        stakeAction(_nftIds, true);
    }

    /**
     * @dev Unstakes the nfts on providing the nft IDs.
     */
    function unstake(uint256[] memory _nftIds) public {
        stakeAction(_nftIds, false);
    }

    function stakeAction(uint256[] memory _nftIds, bool stake) private {
        require(_nftIds.length > 0, "you need to stake something");

        // Check no nft will end up above max stake and if it is needed to update the user NFT pool
        uint256 length = _nftIds.length;
        bool hasLanttis = false;
        bool onlyNoBoosters = true;
        uint256 setId;
        uint256 nftType;
        NftSet storage nftSet;

        for (uint256 i = 0; i < length; ++i) {
            nftType = extractType(_nftIds[i]);
            setId = nftToSetId[nftType];

            require(setId != 0, "unknown set");

            if (stake) {
                require(userNfts[msg.sender][nftType] <= maxNftStake[nftType], "max staked");
                userNfts[msg.sender][nftType]++;
            } else {
                require(userNfts[msg.sender][nftType] != 0, "not staked");
                userNfts[msg.sender][nftType]--;
            }

            if (nftSets[setId].lanttiPerDayPerNft > 0) {
                hasLanttis = true;
            }

            if (nftSets[setId].isBooster) {
                onlyNoBoosters = false;
            }
        }

        // Harvest NFT pool if the LANTTI/day will be modified
        if (hasLanttis) {
            harvest();
        }

        // Harvest each pool where booster value will be modified
        if (!onlyNoBoosters) {
            for (uint256 i = 0; i < length; ++i) {
                nftType = extractType(_nftIds[i]);
                setId = nftToSetId[nftType];

                if (nftSets[setId].isBooster) {
                    nftSet = nftSets[setId];
                    uint256 boostLength = nftSet.poolBoosts.length;
                    for (uint256 j = 1; j <= boostLength; ++j) {
                        // pool ID starts from 1
                        if (
                            nftSet.poolBoosts[j - 1] > 0 &&
                            lanttiPools.pendingLantti(j, msg.sender) > 0
                        ) {
                            address staker = msg.sender;
                            lanttiPools.withdraw(j, 0, staker);
                        }
                    }
                }
            }
        }

        //Stake 1 unit of each nftId
        uint256[] memory amounts = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            amounts[i] = 1;
        }

        if (stake) {
            nft.safeBatchTransferFrom(msg.sender, address(this), _nftIds, amounts, "");
            emit Stake(msg.sender, _nftIds);
        } else {
            nft.safeBatchTransferFrom(address(this), msg.sender, _nftIds, amounts, "");
            emit Unstake(msg.sender, _nftIds);
        }
    }

    /**
     * @dev Emergency unstake the nfts on providing the nft IDs, forfeiting the LANTTI rewards in both Hub and LanttiPools.
     */
    function emergencyUnstake(uint256[] memory _nftIds) public {
        userLastUpdate[msg.sender] = block.timestamp;

        uint256[] memory amounts = new uint256[](_nftIds.length);
        uint256 length = _nftIds.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 nftType = extractType(_nftIds[i]);

            uint256 nftsStaked = userNfts[msg.sender][nftType];
            require(nftsStaked != 0, "Nft not staked");

            amounts[i] = 1;
            userNfts[msg.sender][nftType]--;
        }

        nft.safeBatchTransferFrom(address(this), msg.sender, _nftIds, amounts, "");
    }

    // update pot address if the pot logic changed.
    function updateLanttiPoolsAddress(LanttiPools _pools) public onlyGovernance {
        lanttiPools = _pools;
    }

    function extractType(uint256 nftId) private pure returns (uint256) {
        return nftId & TYPE_MASK;
    }

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0xf23a6e61;
    }

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0xbc197c81;
    }

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
            interfaceID == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    function scheduleUpgrade(address impl) public onlyGovernance {
        _setNextImplementation(impl);
        _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
    }

    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0 &&
                block.timestamp > nextImplementationTimestamp() &&
                nextImplementation() != address(0),
            nextImplementation()
        );
    }

    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }
}

pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "../Governable.sol";
import "../token/Lantti.sol";
import "./INftHub.sol";
import "../interfaces/IUpgradeSource.sol";
import "../ControllableInit.sol";
import "../upgradability/BaseProxyStorage.sol";

contract LanttiPools is ControllableInit, BaseProxyStorage, IUpgradeSource {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 public constant BONUS_PRECISION = 10**5;
    uint256 public constant REWARD_PRECISION = 10**12;

    // info of each user.
    struct UserInfo {
        uint256 amount; // how many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // we do some fancy math here. basically, any point in time, the amount of LANTTI
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accLanttiPerShare) - user.rewardDebt
        //
        // whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. user's pending reward is minted to his/her address.
        //   2. user's `amount` gets updated.
        //   3. user's `lastUpdate` gets updated.
    }

    // info of each pool.
    struct PoolInfo {
        IBEP20 token; // address of token contract.
        uint256 lanttiPerDay; // the amount of LANTTI per day generated for each token staked
        uint256 maxStake; // the maximum amount of tokens which can be staked in this pool
        uint256 lastUpdateTime; // last timestamp that LANTTI distribution occurs.
        uint256 accLanttiPerShare; // accumulated LANTTI per share. See below.
    }

    // info of each pool.
    PoolInfo[] public poolInfo;
    // info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // record whether the pair has been added.
    mapping(address => uint256) public tokenPID;

    Lantti public lantti;
    INftHub public hub;
    uint256 public rewardsUnit;

    event PoolCreated(address indexed token, uint256 pid);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() public {}

    function initialize(
        address _storage,
        Lantti _lantti,
        INftHub _hub
    ) public initializer {
        ControllableInit.initialize(_storage);

        lantti = _lantti;
        hub = _hub;

        uint256 d = _lantti.decimals();
        rewardsUnit = 10**d;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // add a new token to the pool. can only be called by the owner.
    // XXX DO NOT add the same token more than once. rewards will be messed up if you do.
    function add(
        address _token,
        uint256 _lanttiPerDay,
        uint256 _maxStake
    ) public onlyGovernance {
        uint256 pid = poolInfo.length.add(1);

        require(tokenPID[_token] == 0, "duplicated pool");
        require(_token != address(lantti), "can't stake lantti");
        poolInfo.push(
            PoolInfo({
                token: IBEP20(_token),
                maxStake: _maxStake,
                lanttiPerDay: _lanttiPerDay,
                lastUpdateTime: block.timestamp,
                accLanttiPerShare: 0
            })
        );

        tokenPID[_token] = pid;

        emit PoolCreated(_token, pid);
    }

    // set a new max stake. value must be greater than previous one,
    // to not give an unfair advantage to people who already staked > new max
    function setMaxStake(uint256 pid, uint256 amount) public onlyGovernance {
        poolInfo[pid.sub(1)].maxStake = amount;
    }

    // set the amount of LANTTI generated per day for each token staked
    function setLanttiPerDay(uint256 pid, uint256 amount) public onlyGovernance {
        PoolInfo storage pool = poolInfo[pid.sub(1)];
        uint256 blockTime = block.timestamp;
        uint256 lanttiReward = blockTime.sub(pool.lastUpdateTime).mul(pool.lanttiPerDay);

        pool.accLanttiPerShare = pool.accLanttiPerShare.add(
            lanttiReward.mul(REWARD_PRECISION).div(24 hours)
        );
        pool.lastUpdateTime = block.timestamp;
        pool.lanttiPerDay = amount;
    }

    function _userPoolState(uint256 _pid, address _user)
        internal
        view
        returns (uint256 pending, uint256 accLantti)
    {
        PoolInfo storage pool = poolInfo[_pid.sub(1)];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 blockTime = block.timestamp;
        accLantti = pool.accLanttiPerShare;

        uint256 lanttiReward = blockTime.sub(pool.lastUpdateTime).mul(pool.lanttiPerDay);
        accLantti = accLantti.add(lanttiReward.mul(REWARD_PRECISION).div(24 hours));

        pending = user.amount.mul(accLantti).div(REWARD_PRECISION).sub(user.rewardDebt).div(
            rewardsUnit
        );
    }

    // view function to see pending LANTTI on a frontend.
    function pendingLantti(uint256 _pid, address _user) public view returns (uint256) {
        (uint256 pending, ) = _userPoolState(_pid, _user);
        uint256 booster = hub.getBoosterForUser(_user, _pid);
        if (booster > 0) {
            pending = pending.mul(booster.add(BONUS_PRECISION));
            pending = pending.div(BONUS_PRECISION);
        }
        return pending;
    }

    // view function to calculate the total pending LANTTI of address across all pools
    function totalPendingLantti(address _user) public view returns (uint256) {
        uint256 total = 0;
        uint256 length = poolInfo.length;
        for (uint256 pid = 1; pid <= length; ++pid) {
            total = total.add(pendingLantti(pid, _user));
        }

        return total;
    }

    // harvest pending LANTTI of a list of pools.
    // might be worth it checking in the frontend for the pool IDs with pending lantti for this address and only harvest those
    function rugPull(uint256[] memory _pids) public {
        for (uint256 i = 0; i < _pids.length; i++) {
            withdraw(_pids[i], 0, msg.sender);
        }
    }

    // deposit LP tokens to pool for LANTTI allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid.sub(1)];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 userAmount = user.amount;
        require(_amount.add(userAmount) <= pool.maxStake, "cannot stake beyond max stake value");

        (uint256 pending, uint256 accLantti) = _userPoolState(_pid, msg.sender);
        userAmount = userAmount.add(_amount);
        user.rewardDebt = userAmount.mul(accLantti).div(REWARD_PRECISION);
        user.amount = userAmount;

        uint256 booster = hub.getBoosterForUser(msg.sender, _pid).add(BONUS_PRECISION);
        uint256 pendingWithBooster = pending.mul(booster).div(BONUS_PRECISION);
        if (pendingWithBooster > 0) {
            lantti.mint(msg.sender, pendingWithBooster);
        }

        pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // withdraw tokens from pool
    // withdrawing 0 amount will harvest rewards only
    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _staker
    ) public {
        address staker = _staker;
        PoolInfo storage pool = poolInfo[_pid.sub(1)];
        UserInfo storage user = userInfo[_pid][staker];

        uint256 userAmount = user.amount;

        if (userAmount == 0) {
            // early exit, nothing was staked to this pool
            return;
        }

        require(userAmount >= _amount, "not enough amount");
        require(msg.sender == staker || _amount == 0);

        (uint256 pending, uint256 accLantti) = _userPoolState(_pid, staker);

        // in case the maxstake has been lowered and address is above maxstake, we force it to withdraw what is above current maxstake
        // user can delay his/her withdraw/harvest to take advantage of a reducing of maxstake,
        // if he/she entered the pool at maxstake before the maxstake reducing occured
        uint256 leftAfterWithdraw = userAmount.sub(_amount);
        if (leftAfterWithdraw > pool.maxStake) {
            _amount = _amount.add(leftAfterWithdraw - pool.maxStake);
        }

        userAmount = userAmount.sub(_amount);
        user.rewardDebt = userAmount.mul(accLantti).div(REWARD_PRECISION);
        user.amount = userAmount;

        uint256 booster = hub.getBoosterForUser(staker, _pid).add(BONUS_PRECISION);
        uint256 pendingWithBooster = pending.mul(booster).div(BONUS_PRECISION);
        if (pendingWithBooster > 0) {
            lantti.mint(staker, pendingWithBooster);
        }

        pool.token.safeTransfer(address(staker), _amount);
        emit Withdraw(staker, _pid, _amount);
    }

    // withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid.sub(1)];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount > 0, "not enough amount");

        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(address(msg.sender), _amount);

        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // update hub address if the booster logic changed.
    function updateNftHubAddress(INftHub _hub) public onlyGovernance {
        hub = _hub;
    }

    function scheduleUpgrade(address impl) public onlyGovernance {
        _setNextImplementation(impl);
        _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
    }

    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0 &&
                block.timestamp > nextImplementationTimestamp() &&
                nextImplementation() != address(0),
            nextImplementation()
        );
    }

    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }
}

pragma solidity 0.6.12;

interface INftHub {
  function getBoosterForUser(address _user, uint256 _pid) external view returns (uint256);
}

pragma solidity 0.6.12;

import "../interfaces/IUpgradeSource.sol";
import "./BaseUpgradeabilityProxy.sol";

contract UpgradableProxy is BaseUpgradeabilityProxy {

  constructor(address _implementation) public {
    _setImplementation(_implementation);
  }

  /**
  * The main logic. If the timer has elapsed and there is a schedule upgrade,
  * the governance can upgrade the vault
  */
  function upgrade() external {
    (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
    require(should, "Upgrade not scheduled");
    _upgradeTo(newImplementation);

    // the finalization needs to be executed on itself to update the storage of this proxy
    // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
    (bool success, bytes memory result) = address(this).delegatecall(
      abi.encodeWithSignature("finalizeUpgrade()")
    );

    require(success, "Issue when finalizing the upgrade");
  }

  function implementation() external view returns (address) {
    return _implementation();
  }
}

pragma solidity 0.6.12;

import './Proxy.sol';
import './Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

pragma solidity 0.6.12;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

pragma solidity 0.6.12;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity 0.6.12;

import "../upgradability/UpgradableProxy.sol";

contract NftMarketProxy is UpgradableProxy {
  constructor(address _implementation) public UpgradableProxy(_implementation) {
  }
}

pragma solidity 0.6.12;

import "../upgradability/UpgradableProxy.sol";

contract NftHubProxy is UpgradableProxy {
  constructor(address _implementation) public UpgradableProxy(_implementation) {
  }
}

pragma solidity 0.6.12;

import "../upgradability/UpgradableProxy.sol";

contract LanttiPoolsProxy is UpgradableProxy {
  constructor(address _implementation) public UpgradableProxy(_implementation) {
  }
}

pragma solidity 0.6.12;

import "./INftHub.sol";

contract NftHubMock is INftHub {
  uint256 public boosterValue;

  constructor(
    uint256 _boosterValue
  ) public {
    boosterValue = _boosterValue;
  }

  function getBoosterForUser(address _user, uint256 _pid) external override view returns (uint256) {
    return boosterValue;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./BEP20.sol";
import "../lib/MinterRole.sol";

contract RewardToken is
    BEP20,
    MinterRole
{
    uint256 public constant HARD_CAP = 15000000 * (10**18);

    constructor(address gov) public BEP20("Vaulty Token", "VLTY") {
        if (!isMinter(gov)) {
            _addMinter(gov);
        }
    }

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        require(totalSupply().add(amount) <= HARD_CAP, "cap exceeded");
        _mint(account, amount);
        return true;
    }
}

pragma solidity 0.6.12;

import "./Controllable.sol";
import "./NoMintRewardPool.sol";
import "./lib/WhitelistAdminRole.sol";

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

interface IFeeRewardForwarder {
    function poolNotifyFixedTarget(address _token, uint256 _amount) external;
}

contract NotifyHelper is WhitelistAdminRole, Controllable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public feeRewardForwarder;
    address public rewardToken;
    uint256 public profitShareIncentiveDaily;
    uint256 public lastProfitShareTimestamp;

    mapping(address => bool) public alreadyNotified;

    event FeeRewardForwarderChanged(address _address);

    constructor(
        address _storage,
        address _feeRewardForwarder,
        address _rewardToken
    ) public Controllable(_storage) {
        require(_feeRewardForwarder != address(0), 'pool address cannot be zero');
        feeRewardForwarder = _feeRewardForwarder;
        rewardToken = _rewardToken;
    }

    /**
     * Notifies all the pools, safe guarding the notification amount.
     */
    function notifyPools(
        uint256[] memory amounts,
        address[] memory pools
    ) public onlyWhitelistAdmin {
        require(amounts.length == pools.length, "Amounts and pools lengths mismatch");
        for (uint256 i = 0; i < pools.length; i++) {
            alreadyNotified[pools[i]] = false;
        }

        uint256 check = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            require(amounts[i] > 0, "Notify zero");
            require(!alreadyNotified[pools[i]], "Duplicate pool");
            require(pools[i] != address(0), 'pool address cannot be zero');
            
            NoMintRewardPool pool = NoMintRewardPool(pools[i]);
            IBEP20 token = IBEP20(pool.rewardToken());
            check = check.add(amounts[i]);
            alreadyNotified[pools[i]] = true;

            token.safeTransferFrom(msg.sender, pools[i], amounts[i]);
            NoMintRewardPool(pools[i]).notifyRewardAmount(amounts[i]);
        }
    }

    /**
     * Notifies all the pools, safe guarding the notification amount.
     */
    function notifyPoolsIncludingProfitShare(
        uint256[] memory amounts,
        address[] memory pools,
        uint256 profitShareIncentiveForWeek,
        uint256 firstProfitShareTimestamp,
        uint256 sum
    ) public onlyWhitelistAdmin {
        require(amounts.length == pools.length, "Amounts and pools lengths mismatch");

        profitShareIncentiveDaily = profitShareIncentiveForWeek.div(7);
        IBEP20(rewardToken).safeTransferFrom(msg.sender, address(this), profitShareIncentiveForWeek);
        lastProfitShareTimestamp = 0;
        notifyProfitSharing();
        lastProfitShareTimestamp = firstProfitShareTimestamp;

        notifyPools(amounts, pools);
    }

    function notifyProfitSharing() public {
        require(
            IBEP20(rewardToken).balanceOf(address(this)) >= profitShareIncentiveDaily,
            "Balance too low"
        );
        require(!(lastProfitShareTimestamp.add(24 hours) > block.timestamp), "Called too early");
        lastProfitShareTimestamp = lastProfitShareTimestamp.add(24 hours);

        IBEP20(rewardToken).safeIncreaseAllowance(feeRewardForwarder, profitShareIncentiveDaily);
        IFeeRewardForwarder(feeRewardForwarder).poolNotifyFixedTarget(
            rewardToken,
            profitShareIncentiveDaily
        );
    }

    function setFeeRewardForwarder(address newForwarder) public onlyGovernance {
        require(newForwarder != address(0), 'address cannot be zero');
        feeRewardForwarder = newForwarder;
        emit FeeRewardForwarderChanged(newForwarder);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Governable.sol";
import "./NoMintRewardPool.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

contract GovernaceStaking is Governable {
  uint256 public lockPeriod;
  uint256 public depositTimestamp;
  uint256 public tokensLocked;
  uint256 public tokensStaked;
  NoMintRewardPool public activePool;
  IBEP20 public token;

  constructor(address _storage, IBEP20 _token, uint256 _lockPeriod) Governable(_storage) public {
    require(_token != IBEP20(address(0)));
    lockPeriod = _lockPeriod;
    token = _token;
  }

  function depositTokens(uint256 amount) public onlyGovernance {
    depositTimestamp = block.timestamp;
    token.transferFrom(msg.sender, address(this), amount);
    tokensLocked += amount;
  }

  function withdrawTokens() public onlyGovernance {
    require(block.timestamp - depositTimestamp > lockPeriod, "too early");

    uint256 unavailableTokens = tokensStaked;
    uint256 availableTokens = tokensLocked - unavailableTokens;
    token.transfer(msg.sender, availableTokens);

    tokensLocked = unavailableTokens;
  }

  function stake(NoMintRewardPool pool, uint256 amount) public onlyGovernance {
    require(amount >= tokensLocked - tokensStaked, "not enough tokens");

    tokensStaked += amount;

    token.approve(address(pool), amount);
    pool.stake(amount);

    activePool = pool;
  }

  function unstake() public onlyGovernance {
    activePool.exit(); // unstake all tokens at once

    tokensStaked = 0;
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./interface/IFairLaunch.sol";
import "./interface/IVault.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "../../upgradability/BaseUpgradeableStrategy.sol";
import "../../interfaces/pancakeswap/IPancakeRouter02.sol";

contract AlpacaBaseStrategy is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public constant pancakeswapRouterV2 =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
    bytes32 internal constant _POOLID_SLOT =
        0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
    bytes32 internal constant _DEPOSITOR_SLOT =
        0x7e51443ed339b944018a93b758544b6d25c6c65ccaf25ffca5127da0103d7ddf;
    bytes32 internal constant _DEPOSITOR_UNDERLYING_SLOT =
        0xfffae5dac57e2313ef5a16a03f71dacc1da392f7ae9ca598779f29a0ada318c2;

    address[] public pancake_route;

    constructor() public BaseUpgradeableStrategy() {
        assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
        assert(
            _DEPOSITOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositor")) - 1)
        );
        assert(
            _DEPOSITOR_UNDERLYING_SLOT ==
                bytes32(uint256(keccak256("eip1967.strategyStorage.depositorUnderlying")) - 1)
        );
    }

    function initialize(
        address _storage,
        address _underlying, // main underlying like BNB, ETH, USDT
        address _vault,
        address _depositHelp, // lend contract where to put BNB, ETH, USDT
        address _depositorUnderlying, // ibToken which should be staked to get rewards (usually the same as _depositorHelp)
        uint256 _poolID
    ) public initializer {
        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            address(0xA625AB01B08ce023B2a342Dbb12a16f2C8489A8F), // _rewardPool ALPACA FairLaunch contract (staking contract)
            address(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F), // _rewardToken ALPACA token
            100, // profit sharing numerator
            1000, // profit sharing denominator
            true, // sell
            1e16, // sell floor
            12 hours // implementation change delay
        );

        address _lpt;
        (_lpt, , , ) = IFairLaunch(rewardPool()).poolInfo(_poolID);
        require(_lpt == _depositorUnderlying, "Pool Info does not match underlying");
        _setPoolId(_poolID);
        _setDepositor(_depositHelp);
        _setDepositorUnderlying(_depositorUnderlying);
    }

    function depositArbCheck() public pure returns (bool) {
        return true;
    }

    function rewardPoolBalance() public view returns (uint256) {
        return IFairLaunch(rewardPool()).pendingAlpaca(poolId(), address(this));
    }

    function ibTokensStaked() public view returns (uint256 bal) {
        (bal, , , ) = IFairLaunch(rewardPool()).userInfo(poolId(), address(this));
    }

    function ibTokensBalance() public view returns (uint256) {
        return IBEP20(depositorUnderlying()).balanceOf(address(this));
    }

    function ibTokensStakedInUnderlying() public view returns (uint256) {
        return ibTokensToUnderlying(ibTokensStaked());
    }

    function ibTokensBalanceInUnderlying() public view returns (uint256) {
        return ibTokensToUnderlying(ibTokensBalance());
    }

    function ibTokenPrice() internal view returns (uint256) {
        return IVault(depositor()).totalToken().div(IVault(depositor()).totalSupply());
    }

    // return how many unerlying will be for ibTokens
    function ibTokensToUnderlying(uint256 ibTokens) internal view returns (uint256) {
        return ibTokenPrice().mul(ibTokens);
    }

    // how many ibTokens will be for underlying
    function underlyingToIbTokens(uint256 val) internal view returns (uint256) {
        return val.div(ibTokenPrice());
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    /*
     *   In case there are some issues discovered about the pool or underlying asset
     *   Governance can exit the pool properly
     *   The function is only used for emergency to exit the pool
     */
    function emergencyExit() public onlyGovernance {
        IFairLaunch(rewardPool()).emergencyWithdraw(poolId());
        _setPausedInvesting(true);
    }

    /*
     *   Resumes the ability to invest into the underlying reward pools
     */
    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    function setLiquidationPath(address[] memory _route) public onlyGovernance {
        require(_route[0] == rewardToken(), "Path should start with rewardToken");
        pancake_route = _route;
    }

    // We assume that all the tradings can be done on Pancakeswap
    function _liquidateReward() internal {
        if (underlying() != rewardToken()) {
            uint256 rewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
            if (!sell() || rewardBalance < sellFloor()) {
                // Profits can be disabled for possible simplified and rapid exit
                emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
                return;
            }
            notifyProfitInRewardToken(rewardBalance);
            uint256 remainingRewardBalance = IBEP20(rewardToken()).balanceOf(address(this));
            if (remainingRewardBalance == 0) {
                return;
            }

            // allow Pancakeswap to sell our reward
            IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, 0);
            IBEP20(rewardToken()).safeApprove(pancakeswapRouterV2, remainingRewardBalance);

            // we can accept 1 as minimum because this is called only by a trusted role
            uint256 amountOutMin = 1;

            IPancakeRouter02(pancakeswapRouterV2).swapExactTokensForTokens(
                remainingRewardBalance,
                amountOutMin,
                pancake_route,
                address(this),
                block.timestamp
            );
        }
    }

    function claimAndLiquidateReward() internal {
        IFairLaunch(rewardPool()).harvest(poolId());
        _liquidateReward();
    }

    function getUnderlyingFromDepositor() internal {
        uint256 ibTokensBalance = ibTokensBalance();
        if (ibTokensBalance > 0) {
            IVault(depositor()).withdraw(ibTokensBalance);
        }
    }

    function unstakeAll() internal {
        uint256 stakedBalance = ibTokensStaked();
        if (stakedBalance > 0) {
            IFairLaunch(rewardPool()).withdraw(address(this), poolId(), stakedBalance);
        }
    }

    /*
     *   Lend everything the strategy holds and then stake into the reward pool
     */
    function investAllUnderlying() internal onlyNotPausedInvesting {
        uint256 underlyingBalance = IBEP20(underlying()).balanceOf(address(this));
        if (underlyingBalance > 0) {
            IBEP20(underlying()).safeApprove(depositor(), 0);
            IBEP20(underlying()).safeApprove(depositor(), underlyingBalance);
            IVault(depositor()).deposit(underlyingBalance);
        }

        uint256 ibTokensBalance = ibTokensBalance();

        if (ibTokensBalance > 0) {
            IBEP20(depositorUnderlying()).safeApprove(rewardPool(), 0);
            IBEP20(depositorUnderlying()).safeApprove(rewardPool(), ibTokensBalance);
            IFairLaunch(rewardPool()).deposit(address(this), poolId(), ibTokensBalance);
        }
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawAllToVault() public restricted {
        if (address(rewardPool()) != address(0)) {
            uint256 bal = rewardPoolBalance();
            if (bal != 0) {
                claimAndLiquidateReward();
            }
            unstakeAll();
        }
        getUnderlyingFromDepositor();
        IBEP20(underlying()).safeTransfer(vault(), IBEP20(underlying()).balanceOf(address(this)));
    }

    /*
     *   Withdraws amount of the asset to the vault
     */
    function withdrawToVault(uint256 amount) public restricted {
        uint256 availableBalance = IBEP20(underlying()).balanceOf(address(this));

        if (amount > availableBalance) {
            uint256 needToWithdraw = underlyingToIbTokens(amount.sub(availableBalance));
            uint256 ibTokensBalance_ = ibTokensBalance();
            if (needToWithdraw > ibTokensBalance_) {
                uint256 needToUnstake = needToWithdraw.sub(ibTokensBalance_);
                uint256 toUnstake = MathUpgradeable.min(ibTokensStaked(), needToUnstake);
                // unstaking to get new increased ibTokensBalance
                IFairLaunch(rewardPool()).withdraw(address(this), poolId(), toUnstake);
            }

            uint256 newIbTokensBalance = ibTokensBalance();
            uint256 toWithdraw = MathUpgradeable.min(
                newIbTokensBalance,
                needToWithdraw
            );
            // withdrawing ibTokens for underlying
            IVault(depositor()).withdraw(toWithdraw);
        }
        uint256 availableBalance_ = IBEP20(underlying()).balanceOf(address(this));
        IBEP20(underlying()).safeTransfer(vault(), amount);
    }

    /*
     *   Note that we currently do not have a mechanism here to include the
     *   amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool() == address(0)) {
            return IBEP20(underlying()).balanceOf(address(this)).add(ibTokensBalanceInUnderlying());
        }
        return
            IBEP20(underlying()).balanceOf(address(this)).add(ibTokensStakedInUnderlying()).add(
                ibTokensBalanceInUnderlying()
            );
    }

    /*
     *   Governance or Controller can claim coins that are somehow transferred into the contract
     *   Note that they cannot come in take away coins that are used and defined in the strategy itself
     */
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IBEP20(token).safeTransfer(recipient, amount);
    }

    /*
     *   Get the reward, sell it in exchange for underlying, invest what you got.
     *   It's not much, but it's honest work.
     *
     *   Note that although `onlyNotPausedInvesting` is not added here,
     *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
     *   when the investing is being paused by governance.
     */
    function doHardWork() external onlyNotPausedInvesting restricted {
        uint256 bal = rewardPoolBalance();
        if (bal != 0) {
            claimAndLiquidateReward();
        }
        investAllUnderlying();
    }

    /**
     * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
     * simplest possible way.
     */
    function setSell(bool s) public onlyGovernance {
        _setSell(s);
    }

    /**
     * Sets the minimum amount needed to trigger a sale.
     */
    function setSellFloor(uint256 floor) public onlyGovernance {
        _setSellFloor(floor);
    }

    // rewards pool ID
    function _setPoolId(uint256 _value) internal {
        setUint256(_POOLID_SLOT, _value);
    }

    function poolId() public view returns (uint256) {
        return getUint256(_POOLID_SLOT);
    }

    function _setDepositor(address _address) internal {
        setAddress(_DEPOSITOR_SLOT, _address);
    }

    function depositor() public view virtual returns (address) {
        return getAddress(_DEPOSITOR_SLOT);
    }

    function _setDepositorUnderlying(address _address) internal {
        setAddress(_DEPOSITOR_UNDERLYING_SLOT, _address);
    }

    function depositorUnderlying() public view virtual returns (address) {
        return getAddress(_DEPOSITOR_UNDERLYING_SLOT);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IFairLaunch {
    function poolLength() external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt, uint256 bonusDebt, address fundedBy);
    function poolInfo(uint256 _pid) external view returns (address stakeToken, uint256, uint256, uint256);

    function addPool(
        uint256 _allocPoint,
        address _stakeToken,
        bool _withUpdate
    ) external;

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);

    function updatePool(uint256 _pid) external;

    function deposit(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdrawAll(address _for, uint256 _pid) external;

    function harvest(uint256 _pid) external;

    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVault {

  /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  /// @dev Add more ERC20 to the bank. Hope to get some good returns.
  function deposit(uint256 amountToken) external payable;

  /// @dev Withdraw ERC20 from the bank by burning the share tokens.
  function withdraw(uint256 share) external;

  /// @dev Request funds from user through Vault
  function requestFunds(address targetedToken, uint amount) external;

  function debtShareToVal(uint256 debtShare) external view returns (uint256);

  function debtValToShare(uint256 debtVal) external view returns (uint256);

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./AlpacaBaseStrategy.sol";

contract AlpacaUSDTStrategy is AlpacaBaseStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x55d398326f99059fF775485246999027B3197955);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address alpaca = address(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    address ibToken = address(0x158Da805682BdC8ee32d52833aD41E74bb951E59); // underlying and depositor help contract at once
    AlpacaBaseStrategy.initialize(
      _storage,
      underlying,
      _vault,
      ibToken,
      ibToken,
      16
    );
    pancake_route = [alpaca, wbnb, underlying];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./AlpacaBaseStrategy.sol";

contract AlpacaTUSDStrategy is AlpacaBaseStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x14016E85a25aeb13065688cAFB43044C2ef86784);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address alpaca = address(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    address ibToken = address(0x3282d2a151ca00BfE7ed17Aa16E42880248CD3Cd); // underlying and depositor help contract at once
    AlpacaBaseStrategy.initialize(
      _storage,
      underlying,
      _vault,
      ibToken,
      ibToken,
      20
    );
    pancake_route = [alpaca, wbnb, underlying];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./AlpacaBaseStrategy.sol";

contract AlpacaETHStrategy is AlpacaBaseStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address alpaca = address(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    address ibToken = address(0xbfF4a34A4644a113E8200D7F1D79b3555f723AfE); // underlying and depositor help contract at once
    AlpacaBaseStrategy.initialize(
      _storage,
      underlying,
      _vault,
      ibToken,
      ibToken,
      9
    );
    pancake_route = [alpaca, wbnb, underlying];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./AlpacaBaseStrategy.sol";

contract AlpacaBUSDStrategy is AlpacaBaseStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address alpaca = address(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    address ibToken = address(0x7C9e73d4C71dae564d41F78d56439bB4ba87592f); // underlying and depositor help contract at once
    AlpacaBaseStrategy.initialize(
      _storage,
      underlying,
      _vault,
      ibToken,
      ibToken,
      3
    );
    pancake_route = [alpaca, wbnb, underlying];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./AlpacaBaseStrategy.sol";

contract AlpacaBTCBStrategy is AlpacaBaseStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address alpaca = address(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    address ibToken = address(0x08FC9Ba2cAc74742177e0afC3dC8Aed6961c24e7); // underlying and depositor help contract at once
    AlpacaBaseStrategy.initialize(
      _storage,
      underlying,
      _vault,
      ibToken,
      ibToken,
      18
    );
    pancake_route = [alpaca, wbnb, underlying];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./AlpacaBaseStrategy.sol";

contract AlpacaALPACAStrategy is AlpacaBaseStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address alpaca = address(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    address ibToken = address(0xf1bE8ecC990cBcb90e166b71E368299f0116d421); // underlying and depositor help contract at once
    AlpacaBaseStrategy.initialize(
      _storage,
      underlying,
      _vault,
      ibToken,
      ibToken,
      11
    );
    pancake_route = [alpaca, wbnb, underlying];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "./BeltSingleStrategy.sol";

contract BeltSingleStrategy_BeltBNB is BeltSingleStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address belt = address(0xE0e514c71282b6f4e823703a39374Cf58dc3eA4f);
    address wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address beltBNB = address(0xa8Bb71facdd46445644C277F9499Dd22f6F0A30C);
    address masterBelt = address(0xD4BbC80b9B102b77B21A06cb77E954049605E6c1);
    BeltSingleStrategy.initialize(
      _storage,
      beltBNB,
      _vault,
      masterBelt, // stakingPool
      belt,
      beltBNB,
      wbnb,
      9  // Pool id
    );
    pancake_route = [belt, wbnb];
  }
}