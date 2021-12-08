/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File @animoca/ethereum-contracts-core/contracts/utils/types/[email protected]

// SPDX-License-Identifier: MIT

// Partially derived from OpenZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/406c83649bd6169fc1b578e08506d78f0873b276/contracts/utils/Address.sol

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Upgrades the address type to check if it is a contract.
 */
library AddressIsContract {
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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File @animoca/ethereum-contracts-core/contracts/utils/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20Wrapper
 * Wraps ERC20 functions to support non-standard implementations which do not return a bool value.
 * Calls to the wrapped functions revert only if they throw or if they return false.
 */
library ERC20Wrapper {
    using AddressIsContract for address;

    function wrappedTransfer(
        IWrappedERC20 token,
        address to,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function wrappedTransferFrom(
        IWrappedERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function wrappedApprove(
        IWrappedERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callWithOptionalReturnData(IWrappedERC20 token, bytes memory callData) internal {
        address target = address(token);
        require(target.isContract(), "ERC20Wrapper: non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = target.call(callData);
        if (success) {
            if (data.length != 0) {
                require(abi.decode(data, (bool)), "ERC20Wrapper: operation failed");
            }
        } else {
            // revert using a standard revert message
            if (data.length == 0) {
                revert("ERC20Wrapper: operation failed");
            }

            // revert using the revert message coming from the call
            assembly {
                let size := mload(data)
                revert(add(32, data), size)
            }
        }
    }
}

interface IWrappedERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// File @openzeppelin/contracts/math/[email protected]

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


// File @openzeppelin/contracts/math/[email protected]

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


// File @animoca/ethereum-contracts-core/contracts/introspection/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165.
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


// File @animoca/ethereum-contracts-assets/contracts/token/ERC1155/interfaces/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Multi Token Standard, Tokens Receiver.
 * Interface for any contract that wants to support transfers from ERC1155 asset contracts.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * @dev Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     *  (i.e. 0xf23a6e61) to accept the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param id        The ID of the token being transferred
     * @param value     The amount of tokens being transferred
     * @param data      Additional data with no specified format
     * @return bytes4   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     *  (i.e. 0xbc197c81) if to accept the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the batch transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param ids       An array containing ids of each token being transferred (order and length must match _values array)
     * @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param data      Additional data with no specified format
     * @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @animoca/ethereum-contracts-assets/contracts/token/ERC1155/[email protected]

pragma solidity >=0.7.6 <0.8.0;


/**
 * @title ERC1155 Transfers Receiver Contract.
 * @dev The functions `onERC1155Received(address,address,uint256,uint256,bytes)`
 *  and `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)` need to be implemented by a child contract.
 */
abstract contract ERC1155TokenReceiver is IERC165, IERC1155TokenReceiver {
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    bytes4 internal constant _ERC1155_REJECTED = 0xffffffff;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC1155TokenReceiver).interfaceId;
    }
}


// File @animoca/ethereum-contracts-core/contracts/metatx/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}


// File @animoca/ethereum-contracts-core/contracts/access/[email protected]

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}


// File @animoca/ethereum-contracts-core/contracts/access/[email protected]

pragma solidity >=0.7.6 <0.8.0;


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
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }
}


// File contracts/staking/DeltaTimeStaking2021.sol

pragma solidity >=0.7.6 <0.8.0;




/**
 * @title Delta Time Staking 2021
 * Distribute REVV rewards over discrete-time schedules for the staking of Car NFTs.
 * This contract is designed on a self-service model, where users will stake NFTs, unstake NFTs and claim rewards through their own transactions only.
 */
contract DeltaTimeStaking2021 is ERC1155TokenReceiver, Ownable {
    using ERC20Wrapper for IWrappedERC20;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    event RewardsAdded(uint256 startPeriod, uint256 endPeriod, uint256 rewardsPerCycle);

    event Started();

    event NftStaked(address staker, uint256 cycle, uint256 tokenId, uint256 weight);

    event NftUnstaked(address staker, uint256 cycle, uint256 tokenId, uint256 weight);

    event RewardsClaimed(address staker, uint256 cycle, uint256 startPeriod, uint256 periods, uint256 amount);

    event HistoriesUpdated(address staker, uint256 startCycle, uint256 stakerStake, uint256 globalStake);

    event Disabled();

    /**
     * Used to represent the current staking status of an NFT.
     * Optimised for use in storage.
     */
    struct TokenInfo {
        address owner;
        uint64 weight;
        uint16 depositCycle;
        uint16 withdrawCycle;
    }

    /**
     * Used as a historical record of change of stake.
     * Stake represents an aggregation of staked token weights.
     * Optimised for use in storage.
     */
    struct Snapshot {
        uint128 stake;
        uint128 startCycle;
    }

    /**
     * Used to represent a staker's information about the next claim.
     * Optimised for use in storage.
     */
    struct NextClaim {
        uint16 period;
        uint64 globalSnapshotIndex;
        uint64 stakerSnapshotIndex;
    }

    /**
     * Used as a container to hold result values from computing rewards.
     */
    struct ComputedClaim {
        uint16 startPeriod;
        uint16 periods;
        uint256 amount;
    }

    bool public enabled = true;

    uint256 public totalRewardsPool;

    uint256 public startTimestamp;

    IWrappedERC20 public immutable rewardsTokenContract;
    IWhitelistedNftContract public immutable whitelistedNftContract;

    uint32 public immutable cycleLengthInSeconds;
    uint16 public immutable periodLengthInCycles;

    Snapshot[] public globalHistory;

    mapping(uint256 => uint64) public weightsByRarity;

    /* staker => snapshots*/
    mapping(address => Snapshot[]) public stakerHistories;

    /* staker => next claim */
    mapping(address => NextClaim) public nextClaims;

    /* tokenId => token info */
    mapping(uint256 => TokenInfo) public tokenInfos;

    /* period => rewardsPerCycle */
    mapping(uint256 => uint256) public rewardsSchedule;

    modifier hasStarted() {
        require(startTimestamp != 0, "NftStaking: staking not started");
        _;
    }

    modifier hasNotStarted() {
        require(startTimestamp == 0, "NftStaking: staking has started");
        _;
    }

    modifier isEnabled() {
        // solhint-disable-next-line reason-string
        require(enabled, "NftStaking: contract is not enabled");
        _;
    }

    modifier isNotEnabled() {
        require(!enabled, "NftStaking: contract is enabled");
        _;
    }

    /**
     * Constructor.
     * @dev Reverts if the period length value is zero.
     * @dev Reverts if the cycle length value is zero.
     * @dev Warning: cycles and periods need to be calibrated carefully.
     *  Small values will increase computation load while estimating and claiming rewards.
     *  Big values will increase the time to wait before a new period becomes claimable.
     * @param cycleLengthInSeconds_ The length of a cycle, in seconds.
     * @param periodLengthInCycles_ The length of a period, in cycles.
     * @param whitelistedNftContract_ The ERC1155-compliant (optional ERC721-compliance) contract from which staking is accepted.
     * @param rewardsTokenContract_ The ERC20-based token used as staking rewards.
     */
    constructor(
        uint32 cycleLengthInSeconds_,
        uint16 periodLengthInCycles_,
        IWhitelistedNftContract whitelistedNftContract_,
        IWrappedERC20 rewardsTokenContract_,
        uint256[] memory rarities,
        uint64[] memory weights
    ) Ownable(msg.sender) {
        require(rarities.length == weights.length, "NftStaking: wrong arguments");

        // solhint-disable-next-line reason-string
        require(cycleLengthInSeconds_ >= 1 minutes, "NftStaking: invalid cycle length");
        // solhint-disable-next-line reason-string
        require(periodLengthInCycles_ >= 2, "NftStaking: invalid period length");

        cycleLengthInSeconds = cycleLengthInSeconds_;
        periodLengthInCycles = periodLengthInCycles_;
        whitelistedNftContract = whitelistedNftContract_;
        rewardsTokenContract = rewardsTokenContract_;

        for (uint256 i = 0; i < rarities.length; ++i) {
            weightsByRarity[rarities[i]] = weights[i];
        }
    }

    /*                                            Admin Public Functions                                            */

    /**
     * Adds `rewardsPerCycle` reward amount for the period range from `startPeriod` to `endPeriod`, inclusive, to the rewards schedule.
     * The necessary amount of reward tokens is transferred to the contract. Cannot be used for past periods.
     * Can only be used to add rewards and not to remove them.
     * @dev Reverts if not called by the owner.
     * @dev Reverts if the start period is zero.
     * @dev Reverts if the end period precedes the start period.
     * @dev Reverts if attempting to add rewards for a period earlier than the current, after staking has started.
     * @dev Reverts if the reward tokens transfer fails.
     * @dev The rewards token contract emits an ERC20 Transfer event for the reward tokens transfer.
     * @dev Emits a RewardsAdded event.
     * @param startPeriod The starting period (inclusive).
     * @param endPeriod The ending period (inclusive).
     * @param rewardsPerCycle The reward amount to add for each cycle within range.
     */
    function addRewardsForPeriods(
        uint16 startPeriod,
        uint16 endPeriod,
        uint256 rewardsPerCycle
    ) external {
        _requireOwnership(msg.sender);
        require(startPeriod != 0 && startPeriod <= endPeriod, "NftStaking: wrong period range");

        uint16 periodLengthInCycles_ = periodLengthInCycles;

        if (startTimestamp != 0) {
            // solhint-disable-next-line reason-string
            require(startPeriod >= _getCurrentPeriod(periodLengthInCycles_), "NftStaking: already committed reward schedule");
        }

        for (uint256 period = startPeriod; period <= endPeriod; ++period) {
            rewardsSchedule[period] = rewardsSchedule[period].add(rewardsPerCycle);
        }

        uint256 addedRewards = rewardsPerCycle.mul(periodLengthInCycles_).mul(endPeriod - startPeriod + 1);

        totalRewardsPool = totalRewardsPool.add(addedRewards);

        rewardsTokenContract.wrappedTransferFrom(msg.sender, address(this), addedRewards);

        emit RewardsAdded(startPeriod, endPeriod, rewardsPerCycle);
    }

    /**
     * Starts the first cycle of staking, enabling users to stake NFTs.
     * @dev Reverts if not called by the owner.
     * @dev Reverts if the staking has already started.
     * @dev Emits a Started event.
     */
    function start() public hasNotStarted {
        _requireOwnership(msg.sender);
        startTimestamp = block.timestamp;
        emit Started();
    }

    /**
     * Permanently disables all staking and claiming.
     * This is an emergency recovery feature which is NOT part of the normal contract operation.
     * @dev Reverts if not called by the owner.
     * @dev Emits a Disabled event.
     */
    function disable() public {
        _requireOwnership(msg.sender);
        enabled = false;
        emit Disabled();
    }

    /**
     * Withdraws a specified amount of reward tokens from the contract it has been disabled.
     * @dev Reverts if not called by the owner.
     * @dev Reverts if the contract has not been disabled.
     * @dev Reverts if the reward tokens transfer fails.
     * @dev The rewards token contract emits an ERC20 Transfer event for the reward tokens transfer.
     * @param amount The amount to withdraw.
     */
    function withdrawRewardsPool(uint256 amount) public isNotEnabled {
        _requireOwnership(msg.sender);
        rewardsTokenContract.wrappedTransfer(msg.sender, amount);
    }

    /*                                             ERC1155TokenReceiver                                             */

    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 id,
        uint256, /*value*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        _stakeNft(id, from);
        return _ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        for (uint256 i = 0; i < ids.length; ++i) {
            _stakeNft(ids[i], from);
        }
        return _ERC1155_BATCH_RECEIVED;
    }

    /*                                            Staking Public Functions                                            */

    /**
     * Unstakes a deposited NFT from the contract and updates the histories accordingly.
     * The NFT's weight will not count for the current cycle.
     * @dev Reverts if the caller is not the original owner of the NFT.
     * @dev While the contract is enabled, reverts if the NFT is still frozen.
     * @dev Reverts if the NFT transfer back to the original owner fails.
     * @dev If ERC1155 safe transfers are supported by the receiver wallet,
     *  the whitelisted NFT contract emits an ERC1155 TransferSingle event for the NFT transfer back to the staker.
     * @dev If ERC1155 safe transfers are not supported by the receiver wallet,
     *  the whitelisted NFT contract emits an ERC721 Transfer event for the NFT transfer back to the staker.
     * @dev While the contract is enabled, emits a HistoriesUpdated event.
     * @dev Emits a NftUnstaked event.
     * @param tokenId The token identifier, referencing the NFT being unstaked.
     */
    function unstakeNft(uint256 tokenId) external {
        TokenInfo memory tokenInfo = tokenInfos[tokenId];

        // solhint-disable-next-line reason-string
        require(tokenInfo.owner == msg.sender, "NftStaking: token not staked or incorrect token owner");

        uint16 currentCycle = _getCycle(block.timestamp);

        if (enabled) {
            // ensure that at least an entire cycle has elapsed before unstaking the token to avoid
            // an exploit where a full cycle would be claimable if staking just before the end
            // of a cycle and unstaking right after the start of the new cycle
            require(currentCycle - tokenInfo.depositCycle >= 2, "NftStaking: token still frozen");

            _updateHistories(msg.sender, -int128(tokenInfo.weight), currentCycle);

            // clear the token owner to ensure it cannot be unstaked again without being re-staked
            tokenInfo.owner = address(0);

            // set the withdrawal cycle to ensure it cannot be re-staked during the same cycle
            tokenInfo.withdrawCycle = currentCycle;

            tokenInfos[tokenId] = tokenInfo;
        }

        whitelistedNftContract.transferFrom(address(this), msg.sender, tokenId);

        emit NftUnstaked(msg.sender, currentCycle, tokenId, tokenInfo.weight);
    }

    /**
     * Estimates the claimable rewards for the specified maximum number of past periods, starting at the next claimable period.
     * Estimations can be done only for periods which have already ended.
     * The maximum number of periods to claim can be calibrated to chunk down claims in several transactions to accomodate gas constraints.
     * @param maxPeriods The maximum number of periods to calculate for.
     * @return startPeriod The first period on which the computation starts.
     * @return periods The number of periods computed for.
     * @return amount The total claimable rewards.
     */
    function estimateRewards(uint16 maxPeriods)
        external
        view
        isEnabled
        hasStarted
        returns (
            uint16 startPeriod,
            uint16 periods,
            uint256 amount
        )
    {
        (ComputedClaim memory claim, ) = _computeRewards(msg.sender, maxPeriods);
        startPeriod = claim.startPeriod;
        periods = claim.periods;
        amount = claim.amount;
    }

    /**
     * Claims the claimable rewards for the specified maximum number of past periods, starting at the next claimable period.
     * Claims can be done only for periods which have already ended.
     * The maximum number of periods to claim can be calibrated to chunk down claims in several transactions to accomodate gas constraints.
     * @dev Reverts if the reward tokens transfer fails.
     * @dev The rewards token contract emits an ERC20 Transfer event for the reward tokens transfer.
     * @dev Emits a RewardsClaimed event.
     * @param maxPeriods The maximum number of periods to claim for.
     */
    function claimRewards(uint16 maxPeriods) external isEnabled hasStarted {
        NextClaim memory nextClaim = nextClaims[msg.sender];

        (ComputedClaim memory claim, NextClaim memory newNextClaim) = _computeRewards(msg.sender, maxPeriods);

        // free up memory on already processed staker snapshots
        Snapshot[] storage stakerHistory = stakerHistories[msg.sender];
        while (nextClaim.stakerSnapshotIndex < newNextClaim.stakerSnapshotIndex) {
            delete stakerHistory[nextClaim.stakerSnapshotIndex++];
        }

        if (claim.periods == 0) {
            return;
        }

        if (nextClaims[msg.sender].period == 0) {
            return;
        }

        Snapshot memory lastStakerSnapshot = stakerHistory[stakerHistory.length - 1];

        uint256 lastClaimedCycle = (claim.startPeriod + claim.periods - 1) * periodLengthInCycles;
        if (
            lastClaimedCycle >= lastStakerSnapshot.startCycle && // the claim reached the last staker snapshot
            lastStakerSnapshot.stake == 0 // and nothing is staked in the last staker snapshot
        ) {
            // re-init the next claim
            delete nextClaims[msg.sender];
        } else {
            nextClaims[msg.sender] = newNextClaim;
        }

        if (claim.amount != 0) {
            rewardsTokenContract.wrappedTransfer(msg.sender, claim.amount);
        }

        emit RewardsClaimed(msg.sender, _getCycle(block.timestamp), claim.startPeriod, claim.periods, claim.amount);
    }

    /*                                            Utility Public Functions                                            */

    /**
     * Retrieves the current cycle (index-1 based).
     * @return The current cycle (index-1 based).
     */
    function getCurrentCycle() external view returns (uint16) {
        return _getCycle(block.timestamp);
    }

    /**
     * Retrieves the current period (index-1 based).
     * @return The current period (index-1 based).
     */
    function getCurrentPeriod() external view returns (uint16) {
        return _getCurrentPeriod(periodLengthInCycles);
    }

    /**
     * Retrieves the last global snapshot index, if any.
     * @dev Reverts if the global history is empty.
     * @return The last global snapshot index.
     */
    function lastGlobalSnapshotIndex() external view returns (uint256) {
        uint256 length = globalHistory.length;
        // solhint-disable-next-line reason-string
        require(length != 0, "NftStaking: empty global history");
        return length - 1;
    }

    /**
     * Retrieves the last staker snapshot index, if any.
     * @dev Reverts if the staker history is empty.
     * @return The last staker snapshot index.
     */
    function lastStakerSnapshotIndex(address staker) external view returns (uint256) {
        uint256 length = stakerHistories[staker].length;
        // solhint-disable-next-line reason-string
        require(length != 0, "NftStaking: empty staker history");
        return length - 1;
    }

    /*                                            Staking Internal Functions                                            */

    /**
     * Stakes the NFT received by the contract for its owner. The NFT's weight will count for the current cycle.
     * @dev Reverts if the caller is not the whitelisted NFT contract.
     * @dev Emits an HistoriesUpdated event.
     * @dev Emits an NftStaked event.
     * @param tokenId Identifier of the staked NFT.
     * @param tokenOwner Owner of the staked NFT.
     */
    function _stakeNft(uint256 tokenId, address tokenOwner) internal isEnabled hasStarted {
        // solhint-disable-next-line reason-string
        require(address(whitelistedNftContract) == msg.sender, "NftStaking: contract not whitelisted");

        uint64 weight = _validateAndGetNftWeight(tokenId);

        uint16 periodLengthInCycles_ = periodLengthInCycles;
        uint16 currentCycle = _getCycle(block.timestamp);

        _updateHistories(tokenOwner, int128(weight), currentCycle);

        // initialise the next claim if it was the first stake for this staker or if
        // the next claim was re-initialised (ie. rewards were claimed until the last
        // staker snapshot and the last staker snapshot has no stake)
        if (nextClaims[tokenOwner].period == 0) {
            uint16 currentPeriod = _getPeriod(currentCycle, periodLengthInCycles_);
            nextClaims[tokenOwner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), 0);
        }

        uint16 withdrawCycle = tokenInfos[tokenId].withdrawCycle;
        // solhint-disable-next-line reason-string
        require(currentCycle != withdrawCycle, "NftStaking: unstaked token cooldown");

        // set the staked token's info
        tokenInfos[tokenId] = TokenInfo(tokenOwner, weight, currentCycle, 0);

        emit NftStaked(tokenOwner, currentCycle, tokenId, weight);
    }

    /**
     * Calculates the amount of rewards for a staker over a capped number of periods.
     * @dev Processes until the specified maximum number of periods to claim is reached,
     *  or the last computable period is reached, whichever occurs first.
     * @param staker The staker for whom the rewards will be computed.
     * @param maxPeriods Maximum number of periods over which to compute the rewards.
     * @return claim the result of computation
     * @return nextClaim the next claim which can be used to update the staker's state
     */
    // solhint-disable-next-line code-complexity
    function _computeRewards(address staker, uint16 maxPeriods) internal view returns (ComputedClaim memory claim, NextClaim memory nextClaim) {
        // computing 0 periods
        if (maxPeriods == 0) {
            return (claim, nextClaim);
        }

        // the history is empty
        if (globalHistory.length == 0) {
            return (claim, nextClaim);
        }

        nextClaim = nextClaims[staker];
        claim.startPeriod = nextClaim.period;

        // nothing has been staked yet
        if (claim.startPeriod == 0) {
            return (claim, nextClaim);
        }

        uint16 periodLengthInCycles_ = periodLengthInCycles;
        uint16 endClaimPeriod = _getCurrentPeriod(periodLengthInCycles_);

        // current period is not claimable
        if (nextClaim.period == endClaimPeriod) {
            return (claim, nextClaim);
        }

        // retrieve the next snapshots if they exist
        Snapshot[] memory stakerHistory = stakerHistories[staker];

        Snapshot memory globalSnapshot = globalHistory[nextClaim.globalSnapshotIndex];
        Snapshot memory stakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex];
        Snapshot memory nextGlobalSnapshot;
        Snapshot memory nextStakerSnapshot;

        if (nextClaim.globalSnapshotIndex != globalHistory.length - 1) {
            nextGlobalSnapshot = globalHistory[nextClaim.globalSnapshotIndex + 1];
        }
        if (nextClaim.stakerSnapshotIndex != stakerHistory.length - 1) {
            nextStakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex + 1];
        }

        // excludes the current period
        claim.periods = endClaimPeriod - nextClaim.period;

        if (maxPeriods < claim.periods) {
            claim.periods = maxPeriods;
        }

        // re-calibrate the end claim period based on the actual number of
        // periods to claim. nextClaim.period will be updated to this value
        // after exiting the loop
        endClaimPeriod = nextClaim.period + claim.periods;

        // iterate over periods
        while (nextClaim.period != endClaimPeriod) {
            uint16 nextPeriodStartCycle = nextClaim.period * periodLengthInCycles_ + 1;
            uint256 rewardPerCycle = rewardsSchedule[nextClaim.period];
            uint256 startCycle = nextPeriodStartCycle - periodLengthInCycles_;
            uint256 endCycle = 0;

            // iterate over global snapshots
            while (endCycle != nextPeriodStartCycle) {
                // find the range-to-claim starting cycle, where the current
                // global snapshot, the current staker snapshot, and the current
                // period overlap
                if (globalSnapshot.startCycle > startCycle) {
                    startCycle = globalSnapshot.startCycle;
                }
                if (stakerSnapshot.startCycle > startCycle) {
                    startCycle = stakerSnapshot.startCycle;
                }

                // find the range-to-claim ending cycle, where the current
                // global snapshot, the current staker snapshot, and the current
                // period no longer overlap. The end cycle is exclusive of the
                // range-to-claim and represents the beginning cycle of the next
                // range-to-claim
                endCycle = nextPeriodStartCycle;
                if ((nextGlobalSnapshot.startCycle != 0) && (nextGlobalSnapshot.startCycle < endCycle)) {
                    endCycle = nextGlobalSnapshot.startCycle;
                }

                // only calculate and update the claimable rewards if there is
                // something to calculate with
                if ((globalSnapshot.stake != 0) && (stakerSnapshot.stake != 0) && (rewardPerCycle != 0)) {
                    uint256 snapshotReward = (endCycle - startCycle).mul(rewardPerCycle).mul(stakerSnapshot.stake);
                    snapshotReward /= globalSnapshot.stake;

                    claim.amount = claim.amount.add(snapshotReward);
                }

                // advance the current global snapshot to the next (if any)
                // if its cycle range has been fully processed and if the next
                // snapshot starts at most on next period first cycle
                if (nextGlobalSnapshot.startCycle == endCycle) {
                    globalSnapshot = nextGlobalSnapshot;
                    ++nextClaim.globalSnapshotIndex;

                    if (nextClaim.globalSnapshotIndex != globalHistory.length - 1) {
                        nextGlobalSnapshot = globalHistory[nextClaim.globalSnapshotIndex + 1];
                    } else {
                        nextGlobalSnapshot = Snapshot(0, 0);
                    }
                }

                // advance the current staker snapshot to the next (if any)
                // if its cycle range has been fully processed and if the next
                // snapshot starts at most on next period first cycle
                if (nextStakerSnapshot.startCycle == endCycle) {
                    stakerSnapshot = nextStakerSnapshot;
                    ++nextClaim.stakerSnapshotIndex;

                    if (nextClaim.stakerSnapshotIndex != stakerHistory.length - 1) {
                        nextStakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex + 1];
                    } else {
                        nextStakerSnapshot = Snapshot(0, 0);
                    }
                }
            }

            ++nextClaim.period;
        }

        return (claim, nextClaim);
    }

    /**
     * Updates the global and staker histories at the current cycle with a new difference in stake.
     * @dev Emits a HistoriesUpdated event.
     * @param staker The staker who is updating the history.
     * @param stakeDelta The difference to apply to the current stake.
     * @param currentCycle The current cycle.
     */
    function _updateHistories(
        address staker,
        int128 stakeDelta,
        uint16 currentCycle
    ) internal {
        uint256 stakerSnapshotIndex = _updateHistory(stakerHistories[staker], stakeDelta, currentCycle);
        uint256 globalSnapshotIndex = _updateHistory(globalHistory, stakeDelta, currentCycle);

        emit HistoriesUpdated(staker, currentCycle, stakerHistories[staker][stakerSnapshotIndex].stake, globalHistory[globalSnapshotIndex].stake);
    }

    /**
     * Updates the history at the current cycle with a new difference in stake.
     * @dev It will update the latest snapshot if it starts at the current cycle, otherwise will create a new snapshot with the updated stake.
     * @param history The history to update.
     * @param stakeDelta The difference to apply to the current stake.
     * @param currentCycle The current cycle.
     * @return snapshotIndex Index of the snapshot that was updated or created (i.e. the latest snapshot index).
     */
    function _updateHistory(
        Snapshot[] storage history,
        int128 stakeDelta,
        uint16 currentCycle
    ) internal returns (uint256 snapshotIndex) {
        uint256 historyLength = history.length;
        uint128 snapshotStake;

        if (historyLength != 0) {
            // there is an existing snapshot
            snapshotIndex = historyLength - 1;
            Snapshot storage sSnapshot = history[snapshotIndex];
            snapshotStake = uint256(int256(sSnapshot.stake).add(stakeDelta)).toUint128();

            if (sSnapshot.startCycle == currentCycle) {
                // update the snapshot if it starts on the current cycle
                sSnapshot.stake = snapshotStake;
                return snapshotIndex;
            }

            // update the snapshot index (as a reflection that a new latest
            // snapshot will be added to the history), if there was already an
            // existing snapshot
            snapshotIndex += 1;
        } else {
            // the snapshot index (as a reflection that a new latest snapshot
            // will be added to the history) should already be initialized
            // correctly to the default value 0

            // the stake delta will not be negative, if we have no history, as
            // that would indicate that we are unstaking without having staked
            // anything first
            snapshotStake = uint128(stakeDelta);
        }

        Snapshot memory mSnapshot;
        mSnapshot.stake = snapshotStake;
        mSnapshot.startCycle = currentCycle;

        // add a new snapshot in the history
        history.push(mSnapshot);
    }

    /*                                           Utility Internal Functions                                           */

    /**
     * Retrieves the cycle (index-1 based) at the specified timestamp.
     * @param timestamp The timestamp for which the cycle is derived from.
     * @return The cycle (index-1 based) at the specified timestamp, or zero if the contract is not started yet.
     */
    function _getCycle(uint256 timestamp) internal view returns (uint16) {
        uint256 startTimestamp_ = startTimestamp;
        if (startTimestamp_ == 0) return 0;
        return (((timestamp - startTimestamp_) / uint256(cycleLengthInSeconds)) + 1).toUint16();
    }

    /**
     * Retrieves the period (index-1 based) for the specified cycle and period length.
     * @param cycle The cycle within the period to retrieve.
     * @param periodLengthInCycles_ Length of a period, in cycles.
     * @return The period (index-1 based) for the specified cycle and period length, 0r zero if `cycle` is zero.
     */
    function _getPeriod(uint16 cycle, uint16 periodLengthInCycles_) internal pure returns (uint16) {
        if (cycle == 0) {
            return 0;
        }
        return (cycle - 1) / periodLengthInCycles_ + 1;
    }

    /**
     * Retrieves the current period (index-1 based).
     * @param periodLengthInCycles_ Length of a period, in cycles.
     * @return The current period (index-1 based).
     */
    function _getCurrentPeriod(uint16 periodLengthInCycles_) internal view returns (uint16) {
        return _getPeriod(_getCycle(block.timestamp), periodLengthInCycles_);
    }

    /*                                                Internal Hooks                                                */

    /**
     * Verifies that the token is eligible and returns its associated weight.
     * @dev Reverts if the token is not a 2019 or 2020 Car NFT.
     * @param nftId uint256 token identifier of the NFT.
     * @return uint64 the weight of the NFT.
     */
    function _validateAndGetNftWeight(uint256 nftId) internal view returns (uint64) {
        // Ids bits layout specification:
        // https://github.com/animocabrands/f1dt-core_metadata/blob/v0.1.1/src/constants.js
        uint256 nonFungible = (nftId >> 255) & 1;
        uint256 tokenType = (nftId >> 240) & 0xFF;
        uint256 tokenSeason = (nftId >> 224) & 0xFF;
        uint256 tokenRarity = (nftId >> 176) & 0xFF;

        // For interpretation of values, refer to https://github.com/animocabrands/f1dt-core_metadata/blob/version-1.0.3/src/mappings/
        // Types: https://github.com/animocabrands/f1dt-core_metadata/blob/version-1.0.3/src/mappings/CommonAttributes/Type/Types.js
        // Seasons: https://github.com/animocabrands/f1dt-core_metadata/blob/version-1.0.3/src/mappings/CommonAttributes/Season/Seasons.js
        // Rarities: https://github.com/animocabrands/f1dt-core_metadata/blob/version-1.0.3/src/mappings/CommonAttributes/Rarity/Rarities.js
        require(nonFungible == 1 && tokenType == 1 && (tokenSeason == 2 || tokenSeason == 3), "NftStaking: wrong token");

        return weightsByRarity[tokenRarity];
    }
}

interface IWhitelistedNftContract {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}