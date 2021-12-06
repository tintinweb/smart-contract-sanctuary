/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-05
*/

// File: contracts/interfaces/IUniswapV2Callee.sol



pragma solidity >=0.5.16;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// File: contracts/interfaces/IRequiemFactory.sol



pragma solidity >=0.5.16;

interface IRequiemFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint);
    function feeTo() external view returns (address);
    function formula() external view returns (address);
    function protocolFee() external view returns (uint);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB, uint32 tokenWeightA, uint32 swapFee) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function isPair(address) external view returns (bool);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, uint32 tokenWeightA, uint32 swapFee) external returns (address pair);
    function getWeightsAndSwapFee(address pair) external view returns (uint32 tokenWeight0, uint32 tokenWeight1, uint32 swapFee);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFee(uint) external;
}

// File: contracts/interfaces/ERC20/IERC20.sol



pragma solidity ^0.8.10;

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
// File: contracts/libraries/UQ112x112.sol



pragma solidity >=0.5.16;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// File: contracts/libraries/TransferHelper.sol



pragma solidity >=0.8.10;

// solhint-disable avoid-low-level-calls, reason-string

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/libraries/Math.sol



pragma solidity >=0.5.16;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/libraries/helpers/RequiemErrors.sol


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

// solhint-disable
library RequiemErrors {
    /**
     * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
     * supported.
     */
    function _require(bool condition, uint256 errorCode) internal pure {
        if (!condition) RequiemErrors._revert(errorCode);
    }

    /**
     * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
     */
    function _revert(uint256 errorCode) internal pure {
        // We're going to dynamically create a revert string based on the error code, with the following format:
        // 'REQ#{errorCode}'
        // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
        //
        // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
        // number (8 to 16 bits) than the individual string characters.
        //
        // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
        // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
        // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
        assembly {
            // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
            // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
            // the '0' character.

            let units := add(mod(errorCode, 10), 0x30)

            errorCode := div(errorCode, 10)
            let tenths := add(mod(errorCode, 10), 0x30)

            errorCode := div(errorCode, 10)
            let hundreds := add(mod(errorCode, 10), 0x30)

            // With the individual characters, we can now construct the full string. The "REQ#" part is a known constant
            // (0x52455123): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
            // characters to it, each shifted by a multiple of 8.
            // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
            // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
            // array).

            let revertReason := shl(200, add(0x52455123000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

            // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
            // message will have the following layout:
            // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

            // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
            // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
            mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
            mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
            // The string length is fixed: 7 characters.
            mstore(0x24, 7)
            // Finally, the string itself is stored.
            mstore(0x44, revertReason)

            // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
            // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
            revert(0, 100)
        }
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// File: contracts/libraries/SafeMath.sol



pragma solidity ^0.8.10;


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
        RequiemErrors._require(c >= a, Errors.ADD_OVERFLOW);

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
        return sub(a, b, Errors.SUB_OVERFLOW);
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
        uint256 errorCode
    ) internal pure returns (uint256) {
        RequiemErrors._require(b <= a, errorCode);
        uint256 c = a - b;

        return c;
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

// File: contracts/interfaces/IRequiemFormula.sol


pragma solidity >=0.5.16;

/*
    Bancor Formula interface
*/
interface IRequiemFormula {

    function getReserveAndWeights(address pair, address tokenA) external view returns (
        address tokenB,
        uint reserveA,
        uint reserveB,
        uint32 tokenWeightA,
        uint32 tokenWeightB,
        uint32 swapFee
    );

    function getFactoryReserveAndWeights(address factory, address pair, address tokenA) external view returns (
        address tokenB,
        uint reserveA,
        uint reserveB,
        uint32 tokenWeightA,
        uint32 tokenWeightB,
        uint32 swapFee
    );

    function getAmountIn(
        uint amountOut,
        uint reserveIn, uint reserveOut,
        uint32 tokenWeightIn, uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint amountIn);

    function getPairAmountIn(address pair, address tokenIn, uint amountOut) external view returns (uint amountIn);

    function getAmountOut(
        uint amountIn,
        uint reserveIn, uint reserveOut,
        uint32 tokenWeightIn, uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint amountOut);

    function getPairAmountOut(address pair, address tokenIn, uint amountIn) external view returns (uint amountOut);

    function getAmountsIn(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getFactoryAmountsIn(
        address factory,
        address tokenIn,
        address tokenOut,
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getFactoryAmountsOut(
        address factory,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function ensureConstantValue(uint reserve0, uint reserve1, uint balance0Adjusted, uint balance1Adjusted, uint32 tokenWeight0) external view returns (bool);
    function getReserves(address pair, address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);
    function getOtherToken(address pair, address tokenA) external view returns (address tokenB);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function mintLiquidityFee(
        uint totalLiquidity,
        uint112 reserve0,
        uint112  reserve1,
        uint32 tokenWeight0,
        uint32 tokenWeight1,
        uint112  collectedFee0,
        uint112 collectedFee1) external view returns (uint amount);
}

// File: contracts/interfaces/IRequiemSwap.sol



pragma solidity ^0.8.10;

interface IRequiemSwap {
    // this funtion requires the correctly calculated amounts as input
    // the others are supposed to implement that calculation
    // no return value required since the amounts are already known
    function onSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address to
    ) external;

    //
    function onSwapGivenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external returns (uint256);

    function onSwapGivenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address to
    ) external returns (uint256);

    function calculateSwapGivenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256);

    function calculateSwapGivenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256);
}

// File: contracts/interfaces/IRequiemERC20.sol



pragma solidity ^0.8.10;

// solhint-disable func-name-mixedcase

interface IRequiemERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: contracts/RequiemERC20.sol



pragma solidity ^0.8.10;



contract RequiemERC20 is IRequiemERC20 {
    using SafeMath for uint256;

    string public constant name = "Requiem Liquidity Provider";
    string public constant symbol = "RLP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"), keccak256(bytes(name)), keccak256(bytes("1")), chainId, address(this))
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "RLP: EXPIRED");
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "RLP: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

// File: contracts/interfaces/IRequiemPair.sol



pragma solidity ^0.8.10;


// solhint-disable func-name-mixedcase

interface IRequiemPair is IRequiemERC20 {

    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

    function getSwapFee() external view returns (uint32);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        uint32,
        uint32
    ) external;
}

// File: contracts/RequiemPair.sol



pragma solidity ^0.8.10;











// solhint-disable not-rely-on-time, var-name-mixedcase, max-line-length, reason-string, avoid-low-level-calls

contract RequiemPair is IRequiemSwap, IRequiemPair, RequiemERC20 {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 private unlocked = 1;
    address public formula;

    uint112 private collectedFee0; // uses single storage slot, accessible via getReserves
    uint112 private collectedFee1; // uses single storage slot, accessible via getReserves

    uint32 private tokenWeight0;
    uint32 private tokenWeight1;
    uint32 private swapFee;

    modifier lock() {
        require(unlocked == 1, "REQLP: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function getCollectedFees() public view returns (uint112 _collectedFee0, uint112 _collectedFee1) {
        _collectedFee0 = collectedFee0;
        _collectedFee1 = collectedFee1;
    }

    function getTokenWeights() public view returns (uint32 _tokenWeight0, uint32 _tokenWeight1) {
        _tokenWeight0 = tokenWeight0;
        _tokenWeight1 = tokenWeight1;
    }

    function getSwapFee() public view returns (uint32 _swapFee) {
        _swapFee = swapFee;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "REQLP: TRANSFER_FAILED");
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        uint32 _tokenWeight0,
        uint32 _swapFee
    ) external {
        require(msg.sender == factory, "REQLP: FORBIDDEN");
        // sufficient check
        token0 = _token0;
        token1 = _token1;
        tokenWeight0 = _tokenWeight0;
        tokenWeight1 = 100 - tokenWeight0;
        swapFee = _swapFee;
        formula = IRequiemFactory(factory).formula();
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        uint32 _tokenWeight0 = tokenWeight0;
        require(balance0 * (100 - _tokenWeight0) <= type(uint112).max && balance1 * _tokenWeight0 <= type(uint112).max, "REQLP: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            uint112 mReserve0 = _reserve0 * (100 - _tokenWeight0);
            uint112 mReserve1 = _reserve1 * _tokenWeight0;
            price0CumulativeLast += uint256(UQ112x112.encode(mReserve1).uqdiv(mReserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(mReserve0).uqdiv(mReserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IRequiemFactory(factory).feeTo();
        uint112 protocolFee = uint112(IRequiemFactory(factory).protocolFee());
        feeOn = feeTo != address(0);
        (uint112 _collectedFee0, uint112 _collectedFee1) = getCollectedFees();
        if (protocolFee > 0 && feeOn && (_collectedFee0 > 0 || _collectedFee1 > 0)) {
            uint32 _tokenWeight0 = tokenWeight0;
            uint256 liquidity = IRequiemFormula(formula).mintLiquidityFee(
                totalSupply,
                _reserve0,
                _reserve1,
                _tokenWeight0,
                100 - _tokenWeight0,
                _collectedFee0 / protocolFee,
                _collectedFee1 / protocolFee
            );
            if (liquidity > 0) _mint(feeTo, liquidity);
        }
        if (_collectedFee0 > 0) collectedFee0 = 0;
        if (_collectedFee1 > 0) collectedFee1 = 0;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);
        _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, "REQLP: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "REQLP: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(amount0Out > 0 || amount1Out > 0, "REQLP: INSUFFICIENT_OUTPUT_AMOUNT");
        uint112 _reserve0 = reserve0; // gas savings
        uint112 _reserve1 = reserve1; // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "REQLP: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "REQLP: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, "REQLP: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(10000);
            uint256 balance1Adjusted = balance1.mul(10000);
            {
                // avoids stack too deep errors
                if (amount0In > 0) {
                    uint256 amount0InFee = amount0In.mul(swapFee);
                    balance0Adjusted = balance0Adjusted.sub(amount0InFee);
                    collectedFee0 = uint112(uint256(collectedFee0).add(amount0InFee));
                }
                if (amount1In > 0) {
                    uint256 amount1InFee = amount1In.mul(swapFee);
                    balance1Adjusted = balance1Adjusted.sub(amount1InFee);
                    collectedFee1 = uint112(uint256(collectedFee1).add(amount1InFee));
                }
                uint32 _tokenWeight0 = tokenWeight0; // gas savings
                if (_tokenWeight0 == 50) {
                    // gas savings for pair 50/50
                    require(balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(10000**2), "REQLP: K");
                } else {
                    require(IRequiemFormula(formula).ensureConstantValue(uint256(_reserve0).mul(10000), uint256(_reserve1).mul(10000), balance0Adjusted, balance1Adjusted, _tokenWeight0), "REQLP: K");
                }
            }
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    //
    function calculateSwapGivenIn(
        address tokenIn,
        address,
        uint256 amountIn
    ) external view returns (uint256) {
        (uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut) = tokenIn == token0
            ? (reserve0, reserve1, tokenWeight0, tokenWeight1)
            : (reserve1, reserve0, tokenWeight1, tokenWeight0);
        return IRequiemFormula(formula).getAmountOut(amountIn, reserveIn, reserveOut, tokenWeightIn, tokenWeightOut, swapFee);
    }

    function calculateSwapGivenOut(
        address tokenIn,
        address,
        uint256 amountOut
    ) external view returns (uint256) {
        (uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut) = tokenIn == token0
            ? (reserve0, reserve1, tokenWeight0, tokenWeight1)
            : (reserve1, reserve0, tokenWeight1, tokenWeight0);
        return IRequiemFormula(formula).getAmountIn(amountOut, reserveIn, reserveOut, tokenWeightIn, tokenWeightOut, swapFee);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    // calculates output amount for given input and executes the respective trade
    // viable for use in multi swaps as it returns the output value
    // requires the amount in to be sent to this address beforehand
    function onSwapGivenIn(
        address tokenIn,
        address,
        uint256 amountIn,
        uint256,
        address to
    ) external override lock returns (uint256) {
        bool inToken0 = tokenIn == token0;
        (uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut) = inToken0
            ? (reserve0, reserve1, tokenWeight0, tokenWeight1)
            : (reserve1, reserve0, tokenWeight1, tokenWeight0);
        uint256 amountOut = IRequiemFormula(formula).getAmountOut(amountIn, reserveIn, reserveOut, tokenWeightIn, tokenWeightOut, swapFee);
        (uint256 amount0Out, uint256 amount1Out) = inToken0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        return _swap(amount0Out, amount1Out, to);
    }

    // calculates input amount for given output and executes the respective trade
    // calling this one only makes sense if a single trade is supposd to be executed in the tx
    // requires the amount in to be sent to this address beforehand
    function onSwapGivenOut(
        address tokenIn,
        address,
        uint256 amountOut,
        uint256,
        address to
    ) external override lock returns (uint256) {
        bool inToken0 = tokenIn == token0;
        (uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut) = tokenIn == token0
            ? (reserve0, reserve1, tokenWeight0, tokenWeight1)
            : (reserve1, reserve0, tokenWeight1, tokenWeight0);
        uint256 amountIn = IRequiemFormula(formula).getAmountIn(amountOut, reserveIn, reserveOut, tokenWeightIn, tokenWeightOut, swapFee);
        (uint256 amount0Out, uint256 amount1Out) = inToken0 ? (uint256(0), amountIn) : (amountIn, uint256(0));
        return _swap(amount0Out, amount1Out, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function _swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal returns (uint256) {
        require(amount0Out > 0 || amount1Out > 0, "REQLP: INSUFFICIENT_OUTPUT_AMOUNT");
        uint112 _reserve0 = reserve0; // gas savings
        uint112 _reserve1 = reserve1; // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "REQLP: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "REQLP: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, "REQLP: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(10000);
            uint256 balance1Adjusted = balance1.mul(10000);
            {
                // avoids stack too deep errors
                if (amount0In > 0) {
                    uint256 amount0InFee = amount0In.mul(swapFee);
                    balance0Adjusted = balance0Adjusted.sub(amount0InFee);
                    collectedFee0 = uint112(uint256(collectedFee0).add(amount0InFee));
                }
                if (amount1In > 0) {
                    uint256 amount1InFee = amount1In.mul(swapFee);
                    balance1Adjusted = balance1Adjusted.sub(amount1InFee);
                    collectedFee1 = uint112(uint256(collectedFee1).add(amount1InFee));
                }
                uint32 _tokenWeight0 = tokenWeight0; // gas savings
                if (_tokenWeight0 == 50) {
                    // gas savings for pair 50/50
                    require(balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(10000**2), "REQLP: K");
                } else {
                    require(IRequiemFormula(formula).ensureConstantValue(uint256(_reserve0).mul(10000), uint256(_reserve1).mul(10000), balance0Adjusted, balance1Adjusted, _tokenWeight0), "REQLP: K");
                }
            }
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
        return amount0Out > 0 ? amount0Out : amount1Out;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function onSwap(
        address tokenIn,
        address,
        uint256,
        uint256 amountOut,
        address to
    ) external override lock {
        (uint256 amount0Out, uint256 amount1Out) = token0 == tokenIn ? (uint256(0), amountOut) : (amountOut, uint256(0));
        require(amount0Out > 0 || amount1Out > 0, "REQLP: INSUFFICIENT_OUTPUT_AMOUNT");
        uint112 _reserve0 = reserve0; // gas savings
        uint112 _reserve1 = reserve1; // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "REQLP: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "REQLP: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;

        require(amount0In > 0 || amount1In > 0, "REQLP: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(10000);
            uint256 balance1Adjusted = balance1.mul(10000);
            {
                // avoids stack too deep errors
                if (amount0In > 0) {
                    uint256 amount0InFee = amount0In.mul(swapFee);
                    balance0Adjusted = balance0Adjusted.sub(amount0InFee);
                    collectedFee0 = uint112(uint256(collectedFee0).add(amount0InFee));
                }
                if (amount1In > 0) {
                    uint256 amount1InFee = amount1In.mul(swapFee);
                    balance1Adjusted = balance1Adjusted.sub(amount1InFee);
                    collectedFee1 = uint112(uint256(collectedFee1).add(amount1InFee));
                }
                uint32 _tokenWeight0 = tokenWeight0; // gas savings
                if (_tokenWeight0 == 50) {
                    // gas savings for pair 50/50
                    require(balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(10000**2), "REQLP: K");
                } else {
                    require(IRequiemFormula(formula).ensureConstantValue(uint256(_reserve0).mul(10000), uint256(_reserve1).mul(10000), balance0Adjusted, balance1Adjusted, _tokenWeight0), "REQLP: K");
                }
            }
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
}