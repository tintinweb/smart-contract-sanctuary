/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/math/SafeMath.sol



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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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



pragma solidity ^0.6.0;




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

// File: contracts/interfaces/maker/IMakerDAO.sol



pragma solidity 0.6.12;

interface ManagerLike {
    function cdpCan(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function ilks(uint256) external view returns (bytes32);

    function owns(uint256) external view returns (address);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);

    function open(bytes32, address) external returns (uint256);

    function give(uint256, address) external;

    function cdpAllow(
        uint256,
        address,
        uint256
    ) external;

    function urnAllow(address, uint256) external;

    function frob(
        uint256,
        int256,
        int256
    ) external;

    function flux(
        uint256,
        address,
        uint256
    ) external;

    function move(
        uint256,
        address,
        uint256
    ) external;

    function exit(
        address,
        uint256,
        address,
        uint256
    ) external;

    function quit(uint256, address) external;

    function enter(address, uint256) external;

    function shift(uint256, uint256) external;
}

interface VatLike {
    function can(address, address) external view returns (uint256);

    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function frob(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) external;

    function hope(address) external;

    function nope(address) external;

    function move(
        address,
        address,
        uint256
    ) external;
}

interface GemJoinLike {
    function dec() external view returns (uint256);

    function gem() external view returns (address);

    function ilk() external view returns (bytes32);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

interface DaiJoinLike {
    function vat() external returns (VatLike);

    function dai() external view returns (address);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint256);
}

interface SpotterLike {
    function ilks(bytes32) external view returns (address, uint256);
}

// File: contracts/interfaces/vesper/ICollateralManager.sol



pragma solidity 0.6.12;

interface ICollateralManager {
    function addGemJoin(address[] calldata gemJoins) external;

    function mcdManager() external view returns (address);

    function borrow(uint256 vaultNum, uint256 amount) external;

    function depositCollateral(uint256 vaultNum, uint256 amount) external;

    function getVaultBalance(uint256 vaultNum) external view returns (uint256 collateralLocked);

    function getVaultDebt(uint256 vaultNum) external view returns (uint256 daiDebt);

    function getVaultInfo(uint256 vaultNum)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );

    function payback(uint256 vaultNum, uint256 amount) external;

    function registerVault(uint256 vaultNum, bytes32 collateralType) external;

    function vaultOwner(uint256 vaultNum) external returns (address owner);

    function whatWouldWithdrawDo(uint256 vaultNum, uint256 amount)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );

    function withdrawCollateral(uint256 vaultNum, uint256 amount) external;
}

// File: contracts/interfaces/vesper/IController.sol



pragma solidity 0.6.12;

interface IController {
    function aaveReferralCode() external view returns (uint16);

    function feeCollector(address) external view returns (address);

    function founderFee() external view returns (uint256);

    function founderVault() external view returns (address);

    function interestFee(address) external view returns (uint256);

    function isPool(address) external view returns (bool);

    function pools() external view returns (address);

    function strategy(address) external view returns (address);

    function rebalanceFriction(address) external view returns (uint256);

    function poolRewards(address) external view returns (address);

    function treasuryPool() external view returns (address);

    function uniswapRouter() external view returns (address);

    function withdrawFee(address) external view returns (uint256);
}

// File: contracts/strategies/CollateralManager.sol



pragma solidity 0.6.12;







contract DSMath {
    uint256 internal constant RAY = 10**27;
    uint256 internal constant WAD = 10**18;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = mul(wad, RAY);
    }

    /**
     * @notice It will work only if _dec < 18
     */
    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }
}

contract CollateralManager is ICollateralManager, DSMath, ReentrancyGuard {
    using SafeERC20 for IERC20;
    mapping(uint256 => address) public override vaultOwner;
    mapping(bytes32 => address) public mcdGemJoin;
    mapping(uint256 => bytes32) public vaultType;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public override mcdManager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public mcdDaiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public mcdSpot = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public mcdJug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    uint256 internal constant MAX_UINT_VALUE = uint256(-1);
    IController public immutable controller;

    modifier onlyVaultOwner(uint256 vaultNum) {
        require(msg.sender == vaultOwner[vaultNum], "Not a vault owner");
        _;
    }

    modifier onlyController() {
        require(msg.sender == address(controller), "Not a controller");
        _;
    }

    constructor(address _controller) public {
        require(_controller != address(0), "_controller is zero");
        controller = IController(_controller);
    }

    /**
     * @dev Add gemJoin adapter address from Maker in mapping
     * @param gemJoins Array of gem join addresses
     */
    function addGemJoin(address[] calldata gemJoins) external override onlyController {
        require(gemJoins.length != 0, "No gemJoin address");
        for (uint256 i; i < gemJoins.length; i++) {
            address gemJoin = gemJoins[i];
            bytes32 ilk = GemJoinLike(gemJoin).ilk();
            mcdGemJoin[ilk] = gemJoin;
        }
    }

    /**
     * @dev Store vault info.
     * @param vaultNum Vault number.
     * @param collateralType Collateral type of vault.
     */
    function registerVault(uint256 vaultNum, bytes32 collateralType) external override {
        require(msg.sender == ManagerLike(mcdManager).owns(vaultNum), "Not a vault owner");
        vaultOwner[vaultNum] = msg.sender;
        vaultType[vaultNum] = collateralType;
    }

    /**
     * @dev Update MCD addresses.
     */
    function updateMCDAddresses(
        address _mcdManager,
        address _mcdDaiJoin,
        address _mcdSpot,
        address _mcdJug
    ) external onlyController {
        mcdManager = _mcdManager;
        mcdDaiJoin = _mcdDaiJoin;
        mcdSpot = _mcdSpot;
        mcdJug = _mcdJug;
    }

    /**
     * @dev Deposit ERC20 collateral.
     * @param vaultNum Vault number.
     * @param amount ERC20 amount to deposit.
     */
    function depositCollateral(uint256 vaultNum, uint256 amount)
        external
        override
        nonReentrant
        onlyVaultOwner(vaultNum)
    {
        // Receives Gem amount, approve and joins it into the vat.
        // Also convert amount to 18 decimal
        amount = joinGem(mcdGemJoin[vaultType[vaultNum]], amount);

        ManagerLike manager = ManagerLike(mcdManager);
        // Locks Gem amount into the CDP
        VatLike(manager.vat()).frob(
            vaultType[vaultNum],
            manager.urns(vaultNum),
            address(this),
            address(this),
            toInt(amount),
            0
        );
    }

    /**
     * @dev Withdraw collateral.
     * @param vaultNum Vault number.
     * @param amount Collateral amount to withdraw.
     */
    function withdrawCollateral(uint256 vaultNum, uint256 amount)
        external
        override
        nonReentrant
        onlyVaultOwner(vaultNum)
    {
        ManagerLike manager = ManagerLike(mcdManager);
        GemJoinLike gemJoin = GemJoinLike(mcdGemJoin[vaultType[vaultNum]]);

        uint256 amount18 = convertTo18(gemJoin.dec(), amount);

        // Unlocks Gem amount18 from the CDP
        manager.frob(vaultNum, -toInt(amount18), 0);

        // Moves Gem amount18 from the CDP urn to this address
        manager.flux(vaultNum, address(this), amount18);

        // Exits Gem amount to this address as a token
        gemJoin.exit(address(this), amount);

        // Send Gem to pool's address
        IERC20(gemJoin.gem()).safeTransfer(vaultOwner[vaultNum], amount);
    }

    /**
     * @dev Payback borrowed DAI.
     * @param vaultNum Vault number.
     * @param amount Dai amount to payback.
     */
    function payback(uint256 vaultNum, uint256 amount) external override onlyVaultOwner(vaultNum) {
        ManagerLike manager = ManagerLike(mcdManager);
        address urn = manager.urns(vaultNum);
        address vat = manager.vat();
        bytes32 ilk = vaultType[vaultNum];

        // Calculate dai debt
        uint256 _daiDebt = _getVaultDebt(ilk, urn, vat);
        require(_daiDebt >= amount, "paying-excess-debt");

        // Approve and join dai in vat
        joinDai(urn, amount);
        manager.frob(vaultNum, 0, _getWipeAmount(ilk, urn, vat));
    }

    /**
     * @notice Borrow DAI.
     * @dev In edge case, when we hit DAI mint limit, we might end up borrowing
     * less than what is being asked.
     * @param vaultNum Vault number.
     * @param amount Dai amount to borrow. Actual borrow amount may be less than "amount"
     */
    function borrow(uint256 vaultNum, uint256 amount) external override onlyVaultOwner(vaultNum) {
        ManagerLike manager = ManagerLike(mcdManager);
        address vat = manager.vat();
        // Safety check in scenario where current debt and request borrow will exceed max dai limit
        uint256 _maxAmount = maxAvailableDai(vat, vaultNum);
        if (amount > _maxAmount) {
            amount = _maxAmount;
        }

        // Generates debt in the CDP
        manager.frob(vaultNum, 0, _getBorrowAmount(vat, manager.urns(vaultNum), vaultNum, amount));
        // Moves the DAI amount (balance in the vat in rad) to pool's address
        manager.move(vaultNum, address(this), toRad(amount));
        // Allows adapter to access to pool's DAI balance in the vat
        if (VatLike(vat).can(address(this), mcdDaiJoin) == 0) {
            VatLike(vat).hope(mcdDaiJoin);
        }
        // Exits DAI as a token to user's address
        DaiJoinLike(mcdDaiJoin).exit(msg.sender, amount);
    }

    /// @dev sweep given ERC20 token to treasury pool
    function sweepErc20(address fromToken) external {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        address treasuryPool = controller.treasuryPool();
        IERC20(fromToken).safeTransfer(treasuryPool, amount);
    }

    /**
     * @dev Get current dai debt of vault.
     * @param vaultNum Vault number.
     */
    function getVaultDebt(uint256 vaultNum) external view override returns (uint256 daiDebt) {
        address urn = ManagerLike(mcdManager).urns(vaultNum);
        address vat = ManagerLike(mcdManager).vat();
        bytes32 ilk = vaultType[vaultNum];

        daiDebt = _getVaultDebt(ilk, urn, vat);
    }

    /**
     * @dev Get current collateral balance of vault.
     * @param vaultNum Vault number.
     */
    function getVaultBalance(uint256 vaultNum)
        external
        view
        override
        returns (uint256 collateralLocked)
    {
        address vat = ManagerLike(mcdManager).vat();
        address urn = ManagerLike(mcdManager).urns(vaultNum);
        (collateralLocked, ) = VatLike(vat).urns(vaultType[vaultNum], urn);
    }

    /**
     * @dev Calculate state based on withdraw amount.
     * @param vaultNum Vault number.
     * @param amount Collateral amount to withraw.
     */
    function whatWouldWithdrawDo(uint256 vaultNum, uint256 amount)
        external
        view
        override
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        )
    {
        (collateralLocked, daiDebt, collateralUsdRate, collateralRatio, minimumDebt) = getVaultInfo(
            vaultNum
        );

        GemJoinLike gemJoin = GemJoinLike(mcdGemJoin[vaultType[vaultNum]]);
        uint256 amount18 = convertTo18(gemJoin.dec(), amount);
        require(amount18 <= collateralLocked, "insufficient collateral locked");
        collateralLocked = sub(collateralLocked, amount18);
        collateralRatio = getCollateralRatio(collateralLocked, collateralUsdRate, daiDebt);
    }

    /**
     * @dev Get vault info
     * @param vaultNum Vault number.
     */
    function getVaultInfo(uint256 vaultNum)
        public
        view
        override
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        )
    {
        (collateralLocked, collateralUsdRate, daiDebt, minimumDebt) = _getVaultInfo(vaultNum);
        collateralRatio = getCollateralRatio(collateralLocked, collateralUsdRate, daiDebt);
    }

    /**
     * @dev Get available DAI amount based on current DAI debt and limit for given vault type.
     * @param vat Vat address
     * @param vaultNum Vault number.
     */
    function maxAvailableDai(address vat, uint256 vaultNum) public view returns (uint256) {
        // Get stable coin Art(debt) [wad], rate [ray], line [rad]
        //solhint-disable-next-line var-name-mixedcase
        (uint256 Art, uint256 rate, , uint256 line, ) = VatLike(vat).ilks(vaultType[vaultNum]);
        // Calculate total issued debt is Art * rate [rad]
        // Calcualte total available dai [wad]
        uint256 _totalAvailableDai = sub(line, mul(Art, rate)) / RAY;
        // For safety reason, return 99% of available
        return mul(_totalAvailableDai, 99) / 100;
    }

    function joinDai(address urn, uint256 amount) internal {
        DaiJoinLike daiJoin = DaiJoinLike(mcdDaiJoin);
        // Transfer Dai from strategy or pool to here
        IERC20(DAI).safeTransferFrom(msg.sender, address(this), amount);
        // Approves adapter to move dai.
        IERC20(DAI).safeApprove(mcdDaiJoin, 0);
        IERC20(DAI).safeApprove(mcdDaiJoin, amount);
        // Joins DAI into the vat
        daiJoin.join(urn, amount);
    }

    function joinGem(address adapter, uint256 amount) internal returns (uint256) {
        GemJoinLike gemJoin = GemJoinLike(adapter);

        IERC20 token = IERC20(gemJoin.gem());
        // Transfer token from strategy or pool to here
        token.safeTransferFrom(msg.sender, address(this), amount);
        // Approves adapter to take the Gem amount
        token.safeApprove(adapter, 0);
        token.safeApprove(adapter, amount);
        // Joins Gem collateral into the vat
        gemJoin.join(address(this), amount);
        // Convert amount to 18 decimal
        return convertTo18(gemJoin.dec(), amount);
    }

    /**
     * @dev Get borrow dai amount.
     */
    function _getBorrowAmount(
        address vat,
        address urn,
        uint256 vaultNum,
        uint256 wad
    ) internal returns (int256 amount) {
        // Updates stability fee rate
        uint256 rate = JugLike(mcdJug).drip(vaultType[vaultNum]);

        // Gets DAI balance of the urn in the vat
        uint256 dai = VatLike(vat).dai(urn);

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < mul(wad, RAY)) {
            // Calculates the needed amt so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            amount = toInt(sub(mul(wad, RAY), dai) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra amt wei (for the given DAI wad amount)
            amount = mul(uint256(amount), rate) < mul(wad, RAY) ? amount + 1 : amount;
        }
    }

    /**
     * @dev Get collateral ratio
     */
    function getCollateralRatio(
        uint256 collateralLocked,
        uint256 collateralRate,
        uint256 daiDebt
    ) internal pure returns (uint256) {
        if (collateralLocked == 0) {
            return 0;
        }

        if (daiDebt == 0) {
            return MAX_UINT_VALUE;
        }

        require(collateralRate != 0, "Collateral rate is zero");
        return wdiv(wmul(collateralLocked, collateralRate), daiDebt);
    }

    /**
     * @dev Get Vault Debt Amount.
     */
    function _getVaultDebt(
        bytes32 ilk,
        address urn,
        address vat
    ) internal view returns (uint256 wad) {
        // Get normalised debt [wad]
        (, uint256 art) = VatLike(vat).urns(ilk, urn);
        // Get stable coin rate [ray]
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Get balance from vat [rad]
        uint256 dai = VatLike(vat).dai(urn);

        wad = _getVaultDebt(art, rate, dai);
    }

    function _getVaultDebt(
        uint256 art,
        uint256 rate,
        uint256 dai
    ) internal pure returns (uint256 wad) {
        if (dai < mul(art, rate)) {
            uint256 rad = sub(mul(art, rate), dai);
            wad = rad / RAY;
            wad = mul(wad, RAY) < rad ? wad + 1 : wad;
        } else {
            wad = 0;
        }
    }

    function _getVaultInfo(uint256 vaultNum)
        internal
        view
        returns (
            uint256 collateralLocked,
            uint256 collateralUsdRate,
            uint256 daiDebt,
            uint256 minimumDebt
        )
    {
        address urn = ManagerLike(mcdManager).urns(vaultNum);
        address vat = ManagerLike(mcdManager).vat();
        bytes32 ilk = vaultType[vaultNum];

        // Get minimum liquidation ratio [ray]
        (, uint256 mat) = SpotterLike(mcdSpot).ilks(ilk);

        // Get collateral locked and normalised debt [wad] [wad]
        (uint256 ink, uint256 art) = VatLike(vat).urns(ilk, urn);
        // Get stable coin and collateral rate  and min debt [ray] [ray] [rad]
        (, uint256 rate, uint256 spot, , uint256 dust) = VatLike(vat).ilks(ilk);
        // Get balance from vat [rad]

        collateralLocked = ink;
        daiDebt = _getVaultDebt(art, rate, VatLike(vat).dai(urn));
        minimumDebt = dust / RAY;
        // Calculate collateral rate in 18 decimals
        collateralUsdRate = rmul(mat, spot) / 10**9;
    }

    /**
     * @dev Get Payback amount.
     * @notice We need to fetch latest art, rate and dai to calcualte payback amount.
     */
    function _getWipeAmount(
        bytes32 ilk,
        address urn,
        address vat
    ) internal view returns (int256 amount) {
        // Get normalize debt, rate and dai balance from Vat
        (, uint256 art) = VatLike(vat).urns(ilk, urn);
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        uint256 dai = VatLike(vat).dai(urn);

        // Uses the whole dai balance in the vat to reduce the debt
        amount = toInt(dai / rate);
        // Checks the calculated amt is not higher than urn.art (total debt), otherwise uses its value
        amount = uint256(amount) <= art ? -amount : -toInt(art);
    }
}