/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


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
        return sub(a, b, "SafeMath: subtraction overflow");
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts/common/Constants.sol

pragma solidity >=0.6.0 <0.7.0;

contract Constants {
    uint8 public constant N_COINS = 3;
    uint8 public constant DEFAULT_DECIMALS = 18; 
    uint256 public constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR = uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
    uint256 public constant CURVE_RATIO_DECIMALS = 6;
    uint256 public constant CURVE_RATIO_DECIMALS_FACTOR = uint256(10)**CURVE_RATIO_DECIMALS;
}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/interfaces/IController.sol

pragma solidity >=0.6.0 <0.7.0;

interface IController {
    function stablecoins() external view returns (address[3] memory);

    function vaults() external view returns (address[3] memory);

    function underlyingVaults(uint256 i) external view returns (address vault);

    function curveVault() external view returns (address);

    function pnl() external view returns (address);

    function insurance() external view returns (address);

    function lifeGuard() external view returns (address);

    function buoy() external view returns (address);

    function reward() external view returns (address);

    function isValidBigFish(
        bool pwrd,
        bool deposit,
        uint256 amount
    ) external view returns (bool);

    function withdrawHandler() external view returns (address);

    function emergencyHandler() external view returns (address);

    function depositHandler() external view returns (address);

    function totalAssets() external view returns (uint256);

    function gTokenTotalAssets() external view returns (uint256);

    function eoaOnly(address sender) external;

    function getSkimPercent() external view returns (uint256);

    function gToken(bool _pwrd) external view returns (address);

    function emergencyState() external view returns (bool);

    function deadCoin() external view returns (uint256);

    function distributeStrategyGainLoss(uint256 gain, uint256 loss) external;

    function burnGToken(
        bool pwrd,
        bool all,
        address account,
        uint256 amount,
        uint256 bonus
    ) external;

    function mintGToken(
        bool pwrd,
        address account,
        uint256 amount
    ) external;

    function getUserAssets(bool pwrd, address account) external view returns (uint256 deductUsd);

    function referrals(address account) external view returns (address);

    function addReferral(address account, address referral) external;

    function getStrategiesTargetRatio() external view returns (uint256[] memory);

    function withdrawalFee(bool pwrd) external view returns (uint256);

    function validGTokenDecrease(uint256 amount) external view returns (bool);
}

// File: contracts/interfaces/IPausable.sol

pragma solidity >=0.6.0 <0.7.0;

interface IPausable {
    function paused() external view returns (bool);
}

// File: contracts/common/Controllable.sol

pragma solidity >=0.6.0 <0.7.0;





contract Controllable is Ownable {
    address public controller;

    event ChangeController(address indexed oldController, address indexed newController);

    modifier whenNotPaused() {
        require(!_pausable().paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_pausable().paused(), "Pausable: not paused");
        _;
    }

    function ctrlPaused() public view returns (bool) {
        return _pausable().paused();
    }

    function setController(address newController) external onlyOwner {
        require(newController != address(0), "setController: !0x");
        address oldController = controller;
        controller = newController;
        emit ChangeController(oldController, newController);
    }

    function _controller() internal view returns (IController) {
        require(controller != address(0), "Controller not set");
        return IController(controller);
    }

    function _pausable() internal view returns (IPausable) {
        require(controller != address(0), "Controller not set");
        return IPausable(controller);
    }
}

// File: contracts/common/StructDefinitions.sol

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

struct SystemState {
    uint256 totalCurrentAssetsUsd;
    uint256 curveCurrentAssetsUsd;
    uint256 lifeguardCurrentAssetsUsd;
    uint256[3] vaultCurrentAssets;
    uint256[3] vaultCurrentAssetsUsd;
    uint256 rebalanceThreshold;
    uint256 utilisationRatio;
    uint256 targetBuffer;
    uint256[3] stablePercents;
    uint256 curvePercent;
}

struct ExposureState {
    uint256[3] stablecoinExposure;
    uint256[] protocolExposure;
    uint256 curveExposure;
    bool stablecoinExposed;
    bool protocolExposed;
}

struct AllocationState {
    uint256[] strategyTargetRatio;
    bool needProtocolWithdrawal;
    uint256 protocolExposedIndex;
    uint256[3] protocolWithdrawalUsd;
    StablecoinAllocationState stableState;
}

struct StablecoinAllocationState {
    uint256 swapInTotalAmountUsd;
    uint256[3] swapInAmounts;
    uint256[3] swapInAmountsUsd;
    uint256[3] swapOutPercents;
    uint256[3] vaultsTargetUsd;
    uint256 curveTargetUsd;
    uint256 curveTargetDeltaUsd;
}

// File: contracts/interfaces/IAllocation.sol

pragma solidity >=0.6.0 <0.7.0;


interface IAllocation {
    function calcSystemTargetDelta(SystemState calldata sysState, ExposureState calldata expState)
        external
        view
        returns (AllocationState memory allState);

    function calcVaultTargetDelta(SystemState calldata sysState, bool onlySwapOut)
        external
        view
        returns (StablecoinAllocationState memory stableState);

    function calcStrategyPercent(uint256 utilisationRatio) external pure returns (uint256[] memory);
}

// File: contracts/interfaces/IInsurance.sol

pragma solidity >=0.6.0 <0.7.0;

interface IInsurance {
    function calculateDepositDeltasOnAllVaults() external view returns (uint256[3] memory);

    function rebalanceTrigger() external view returns (bool sysNeedRebalance);

    function rebalance() external;

    function calcSkim() external view returns (uint256);

    function rebalanceForWithdraw(uint256 withdrawUsd, bool pwrd) external returns (bool);

    function getDelta(uint256 withdrawUsd) external view returns (uint256[3] memory delta);

    function getVaultDeltaForDeposit(uint256 amount)
        external
        view
        returns (
            uint256[3] memory,
            uint256[3] memory,
            uint256
        );

    function sortVaultsByDelta(bool bigFirst) external view returns (uint256[3] memory vaultIndexes);

    function getStrategiesTargetRatio(uint256 utilRatio) external view returns (uint256[] memory);

    function setUnderlyingTokenPercent(uint256 coinIndex, uint256 percent) external;
}

// File: contracts/interfaces/IExposure.sol

pragma solidity >=0.6.0 <0.7.0;


interface IExposure {
    function calcRiskExposure(SystemState calldata sysState) external view returns (ExposureState memory expState);

    function getExactRiskExposure(SystemState calldata sysState) external view returns (ExposureState memory expState);

    function getUnifiedAssets(address[3] calldata vaults)
        external
        view
        returns (uint256 unifiedTotalAssets, uint256[3] memory unifiedAssets);

    function sortVaultsByDelta(
        bool bigFirst,
        uint256 unifiedTotalAssets,
        uint256[3] calldata unifiedAssets,
        uint256[3] calldata targetPercents
    ) external pure returns (uint256[3] memory vaultIndexes);

    function calcRoughDelta(
        uint256[3] calldata targets,
        address[3] calldata vaults,
        uint256 withdrawUsd
    ) external view returns (uint256[3] memory);
}

// File: contracts/interfaces/IERC20Detailed.sol

pragma solidity >=0.6.0 <0.7.0;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: contracts/interfaces/ILifeGuard.sol

pragma solidity >=0.6.0 <0.7.0;


interface ILifeGuard {
    function assets(uint256 i) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function getAssets() external view returns (uint256[3] memory);

    function totalAssetsUsd() external view returns (uint256);

    function availableUsd() external view returns (uint256 dollar);

    function availableLP() external view returns (uint256);

    function depositStable(bool rebalance) external returns (uint256);

    function investToCurveVault() external;

    function distributeCurveVault(uint256 amount, uint256[3] memory delta) external returns (uint256[3] memory);

    function deposit() external returns (uint256 usdAmount);

    function withdrawSingleByLiquidity(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external returns (uint256 usdAmount, uint256 amount);

    function withdrawSingleByExchange(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external returns (uint256 usdAmount, uint256 amount);

    function invest(uint256 whaleDepositAmount, uint256[3] calldata delta) external returns (uint256 dollarAmount);

    function getBuoy() external view returns (address);

    function investSingle(
        uint256[3] calldata inAmounts,
        uint256 i,
        uint256 j
    ) external returns (uint256 dollarAmount);

    function investToCurveVaultTrigger() external view returns (bool _invest);
}

// File: contracts/interfaces/IVault.sol

pragma solidity >=0.6.0 <0.7.0;

interface IVault {
    function withdraw(uint256 amount) external;

    function withdraw(uint256 amount, address recipient) external;

    function withdrawByStrategyOrder(
        uint256 amount,
        address recipient,
        bool reversed
    ) external;

    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external;

    function deposit(uint256 amount) external;

    function updateStrategyRatio(uint256[] calldata strategyRetios) external;

    function totalAssets() external view returns (uint256);

    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index) external returns (bool);

    function getStrategyAssets(uint256 index) external view returns (uint256);

    function token() external view returns (address);

    function vault() external view returns (address);

    function investTrigger() external view returns (bool);

    function invest() external;
}

// File: contracts/interfaces/IBuoy.sol

pragma solidity >=0.6.0 <0.7.0;

interface IBuoy {
    function safetyCheck() external view returns (bool);

    function updateRatios() external returns (bool);

    function updateRatiosWithTolerance(uint256 tolerance) external returns (bool);

    function lpToUsd(uint256 inAmount) external view returns (uint256);

    function usdToLp(uint256 inAmount) external view returns (uint256);

    function stableToUsd(uint256[3] calldata inAmount, bool deposit) external view returns (uint256);

    function stableToLp(uint256[3] calldata inAmount, bool deposit) external view returns (uint256);

    function singleStableFromLp(uint256 inAmount, int128 i) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function singleStableFromUsd(uint256 inAmount, int128 i) external view returns (uint256);

    function singleStableToUsd(uint256 inAmount, uint256 i) external view returns (uint256);
}

// File: contracts/interfaces/IPnL.sol

pragma solidity >=0.6.0 <0.7.0;

interface IPnL {
    function calcPnL() external view returns (uint256, uint256);

    function increaseGTokenLastAmount(bool pwrd, uint256 dollarAmount) external;

    function decreaseGTokenLastAmount(
        bool pwrd,
        uint256 dollarAmount,
        uint256 bonus
    ) external;

    function lastGvtAssets() external view returns (uint256);

    function lastPwrdAssets() external view returns (uint256);

    function utilisationRatio() external view returns (uint256);

    function emergencyPnL() external;

    function recover() external;

    function distributeStrategyGainLoss(
        uint256 gain,
        uint256 loss,
        address reward
    ) external;

    function distributePriceChange(uint256 currentTotalAssets) external;
}

// File: contracts/insurance/Insurance.sol

pragma solidity >=0.6.0 <0.7.0;













contract Insurance is Constants, Controllable, IInsurance {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IAllocation public allocation;
    IExposure public exposure;

    mapping(uint256 => uint256) public underlyingTokensPercents;
    uint256 public curveVaultPercent;

    
    
    
    uint256 public exposureBufferRebalance;
    
    
    
    
    uint256 public maxPercentForWithdraw;
    
    
    
    uint256 public maxPercentForDeposit;

    event LogNewAllocation(address allocation);
    event LogNewExposure(address exposure);
    event LogNewTargetAllocation(uint256 indexed index, uint256 percent);
    event LogNewCurveAllocation(uint256 percent);
    event LogNewExposureBuffer(uint256 buffer);
    event LogNewVaultMax(bool deposit, uint256 percent);

    modifier onlyValidIndex(uint256 index) {
        require(index >= 0 && index < N_COINS, "Invalid index value.");
        _;
    }

    function setAllocation(address _allocation) external onlyOwner {
        require(_allocation != address(0), "Zero address provided");
        allocation = IAllocation(_allocation);
        emit LogNewAllocation(_allocation);
    }

    function setExposure(address _exposure) external onlyOwner {
        require(_exposure != address(0), "Zero address provided");
        exposure = IExposure(_exposure);
        emit LogNewExposure(_exposure);
    }

    function setUnderlyingTokenPercent(uint256 coinIndex, uint256 percent) external override onlyValidIndex(coinIndex) {
        require(msg.sender == controller || msg.sender == owner(), "setUnderlyingTokenPercent: !authorized");
        underlyingTokensPercents[coinIndex] = percent;
        emit LogNewTargetAllocation(coinIndex, percent);
    }

    function setCurveVaultPercent(uint256 _curveVaultPercent) external onlyOwner {
        curveVaultPercent = _curveVaultPercent;
        emit LogNewCurveAllocation(_curveVaultPercent);
    }

    function setExposureBufferRebalance(uint256 rebalanceBuffer) external onlyOwner {
        exposureBufferRebalance = rebalanceBuffer;
        emit LogNewExposureBuffer(rebalanceBuffer);
    }

    function setWhaleThresholdWithdraw(uint256 _maxPercentForWithdraw) external onlyOwner {
        maxPercentForWithdraw = _maxPercentForWithdraw;
        emit LogNewVaultMax(false, _maxPercentForWithdraw);
    }

    function setWhaleThresholdDeposit(uint256 _maxPercentForDeposit) external onlyOwner {
        maxPercentForDeposit = _maxPercentForDeposit;
        emit LogNewVaultMax(true, _maxPercentForDeposit);
    }

    function calculateDepositDeltasOnAllVaults() public view override returns (uint256[N_COINS] memory) {
        return getStablePercents();
    }

    function getVaultDeltaForDeposit(uint256 amount)
        external
        view
        override
        returns (
            uint256[N_COINS] memory,
            uint256[N_COINS] memory,
            uint256
        )
    {
        uint256[N_COINS] memory investDelta;
        uint256[N_COINS] memory vaultIndexes;
        (uint256 totalAssets, uint256[N_COINS] memory vaultAssets) = exposure.getUnifiedAssets(_controller().vaults());
        
        
        if (amount < totalAssets.mul(maxPercentForDeposit).div(PERCENTAGE_DECIMAL_FACTOR)) {
            uint256[N_COINS] memory _vaultIndexes = exposure.sortVaultsByDelta(
                false,
                totalAssets,
                vaultAssets,
                getStablePercents()
            );
            investDelta[vaultIndexes[0]] = 10000;
            vaultIndexes[0] = _vaultIndexes[0];
            vaultIndexes[1] = _vaultIndexes[1];
            vaultIndexes[2] = _vaultIndexes[2];

            return (investDelta, vaultIndexes, 1);
            
            
        } else {
            return (investDelta, vaultIndexes, N_COINS);
        }
    }

    function sortVaultsByDelta(bool bigFirst) external view override returns (uint256[N_COINS] memory vaultIndexes) {
        (uint256 totalAssets, uint256[N_COINS] memory vaultAssets) = exposure.getUnifiedAssets(_controller().vaults());
        return exposure.sortVaultsByDelta(bigFirst, totalAssets, vaultAssets, getStablePercents());
    }

    function rebalanceTrigger() external view override returns (bool sysNeedRebalance) {
        SystemState memory sysState = prepareCalculation();
        sysState.utilisationRatio = IPnL(_controller().pnl()).utilisationRatio();
        sysState.rebalanceThreshold = PERCENTAGE_DECIMAL_FACTOR.sub(sysState.utilisationRatio.div(2)).sub(
            exposureBufferRebalance
        );
        ExposureState memory expState = exposure.calcRiskExposure(sysState);
        sysNeedRebalance = expState.stablecoinExposed || expState.protocolExposed;
    }

    function rebalance() external override {
        SystemState memory sysState = prepareCalculation();
        sysState.utilisationRatio = IPnL(_controller().pnl()).utilisationRatio();
        sysState.rebalanceThreshold = PERCENTAGE_DECIMAL_FACTOR.sub(sysState.utilisationRatio.div(2)).sub(
            exposureBufferRebalance
        );
        ExposureState memory expState = exposure.calcRiskExposure(sysState);
        if (!expState.stablecoinExposed && !expState.protocolExposed) return;
        sysState.targetBuffer = exposureBufferRebalance;
        AllocationState memory allState = allocation.calcSystemTargetDelta(sysState, expState);
        _rebalance(allState);
    }

    function rebalanceForWithdraw(uint256 withdrawUsd, bool pwrd) external override returns (bool) {
        require(msg.sender == _controller().withdrawHandler(), "rebalanceForWithdraw: !withdrawHandler");
        return withdraw(withdrawUsd, pwrd);
    }

    function calcSkim() external view override returns (uint256) {
        IPnL pnl = IPnL(_controller().pnl());
        (uint256 gvt, uint256 pwrd) = pnl.calcPnL();
        uint256 totalAssets = gvt.add(pwrd);
        uint256 curveAssets = IVault(_controller().curveVault()).totalAssets();
        if (totalAssets != 0 && curveAssets.mul(PERCENTAGE_DECIMAL_FACTOR).div(totalAssets) >= curveVaultPercent) {
            return 0;
        }
        return curveVaultPercent;
    }

    function getStrategiesTargetRatio(uint256 utilRatio) external view override returns (uint256[] memory) {
        return allocation.calcStrategyPercent(utilRatio);
    }

    function prepareCalculation() public view returns (SystemState memory systemState) {
        ILifeGuard lg = getLifeGuard();
        IBuoy buoy = IBuoy(lg.getBuoy());
        require(buoy.safetyCheck());
        IVault curve = IVault(_controller().curveVault());
        systemState.lifeguardCurrentAssetsUsd = lg.totalAssetsUsd();
        systemState.curveCurrentAssetsUsd = buoy.lpToUsd(curve.totalAssets());
        systemState.totalCurrentAssetsUsd = systemState.lifeguardCurrentAssetsUsd.add(
            systemState.curveCurrentAssetsUsd
        );
        systemState.curvePercent = curveVaultPercent;
        address[N_COINS] memory vaults = _controller().vaults();
        
        for (uint256 i = 0; i < N_COINS; i++) {
            IVault vault = IVault(vaults[i]);
            uint256 vaultAssets = vault.totalAssets();
            uint256 vaultAssetsUsd = buoy.singleStableToUsd(vaultAssets, i);
            systemState.totalCurrentAssetsUsd = systemState.totalCurrentAssetsUsd.add(vaultAssetsUsd);
            systemState.vaultCurrentAssets[i] = vaultAssets;
            systemState.vaultCurrentAssetsUsd[i] = vaultAssetsUsd;
        }
        systemState.stablePercents = getStablePercents();
    }

    function withdraw(uint256 amount, bool pwrd) private returns (bool curve) {
        address[N_COINS] memory vaults = _controller().vaults();

        
        (uint256 withdrawType, uint256[N_COINS] memory withdrawalAmounts) = calculateWithdrawalAmountsOnPartVaults(
            amount,
            vaults
        );

        
        

        
        if (withdrawType > 1) {
            
            if (withdrawType == 2)
                withdrawalAmounts = calculateWithdrawalAmountsOnAllVaults(amount, vaults);
                
            else {
                
                for (uint256 i; i < N_COINS; i++) {
                    withdrawalAmounts[i] = IVault(vaults[i]).totalAssets();
                }
            }
        }
        ILifeGuard lg = getLifeGuard();
        for (uint256 i = 0; i < N_COINS; i++) {
            
            
            
            if (withdrawalAmounts[i] > 0) {
                IVault(vaults[i]).withdrawByStrategyOrder(withdrawalAmounts[i], address(lg), pwrd);
            }
        }

        if (withdrawType == 3) {
            
            
            
            IBuoy buoy = IBuoy(lg.getBuoy());
            uint256[N_COINS] memory _withdrawalAmounts;
            _withdrawalAmounts[0] = withdrawalAmounts[0];
            _withdrawalAmounts[1] = withdrawalAmounts[1];
            _withdrawalAmounts[2] = withdrawalAmounts[2];
            uint256 leftUsd = amount.sub(buoy.stableToUsd(_withdrawalAmounts, false));
            IVault curveVault = IVault(_controller().curveVault());
            uint256 curveVaultUsd = buoy.lpToUsd(curveVault.totalAssets());
            require(curveVaultUsd > leftUsd, "no enough system assets");
            curveVault.withdraw(buoy.usdToLp(leftUsd), address(lg));
            curve = true;
        }
    }

    function calculateWithdrawalAmountsOnPartVaults(uint256 amount, address[N_COINS] memory vaults)
        private
        view
        returns (uint256 withdrawType, uint256[N_COINS] memory withdrawalAmounts)
    {
        uint256 maxWithdrawal;
        uint256 leftAmount = amount;
        uint256 vaultIndex;
        (uint256 totalAssets, uint256[N_COINS] memory vaultAssets) = exposure.getUnifiedAssets(vaults);
        if (amount > totalAssets) {
            withdrawType = 3;
        } else {
            withdrawType = 2;
            
            uint256[N_COINS] memory vaultIndexes = exposure.sortVaultsByDelta(
                true,
                totalAssets,
                vaultAssets,
                getStablePercents()
            );

            IBuoy buoy = IBuoy(getLifeGuard().getBuoy());
            
            for (uint256 i; i < N_COINS - 1; i++) {
                vaultIndex = vaultIndexes[i];
                
                maxWithdrawal = vaultAssets[vaultIndex].mul(maxPercentForWithdraw).div(PERCENTAGE_DECIMAL_FACTOR);
                
                
                if (leftAmount > maxWithdrawal) {
                    withdrawalAmounts[vaultIndex] = buoy.singleStableFromUsd(maxWithdrawal, int128(vaultIndex));
                    leftAmount = leftAmount.sub(maxWithdrawal);
                    
                } else {
                    withdrawType = 1;
                    withdrawalAmounts[vaultIndex] = buoy.singleStableFromUsd(leftAmount, int128(vaultIndex));
                    break;
                }
            }
        }
    }

    function getDelta(uint256 withdrawUsd) external view override returns (uint256[N_COINS] memory delta) {
        address[N_COINS] memory vaults = _controller().vaults();
        delta = exposure.calcRoughDelta(getStablePercents(), vaults, withdrawUsd);
    }

    function calculateWithdrawalAmountsOnAllVaults(uint256 amount, address[N_COINS] memory vaults)
        private
        view
        returns (uint256[N_COINS] memory withdrawalAmounts)
    {
        
        bool simple = true;
        
        
        uint256[N_COINS] memory delta = exposure.calcRoughDelta(getStablePercents(), vaults, amount);
        for (uint256 i = 0; i < N_COINS; i++) {
            IVault vault = IVault(vaults[i]);
            withdrawalAmounts[i] = amount
            .mul(delta[i])
            .mul(uint256(10)**IERC20Detailed(vault.token()).decimals())
            .div(PERCENTAGE_DECIMAL_FACTOR)
            .div(DEFAULT_DECIMALS_FACTOR);
            if (withdrawalAmounts[i] > vault.totalAssets()) {
                simple = false;
                break;
            }
        }
        
        
        if (!simple) {
            (withdrawalAmounts, ) = calculateVaultSwapData(amount);
        }
    }

    function calculateVaultSwapData(uint256 withdrawAmount)
        private
        view
        returns (uint256[N_COINS] memory swapInAmounts, uint256[N_COINS] memory swapOutPercents)
    {
        
        SystemState memory state = prepareCalculation();

        require(withdrawAmount < state.totalCurrentAssetsUsd, "Withdrawal exceeds system assets");
        state.totalCurrentAssetsUsd = state.totalCurrentAssetsUsd.sub(withdrawAmount);

        StablecoinAllocationState memory stableState = allocation.calcVaultTargetDelta(state, false);
        swapInAmounts = stableState.swapInAmounts;
        swapOutPercents = stableState.swapOutPercents;
    }

    function getLifeGuard() private view returns (ILifeGuard) {
        return ILifeGuard(_controller().lifeGuard());
    }

    function _rebalance(AllocationState memory allState) private {
        address[N_COINS] memory vaults = _controller().vaults();
        ILifeGuard lg = getLifeGuard();
        IBuoy buoy = IBuoy(lg.getBuoy());
        
        if (allState.needProtocolWithdrawal) {
            for (uint256 i = 0; i < N_COINS; i++) {
                if (allState.protocolWithdrawalUsd[i] > 0) {
                    uint256 amount = buoy.singleStableFromUsd(allState.protocolWithdrawalUsd[i], int128(i));
                    IVault(vaults[i]).withdrawByStrategyIndex(
                        amount,
                        IVault(vaults[i]).vault(),
                        allState.protocolExposedIndex
                    );
                }
            }
        }

        bool hasWithdrawal = moveAssetsFromVaultsToLifeguard(
            vaults,
            allState.stableState.swapInAmounts,
            lg,
            allState.needProtocolWithdrawal ? 0 : allState.protocolExposedIndex,
            allState.strategyTargetRatio 
        );

        
        uint256 curveDeltaUsd = allState.stableState.curveTargetDeltaUsd;
        if (curveDeltaUsd > 0) {
            uint256 usdAmount = lg.totalAssetsUsd();
            
            
            
            
            
            
            lg.depositStable(true);
            if (usdAmount < curveDeltaUsd) {
                IVault(_controller().curveVault()).withdraw(buoy.usdToLp(curveDeltaUsd.sub(usdAmount)), address(lg));
            }
        }

        if (curveDeltaUsd == 0 && hasWithdrawal) lg.depositStable(false);

        
        
        for (uint256 i = 0; i < N_COINS; i++) {
            if (allState.stableState.swapOutPercents[i] > 0) {
                uint256[N_COINS] memory _swapOutPercents;
                _swapOutPercents[0] = allState.stableState.swapOutPercents[0];
                _swapOutPercents[1] = allState.stableState.swapOutPercents[1];
                _swapOutPercents[2] = allState.stableState.swapOutPercents[2];
                lg.invest(0, _swapOutPercents);
                break;
            }
        }
    }

    function moveAssetsFromVaultsToLifeguard(
        address[N_COINS] memory vaults,
        uint256[N_COINS] memory swapInAmounts,
        ILifeGuard lg,
        uint256 strategyIndex,
        uint256[] memory strategyTargetRatio
    ) private returns (bool) {
        bool moved = false;

        for (uint256 i = 0; i < N_COINS; i++) {
            IVault vault = IVault(vaults[i]);
            if (swapInAmounts[i] > 0) {
                moved = true;
                vault.withdrawByStrategyIndex(swapInAmounts[i], address(lg), strategyIndex);
            }
            vault.updateStrategyRatio(strategyTargetRatio);
        }

        return moved;
    }

    function getStablePercents() private view returns (uint256[N_COINS] memory stablePercents) {
        for (uint256 i = 0; i < N_COINS; i++) {
            stablePercents[i] = underlyingTokensPercents[i];
        }
    }
}