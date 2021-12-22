// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ISwapRouter} from "../integrations/uniswap/IUniswapV3.sol";
import {BytesLib} from "../integrations/uniswap/BytesLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {CreditManager} from "../credit/CreditManager.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title UniswapV3 Router adapter
contract UniswapV3Adapter is ISwapRouter, ReentrancyGuard {
    using BytesLib for bytes;
    using SafeMath for uint256;

    ICreditManager public creditManager;
    ICreditFilter public creditFilter;
    address public router;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev Constructor
    /// @param _creditManager Address Credit manager
    /// @param _router Address of ISwapRouter
    constructor(address _creditManager, address _router) {
        require(
            _creditManager != address(0) && _router != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());
        router = _router;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountOut)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            router,
            params.tokenIn
        );

        ExactInputSingleParams memory paramsUpdate = params;
        paramsUpdate.recipient = creditAccount;

        // 0x414bf389 = exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))
        bytes memory data = abi.encodeWithSelector(
            bytes4(0x414bf389), // +
            paramsUpdate
        );

        uint256 balanceInBefore = IERC20(paramsUpdate.tokenIn).balanceOf(
            creditAccount
        );

        uint256 balanceOutBefore = IERC20(paramsUpdate.tokenOut).balanceOf(
            creditAccount
        );

        (amountOut) = abi.decode(
            creditManager.executeOrder(msg.sender, router, data),
            (uint256)
        );

        creditFilter.checkCollateralChange(
            creditAccount,
            params.tokenIn,
            params.tokenOut,
            balanceInBefore.sub(
                IERC20(paramsUpdate.tokenIn).balanceOf(creditAccount)
            ),
            IERC20(paramsUpdate.tokenOut).balanceOf(creditAccount).sub(
                balanceOutBefore
            )
        );
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountOut)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        (address tokenIn, address tokenOut) = _extractTokens(params.path);

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            router,
            tokenIn
        );

        ExactInputParams memory paramsUpdate = params;
        paramsUpdate.recipient = creditAccount;

        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount);
        uint256 balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount);

        {
            // 0xc04b8d59 = exactInput((bytes,address,uint256,uint256,uint256))
            bytes memory data = abi.encodeWithSelector(
                bytes4(0xc04b8d59), // +
                paramsUpdate
            );

            (amountOut) = abi.decode(
                creditManager.executeOrder(msg.sender, router, data),
                (uint256)
            );
        }

        creditFilter.checkCollateralChange(
            creditAccount,
            tokenIn,
            tokenOut,
            balanceInBefore.sub(IERC20(tokenIn).balanceOf(creditAccount)),
            IERC20(tokenOut).balanceOf(creditAccount).sub(balanceOutBefore)
        );
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountIn)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            router,
            params.tokenIn
        );

        ExactOutputSingleParams memory paramsUpdate = params;
        paramsUpdate.recipient = creditAccount;

        //
        bytes memory data = abi.encodeWithSelector(
            bytes4(0xdb3e2198), //+
            paramsUpdate
        );

        uint256 balanceInBefore = IERC20(paramsUpdate.tokenIn).balanceOf(
            creditAccount
        );

        uint256 balanceOutBefore = IERC20(paramsUpdate.tokenOut).balanceOf(
            creditAccount
        );

        (amountIn) = abi.decode(
            creditManager.executeOrder(msg.sender, router, data),
            (uint256)
        );

        creditFilter.checkCollateralChange(
            creditAccount,
            params.tokenIn,
            params.tokenOut,
            balanceInBefore.sub(
                IERC20(paramsUpdate.tokenIn).balanceOf(creditAccount)
            ),
            IERC20(paramsUpdate.tokenOut).balanceOf(creditAccount).sub(
                balanceOutBefore
            )
        );
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountIn)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        (address tokenOut, address tokenIn) = _extractTokens(params.path);

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            router,
            tokenIn
        );

        ExactOutputParams memory paramsUpdate = params;
        paramsUpdate.recipient = creditAccount;

        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount);
        uint256 balanceOutBefore = IERC20(tokenOut).balanceOf(creditAccount);

        {
            bytes memory data = abi.encodeWithSelector(
                bytes4(0xf28c0498), // exactOutput((bytes,address,uint256,uint256,uint256))
                paramsUpdate
            );

            (amountIn) = abi.decode(
                creditManager.executeOrder(msg.sender, router, data),
                (uint256)
            );
        }

        creditFilter.checkCollateralChange(
            creditAccount,
            tokenIn,
            tokenOut,
            balanceInBefore.sub(IERC20(tokenIn).balanceOf(creditAccount)),
            IERC20(tokenOut).balanceOf(creditAccount).sub(balanceOutBefore)
        );
    }

    function _extractTokens(bytes memory path)
        internal
        pure
        returns (address tokenA, address tokenB)
    {
        tokenA = path.toAddress(0);
        tokenB = path.toAddress(path.length - ADDR_SIZE);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter  {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.8.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint24)
    {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

interface ICreditFilter {
    // Emits each time token is allowed or liquidtion threshold changed
    event TokenAllowed(address indexed token, uint256 liquidityThreshold);

   // Emits each time token is allowed or liquidtion threshold changed
    event TokenForbidden(address indexed token);

    // Emits each time contract is allowed or adapter changed
    event ContractAllowed(address indexed protocol, address indexed adapter);

    // Emits each time contract is forbidden
    event ContractForbidden(address indexed protocol);

    // Emits each time when fast check parameters are updated
    event NewFastCheckParameters(uint256 chiThreshold, uint256 fastCheckDelay);

    event TransferAccountAllowed(
        address indexed from,
        address indexed to,
        bool state
    );

    event TransferPluginAllowed(
        address indexed pugin,
        bool state
    );

    event PriceOracleUpdated(address indexed newPriceOracle);

    //
    // STATE-CHANGING FUNCTIONS
    //

    /// @dev Adds token to the list of allowed tokens
    /// @param token Address of allowed token
    /// @param liquidationThreshold The constant showing the maximum allowable ratio of Loan-To-Value for the i-th asset.
    function allowToken(address token, uint256 liquidationThreshold) external;

    /// @dev Adds contract to the list of allowed contracts
    /// @param targetContract Address of contract to be allowed
    /// @param adapter Adapter contract address
    function allowContract(address targetContract, address adapter) external;

    /// @dev Forbids contract and removes it from the list of allowed contracts
    /// @param targetContract Address of allowed contract
    function forbidContract(address targetContract) external;

    /// @dev Checks financial order and reverts if tokens aren't in list or collateral protection alerts
    /// @param creditAccount Address of credit account
    /// @param tokenIn Address of token In in swap operation
    /// @param tokenOut Address of token Out in swap operation
    /// @param amountIn Amount of tokens in
    /// @param amountOut Amount of tokens out
    function checkCollateralChange(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external;

    function checkMultiTokenCollateral(
        address creditAccount,
        uint256[] memory amountIn,
        uint256[] memory amountOut,
        address[] memory tokenIn,
        address[] memory tokenOut
    ) external;

    /// @dev Connects credit managaer, hecks that all needed price feeds exists and finalize config
    function connectCreditManager(address poolService) external;

    /// @dev Sets collateral protection for new credit accounts
    function initEnabledTokens(address creditAccount) external;

    function checkAndEnableToken(address creditAccount, address token) external;

    //
    // GETTERS
    //

    /// @dev Returns quantity of contracts in allowed list
    function allowedContractsCount() external view returns (uint256);

    /// @dev Returns of contract address from the allowed list by its id
    function allowedContracts(uint256 id) external view returns (address);

    /// @dev Reverts if token isn't in token allowed list
    function revertIfTokenNotAllowed(address token) external view;

    /// @dev Returns true if token is in allowed list otherwise false
    function isTokenAllowed(address token) external view returns (bool);

    /// @dev Returns quantity of tokens in allowed list
    function allowedTokensCount() external view returns (uint256);

    /// @dev Returns of token address from allowed list by its id
    function allowedTokens(uint256 id) external view returns (address);

    /// @dev Calculates total value for provided address
    /// More: https://dev.gearbox.fi/developers/credit/economy#total-value
    ///
    /// @param creditAccount Token creditAccount address
    function calcTotalValue(address creditAccount)
        external
        view
        returns (uint256 total);

    /// @dev Calculates Threshold Weighted Total Value
    /// More: https://dev.gearbox.fi/developers/credit/economy#threshold-weighted-value
    ///
    ///@param creditAccount Credit account address
    function calcThresholdWeightedValue(address creditAccount)
        external
        view
        returns (uint256 total);

    function contractToAdapter(address allowedContract)
        external
        view
        returns (address);

    /// @dev Returns address of underlying token
    function underlyingToken() external view returns (address);

    /// @dev Returns address & balance of token by the id of allowed token in the list
    /// @param creditAccount Credit account address
    /// @param id Id of token in allowed list
    /// @return token Address of token
    /// @return balance Token balance
    function getCreditAccountTokenById(address creditAccount, uint256 id)
        external
        view
        returns (
            address token,
            uint256 balance,
            uint256 tv,
            uint256 twv
        );

    /**
     * @dev Calculates health factor for the credit account
     *
     *         sum(asset[i] * liquidation threshold[i])
     *   Hf = --------------------------------------------
     *             borrowed amount + interest accrued
     *
     *
     * More info: https://dev.gearbox.fi/developers/credit/economy#health-factor
     *
     * @param creditAccount Credit account address
     * @return Health factor in percents (see PERCENTAGE FACTOR in PercentageMath.sol)
     */
    function calcCreditAccountHealthFactor(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Calculates credit account interest accrued
    /// More: https://dev.gearbox.fi/developers/credit/economy#interest-rate-accrued
    ///
    /// @param creditAccount Credit account address
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Return enabled tokens - token masks where each bit is "1" is token is enabled
    function enabledTokens(address creditAccount)
        external
        view
        returns (uint256);

    function liquidationThresholds(address token)
        external
        view
        returns (uint256);

    function priceOracle() external view returns (address);

    function updateUnderlyingTokenLiquidationThreshold() external;

    function revertIfCantIncreaseBorrowing(
        address creditAccount,
        uint256 minHealthFactor
    ) external view;

    function revertIfAccountTransferIsNotAllowed(
        address onwer,
        address creditAccount
    ) external view;

    function approveAccountTransfers(address from, bool state) external;

    function allowanceForAccountTransfers(address from, address to)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {IAppCreditManager} from "./app/IAppCreditManager.sol";
import {DataTypes} from "../libraries/data/Types.sol";


/// @title Credit Manager interface
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
interface ICreditManager is IAppCreditManager {
    // Emits each time when the credit account is opened
    event OpenCreditAccount(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed creditAccount,
        uint256 amount,
        uint256 borrowAmount,
        uint256 referralCode
    );

    // Emits each time when the credit account is closed
    event CloseCreditAccount(
        address indexed owner,
        address indexed to,
        uint256 remainingFunds
    );

    // Emits each time when the credit account is liquidated
    event LiquidateCreditAccount(
        address indexed owner,
        address indexed liquidator,
        uint256 remainingFunds
    );

    // Emits each time when borrower increases borrowed amount
    event IncreaseBorrowedAmount(address indexed borrower, uint256 amount);

    // Emits each time when borrower adds collateral
    event AddCollateral(
        address indexed onBehalfOf,
        address indexed token,
        uint256 value
    );

    // Emits each time when the credit account is repaid
    event RepayCreditAccount(address indexed owner, address indexed to);

    // Emit each time when financial order is executed
    event ExecuteOrder(address indexed borrower, address indexed target);

    // Emits each time when new fees are set
    event NewParameters(
        uint256 minAmount,
        uint256 maxAmount,
        uint256 maxLeverage,
        uint256 feeInterest,
        uint256 feeLiquidation,
        uint256 liquidationDiscount
    );

    event TransferAccount(address indexed oldOwner, address indexed newOwner);

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    /**
     * @dev Opens credit account and provides credit funds.
     * - Opens credit account (take it from account factory)
     * - Transfers trader /farmers initial funds to credit account
     * - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
     * - Emits OpenCreditAccount event
     * Function reverts if user has already opened position
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
     *
     * @param amount Borrowers own funds
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param leverageFactor Multiplier to borrowers own funds
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external override;

    /**
     * @dev Closes credit account
     * - Swaps all assets to underlying one using default swap protocol
     * - Pays borrowed amount + interest accrued + fees back to the pool by calling repayCreditAccount
     * - Transfers remaining funds to the trader / farmer
     * - Closes the credit account and return it to account factory
     * - Emits CloseCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#close-credit-account
     *
     * @param to Address to send remaining funds
     * @param paths Exchange type data which provides paths + amountMinOut
     */
    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external
        override;

    /**
     * @dev Liquidates credit account
     * - Transfers discounted total credit account value from liquidators account
     * - Pays borrowed funds + interest + fees back to pool, than transfers remaining funds to credit account owner
     * - Transfer all assets from credit account to liquidator ("to") account
     * - Returns credit account to factory
     * - Emits LiquidateCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#liquidate-credit-account
     *
     * @param borrower Borrower address
     * @param to Address to transfer all assets from credit account
     * @param force If true, use transfer function for transferring tokens instead of safeTransfer
     */
    function liquidateCreditAccount(
        address borrower,
        address to,
        bool force
    ) external;

    /// @dev Repays credit account
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#repay-credit-account
    ///
    /// @param to Address to send credit account assets
    function repayCreditAccount(address to) external override;

    /// @dev Repays credit account with ETH. Restricted to be called by WETH Gateway only
    ///
    /// @param borrower Address of borrower
    /// @param to Address to send credit account assets
    function repayCreditAccountETH(address borrower, address to)
        external
        returns (uint256);

    /// @dev Increases borrowed amount by transferring additional funds from
    /// the pool if after that HealthFactor > minHealth
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrowed-amount
    ///
    /// @param amount Amount to increase borrowed amount
    function increaseBorrowedAmount(uint256 amount) external override;

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external override;

    /// @dev Returns true if the borrower has opened a credit account
    /// @param borrower Borrower account
    function hasOpenedCreditAccount(address borrower)
        external
        view
        override
        returns (bool);

    /// @dev Calculates Repay amount = borrow amount + interest accrued + fee
    ///
    /// More info: https://dev.gearbox.fi/developers/credit/economy#repay
    ///           https://dev.gearbox.fi/developers/credit/economy#liquidate
    ///
    /// @param borrower Borrower address
    /// @param isLiquidated True if calculated repay amount for liquidator
    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        override
        returns (uint256);

    /// @dev Returns minimal amount for open credit account
    function minAmount() external view returns (uint256);

    /// @dev Returns maximum amount for open credit account
    function maxAmount() external view returns (uint256);

    /// @dev Returns maximum leveraged factor allowed for this pool
    function maxLeverageFactor() external view returns (uint256);

    /// @dev Returns underlying token address
    function underlyingToken() external view returns (address);

    /// @dev Returns address of connected pool
    function poolService() external view returns (address);

    /// @dev Returns address of CreditFilter
    function creditFilter() external view returns (ICreditFilter);

    /// @dev Returns address of CreditFilter
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Executes filtered order on credit account which is connected with particular borrowers
    /// @param borrower Borrower address
    /// @param target Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    ) external returns (bytes memory);

    /// @dev Approves token for msg.sender's credit account
    function approve(address targetContract, address token) external;

    /// @dev Approve tokens for credit accounts. Restricted for adapters only
    function provideCreditAccountAllowance(
        address creditAccount,
        address toContract,
        address token
    ) external;

    function transferAccountOwnership(address newOwner) external;

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        override
        returns (address);

//    function feeSuccess() external view returns (uint256);

    function feeInterest() external view returns (uint256);

    function feeLiquidation() external view returns (uint256);

    function liquidationDiscount() external view returns (uint256);

    function minHealthFactor() external view returns (uint256);

    function defaultSwapContract() external view override returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IAccountFactory} from "../interfaces/IAccountFactory.sol";
import {ICreditAccount} from "../interfaces/ICreditAccount.sol";
import {IPoolService} from "../interfaces/IPoolService.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {AddressProvider} from "../core/AddressProvider.sol";
import {ACLTrait} from "../core/ACLTrait.sol";

import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/data/Types.sol";


/// @title Credit Manager
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
///
/// #define roughEq(uint256 a, uint256 b) bool =
///     a == b || a + 1 == b || a == b + 1;
///
/// #define borrowedPlusInterest(address creditAccount) uint =
///     let borrowedAmount, cumIndexAtOpen := getCreditAccountParameters(creditAccount) in
///     let curCumulativeIndex := IPoolService(poolService).calcLinearCumulative_RAY() in
///         borrowedAmount.mul(curCumulativeIndex).div(cumIndexAtOpen);
contract CreditManager is ICreditManager, ACLTrait, ReentrancyGuard {
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    // Minimal amount for open credit account
    uint256 public override minAmount;

    //  Maximum amount for open credit account
    uint256 public override maxAmount;

    // Maximum leveraged factor allowed for this pool
    uint256 public override maxLeverageFactor;

    // Minimal allowed Hf after increasing borrow amount
    uint256 public override minHealthFactor;

    // Mapping between borrowers'/farmers' address and credit account
    mapping(address => address) public override creditAccounts;

    // Account manager - provides credit accounts to pool
    IAccountFactory internal _accountFactory;

    // Credit Manager filter
    ICreditFilter public override creditFilter;

    // Underlying token address
    address public override underlyingToken;

    // Address of connected pool
    address public override poolService;

    // Address of WETH token
    address public wethAddress;

    // Address of WETH Gateway
    address public wethGateway;

    // Default swap contracts - uses for automatic close
    address public override defaultSwapContract;

    uint256 public override feeInterest;

    uint256 public override feeLiquidation;

    uint256 public override liquidationDiscount;

    // Contract version
    uint constant public version = 1;

    //
    // MODIFIERS
    //

    /// @dev Restricts actions for users with opened credit accounts only
    modifier allowedAdaptersOnly(address targetContract) {
        require(
            creditFilter.contractToAdapter(targetContract) == msg.sender,
            Errors.CM_TARGET_CONTRACT_iS_NOT_ALLOWED
        );
        _;
    }

    /// @dev Constructor
    /// @param _addressProvider Address Repository for upgradable contract model
    /// @param _minAmount Minimal amount for open credit account
    /// @param _maxAmount Maximum amount for open credit account
    /// @param _maxLeverage Maximum allowed leverage factor
    /// @param _poolService Address of pool service
    /// @param _creditFilterAddress CreditFilter address. It should be finalised
    /// @param _defaultSwapContract Default IUniswapV2Router02 contract to change assets in case of closing account
    constructor(
        address _addressProvider,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _maxLeverage,
        address _poolService,
        address _creditFilterAddress,
        address _defaultSwapContract
    ) ACLTrait(_addressProvider) {
        require(
            _addressProvider != address(0) &&
                _poolService != address(0) &&
                _creditFilterAddress != address(0) &&
                _defaultSwapContract != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        AddressProvider addressProvider = AddressProvider(_addressProvider); // T:[CM-1]
        poolService = _poolService; // T:[CM-1]
        underlyingToken = IPoolService(_poolService).underlyingToken(); // T:[CM-1]

        wethAddress = addressProvider.getWethToken(); // T:[CM-1]
        wethGateway = addressProvider.getWETHGateway(); // T:[CM-1]
        defaultSwapContract = _defaultSwapContract; // T:[CM-1]
        _accountFactory = IAccountFactory(addressProvider.getAccountFactory()); // T:[CM-1]

        _setParams(
            _minAmount,
            _maxAmount,
            _maxLeverage,
            Constants.FEE_INTEREST,
            Constants.FEE_LIQUIDATION,
            Constants.LIQUIDATION_DISCOUNTED_SUM
        ); // T:[CM-1]

        creditFilter = ICreditFilter(_creditFilterAddress); // T:[CM-1]
    }

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    /**
     * @dev Opens credit account and provides credit funds.
     * - Opens credit account (take it from account factory^1)
     * - Transfers trader /farmers initial funds to credit account
     * - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
     * - Emits OpenCreditAccount event
     * Function reverts if user has already opened position
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
     *
     * @param amount Borrowers own funds
     * @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
     *  or a different address if the beneficiary is a different wallet
     * @param leverageFactor Multiplier to borrowers own funds
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     *
     * #if_succeeds {:msg "A credit account with the correct balance is opened."}
     *      let newAccount := creditAccounts[onBehalfOf] in
     *      newAccount != address(0) &&
     *          IERC20(underlyingToken).balanceOf(newAccount) >=
     *          amount.add(amount.mul(leverageFactor).div(Constants.LEVERAGE_DECIMALS));
     *
     * #if_succeeds {:msg "Sender looses amount tokens." }
     *      IERC20(underlyingToken).balanceOf(msg.sender) == old(IERC20(underlyingToken).balanceOf(msg.sender)) - amount;
     *
     * #if_succeeds {:msg "Pool provides correct leverage (amount x leverageFactor)." }
     *      IERC20(underlyingToken).balanceOf(poolService) == old(IERC20(underlyingToken).balanceOf(poolService)) - amount.mul(leverageFactor).div(Constants.LEVERAGE_DECIMALS);
     *
     * #if_succeeds {:msg "The new account is healthy."}
     *      creditFilter.calcCreditAccountHealthFactor(creditAccounts[onBehalfOf]) >= PercentageMath.PERCENTAGE_FACTOR;
     *
     * #if_succeeds {:msg "The new account has balance <= 1 for all tokens other than the underlying token."}
     *     let newAccount := creditAccounts[onBehalfOf] in
     *         forall (uint i in 1...creditFilter.allowedTokensCount())
     *             IERC20(creditFilter.allowedTokens(i)).balanceOf(newAccount) <= 1;
     */
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    )
        external
        override
        whenNotPaused // T:[CM-39]
        nonReentrant
    {
        // Checks that amount is in limits
        require(
            amount >= minAmount &&
                amount <= maxAmount &&
                leverageFactor > 0 &&
                leverageFactor <= maxLeverageFactor,
            Errors.CM_INCORRECT_PARAMS
        ); // T:[CM-2]

        // Checks that user "onBehalfOf" has no opened accounts
        //        require(
        //            !hasOpenedCreditAccount(onBehalfOf) && onBehalfOf != address(0),
        //            Errors.CM_ZERO_ADDRESS_OR_USER_HAVE_ALREADY_OPEN_CREDIT_ACCOUNT
        //        ); // T:[CM-3]

        _checkAccountTransfer(onBehalfOf);

        // borrowedAmount = amount * leverageFactor
        uint256 borrowedAmount = amount.mul(leverageFactor).div(
            Constants.LEVERAGE_DECIMALS
        ); // T:[CM-7]

        // Get Reusable Credit account creditAccount
        address creditAccount = _accountFactory.takeCreditAccount(
            borrowedAmount,
            IPoolService(poolService).calcLinearCumulative_RAY()
        ); // T:[CM-5]

        // Initializes enabled tokens for the account. Enabled tokens is a bit mask which
        // holds information which tokens were used by user
        creditFilter.initEnabledTokens(creditAccount); // T:[CM-5]

        // Transfer pool tokens to new credit account
        IPoolService(poolService).lendCreditAccount(
            borrowedAmount,
            creditAccount
        ); // T:[CM-7]

        // Transfer borrower own fund to credit account
        IERC20(underlyingToken).safeTransferFrom(
            msg.sender,
            creditAccount,
            amount
        ); // T:[CM-6]

        // link credit account address with borrower address
        creditAccounts[onBehalfOf] = creditAccount; // T:[CM-5]

        // emit new event
        emit OpenCreditAccount(
            msg.sender,
            onBehalfOf,
            creditAccount,
            amount,
            borrowedAmount,
            referralCode
        ); // T:[CM-8]
    }

    /**
     * @dev Closes credit account
     * - Swaps all assets to underlying one using default swap protocol
     * - Pays borrowed amount + interest accrued + fees back to the pool by calling repayCreditAccount
     * - Transfers remaining funds to the trader / farmer
     * - Closes the credit account and return it to account factory
     * - Emits CloseCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#close-credit-account
     *
     * @param to Address to send remaining funds
     * @param paths Exchange type data which provides paths + amountMinOut
     *
     * #if_succeeds {:msg "Can only be called by account holder"} old(creditAccounts[msg.sender]) != address(0x0);
     * #if_succeeds {:msg "Can only close healthy accounts" } old(creditFilter.calcCreditAccountHealthFactor(creditAccounts[msg.sender])) > PercentageMath.PERCENTAGE_FACTOR;
     * #if_succeeds {:msg "If this succeeded the pool gets paid at least borrowed + interest"}
     *    let minAmountOwedToPool := old(borrowedPlusInterest(creditAccounts[msg.sender])) in
     *        IERC20(underlyingToken).balanceOf(poolService) >= old(IERC20(underlyingToken).balanceOf(poolService)).add(minAmountOwedToPool);
     */
    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external
        override
        whenNotPaused // T:[CM-39]
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(msg.sender); // T: [CM-9, 44]

        // Converts all assets to underlying one. _convertAllAssetsToUnderlying is virtual
        _convertAllAssetsToUnderlying(creditAccount, paths); // T: [CM-44]

        // total value equals underlying assets after converting all assets
        uint256 totalValue = IERC20(underlyingToken).balanceOf(creditAccount); // T: [CM-44]

        (, uint256 remainingFunds) = _closeCreditAccountImpl(
            creditAccount,
            Constants.OPERATION_CLOSURE,
            totalValue,
            msg.sender,
            address(0),
            to
        ); // T: [CM-44]

        emit CloseCreditAccount(msg.sender, to, remainingFunds); // T: [CM-44]
    }

    /**
     * @dev Liquidates credit account
     * - Transfers discounted total credit account value from liquidators account
     * - Pays borrowed funds + interest + fees back to pool, than transfers remaining funds to credit account owner
     * - Transfer all assets from credit account to liquidator ("to") account
     * - Returns credit account to factory
     * - Emits LiquidateCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#liquidate-credit-account
     *
     * @param borrower Borrower address
     * @param to Address to transfer all assets from credit account
     *
     * #if_succeeds {:msg "Can only be called by account holder"} old(creditAccounts[msg.sender]) != address(0x0);
     * #if_succeeds {:msg "Can only liquidate an un-healthy accounts" } old(creditFilter.calcCreditAccountHealthFactor(creditAccounts[msg.sender])) < PercentageMath.PERCENTAGE_FACTOR;
     */
    function liquidateCreditAccount(
        address borrower,
        address to,
        bool force
    )
        external
        override
        whenNotPaused // T:[CM-39]
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(borrower); // T: [CM-9]

        // transfers assets to "to" address and compute total value (tv) & threshold weighted value (twv)
        (uint256 totalValue, uint256 tvw) = _transferAssetsTo(
            creditAccount,
            to,
            force
        ); // T:[CM-13, 16, 17]

        // Checks that current Hf < 1
        require(
            tvw <
                creditFilter
                .calcCreditAccountAccruedInterest(creditAccount)
                .mul(PercentageMath.PERCENTAGE_FACTOR),
            Errors.CM_CAN_LIQUIDATE_WITH_SUCH_HEALTH_FACTOR
        ); // T:[CM-13, 16, 17]

        // Liquidate credit account
        (, uint256 remainingFunds) = _closeCreditAccountImpl(
            creditAccount,
            Constants.OPERATION_LIQUIDATION,
            totalValue,
            borrower,
            msg.sender,
            to
        ); // T:[CM-13]

        emit LiquidateCreditAccount(borrower, msg.sender, remainingFunds); // T:[CM-13]
    }

    /// @dev Repays credit account
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#repay-credit-account
    ///
    /// @param to Address to send credit account assets
    /// #if_succeeds {:msg "Can only be called by account holder"} old(creditAccounts[msg.sender]) != address(0x0);
    /// #if_succeeds {:msg "If this succeeded the pool gets paid at least borrowed + interest"}
    ///     let minAmountOwedToPool := old(borrowedPlusInterest(creditAccounts[msg.sender])) in
    ///         IERC20(underlyingToken).balanceOf(poolService) >= old(IERC20(underlyingToken).balanceOf(poolService)).add(minAmountOwedToPool);
    function repayCreditAccount(address to)
        external
        override
        whenNotPaused // T:[CM-39]
        nonReentrant
    {
        _repayCreditAccountImpl(msg.sender, to); // T:[CM-17]
    }

    /// @dev Repay credit account with ETH. Restricted to be called by WETH Gateway only
    ///
    /// @param borrower Address of borrower
    /// @param to Address to send credit account assets
    /// #if_succeeds {:msg "If this succeeded the pool gets paid at least borrowed + interest"}
    ///     let minAmountOwedToPool := old(borrowedPlusInterest(creditAccounts[borrower])) in
    ///         IERC20(underlyingToken).balanceOf(poolService) >= old(IERC20(underlyingToken).balanceOf(poolService)).add(minAmountOwedToPool);
    function repayCreditAccountETH(address borrower, address to)
        external
        override
        whenNotPaused // T:[CM-39]
        nonReentrant
        returns (uint256)
    {
        // Checks that msg.sender is WETH Gateway
        require(msg.sender == wethGateway, Errors.CM_WETH_GATEWAY_ONLY); // T:[CM-38]

        // Difference with usual Repay is that there is borrower in repay implementation call
        return _repayCreditAccountImpl(borrower, to); // T:[WG-11]
    }

    /// @dev Implements logic for repay credit accounts
    ///
    /// @param borrower Borrower address
    /// @param to Address to transfer assets from credit account
    function _repayCreditAccountImpl(address borrower, address to)
        internal
        returns (uint256)
    {
        address creditAccount = getCreditAccountOrRevert(borrower);
        (uint256 totalValue, ) = _transferAssetsTo(creditAccount, to, false); // T:[CM-17, 23]

        (uint256 amountToPool, ) = _closeCreditAccountImpl(
            creditAccount,
            Constants.OPERATION_REPAY,
            totalValue,
            borrower,
            borrower,
            to
        ); // T:[CM-17]

        emit RepayCreditAccount(borrower, to); // T:[CM-18]
        return amountToPool;
    }

    /// @dev Implementation for all closing account procedures
    /// #if_succeeds {:msg "Credit account balances should be <= 1 for all allowed tokens after closing"}
    ///     forall (uint i in 0...creditFilter.allowedTokensCount())
    ///         IERC20(creditFilter.allowedTokens(i)).balanceOf(creditAccount) <= 1;
    function _closeCreditAccountImpl(
        address creditAccount,
        uint8 operation,
        uint256 totalValue,
        address borrower,
        address liquidator,
        address to
    ) internal returns (uint256, uint256) {
        bool isLiquidated = operation == Constants.OPERATION_LIQUIDATION;

        (
            uint256 borrowedAmount,
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        ) = _calcClosePayments(creditAccount, totalValue, isLiquidated); // T:[CM-11, 15, 17]

        if (operation == Constants.OPERATION_CLOSURE) {
            ICreditAccount(creditAccount).safeTransfer(
                underlyingToken,
                poolService,
                amountToPool
            ); // T:[CM-11]

            // close operation with loss is not allowed
            require(remainingFunds > 0, Errors.CM_CANT_CLOSE_WITH_LOSS); // T:[CM-42]

            // transfer remaining funds to borrower
            _safeTokenTransfer(
                creditAccount,
                underlyingToken,
                to,
                remainingFunds,
                false
            ); // T:[CM-11]
        }
        // LIQUIDATION
        else if (operation == Constants.OPERATION_LIQUIDATION) {
            // repay amount to pool
            IERC20(underlyingToken).safeTransferFrom(
                liquidator,
                poolService,
                amountToPool
            ); // T:[CM-14]

            // transfer remaining funds to borrower
            if (remainingFunds > 0) {
                IERC20(underlyingToken).safeTransferFrom(
                    liquidator,
                    borrower,
                    remainingFunds
                ); //T:[CM-14]
            }
        }
        // REPAY
        else {
            // repay amount to pool
            IERC20(underlyingToken).safeTransferFrom(
                msg.sender, // msg.sender in case of WETH Gateway
                poolService,
                amountToPool
            ); // T:[CM-17]
        }

        // Return creditAccount
        _accountFactory.returnCreditAccount(creditAccount); // T:[CM-21]

        // Release memory
        delete creditAccounts[borrower]; // T:[CM-27]

        // Transfer pool tokens to new credit account
        IPoolService(poolService).repayCreditAccount(
            borrowedAmount,
            profit,
            loss
        ); // T:[CM-11, 15]

        return (amountToPool, remainingFunds); // T:[CM-11]
    }

    /// @dev Collects data and call calc payments pure function during closure procedures
    /// @param creditAccount Credit account address
    /// @param totalValue Credit account total value
    /// @param isLiquidated True if calculations needed for liquidation
    function _calcClosePayments(
        address creditAccount,
        uint256 totalValue,
        bool isLiquidated
    )
        public
        view
        returns (
            uint256 _borrowedAmount,
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        )
    {
        // Gets credit account parameters
        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtCreditAccountOpen_RAY
        ) = getCreditAccountParameters(creditAccount); // T:[CM-13]

        return
            _calcClosePaymentsPure(
                totalValue,
                isLiquidated,
                borrowedAmount,
                cumulativeIndexAtCreditAccountOpen_RAY,
                IPoolService(poolService).calcLinearCumulative_RAY()
            );
    }

    /// @dev Computes all close parameters based on data
    /// @param totalValue Credit account total value
    /// @param isLiquidated True if calculations needed for liquidation
    /// @param borrowedAmount Credit account borrow amount
    /// @param cumulativeIndexAtCreditAccountOpen_RAY Cumulative index at opening credit account in RAY format
    /// @param cumulativeIndexNow_RAY Current value of cumulative index in RAY format
    function _calcClosePaymentsPure(
        uint256 totalValue,
        bool isLiquidated,
        uint256 borrowedAmount,
        uint256 cumulativeIndexAtCreditAccountOpen_RAY,
        uint256 cumulativeIndexNow_RAY
    )
        public
        view
        returns (
            uint256 _borrowedAmount,
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        )
    {
        uint256 totalFunds = isLiquidated
            ? totalValue.mul(liquidationDiscount).div(
                PercentageMath.PERCENTAGE_FACTOR
            )
            : totalValue; // T:[CM-45]

        _borrowedAmount = borrowedAmount; // T:[CM-45]

        uint256 borrowedAmountWithInterest = borrowedAmount
        .mul(cumulativeIndexNow_RAY)
        .div(cumulativeIndexAtCreditAccountOpen_RAY); // T:[CM-45]

        if (totalFunds < borrowedAmountWithInterest) {
            amountToPool = totalFunds.sub(1); // T:[CM-45]
            loss = borrowedAmountWithInterest.sub(amountToPool); // T:[CM-45]
        } else {
            amountToPool = isLiquidated
                ? totalFunds.percentMul(feeLiquidation).add(
                    borrowedAmountWithInterest
                )
                : borrowedAmountWithInterest.add(
                    borrowedAmountWithInterest.sub(borrowedAmount).percentMul(
                        feeInterest
                    )
                ); // T:[CM-45]

            if (totalFunds > amountToPool) {
                remainingFunds = totalFunds.sub(amountToPool).sub(1); // T:[CM-45]
            } else {
                amountToPool = totalFunds.sub(1); // T:[CM-45]
            }

            profit = amountToPool.sub(borrowedAmountWithInterest); // T:[CM-45]
        }
    }

    /// @dev Transfers all assets from borrower credit account to "to" account and converts WETH => ETH if applicable
    /// @param creditAccount  Credit account address
    /// @param to Address to transfer all assets to
    function _transferAssetsTo(
        address creditAccount,
        address to,
        bool force
    ) internal returns (uint256 totalValue, uint256 totalWeightedValue) {
        uint256 tokenMask;
        uint256 enabledTokens = creditFilter.enabledTokens(creditAccount);
        require(to != address(0), Errors.ZERO_ADDRESS_IS_NOT_ALLOWED);

        for (uint256 i = 0; i < creditFilter.allowedTokensCount(); i++) {
            tokenMask = 1 << i;
            if (enabledTokens & tokenMask > 0) {
                (
                    address token,
                    uint256 amount,
                    uint256 tv,
                    uint256 tvw
                ) = creditFilter.getCreditAccountTokenById(creditAccount, i); // T:[CM-14, 17, 22, 23]
                if (amount > 1) {
                    if (
                        _safeTokenTransfer(
                            creditAccount,
                            token,
                            to,
                            amount.sub(1), // Michael Egorov gas efficiency trick
                            force
                        )
                    ) {
                        totalValue = totalValue.add(tv); // T:[CM-14, 17, 22, 23]
                        totalWeightedValue = totalWeightedValue.add(tvw); // T:[CM-14, 17, 22, 23]
                    }
                }
            }
        }
    }

    /// @dev Transfers token to particular address from credit account and converts WETH => ETH if applicable
    /// @param creditAccount Address of credit account
    /// @param token Token address
    /// @param to Address to transfer asset
    /// @param amount Amount to be transferred
    /// @param force If true it will skip reverts of safeTransfer function. Used for force liquidation if there is
    /// a blocked token on creditAccount
    /// @return true if transfer were successful otherwise false
    function _safeTokenTransfer(
        address creditAccount,
        address token,
        address to,
        uint256 amount,
        bool force
    ) internal returns (bool) {
        if (token != wethAddress) {
            try
                ICreditAccount(creditAccount).safeTransfer(token, to, amount) // T:[CM-14, 17]
            {} catch {
                require(force, Errors.CM_TRANSFER_FAILED); // T:[CM-50]
                return false;
            }
        } else {
            ICreditAccount(creditAccount).safeTransfer(
                token,
                wethGateway,
                amount
            ); // T:[CM-22, 23]
            IWETHGateway(wethGateway).unwrapWETH(to, amount); // T:[CM-22, 23]
        }
        return true;
    }

    /// @dev Increases borrowed amount by transferring additional funds from
    /// the pool if after that HealthFactor > minHealth
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrowed-amount
    ///
    /// @param amount Amount to increase borrowed amount
    function increaseBorrowedAmount(uint256 amount)
        external
        override
        whenNotPaused // T:[CM-39]
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(msg.sender); // T: [CM-9, 30]

        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen
        ) = getCreditAccountParameters(creditAccount); // T:[CM-30]

        //
        uint256 newBorrowedAmount = borrowedAmount.add(amount);
        uint256 newCumulativeIndex = IPoolService(poolService)
        .calcCumulativeIndexAtBorrowMore(
            borrowedAmount,
            amount,
            cumulativeIndexAtOpen
        ); // T:[CM-30]

        require(
            newBorrowedAmount.mul(Constants.LEVERAGE_DECIMALS) <
                maxAmount.mul(maxLeverageFactor),
            Errors.CM_INCORRECT_AMOUNT
        ); // T:[CM-51]

        //
        // Increase _totalBorrowed, it used to compute forecasted interest
        IPoolService(poolService).lendCreditAccount(amount, creditAccount); // T:[CM-29]
        //
        // Set parameters for new credit account
        ICreditAccount(creditAccount).updateParameters(
            newBorrowedAmount,
            newCumulativeIndex
        ); // T:[CM-30]

        //
        creditFilter.revertIfCantIncreaseBorrowing(
            creditAccount,
            minHealthFactor
        ); // T:[CM-28]

        emit IncreaseBorrowedAmount(msg.sender, amount); // T:[CM-29]
    }

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    )
        external
        override
        whenNotPaused // T:[CM-39]
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(onBehalfOf); // T: [CM-9]
        creditFilter.checkAndEnableToken(creditAccount, token); // T:[CM-48]
        IERC20(token).safeTransferFrom(msg.sender, creditAccount, amount); // T:[CM-48]
        emit AddCollateral(onBehalfOf, token, amount); // T: [CM-48]
    }

    /// @dev Sets fees. Restricted for configurator role only
    /// @param _minAmount Minimum amount to open account
    /// @param _maxAmount Maximum amount to open account
    /// @param _maxLeverageFactor Maximum leverage factor
    /// @param _feeInterest Interest fee multiplier
    /// @param _feeLiquidation Liquidation fee multiplier (for totalValue)
    /// @param _liquidationDiscount Liquidation premium multiplier (= PERCENTAGE_FACTOR - premium)
    function setParams(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _maxLeverageFactor,
        uint256 _feeInterest,
        uint256 _feeLiquidation,
        uint256 _liquidationDiscount
    )
        public
        configuratorOnly // T:[CM-36]
    {
        _setParams(
            _minAmount,
            _maxAmount,
            _maxLeverageFactor,
            _feeInterest,
            _feeLiquidation,
            _liquidationDiscount
        );
    }

    function _setParams(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _maxLeverageFactor,
        uint256 _feeInterest,
        uint256 _feeLiquidation,
        uint256 _liquidationDiscount
    ) internal {
        require(
            _minAmount <= _maxAmount && _maxLeverageFactor > 0,
            Errors.CM_INCORRECT_PARAMS
        ); // T:[CM-34]

        minAmount = _minAmount; // T:[CM-32]
        maxAmount = _maxAmount; // T:[CM-32]

        maxLeverageFactor = _maxLeverageFactor;

        feeInterest = _feeInterest; // T:[CM-37]
        feeLiquidation = _feeLiquidation; // T:[CM-37]
        liquidationDiscount = _liquidationDiscount; // T:[CM-37]

        // Compute minHealthFactor: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrow-amount
        // LT_U = liquidationDiscount - feeLiquidation
        minHealthFactor = liquidationDiscount
        .sub(feeLiquidation)
        .mul(maxLeverageFactor.add(Constants.LEVERAGE_DECIMALS))
        .div(maxLeverageFactor); // T:[CM-41]

        if (address(creditFilter) != address(0)) {
            creditFilter.updateUnderlyingTokenLiquidationThreshold(); // T:[CM-49]
        }

        emit NewParameters(
            minAmount,
            maxAmount,
            maxLeverageFactor,
            feeInterest,
            feeLiquidation,
            liquidationDiscount
        ); // T:[CM-37]
    }

    /// @dev Approves credit account for 3rd party contract
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    function approve(address targetContract, address token)
        external
        override
        whenNotPaused // T:[CM-39]
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(msg.sender);

        // Checks that targetContract is allowed - it has non-zero address adapter
        require(
            creditFilter.contractToAdapter(targetContract) != address(0),
            Errors.CM_TARGET_CONTRACT_iS_NOT_ALLOWED
        );

        creditFilter.revertIfTokenNotAllowed(token); // ToDo: add test
        _provideCreditAccountAllowance(creditAccount, targetContract, token);
    }

    /// @dev Approve tokens for credit accounts. Restricted for adapters only
    /// @param creditAccount Credit account address
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    function provideCreditAccountAllowance(
        address creditAccount,
        address targetContract,
        address token
    )
        external
        override
        allowedAdaptersOnly(targetContract) // T:[CM-46]
        whenNotPaused // T:[CM-39]
        nonReentrant
    {
        _provideCreditAccountAllowance(creditAccount, targetContract, token); // T:[CM-35]
    }

    /// @dev Checks that credit account has enough allowance for operation by comparing existing one with x10 times more than needed
    /// @param creditAccount Credit account address
    /// @param toContract Contract to check allowance
    /// @param token Token address of contract
    function _provideCreditAccountAllowance(
        address creditAccount,
        address toContract,
        address token
    ) internal {
        // Get 10x reserve in allowance
        if (
            IERC20(token).allowance(creditAccount, toContract) <
            Constants.MAX_INT_4
        ) {
            ICreditAccount(creditAccount).approveToken(token, toContract); // T:[CM-35]
        }
    }

    /// @dev Converts all assets to underlying one using uniswap V2 protocol
    /// @param creditAccount Credit Account address
    /// @param paths Exchange type data which provides paths + amountMinOut
    function _convertAllAssetsToUnderlying(
        address creditAccount,
        DataTypes.Exchange[] calldata paths
    ) internal {
        uint256 tokenMask;
        uint256 enabledTokens = creditFilter.enabledTokens(creditAccount); // T: [CM-44]

        require(
            paths.length == creditFilter.allowedTokensCount(),
            Errors.INCORRECT_PATH_LENGTH
        ); // ToDo: check

        for (uint256 i = 1; i < paths.length; i++) {
            tokenMask = 1 << i;
            if (enabledTokens & tokenMask > 0) {
                (address tokenAddr, uint256 amount, , ) = creditFilter
                .getCreditAccountTokenById(creditAccount, i); // T: [CM-44]

                if (amount > 1) {
                    _provideCreditAccountAllowance(
                        creditAccount,
                        defaultSwapContract,
                        tokenAddr
                    ); // T: [CM-44]

                    address[] memory currentPath = paths[i].path;
                    currentPath[0] = tokenAddr;
                    currentPath[paths[i].path.length - 1] = underlyingToken;

                    bytes memory data = abi.encodeWithSelector(
                        bytes4(0x38ed1739), // "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                        amount.sub(1),
                        paths[i].amountOutMin, // T: [CM-45]
                        currentPath,
                        creditAccount,
                        block.timestamp
                    ); // T: [CM-44]

                    ICreditAccount(creditAccount).execute(
                        defaultSwapContract,
                        data
                    ); // T: [CM-44]
                }
            }
        }
    }

    /// @dev Executes filtered order on credit account which is connected with particular borrower
    /// @param borrower Borrower address
    /// @param target Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    )
        external
        override
        allowedAdaptersOnly(target) // T:[CM-46]
        whenNotPaused // T:[CM-39]
        nonReentrant
        returns (bytes memory)
    {
        address creditAccount = getCreditAccountOrRevert(borrower); // T:[CM-9]
        emit ExecuteOrder(borrower, target);
        return ICreditAccount(creditAccount).execute(target, data); // : [CM-47]
    }

    //
    // GETTERS
    //

    /// @dev Returns true if the borrower has opened a credit account
    /// @param borrower Borrower account
    function hasOpenedCreditAccount(address borrower)
        public
        view
        override
        returns (bool)
    {
        return creditAccounts[borrower] != address(0); // T:[CM-26]
    }

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        public
        view
        override
        returns (address)
    {
        address result = creditAccounts[borrower]; // T: [CM-9]
        require(result != address(0), Errors.CM_NO_OPEN_ACCOUNT); // T: [CM-9]
        return result;
    }

    /// @dev Calculates repay / liquidation amount
    /// repay amount = borrow amount + interest accrued + fee amount
    ///
    /// More info: https://dev.gearbox.fi/developers/credit/economy#repay
    /// https://dev.gearbox.fi/developers/credit/economy#liquidate
    /// @param borrower Borrower address
    /// @param isLiquidated True if calculated repay amount for liquidator
    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        override
        returns (uint256)
    {
        address creditAccount = getCreditAccountOrRevert(borrower);
        uint256 totalValue = creditFilter.calcTotalValue(creditAccount);

        (
            ,
            uint256 amountToPool,
            uint256 remainingFunds,
            ,

        ) = _calcClosePayments(creditAccount, totalValue, isLiquidated); // T:[CM-14, 17, 31]

        return isLiquidated ? amountToPool.add(remainingFunds) : amountToPool; // T:[CM-14, 17, 31]
    }

    /// @dev Gets credit account generic parameters
    /// @param creditAccount Credit account address
    /// @return borrowedAmount Amount which pool lent to credit account
    /// @return cumulativeIndexAtOpen Cumulative index at open. Used for interest calculation
    function getCreditAccountParameters(address creditAccount)
        internal
        view
        returns (uint256 borrowedAmount, uint256 cumulativeIndexAtOpen)
    {
        borrowedAmount = ICreditAccount(creditAccount).borrowedAmount();
        cumulativeIndexAtOpen = ICreditAccount(creditAccount)
        .cumulativeIndexAtOpen();
    }

    /// @dev Transfers account ownership to another account
    /// @param newOwner Address of new owner
    function transferAccountOwnership(address newOwner)
        external
        override
        whenNotPaused // T: [CM-39]
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(msg.sender); // M:[LA-1,2,3,4,5,6,7,8] // T:[CM-52,53, 54]
        _checkAccountTransfer(newOwner);
        delete creditAccounts[msg.sender]; // T:[CM-54], M:[LA-1,2,3,4,5,6,7,8]
        creditAccounts[newOwner] = creditAccount; // T:[CM-54], M:[LA-1,2,3,4,5,6,7,8]
        emit TransferAccount(msg.sender, newOwner); // T:[CM-54]
    }

    function _checkAccountTransfer(address newOwner) internal view {
        require(
            newOwner != address(0) && !hasOpenedCreditAccount(newOwner),
            Errors.CM_ZERO_ADDRESS_OR_USER_HAVE_ALREADY_OPEN_CREDIT_ACCOUNT
        ); // T:[CM-52,53]
        if (msg.sender != newOwner) {
            creditFilter.revertIfAccountTransferIsNotAllowed(
                msg.sender,
                newOwner
            ); // T:[54,55]
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Errors library
library Errors {
    //
    // COMMON
    //

    string public constant ZERO_ADDRESS_IS_NOT_ALLOWED = "Z0";
    string public constant NOT_IMPLEMENTED = "NI";
    string public constant INCORRECT_PATH_LENGTH = "PL";
    string public constant INCORRECT_ARRAY_LENGTH = "CR";
    string public constant REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY = "CP";
    string public constant REGISTERED_POOLS_ONLY = "RP";
    string public constant INCORRECT_PARAMETER = "IP";

    //
    // MATH
    //

    string public constant MATH_MULTIPLICATION_OVERFLOW = "M1";
    string public constant MATH_ADDITION_OVERFLOW = "M2";
    string public constant MATH_DIVISION_BY_ZERO = "M3";

    //
    // POOL
    //

    string public constant POOL_CONNECTED_CREDIT_MANAGERS_ONLY = "PS0";
    string public constant POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER = "PS1";
    string public constant POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT = "PS2";
    string public constant POOL_INCORRECT_WITHDRAW_FEE = "PS3";
    string public constant POOL_CANT_ADD_CREDIT_MANAGER_TWICE = "PS4";

    //
    // CREDIT MANAGER
    //

    string public constant CM_NO_OPEN_ACCOUNT = "CM1";
    string
        public constant CM_ZERO_ADDRESS_OR_USER_HAVE_ALREADY_OPEN_CREDIT_ACCOUNT =
        "CM2";

    string public constant CM_INCORRECT_AMOUNT = "CM3";
    string public constant CM_CAN_LIQUIDATE_WITH_SUCH_HEALTH_FACTOR = "CM4";
    string public constant CM_CAN_UPDATE_WITH_SUCH_HEALTH_FACTOR = "CM5";
    string public constant CM_WETH_GATEWAY_ONLY = "CM6";
    string public constant CM_INCORRECT_PARAMS = "CM7";
    string public constant CM_INCORRECT_FEES = "CM8";
    string public constant CM_MAX_LEVERAGE_IS_TOO_HIGH = "CM9";
    string public constant CM_CANT_CLOSE_WITH_LOSS = "CMA";
    string public constant CM_TARGET_CONTRACT_iS_NOT_ALLOWED = "CMB";
    string public constant CM_TRANSFER_FAILED = "CMC";
    string public constant CM_INCORRECT_NEW_OWNER = "CME";

    //
    // ACCOUNT FACTORY
    //

    string public constant AF_CANT_CLOSE_CREDIT_ACCOUNT_IN_THE_SAME_BLOCK =
        "AF1";
    string public constant AF_MINING_IS_FINISHED = "AF2";
    string public constant AF_CREDIT_ACCOUNT_NOT_IN_STOCK = "AF3";
    string public constant AF_EXTERNAL_ACCOUNTS_ARE_FORBIDDEN = "AF4";

    //
    // ADDRESS PROVIDER
    //

    string public constant AS_ADDRESS_NOT_FOUND = "AP1";

    //
    // CONTRACTS REGISTER
    //

    string public constant CR_POOL_ALREADY_ADDED = "CR1";
    string public constant CR_CREDIT_MANAGER_ALREADY_ADDED = "CR2";

    //
    // CREDIT_FILTER
    //

    string public constant CF_UNDERLYING_TOKEN_FILTER_CONFLICT = "CF0";
    string public constant CF_INCORRECT_LIQUIDATION_THRESHOLD = "CF1";
    string public constant CF_TOKEN_IS_NOT_ALLOWED = "CF2";
    string public constant CF_CREDIT_MANAGERS_ONLY = "CF3";
    string public constant CF_ADAPTERS_ONLY = "CF4";
    string public constant CF_OPERATION_LOW_HEALTH_FACTOR = "CF5";
    string public constant CF_TOO_MUCH_ALLOWED_TOKENS = "CF6";
    string public constant CF_INCORRECT_CHI_THRESHOLD = "CF7";
    string public constant CF_INCORRECT_FAST_CHECK = "CF8";
    string public constant CF_NON_TOKEN_CONTRACT = "CF9";
    string public constant CF_CONTRACT_IS_NOT_IN_ALLOWED_LIST = "CFA";
    string public constant CF_FAST_CHECK_NOT_COVERED_COLLATERAL_DROP = "CFB";
    string public constant CF_SOME_LIQUIDATION_THRESHOLD_MORE_THAN_NEW_ONE =
        "CFC";
    string public constant CF_ADAPTER_CAN_BE_USED_ONLY_ONCE = "CFD";
    string public constant CF_INCORRECT_PRICEFEED = "CFE";
    string public constant CF_TRANSFER_IS_NOT_ALLOWED = "CFF";
    string public constant CF_CREDIT_MANAGER_IS_ALREADY_SET = "CFG";

    //
    // CREDIT ACCOUNT
    //

    string public constant CA_CONNECTED_CREDIT_MANAGER_ONLY = "CA1";
    string public constant CA_FACTORY_ONLY = "CA2";

    //
    // PRICE ORACLE
    //

    string public constant PO_PRICE_FEED_DOESNT_EXIST = "PO0";
    string public constant PO_TOKENS_WITH_DECIMALS_MORE_18_ISNT_ALLOWED = "PO1";
    string public constant PO_AGGREGATOR_DECIMALS_SHOULD_BE_18 = "PO2";

    //
    // ACL
    //

    string public constant ACL_CALLER_NOT_PAUSABLE_ADMIN = "ACL1";
    string public constant ACL_CALLER_NOT_CONFIGURATOR = "ACL2";

    //
    // WETH GATEWAY
    //

    string public constant WG_DESTINATION_IS_NOT_WETH_COMPATIBLE = "WG1";
    string public constant WG_RECEIVE_IS_NOT_ALLOWED = "WG2";
    string public constant WG_NOT_ENOUGH_FUNDS = "WG3";

    //
    // LEVERAGED ACTIONS
    //

    string public constant LA_INCORRECT_VALUE = "LA1";
    string public constant LA_HAS_VALUE_WITH_TOKEN_TRANSFER = "LA2";
    string public constant LA_UNKNOWN_SWAP_INTERFACE = "LA3";
    string public constant LA_UNKNOWN_LP_INTERFACE = "LA4";
    string public constant LA_LOWER_THAN_AMOUNT_MIN = "LA5";
    string public constant LA_TOKEN_OUT_IS_NOT_COLLATERAL = "LA6";

    //
    // YEARN PRICE FEED
    //
    string public constant YPF_PRICE_PER_SHARE_OUT_OF_RANGE = "YP1";
    string public constant YPF_INCORRECT_LIMITER_PARAMETERS = "YP2";

    //
    // TOKEN DISTRIBUTOR
    //
    string public constant TD_WALLET_IS_ALREADY_CONNECTED_TO_VC = "TD1";
    string public constant TD_INCORRECT_WEIGHTS = "TD2";
    string public constant TD_NON_ZERO_BALANCE_AFTER_DISTRIBUTION = "TD3";
    string public constant TD_CONTRIBUTOR_IS_NOT_REGISTERED = "TD4";
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {DataTypes} from "../../libraries/data/Types.sol";


/// @title Optimised for front-end credit Manager interface
/// @notice It's optimised for light-weight abi
interface IAppCreditManager {
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external;

    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external;

    function repayCreditAccount(address to) external;

    function increaseBorrowedAmount(uint256 amount) external;

    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external;

    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        returns (uint256);

    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    function hasOpenedCreditAccount(address borrower)
        external
        view
        returns (bool);

    function defaultSwapContract() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title DataType library
/// @notice Contains data types used in data compressor.
library DataTypes {
    struct Exchange {
        address[] path;
        uint256 amountOutMin;
    }

    struct TokenBalance {
        address token;
        uint256 balance;
        bool isAllowed;
    }

    struct ContractAdapter {
        address allowedContract;
        address adapter;
    }

    struct CreditAccountData {
        address addr;
        address borrower;
        bool inUse;
        address creditManager;
        address underlyingToken;
        uint256 borrowedAmountPlusInterest;
        uint256 totalValue;
        uint256 healthFactor;
        uint256 borrowRate;
        TokenBalance[] balances;
    }

    struct CreditAccountDataExtended {
        address addr;
        address borrower;
        bool inUse;
        address creditManager;
        address underlyingToken;
        uint256 borrowedAmountPlusInterest;
        uint256 totalValue;
        uint256 healthFactor;
        uint256 borrowRate;
        TokenBalance[] balances;
        uint256 repayAmount;
        uint256 liquidationAmount;
        bool canBeClosed;
        uint256 borrowedAmount;
        uint256 cumulativeIndexAtOpen;
        uint256 since;
    }

    struct CreditManagerData {
        address addr;
        bool hasAccount;
        address underlyingToken;
        bool isWETH;
        bool canBorrow;
        uint256 borrowRate;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 maxLeverageFactor;
        uint256 availableLiquidity;
        address[] allowedTokens;
        ContractAdapter[] adapters;
    }

    struct PoolData {
        address addr;
        bool isWETH;
        address underlyingToken;
        address dieselToken;
        uint256 linearCumulativeIndex;
        uint256 availableLiquidity;
        uint256 expectedLiquidity;
        uint256 expectedLiquidityLimit;
        uint256 totalBorrowed;
        uint256 depositAPY_RAY;
        uint256 borrowAPY_RAY;
        uint256 dieselRate_RAY;
        uint256 withdrawFee;
        uint256 cumulativeIndex_RAY;
        uint256 timestampLU;
    }

    struct TokenInfo {
        address addr;
        string symbol;
        uint8 decimals;
    }

    struct AddressProviderData {
        address contractRegister;
        address acl;
        address priceOracle;
        address traderAccountFactory;
        address dataCompressor;
        address farmingFactory;
        address accountMiner;
        address treasuryContract;
        address gearToken;
        address wethToken;
        address wethGateway;
    }

    struct MiningApproval {
        address token;
        address swapContract;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0; // T:[PM-1]
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[PM-1]

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR; // T:[PM-1]
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[PM-2]
        uint256 halfPercentage = percentage / 2; // T:[PM-2]

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[PM-2]

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {DataTypes} from "../libraries/data/Types.sol";

interface IAccountFactory {
    // emits if new account miner was changed
    event AccountMinerChanged(address indexed miner);

    // emits each time when creditManager takes credit account
    event NewCreditAccount(address indexed account);

    // emits each time when creditManager takes credit account
    event InitializeCreditAccount(
        address indexed account,
        address indexed creditManager
    );

    // emits each time when pool returns credit account
    event ReturnCreditAccount(address indexed account);

    // emits each time when DAO takes account from account factory forever
    event TakeForever(address indexed creditAccount, address indexed to);

    /// @dev Provide new creditAccount to pool. Creates a new one, if needed
    /// @return Address of creditAccount
    function takeCreditAccount(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external returns (address);

    /// @dev Takes credit account back and stay in tn the queue
    /// @param usedAccount Address of used credit account
    function returnCreditAccount(address usedAccount) external;

    /// @dev Returns address of next available creditAccount
    function getNext(address creditAccount) external view returns (address);

    /// @dev Returns head of list of unused credit accounts
    function head() external view returns (address);

    /// @dev Returns tail of list of unused credit accounts
    function tail() external view returns (address);

    /// @dev Returns quantity of unused credit accounts in the stock
    function countCreditAccountsInStock() external view returns (uint256);

    /// @dev Returns credit account address by its id
    function creditAccounts(uint256 id) external view returns (address);

    /// @dev Quantity of credit accounts
    function countCreditAccounts() external view returns (uint256);

    //    function miningApprovals(uint i) external returns(DataTypes.MiningApproval calldata);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Reusable Credit Account interface
/// @notice Implements general credit account:
///   - Keeps token balances
///   - Keeps token balances
///   - Stores general parameters: borrowed amount, cumulative index at open and block when it was initialized
///   - Approves tokens for 3rd party contracts
///   - Transfers assets
///   - Execute financial orders
///
///  More: https://dev.gearbox.fi/developers/creditManager/vanillacreditAccount

interface ICreditAccount {
    /// @dev Initializes clone contract
    function initialize() external;

    /// @dev Connects credit account to credit manager
    /// @param _creditManager Credit manager address
    function connectTo(
        address _creditManager,
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    //    /// @dev Set general credit account parameters. Restricted to credit managers only
    //    /// @param _borrowedAmount Amount which pool lent to credit account
    //    /// @param _cumulativeIndexAtOpen Cumulative index at open. Uses for interest calculation
    //    function setGenericParameters(
    //
    //    ) external;

    /// @dev Updates borrowed amount. Restricted to credit managers only
    /// @param _borrowedAmount Amount which pool lent to credit account
    function updateParameters(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    /// @dev Approves particular token for swap contract
    /// @param token ERC20 token for allowance
    /// @param swapContract Swap contract address
    function approveToken(address token, address swapContract) external;

    /// @dev Cancels allowance for particular contract
    /// @param token Address of token for allowance
    /// @param targetContract Address of contract to cancel allowance
    function cancelAllowance(address token, address targetContract) external;

    /// Transfers tokens from credit account to provided address. Restricted for pool calls only
    /// @param token Token which should be tranferred from credit account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    /// @dev Returns borrowed amount
    function borrowedAmount() external view returns (uint256);

    /// @dev Returns cumulative index at time of opening credit account
    function cumulativeIndexAtOpen() external view returns (uint256);

    /// @dev Returns Block number when it was initialised last time
    function since() external view returns (uint256);

    /// @dev Address of last connected credit manager
    function creditManager() external view returns (address);

    /// @dev Address of last connected credit manager
    function factory() external view returns (address);

    /// @dev Executed financial order on 3rd party service. Restricted for pool calls only
    /// @param destination Contract address which should be called
    /// @param data Call data which should be sent
    function execute(address destination, bytes memory data)
        external
        returns (bytes memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
import {IAppPoolService} from "./app/IAppPoolService.sol";


/// @title Pool Service Interface
/// @notice Implements business logic:
///   - Adding/removing pool liquidity
///   - Managing diesel tokens & diesel rates
///   - Lending/repaying funds to credit Manager
/// More: https://dev.gearbox.fi/developers/pool/abstractpoolservice
interface IPoolService is IAppPoolService {
    // Emits each time when LP adds liquidity to the pool
    event AddLiquidity(
        address indexed sender,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 referralCode
    );

    // Emits each time when LP removes liquidity to the pool
    event RemoveLiquidity(
        address indexed sender,
        address indexed to,
        uint256 amount
    );

    // Emits each time when Credit Manager borrows money from pool
    event Borrow(
        address indexed creditManager,
        address indexed creditAccount,
        uint256 amount
    );

    // Emits each time when Credit Manager repays money from pool
    event Repay(
        address indexed creditManager,
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    );

    // Emits each time when Interest Rate model was changed
    event NewInterestRateModel(address indexed newInterestRateModel);

    // Emits each time when new credit Manager was connected
    event NewCreditManagerConnected(address indexed creditManager);

    // Emits each time when borrow forbidden for credit manager
    event BorrowForbidden(address indexed creditManager);

    // Emits each time when uncovered (non insured) loss accrued
    event UncoveredLoss(address indexed creditManager, uint256 loss);

    // Emits after expected liquidity limit update
    event NewExpectedLiquidityLimit(uint256 newLimit);

    // Emits each time when withdraw fee is udpated
    event NewWithdrawFee(uint256 fee);

    //
    // LIQUIDITY MANAGEMENT
    //

    /**
     * @dev Adds liquidity to pool
     * - transfers lp tokens to pool
     * - mint diesel (LP) tokens and provide them
     * @param amount Amount of tokens to be transfer
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external override;

    /**
     * @dev Removes liquidity from pool
     * - burns lp's diesel (LP) tokens
     * - returns underlying tokens to lp
     * @param amount Amount of tokens to be transfer
     * @param to Address to transfer liquidity
     */

    function removeLiquidity(uint256 amount, address to)
        external
        override
        returns (uint256);

    /**
     * @dev Transfers money from the pool to credit account
     * and updates the pool parameters
     * @param borrowedAmount Borrowed amount for credit account
     * @param creditAccount Credit account address
     */
    function lendCreditAccount(uint256 borrowedAmount, address creditAccount)
        external;

    /**
     * @dev Recalculates total borrowed & borrowRate
     * mints/burns diesel tokens
     */
    function repayCreditAccount(
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    ) external;

    //
    // GETTERS
    //

    /**
     * @return expected pool liquidity
     */
    function expectedLiquidity() external view returns (uint256);

    /**
     * @return expected liquidity limit
     */
    function expectedLiquidityLimit() external view returns (uint256);

    /**
     * @dev Gets available liquidity in the pool (pool balance)
     * @return available pool liquidity
     */
    function availableLiquidity() external view returns (uint256);

    /**
     * @dev Calculates interest accrued from the last update using the linear model
     */
    function calcLinearCumulative_RAY() external view returns (uint256);

    /**
     * @dev Calculates borrow rate
     * @return borrow rate in RAY format
     */
    function borrowAPY_RAY() external view returns (uint256);

    /**
     * @dev Gets the amount of total borrowed funds
     * @return Amount of borrowed funds at current time
     */
    function totalBorrowed() external view returns (uint256);

    /**
     * @return Current diesel rate
     **/

    function getDieselRate_RAY() external view returns (uint256);

    /**
     * @dev Underlying token address getter
     * @return address of underlying ERC-20 token
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev Diesel(LP) token address getter
     * @return address of diesel(LP) ERC-20 token
     */
    function dieselToken() external view returns (address);

    /**
     * @dev Credit Manager address getter
     * @return address of Credit Manager contract by id
     */
    function creditManagers(uint256 id) external view returns (address);

    /**
     * @dev Credit Managers quantity
     * @return quantity of connected credit Managers
     */
    function creditManagersCount() external view returns (uint256);

    function creditManagersCanBorrow(address id) external view returns (bool);

    function toDiesel(uint256 amount) external view returns (uint256);

    function fromDiesel(uint256 amount) external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function _timestampLU() external view returns (uint256);

    function _cumulativeIndex_RAY() external view returns (uint256);

    function calcCumulativeIndexAtBorrowMore(
        uint256 amount,
        uint256 dAmount,
        uint256 cumulativeIndexAtOpen
    ) external view returns (uint256);

}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


interface IWETHGateway {
    /// @dev convert ETH to WETH and add liqudity to pool
    /// @param pool Address of PoolService contract which where user wants to add liquidity. This pool should has WETH as underlying asset
    /// @param onBehalfOf The address that will receive the diesel tokens, same as msg.sender if the user  wants to receive them on his
    ///                   own wallet, or a different address if the beneficiary of diesel tokens is a different wallet
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle-man
    function addLiquidityETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    /// @dev Removes liquidity from pool and convert WETH to ETH
    ///       - burns lp's diesel (LP) tokens
    ///       - returns underlying tokens to lp
    /// @param pool Address of PoolService contract which where user wants to withdraw liquidity. This pool should has WETH as underlying asset
    /// @param amount Amount of tokens to be transfer
    /// @param to Address to transfer liquidity
    function removeLiquidityETH(
        address pool,
        uint256 amount,
        address payable to
    ) external;

    /// @dev Opens credit account in ETH
    /// @param creditManager Address of credit Manager. Should used WETH as underlying asset
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///                   or a different address if the beneficiary is a different wallet
    /// @param leverageFactor Multiplier to borrowers own funds
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    ///                     0 if the action is executed directly by the user, without any middle-man
    function openCreditAccountETH(
        address creditManager,
        address payable onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external payable;

    /// @dev Repays credit account in ETH
    ///       - transfer borrowed money with interest + fee from borrower account to pool
    ///       - transfer all assets to "to" account
    /// @param creditManager Address of credit Manager. Should used WETH as underlying asset
    /// @param to Address to send credit account assets
    function repayCreditAccountETH(address creditManager, address to)
        external
        payable;

    function addCollateralETH(address creditManager, address onBehalfOf)
        external
        payable;

    /// @dev Unwrap WETH => ETH
    /// @param to Address to send eth
    /// @param amount Amount of WETH was transferred
    function unwrapWETH(address to, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {IAppAddressProvider} from "../interfaces/app/IAppAddressProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title AddressRepository
/// @notice Stores addresses of deployed contracts
contract AddressProvider is Ownable, IAppAddressProvider {
    // Mapping which keeps all addresses
    mapping(bytes32 => address) public addresses;

    // Emits each time when new address is set
    event AddressSet(bytes32 indexed service, address indexed newAddress);

    // This event is triggered when a call to ClaimTokens succeeds.
    event Claimed(uint256 user_id, address account, uint256 amount, bytes32 leaf);

    // Repositories & services
    bytes32 public constant CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
    bytes32 public constant ACL = "ACL";
    bytes32 public constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 public constant ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
    bytes32 public constant DATA_COMPRESSOR = "DATA_COMPRESSOR";
    bytes32 public constant TREASURY_CONTRACT = "TREASURY_CONTRACT";
    bytes32 public constant GEAR_TOKEN = "GEAR_TOKEN";
    bytes32 public constant WETH_TOKEN = "WETH_TOKEN";
    bytes32 public constant WETH_GATEWAY = "WETH_GATEWAY";
    bytes32 public constant LEVERAGED_ACTIONS = "LEVERAGED_ACTIONS";

    // Contract version
    uint256 public constant version = 1;

    constructor() {
        // @dev Emits first event for contract discovery
        emit AddressSet("ADDRESS_PROVIDER", address(this));
    }

    /// @return Address of ACL contract
    function getACL() external view returns (address) {
        return _getAddress(ACL); // T:[AP-3]
    }

    /// @dev Sets address of ACL contract
    /// @param _address Address of ACL contract
    function setACL(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(ACL, _address); // T:[AP-3]
    }

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address) {
        return _getAddress(CONTRACTS_REGISTER); // T:[AP-4]
    }

    /// @dev Sets address of ContractsRegister
    /// @param _address Address of ContractsRegister
    function setContractsRegister(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(CONTRACTS_REGISTER, _address); // T:[AP-4]
    }

    /// @return Address of PriceOracle
    function getPriceOracle() external view override returns (address) {
        return _getAddress(PRICE_ORACLE); // T:[AP-5]
    }

    /// @dev Sets address of PriceOracle
    /// @param _address Address of PriceOracle
    function setPriceOracle(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(PRICE_ORACLE, _address); // T:[AP-5]
    }

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address) {
        return _getAddress(ACCOUNT_FACTORY); // T:[AP-6]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setAccountFactory(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(ACCOUNT_FACTORY, _address); // T:[AP-7]
    }

    /// @return Address of AccountFactory
    function getDataCompressor() external view override returns (address) {
        return _getAddress(DATA_COMPRESSOR); // T:[AP-8]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setDataCompressor(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(DATA_COMPRESSOR, _address); // T:[AP-8]
    }

    /// @return Address of Treasury contract
    function getTreasuryContract() external view returns (address) {
        return _getAddress(TREASURY_CONTRACT); //T:[AP-11]
    }

    /// @dev Sets address of Treasury Contract
    /// @param _address Address of Treasury Contract
    function setTreasuryContract(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(TREASURY_CONTRACT, _address); //T:[AP-11]
    }

    /// @return Address of GEAR token
    function getGearToken() external view override returns (address) {
        return _getAddress(GEAR_TOKEN); // T:[AP-12]
    }

    /// @dev Sets address of GEAR token
    /// @param _address Address of GEAR token
    function setGearToken(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(GEAR_TOKEN, _address); // T:[AP-12]
    }

    /// @return Address of WETH token
    function getWethToken() external view override returns (address) {
        return _getAddress(WETH_TOKEN); // T:[AP-13]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWethToken(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(WETH_TOKEN, _address); // T:[AP-13]
    }

    /// @return Address of WETH token
    function getWETHGateway() external view override returns (address) {
        return _getAddress(WETH_GATEWAY); // T:[AP-14]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWETHGateway(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(WETH_GATEWAY, _address); // T:[AP-14]
    }

    /// @return Address of WETH token
    function getLeveragedActions() external view override returns (address) {
        return _getAddress(LEVERAGED_ACTIONS); // T:[AP-7]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setLeveragedActions(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(LEVERAGED_ACTIONS, _address); // T:[AP-7]
    }

    /// @return Address of key, reverts if key doesn't exist
    function _getAddress(bytes32 key) internal view returns (address) {
        address result = addresses[key];
        require(result != address(0), Errors.AS_ADDRESS_NOT_FOUND); // T:[AP-1]
        return result; // T:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    }

    /// @dev Sets address to map by its key
    /// @param key Key in string format
    /// @param value Address
    function _setAddress(bytes32 key, address value) internal {
        addresses[key] = value; // T:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        emit AddressSet(key, value); // T:[AP-2]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AddressProvider} from "./AddressProvider.sol";
import {ACL} from "./ACL.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title ACL Trait
/// @notice Trait which adds acl functions to contract
abstract contract ACLTrait is Pausable {
    // ACL contract to check rights
    ACL private _acl;

    /// @dev constructor
    /// @param addressProvider Address of address repository
    constructor(address addressProvider) {
        require(
            addressProvider != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        _acl = ACL(AddressProvider(addressProvider).getACL());
    }

    /// @dev  Reverts if msg.sender is not configurator
    modifier configuratorOnly() {
        require(
            _acl.isConfigurator(msg.sender),
            Errors.ACL_CALLER_NOT_CONFIGURATOR
        ); // T:[ACLT-8]
        _;
    }

    ///@dev Pause contract
    function pause() external {
        require(
            _acl.isPausableAdmin(msg.sender),
            Errors.ACL_CALLER_NOT_PAUSABLE_ADMIN
        ); // T:[ACLT-1]
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external {
        require(
            _acl.isUnpausableAdmin(msg.sender),
            Errors.ACL_CALLER_NOT_PAUSABLE_ADMIN
        ); // T:[ACLT-1],[ACLT-2]
        _unpause();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {PercentageMath} from "../math/PercentageMath.sol";

library Constants {
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // 25% of MAX_INT
    uint256 constant MAX_INT_4 =
        0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // REWARD FOR LEAN DEPLOYMENT MINING
    uint256 constant ACCOUNT_CREATION_REWARD = 1e5;
    uint256 constant DEPLOYMENT_COST = 1e17;

    // FEE = 10%
    uint256 constant FEE_INTEREST = 1000; // 10%

    // FEE + LIQUIDATION_FEE 2%
    uint256 constant FEE_LIQUIDATION = 200;

    // Liquidation premium 5%
    uint256 constant LIQUIDATION_DISCOUNTED_SUM = 9500;

    // 100% - LIQUIDATION_FEE - LIQUIDATION_PREMIUM
    uint256 constant UNDERLYING_TOKEN_LIQUIDATION_THRESHOLD =
        LIQUIDATION_DISCOUNTED_SUM - FEE_LIQUIDATION;

    // Seconds in a year
    uint256 constant SECONDS_PER_YEAR = 365 days;
    uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = SECONDS_PER_YEAR * 3 /2;

    // 1e18
    uint256 constant RAY = 1e27;
    uint256 constant WAD = 1e18;

    // OPERATIONS
    uint8 constant OPERATION_CLOSURE = 1;
    uint8 constant OPERATION_REPAY = 2;
    uint8 constant OPERATION_LIQUIDATION = 3;

    // Decimals for leverage, so x4 = 4*LEVERAGE_DECIMALS for openCreditAccount function
    uint8 constant LEVERAGE_DECIMALS = 100;

    // Maximum withdraw fee for pool in percentage math format. 100 = 1%
    uint8 constant MAX_WITHDRAW_FEE = 100;

    uint256 constant CHI_THRESHOLD = 9950;
    uint256 constant HF_CHECK_INTERVAL_DEFAULT = 4;

    uint256 constant NO_SWAP = 0;
    uint256 constant UNISWAP_V2 = 1;
    uint256 constant UNISWAP_V3 = 2;
    uint256 constant CURVE_V1 = 3;
    uint256 constant LP_YEARN = 4;

    uint256 constant EXACT_INPUT = 1;
    uint256 constant EXACT_OUTPUT = 2;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

/// @title POptimised for front-end Pool Service Interface
interface IAppPoolService {

    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external;

    function removeLiquidity(uint256 amount, address to) external returns(uint256);

}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Optimised for front-end Address Provider interface
interface IAppAddressProvider {
    function getDataCompressor() external view returns (address);

    function getGearToken() external view returns (address);

    function getWethToken() external view returns (address);

    function getWETHGateway() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLeveragedActions() external view returns (address);
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

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title ACL keeps admins addresses
/// More info: https://dev.gearbox.fi/security/roles
contract ACL is Ownable {
    mapping(address => bool) public pausableAdminSet;
    mapping(address => bool) public unpausableAdminSet;

    // Contract version
    uint256 public constant version = 1;

    // emits each time when new pausable admin added
    event PausableAdminAdded(address indexed newAdmin);

    // emits each time when pausable admin removed
    event PausableAdminRemoved(address indexed admin);

    // emits each time when new unpausable admin added
    event UnpausableAdminAdded(address indexed newAdmin);

    // emits each times when unpausable admin removed
    event UnpausableAdminRemoved(address indexed admin);

    /// @dev Adds pausable admin address
    /// @param newAdmin Address of new pausable admin
    function addPausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[newAdmin] = true; // T:[ACL-2]
        emit PausableAdminAdded(newAdmin); // T:[ACL-2]
    }

    /// @dev Removes pausable admin
    /// @param admin Address of admin which should be removed
    function removePausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[admin] = false; // T:[ACL-3]
        emit PausableAdminRemoved(admin); // T:[ACL-3]
    }

    /// @dev Returns true if the address is pausable admin and false if not
    function isPausableAdmin(address addr) external view returns (bool) {
        return pausableAdminSet[addr]; // T:[ACL-2,3]
    }

    /// @dev Adds unpausable admin address to the list
    /// @param newAdmin Address of new unpausable admin
    function addUnpausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[newAdmin] = true; // T:[ACL-4]
        emit UnpausableAdminAdded(newAdmin); // T:[ACL-4]
    }

    /// @dev Removes unpausable admin
    /// @param admin Address of admin to be removed
    function removeUnpausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[admin] = false; // T:[ACL-5]
        emit UnpausableAdminRemoved(admin); // T:[ACL-5]
    }

    /// @dev Returns true if the address is unpausable admin and false if not
    function isUnpausableAdmin(address addr) external view returns (bool) {
        return unpausableAdminSet[addr]; // T:[ACL-4,5]
    }

    /// @dev Returns true if addr has configurator rights
    function isConfigurator(address account) external view returns (bool) {
        return account == owner(); // T:[ACL-6]
    }
}