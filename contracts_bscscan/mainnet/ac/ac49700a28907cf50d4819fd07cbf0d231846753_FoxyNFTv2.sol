/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-01
*/

// SPDX-License-Identifier: MIT
/*
 * Foxy NFT V2.0.0.5
 * App:             https://foxynft.org/
 * Twitter:         https://twitter.com/foxyequilibrium
 * Telegram:        https://t.me/foxyequilibrium
 * Medium:          https://medium.com/@foxynft
 */

pragma solidity ^0.8.0;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: localhost/openzeppelin-contracts-master/contracts/utils/Counters.sol



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing BEP721 ids, or counting request ids.
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
}

// File: localhost/openzeppelin-contracts-master/contracts/utils/introspection/IBEP165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({BEP165Checker}).
 *
 * For an implementation, see {BEP165}.
 */
interface IBEP165 {
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

// File: localhost/openzeppelin-contracts-master/contracts/utils/introspection/BEP165.sol



pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IBEP165} interface.
 *
 * Contracts that want to implement BEP165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {BEP165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract BEP165 is IBEP165 {
    /**
     * @dev See {IBEP165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBEP165).interfaceId;
    }
}

// File: localhost/openzeppelin-contracts-master/contracts/utils/Initializable.sol



// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
// File: localhost/openzeppelin-contracts-master/contracts/utils/Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// File: localhost/openzeppelin-contracts-master/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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

// File: localhost/openzeppelin-contracts-master/contracts/token/BEP721/IBEP721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an BEP721 compliant contract.
 */
interface IoldNFT {
    
    function tokens(address _fnftowner, uint8 _page, uint8 _rows)  external view returns(uint256[] memory);
    
     function transferFrom(address from, address to, uint256 tokenId) external;
     
     
}
 
 
interface IBEP721 is IBEP165 {
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
     * are aware of the BEP721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
      * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    
}

// File: localhost/openzeppelin-contracts-master/contracts/token/BEP721/extensions/IBEP721Enumerable.sol



pragma solidity ^0.8.0;


/**
 * @title BEP-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IBEP721Enumerable is IBEP721 {

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

// File: localhost/openzeppelin-contracts-master/contracts/token/BEP721/extensions/IBEP721Metadata.sol



pragma solidity ^0.8.0;


/**
 * @title BEP-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IBEP721Metadata is IBEP721 {

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

// File: localhost/openzeppelin-contracts-master/contracts/token/BEP721/IBEP721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title BEP721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from BEP721 asset contracts.
 */
interface IBEP721Receiver {
    /**
     * @dev Whenever an {IBEP721} `tokenId` token is transferred to this contract via {IBEP721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IBEP721.onBEP721Received.selector`.
     */
    function onBEP721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}



// File: localhost/openzeppelin-contracts-master/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: localhost/openzeppelin-contracts-master/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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
    constructor () {
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

// File: localhost/openzeppelin-contracts-master/contracts/token/BEP721/BEP721.sol



pragma solidity ^0.8.0;










/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[BEP721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {BEP721Enumerable}.
 */
contract BEP721 is Context, BEP165, IBEP721, IBEP721Metadata,Initializable {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
     
     function initialize(string memory name_, string memory symbol_) internal initializer {
        
          _name = name_;
        _symbol = symbol_;
     }
     
     
   

    /**
     * @dev See {IBEP165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BEP165, IBEP165) returns (bool) {
        return interfaceId == type(IBEP721).interfaceId
            || interfaceId == type(IBEP721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IBEP721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "BEP721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IBEP721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "BEP721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IBEP721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IBEP721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IBEP721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "BEP721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IBEP721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = BEP721.ownerOf(tokenId);
        require(to != owner, "BEP721: approval to current owner");

        require(_msgSender() == owner || BEP721.isApprovedForAll(owner, _msgSender()),
            "BEP721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IBEP721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "BEP721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IBEP721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "BEP721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IBEP721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IBEP721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "BEP721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IBEP721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IBEP721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "BEP721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the BEP721 protocol to prevent tokens from being forever locked.
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
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnBEP721Received(from, to, tokenId, _data), "BEP721: transfer to non BEP721Receiver implementer");
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
        require(_exists(tokenId), "BEP721: operator query for nonexistent token");
        address owner = BEP721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || BEP721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-BEP721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IBEP721Receiver-onBEP721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnBEP721Received(address(0), to, tokenId, _data), "BEP721: transfer to non BEP721Receiver implementer");
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
        require(to != address(0), "BEP721: mint to the zero address");
        require(!_exists(tokenId), "BEP721: token already minted");

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
        address owner = BEP721.ownerOf(tokenId);

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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(BEP721.ownerOf(tokenId) == from, "BEP721: transfer of token that is not own");
        require(to != address(0), "BEP721: transfer to the zero address");

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
        emit Approval(BEP721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IBEP721Receiver-onBEP721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnBEP721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IBEP721Receiver(to).onBEP721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IBEP721Receiver(to).onBEP721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("BEP721: transfer to non BEP721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// File: localhost/openzeppelin-contracts-master/contracts/token/BEP721/extensions/BEP721Enumerable.sol



pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {BEP721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract BEP721Enumerable is BEP721, IBEP721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IBEP165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IBEP165, BEP721) returns (bool) {
        return interfaceId == type(IBEP721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IBEP721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < BEP721.balanceOf(owner), "BEP721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IBEP721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IBEP721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < BEP721Enumerable.totalSupply(), "BEP721Enumerable: global index out of bounds");
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
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
        uint256 length = BEP721.balanceOf(to);
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

        uint256 lastTokenIndex = BEP721.balanceOf(from) - 1;
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



// File: localhost/openzeppelin-contracts-master/contracts/token/BEP721/PNFT.sol



pragma solidity ^0.8.0;





interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
    
     function mint(address to, uint256 value) external  returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }
    
   

    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

    function renounceMinter(address account) public  onlyOwner{
        _removeMinter(account);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract FoxyNFTv2 is  BEP721Enumerable ,MinterRole{
    using SafeMath for uint256;
     using SafeBEP20 for IBEP20;
    using Counters for Counters.Counter;
    
    IBEP20 public FoxyToken = IBEP20(address(0));
  address private  _owner;
    
 function initialize() public initializer {
     
 address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
  
        
BEP721.initialize("Foxy NFT","FNFT");

adoptprice=100e9;
burntoken=8000; //80% token burn for feed and adopt

lottery =1000;// 10% for treasure battle arena
devfee = 1000;// 10% devfee
buyback=10000;
_baseTokenURI="https://api.foxynft.org/pet.php?id=";
devaddr= _msgSender();  
burnaddr=0x000000000000000000000000000000000000dEaD;
lotteryaddr=address(0);
buybackaddr=address(0);
oldFNFT;
nonce=0;
image=11;
conrewd=3;
cons =100;
specialid=1000;
         
          PetView[_tokenIdTracker.current()] = Adobepets({
            id: _tokenIdTracker.current(),
            Petlevel:1,
            PetXP:0,
            PetDeath:32503726800,
            PetStaminatime:32503726800,
            PetRarity:999,
            Petshield:32503726800,
            PetStamina:0,
            PetIntelligence:999,
            PetHP:999,
            PetAttack:999,
            PetIMG:999,
            BattleWin:0,
            BattleLose:0
        });
        
        uint256 TokenID= _tokenIdTracker.current();
        _mint(msg.sender,TokenID);
        _tokenIdTracker.increment();
        
     
 }
 
    function owner() public view override virtual returns (address) {
        return _owner;
    } 
   function setFoxy(address _Foxytokenaddr) public onlyOwner {
        
        FoxyToken = IBEP20(_Foxytokenaddr);
    }
    
     function setConLVL(uint _cons) public onlyOwner {
 
        cons=_cons;
        
    }
    
    function setConrwd(uint _conrewd) public onlyOwner {
        
        conrewd = _conrewd;
        
    }
    function setConchance(uint _conchchance) public onlyOwner {
        
        conchance = _conchchance;
      
    }
    
    function setIMG(uint _image) public onlyOwner {
        
        image=_image;
        
    }
    
function SetGameprice(uint256 _burntoken,uint256  _lottery,uint256 _devfee) public onlyOwner {

burntoken=_burntoken; //80% token burn for feed and adopt
lottery =_lottery;// 10% for treasure battle arena
devfee = _devfee;// 10% devfee
    
}

function Setadoptprice(uint256 _adobptprice) public onlyOwner {
    
adoptprice=_adobptprice;
}

function Setbuyback(uint256 _buyback) public onlyOwner {
    
buyback=_buyback;
}

function autoadoptprice() public view returns(uint256) {
    
    uint256 totalpet=totalSupply();
    uint256 autoadopt=(totalpet.mul(adoptprice).div(10000)).mul(1e9);
return(autoadopt);
}

function setAddress(address _burnaddr,address _devaddr,address _lotteryaddr,address _buybackaddr, IoldNFT oldFNFT_) public onlyOwner {
    
devaddr= _devaddr;  
lotteryaddr=_lotteryaddr;
oldFNFT=oldFNFT_;
buybackaddr=_buybackaddr;
burnaddr=_burnaddr;
}

   function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI=baseURI;
    }

function editFood(uint _idfood,IBEP20 _tokenaddr,uint _foodCost,uint _foodlife,uint _foodxp) public onlyOwner {
         FoodView[_idfood] = Foods({
            id: _idfood,
            tokenaddress: _tokenaddr,
            foodcost:_foodCost,
            foodxp:_foodxp,
            foodlife:_foodlife
            
        });
    }
    
     string private _baseTokenURI="https://api.foxynft.org/pettest.php?id=";
     Counters.Counter private _tokenIdTracker;
   
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
  

   

 uint nonce=0;
 uint public image=2;
 function random() internal returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % image;
    randomnumber = randomnumber;
    nonce++;
    return randomnumber;
}

function diceplayer(uint _petchance) internal returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 10000;
    randomnumber = randomnumber+_petchance;
    nonce++;
    return randomnumber;
}

function dicebot() internal returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 10000;
    randomnumber = randomnumber+1;
    nonce++;
    return randomnumber;
}

function randomIntl() internal returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 99;
    randomnumber = randomnumber+1;
    nonce++;
    return randomnumber;
}

function randomattack() internal returns (uint) {
    uint autorandom = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 2;
    autorandom = autorandom+1;
    nonce++;
    return autorandom;
}


    
   struct Foods {
        uint id;
        IBEP20 tokenaddress;
        uint256 foodcost;
        uint foodxp;
        uint foodlife;
       
    } 
    
    struct Extradata {
        uint BreedCount;
        uint256 LastBreedtime;
        uint ATKequip;
        uint Parentid1;
        uint Parentid2;
        
    } 

 struct Adobepets {
        uint id;
        uint Petlevel;
        uint256 PetXP;
        uint PetDeath;
        uint256 PetStaminatime;
        uint PetRarity;
        uint256 Petshield;
        uint256 PetStamina;
        uint PetIntelligence;
        uint256 PetHP;
        uint256 PetAttack;
        uint256 PetIMG;
        uint256 BattleWin;
        uint256 BattleLose;
        
    }
    
    mapping (uint => Adobepets) public PetView;
    mapping (uint => Extradata) public Petextra;
    
    mapping (uint => Foods) public FoodView;
    mapping(address => uint) public KillCount;
   uint256[] private _allTokens;
    
    


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


    
    
   
uint256 public adoptprice;
uint256 public burntoken;
uint256 public lottery;
uint256 public devfee;
uint256 public buyback;
address public devaddr;
address public burnaddr;
address public lotteryaddr;
address public buybackaddr;

IoldNFT public  oldFNFT;

 uint256 public specialid;



//event here

event ETreasure(address treasure_,address ownerclaim,uint256 totalclaim);
event EClaim(address ownerclaim,uint256 totalclaim);
event Ekill(address killer,uint256 petidkill,uint256 petidpoint);
event Efeed(address ownerpet,uint256 petid,uint256 feedid);
event Eadopt(address ownerpet,uint256 petid);
event battleresult(uint256 diceattacker,uint256 dicetarget,string pveresult,uint256 pvereward,uint256 exp);




function PoolMint() public onlyMinter{
 
         PetView[_tokenIdTracker.current()] = Adobepets({
            id: _tokenIdTracker.current(),
            Petlevel:1,
            PetXP:100,
            PetDeath:block.timestamp+172800,
            PetStaminatime:block.timestamp,
            PetRarity:intelrarity(),
            Petshield:block.timestamp+172800,
            PetStamina:200,
            PetIntelligence:intelrarity(),
            PetHP:14,
            PetAttack:6,
            PetIMG:random(),
            BattleWin:0,
            BattleLose:0
        });
        
        uint256 TokenID= _tokenIdTracker.current();
        _mint(msg.sender,TokenID);
        _tokenIdTracker.increment();
        
        emit Eadopt(msg.sender,TokenID);
        
    } 
    
    function Specialadopt() public onlyMinter{
 
        PetView[_tokenIdTracker.current()] = Adobepets({
            id: _tokenIdTracker.current(),
            Petlevel:1,
            PetXP:100,
            PetDeath:block.timestamp+172800,
            PetStaminatime:block.timestamp,
            PetRarity:intelrarity(),
            Petshield:block.timestamp+172800,
            PetStamina:200,
            PetIntelligence:intelrarity(),
            PetHP:14,
            PetAttack:6,
            PetIMG:specialid,
            BattleWin:0,
            BattleLose:0
        });
        
        uint256 TokenID= _tokenIdTracker.current();
        _mint(msg.sender,TokenID);
        _tokenIdTracker.increment();
        
        emit Eadopt(msg.sender,TokenID);
        
    } 
 
bool public battle = false;
bool public nftgame = false;
bool public adoptedpauset = false;

modifier BattlePaused() {
        require(!battle, "Battle Paused!!");
        _;
    }
    
    modifier Gamepaused() {
        require(!nftgame, "Foxy NFT Game Paused!!!");
        _;
    }
    
     modifier Adoptpaused() {
        require(!adoptedpauset, "Adobpt Closed!!!");
        _;
    }
    
    
function Battlepaused(bool _battle) public onlyOwner {
        battle = _battle;
    }
    
    function Gameplay(bool _nftgame) public onlyOwner {
        nftgame = _nftgame;
    }
    
    function PauseAdopt(bool _nftadobe) public onlyOwner {
        adoptedpauset = _nftadobe;
    }
    
    function SpecialIDNFT(uint256 _specialid) public onlyOwner {
       specialid = _specialid;
    }
    



    
    



    
function AdoptPet() public Adoptpaused {
     require(tx.origin == msg.sender,"Caller Only non contract");
    
 uint256  priceautoadopt=autoadoptprice();    
 uint256   forburn = priceautoadopt.mul(burntoken).div(10000); 
 uint256   forlottery = priceautoadopt.mul(lottery).div(10000); 
 uint256   fordev = priceautoadopt.mul(devfee).div(10000); 
        
    FoxyToken.safeTransferFrom(msg.sender, burnaddr,forburn);
    FoxyToken.safeTransferFrom(msg.sender, lotteryaddr,forlottery);
    FoxyToken.safeTransferFrom(msg.sender, devaddr,fordev);

     
        PetView[_tokenIdTracker.current()] = Adobepets({
            id: _tokenIdTracker.current(),
            Petlevel:1,
            PetXP:100,
            PetDeath:block.timestamp+172800,
            PetStaminatime:block.timestamp,
            PetRarity:intelrarity(),
            Petshield:block.timestamp+172800,
            PetStamina:200,
            PetIntelligence:intelrarity(),
            PetHP:14,
            PetAttack:6,
            PetIMG:random(),
            BattleWin:0,
            BattleLose:0
        });
        
        uint256 TokenID= _tokenIdTracker.current();
        _mint(msg.sender,TokenID);
        _tokenIdTracker.increment();
        
        emit Eadopt(msg.sender,TokenID);
        
    } 
    
    
    
    uint public conrewd;
    uint public cons;
    uint public conchance;
    
    function _CalcLVL(uint _petid) private {
 
      uint petxps= PetView[ _petid].PetXP;
         //Petlevel using squaremetod
uint levelup = sqrt(petxps.div(cons)); 
      PetView[_petid].Petlevel=levelup;
        
         
    }
    
     function CalcReward(uint _petid) public view returns(uint256) {
 
uint256 petlvl=PetView[_petid].Petlevel;
uint256 petrary=PetView[_petid].PetRarity;
uint256 petint=PetView[_petid].PetIntelligence;
uint256 petreward=sqrt(petlvl.mul(petrary).mul(petint));
uint256 finalreward=petreward.mul(1e9).div(conrewd);

return(finalreward);
       
        
    }
    
     

    
function feedPet(uint _idfood,uint _petid) public Gamepaused {
 require(_isApprovedOrOwner(_msgSender(), _petid), "BEP721: transfer caller is not owner nor approved");
      //send token here
  uint256 feedcosts= FoodView[_idfood].foodcost;
  IBEP20 FeedToken= FoodView[_idfood].tokenaddress;
  uint256 feedxp=FoodView[_idfood].foodxp;
   uint256 feedtime=FoodView[_idfood].foodlife;
  
  
  
   uint petxps= PetView[ _petid].PetXP.add(feedxp);
   PetView[ _petid].PetDeath=block.timestamp.add(feedtime);
   PetView[ _petid].PetXP=petxps;
  
  if(FeedToken==FoxyToken){
      
 
  uint256   foxycost=feedcosts; 
  
 uint256   forburn = foxycost.mul(burntoken).div(10000); 
 uint256   forlottery = foxycost.mul(lottery).div(10000); 
 uint256   fordev = foxycost.mul(devfee).div(10000); 
 FeedToken.transferFrom(msg.sender, burnaddr,forburn);
 FeedToken.transferFrom(msg.sender, lotteryaddr,forlottery);
 FeedToken.transferFrom(msg.sender, devaddr,fordev);
    
   
  }else {
      
      
       uint256   forbuyback=feedcosts.mul(buyback).div(10000);
        
         FeedToken.transferFrom(msg.sender, buybackaddr,forbuyback);
         

      
  }    
     _CalcLVL(_petid);   
emit Efeed(msg.sender,_petid,_idfood);
 
    }
    
 function feedAll(uint256[] calldata ids,uint256 _idfood) public  {
     
     for (uint256 i = 0; i < ids.length; i++) {
         
         feedPet(_idfood,ids[i]);
         
     }
     
 }
 
 
 
    function KillPets(uint256 PetKill) public onlyOwner Gamepaused{
        
  PetView[PetKill].PetXP=100;
  PetView[PetKill].Petlevel=1;
      

    }
    
    function PVEchance(uint _petid) public view returns(uint256){
         uint chancefac=conchance;
         uint petLVL=PetView[_petid].Petlevel;
         uint petInt = PetView[_petid].PetIntelligence;
         uint petRari = PetView[_petid].PetRarity;
         
         
         uint petchannumber=chancefac.mul(petLVL).mul(petInt).mul(petRari);
         uint petchancewin=sqrt(petchannumber);
         
         return(petchancewin);
        
        
    }
    
    function PVPbattle(uint _petid,uint _petartget) public  Gamepaused BattlePaused {
        require(_isApprovedOrOwner(_msgSender(), _petid), "BEP721: transfer caller is not owner nor approved");
       uint256 laststamina= PetView[_petid].PetStamina;
       uint256 Targetlvl= PetView[_petartget].Petlevel;
       uint256 maxlvl= PetView[_petid].Petlevel.add(3);
        require(laststamina  >= 50,"You can't Battle need 50 stamina");
        require(_petid  != _petartget,"You can't same pet");
        require(Targetlvl  <= maxlvl,"Can't attack more than 3 lvl up form your pet");
        require(tx.origin == msg.sender,"Caller Only non contract");
         require(PetView[_petid].PetDeath < block.timestamp,"Can't Battle Feed your pet!!");
        
       PetView[_petid].PetStamina=laststamina.sub(50);
       uint petchance=PVEchance(_petid);
       uint targetchance=PVEchance(_petartget);
       uint dicepet=diceplayer(petchance);
       uint dicetarget=diceplayer(targetchance);
       uint256 pvereward=CalcReward(_petartget);
       string memory pveresult;
       uint256 xpbonus= PetView[_petartget].PetIntelligence.mul(10);
        uint256  beforexp=PetView[_petid].PetXP;
    PetView[_petid].PetXP=beforexp.add(xpbonus);
  
  _CalcLVL(_petid);
       
       
       
       if(dicepet>dicetarget){
           pveresult="win";
            IBEP20(FoxyToken).mint(msg.sender,pvereward);
          
       }else{
            pveresult="lost";
       
       }
      emit battleresult(dicepet,dicetarget,pveresult,pvereward,xpbonus);
    }
    
    function PVEbattle(uint _petid) public  Gamepaused BattlePaused {
        require(_isApprovedOrOwner(_msgSender(), _petid), "BEP721: transfer caller is not owner nor approved");
        uint256 laststamina= PetView[_petid].PetStamina;
        require(laststamina  >= 40,"Not enough stamina");
        require(tx.origin == msg.sender,"Caller Only non contract");
         require(PetView[_petid].PetDeath < block.timestamp,"Can't Battle Feed your pet!!");
        
       PetView[_petid].PetStamina=laststamina.sub(40);
      
       uint petchance=PVEchance(_petid);
       uint botdice=dicebot();
       uint dicepet=diceplayer(petchance);
       uint256 pvereward=CalcReward(_petid);
       string memory pveresult;
       uint256 xpbonus= PetView[_petid].PetIntelligence.mul(10);
        uint256  beforexp=PetView[_petid].PetXP;
    PetView[_petid].PetXP=beforexp.add(xpbonus);
    
      _CalcLVL(_petid);
       
       if(dicepet>botdice){
           pveresult="win";
           IBEP20(FoxyToken).mint(msg.sender,pvereward);
           
       }else{
            pveresult="lost";
       
       }
       
       emit battleresult(dicepet,botdice,pveresult,pvereward,xpbonus);
    }


    
function LastPets() public view returns(uint){
    
    return _tokenIdTracker.current();
}

function dieNFT(uint256 _petid) public view returns(uint){
    
    return PetView[_petid].PetDeath;
}

uint256 public staminaprice;
function setStaminaprice(uint256 _staminaprice) public onlyOwner{
    
     staminaprice=_staminaprice; 
    

}
uint256 public xpprice;
function setxpprice(uint256 _xpprice) public onlyOwner{
    
     xpprice=_xpprice; 
    

}
uint256 public petxpget;
function setxget(uint256 _xpget) public onlyOwner{
    
     petxpget=_xpget; 
    

}

function buystamina(uint _petid) public Gamepaused{
     require(_isApprovedOrOwner(_msgSender(), _petid), "BEP721: transfer caller is not owner nor approved");
    require(block.timestamp  > PetView[_petid].PetStaminatime,"You can't Buy Stamina");
    
    uint256 staminafee=staminaprice.mul(1e9); 
    
    FoxyToken.safeTransferFrom(msg.sender, burnaddr,staminafee);
    PetView[_petid].PetStaminatime=block.timestamp+86400;
    PetView[_petid].PetStamina=200;
   
}


function buyexp(uint _petid) public Gamepaused{
    require(_isApprovedOrOwner(_msgSender(), _petid), "BEP721: transfer caller is not owner nor approved");
    
    uint256 xpfee=xpprice.mul(1e9); 
    
    FoxyToken.safeTransferFrom(msg.sender, burnaddr,xpfee);
  uint256  beforexp=PetView[_petid].PetXP;
    PetView[_petid].PetXP=beforexp.add(petxpget);
  
  _CalcLVL(_petid);
   
}

function buystaminaAll(uint256[] calldata ids) public  {
     
     for (uint256 i = 0; i < ids.length; i++) {
         
         buystamina(ids[i]);
     }
     
 }



function viewBaseURI() public view returns(string memory){
    return _baseURI();
}



function intelrarity() private returns(uint256) {
    
    uint256 chance=randomIntl();
    uint256  petchance;
    if(chance<=10){
     petchance=4;
    }else  if(chance<=30){
        
        petchance=3;
        
    }else  if(chance<=60){
        
       petchance=2;
        
    }else {
        petchance=1;
    }
    
    return(petchance);
    
}

function Breeding(uint256 parentid1,uint256 parentid2) public {
    
   uint256 Bcount1= Petextra[parentid1].BreedCount;
   uint256 Bcount2= Petextra[parentid2].BreedCount;
   require(Bcount1<=1,"Need BreedCount less than 2");
   require(Bcount2<=1,"Need BreedCount less than 2");
   require(parentid1!=parentid2,"Can't Breed Same pet");
   require(_isApprovedOrOwner(_msgSender(), parentid1), "BEP721: Breed caller is not owner nor approved");
   require(_isApprovedOrOwner(_msgSender(), parentid2), "BEP721: Breed caller is not owner nor approved");
   
  
    
    uint256 intelparient1=PetView[parentid1].PetIntelligence;
    uint256 intelparient2=PetView[parentid2].PetIntelligence;
    uint256 rarityparient1=PetView[parentid1].PetRarity;
    uint256 rarityparient2=PetView[parentid2].PetRarity;
    
     uint256 totalintel=(intelparient1+intelparient2).mul(100).mul(5000).div(10000);
     uint256 costbreed=totalintel.mul(1e9);
     
      FoxyToken.safeTransferFrom(msg.sender, burnaddr,costbreed);
    
     uint256 chance=randomIntl();
     uint256  petintelparent;
     uint256  petrarityparent;
    if(chance<=50){
    
     petintelparent=intelparient1;
     
    }else{
        
        petintelparent=intelparient2;
        
    }
    
      if(chance<=20){
    
     petrarityparent=rarityparient1;
     
    }else  if(chance<=40){
        
        petrarityparent=rarityparient2;
        
    }else  if(chance<=70){
        
        petrarityparent=2;
        
    }else{
        
        petrarityparent=1;
        
    }
    
    Petextra[parentid1].BreedCount=Bcount1.add(1);
    Petextra[parentid2].BreedCount=Bcount2.add(1);
    
    PetView[_tokenIdTracker.current()] = Adobepets({
            id: _tokenIdTracker.current(),
            Petlevel:1,
            PetXP:100,
            PetDeath:block.timestamp+172800,
            PetStaminatime:block.timestamp,
            PetRarity:petrarityparent,
            Petshield:block.timestamp+172800,
            PetStamina:200,
            PetIntelligence:petintelparent,
            PetHP:14,
            PetAttack:6,
            PetIMG:random(),
            BattleWin:0,
            BattleLose:0
        });
        
        uint256 TokenID= _tokenIdTracker.current();
        
        Petextra[TokenID].Parentid1=parentid1;
        Petextra[TokenID].Parentid2=parentid2;
        
        _mint(msg.sender,TokenID);
        _tokenIdTracker.increment();
        
        emit Eadopt(msg.sender,TokenID);
    
    
}


function battleready(uint256 _filterlvl,uint256 _filterint,uint256 _filterary) public view returns(uint256[] memory ) {
    
   uint256 _tokenCount = LastPets();
    uint256[] memory petTemp = new uint256[](_tokenCount);
    uint count;
    for (uint256 i = 1; i < _tokenCount; i++) {
        
        if(PetView[i].Petlevel ==_filterlvl && PetView[i].PetIntelligence == _filterint  && PetView[i].PetRarity  == _filterary){
            
             petTemp[count]  = PetView[i].id;
             count += 1;
            
        } 
      
    }
uint256[] memory filterhp0 = new uint256[](count);
    for(uint i = 0; i<count; i++){
      filterhp0[i] = petTemp[i];
    }
    return filterhp0;
}

function allnft(uint256 _Petlevel) public view returns(uint256[] memory ) {
    
   uint256 _tokenCount = LastPets();
    uint256[] memory petTemp = new uint256[](_tokenCount);
    uint count;
    for (uint256 i = 1; i < _tokenCount; i++) {
        
       
            if(PetView[i].Petlevel !=_Petlevel){
            
             petTemp[count]  = PetView[i].id;
             count += 1;
            
        }
      
    }
uint256[] memory filterhp0 = new uint256[](count);
    for(uint i = 0; i<count; i++){
      filterhp0[i] = petTemp[i];
    }
    return filterhp0;
}



 
 
 function tokens(address _fnftowner, uint8 _page, uint8 _rows) public view returns(uint256[] memory) {
    require(_page > 0, "_page should be greater than 0");
    require(_rows > 0, "_rows should be greater than 0");

    uint256 _tokenCount = balanceOf(_fnftowner);
    uint256 _offset = (_page - 1) * _rows;
    uint256 _range = _offset > _tokenCount ? 0 : min(_tokenCount - _offset, _rows);

    uint256[] memory _tokens = new uint256[](_range);
    for (uint256 i = 0; i < _range; i++) {
        _tokens[i] = tokenOfOwnerByIndex(_fnftowner, _offset + i);
    }
    return _tokens;
}

function min(uint256 a, uint256 b) private pure returns (uint256) {
    return a > b ? b : a;
}
  
}