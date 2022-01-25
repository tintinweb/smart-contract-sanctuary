// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/StringHelpers.sol";
import "./libraries/MathHelpers.sol";
import "./libraries/BorrowableHelpers02.sol";
import "./interfaces/ISupplyVaultStrategy.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ISupplyVault.sol";
import "./interfaces/IFactory.sol";

contract SupplyVaultStrategyV3 is ISupplyVaultStrategy, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using BorrowableHelpers for IBorrowable;
    using BorrowableDetailHelpers for BorrowableDetail;

    struct SupplyVaultInfo {
        uint256 additionalDeallocAmount;
        uint256 minAllocAmount;
    }
    mapping(ISupplyVault => SupplyVaultInfo) public supplyVaultInfo;

    function updateSupplyVaultInfo(
        ISupplyVault supplyVault,
        uint256 additionalDeallocAmount,
        uint256 minAllocAmount
    ) external onlyOwner {
        require(isAuthorized[supplyVault], "SupplyVaultStrategyV3: INVALID_VAULT");

        supplyVaultInfo[supplyVault].additionalDeallocAmount = additionalDeallocAmount;
        supplyVaultInfo[supplyVault].minAllocAmount = minAllocAmount;
    }

    struct BorrowableOption {
        IBorrowable borrowable;
        uint256 underlyingAmount;
        uint256 borrowableAmount;
        uint256 minLoss;
        uint256 maxGain;
    }

    mapping(ISupplyVault => bool) public isAuthorized;

    function _authorize(ISupplyVault supplyVault) private {
        require(!isAuthorized[supplyVault], "SupplyVaultStrategyV3: ALREADY_AUTHORIZED");

        isAuthorized[supplyVault] = true;
    }

    function authorize(ISupplyVault supplyVault) external onlyOwner {
        _authorize(supplyVault);
    }

    function authorizeMany(ISupplyVault[] calldata supplyVaultList) external onlyOwner {
        for (uint256 i = 0; i < supplyVaultList.length; i++) {
            _authorize(supplyVaultList[i]);
        }
    }

    modifier onlyAuthorized() {
        require(isAuthorized[ISupplyVault(msg.sender)], "SupplyVaultStrategyV3: NOT_AUTHORIZED");

        _;
    }

    IFactory constant TAROT_FACTORY = IFactory(0x35C052bBf8338b06351782A565aa9AaD173432eA);

    function getBorrowable(address _address) external view override onlyAuthorized returns (IBorrowable) {
        ISupplyVault supplyVault = ISupplyVault(msg.sender);
        address underlying = address(supplyVault.underlying());

        // Treating _address as a UniswapV2Pair, try to get the lending pool from the known factory adress
        (bool initialized, , , address borrowable0, address borrowable1) = TAROT_FACTORY.getLendingPool(_address);
        if (initialized) {
            if (IBorrowable(borrowable0).underlying() == underlying) {
                return IBorrowable(borrowable0);
            }
            if (IBorrowable(borrowable1).underlying() == underlying) {
                return IBorrowable(borrowable1);
            }
        }

        require(false, "SupplyVaultStrategyV3: INVALID_BORROWABLE");
    }

    function getSupplyRate() external override onlyAuthorized returns (uint256 supplyRate_) {
        ISupplyVault supplyVault = ISupplyVault(msg.sender);
        IERC20 underlying = supplyVault.underlying();

        uint256 totalUnderlying = underlying.balanceOf(address(supplyVault));
        uint256 weightedSupplyRate = 0; // Underlying has a supply rate of zero

        uint256 numBorrowables = supplyVault.getBorrowablesLength();
        for (uint256 i = 0; i < numBorrowables; i++) {
            IBorrowable borrowable = supplyVault.borrowables(i);
            uint256 borrowableUnderlyingBalance = borrowable.underlyingBalanceOf(address(supplyVault));
            if (borrowableUnderlyingBalance > 0) {
                (uint256 borrowableSupplyRate, , ) = borrowable.getCurrentSupplyRate();
                weightedSupplyRate = weightedSupplyRate.add(borrowableUnderlyingBalance.mul(borrowableSupplyRate));
                totalUnderlying = totalUnderlying.add(borrowableUnderlyingBalance);
            }
        }

        if (totalUnderlying != 0) {
            supplyRate_ = weightedSupplyRate.div(totalUnderlying);
        }
    }

    function _allocate(uint256 amount) private {
        ISupplyVault supplyVault = ISupplyVault(msg.sender);

        if (amount == 0) {
            // Nothing to allocate
            return;
        }

        BorrowableOption memory best;
        best.minLoss = type(uint256).max;

        uint256 numBorrowables = supplyVault.getBorrowablesLength();
        require(numBorrowables > 0, "SupplyVaultStrategyV3: NO_BORROWABLES");

        for (uint256 i = 0; i < numBorrowables; i++) {
            IBorrowable borrowable = supplyVault.borrowables(i);
            if (!supplyVault.getBorrowableEnabled(borrowable)) {
                continue;
            }

            uint256 exchangeRate = borrowable.exchangeRate();

            uint256 borrowableMinUnderlying = exchangeRate.div(1E18).add(1);
            if (amount < borrowableMinUnderlying) {
                continue;
            }

            BorrowableDetail memory detail = borrowable.getBorrowableDetail();
            uint256 underlyingBalance = borrowable.balanceOf(address(supplyVault)).mul(exchangeRate).div(1E18);

            (uint256 gain, uint256 loss) = detail.getMyNetInterest(underlyingBalance, amount, 0);

            if (gain > best.maxGain || (best.maxGain == 0 && loss < best.minLoss)) {
                best.borrowable = borrowable;
                best.maxGain = gain;
                best.minLoss = loss;
            }
        }

        if (address(best.borrowable) != address(0)) {
            supplyVault.allocateIntoBorrowable(best.borrowable, amount);
        }
    }

    function allocate() public override onlyAuthorized {
        ISupplyVault supplyVault = ISupplyVault(msg.sender);

        IERC20 underlying = supplyVault.underlying();
        uint256 amount = underlying.balanceOf(address(supplyVault));

        if (amount < supplyVaultInfo[supplyVault].minAllocAmount) {
            return;
        }

        _allocate(amount);
    }

    struct DeallocOption {
        uint256 withdrawBorrowableAmount;
        uint256 withdrawBorrowableAmountAsUnderlying;
        uint256 exchangeRate;
        uint256 vaultBorrowableBalance;
    }

    /**
     * Deallocate from the least performing borrowable either:
     *    1) The amount of that borrowable to generate at least needAmount of underlying
     *    2) The maximum amount that can be withdrawn from that borrowable at this time
     */
    function _deallocateFromLowestSupplyRate(
        ISupplyVault supplyVault,
        uint256 numBorrowables,
        IERC20 underlying,
        uint256 needAmount
    ) private returns (uint256 deallocatedAmount) {
        BorrowableOption memory best;
        best.minLoss = type(uint256).max;

        for (uint256 i = 0; i < numBorrowables; i++) {
            IBorrowable borrowable = supplyVault.borrowables(i);

            DeallocOption memory option;
            option.exchangeRate = borrowable.exchangeRate();

            {
                option.vaultBorrowableBalance = borrowable.balanceOf(address(supplyVault));
                if (option.vaultBorrowableBalance == 0) {
                    continue;
                }
                uint256 borrowableUnderlyingBalance = underlying.balanceOf(address(borrowable));
                uint256 borrowableUnderlyingBalanceAsBorrowable = borrowableUnderlyingBalance.mul(1E18).div(
                    option.exchangeRate
                );
                if (borrowableUnderlyingBalanceAsBorrowable == 0) {
                    continue;
                }
                uint256 needAmountAsBorrowableIn = needAmount.mul(1E18).div(option.exchangeRate).add(1);

                option.withdrawBorrowableAmount = MathHelpers.min(
                    needAmountAsBorrowableIn,
                    option.vaultBorrowableBalance,
                    borrowableUnderlyingBalanceAsBorrowable
                );
                option.withdrawBorrowableAmountAsUnderlying = option
                    .withdrawBorrowableAmount
                    .mul(option.exchangeRate)
                    .div(1E18);
            }
            if (option.withdrawBorrowableAmountAsUnderlying == 0) {
                continue;
            }

            BorrowableDetail memory detail = borrowable.getBorrowableDetail();
            uint256 underlyingBalance = option.vaultBorrowableBalance.mul(option.exchangeRate).div(1E18);
            (uint256 gain, uint256 loss) = detail.getMyNetInterest(
                underlyingBalance,
                0,
                option.withdrawBorrowableAmountAsUnderlying
            );

            uint256 lossPerUnderlying = loss.mul(1e18).div(option.withdrawBorrowableAmountAsUnderlying);
            uint256 gainPerUnderlying = gain.mul(1e18).div(option.withdrawBorrowableAmountAsUnderlying);
            if (gainPerUnderlying > best.maxGain || (best.maxGain == 0 && lossPerUnderlying < best.minLoss)) {
                best.borrowable = borrowable;
                best.minLoss = lossPerUnderlying;
                best.maxGain = gainPerUnderlying;
                best.borrowableAmount = option.withdrawBorrowableAmount;
                best.underlyingAmount = option.withdrawBorrowableAmountAsUnderlying;
            }
        }

        require(best.minLoss < type(uint256).max, "SupplyVaultStrategyV3: INSUFFICIENT_CASH");

        uint256 beforeBalance = underlying.balanceOf(address(supplyVault));
        supplyVault.deallocateFromBorrowable(best.borrowable, best.borrowableAmount);
        uint256 afterBalance = underlying.balanceOf(address(supplyVault));
        require(afterBalance.sub(beforeBalance) == best.underlyingAmount, "Delta must match");

        return best.underlyingAmount;
    }

    function deallocate(uint256 needAmount) public override onlyAuthorized {
        require(needAmount > 0, "SupplyVaultStrategyV3: ZERO_AMOUNT");

        ISupplyVault supplyVault = ISupplyVault(msg.sender);
        IERC20 underlying = supplyVault.underlying();

        needAmount = needAmount.add(supplyVaultInfo[supplyVault].additionalDeallocAmount);

        uint256 numBorrowables = supplyVault.getBorrowablesLength();

        do {
            // Withdraw as much as we can from the lowest supply or fail if none is available
            uint256 withdraw = _deallocateFromLowestSupplyRate(supplyVault, numBorrowables, underlying, needAmount);
            // If we get here then we made some progress

            if (withdraw >= needAmount) {
                // We unwound a bit more than we needed as deallocation had to round up
                needAmount = 0;
            } else {
                // Update the remaining amount that we desire
                needAmount = needAmount.sub(withdraw);
            }

            if (needAmount == 0) {
                // We have enough so we are done
                break;
            }
            // Keep going and try a different borrowable
        } while (true);

        assert(needAmount == 0);
    }

    struct ReallocateInfo {
        IBorrowable deallocFromBorrowable;
        IBorrowable allocIntoBorrowable;
    }

    function getReallocateInfo(bytes calldata _data) private pure returns (ReallocateInfo memory info) {
        if (_data.length == 0) {
            // Use default empty addresses
        } else if (_data.length == 64) {
            info = abi.decode(_data, (ReallocateInfo));
            require(info.deallocFromBorrowable != info.allocIntoBorrowable, "SupplyVaultStrategyV3: SAME_IN_OUT");
        } else {
            require(false, "SupplyVaultStrategyV3: INVALID_DATA");
        }
    }

    function reallocate(uint256 _underlyingAmount, bytes calldata _data) external override onlyAuthorized {
        require(_underlyingAmount > 0, "SupplyVaultStrategyV3: ZERO_AMOUNT");

        ReallocateInfo memory info = getReallocateInfo(_data);
        ISupplyVault supplyVault = ISupplyVault(msg.sender);
        IERC20 underlying = supplyVault.underlying();

        uint256 underlyingBalance = underlying.balanceOf(address(supplyVault));
        if (underlyingBalance < _underlyingAmount) {
            uint256 deallocateAmount = _underlyingAmount.sub(underlyingBalance);

            if (address(info.deallocFromBorrowable) != address(0)) {
                // Deallocate from this specific borrowable
                uint256 deallocateBorrowableAmount = info.deallocFromBorrowable.borrowableValueOf(deallocateAmount);
                supplyVault.deallocateFromBorrowable(info.deallocFromBorrowable, deallocateBorrowableAmount);
            } else {
                deallocate(deallocateAmount);
            }
        }

        uint256 allocateAmount = MathHelpers.min(_underlyingAmount, underlying.balanceOf(address(supplyVault)));
        if (address(info.allocIntoBorrowable) != address(0)) {
            // Allocate into this specific borrowable
            supplyVault.allocateIntoBorrowable(info.allocIntoBorrowable, allocateAmount);
        } else {
            _allocate(allocateAmount);
        }
    }
}

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

pragma solidity 0.6.12;

library StringHelpers {
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /**
     * Returns the first string if it is not-empty, otherwise the second.
     */
    function orElse(string memory a, string memory b) internal pure returns (string memory) {
        if (bytes(a).length > 0) {
            return a;
        }
        return b;
    }
}

pragma solidity 0.6.12;

library MathHelpers {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function min(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return min(a, min(b, c));
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        }
        return b;
    }

    function max(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return max(a, max(b, c));
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IBorrowable.sol";

struct BorrowableDetail {
    uint256 totalBorrows;
    uint256 totalBalance;
    uint256 kinkUtilizationRate;
    uint256 kinkBorrowRate;
    uint256 kinkMultiplier;
    uint256 reserveFactor;
}

library BorrowableHelpers {
    using SafeMath for uint256;
    using BorrowableDetailHelpers for BorrowableDetail;

    function borrowableValueOf(IBorrowable borrowable, uint256 underlyingAmount) internal returns (uint256) {
        if (underlyingAmount == 0) {
            return 0;
        }
        uint256 exchangeRate = borrowable.exchangeRate();
        return underlyingAmount.mul(1e18).div(exchangeRate);
    }

    function underlyingValueOf(IBorrowable borrowable, uint256 borrowableAmount) internal returns (uint256) {
        if (borrowableAmount == 0) {
            return 0;
        }
        uint256 exchangeRate = borrowable.exchangeRate();
        return borrowableAmount.mul(exchangeRate).div(1e18);
    }

    function underlyingBalanceOf(IBorrowable borrowable, address account) internal returns (uint256) {
        return underlyingValueOf(borrowable, borrowable.balanceOf(account));
    }

    function myUnderlyingBalance(IBorrowable borrowable) internal returns (uint256) {
        return underlyingValueOf(borrowable, borrowable.balanceOf(address(this)));
    }

    function getBorrowableDetail(IBorrowable borrowable) internal view returns (BorrowableDetail memory detail) {
        detail.totalBorrows = borrowable.totalBorrows();
        detail.totalBalance = borrowable.totalBalance();
        detail.kinkUtilizationRate = borrowable.kinkUtilizationRate();
        detail.kinkBorrowRate = borrowable.kinkBorrowRate();
        detail.kinkMultiplier = borrowable.KINK_MULTIPLIER();
        detail.reserveFactor = borrowable.reserveFactor();
    }

    function getCurrentSupplyRate(IBorrowable borrowable)
        internal
        view
        returns (
            uint256 supplyRate_,
            uint256 borrowRate_,
            uint256 utilizationRate_
        )
    {
        BorrowableDetail memory detail = getBorrowableDetail(borrowable);
        return detail.getSupplyRate();
    }
}

library BorrowableDetailHelpers {
    using SafeMath for uint256;

    uint256 private constant TEN_TO_18 = 1e18;

    function getBorrowRate(BorrowableDetail memory detail)
        internal
        pure
        returns (uint256 borrowRate_, uint256 utilizationRate_)
    {
        (borrowRate_, utilizationRate_) = getBorrowRate(
            detail.totalBorrows,
            detail.totalBalance,
            detail.kinkUtilizationRate,
            detail.kinkBorrowRate,
            detail.kinkMultiplier
        );
    }

    function getBorrowRate(
        uint256 totalBorrows,
        uint256 totalBalance,
        uint256 kinkUtilizationRate,
        uint256 kinkBorrowRate,
        uint256 kinkMultiplier
    ) internal pure returns (uint256 borrowRate_, uint256 utilizationRate_) {
        uint256 actualBalance = totalBorrows.add(totalBalance);

        utilizationRate_ = actualBalance == 0 ? 0 : totalBorrows.mul(TEN_TO_18).div(actualBalance);

        if (utilizationRate_ < kinkUtilizationRate) {
            borrowRate_ = kinkBorrowRate.mul(utilizationRate_).div(kinkUtilizationRate);
        } else {
            uint256 overUtilization = (utilizationRate_.sub(kinkUtilizationRate)).mul(TEN_TO_18).div(
                TEN_TO_18.sub(kinkUtilizationRate)
            );
            borrowRate_ = (((kinkMultiplier.sub(1)).mul(overUtilization)).add(TEN_TO_18)).mul(kinkBorrowRate).div(
                TEN_TO_18
            );
        }
    }

    function getSupplyRate(BorrowableDetail memory detail)
        internal
        pure
        returns (
            uint256 supplyRate_,
            uint256 borrowRate_,
            uint256 utilizationRate_
        )
    {
        return getNextSupplyRate(detail, 0, 0);
    }

    function getNextSupplyRate(
        BorrowableDetail memory detail,
        uint256 depositAmount,
        uint256 withdrawAmount
    )
        internal
        pure
        returns (
            uint256 supplyRate_,
            uint256 borrowRate_,
            uint256 utilizationRate_
        )
    {
        require(depositAmount == 0 || withdrawAmount == 0, "BH: INVLD_DELTA");

        (borrowRate_, utilizationRate_) = getBorrowRate(
            detail.totalBorrows,
            detail.totalBalance.add(depositAmount).sub(withdrawAmount),
            detail.kinkUtilizationRate,
            detail.kinkBorrowRate,
            detail.kinkMultiplier
        );

        supplyRate_ = borrowRate_.mul(utilizationRate_).div(TEN_TO_18).mul(TEN_TO_18.sub(detail.reserveFactor)).div(
            TEN_TO_18
        );
    }

    function getInterest(
        uint256 balance,
        uint256 supplyRate,
        uint256 actualBalance
    ) internal pure returns (uint256) {
        return TEN_TO_18.mul(balance).mul(supplyRate).div(actualBalance);
    }

    function getMyNetInterest(
        BorrowableDetail memory detail,
        uint256 myBalance,
        uint256 depositAmount,
        uint256 withdrawAmount
    ) internal pure returns (uint256 gain_, uint256 loss_) {
        require(depositAmount > 0 != withdrawAmount > 0, "BH: INVLD_DELTA");

        (uint256 currentSupplyRate, , ) = getSupplyRate(detail);
        if (currentSupplyRate == 0) {
            return (gain_ = 0, loss_ = 0);
        }
        (uint256 nextSupplyRate, , ) = getNextSupplyRate(detail, depositAmount, withdrawAmount);

        uint256 actualBalance = detail.totalBalance.add(detail.totalBorrows);

        uint256 currentInterest = getInterest(myBalance, currentSupplyRate, actualBalance);
        uint256 nextInterest = getInterest(
            myBalance.add(depositAmount).sub(withdrawAmount),
            nextSupplyRate,
            actualBalance.add(depositAmount).sub(withdrawAmount)
        );

        if (nextInterest > currentInterest) {
            gain_ = nextInterest.sub(currentInterest);
        } else {
            loss_ = currentInterest.sub(nextInterest);
        }
    }
}

pragma solidity >=0.5.0;

import "./IBorrowable.sol";
import "./ISupplyVault.sol";

interface ISupplyVaultStrategy {
    function getBorrowable(address _address) external view returns (IBorrowable);

    function getSupplyRate() external returns (uint256 supplyRate_);

    function allocate() external;

    function deallocate(uint256 _underlyingAmount) external;

    function reallocate(uint256 _underlyingAmount, bytes calldata _data) external;
}

pragma solidity >=0.5.0;

interface IBorrowable {
    /*** Tarot ERC20 ***/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /*** Pool Token ***/

    event Mint(
        address indexed sender,
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens
    );
    event Redeem(
        address indexed sender,
        address indexed redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    );
    event Sync(uint256 totalBalance);

    function underlying() external view returns (address);

    function factory() external view returns (address);

    function totalBalance() external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function exchangeRate() external returns (uint256);

    function mint(address minter) external returns (uint256 mintTokens);

    function redeem(address redeemer) external returns (uint256 redeemAmount);

    function skim(address to) external;

    function sync() external;

    function _setFactory() external;

    /*** Borrowable ***/

    event BorrowApproval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Borrow(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 borrowAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed liquidator,
        uint256 seizeTokens,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    function BORROW_FEE() external pure returns (uint256);

    function collateral() external view returns (address);

    function reserveFactor() external view returns (uint256);

    function exchangeRateLast() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function borrowAllowance(address owner, address spender)
        external
        view
        returns (uint256);

    function borrowBalance(address borrower) external view returns (uint256);

    function borrowTracker() external view returns (address);

    function BORROW_PERMIT_TYPEHASH() external pure returns (bytes32);

    function borrowApprove(address spender, uint256 value)
        external
        returns (bool);

    function borrowPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function borrow(
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    function liquidate(address borrower, address liquidator)
        external
        returns (uint256 seizeTokens);

    function trackBorrow(address borrower) external;

    /*** Borrowable Interest Rate Model ***/

    event AccrueInterest(
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );
    event CalculateKink(uint256 kinkRate);
    event CalculateBorrowRate(uint256 borrowRate);

    function KINK_BORROW_RATE_MAX() external pure returns (uint256);

    function KINK_BORROW_RATE_MIN() external pure returns (uint256);

    function KINK_MULTIPLIER() external pure returns (uint256);

    function borrowRate() external view returns (uint256);

    function kinkBorrowRate() external view returns (uint256);

    function kinkUtilizationRate() external view returns (uint256);

    function adjustSpeed() external view returns (uint256);

    function rateUpdateTimestamp() external view returns (uint32);

    function accrualTimestamp() external view returns (uint32);

    function accrueInterest() external;

    /*** Borrowable Setter ***/

    event NewReserveFactor(uint256 newReserveFactor);
    event NewKinkUtilizationRate(uint256 newKinkUtilizationRate);
    event NewAdjustSpeed(uint256 newAdjustSpeed);
    event NewBorrowTracker(address newBorrowTracker);

    function RESERVE_FACTOR_MAX() external pure returns (uint256);

    function KINK_UR_MIN() external pure returns (uint256);

    function KINK_UR_MAX() external pure returns (uint256);

    function ADJUST_SPEED_MIN() external pure returns (uint256);

    function ADJUST_SPEED_MAX() external pure returns (uint256);

    function _initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlying,
        address _collateral
    ) external;

    function _setReserveFactor(uint256 newReserveFactor) external;

    function _setKinkUtilizationRate(uint256 newKinkUtilizationRate) external;

    function _setAdjustSpeed(uint256 newAdjustSpeed) external;

    function _setBorrowTracker(address newBorrowTracker) external;
}

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBorrowable.sol";
import "./ISupplyVaultStrategy.sol";

interface ISupplyVault {
    /* Vault */
    function enter(uint256 _amount) external returns (uint256 share);

    function enterWithToken(address _tokenAddress, uint256 _tokenAmount) external returns (uint256 share);

    function leave(uint256 _share) external returns (uint256 underlyingAmount);

    function leaveInKind(uint256 _share) external;

    function applyFee() external;

    /** Read */

    function getBorrowablesLength() external view returns (uint256);

    function getBorrowableEnabled(IBorrowable borrowable) external view returns (bool);

    function getBorrowableExists(IBorrowable borrowable) external view returns (bool);

    function indexOfBorrowable(IBorrowable borrowable) external view returns (uint256);

    function borrowables(uint256) external view returns (IBorrowable);

    function underlying() external view returns (IERC20);

    function strategy() external view returns (ISupplyVaultStrategy);

    function pendingStrategy() external view returns (ISupplyVaultStrategy);

    function pendingStrategyNotBefore() external view returns (uint256);

    function feeBps() external view returns (uint256);

    function feeTo() external view returns (address);

    function reallocateManager() external view returns (address);

    /* Read functions that are non-view due to updating exchange rates */
    function underlyingBalanceForAccount(address _account) external returns (uint256 underlyingBalance);

    function shareValuedAsUnderlying(uint256 _share) external returns (uint256 underlyingAmount_);

    function underlyingValuedAsShare(uint256 _underlyingAmount) external returns (uint256 share_);

    function getTotalUnderlying() external returns (uint256 totalUnderlying);

    function getSupplyRate() external returns (uint256 supplyRate_);

    /* Only from strategy */

    function allocateIntoBorrowable(IBorrowable borrowable, uint256 underlyingAmount) external;

    function deallocateFromBorrowable(IBorrowable borrowable, uint256 borrowableAmount) external;

    function reallocate(uint256 _share, bytes calldata _data) external;

    /* Only owner */
    function addBorrowable(address _address) external;

    function addBorrowables(address[] calldata _addressList) external;

    function removeBorrowable(IBorrowable borrowable) external;

    function disableBorrowable(IBorrowable borrowable) external;

    function enableBorrowable(IBorrowable borrowable) external;

    function unwindBorrowable(IBorrowable borrowable, uint256 borowableAmount) external;

    function updatePendingStrategy(ISupplyVaultStrategy _newPendingStrategy, uint256 _notBefore) external;

    function updateStrategy() external;

    function updateFeeBps(uint256 _newFeeBps) external;

    function updateFeeTo(address _newFeeTo) external;

    function updateReallocateManager(address _newReallocateManager) external;

    function pause() external;

    function unpause() external;

    /* Voting */
    function delegates(address delegator) external view returns (address);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);

    /* Events */
    event AddBorrowable(address indexed borrowable);
    event RemoveBorrowable(address indexed borrowable);
    event EnableBorrowable(address indexed borrowable);
    event DisableBorrowable(address indexed borrowable);
    event UpdatePendingStrategy(address indexed strategy, uint256 notBefore);
    event UpdateStrategy(address indexed strategy);
    event UpdateFeeBps(uint256 newFeeBps);
    event UpdateFeeTo(address indexed newFeeTo);
    event UpdateReallocateManager(address indexed newReallocateManager);
    event UnwindBorrowable(address indexed borrowable, uint256 underlyingAmount, uint256 borrowableAmount);
    event Enter(
        address indexed who,
        address indexed token,
        uint256 tokenAmount,
        uint256 underlyingAmount,
        uint256 share
    );
    event Leave(address indexed who, uint256 share, uint256 underlyingAmount);
    event LeaveInKind(address indexed who, uint256 share);
    event Reallocate(address indexed sender, uint256 share);
    event AllocateBorrowable(address indexed borrowable, uint256 underlyingAmount, uint256 borrowableAmount);
    event DeallocateBorrowable(address indexed borrowable, uint256 borrowableAmount, uint256 underlyingAmount);

    event ApplyFee(address indexed feeTo, uint256 gain, uint256 fee, uint256 feeShare);
    event UpdateCheckpoint(uint256 checkpointBalance);
}

pragma solidity >=0.5.0;

interface IFactory {
	event LendingPoolInitialized(address indexed uniswapV2Pair, address indexed token0, address indexed token1,
		address collateral, address borrowable0, address borrowable1, uint lendingPoolId);
	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
	event NewAdmin(address oldAdmin, address newAdmin);
	event NewReservesPendingAdmin(address oldReservesPendingAdmin, address newReservesPendingAdmin);
	event NewReservesAdmin(address oldReservesAdmin, address newReservesAdmin);
	event NewReservesManager(address oldReservesManager, address newReservesManager);
	
	function admin() external view returns (address);
	function pendingAdmin() external view returns (address);
	function reservesAdmin() external view returns (address);
	function reservesPendingAdmin() external view returns (address);
	function reservesManager() external view returns (address);

	function getLendingPool(address uniswapV2Pair) external view returns (
		bool initialized, 
		uint24 lendingPoolId, 
		address collateral, 
		address borrowable0, 
		address borrowable1
	);
	function allLendingPools(uint) external view returns (address uniswapV2Pair);
	function allLendingPoolsLength() external view returns (uint);
	
	function bDeployer() external view returns (address);
	function cDeployer() external view returns (address);
	function tarotPriceOracle() external view returns (address);

	function createCollateral(address uniswapV2Pair) external returns (address collateral);
	function createBorrowable0(address uniswapV2Pair) external returns (address borrowable0);
	function createBorrowable1(address uniswapV2Pair) external returns (address borrowable1);
	function initializeLendingPool(address uniswapV2Pair) external;

	function _setPendingAdmin(address newPendingAdmin) external;
	function _acceptAdmin() external;
	function _setReservesPendingAdmin(address newPendingAdmin) external;
	function _acceptReservesAdmin() external;
	function _setReservesManager(address newReservesManager) external;
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