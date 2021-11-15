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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
pragma solidity 0.7.4;

interface IPriceFeedsExt {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.4;

interface ISpotOracle {
    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external view returns (bool);

    function setMarketClosed(bool _marketClosed) external;

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() external view returns (bool);

    function setTerminated(bool _terminated) external;

    /**
     *  Spot price.
     */
    function getSpotPrice() external view returns (int128, uint256);

    /**
     * Get base currency symbol.
     */
    function getBaseCurrency() external view returns (bytes32);

    /**
     * Get quote currency symbol.
     */
    function getQuoteCurrency() external view returns (bytes32);

    /**
     * @dev Mark price.

    function priceTWAPLong() external returns (int256 newPrice, uint256 newTimestamp);
     * @dev Get collateral symbol.
     
    function collateral() external view returns (string memory);

    /**
     *  Index price.
    function priceTWAPShort() external returns (int256 newPrice, uint256 newTimestamp);
    */
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.7.4;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = - 0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= - 0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(x <= 0x7FFFFFFFFFFFFFFF);
        return int128(int256(x << 64));
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0);
        return uint64(uint128(x >> 64));
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return int256(x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) * y >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require(y >= - 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
            y <= 0x1000000000000000000000000000000000000000000000000);
            return - y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = - x;
                negativeResult = true;
            }
            if (y < 0) {
                y = - y;
                // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu(x, uint256(y));
            if (negativeResult) {
                require(absoluteResult <=
                    0x8000000000000000000000000000000000000000000000000000000000000000);
                return - int256(absoluteResult);
                // We rely on overflow behavior here
            } else {
                require(absoluteResult <=
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int256(absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0);

        uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256(int256(x)) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require(hi <=
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        require(y != 0);
        int256 result = (int256(x) << 64) / y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        require(y != 0);

        bool negativeResult = false;
        if (x < 0) {
            x = - x;
            // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = - y;
            // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu(uint256(x), uint256(y));
        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000);
            return - int128(absoluteResult);
            // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128(absoluteResult);
            // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0);
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64));
        return int128(result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return - x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return x < 0 ? - x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        require(x != 0);
        int256 result = int256(0x100000000000000000000000000000000) / x;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return int128((int256(x) + int256(y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256(x) * int256(y);
        require(m >= 0);
        require(m <
            0x4000000000000000000000000000000000000000000000000000000000000000);
        return int128(sqrtu(uint256(m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        bool negative = x < 0 && y & 1 == 1;

        uint256 absX = uint128(x < 0 ? - x : x);
        uint256 absResult;
        absResult = 0x100000000000000000000000000000000;

        if (absX <= 0x10000000000000000) {
            absX <<= 63;
            while (y != 0) {
                if (y & 0x1 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x2 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x4 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x8 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                y >>= 4;
            }

            absResult >>= 64;
        } else {
            uint256 absXShift = 63;
            if (absX < 0x1000000000000000000000000) {absX <<= 32;
                absXShift -= 32;}
            if (absX < 0x10000000000000000000000000000) {absX <<= 16;
                absXShift -= 16;}
            if (absX < 0x1000000000000000000000000000000) {absX <<= 8;
                absXShift -= 8;}
            if (absX < 0x10000000000000000000000000000000) {absX <<= 4;
                absXShift -= 4;}
            if (absX < 0x40000000000000000000000000000000) {absX <<= 2;
                absXShift -= 2;}
            if (absX < 0x80000000000000000000000000000000) {absX <<= 1;
                absXShift -= 1;}

            uint256 resultShift = 0;
            while (y != 0) {
                require(absXShift < 64);

                if (y & 0x1 != 0) {
                    absResult = absResult * absX >> 127;
                    resultShift += absXShift;
                    if (absResult > 0x100000000000000000000000000000000) {
                        absResult >>= 1;
                        resultShift += 1;
                    }
                }
                absX = absX * absX >> 127;
                absXShift <<= 1;
                if (absX >= 0x100000000000000000000000000000000) {
                    absX >>= 1;
                    absXShift += 1;
                }

                y >>= 1;
            }

            require(resultShift < 64);
            absResult >>= 64 - resultShift;
        }
        int256 result = negative ? - int256(absResult) : int256(absResult);
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        require(x >= 0);
        return int128(sqrtu(uint256(int256(x)) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {xc >>= 64;
            msb += 64;}
        if (xc >= 0x100000000) {xc >>= 32;
            msb += 32;}
        if (xc >= 0x10000) {xc >>= 16;
            msb += 16;}
        if (xc >= 0x100) {xc >>= 8;
            msb += 8;}
        if (xc >= 0x10) {xc >>= 4;
            msb += 4;}
        if (xc >= 0x4) {xc >>= 2;
            msb += 2;}
        if (xc >= 0x2) msb += 1;
        // No need to shift xc anymore

        int256 result = msb - 64 << 64;
        uint256 ux = uint256(int256(x)) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        require(x > 0);

        return int128(int256(
                uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000);
        // Overflow

        if (x < - 0x400000000000000000) return 0;
        // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (x & 0x4000000000000000 > 0)
            result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (x & 0x2000000000000000 > 0)
            result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (x & 0x1000000000000000 > 0)
            result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (x & 0x800000000000000 > 0)
            result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (x & 0x400000000000000 > 0)
            result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (x & 0x200000000000000 > 0)
            result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (x & 0x100000000000000 > 0)
            result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (x & 0x80000000000000 > 0)
            result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (x & 0x40000000000000 > 0)
            result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (x & 0x20000000000000 > 0)
            result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (x & 0x10000000000000 > 0)
            result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (x & 0x8000000000000 > 0)
            result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (x & 0x4000000000000 > 0)
            result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (x & 0x2000000000000 > 0)
            result = result * 0x1000162E525EE054754457D5995292026 >> 128;
        if (x & 0x1000000000000 > 0)
            result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (x & 0x800000000000 > 0)
            result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (x & 0x400000000000 > 0)
            result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (x & 0x200000000000 > 0)
            result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (x & 0x100000000000 > 0)
            result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (x & 0x80000000000 > 0)
            result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (x & 0x40000000000 > 0)
            result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (x & 0x20000000000 > 0)
            result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (x & 0x10000000000 > 0)
            result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (x & 0x8000000000 > 0)
            result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (x & 0x4000000000 > 0)
            result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (x & 0x2000000000 > 0)
            result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (x & 0x1000000000 > 0)
            result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (x & 0x800000000 > 0)
            result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (x & 0x400000000 > 0)
            result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (x & 0x200000000 > 0)
            result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (x & 0x100000000 > 0)
            result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (x & 0x80000000 > 0)
            result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (x & 0x40000000 > 0)
            result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (x & 0x20000000 > 0)
            result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (x & 0x10000000 > 0)
            result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (x & 0x8000000 > 0)
            result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (x & 0x4000000 > 0)
            result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (x & 0x2000000 > 0)
            result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (x & 0x1000000 > 0)
            result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (x & 0x800000 > 0)
            result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (x & 0x400000 > 0)
            result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (x & 0x200000 > 0)
            result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (x & 0x100000 > 0)
            result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (x & 0x80000 > 0)
            result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (x & 0x40000 > 0)
            result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (x & 0x20000 > 0)
            result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (x & 0x10000 > 0)
            result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (x & 0x8000 > 0)
            result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (x & 0x4000 > 0)
            result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (x & 0x2000 > 0)
            result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (x & 0x1000 > 0)
            result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (x & 0x800 > 0)
            result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (x & 0x400 > 0)
            result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (x & 0x200 > 0)
            result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (x & 0x100 > 0)
            result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (x & 0x80 > 0)
            result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (x & 0x40 > 0)
            result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (x & 0x20 > 0)
            result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (x & 0x10 > 0)
            result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (x & 0x8 > 0)
            result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (x & 0x4 > 0)
            result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (x & 0x2 > 0)
            result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (x & 0x1 > 0)
            result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

        result >>= uint256(int256(63 - (x >> 64)));
        require(result <= uint256(int256(MAX_64x64)));

        return int128(int256(result));
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000);
        // Overflow

        if (x < - 0x400000000000000000) return 0;
        // Underflow

        return exp_2(
            int128(int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {xc >>= 32;
                msb += 32;}
            if (xc >= 0x10000) {xc >>= 16;
                msb += 16;}
            if (xc >= 0x100) {xc >>= 8;
                msb += 8;}
            if (xc >= 0x10) {xc >>= 4;
                msb += 4;}
            if (xc >= 0x4) {xc >>= 2;
                msb += 2;}
            if (xc >= 0x2) msb += 1;
            // No need to shift xc anymore

            result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128(result);
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {xx >>= 128;
                r <<= 64;}
            if (xx >= 0x10000000000000000) {xx >>= 64;
                r <<= 32;}
            if (xx >= 0x100000000) {xx >>= 32;
                r <<= 16;}
            if (xx >= 0x10000) {xx >>= 16;
                r <<= 8;}
            if (xx >= 0x100) {xx >>= 8;
                r <<= 4;}
            if (xx >= 0x10) {xx >>= 4;
                r <<= 2;}
            if (xx >= 0x8) {r <<= 1;}
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

library QuickSort {
    function sort(uint256[] memory _data) internal pure returns (uint256[] memory) {
        sort(_data, int256(0), int256(_data.length - 1));
        return _data;
    }

    function sort(
        uint256[] memory _data,
        int256 _start,
        int256 _end
    ) internal pure {
        int256 i = _start;
        int256 j = _end;
        if (i == j) {
            return;
        }
        uint256 pivot = _data[uint256(_start + (_end - _start) / 2)];
        while (i <= j) {
            while (_data[uint256(i)] < pivot) {
                i++;
            }
            while (pivot < _data[uint256(j)]) {
                j--;
            }
            if (i <= j) {
                (_data[uint256(i)], _data[uint256(j)]) = (_data[uint256(j)], _data[uint256(i)]);
                i++;
                j--;
            }
        }
        if (_start < j) {
            sort(_data, _start, j);
        }
        if (i < _end) {
            sort(_data, i, _end);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/ISpotOracle.sol";
import "./OracleInterfaceID.sol";

abstract contract AbstractOracle is Ownable, ERC165, OracleInterfaceID, ISpotOracle {
    constructor() {
        _registerInterface(_getOracleInterfaceID());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ABDKMath64x64.sol";
import "../interface/IPriceFeedsExt.sol";
import "./SpotOracle.sol";

contract OracleFactory is Ownable, OracleInterfaceID {
    using ERC165Checker for address;
    using ABDKMath64x64 for int128;

    int128 constant ONE_64x64 = 0x10000000000000000; // 2^64

    struct OracleData {
        address oracle;
        bool isInverse;
    }

    //baseCurrency => quoteCurrency => oracles' addresses
    mapping(bytes32 => mapping(bytes32 => OracleData[])) private routes;

    event OracleCreated(bytes32 baseCurrency, bytes32 quoteCurrency, address oracle);
    event OracleAdded(bytes32 baseCurrency, bytes32 quoteCurrency, address oracle);
    event ShortRouteAdded(bytes32 baseCurrency, bytes32 quoteCurrency, address oracle);
    event RouteAdded(bytes32 baseCurrency, bytes32 quoteCurrency, address[] oracle, bool[] isInverse);
    event RouteRemoved(bytes32 baseCurrency, bytes32 quoteCurrency);

    /**
     * @notice Deploys Oracle contract for currency pair.
     * @dev The route for the given pair will be set (overwritten if it was already set).
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _priceFeeds     The array of IPriceFeedsExt
     */
    function createOracle(
        bytes32 _baseCurrency,
        bytes32 _quoteCurrency,
        address[] memory _priceFeeds
    ) external onlyOwner returns (address) {
        require(_baseCurrency != "", "invalid base currency");
        require(_quoteCurrency != 0, "invalid quote currency");
        require(_baseCurrency != _quoteCurrency, "base and quote should be different");
        require(_priceFeeds.length > 0, "at least one price feed is needed");

        address oracle = address(new SpotOracle(_baseCurrency, _quoteCurrency, _priceFeeds));
        SpotOracle(oracle).transferOwnership(msg.sender);
        _setRoute(_baseCurrency, _quoteCurrency, oracle);

        //checks that price can be calculated
        //TODO: James: uncomment after changing deployment (mock price feed should be deployed locally)
//        _getSpotPrice(_baseCurrency, _quoteCurrency);

        emit OracleCreated(_baseCurrency, _quoteCurrency, oracle);

        return oracle;
    }

    /**
     * @notice Sets Oracle contract for currency pair.
     * @dev The route for the given pair will be set (overwritten if it was already set).
     *
     * @param   _oracle   The Oracle contract (should implement ISpotOracle interface).
     */
    function addOracle(address _oracle) external onlyOwner {
        require(_oracle.supportsInterface(_getOracleInterfaceID()), "invalid oracle");

        bytes32 baseCurrency = ISpotOracle(_oracle).getBaseCurrency();
        bytes32 quoteCurrency = ISpotOracle(_oracle).getQuoteCurrency();
        _setRoute(baseCurrency, quoteCurrency, _oracle);

        //checks that price can be calculated
        _getSpotPrice(baseCurrency, quoteCurrency);

        emit OracleAdded(baseCurrency, quoteCurrency, _oracle);
    }

    /**
     * @notice Sets Oracle as a shortest route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracle         The Oracle contract (should implement ISpotOracle interface).
     */
    function _setRoute(
        bytes32 _baseCurrency,
        bytes32 _quoteCurrency,
        address _oracle
    ) internal {
        delete routes[_baseCurrency][_quoteCurrency];
        routes[_baseCurrency][_quoteCurrency].push(OracleData(address(_oracle), false));
        emit ShortRouteAdded(_baseCurrency, _quoteCurrency, _oracle);
    }

    /**
     * @notice Sets the given array of oracles as a route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracles        The array Oracle contracts.
     * @param   _isInverse      The array of flags whether price is inverted.
     */
    function addRoute(
        bytes32 _baseCurrency,
        bytes32 _quoteCurrency,
        address[] calldata _oracles,
        bool[] calldata _isInverse
    ) external onlyOwner {
        _validateRoute(_baseCurrency, _quoteCurrency, _oracles, _isInverse);

        uint256 length = _oracles.length;
        delete routes[_baseCurrency][_quoteCurrency];
        for (uint256 i = 0; i < length; i++) {
            routes[_baseCurrency][_quoteCurrency].push(OracleData(_oracles[i], _isInverse[i]));
        }

        //checks that price can be calculated
        _getSpotPrice(_baseCurrency, _quoteCurrency);

        emit RouteAdded(_baseCurrency, _quoteCurrency, _oracles, _isInverse);
    }

    /**
     * @notice Validates the given array of oracles as a route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracles        The array Oracle contracts.
     * @param   _isInverse      The array of flags whether price is inverted.
     */
    function _validateRoute(
        bytes32 _baseCurrency,
        bytes32 _quoteCurrency,
        address[] calldata _oracles,
        bool[] calldata _isInverse
    ) internal {
        require(_oracles.length == _isInverse.length, "arrays mismatch");
        uint256 length = _oracles.length;
        require(length > 0, "invalid oracles data");

        bytes32 srcCurrency;
        bytes32 destCurrency;
        if (!_isInverse[0]) {
            srcCurrency = ISpotOracle(_oracles[0]).getBaseCurrency();
            require(_baseCurrency == srcCurrency, "invalid route [1]");
            destCurrency = ISpotOracle(_oracles[0]).getQuoteCurrency();
        } else {
            srcCurrency = ISpotOracle(_oracles[0]).getQuoteCurrency();
            require(_baseCurrency == srcCurrency, "invalid route [2]");
            destCurrency = ISpotOracle(_oracles[0]).getBaseCurrency();
        }
        for (uint256 i = 1; i < length; i++) {
            bytes32 oracleBaseCurrency = ISpotOracle(_oracles[i]).getBaseCurrency();
            bytes32 oracleQuoteCurrency = ISpotOracle(_oracles[i]).getQuoteCurrency();
            if (!_isInverse[i]) {
                require(destCurrency == oracleBaseCurrency, "invalid route [3]");
                destCurrency = oracleQuoteCurrency;
            } else {
                require(destCurrency == oracleQuoteCurrency, "invalid route [4]");
                destCurrency = oracleBaseCurrency;
            }
        }
        require(_quoteCurrency == destCurrency, "invalid route [5]");
    }

    /**
     * @notice Removes a route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     */
    function removeRoute(bytes32 _baseCurrency, bytes32 _quoteCurrency) external onlyOwner {
        delete routes[_baseCurrency][_quoteCurrency];
        emit RouteRemoved(_baseCurrency, _quoteCurrency);
    }

    /**
     * @notice Returns the route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     */
    function getRoute(bytes32 _baseCurrency, bytes32 _quoteCurrency) external view returns (OracleData[] memory) {
        return routes[_baseCurrency][_quoteCurrency];
    }

    /**
     * @notice Calculates spot price.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     */
    function getSpotPrice(bytes32 _baseCurrency, bytes32 _quoteCurrency) external view returns (int128, uint256) {
        return _getSpotPrice(_baseCurrency, _quoteCurrency);
    }

    function _getSpotPrice(bytes32 _baseCurrency, bytes32 _quoteCurrency) internal view returns (int128, uint256) {
        OracleData[] storage routeOracles = routes[_baseCurrency][_quoteCurrency];
        uint256 length = routeOracles.length;
        bool isInverse;
        if (length == 0) {
            routeOracles = routes[_quoteCurrency][_baseCurrency];
            length = routeOracles.length;
            require(length > 0, "route not found");
            isInverse = true;
        }

        int128 price = ONE_64x64;
        int128 oraclePrice;
        uint256 oracleTime;
        for (uint256 i = 0; i < length; i++) {
            OracleData storage oracleData = routeOracles[i];
            (oraclePrice, oracleTime) = ISpotOracle(oracleData.oracle).getSpotPrice();
            if (!oracleData.isInverse) {
                price = price.mul(oraclePrice);
            } else {
                price = price.div(oraclePrice);
            }
        }
        if (isInverse) {
            price = ONE_64x64.div(price);
        }
        return (price, oracleTime);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "../interface/ISpotOracle.sol";

contract OracleInterfaceID {
    function _getOracleInterfaceID() internal pure returns (bytes4) {
        ISpotOracle i;
        return i.isMarketClosed.selector ^ i.isTerminated.selector ^ i.getSpotPrice.selector ^ i.getBaseCurrency.selector ^ i.getQuoteCurrency.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AbstractOracle.sol";
import "../interface/IPriceFeedsExt.sol";
import "../libraries/ABDKMath64x64.sol";
import "../libraries/QuickSort.sol";

contract SpotOracle is AbstractOracle {
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;
    using QuickSort for uint256[];
    using SafeMath for uint256;

    bytes32 private baseCurrency;
    bytes32 private quoteCurrency;

    address[] public priceFeeds;

    bool private marketClosed;
    bool private terminated;

    constructor(
        bytes32 _baseCurrency,
        bytes32 _quoteCurrency,
        address[] memory _priceFeeds
    ) {
        baseCurrency = _baseCurrency;
        quoteCurrency = _quoteCurrency;
        priceFeeds = _priceFeeds;
    }

    /**
     * @dev Sets the market is closed flag.
     */
    function setMarketClosed(bool _marketClosed) external override onlyOwner {
        marketClosed = _marketClosed;
    }

    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external view override returns (bool) {
        return marketClosed;
    }

    /**
     * @dev Sets terminated flag.
     */
    function setTerminated(bool _terminated) external override onlyOwner {
        terminated = _terminated;
    }

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() external view override returns (bool) {
        return terminated;
    }

    /**
     *  Spot price.
     */
    function getSpotPrice() external view override returns (int128, uint256) {
        uint256 length = priceFeeds.length;
        int128 price = 0;
        if (length < 3) {
            for (uint256 i = 0; i < length; i++) {
                uint256 oraclePrice = IPriceFeedsExt(priceFeeds[i]).latestAnswer();
                price = price.add(oraclePrice.fromUInt());
            }
            price = price.div(length.fromUInt());
        } else {
            uint256[] memory prices = new uint256[](length);
            for (uint256 i = 0; i < length; i++) {
                prices[i] = IPriceFeedsExt(priceFeeds[i]).latestAnswer();
            }
            prices = prices.sort();
            if (length % 2 != 0) {
                uint256 i = length / 2;
                price = prices[i].fromUInt();
            } else {
                uint256 i = length / 2;
                price = ((prices[i - 1].add(prices[i])).div(2)).fromUInt();
            }
        }
        return (price, block.timestamp);
    }

    /**
     * Get base currency symbol.
     */
    function getBaseCurrency() external view override returns (bytes32) {
        return baseCurrency;
    }

    /**
     * Get quote currency symbol.
     */
    function getQuoteCurrency() external view override returns (bytes32) {
        return quoteCurrency;
    }
}