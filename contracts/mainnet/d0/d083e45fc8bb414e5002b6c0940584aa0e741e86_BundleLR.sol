// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IBundle.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IController.sol";
import "../interfaces/IVault.sol";
import "../Controllable.sol";
import "../Storage.sol";


contract Bundle is IBundle, Controllable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  event Invest(uint256 amount);

  IERC20 public underlying;
  IVault public vault;

  struct StrategyStruct {
    uint256 riskScore;
    uint256 weightage;
    bool isActive;
  }

  mapping(address => StrategyStruct) public strategyStruct;
  address[] public strategyList;

  uint256 vaultFractionToInvestNumerator = 0;
  uint256 vaultFractionToInvestDenominator = 100;
  
  uint256 accountedBalance;

  // These tokens cannot be claimed by the controller
  mapping (address => bool) public unsalvagableTokens;

  constructor(address _storage, address _underlying, address _vault) public
  Controllable(_storage) {
    require(_underlying != address(0), "_underlying cannot be empty");
    require(_vault != address(0), "_vault cannot be empty");
    // We assume that this contract is a minter on underlying
    underlying = IERC20(_underlying);
    vault = IVault(_vault);
  }

  function depositArbCheck() public override view returns(bool) {
    return true;
  }

  modifier restricted() {
    require(msg.sender == address(vault) || msg.sender == address(controller()),
      "The sender has to be the controller or vault");
    _;
  }

  function isActiveStrategy(address _strategy) internal view returns(bool isActive) {
      return strategyStruct[_strategy].isActive;
  }

  function getStrategyCount() internal view returns(uint256 strategyCount) {
    return strategyList.length;
  }

  modifier whenStrategyDefined() {
    require(getStrategyCount() > 0, "Strategies must be defined");
    _;
  }

  function getUnderlying() public override view returns (address) {
    return address(underlying);
  }

  function getVault() public override view returns (address) {
    return address(vault);
  }

  /*
  * Returns the cash balance across all users in this contract.
  */
  function underlyingBalanceInBundle() view public override returns (uint256) {
    return underlying.balanceOf(address(this));
  }

  /* Returns the current underlying (e.g., DAI's) balance together with
   * the invested amount (if DAI is invested elsewhere by the strategy).
  */
  function underlyingBalanceWithInvestment() view public override returns (uint256) {
    uint256 underlyingBalance = underlyingBalanceInBundle();
    if (getStrategyCount() == 0) {
      // initial state, when not set
      return underlyingBalance;
    }
    for (uint256 i=0; i<getStrategyCount(); i++) {
      underlyingBalance = underlyingBalance.add(IStrategy(strategyList[i]).investedUnderlyingBalance());
    }
    return underlyingBalance;
  }

  function availableToInvestOut() public view returns (uint256) {
    uint256 wantInvestInTotal = underlyingBalanceWithInvestment()
        .mul(vaultFractionToInvestNumerator)
        .div(vaultFractionToInvestDenominator);
    uint256 alreadyInvested = 0;
    for (uint256 i=0; i<getStrategyCount(); i++) {
      alreadyInvested = alreadyInvested.add(IStrategy(strategyList[i]).investedUnderlyingBalance());
    }
    if (alreadyInvested >= wantInvestInTotal) {
      return 0;
    } else {
      uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
      return remainingToInvest <= underlyingBalanceInBundle()
        ? remainingToInvest : underlyingBalanceInBundle();
    }
  }

  function addStrategy(address _strategy, uint256 riskScore, uint256 weightage) public override onlyControllerOrGovernance {
    require(_strategy != address(0), "new _strategy cannot be empty");
    require((IStrategy(_strategy).getUnderlying() == address(underlying)), "Bundle underlying must match Strategy underlying");
    require(IStrategy(_strategy).getBundle() == address(this), "The strategy does not belong to this bundle");
    require(isActiveStrategy(_strategy) == false, "This strategy is already active in this bundle");
    require(vaultFractionToInvestNumerator.add(weightage) <= 90, "Total investment can't be above 90%");
    
    strategyStruct[_strategy].riskScore = riskScore;
    strategyStruct[_strategy].weightage = weightage;
    vaultFractionToInvestNumerator = vaultFractionToInvestNumerator.add(weightage);
    strategyStruct[_strategy].isActive = true;
    strategyList.push(_strategy);

    underlying.safeApprove(_strategy, 0);
    underlying.safeApprove(_strategy, uint256(~0));
  }

  // function removeStrategy(address _strategy) public override onlyControllerOrGovernance {
  //   require(_strategy != address(0), "new _strategy cannot be empty");
  //   require(IStrategy(_strategy).getUnderlying() == address(underlying), "Vault underlying must match Strategy underlying");
  //   require(IStrategy(_strategy).getVault() == address(this), "the strategy does not belong to this vault");

  //   if (address(_strategy) != address(strategy)) {
  //     if (address(strategy) != address(0)) { // if the original strategy (no underscore) is defined
  //       underlying.safeApprove(address(strategy), 0);
  //       strategy.withdrawAllToVault();
  //     }
  //     strategy = IStrategy(_strategy);
  //     underlying.safeApprove(address(strategy), 0);
  //     underlying.safeApprove(address(strategy), uint256(~0));
  //   }
  // }

  function invest() internal whenStrategyDefined {
    uint256 availableAmount = availableToInvestOut();
    for (uint256 i=0; i<getStrategyCount(); i++) {
      if (strategyStruct[strategyList[i]].isActive) {
        uint256 weightage = strategyStruct[strategyList[i]].weightage;
        uint256 availableAmountForStrategy = availableAmount.mul(weightage).div(vaultFractionToInvestNumerator);
        if (availableAmountForStrategy > 0) {
          underlying.safeTransfer(strategyList[i], availableAmountForStrategy);
          emit Invest(availableAmountForStrategy);
        }
      }
    }
  }

  /**
  * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
  * doHardWork on the current strategy. Call this through controller to claim hard rewards.
  */
  function doHardWork() whenStrategyDefined external override restricted{
    // ensure that new funds are invested too
    invest();
    for (uint256 i=0; i<getStrategyCount(); i++) {
      if (strategyStruct[strategyList[i]].isActive) {
        IStrategy(strategyList[i]).doHardWork();
      }
    }
  }

  function rebalance() external override onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }

  function withdrawAll() public override onlyControllerOrGovernance whenStrategyDefined {
    for (uint256 i=0; i<getStrategyCount(); i++) {
      IStrategy(strategyList[i]).withdrawAllToBundle();
    }
  }

  function withdraw(uint256 underlyingAmountToWithdraw, address holder) external override restricted returns (uint256){

    if (underlyingAmountToWithdraw > underlyingBalanceInBundle()) {
      uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInBundle());
      for (uint256 i=0; i<getStrategyCount(); i++) {
        if (strategyStruct[strategyList[i]].isActive) {
          uint256 weightage = strategyStruct[strategyList[i]].weightage;
          uint256 missingforStrategy = missing.mul(weightage).div(vaultFractionToInvestNumerator);
          IStrategy(strategyList[i]).withdrawToBundle(missingforStrategy);
        }
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = Math.min(underlyingAmountToWithdraw, underlyingBalanceInBundle());
    }

    underlying.safeTransfer(holder, underlyingAmountToWithdraw);
    return underlyingAmountToWithdraw;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./Bundle.sol";

contract BundleLR is Bundle {
  constructor(address _storage, address _underlying, address _vault) Bundle(_storage, _underlying, _vault) public {
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IBundle {
    
    function underlyingBalanceInBundle() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);
    
    // function governance() external view returns (address);
    // function controller() external view returns (address);
    function getUnderlying() external view returns (address);
    function getVault() external view returns (address);

    function addStrategy(address _strategy, uint256 riskScore, uint256 weightage) external;
    // function removeStrategy(address _strategy) external;
    
    function withdrawAll() external;
    function withdraw(uint256 underlyingAmountToWithdraw, address holder) external returns (uint256);

    function depositArbCheck() external view returns(bool);

    function doHardWork() external;
    function rebalance() external;
}

// SPDX-License-Identifier: MIT
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    
    // function unsalvagableTokens(address tokens) external view returns (bool);
    
    // function governance() external view returns (address);
    // function controller() external view returns (address);
    function getUnderlying() external view returns (address);
    function getBundle() external view returns (address);

    function withdrawAllToBundle() external;
    function withdrawToBundle(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVault {
    // the IERC20 part is the share

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function governance() external view returns (address);
    // function controller() external view returns (address);
    function underlying() external view returns (address);
    function bundle() external view returns (address);

    function setBundle(address _bundle) external;
    // function removeBundle(address _bundle) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

pragma solidity ^0.6.0;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
        assembly { codehash := extcodehash(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

