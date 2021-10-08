// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveAaveConstants} from "./Constants.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

contract AavePoolZap is CurveGaugeZapBase, CurveAaveConstants {
    string internal constant AAVE_ALLOCATION = "aave";

    constructor()
        public
        CurveGaugeZapBase(
            STABLE_SWAP_ADDRESS,
            LP_TOKEN_ADDRESS,
            LIQUIDITY_GAUGE_ADDRESS,
            10000,
            100,
            3
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](2);
        allocationNames[0] = NAME;
        allocationNames[1] = AAVE_ALLOCATION;
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = _createErc20AllocationArray(0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return IStableSwap(SWAP_ADDRESS).get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return IStableSwap(SWAP_ADDRESS).underlying_coins(i);
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        IStableSwap(SWAP_ADDRESS).add_liquidity(
            [amounts[0], amounts[1], amounts[2]],
            minAmount,
            true
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        require(index < 3, "INVALID_INDEX");
        IStableSwap(SWAP_ADDRESS).remove_liquidity_one_coin(
            lpBalance,
            index,
            minAmount,
            true
        );
    }

    /**
     * @dev claim protocol-specific rewards; stkAAVE in this case.
     *      CRV rewards are always claimed through the minter, in
     *      the `CurveBasePoolGauge` implementation.
     */
    function _claimRewards() internal override {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        liquidityGauge.claim_rewards();
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IDetailedERC20} from "./IDetailedERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {AccessControl} from "./AccessControl.sol";
import {INameIdentifier} from "./INameIdentifier.sol";
import {IAssetAllocation} from "./IAssetAllocation.sol";
import {IEmergencyExit} from "./IEmergencyExit.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {CTokenInterface} from "./CTokenInterface.sol";
import {ITokenMinter} from "./ITokenMinter.sol";
import {IStableSwap, IStableSwap3} from "./IStableSwap.sol";
import {IStableSwap2} from "./IStableSwap2.sol";
import {IStableSwap4} from "./IStableSwap4.sol";
import {IOldStableSwap2} from "./IOldStableSwap2.sol";
import {IOldStableSwap4} from "./IOldStableSwap4.sol";
import {ILiquidityGauge} from "./ILiquidityGauge.sol";
import {IStakingRewards} from "./IStakingRewards.sol";
import {IDepositZap} from "./IDepositZap.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveAaveConstants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-aave";

    address public constant STABLE_SWAP_ADDRESS =
        0xDeBF20617708857ebe4F679508E7b7863a8A8EeE;
    address public constant LP_TOKEN_ADDRESS =
        0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xd662908ADA2Ea1916B3318327A97eB18aD588b5d;

    address public constant STKAAVE_ADDRESS =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant ADAI_ADDRESS =
        0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address public constant AUSDC_ADDRESS =
        0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address public constant AUSDT_ADDRESS =
        0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {
    CurveAllocationBase,
    CurveAllocationBase3
} from "./CurveAllocationBase.sol";
import {CurveAllocationBase2} from "./CurveAllocationBase2.sol";
import {CurveAllocationBase4} from "./CurveAllocationBase4.sol";
import {CurveGaugeZapBase} from "./CurveGaugeZapBase.sol";
import {CurveZapBase} from "./CurveZapBase.sol";
import {OldCurveAllocationBase2} from "./OldCurveAllocationBase2.sol";
import {OldCurveAllocationBase4} from "./OldCurveAllocationBase4.sol";
import {TestCurveZap} from "./TestCurveZap.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.11;

import {
    AccessControl as OZAccessControl
} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @notice Extends OpenZeppelin AccessControl contract with modifiers
 * @dev This contract and AccessControlUpgradeSafe are essentially duplicates.
 */
contract AccessControl is OZAccessControl {
    /** @notice access control roles **/
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    modifier onlyLpRole() {
        require(hasRole(LP_ROLE, _msgSender()), "NOT_LP_ROLE");
        _;
    }

    modifier onlyContractRole() {
        require(hasRole(CONTRACT_ROLE, _msgSender()), "NOT_CONTRACT_ROLE");
        _;
    }

    modifier onlyAdminRole() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN_ROLE");
        _;
    }

    modifier onlyEmergencyRole() {
        require(hasRole(EMERGENCY_ROLE, _msgSender()), "NOT_EMERGENCY_ROLE");
        _;
    }

    modifier onlyLpOrContractRole() {
        require(
            hasRole(LP_ROLE, _msgSender()) ||
                hasRole(CONTRACT_ROLE, _msgSender()),
            "NOT_LP_OR_CONTRACT_ROLE"
        );
        _;
    }

    modifier onlyAdminOrContractRole() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
                hasRole(CONTRACT_ROLE, _msgSender()),
            "NOT_ADMIN_OR_CONTRACT_ROLE"
        );
        _;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice Used by the `NamedAddressSet` library to store sets of contracts
 */
interface INameIdentifier {
    /// @notice Should be implemented as a constant value
    // solhint-disable-next-line func-name-mixedcase
    function NAME() external view returns (string memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {INameIdentifier} from "./INameIdentifier.sol";

/**
 * @notice For use with the `TvlManager` to track the value locked in a protocol
 */
interface IAssetAllocation is INameIdentifier {
    struct TokenData {
        address token;
        string symbol;
        uint8 decimals;
    }

    /**
     * @notice Get data for the underlying tokens stored in the protocol
     * @return The array of `TokenData`
     */
    function tokens() external view returns (TokenData[] memory);

    /**
     * @notice Get the number of different tokens stored in the protocol
     * @return The number of tokens
     */
    function numberOfTokens() external view returns (uint256);

    /**
     * @notice Get an account's balance for a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param account The account to get the balance for
     * @param tokenIndex The index of the token to get the balance for
     * @return The account's balance
     */
    function balanceOf(address account, uint8 tokenIndex)
        external
        view
        returns (uint256);

    /**
     * @notice Get the symbol of a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param tokenIndex The index of the token
     * @return The symbol of the token
     */
    function symbolOf(uint8 tokenIndex) external view returns (string memory);

    /**
     * @notice Get the decimals of a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param tokenIndex The index of the token
     * @return The decimals of the token
     */
    function decimalsOf(uint8 tokenIndex) external view returns (uint8);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20} from "./Imports.sol";

/**
 * @notice Used for contracts that need an emergency escape hatch
 * @notice Should only be used in an emergency to keep funds safu
 */
interface IEmergencyExit {
    /**
     * @param emergencySafe The address the tokens were escaped to
     * @param token The token escaped
     * @param balance The amount of tokens escaped
     */
    event EmergencyExit(address emergencySafe, IERC20 token, uint256 balance);

    /**
     * @notice Transfer all tokens to the emergency Safe
     * @dev Should only be callable by the emergency Safe
     * @dev Should only transfer tokens to the emergency Safe
     * @param token The token to transfer
     */
    function emergencyExit(address token) external;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: BSD 3-Clause
/*
 * https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
 */
pragma solidity 0.6.11;

interface CTokenInterface {
    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function totalSupply() external returns (uint256);

    function isCToken() external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/**
 * @notice the Curve token minter
 * @author Curve Finance
 * @dev translated from vyper
 * license MIT
 * version 0.2.4
 */

// solhint-disable func-name-mixedcase, func-param-name-mixedcase
interface ITokenMinter {
    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge_addr `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge_addr) external;

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gauge_addrs List of `LiquidityGauge` addresses
     */
    function mint_many(address[8] calldata gauge_addrs) external;

    /**
     * @notice Mint tokens for `_for`
     * @dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
     * @param gauge_addr `LiquidityGauge` address to get mintable amount from
     * @param _for Address to mint to
     */
    function mint_for(address gauge_addr, address _for) external;

    /**
     * @notice allow `minting_user` to mint for `msg.sender`
     * @param minting_user Address to toggle permission for
     */
    function toggle_approve_mint(address minting_user) external;
}
// solhint-enable

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IStableSwap {
    function balances(uint256 coin) external view returns (uint256);

    function coins(uint256 coin) external view returns (address);

    // solhint-disable-next-line
    function underlying_coins(uint256 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    // solhint-disable-next-line
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 minMinAmount,
        bool useUnderlyer
    ) external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount,
        bool useUnderlyer
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);

    /**
     * @dev For newest curve pools like aave; older pools refer to a private `token` variable.
     */
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// solhint-disable-next-line no-empty-blocks
interface IStableSwap3 is IStableSwap {

}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IStableSwap2 {
    function balances(uint256 coin) external view returns (uint256);

    function coins(uint256 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);

    /**
     * @dev For newest curve pools like aave; older pools refer to a private `token` variable.
     */
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IStableSwap4 {
    function balances(uint256 coin) external view returns (uint256);

    function coins(uint256 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[4] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);

    /**
     * @dev For newest curve pools like aave; older pools refer to a private `token` variable.
     */
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IOldStableSwap2 {
    function balances(int128 coin) external view returns (uint256);

    function coins(int128 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    /// @dev need this due to lack of `remove_liquidity_one_coin`
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy // solhint-disable-line func-param-name-mixedcase
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);

    /**
     * @dev For newest curve pools like aave; older pools refer to a private `token` variable.
     */
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IOldStableSwap4 {
    function balances(int128 coin) external view returns (uint256);

    function coins(int128 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[4] memory min_amounts)
        external;

    /// @dev need this due to lack of `remove_liquidity_one_coin`
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy // solhint-disable-line func-param-name-mixedcase
    ) external;

    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the liquidity gauge, i.e. staking contract, for the stablecoin pool
 */
interface ILiquidityGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    /**
     * @notice Claim available reward tokens for msg.sender
     */
    // solhint-disable-next-line func-name-mixedcase
    function claim_rewards() external;

    /**
     * @notice Get the number of claimable reward tokens for a user
     * @dev This function should be manually changed to "view" in the ABI
     *      Calling it via a transaction will claim available reward tokens
     * @param _addr Account to get reward amount for
     * @param _token Token to get reward amount for
     * @return uint256 Claimable reward token amount
     */
    // solhint-disable-next-line func-name-mixedcase
    function claimable_reward(address _addr, address _token)
        external
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/*
 * Synthetix: StakingRewards.sol
 *
 * Docs: https://docs.synthetix.io/
 *
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2020 Synthetix
 *
 */

interface IStakingRewards {
    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-2.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the stablecoin pool contract
 */
interface IDepositZap {
    // this method only exists on the DepositCompound Contract
    // solhint-disable-next-line
    function underlying_coins(int128 coin) external view returns (address);

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    /**
     * @dev the number of coins is hard-coded in curve contracts
     */
    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 _amount,
        int128 i,
        uint256 minAmount
    ) external;

    function curve() external view returns (address);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract Curve3PoolUnderlyerConstants {
    // underlyer addresses
    address public constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
}

abstract contract Curve3PoolConstants is
    Curve3PoolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-3pool";

    address public constant STABLE_SWAP_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant LP_TOKEN_ADDRESS =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurveAllocationBase {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// solhint-disable-next-line no-empty-blocks
contract CurveAllocationBase3 is CurveAllocationBase {

}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap2,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurveAllocationBase2 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap2 stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap4,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurveAllocationBase4 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap4 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap4 stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap4 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IZap} from "contracts/lpaccount/Imports.sol";
import {
    IAssetAllocation,
    IERC20,
    IDetailedERC20
} from "contracts/common/Imports.sol";
import {SafeERC20} from "contracts/libraries/Imports.sol";
import {
    ILiquidityGauge,
    ITokenMinter
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveZapBase} from "contracts/protocols/curve/common/CurveZapBase.sol";

abstract contract CurveGaugeZapBase is IZap, CurveZapBase {
    using SafeERC20 for IERC20;

    address internal constant MINTER_ADDRESS =
        0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    address internal immutable LP_ADDRESS;
    address internal immutable GAUGE_ADDRESS;

    constructor(
        address swapAddress,
        address lpAddress,
        address gaugeAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 nCoins
    )
        public
        CurveZapBase(swapAddress, denominator, slippage, nCoins)
    // solhint-disable-next-line no-empty-blocks
    {
        LP_ADDRESS = lpAddress;
        GAUGE_ADDRESS = gaugeAddress;
    }

    function _depositToGauge() internal override {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        uint256 lpBalance = IERC20(LP_ADDRESS).balanceOf(address(this));
        IERC20(LP_ADDRESS).safeApprove(GAUGE_ADDRESS, 0);
        IERC20(LP_ADDRESS).safeApprove(GAUGE_ADDRESS, lpBalance);
        liquidityGauge.deposit(lpBalance);
    }

    function _withdrawFromGauge(uint256 amount)
        internal
        override
        returns (uint256)
    {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        liquidityGauge.withdraw(amount);
        //lpBalance
        return IERC20(LP_ADDRESS).balanceOf(address(this));
    }

    function _claim() internal override {
        // claim CRV
        ITokenMinter(MINTER_ADDRESS).mint(GAUGE_ADDRESS);

        // claim protocol-specific rewards
        _claimRewards();
    }

    // solhint-disable-next-line no-empty-blocks
    function _claimRewards() internal virtual {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath, SafeERC20} from "contracts/libraries/Imports.sol";
import {IZap} from "contracts/lpaccount/Imports.sol";
import {
    IAssetAllocation,
    IDetailedERC20,
    IERC20
} from "contracts/common/Imports.sol";
import {
    Curve3PoolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveZapBase is Curve3PoolUnderlyerConstants, IZap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address internal constant CRV_ADDRESS =
        0xD533a949740bb3306d119CC777fa900bA034cd52;

    address internal immutable SWAP_ADDRESS;
    uint256 internal immutable DENOMINATOR;
    uint256 internal immutable SLIPPAGE;
    uint256 internal immutable N_COINS;

    constructor(
        address swapAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 nCoins
    ) public {
        SWAP_ADDRESS = swapAddress;
        DENOMINATOR = denominator;
        SLIPPAGE = slippage;
        N_COINS = nCoins;
    }

    /// @param amounts array of underlyer amounts
    function deployLiquidity(uint256[] calldata amounts) external override {
        require(amounts.length == N_COINS, "INVALID_AMOUNTS");

        uint256 totalNormalizedDeposit = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;

            uint256 deposit = amounts[i];
            address underlyerAddress = _getCoinAtIndex(i);
            uint8 decimals = IDetailedERC20(underlyerAddress).decimals();

            uint256 normalizedDeposit =
                deposit.mul(10**uint256(18)).div(10**uint256(decimals));
            totalNormalizedDeposit = totalNormalizedDeposit.add(
                normalizedDeposit
            );

            IERC20(underlyerAddress).safeApprove(SWAP_ADDRESS, 0);
            IERC20(underlyerAddress).safeApprove(SWAP_ADDRESS, amounts[i]);
        }

        uint256 minAmount =
            _calcMinAmount(totalNormalizedDeposit, _getVirtualPrice());
        _addLiquidity(amounts, minAmount);
        _depositToGauge();
    }

    /**
     * @param amount LP token amount
     * @param index underlyer index
     */
    function unwindLiquidity(uint256 amount, uint8 index) external override {
        require(index < N_COINS, "INVALID_INDEX");
        uint256 lpBalance = _withdrawFromGauge(amount);
        address underlyerAddress = _getCoinAtIndex(index);
        uint8 decimals = IDetailedERC20(underlyerAddress).decimals();
        uint256 minAmount =
            _calcMinAmountUnderlyer(lpBalance, _getVirtualPrice(), decimals);
        _removeLiquidity(lpBalance, index, minAmount);
    }

    function claim() external override {
        _claim();
    }

    function sortedSymbols() public view override returns (string[] memory) {
        // N_COINS is not available as a public function
        // so we have to hardcode the number here
        string[] memory symbols = new string[](N_COINS);
        for (uint256 i = 0; i < symbols.length; i++) {
            address underlyerAddress = _getCoinAtIndex(i);
            symbols[i] = IDetailedERC20(underlyerAddress).symbol();
        }
        return symbols;
    }

    function _getVirtualPrice() internal view virtual returns (uint256);

    function _getCoinAtIndex(uint256 i) internal view virtual returns (address);

    function _addLiquidity(uint256[] calldata amounts_, uint256 minAmount)
        internal
        virtual;

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal virtual;

    function _depositToGauge() internal virtual;

    function _withdrawFromGauge(uint256 amount)
        internal
        virtual
        returns (uint256);

    function _claim() internal virtual;

    /**
     * @dev normalizedDepositAmount the amount in same units as virtual price (18 decimals)
     * @dev virtualPrice the "price", in 18 decimals, per big token unit of the LP token
     * @return required minimum amount of LP token (in token wei)
     */
    function _calcMinAmount(
        uint256 normalizedDepositAmount,
        uint256 virtualPrice
    ) internal view returns (uint256) {
        uint256 idealLpTokenAmount =
            normalizedDepositAmount.mul(1e18).div(virtualPrice);
        // allow some slippage/MEV
        return
            idealLpTokenAmount.mul(DENOMINATOR.sub(SLIPPAGE)).div(DENOMINATOR);
    }

    /**
     * @param lpTokenAmount the amount in the same units as Curve LP token (18 decimals)
     * @param virtualPrice the "price", in 18 decimals, per big token unit of the LP token
     * @param decimals the number of decimals for underlyer token
     * @return required minimum amount of underlyer (in token wei)
     */
    function _calcMinAmountUnderlyer(
        uint256 lpTokenAmount,
        uint256 virtualPrice,
        uint8 decimals
    ) internal view returns (uint256) {
        // TODO: grab LP Token decimals explicitly?
        uint256 normalizedUnderlyerAmount =
            lpTokenAmount.mul(virtualPrice).div(1e18);
        uint256 underlyerAmount =
            normalizedUnderlyerAmount.mul(10**uint256(decimals)).div(
                10**uint256(18)
            );

        // allow some slippage/MEV
        return underlyerAmount.mul(DENOMINATOR.sub(SLIPPAGE)).div(DENOMINATOR);
    }

    function _createErc20AllocationArray(uint256 extraAllocations)
        internal
        pure
        returns (IERC20[] memory)
    {
        IERC20[] memory allocations = new IERC20[](extraAllocations.add(4));
        allocations[0] = IERC20(CRV_ADDRESS);
        allocations[1] = IERC20(DAI_ADDRESS);
        allocations[2] = IERC20(USDC_ADDRESS);
        allocations[3] = IERC20(USDT_ADDRESS);
        return allocations;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IOldStableSwap2,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract OldCurveAllocationBase2 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IOldStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        int128 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IOldStableSwap2 stableSwap, int128 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IOldStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IOldStableSwap4,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract OldCurveAllocationBase4 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IOldStableSwap4 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        int128 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IOldStableSwap4 stableSwap, int128 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IOldStableSwap4 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {
    CurveGaugeZapBase
} from "contracts/protocols/curve/common/CurveGaugeZapBase.sol";

contract TestCurveZap is CurveGaugeZapBase {
    string public constant override NAME = "TestCurveZap";

    address[] private _underlyers;

    constructor(
        address swapAddress,
        address lpTokenAddress,
        address liquidityGaugeAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 numOfCoins
    )
        public
        CurveGaugeZapBase(
            swapAddress,
            lpTokenAddress,
            liquidityGaugeAddress,
            denominator,
            slippage,
            numOfCoins
        ) // solhint-disable-next-line no-empty-blocks
    {}

    function setUnderlyers(address[] calldata underlyers) external {
        _underlyers = underlyers;
    }

    function getSwapAddress() external view returns (address) {
        return SWAP_ADDRESS;
    }

    function getLpTokenAddress() external view returns (address) {
        return address(LP_ADDRESS);
    }

    function getGaugeAddress() external view returns (address) {
        return GAUGE_ADDRESS;
    }

    function getDenominator() external view returns (uint256) {
        return DENOMINATOR;
    }

    function getSlippage() external view returns (uint256) {
        return SLIPPAGE;
    }

    function getNumberOfCoins() external view returns (uint256) {
        return N_COINS;
    }

    function calcMinAmount(uint256 totalAmount, uint256 virtualPrice)
        external
        view
        returns (uint256)
    {
        return _calcMinAmount(totalAmount, virtualPrice);
    }

    function calcMinAmountUnderlyer(
        uint256 totalAmount,
        uint256 virtualPrice,
        uint8 decimals
    ) external view returns (uint256) {
        return _calcMinAmountUnderlyer(totalAmount, virtualPrice, decimals);
    }

    function assetAllocations() public view override returns (string[] memory) {
        string[] memory allocationNames = new string[](1);
        return allocationNames;
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = new IERC20[](0);
        return allocations;
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return 1;
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        return _underlyers[i];
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount // solhint-disable-next-line no-empty-blocks
    ) internal override {}
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {NamedAddressSet} from "./NamedAddressSet.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IErc20Allocation} from "./IErc20Allocation.sol";
import {IChainlinkRegistry} from "./IChainlinkRegistry.sol";
import {IAssetAllocationRegistry} from "./IAssetAllocationRegistry.sol";
import {AssetAllocationBase} from "./AssetAllocationBase.sol";
import {ImmutableAssetAllocation} from "./ImmutableAssetAllocation.sol";
import {Erc20AllocationConstants} from "./Erc20Allocation.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {IAssetAllocation, INameIdentifier} from "contracts/common/Imports.sol";
import {IZap, ISwap} from "contracts/lpaccount/Imports.sol";

/**
 * @notice Stores a set of addresses that can be looked up by name
 * @notice Addresses can be added or removed dynamically
 * @notice Useful for keeping track of unique deployed contracts
 * @dev Each address must be a contract with a `NAME` constant for lookup
 */
library NamedAddressSet {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Set {
        EnumerableSet.AddressSet _namedAddresses;
        mapping(string => INameIdentifier) _nameLookup;
    }

    struct AssetAllocationSet {
        Set _inner;
    }

    struct ZapSet {
        Set _inner;
    }

    struct SwapSet {
        Set _inner;
    }

    function _add(Set storage set, INameIdentifier namedAddress) private {
        require(Address.isContract(address(namedAddress)), "INVALID_ADDRESS");
        require(
            !set._namedAddresses.contains(address(namedAddress)),
            "DUPLICATE_ADDRESS"
        );

        string memory name = namedAddress.NAME();
        require(bytes(name).length != 0, "INVALID_NAME");
        require(address(set._nameLookup[name]) == address(0), "DUPLICATE_NAME");

        set._namedAddresses.add(address(namedAddress));
        set._nameLookup[name] = namedAddress;
    }

    function _remove(Set storage set, string memory name) private {
        address namedAddress = address(set._nameLookup[name]);
        require(namedAddress != address(0), "INVALID_NAME");

        set._namedAddresses.remove(namedAddress);
        delete set._nameLookup[name];
    }

    function _contains(Set storage set, INameIdentifier namedAddress)
        private
        view
        returns (bool)
    {
        return set._namedAddresses.contains(address(namedAddress));
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._namedAddresses.length();
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (INameIdentifier)
    {
        return INameIdentifier(set._namedAddresses.at(index));
    }

    function _get(Set storage set, string memory name)
        private
        view
        returns (INameIdentifier)
    {
        return set._nameLookup[name];
    }

    function _names(Set storage set) private view returns (string[] memory) {
        uint256 length_ = set._namedAddresses.length();
        string[] memory names_ = new string[](length_);

        for (uint256 i = 0; i < length_; i++) {
            INameIdentifier namedAddress =
                INameIdentifier(set._namedAddresses.at(i));
            names_[i] = namedAddress.NAME();
        }

        return names_;
    }

    function add(
        AssetAllocationSet storage set,
        IAssetAllocation assetAllocation
    ) internal {
        _add(set._inner, assetAllocation);
    }

    function remove(AssetAllocationSet storage set, string memory name)
        internal
    {
        _remove(set._inner, name);
    }

    function contains(
        AssetAllocationSet storage set,
        IAssetAllocation assetAllocation
    ) internal view returns (bool) {
        return _contains(set._inner, assetAllocation);
    }

    function length(AssetAllocationSet storage set)
        internal
        view
        returns (uint256)
    {
        return _length(set._inner);
    }

    function at(AssetAllocationSet storage set, uint256 index)
        internal
        view
        returns (IAssetAllocation)
    {
        return IAssetAllocation(address(_at(set._inner, index)));
    }

    function get(AssetAllocationSet storage set, string memory name)
        internal
        view
        returns (IAssetAllocation)
    {
        return IAssetAllocation(address(_get(set._inner, name)));
    }

    function names(AssetAllocationSet storage set)
        internal
        view
        returns (string[] memory)
    {
        return _names(set._inner);
    }

    function add(ZapSet storage set, IZap zap) internal {
        _add(set._inner, zap);
    }

    function remove(ZapSet storage set, string memory name) internal {
        _remove(set._inner, name);
    }

    function contains(ZapSet storage set, IZap zap)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, zap);
    }

    function length(ZapSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(ZapSet storage set, uint256 index)
        internal
        view
        returns (IZap)
    {
        return IZap(address(_at(set._inner, index)));
    }

    function get(ZapSet storage set, string memory name)
        internal
        view
        returns (IZap)
    {
        return IZap(address(_get(set._inner, name)));
    }

    function names(ZapSet storage set) internal view returns (string[] memory) {
        return _names(set._inner);
    }

    function add(SwapSet storage set, ISwap swap) internal {
        _add(set._inner, swap);
    }

    function remove(SwapSet storage set, string memory name) internal {
        _remove(set._inner, name);
    }

    function contains(SwapSet storage set, ISwap swap)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, swap);
    }

    function length(SwapSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(SwapSet storage set, uint256 index)
        internal
        view
        returns (ISwap)
    {
        return ISwap(address(_at(set._inner, index)));
    }

    function get(SwapSet storage set, string memory name)
        internal
        view
        returns (ISwap)
    {
        return ISwap(address(_get(set._inner, name)));
    }

    function names(SwapSet storage set)
        internal
        view
        returns (string[] memory)
    {
        return _names(set._inner);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IZap} from "./IZap.sol";
import {ISwap} from "./ISwap.sol";
import {ILpAccount} from "./ILpAccount.sol";
import {IZapRegistry} from "./IZapRegistry.sol";
import {ISwapRegistry} from "./ISwapRegistry.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    INameIdentifier,
    IERC20
} from "contracts/common/Imports.sol";

/**
 * @notice Used to define how an LP Account farms an external protocol
 */
interface IZap is INameIdentifier {
    /**
     * @notice Deploy liquidity to a protocol (i.e. enter a farm)
     * @dev Implementation should add liquidity and stake LP tokens
     * @param amounts Amount of each token to deploy
     */
    function deployLiquidity(uint256[] calldata amounts) external;

    /**
     * @notice Unwind liquidity from a protocol (i.e exit a farm)
     * @dev Implementation should unstake LP tokens and remove liquidity
     * @dev If there is only one token to unwind, `index` should be 0
     * @param amount Amount of liquidity to unwind
     * @param index Which token should be unwound
     */
    function unwindLiquidity(uint256 amount, uint8 index) external;

    /**
     * @notice Claim accrued rewards from the protocol (i.e. harvest yield)
     */
    function claim() external;

    /**
     * @notice Order of tokens for deploy `amounts` and unwind `index`
     * @dev Implementation should use human readable symbols
     * @dev Order should be the same for deploy and unwind
     * @return The array of symbols in order
     */
    function sortedSymbols() external view returns (string[] memory);

    /**
     * @notice Asset allocations to include in TVL
     * @dev Requires all allocations that track value deployed to the protocol
     * @return An array of the asset allocation names
     */
    function assetAllocations() external view returns (string[] memory);

    /**
     * @notice ERC20 asset allocations to include in TVL
     * @dev Should return addresses for all tokens that get deployed or unwound
     * @return The array of ERC20 token addresses
     */
    function erc20Allocations() external view returns (IERC20[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    INameIdentifier,
    IERC20
} from "contracts/common/Imports.sol";

/**
 * @notice Used to define a token swap that can be performed by an LP Account
 */
interface ISwap is INameIdentifier {
    /**
     * @dev Implementation should perform a token swap
     * @param amount The amount of the input token to swap
     * @param minAmount The minimum amount of the output token to accept
     */
    function swap(uint256 amount, uint256 minAmount) external;

    /**
     * @notice ERC20 asset allocations to include in TVL
     * @dev Should return addresses for all tokens going in and out of the swap
     * @return The array of ERC20 token addresses
     */
    function erc20Allocations() external view returns (IERC20[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice For contracts that provide liquidity to external protocols
 */
interface ILpAccount {
    /**
     * @notice Deploy liquidity with a registered `IZap`
     * @dev The order of token amounts should match `IZap.sortedSymbols`
     * @param name The name of the `IZap`
     * @param amounts The token amounts to deploy
     */
    function deployStrategy(string calldata name, uint256[] calldata amounts)
        external;

    /**
     * @notice Unwind liquidity with a registered `IZap`
     * @dev The index should match the order of `IZap.sortedSymbols`
     * @param name The name of the `IZap`
     * @param amount The amount of the token to unwind
     * @param index The index of the token to unwind
     */
    function unwindStrategy(
        string calldata name,
        uint256 amount,
        uint8 index
    ) external;

    /**
     * @notice Return liquidity to a pool
     * @notice Typically used to refill a liquidity pool's reserve
     * @dev This should only be callable by the `MetaPoolToken`
     * @param pool The `IReservePool` to transfer to
     * @param amount The amount of the pool's underlyer token to transer
     */
    function transferToPool(address pool, uint256 amount) external;

    /**
     * @notice Swap tokens with a registered `ISwap`
     * @notice Used to compound reward tokens
     * @notice Used to rebalance underlyer tokens
     * @param name The name of the `IZap`
     * @param amount The amount of tokens to swap
     * @param minAmount The minimum amount of tokens to receive from the swap
     */
    function swap(
        string calldata name,
        uint256 amount,
        uint256 minAmount
    ) external;

    /**
     * @notice Claim reward tokens with a registered `IZap`
     * @param name The name of the `IZap`
     */
    function claim(string calldata name) external;
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IZap} from "./IZap.sol";

/**
 * @notice For managing a collection of `IZap` contracts
 */
interface IZapRegistry {
    /** @notice Log when a new `IZap` is registered */
    event ZapRegistered(IZap zap);

    /** @notice Log when an `IZap` is removed */
    event ZapRemoved(string name);

    /**
     * @notice Add a new `IZap` to the registry
     * @dev Should not allow duplicate swaps
     * @param zap The new `IZap`
     */
    function registerZap(IZap zap) external;

    /**
     * @notice Remove an `IZap` from the registry
     * @param name The name of the `IZap` (see `INameIdentifier`)
     */
    function removeZap(string calldata name) external;

    /**
     * @notice Get the names of all registered `IZap`
     * @return An array of `IZap` names
     */
    function zapNames() external view returns (string[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {ISwap} from "./ISwap.sol";

/**
 * @notice For managing a collection of `ISwap` contracts
 */
interface ISwapRegistry {
    /** @notice Log when a new `ISwap` is registered */
    event SwapRegistered(ISwap swap);

    /** @notice Log when an `ISwap` is removed */
    event SwapRemoved(string name);

    /**
     * @notice Add a new `ISwap` to the registry
     * @dev Should not allow duplicate swaps
     * @param swap The new `ISwap`
     */
    function registerSwap(ISwap swap) external;

    /**
     * @notice Remove an `ISwap` from the registry
     * @param name The name of the `ISwap` (see `INameIdentifier`)
     */
    function removeSwap(string calldata name) external;

    /**
     * @notice Get the names of all registered `ISwap`
     * @return An array of `ISwap` names
     */
    function swapNames() external view returns (string[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IERC20, IDetailedERC20} from "contracts/common/Imports.sol";

/**
 * @notice An asset allocation for tokens not stored in a protocol
 * @dev `IZap`s and `ISwap`s register these separate from other allocations
 * @dev Unlike other asset allocations, new tokens can be added or removed
 * @dev Registration can override `symbol` and `decimals` manually because
 * they are optional in the ERC20 standard.
 */
interface IErc20Allocation {
    /** @notice Log when an ERC20 allocation is registered */
    event Erc20TokenRegistered(IERC20 token, string symbol, uint8 decimals);

    /** @notice Log when an ERC20 allocation is removed */
    event Erc20TokenRemoved(IERC20 token);

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     */
    function registerErc20Token(IDetailedERC20 token) external;

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     * @param symbol Override the token symbol
     */
    function registerErc20Token(IDetailedERC20 token, string calldata symbol)
        external;

    /**
     * @notice Add a new ERC20 token to the asset allocation
     * @dev Should not allow duplicate tokens
     * @param token The new token
     * @param symbol Override the token symbol
     * @param decimals Override the token decimals
     */
    function registerErc20Token(
        IERC20 token,
        string calldata symbol,
        uint8 decimals
    ) external;

    /**
     * @notice Remove an ERC20 token from the asset allocation
     * @param token The token to remove
     */
    function removeErc20Token(IERC20 token) external;

    /**
     * @notice Check if an ERC20 token is registered
     * @param token The token to check
     * @return `true` if the token is registered, `false` otherwise
     */
    function isErc20TokenRegistered(IERC20 token) external view returns (bool);

    /**
     * @notice Check if multiple ERC20 tokens are ALL registered
     * @param tokens An array of tokens to check
     * @return `true` if every token is registered, `false` otherwise
     */
    function isErc20TokenRegistered(IERC20[] calldata tokens)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice Interface used by Chainlink to aggregate allocations and compute TVL
 */
interface IChainlinkRegistry {
    /**
     * @notice Get all IDs from registered asset allocations
     * @notice Each ID is a unique asset allocation and token index pair
     * @dev Should contain no duplicate IDs
     * @return list of all IDs
     */
    function getAssetAllocationIds() external view returns (bytes32[] memory);

    /**
     * @notice Get the LP Account's balance for an asset allocation ID
     * @param allocationId The ID to fetch the balance for
     * @return The balance for the LP Account
     */
    function balanceOf(bytes32 allocationId) external view returns (uint256);

    /**
     * @notice Get the symbol for an allocation ID's underlying token
     * @param allocationId The ID to fetch the symbol for
     * @return The underlying token symbol
     */
    function symbolOf(bytes32 allocationId)
        external
        view
        returns (string memory);

    /**
     * @notice Get the decimals for an allocation ID's underlying token
     * @param allocationId The ID to fetch the decimals for
     * @return The underlying token decimals
     */
    function decimalsOf(bytes32 allocationId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";

/**
 * @notice For managing a collection of `IAssetAllocation` contracts
 */
interface IAssetAllocationRegistry {
    /** @notice Log when an asset allocation is registered */
    event AssetAllocationRegistered(IAssetAllocation assetAllocation);

    /** @notice Log when an asset allocation is removed */
    event AssetAllocationRemoved(string name);

    /**
     * @notice Add a new asset allocation to the registry
     * @dev Should not allow duplicate asset allocations
     * @param assetAllocation The new asset allocation
     */
    function registerAssetAllocation(IAssetAllocation assetAllocation) external;

    /**
     * @notice Remove an asset allocation from the registry
     * @param name The name of the asset allocation (see `INameIdentifier`)
     */
    function removeAssetAllocation(string memory name) external;

    /**
     * @notice Check if multiple asset allocations are ALL registered
     * @param allocationNames An array of asset allocation names
     * @return `true` if every allocation is registered, otherwise `false`
     */
    function isAssetAllocationRegistered(string[] calldata allocationNames)
        external
        view
        returns (bool);

    /**
     * @notice Get the registered asset allocation with a given name
     * @param name The asset allocation name
     * @return The asset allocation
     */
    function getAssetAllocation(string calldata name)
        external
        view
        returns (IAssetAllocation);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";

abstract contract AssetAllocationBase is IAssetAllocation {
    function numberOfTokens() external view override returns (uint256) {
        return tokens().length;
    }

    function symbolOf(uint8 tokenIndex)
        public
        view
        override
        returns (string memory)
    {
        return tokens()[tokenIndex].symbol;
    }

    function decimalsOf(uint8 tokenIndex) public view override returns (uint8) {
        return tokens()[tokenIndex].decimals;
    }

    function addressOf(uint8 tokenIndex) public view returns (address) {
        return tokens()[tokenIndex].token;
    }

    function tokens() public view virtual override returns (TokenData[] memory);
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Address} from "contracts/libraries/Imports.sol";
import {AssetAllocationBase} from "./AssetAllocationBase.sol";

/**
 * @notice Asset allocation with underlying tokens that cannot be added/removed
 */
abstract contract ImmutableAssetAllocation is AssetAllocationBase {
    using Address for address;

    constructor() public {
        _validateTokens(_getTokenData());
    }

    function tokens() public view override returns (TokenData[] memory) {
        TokenData[] memory tokens_ = _getTokenData();
        return tokens_;
    }

    /**
     * @notice Get the immutable array of underlying `TokenData`
     * @dev Should be implemented in child contracts with a hardcoded array
     * @return The array of `TokenData`
     */
    function _getTokenData() internal pure virtual returns (TokenData[] memory);

    /**
     * @notice Verifies that a `TokenData` array works with the `TvlManager`
     * @dev Reverts when there is invalid `TokenData`
     * @param tokens_ The array of `TokenData`
     */
    function _validateTokens(TokenData[] memory tokens_) internal view virtual {
        // length restriction due to encoding logic for allocation IDs
        require(tokens_.length < type(uint8).max, "TOO_MANY_TOKENS");
        for (uint256 i = 0; i < tokens_.length; i++) {
            address token = tokens_[i].token;
            _validateTokenAddress(token);
            string memory symbol = tokens_[i].symbol;
            require(bytes(symbol).length != 0, "INVALID_SYMBOL");
        }
        // TODO: check for duplicate tokens
    }

    /**
     * @notice Verify that a token is a contract
     * @param token The token to verify
     */
    function _validateTokenAddress(address token) internal view virtual {
        require(token.isContract(), "INVALID_ADDRESS");
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IERC20,
    IDetailedERC20,
    AccessControl,
    INameIdentifier,
    ReentrancyGuard
} from "contracts/common/Imports.sol";
import {Address, EnumerableSet} from "contracts/libraries/Imports.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";

import {IErc20Allocation} from "./IErc20Allocation.sol";
import {AssetAllocationBase} from "./AssetAllocationBase.sol";

abstract contract Erc20AllocationConstants is INameIdentifier {
    string public constant override NAME = "erc20Allocation";
}

contract Erc20Allocation is
    IErc20Allocation,
    AssetAllocationBase,
    Erc20AllocationConstants,
    AccessControl,
    ReentrancyGuard
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _tokenAddresses;
    mapping(address => TokenData) private _tokenToData;

    constructor(address addressRegistry_) public {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS_REGISTRY");
        IAddressRegistryV2 addressRegistry =
            IAddressRegistryV2(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
    }

    function registerErc20Token(IDetailedERC20 token)
        external
        override
        nonReentrant
        onlyAdminOrContractRole
    {
        string memory symbol = token.symbol();
        uint8 decimals = token.decimals();
        _registerErc20Token(token, symbol, decimals);
    }

    function registerErc20Token(IDetailedERC20 token, string calldata symbol)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        uint8 decimals = token.decimals();
        _registerErc20Token(token, symbol, decimals);
    }

    function registerErc20Token(
        IERC20 token,
        string calldata symbol,
        uint8 decimals
    ) external override nonReentrant onlyAdminRole {
        _registerErc20Token(token, symbol, decimals);
    }

    function removeErc20Token(IERC20 token)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _tokenAddresses.remove(address(token));
        delete _tokenToData[address(token)];

        emit Erc20TokenRemoved(token);
    }

    function isErc20TokenRegistered(IERC20 token)
        external
        view
        override
        returns (bool)
    {
        return _tokenAddresses.contains(address(token));
    }

    function isErc20TokenRegistered(IERC20[] calldata tokens)
        external
        view
        override
        returns (bool)
    {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (!_tokenAddresses.contains(address(tokens[i]))) {
                return false;
            }
        }

        return true;
    }

    function balanceOf(address account, uint8 tokenIndex)
        external
        view
        override
        returns (uint256)
    {
        address token = addressOf(tokenIndex);
        return IERC20(token).balanceOf(account);
    }

    function tokens() public view override returns (TokenData[] memory) {
        TokenData[] memory _tokens = new TokenData[](_tokenAddresses.length());
        for (uint256 i = 0; i < _tokens.length; i++) {
            address tokenAddress = _tokenAddresses.at(i);
            _tokens[i] = _tokenToData[tokenAddress];
        }
        return _tokens;
    }

    function _registerErc20Token(
        IERC20 token,
        string memory symbol,
        uint8 decimals
    ) internal {
        require(address(token).isContract(), "INVALID_ADDRESS");
        require(bytes(symbol).length != 0, "INVALID_SYMBOL");
        _tokenAddresses.add(address(token));
        _tokenToData[address(token)] = TokenData(
            address(token),
            symbol,
            decimals
        );

        emit Erc20TokenRegistered(token, symbol, decimals);
    }
}

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IAddressRegistryV2} from "./IAddressRegistryV2.sol";

// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice The address registry has two important purposes, one which
 * is fairly concrete and another abstract.
 *
 * 1. The registry enables components of the APY.Finance system
 * and external systems to retrieve core addresses reliably
 * even when the functionality may move to a different
 * address.
 *
 * 2. The registry also makes explicit which contracts serve
 * as primary entrypoints for interacting with different
 * components.  Not every contract is registered here, only
 * the ones properly deserving of an identifier.  This helps
 * define explicit boundaries between groups of contracts,
 * each of which is logically cohesive.
 */
interface IAddressRegistryV2 {
    /**
     * @notice Log when a new address is registered
     * @param id The ID of the new address
     * @param _address The new address
     */
    event AddressRegistered(bytes32 id, address _address);

    /**
     * @notice Log when an address is removed from the registry
     * @param id The ID of the address
     * @param _address The address
     */
    event AddressDeleted(bytes32 id, address _address);

    /**
     * @notice Register address with identifier
     * @dev Using an existing ID will replace the old address with new
     * @dev Currently there is no way to remove an ID, as attempting to
     * register the zero address will revert.
     */
    function registerAddress(bytes32 id, address address_) external;

    /**
     * @notice Registers multiple address at once
     * @dev Convenient method to register multiple addresses at once.
     * @param ids Ids to register addresses under
     * @param addresses Addresses to register
     */
    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external;

    /**
     * @notice Removes a registered id and it's associated address
     * @dev Delete the address corresponding to the identifier Time-complexity is O(n) where n is the length of `_idList`.
     * @param id ID to remove along with it's associated address
     */
    function deleteAddress(bytes32 id) external;

    /**
     * @notice Returns the list of all registered identifiers.
     * @return List of identifiers
     */
    function getIds() external view returns (bytes32[] memory);

    /**
     * @notice Returns the list of all registered identifiers
     * @param id Component identifier
     * @return The current address represented by an identifier
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice Returns the TVL Manager Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return TVL Manager Address
     */
    function tvlManagerAddress() external view returns (address);

    /**
     * @notice Returns the Chainlink Registry Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Chainlink Registry Address
     */
    function chainlinkRegistryAddress() external view returns (address);

    /**
     * @notice Returns the DAI Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return DAI Pool Address
     */
    function daiPoolAddress() external view returns (address);

    /**
     * @notice Returns the USDC Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return USDC Pool Address
     */
    function usdcPoolAddress() external view returns (address);

    /**
     * @notice Returns the USDT Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return USDT Pool Address
     */
    function usdtPoolAddress() external view returns (address);

    /**
     * @notice Returns the MAPT Pool Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return MAPT Pool Address
     */
    function mAptAddress() external view returns (address);

    /**
     * @notice Returns the LP Account Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return LP Account Address
     */
    function lpAccountAddress() external view returns (address);

    /**
     * @notice Returns the LP Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return LP Safe Address
     */
    function lpSafeAddress() external view returns (address);

    /**
     * @notice Returns the Admin Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Admin Safe Address
     */
    function adminSafeAddress() external view returns (address);

    /**
     * @notice Returns the Emergency Safe Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Emergency Safe Address
     */
    function emergencySafeAddress() external view returns (address);

    /**
     * @notice Returns the Oracle Adapter Address
     * @dev Not just a helper function, this makes explicit a key ID for the system
     * @return Oracle Adapter Address
     */
    function oracleAdapterAddress() external view returns (address);
}