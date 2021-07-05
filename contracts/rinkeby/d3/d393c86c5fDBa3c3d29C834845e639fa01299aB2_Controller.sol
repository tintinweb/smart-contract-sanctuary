// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IStrategy.sol";
import "../interface/ISmartVault.sol";
import "../interface/IFeeRewardForwarder.sol";
import "./Controllable.sol";
import "../interface/IBookkeeper.sol";
import "./ControllerStorage.sol";

contract Controller is Initializable, Controllable, ControllerStorage {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  function initialize() public initializer {
    Controllable.initializeControllable(address(this));
    ControllerStorage.initializeControllerStorage(
      msg.sender
    );

    setPSNumeratorDenominator(1000, 1000);
  }

  // ************ EVENTS **********************

  event HardWorkerAdded(address value);
  event HardWorkerRemoved(address value);
  event AddedToWhiteList(address value);
  event RemovedFromWhiteList(address value);
  event VaultAndStrategyAdded(address vault, address strategy);
  event Salvaged(address token, uint256 amount);
  event SalvagedStrategy(address strategy, address token, uint256 amount);
  event NotifyFee(address underlying, uint256 fee);
  event SharePriceChangeLog(
    address indexed vault,
    address indexed strategy,
    uint256 oldSharePrice,
    uint256 newSharePrice,
    uint256 timestamp
  );

  // ************ VARIABLES **********************
  string public constant VERSION = "0";
  mapping(address => bool) public override whiteList;
  mapping(address => bool) public override vaults;
  mapping(address => bool) public override strategies;
  mapping(address => bool) public hardWorkers;
  mapping(address => bool) public rewardDistribution;

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "not governance");
    _;
  }

  modifier onlyVault() {
    require(vaults[msg.sender], "only exist active vault");
    _;
  }

  modifier onlyHardWorkerOrGovernance() {
    require(IController(controller()).isHardWorker(msg.sender)
      || IController(controller()).isGovernance(msg.sender), "only hardworker");
    _;
  }

  // ************ GOVERNANCE ACTIONS **************************

  function setGovernance(address _governance) external onlyGovernance {
    require(_governance != address(0), "zero address");
    _setGovernance(_governance);
  }

  function setFeeRewardForwarder(address _feeRewardForwarder) external onlyGovernance {
    require(_feeRewardForwarder != address(0), "zero address");
    rewardDistribution[feeRewardForwarder()] = false;
    _setFeeRewardForwarder(_feeRewardForwarder);
    rewardDistribution[feeRewardForwarder()] = true;
  }

  function setBookkeeper(address _bookkeeper) external onlyGovernance {
    require(_bookkeeper != address(0), "zero address");
    _setBookkeeper(_bookkeeper);
  }

  function setMintHelper(address _newValue) external onlyGovernance {
    require(_newValue != address(0), "zero address");
    _setMintHelper(_newValue);
  }

  function setRewardToken(address _newValue) external onlyGovernance {
    require(_newValue != address(0), "zero address");
    _setRewardToken(_newValue);
  }

  function setNotifyHelper(address _newValue) external onlyGovernance {
    require(_newValue != address(0), "zero address");
    rewardDistribution[notifyHelper()] = false;
    _setNotifyHelper(_newValue);
    rewardDistribution[notifyHelper()] = true;
  }

  function setPsVault(address _newValue) external onlyGovernance {
    require(_newValue != address(0), "zero address");
    _setPsVault(_newValue);
  }

  function setRewardDistribution(address[] calldata _newRewardDistribution, bool _flag) external onlyGovernance {
    for (uint256 i = 0; i < _newRewardDistribution.length; i++) {
      rewardDistribution[_newRewardDistribution[i]] = _flag;
    }
  }

  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) public onlyGovernance {
    require(numerator <= denominator, "invalid values");
    require(denominator != 0, "cannot divide by 0");
    _setPsNumerator(numerator);
    _setPsDenominator(denominator);
  }

  function addHardWorker(address _worker) external onlyGovernance {
    require(_worker != address(0), "_worker must be defined");
    hardWorkers[_worker] = true;
    emit HardWorkerAdded(_worker);
  }

  function removeHardWorker(address _worker) external onlyGovernance {
    require(_worker != address(0), "_worker must be defined");
    hardWorkers[_worker] = false;
    emit HardWorkerRemoved(_worker);
  }

  function addToWhiteList(address _target) external onlyGovernance {
    whiteList[_target] = true;
    emit AddedToWhiteList(_target);
  }

  function removeFromWhiteList(address _target) external onlyGovernance {
    whiteList[_target] = false;
    emit RemovedFromWhiteList(_target);
  }

  function addVaultAndStrategy(address _vault, address _strategy) external override onlyGovernance {
    require(_vault != address(0), "new vault shouldn't be empty");
    require(!vaults[_vault], "vault already exists");
    // existed strategies allowed
    require(_strategy != address(0), "new strategy must not be empty");

    vaults[_vault] = true;
    IBookkeeper(bookkeeper()).addVault(_vault);

    // adding happens while setting
    ISmartVault(_vault).setStrategy(_strategy);
    emit VaultAndStrategyAdded(_vault, _strategy);
  }

  function addStrategy(address _strategy) public override onlyVault {
    if (strategies[_strategy] == false) {
      strategies[_strategy] = true;
      IBookkeeper(bookkeeper()).addStrategy(_strategy);
    }
  }

  function doHardWork(address _vault) external onlyHardWorkerOrGovernance {
    require(isValidVault(_vault), "not vault");
    uint256 oldSharePrice = ISmartVault(_vault).getPricePerFullShare();
    ISmartVault(_vault).doHardWork();
    emit SharePriceChangeLog(
      _vault,
      ISmartVault(_vault).strategy(),
      oldSharePrice,
      ISmartVault(_vault).getPricePerFullShare(),
      block.timestamp
    );
  }

  // transfers token in the controller contract to the governance
  function salvage(address _token, uint256 _amount) external onlyGovernance {
    IERC20(_token).safeTransfer(governance(), _amount);
    emit Salvaged(_token, _amount);
  }

  function salvageStrategy(address _strategy, address _token, uint256 _amount) external onlyGovernance {
    // the strategy is responsible for maintaining the list of
    // salvagable tokens, to make sure that governance cannot come
    // in and take away the coins
    IStrategy(_strategy).salvage(governance(), _token, _amount);
    emit SalvagedStrategy(_strategy, _token, _amount);
  }

  // ***************** EXTERNAL *******************************

  function isGovernance(address _adr) public view override returns (bool) {
    return governance() == _adr;
  }

  function isHardWorker(address _adr) public override view returns (bool) {
    return hardWorkers[_adr] || isGovernance(_adr);
  }

  function isRewardDistributor(address _adr) public override view returns (bool) {
    return rewardDistribution[_adr] || isGovernance(_adr) || isValidStrategy(_adr);
  }

  function isAllowedUser(address _adr) external view override returns (bool) {
    return isNotSmartContract(_adr)
    || whiteList[_adr]
    || isGovernance(_adr)
    || isHardWorker(_adr)
    || isRewardDistributor(_adr)
    || vaults[_adr]
    || strategies[_adr];
  }

  // it is not 100% guarantee after EIP-3074 implementation
  // use it as an additional check
  function isNotSmartContract(address _adr) private view returns (bool) {
    return _adr == tx.origin;
  }

  function isValidVault(address _vault) public override view returns (bool) {
    return vaults[_vault];
  }

  function isValidStrategy(address _strategy) public override view returns (bool) {
    return strategies[_strategy];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IStrategy {

  // *************** GOVERNANCE ACTIONS **************
  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external view returns (string memory);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);

  function poolWeeklyRewardsAmount() external view returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function doHardWork() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFor(uint256 amount, address holder) external;

  function withdraw(uint256 numberOfShares) external;

  function exit() external;

  function getAllRewards() external;

  function getReward(address rt) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function nextImplementation() external view returns (address);

  function futureStrategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function nextImplementationTimestamp() external view returns (uint256);

  function strategyUpdateTime() external view returns (uint256);

  function duration() external view returns (uint256);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function availableToInvestOut() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function rewardPerToken(address rt) external view returns (uint256);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function rewardTokensLength() external view returns (uint256);

  function active() external view returns (bool);

  function canUpdateStrategy(address _strategy) external view returns (bool);

  function rewardTokens() external view returns (address[] memory);

  function periodFinishForToken(address _rt) external view returns (uint256);

  function rewardRateForToken(address _rt) external view returns (uint256);

  function lastUpdateTimeForToken(address _rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

  function rewardsForToken(address _rt, address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IFeeRewardForwarder {
  function notifyPsPool(address _token, uint256 _amount) external returns (uint256);

  function notifyCustomPool(address _token, address _rewardPool, uint256 _maxBuyback) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interface/IController.sol";

/**
* 200 - vault does not exist
* 201 - only hard worker or governance can call this
* 202 - Not governance
* 203 - message sender is a contract and have not added to the white list
* 204 - Not reward distributor
* 205 - empty address
* 206 - Not controller
*/
abstract contract Controllable is Initializable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  event UpdateController(address oldValue, address newValue);

  function initializeControllable(address _controller) public initializer {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
    setController(_controller);
    setCreated(block.timestamp);
  }

  // ************ MODIFIERS **********************

  modifier onlyControllerOrGovernance() {
    require(controller() == msg.sender || IController(controller()).isGovernance(msg.sender), "not controller");
    _;
  }

  /**
 *  Only smart contracts will be affected by this modifier
 *  If it is a contract it should be whitelisted
 */
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  function controller() public view returns (address str) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      str := sload(slot)
    }
  }

  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  function created() public view returns (uint256 str) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      str := sload(slot)
    }
  }

  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function vaults() external view returns (address[] memory);

  function strategies() external view returns (address[] memory);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  function targetTokenEarned(address vault) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  function vaultUsersQuantity(address vault) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interface/IController.sol";

// Eternal storage + getters and setters pattern
// If you will change a key value it will require setup it again
abstract contract ControllerStorage is Initializable, IController {

  // don't change names or ordering!
  mapping(bytes32 => uint256) private uintStorage;
  mapping(bytes32 => address) private addressStorage;

  event UpdatedAddressSlot(string name, address oldValue, address newValue);
  event UpdatedUint256Slot(string name, uint256 oldValue, uint256 newValue);

  function initializeControllerStorage(
    address _governance
  ) public initializer {
    _setGovernance(_governance);
  }

  // ******************* SETTERS AND GETTERS **********************

  // ----------- ADDRESSES ----------
  function _setGovernance(address _address) internal {
    emit UpdatedAddressSlot("governance", governance(), _address);
    setAddress("governance", _address);
  }

  function governance() public override view returns (address) {
    return getAddress("governance");
  }

  function _setFeeRewardForwarder(address _address) internal {
    emit UpdatedAddressSlot("feeRewardForwarder", feeRewardForwarder(), _address);
    setAddress("feeRewardForwarder", _address);
  }

  function feeRewardForwarder() public override view returns (address) {
    return getAddress("feeRewardForwarder");
  }

  function _setBookkeeper(address _address) internal {
    emit UpdatedAddressSlot("bookkeeper", bookkeeper(), _address);
    setAddress("bookkeeper", _address);
  }

  function bookkeeper() public override view returns (address) {
    return getAddress("bookkeeper");
  }

  function _setMintHelper(address _address) internal {
    emit UpdatedAddressSlot("mintHelper", mintHelper(), _address);
    setAddress("mintHelper", _address);
  }

  function mintHelper() public override view returns (address) {
    return getAddress("mintHelper");
  }

  function _setRewardToken(address _address) internal {
    emit UpdatedAddressSlot("rewardToken", rewardToken(), _address);
    setAddress("rewardToken", _address);
  }

  function rewardToken() public override view returns (address) {
    return getAddress("rewardToken");
  }

  function _setNotifyHelper(address _address) internal {
    emit UpdatedAddressSlot("notifyHelper", notifyHelper(), _address);
    setAddress("notifyHelper", _address);
  }

  function notifyHelper() public override view returns (address) {
    return getAddress("notifyHelper");
  }

  function _setPsVault(address _address) internal {
    emit UpdatedAddressSlot("psVault", psVault(), _address);
    setAddress("psVault", _address);
  }

  function psVault() public override view returns (address) {
    return getAddress("psVault");
  }

  // ----------- INTEGERS ----------
  function _setPsNumerator(uint256 _value) internal {
    emit UpdatedUint256Slot("psNumerator", psNumerator(), _value);
    setUint256("psNumerator", _value);
  }

  function psNumerator() public view override returns (uint256) {
    return getUint256("psNumerator");
  }

  function _setPsDenominator(uint256 _value) internal {
    emit UpdatedUint256Slot("psDenominator", psDenominator(), _value);
    setUint256("psDenominator", _value);
  }

  function psDenominator() public view override returns (uint256) {
    return getUint256("psDenominator");
  }

  // ******************** STORAGE INTERNAL FUNCTIONS ********************

  function setAddress(string memory key, address _address) private {
    addressStorage[keccak256(abi.encodePacked(key))] = _address;
  }

  function getAddress(string memory key) private view returns (address) {
    return addressStorage[keccak256(abi.encodePacked(key))];
  }

  function setUint256(string memory key, uint256 _value) private {
    uintStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getUint256(string memory key) private view returns (uint256) {
    return uintStorage[keccak256(abi.encodePacked(key))];
  }

  uint256[50] private ______gap;
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

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IController {

  function addVaultAndStrategy(address _vault, address _strategy) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function notifyHelper() external view returns (address);

  function psVault() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isGovernance(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}