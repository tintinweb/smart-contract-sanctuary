// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/TransferHelper.sol";

/// @notice Transaction excutor of Path
contract ExecutorOfPath is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public name;

    string public symbol;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => bool) public isWhiteListed;

    address public dev;

    uint256 public fee; // wei

    /// @notice Swap's log.
    /// @param fromToken token's address.
    /// @param toToken token's address.
    /// @param sender Who swap
    /// @param fromAmount Input amount.
    /// @param returnAmount toToken's amount include fee amount. Not cut fee yet.
    event Swap(
        address fromToken,
        address toToken,
        address sender,
        uint256 fromAmount,
        uint256 returnAmount
    );

    event SwapCrossChain(address fromToken, address sender, uint256 fromAmount);

    event AddWhiteList(address contractAddress);

    event RemoveWhiteList(address contractAddr);

    event SetFee(uint256 fee);

    event WithdrawETH(uint256 balance);

    event Withdtraw(address token, uint256 balance);

    event SetDev(address _dev);

    modifier noExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "EXPIRED");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    constructor(
        address _dev,
        uint256 _fee,
        address _owner
    ) {
        name = "Excutor of PATH";
        symbol = "EXCUTOR_v1";
        require(_dev != address(0), "DEV_CAN_T_BE_0");
        require(_owner != address(0), "OWNER_CAN_T_BE_0");
        dev = _dev;
        fee = _fee;
        transferOwnership(_owner);
    }

    function addWhiteList(address contractAddr) public onlyOwner {
        isWhiteListed[contractAddr] = true;
        emit AddWhiteList(contractAddr);
    }

    function removeWhiteList(address contractAddr) public onlyOwner {
        isWhiteListed[contractAddr] = false;
        emit RemoveWhiteList(contractAddr);
    }

    /// @notice Excute transactions. 从转入的币中扣除手续费。
    /// @param fromToken token's address. 源币的合约地址
    /// @param toToken token's address. 目标币的合约地址。如果是跨链情况，这个参数用0地址
    /// @param approveTarget contract's address which will excute calldata 执行交易的目标合约地址
    /// @param callDataConcat calldata 交易数据
    /// @param deadLine Deadline 时间戳，超过这个时间戳就表示交易执行失败，将revert
    /// @param isCrossChain 是否是跨链
    function swap(
        address fromToken,
        address toToken,
        address approveTarget,
        uint256 fromTokenAmount,
        bytes calldata callDataConcat,
        uint256 deadLine,
        bool isCrossChain
    ) external payable noExpired(deadLine) nonReentrant {
        require(isWhiteListed[approveTarget], "NOT_WHITELIST_CONTRACT"); // 要求执行交易的目标合约地址，必须在白名单中。
        require(fromToken != address(0), "FROMTOKEN_CANT_T_BE_0"); // 源币地址不能为0
        if (!isCrossChain) {
            // 单链情况的限制条件
            require(toToken != address(0), "TOTOKEN_CAN_T_BE_0");
        } else {
            // 跨链的限制条件
            require(toToken == address(0), "TOTOKEN_MUST_BE_0"); // 跨链情况下totoken必须是0地址
        }
        uint256 _inputAmount; // 实际收到的源币的数量
        /// @dev 下面计算实际收到的源币的数量
        if (fromToken != ETH_ADDRESS) {
            uint256 _fromTokenBalanceOrigin = IERC20(fromToken).balanceOf(
                address(this)
            );
            TransferHelper.safeTransferFrom(
                fromToken,
                msg.sender,
                address(this),
                fromTokenAmount
            );
            uint256 _fromTokenBalanceNew = IERC20(fromToken).balanceOf(
                address(this)
            );
            _inputAmount = _fromTokenBalanceNew.sub(_fromTokenBalanceOrigin);
            require(
                _inputAmount > 0,
                "NO_FROM_TOKEN_TRANSFER_TO_THIS_CONTRACT"
            );
        } else {
            _inputAmount = msg.value;
        }
        uint256 feeAmount = 0; // 手续费的数量
        /// @dev 计算手续费的数量
        if (fee > 0 && dev != address(0)) {
            feeAmount = _inputAmount.mul(fee).div(10**18);
        }
        uint256 fromAmount = _inputAmount.sub(feeAmount); // 除去去手续费，将授权目标合约转走的数量。
        TransferHelper.safeApprove(fromToken, approveTarget, fromAmount); // 授权目标合约转走源币
        /// @dev 将手续费转到dev地址
        if (fee > 0 && dev != address(0) && fromToken != ETH_ADDRESS) {
            TransferHelper.safeTransfer(fromToken, dev, feeAmount);
        } else if (fee > 0 && dev != address(0) && fromToken == ETH_ADDRESS) {
            TransferHelper.safeTransferETH(dev, feeAmount);
        }
        uint256 _toTokenBalanceOrigin = 0; // 兑换成目标币的数量。
        if (!isCrossChain) {
            // 如果是单链情况，先记录一下目标合约执行交易前的totoken的余额。后面计算余额差给到用户地址。
            _toTokenBalanceOrigin = toToken == ETH_ADDRESS
                ? address(this).balance
                : IERC20(toToken).balanceOf(address(this));
        }
        (bool success, ) = approveTarget.call{
            value: fromToken == ETH_ADDRESS ? fromAmount : 0
        }(callDataConcat);
        uint256 returnAmt = 0;
        require(success, "EXTERNAL_SWAP_EXECUTION_FAILED");
        /// @dev 如果是跨链情况，目标合约执行交易后就结束了。
        if (!isCrossChain) {
            // 如果是单链的情况，把换出来的币转给用户地址。
            returnAmt = toToken == ETH_ADDRESS
                ? address(this).balance.sub(_toTokenBalanceOrigin)
                : IERC20(toToken).balanceOf(address(this)).sub(
                    _toTokenBalanceOrigin
                );
            require(returnAmt >= 0, "RETURN_AMOUNT_IS_0");
            if (toToken == ETH_ADDRESS) {
                TransferHelper.safeTransferETH(msg.sender, returnAmt);
            } else {
                TransferHelper.safeTransfer(toToken, msg.sender, returnAmt);
            }
            emit Swap(
                fromToken,
                toToken,
                msg.sender,
                fromTokenAmount,
                returnAmt
            );
        } else {
            emit SwapCrossChain(fromToken, msg.sender, fromTokenAmount);
        }
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetFee(_fee);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        TransferHelper.safeTransferETH(owner(), balance);
        emit WithdrawETH(balance);
    }

    function withdtraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransfer(token, owner(), balance);
        emit Withdtraw(token, balance);
    }

    function setDev(address _dev) external onlyOwner {
        require(_dev != address(0), "0_ADDRESS_CAN_T_BE_A_DEV");
        dev = _dev;
        emit SetDev(_dev);
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

    constructor() {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}