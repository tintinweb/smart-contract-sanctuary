/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*

   /$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  | $DOCDOCDOCDOCDOOWWNNNXXXNNWCDOCDOCDOCDO$
  | $OCDOCDOCOOWXOdc:,'......',:ld0NDOCDOCO$     /$$$$$$             /$$$$$$  /$$                 /$$          
  | $CDOCDOCDKo;.                 .;0OCDOCD$    /$$__  $$           /$$__  $$| $$                |__/   
  | $DOCDOOO0;                    .:0CDOCDO$   | $$  \ $$ /$$$$$$$ | $$  \__/| $$$$$$$   /$$$$$$  /$$ /$$$$$$$ 
  | $OCDOCONc    ';,'..........';o0NDOCDOCO$   | $$  | $$| $$__  $$| $$      | $$__  $$ |____  $$| $$| $$__  $$
  | $CDOCDO0,   .cxxdddddddddddxx0NOCDOCDOC$   | $$  | $$| $$  \ $$| $$      | $$  \ $$  /$$$$$$$| $$| $$  \ $$
  | $DOCDOO0'   ,ddc::cdxxxo:;:oxOXCDOCDOCD$   | $$  | $$| $$  | $$| $$    $$| $$  | $$ /$$__  $$| $$| $$  | $$
  | $OCDOCONl..,oxxxddxxxxxxdddxxkXDOCDOCDO$   |  $$$$$$/| $$  | $$|  $$$$$$/| $$  | $$|  $$$$$$$| $$| $$  | $$
  | $CDOCDOON0kxxxxxxxxxdddxxxxxxONOCDOCDOC$    \______/ |__/  |__/ \______/ |__/  |__/ \_______/|__/|__/  |__/
  | $DOCDOCDOON0xxxxxxxxxxxxxxxxkKWCDOCDOCD$
  | $OCDOCDOCOON0xxxxxdxxxxxxxxkKWDOCDOCDOC$              /$$$$$$$                                /$$       /$$
  | $CDOCDOCDOCDKddxxxxxxxxxxdd0WOCDOCDOCDO$             | $$__  $$                              | $$      | $$
  | $DOCDOCDOON0c'oK0kxxdxkO0o'cKWCDOCDOCDO$             | $$  \ $$  /$$$$$$  /$$$$$$$   /$$$$$$ | $$  /$$$$$$$
  | $OCDOCNKxl;...,0W0occo0WK:..'ckNWDOCDOC$             | $$  | $$ /$$__  $$| $$__  $$ |____  $$| $$ /$$__  $$
  | $OWKkl,.   ....cKKdccdKNd.... .'o0WOCDO$             | $$  | $$| $$  \ $$| $$  \ $$  /$$$$$$$| $$| $$  | $$
  | $l,.       .....o0d::o0k,...     .;xXWO$             | $$  | $$| $$  | $$| $$  | $$ /$$__  $$| $$| $$  | $$
  | $          .....,lc::cdc.....       .cO$             | $$$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$| $$|  $$$$$$$
  | $           .....';:::;......         .$             |_______/  \______/ |__/  |__/ \_______/|__/ \_______/
  | $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  |________________________________________/

  OnChainDonald (OCD) is a collection of 2024 unique Donalds:
  - Built with long term preservation and decentralization in mind
  - All metadata and images are generated and stored 100% on-chain
  - Each Donald is unique and is composed from 9 traits with 73 values
  - In addition, there is an optional special trait with 17 values (opt-in on mint)
  - Extensive API surface to build on

*/

// File: base64-sol/base64.sol

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Counters.sol

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/finance/PaymentSplitter.sol


// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// File: contracts/OnChainDonald.sol

contract OnChainDonald is
    ERC721,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // State
    uint256 public state;
    uint256 internal constant STATE_INIT = 0;
    uint256 internal constant STATE_MINTING = 1;
    uint256 internal constant STATE_MINTING_REVEALED = 2;
    uint256 internal constant STATE_MINTED = 3;
    uint256 internal constant STATE_LOCKED = 4;

    // Nifties
    Counters.Counter public numMinted;
    uint256 public constant MAX_MINTS = 2024;
    uint256 internal constant MAX_MINTS_PER_TX = 5;
    uint256 internal constant MINT_PRICE = 0.02024 ether;
    uint256 internal constant SPECIAL_MINT_PRICE = 0.045 ether;
    uint256 internal constant MAX_WHITELIST_MINTS_PER_TX = 2;
    mapping (address => bool) public whitelist;
    mapping(uint256 => bool) internal special;
    uint256 internal seed;
    string internal description =
        "OnChainDonald is a collection of 2024 unique Donalds. "
        "The artwork and metadata are fully on-chain, in a single contract.";

    // Traits
    string internal constant COLOR_BLACK = "#000000";
    string internal constant COLOR_WHITE = "#ffffff";
    string internal constant ATTRIBUTE_NAME_EYES = "Eyes";
    string internal constant ATTRIBUTE_NAME_EXPRESSION = "Expression";
    string internal constant ATTRIBUTE_NAME_SKIN = "Skin";
    string internal constant ATTRIBUTE_NAME_LOCATION = "Location";
    string internal constant ATTRIBUTE_NAME_HAIR = "Hair";
    string internal constant ATTRIBUTE_NAME_TIE = "Tie";
    string internal constant ATTRIBUTE_NAME_MOUTH = "Mouth";
    string internal constant ATTRIBUTE_NAME_SUIT = "Suit";
    string internal constant ATTRIBUTE_NAME_PIN = "Pin";
    string internal constant ATTRIBUTE_NAME_SPECIALITY = "Speciality";

    string[] internal locations = [
        "",
        "Red Room",
        "Blue Room",
        "Office",
        "Boardroom",
        "Beach Villa",
        "Golf Resort",
        "Casino",
        "Penthouse",
        "Podium",
        "Mars",
        "Swamp"
    ];

    uint256[] internal locationColors = [
        0xb31942, 0xb31942, 0xb31942,
        0x54000c, 0x54000c, 0x54000c,
        0x000c54, 0x000c54, 0x000c54,
        0xb22234, 0xffffff, 0x3c3b6e,
        0xd98922, 0xf9c35d, 0xa83809,
        0x3e91a3, 0x718e73, 0xbba58f,
        0x93dbdf, 0x52a9bb, 0x8daf23,
        0xfbd946, 0xf55022, 0xff98b0,
        0xb38728, 0xfbf5b8, 0xcfb162,
        0xb5a084, 0x9c815d, 0x957d64,
        0x0e0a22, 0xcb3927, 0xf8b37c,
        0xe5d059, 0x6dba3c, 0x42063c
    ];

    string[] internal expressions = [
        "",
        "Neutral",
        "Wink",
        "Squint",
        "Surprised"
    ];

    uint256 internal NEUTRAL_EXPRESSION_INDEX = 1;
    uint256 internal WINK_EXPRESSION_INDEX = 2;
    uint256 internal SQUINT_EXPRESSION_INDEX = 3;
    uint256 internal SURPRISED_EXPRESSION_INDEX = 4;

    string[] internal eyes = [
        "",
        "Brown",
        "Dark Grey",
        "Black",
        "Hollow",
        "Pearl",
        "Blue",
        "Green",
        "Pepe",
        "Patriot",
        "Laser",
        "Hollow Blue",
        "Candy Apple"
    ];

    uint256[] internal eyeRarities = [
        0, // Unrevealed
        120, // Brown
        410, // Dark Grey
        30, // Black
        60, // Hollow
        50, // Pearl
        60, // Blue
        60, // Green
        30, // Pepe
        50, // Patriot
        40, // Laser
        40, // Hollow Blue
        50  // Candy Apple
    ];

    uint256 internal HOLLOW_EYES_INDEX = 4;
    uint256 internal PEPE_EYES_INDEX = 8;
    uint256 internal PATRIOT_EYES_INDEX = 9;
    uint256 internal LASER_EYES_INDEX = 10;

    uint256[] internal eyeColors = [
        0x000000,
        0x804800, // Brown
        0x394545, // Dark Grey
        0x111111, // Black
        0x000000, // Hollow
        0x6e695f, // Pearl
        0x3d4dcb, // Blue
        0x55ab35, // Green
        0x000000, // Regular
        0x0000ff, // Patriot
        0xff0000, // Laser
        0x2222d8, // Hollow Blue
        0xf51600  // Candy Apple
    ];

    bool[] internal pupils = [
        false,
        true,
        true,
        false,
        false,
        true,
        true,
        true,
        true,
        false,
        false,
        false,
        true
    ];

    string[] internal skins = [
        "",
        "Pale",
        "Warm Pale",
        "Toned Pale",
        "Glow",
        "Mahogany",
        "Orange",
        "Carrot",
        "Burned",
        "Mango",
        "Alien",
        "Pepe",
        "Nyan",
        "White"
    ];

    uint256[] internal skinRarities = [
        0, // Unrevealed
        110, // Pale
        170, // Warm Pale
        176, // Toned Pale
        163, // Glow
        30, // Mahogany
        85, // Orange
        85, // Carrot
        80, // Burned
        65, // Mango
        7, // Alien
        5, // Pepe
        4, // Nyan
        20 // White
    ];

    uint256[] internal skinFaceColors = [
        0x000000,
        0xfee2da,
        0xfecebe,
        0xf0be9b,
        0xf6a685,
        0xb55e45,
        0xffa500,
        0xec9332,
        0xe5887c,
        0xfd844e,        
        0x98aa9c,
        0x69804d,
        0xf391f2,
        0xfff0ea
    ];

    uint256[] internal skinNoseColors = [
        0x000000,
        0xfdf6f6,
        0xffe0e0,
        0xf6ccc6,
        0xffc0a0,
        0xc56e55,
        0xffd020,
        0xe9793c,
        0xf5988c,
        0xff995e,
        0xb2beb5,
        0x89a06d,
        0xf361c1,
        0xfffbfb
    ];

    uint256[] internal skinLipsColors = [
        0x000000,
        0xf0c4b9,
        0xca848a,
        0xb56d69,
        0xc86070,
        0x803d3e,
        0xa06000,
        0xcc6332,
        0xc5685c,
        0xfd541e,
        0x648688,
        0x9a3828,
        0xf33191,
        0xf4c8bc
    ];

    string[] internal mouths = [
        "",
        "Teethy",
        "Closed",
        "Yelling",
        "Taunting",
        "Stern",
        "Pursed",
        "Pepe"
    ];

    uint256[] internal mouthRarities = [
        0,
        175, // Teethy
        150, // Closed
        225, // Yelling
        100, // Taunting
        150, // Stern
        100, // Pursed
        100  // Pepe
    ];

    uint256 internal TEETHY_MOUTH_INDEX = 1;
    uint256 internal CLOSED_MOUTH_INDEX = 2;
    uint256 internal OPEN_MOUTH_INDEX = 3;
    uint256 internal TAUNTING_MOUTH_INDEX = 4;
    uint256 internal STERN_MOUTH_INDEX = 5;
    uint256 internal PURSED_MOUTH_INDEX = 6;
    uint256 internal PEPE_MOUTH_INDEX = 7;

    string[] internal hairs = [
        "",
        "Brown",
        "Copper",
        "Maga",
        "Blonde",
        "White",
        "Cream",
        "Platinum",
        "Silver",
        "Punk",
        "Black",
        "Bald",
        "Gold Flame"
    ];

    uint256[] internal hairRarities = [
        0,
        100, // Brown
        60, // Copper
        160, // Maga
        140, // Blonde
        100, // White
        100, // Cream
        60, // Platinum
        70, // Silver
        20, // Punk
        60, // Black
        100, // Bald,
        30 // Gold Flame
    ];

    uint256[] internal hairColors = [
        0x000000,
        0xd7a183,
        0xef9655,
        0xefc680,
        0xfad799,
        0xf8f8f8,
        0xfaebd7,
        0xdfdad0,
        0xbabfc8,
        0xc46ce9,
        0x080808,
        0x000000,
        0xe46029,
        0xef8045
    ];

    uint256 internal BALD_HAIR_INDEX = 11;

    string[] internal ties = [
        "",
        "Red",
        "Black",
        "Blue",
        "Yellow",
        "Gold",
        "Red Stripes",
        "Blue Stripes",
        "Black Stripes",
        "True Patriot"
    ];

    uint256 internal TIE_STRIPES_START_INDEX = 6;
    uint256 internal PATRIOT_TIE_INDEX = 9;

    uint256[] internal tieColors = [
        0x000000,
        0xd7282a,
        0x000000,
        0x0000ff,
        0xfff642,
        0xffd700,
        0xff0000,
        0x0000ff,
        0x000000,
        0x1010e0
    ];

    string[] internal suits = [
        "",
        "Black",
        "Navy",
        "None"
    ];

    uint256[] internal suitRarities = [
        0,
        400,
        400,
        200
    ];

    uint256[] internal suitColors = [
        0x000000,
        0x080808,
        0x193059,
        0x000000
    ];

    uint256[] internal suitLapelColors = [
        0x000000,
        0x161616,
        0x203865,
        0x000000
    ];

    uint256 internal SUIT_NONE_INDEX = 3;

    string[] internal pins = [
        "",
        "None",
        "Patriot"
    ];

    uint256 internal PIN_NONE_INDEX = 1;
    uint256 internal PIN_PATRIOT_INDEX = 2;

    string[] internal specialities = [
        "None",
        "Covfefe",
        "Hamberder",
        "Macho",
        "Dancer",
        "Big Hands",
        "Golfer",
        "Honest",
        "Dealmaker",
        "Rich",
        "Genius",
        "Patriot",
        "Strong",
        "Great",
        "Humble",
        "Big League",
        "Winner",
        "Handsome"
    ];

    uint256 internal SPECIALITY_NONE_INDEX = 0;

    struct Don {
        uint256 tokenId;
        bool revealed;
        bool special;
        uint256 eyes;
        uint256 expression;
        uint256 skin;
        uint256 location;
        uint256 hair;
        uint256 tie;
        uint256 mouth;
        uint256 suit;
        uint256 pin;
        uint256 speciality;
    }

    constructor(address[] memory _payees, uint256[] memory _shares)
        payable
        ERC721("OnChainDonald", "OCD")
        PaymentSplitter(_payees, _shares) {}

    function _safeMint(uint256 _quantity, bool _special) private {
        require(_quantity > 0);
        require(
            numMinted.current().add(_quantity) <= MAX_MINTS,
            "Cannot exceed total supply"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            numMinted.increment();
            uint256 mintIndex = numMinted.current();

            if (mintIndex <= MAX_MINTS) {
                _safeMint(msg.sender, mintIndex);
                if (_special) {
                    special[mintIndex] = true;
                }
            }
        }
    }

    function mint(uint256 _quantity, bool _special)
        external
        payable
        nonReentrant
    {
        require(
            state == STATE_MINTING || state == STATE_MINTING_REVEALED,
            "Mint closed"
        );
        require(_quantity > 0 && _quantity <= MAX_MINTS_PER_TX);
        require(
            msg.value >=
                (_special ? SPECIAL_MINT_PRICE : MINT_PRICE).mul(_quantity),
            "Payment too small"
        );

        _safeMint(_quantity, _special);
    }

    function whitelistMint(uint256 _quantity)
        external
        payable
        nonReentrant
    {
        require(state == STATE_MINTING || state == STATE_MINTING);
        require(whitelist[msg.sender], "Not whitelisted");
        require(_quantity > 0 && _quantity <= MAX_WHITELIST_MINTS_PER_TX);
        require(msg.value >= MINT_PRICE.mul(_quantity), "Payment too small");

        _safeMint(_quantity, true);
        whitelist[msg.sender] = false;
    }

    function whitelistAddresses(address[] memory _addresses) external onlyOwner {
        require(state == STATE_INIT || state == STATE_MINTING);

        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function startMint() external onlyOwner {
        require(state == STATE_INIT);

        state = STATE_MINTING;
    }

    function reveal(uint256 _seed) external onlyOwner {
        require(state == STATE_MINTING);
        require(_seed != 0);

        state = STATE_MINTING_REVEALED;
        seed = _seed + 0x201620202024c0fefe;
    }

    function closeMint() external onlyOwner {
        require(state == STATE_MINTING_REVEALED);

        state = STATE_MINTED;
    }

    function lock() external onlyOwner {
        require(state == STATE_MINTED);

        state = STATE_LOCKED;
    }

    function setMeta(string memory _description) external onlyOwner {
        require(state != STATE_LOCKED);

        description = _description;
    }

    function random(uint256 _seed, string memory input)
        private
        pure
        returns (uint256)
    {
        return _seed + uint256(keccak256(abi.encodePacked(input)));
    }

    function pluck(
        uint256 _seed,
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) private pure returns (uint256) {
        uint256 rand = random(
            _seed,
            string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
        );
        return (rand % (sourceArray.length - 1)) + 1;
    }

    function pluckRarities(
        uint256 _seed,
        uint256 tokenId,
        string memory keyPrefix,
        uint256[] memory rarityArray
    ) private pure returns (uint256) {

        uint256 rand = random(
            _seed,
            string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
        ) % 1000;

        uint256 i = 0;
        uint256 acc = 0;

        while (i < rarityArray.length - 1) {
            acc += rarityArray[i];
            if(rand < acc) break;
            i++;
        }

        return i;
    }

    function makeFilledEllipse(
        uint256 cx,
        uint256 cy,
        uint256 rx,
        uint256 ry,
        string memory fill,
        string memory extras
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<ellipse cx="',
                    Strings.toString(cx),
                    '" cy="',
                    Strings.toString(cy),
                    '" rx="',
                    Strings.toString(rx),
                    '" ry="',
                    Strings.toString(ry),
                    '" fill="',
                    fill,
                    '" ',
                    extras,
                    "/>"
                )
            );
    }

    function makePolygon(string memory points, string memory fill)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<polygon points="',
                    points,
                    '" fill="',
                    fill,
                    '" />'
                )
            );
    }

    function uint8tohexchar(uint8 i) private pure returns (uint8) {
        return
            (i > 9)
                ? (i + 87) // ascii a-f
                : (i + 48); // ascii 0-9
    }

    function hexColorToString(uint256 i) private pure returns (string memory) {
        bytes memory o = new bytes(7);
        uint24 mask = 0x00000f;

        uint256 j;
        for (j = 6; j > 0; --j) {
            o[j] = bytes1(uint8tohexchar(uint8(i & mask)));
            i = i >> 4;
        }
        o[0] = "#";
        return string(o);
    }

    function getSuitSVG(Don memory don) private view returns (string memory) {
        uint256 suitIndex = don.suit;
        uint256 pinIndex = don.pin;
        string memory suitColor = hexColorToString(suitColors[suitIndex]);
        string memory suitLapelColor = hexColorToString(
            suitLapelColors[suitIndex]
        );

        return
            string(
                abi.encodePacked(
                    suitIndex < SUIT_NONE_INDEX
                        ? makePolygon(
                            "0 220 80 180 90 160 122 256 0 256",
                            suitColor
                        )
                        : "",
                    suitIndex < SUIT_NONE_INDEX
                        ? makePolygon(
                            "256 240 176 180 166 160 138 256 256 256",
                            suitColor
                        )
                        : "",
                    suitIndex < SUIT_NONE_INDEX
                        ? makePolygon(
                            "90 160 122 256 83 256 65 225 78 218 64 210",
                            suitLapelColor
                        )
                        : "",
                    suitIndex < SUIT_NONE_INDEX
                        ? makePolygon(
                            "166 160 138 256 173 256 191 225 178 218 192 210",
                            suitLapelColor
                        )
                        : "",
                    pinIndex == PIN_PATRIOT_INDEX
                        ? '<text x="226" y="175" transform="rotate(18 0 0)" font-family="Tahoma, sans-serif" font-size="14" fill="#FFD700">&#127482;&#127480;</text>'
                        : ""
                )
            );
    }

    function getShirtAndTieSVG(Don memory don)
        private
        view
        returns (string memory)
    {
        uint256 tieIndex = don.tie;
        uint256 suitIndex = don.suit;
        string memory tieColor = hexColorToString(tieColors[tieIndex]);
        string memory shirtCollarColor = hexColorToString(0xffffff);
        string memory shirtBodyColor = hexColorToString(0xeaeaea);
        string
            memory shirtWithSuit = "92 160 160 160 180 190 220 256 190 256 168 220 170 256 85 256 85 220 66 256 38 256";
        string
            memory shirtWithoutSuit = "92 160 160 160 220 180 240 256 170 256 85 256 20 256 30 180";
        string
            memory tiePolygon = "129, 160, 141, 190, 133, 200, 150, 256, 110, 256, 123, 200, 115, 190";

        return
            string(
                abi.encodePacked(
                    makePolygon(
                        suitIndex < SUIT_NONE_INDEX
                            ? shirtWithSuit
                            : shirtWithoutSuit,
                        shirtBodyColor
                    ),
                    makePolygon("130 160 105 210 90 165", shirtCollarColor),
                    makePolygon("126 160 151 210 166 165", shirtCollarColor),
                    makePolygon(tiePolygon, tieColor),
                    tieIndex >= TIE_STRIPES_START_INDEX
                        ? makePolygon(tiePolygon, "url(#p1)")
                        : ""
                )
            );
    }

    function getEyesSVG(Don memory don, string memory eyelashColor) private view returns (string memory) {
        uint256 eyeIndex = don.eyes;
        bool hasPupils = pupils[eyeIndex];
        uint256 expressionIndex = don.expression;
        uint256 eyeWidth = 12;
        uint256 eyeHeight = 5;
        uint256 pupilHeight = 4;
        uint256 pupilWidth = 4;
        uint256 laserWidth = 7;
        string memory lEyeColor = hasPupils ? COLOR_WHITE : hexColorToString(eyeColors[eyeIndex]);
        string memory rEyeColor = lEyeColor;
        string memory pupilColor = hexColorToString(eyeColors[eyeIndex]);
        string memory extras = "";
        string memory extraAttrs = "";
        string memory rEyeEmptyStr = "";

        if (expressionIndex == SQUINT_EXPRESSION_INDEX) {
            eyeHeight -= 2;
            pupilHeight--;
            laserWidth = 4;
        } else if (expressionIndex == WINK_EXPRESSION_INDEX) {
            rEyeEmptyStr = string(
                abi.encodePacked(
                    '<path d="M 150 100 C 155 99, 165 99, 170 100" stroke="',
                    hasPupils ? eyelashColor : rEyeColor,
                    '" stroke-linecap="round" stroke-width="4"',
                    (eyeIndex == HOLLOW_EYES_INDEX) ? ' opacity="0.5"' : "",
                    " />"
                )
            );
        } else if (expressionIndex == SURPRISED_EXPRESSION_INDEX) {
            eyeWidth -= 4;
            eyeHeight++;
            laserWidth += 5;
            pupilWidth++;
        }

        if(eyeIndex == PEPE_EYES_INDEX && expressionIndex != SQUINT_EXPRESSION_INDEX) {
            pupilHeight++;
            pupilWidth++;
        }

        if (expressionIndex == SURPRISED_EXPRESSION_INDEX && eyeIndex == PEPE_EYES_INDEX) {
            eyeWidth++;
            eyeHeight++;
        }

        if (hasPupils) {
            extras = string(
                abi.encodePacked(
                    makeFilledEllipse(
                        112,
                        100,
                        pupilWidth,
                        pupilHeight,
                        pupilColor,
                        extraAttrs
                    ),
                    (expressionIndex != WINK_EXPRESSION_INDEX)
                        ? makeFilledEllipse(
                            160,
                            100,
                            pupilWidth,
                            pupilHeight,
                            pupilColor,
                            extraAttrs
                        )
                        : ""
                )
            );

            lEyeColor = COLOR_WHITE;
            rEyeColor = COLOR_WHITE;
        }

        if (eyeIndex == PATRIOT_EYES_INDEX) {
            lEyeColor = hexColorToString(0xff0000);
        } else if (eyeIndex == LASER_EYES_INDEX) {
            if (laserWidth > 0) {
                extras = string(
                    abi.encodePacked(
                        '<line x1="112" y1="100" x2="266" y2="36" style="stroke:',
                        lEyeColor,
                        ";stroke-width:",
                        Strings.toString(laserWidth),
                        '" opacity="0.8" />'
                    )
                );
            }
            if (laserWidth > 0 && expressionIndex != WINK_EXPRESSION_INDEX) {
                extras = string(
                    abi.encodePacked(
                        extras,
                        '<line x1="160" y1="100" x2="266" y2="56" style="stroke:',
                        lEyeColor,
                        ";stroke-width:",
                        Strings.toString(laserWidth),
                        '" opacity="0.8" />'
                    )
                );
            }
        } else if (eyeIndex == HOLLOW_EYES_INDEX) {
            extraAttrs = 'fill-opacity="0.5"';
        }

        return
            string(
                abi.encodePacked(
                    makeFilledEllipse(
                        112,
                        100,
                        eyeWidth,
                        eyeHeight,
                        lEyeColor,
                        extraAttrs
                    ),
                    (expressionIndex != WINK_EXPRESSION_INDEX)
                        ? makeFilledEllipse(
                            160,
                            100,
                            eyeWidth,
                            eyeHeight,
                            rEyeColor,
                            extraAttrs
                        )
                        : rEyeEmptyStr,
                    extras
                )
            );
    }

    function getSkinSVG(Don memory don) private view returns (string memory) {
        uint256 skinIndex = don.skin;
        uint256 mouthIndex = don.mouth;
        string memory skinFaceColorStr = hexColorToString(
            skinFaceColors[skinIndex]
        );
        string memory skinNoseColorStr = hexColorToString(
            skinNoseColors[skinIndex]
        );
        string memory skinLipsColorStr = hexColorToString(
            skinLipsColors[skinIndex]
        );
        string memory mouthStr = "";

        if (mouthIndex == TEETHY_MOUTH_INDEX) {
            mouthStr = string(
                abi.encodePacked(
                    makeFilledEllipse(135, 156, 16, 8, skinLipsColorStr, ""),
                    makeFilledEllipse(135, 156, 12, 2, COLOR_WHITE, "")
                )
            );
        } else if (mouthIndex == CLOSED_MOUTH_INDEX) {
            mouthStr = makeFilledEllipse(135, 156, 16, 4, skinLipsColorStr, "");
        } else if (mouthIndex == OPEN_MOUTH_INDEX) {
            mouthStr = string(
                abi.encodePacked(
                    makeFilledEllipse(135, 156, 18, 9, skinLipsColorStr, ""),
                    makeFilledEllipse(135, 149, 11, 2, COLOR_WHITE, ""),
                    makeFilledEllipse(135, 163, 11, 2, COLOR_WHITE, "")
                )
            );
        } else if (mouthIndex == TAUNTING_MOUTH_INDEX) {
            mouthStr = makeFilledEllipse(135, 156, 8, 8, skinLipsColorStr, "");
        } else if (mouthIndex == STERN_MOUTH_INDEX) {
            mouthStr = string(
                abi.encodePacked(
                    '<path d="M 121 156 C 126 153, 147 152, 151 155" stroke="',
                    skinLipsColorStr,
                    '" stroke-linecap="round" stroke-width="4" fill="transparent" />'
                )
            );
        } else if (mouthIndex == PURSED_MOUTH_INDEX) {
            mouthStr = string(
                abi.encodePacked(
                    '<ellipse cx="3" cy="206" rx="11" ry="7" fill="',
                    skinLipsColorStr,
                    '" transform="rotate(-40 0 0)" />'
                )
            );
        } else if (mouthIndex == PEPE_MOUTH_INDEX) {
            mouthStr = string(
                abi.encodePacked(
                    '<path d="M 110 150 C 118 155, 154 155, 162 150" stroke="',
                    skinLipsColorStr,
                    '" stroke-linecap="round" stroke-width="6" fill="transparent" />'
                )
            );
        } 

        return
            string(
                abi.encodePacked(
                    makeFilledEllipse(130, 108, 60, 75, skinFaceColorStr, ""),
                    makeFilledEllipse(138, 124, 8, 12, skinNoseColorStr, ""),
                    mouthStr
                )
            );
    }

    function getHairSVG(Don memory don) private view returns (string memory) {
        uint256 hairIndex = don.hair;
        string memory hairColorStr = hexColorToString(hairColors[hairIndex]);

        if (hairIndex == BALD_HAIR_INDEX) {
            return "";
        } else {
            return
                string(
                    abi.encodePacked(
                        makeFilledEllipse(140, 55, 64, 24, hairColorStr, ""),
                        makeFilledEllipse(
                            85,
                            70,
                            16,
                            38,
                            hairColorStr,
                            'transform="rotate(10 0 0)"'
                        )
                    )
                );
        }
    }

    function getLocationSVG(Don memory don, bool transparent)
        private
        view
        returns (string memory)
    {
        uint256 index = don.location * 3;
        string memory fill = transparent ? 'none' : 'url(#gr1)';
        
        return
            string(
                abi.encodePacked(
                    '<linearGradient id="gr1" x1="0" x2="0" y1="0" y2="1">'
                    '<stop offset="0%" stop-color="',
                    hexColorToString(locationColors[index]),
                    '"/>'
                    '<stop offset="40%" stop-color="',
                    hexColorToString(locationColors[index + 1]),
                    '"/>'
                    '<stop offset="80%" stop-color="',
                    hexColorToString(locationColors[index + 2]),
                    '"/>'
                    "</linearGradient>"
                    '<rect x="0" y="0" rx="0" ry="0" width="256" height="256" fill="', fill, '" />'
                )
            );
    }

    function getDefsSVG(Don memory don) private view returns (string memory) {
        string memory stroke = (don.tie == PATRIOT_TIE_INDEX)
            ? "#e01010"
            : COLOR_WHITE;
        string memory strokeOpacity = (don.tie == PATRIOT_TIE_INDEX)
            ? ""
            : 'stroke-opacity="0.7" ';

        return
            string(
                abi.encodePacked(
                    '<pattern id="p1" patternUnits="userSpaceOnUse" width="8" height="8" patternTransform="rotate(-55)">'
                    '<line x1="0" y="0" x2="0" y2="30" stroke="',
                    stroke,
                    '" ',
                    strokeOpacity,
                    'stroke-width="6" /></pattern>'
                )
            );
    }

    function getSVG(Don memory don, bool transparent) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" preserveaspectratio="xMidYMid meet" viewBox="0 0 256 256">',
                    getDefsSVG(don),
                    getLocationSVG(don, transparent),
                    getShirtAndTieSVG(don),
                    getSuitSVG(don),
                    getSkinSVG(don),
                    getHairSVG(don),
                    getEyesSVG(don, hexColorToString(skinLipsColors[don.skin])),
                    "</svg>"
                )
            );
    }

    function makeAttributeJson(string memory name, string memory value)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "',
                    name,
                    '", "value": "',
                    value,
                    '"},'
                )
            );
    }

    function makeCoreAttributesJson(Don memory don)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    makeAttributeJson(ATTRIBUTE_NAME_EYES, eyes[don.eyes]),
                    makeAttributeJson(
                        ATTRIBUTE_NAME_EXPRESSION,
                        expressions[don.expression]
                    ),
                    makeAttributeJson(ATTRIBUTE_NAME_SKIN, skins[don.skin]),
                    makeAttributeJson(
                        ATTRIBUTE_NAME_LOCATION,
                        locations[don.location]
                    ),
                    makeAttributeJson(ATTRIBUTE_NAME_HAIR, hairs[don.hair]),
                    makeAttributeJson(ATTRIBUTE_NAME_TIE, ties[don.tie]),
                    makeAttributeJson(ATTRIBUTE_NAME_MOUTH, mouths[don.mouth]),
                    makeAttributeJson(ATTRIBUTE_NAME_SUIT, suits[don.suit]),
                    makeAttributeJson(ATTRIBUTE_NAME_PIN, pins[don.pin])
                )
            );
    }

    function pluckPin(
        uint256 _seed,
        uint256 tokenId,
        uint256 suit
    ) internal view returns (uint256) {
        if (suit == SUIT_NONE_INDEX) {
            return PIN_NONE_INDEX;
        }

        uint256 val = random(
            _seed,
            string(
                abi.encodePacked(ATTRIBUTE_NAME_PIN, Strings.toString(tokenId))
            )
        ) % 4;
        if (val == 1) {
            return PIN_PATRIOT_INDEX;
        } else {
            return PIN_NONE_INDEX;
        }
    }

    function randomDon(
        uint256 _tokenId,
        uint256 _seed,
        bool _special,
        bool _revealed
    ) internal view returns (Don memory) {
        if (_revealed == false) {
            return Don(_tokenId, false, _special, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        }

        uint256 suit = pluckRarities(
            _seed,
            _tokenId,
            ATTRIBUTE_NAME_SUIT,
            suitRarities
        );
        uint256 speciality = _special
            ? pluck(
                _seed,
                _tokenId,
                ATTRIBUTE_NAME_SPECIALITY,
                specialities
            )
            : SPECIALITY_NONE_INDEX;

        return
            Don({
                tokenId: _tokenId,
                special: _special,
                revealed: true,
                eyes: pluckRarities(_seed, _tokenId, ATTRIBUTE_NAME_EYES, eyeRarities),
                expression: pluck(
                    _seed,
                    _tokenId,
                    ATTRIBUTE_NAME_EXPRESSION,
                    expressions
                ),
                skin: pluckRarities(_seed, _tokenId, ATTRIBUTE_NAME_SKIN, skinRarities),
                location: pluck(
                    _seed,
                    _tokenId,
                    ATTRIBUTE_NAME_LOCATION,
                    locations
                ),
                hair: pluckRarities(_seed, _tokenId, ATTRIBUTE_NAME_HAIR, hairRarities),
                tie: pluck(_seed, _tokenId, ATTRIBUTE_NAME_TIE, ties),
                mouth: pluckRarities(
                    _seed,
                    _tokenId,
                    ATTRIBUTE_NAME_MOUTH,
                    mouthRarities
                ),
                suit: suit,
                pin: pluckPin(_seed, _tokenId, suit),
                speciality: speciality
            });
    }

    function attrs(uint256 tokenId) public view returns (Don memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            randomDon(
                tokenId,
                seed,
                special[tokenId],
                state != STATE_INIT && state != STATE_MINTING
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return encodedMetadata(attrs(tokenId), false);
    }

    function namePrefix(Don memory don) internal view returns (string memory) {
        if (!don.revealed && don.special) {
            return "Special ";
        } else if (don.revealed && don.speciality != SPECIALITY_NONE_INDEX) {
            return string(abi.encodePacked(specialities[don.speciality], " "));
        } else {
            return "";
        }
    }

    function metadata(Don memory don, bool transparent)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    namePrefix(don),
                    "Donald #",
                    Strings.toString(don.tokenId),
                    '","description":"',
                    description,
                    '","attributes":[',
                    makeCoreAttributesJson(don),
                    makeAttributeJson(
                        ATTRIBUTE_NAME_SPECIALITY,
                        specialities[don.speciality]
                    ),
                    '{"trait_type": "Special", "value": "',
                    (don.special ? "Yes" : "No"),
                    '"}'
                    '],"image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(getSVG(don, transparent))),
                    '"}'
                )
            );
    }

    function encodedMetadata(Don memory don, bool transparent)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(metadata(don, transparent)))
                )
            );
    }

    function render(Don memory don, bool transparent)
        external
        view
        returns (string memory)
    {
        return encodedMetadata(don, transparent);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}