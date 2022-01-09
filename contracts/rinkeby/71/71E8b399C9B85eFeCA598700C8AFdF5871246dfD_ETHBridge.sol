// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev ETH side of Drife Bridge smart contracts setup to move DRF tokens across
 * Ethereum and other EVM compatible chains like Binance Smart Chain.
 *   - Min swap value: 10 DRF (configurable)
 *   - Max swap value: Balance amount available
 *   - Swap fee: 0.1% (configurable)
 *   - Finality: (~75 sec.)
 *     - ETH: 7 blocks
 *     - BSC: 15 blocks
 *   - Reference implementation: https://github.com/anyswap/mBTC/blob/master/contracts/ProxySwapAsset.sol
 */
contract ETHBridge is Ownable {
    using SafeMath for uint256;

    // ETH Token contract address
    address public tokenETH;

    // List of TXs on BSC that were processed
    mapping(bytes32 => bool) txHashes;

    // Fee Rate in percentage with two units of precision after the decimal to store as integer
    // e.g. 1%, 0.05%, 0.5% multiplied by 10000 (100 * 100) become 10000, 500, 5000 respectively
    uint256 public feeRate;

    // Minimum and Maximun fee deductible for swaps
    uint256 public minFee;
    uint256 public maxFee;

    // Fee accumulated from swap out transactions
    uint256 public accumulatedFee;

    // Minimum Swap amount of DRF (10 DRF = 10 * 10**18)
    uint256 public minSwapAmount;

    // Fee Type for event logging
    enum FeeType {
        RATE,
        MAX,
        MIN
    }

    /**
     * @dev Event emitted upon the swap out call.
     * @param swapOutAddress The ETH address of the swap out initiator.
     * @param swapInAddress The BSC address to which the tokens are swapped.
     * @param amount The amount of tokens getting locked and swapped from ETH.
     */
    event SwappedOut(
        address indexed swapOutAddress,
        address indexed swapInAddress,
        uint256 amount
    );

    /**
     * @dev Event emitted upon the swap in call.
     * @param txHash Transaction hash on BSC where the swap has beed initiated.
     * @param swapInAddress The ETH address to which the tokens are swapped.
     * @param amountSent The amount of tokens to be released on ETH.
     * @param fee The amount of tokens deducted as fee for carrying out the swap.
     */
    event SwappedIn(
        bytes32 indexed txHash,
        address indexed swapInAddress,
        uint256 amountSent,
        uint256 fee
    );

    /**
     * @dev Event emitted upon changing fee params in the contract.
     * @param oldFeeParam The fee param before tx.
     * @param newFeeParam The new value of the fee param to be updated.
     * @param feeType The fee param to be updated.
     */
    event FeeUpdate(uint256 oldFeeParam, uint256 newFeeParam, FeeType feeType);

    constructor(
        address _ETHtokenAddress,
        uint256 _feeRate,
        uint256 _minSwapAmount,
        uint256 _minFee,
        uint256 _maxFee
    ) {
        tokenETH = _ETHtokenAddress;
        feeRate = _feeRate;
        minSwapAmount = _minSwapAmount;
        minFee = _minFee;
        maxFee = _maxFee;
        accumulatedFee = 0;
    }

    /**
     * @dev Initiate a token transfer from ETH to BSC.
     * @param amount The amount of tokens getting locked and swapped from ETH.
     * @param swapInAddress The address on BSC to which the tokens are swapped.
     */
    function SwapOut(uint256 amount, address swapInAddress)
        external
        returns (bool)
    {
        require(swapInAddress != address(0), "Bridge: invalid addr");
        require(amount >= minSwapAmount, "Bridge: invalid amount");

        require(
            IERC20(tokenETH).transferFrom(msg.sender, address(this), amount),
            "Bridge: invalid transfer"
        );
        emit SwappedOut(msg.sender, swapInAddress, amount);
        return true;
    }

    /**
     * @dev Initiate a token transfer from BSC to ETH.
     * @param txHash Transaction hash on BSC where the swap has been initiated.
     * @param to The address on ETH to which the tokens are swapped.
     * @param amount The amount of tokens swapped.
     */
    function SwapIn(
        bytes32 txHash,
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        require(txHash != bytes32(0), "Bridge: invalid tx");
        require(to != address(0), "Bridge: invalid addr");
        require(txHashes[txHash] == false, "Bridge: dup tx");
        txHashes[txHash] = true;

        // Calculate fee based on `feeRate` and to be at least `minFee` and at most `maxFee`
        uint256 fee = amount.mul(feeRate) >= minFee &&
            amount.mul(feeRate) <= maxFee
            ? amount.mul(feeRate)
            : amount.mul(feeRate) < minFee
            ? minFee
            : maxFee;

        // Automatically check for amount > fee before transferring otherwise throws safemath error
        require(
            IERC20(tokenETH).transfer(
                to,
                amount.sub(fee, "Bridge: invalid amount")
            ),
            "Bridge: invalid transfer"
        );
        accumulatedFee = accumulatedFee.add(fee);

        emit SwappedIn(txHash, to, amount.sub(fee), fee);
        return true;
    }

    /**
     * @dev Update the fee rate on the current chain. Only callable by the owner
     * @param newFeeRate uint - the new fee rate that applies to the current side of the bridge
     */
    function updateFeeRate(uint256 newFeeRate) external onlyOwner {
        uint256 oldFeeRate = feeRate;
        feeRate = newFeeRate;
        emit FeeUpdate(oldFeeRate, newFeeRate, FeeType.RATE);
    }

    /**
     * @dev Update the max fee on the current chain. Only callable by the owner
     * @param newMaxFee uint - the new max fee that applies to the current side bridge
     */
    function updateMaxFee(uint256 newMaxFee) external onlyOwner {
        uint256 oldMaxFee = maxFee;
        maxFee = newMaxFee;
        emit FeeUpdate(oldMaxFee, newMaxFee, FeeType.MAX);
    }

    /**
     * @dev Update the min fee on the current chain. Only callable by the owner
     * @param newMinFee uint - the new max fee that applies to the current side bridge
     */
    function updateMinFee(uint256 newMinFee) external onlyOwner {
        uint256 oldMinFee = minFee;
        minFee = newMinFee;
        emit FeeUpdate(oldMinFee, newMinFee, FeeType.MIN);
    }

    /**
     * @dev Withdraw liquidity from the bridge contract to an address. Only callable by the owner.
     * @param to The address to which the tokens are swapped.
     * @param amount The amount of tokens to be released.
     */
    function withdrawLiquidity(address to, uint256 amount) external onlyOwner {
        IERC20(tokenETH).transfer(to, amount);
    }

    /**
     * @dev Withdraw liquidity from the bridge contract to an address. Only callable by the owner.
     * @param to The address to which the tokens are swapped.
     */
    function withdrawAccumulatedFee(address to) external onlyOwner {
        IERC20(tokenETH).transfer(to, accumulatedFee);
        accumulatedFee = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}