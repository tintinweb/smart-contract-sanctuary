/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// Sources flattened with hardhat v2.0.3 https://hardhat.org

// File @openzeppelin/contracts/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


// File @openzeppelin/contracts/GSN/[email protected]

pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts/introspection/[email protected]

pragma solidity ^0.6.0;

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


// File @openzeppelin/contracts/introspection/[email protected]

pragma solidity ^0.6.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
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
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Multi Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    event URI(
        string _value,
        uint256 indexed _id
    );

    /**
     * @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if balance of holder for token `id` is lower than the `value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param from    Source address
     * @param to      Target address
     * @param id      ID of the token type
     * @param value   Transfer amount
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if length of `ids` is not the same as length of `values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param from    Source address
     * @param to      Target address
     * @param ids     IDs of each token type (order and length must match _values array)
     * @param values  Transfer amounts per token type (order and length must match _ids array)
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * @notice Get the balance of an account's tokens.
     * @param owner  The address of the token holder
     * @param id     ID of the token
     * @return       The _owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param owners The addresses of the token holders
     * @param ids    ID of the tokens
     * @return       The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     * @dev MUST emit the ApprovalForAll event on success.
     * @param operator Address to add to the set of authorized operators
     * @param approved True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner.
     * @param owner     The owner of the tokens
     * @param operator  Address of authorized operator
     * @return          True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Multi Token Standard, optional metadata URI extension
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Note: The ERC-165 identifier for this interface is 0x0e89341c.
 */
interface IERC1155MetadataURI {
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * The uri function SHOULD be used to retrieve values if no event was emitted.
     * The uri function MUST return the same value as the latest event for an _id if it was emitted.
     * The uri function MUST NOT be used to check for the existence of a token as it is possible for an implementation to return a valid string even if the token does not exist.
     * @return URI string
     */
    function uri(uint256 id) external view returns (string memory);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;


/**
 * @title ERC-1155 Multi Token Standard, optional Asset Collections extension
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * Interface for fungible/non-fungible collections management on a 1155-compliant contract.
 * This proposal attempts to rationalize the co-existence of fungible and non-fungible tokens
 * within the same contract. We consider that there 3 types of identifiers:
 * (a) Fungible Collections identifiers, each representing a set of Fungible Tokens,
 * (b) Non-Fungible Collections identifiers, each representing a set of Non-Fungible Tokens,
 * (c) Non-Fungible Tokens identifiers. 

 * Identifiers nature
 * |       Type                | isFungible  | isCollection | isToken |
 * |  Fungible Collection      |   true      |     true     |  true   |
 * |  Non-Fungible Collection  |   false     |     true     |  false  |
 * |  Non-Fungible Token       |   false     |     false    |  true   |
 *
 * Identifiers capabilities
 * |       Type                |  transfer  |   balance    |   supply    |  owner  |
 * |  Fungible Collection      |    OK      |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Collection  |    NOK     |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Token       |    OK      |   0 or 1     |   0 or 1    |   OK    |
 *
 * Note: The ERC-165 identifier for this interface is 0x469bd23f.
 */
interface IERC1155Inventory {

    /**
     * Optional event emitted when a collection is created.
     *  This event SHOULD NOT be emitted twice for the same `collectionId`.
     * 
     *  The parameters in the functions `collectionOf` and `ownerOf` are required to be
     *  non-fungible token identifiers, so they should not be called with any collection
     *  identifiers, else they will revert.
     * 
     *  On the contrary, the functions `balanceOf`, `balanceOfBatch` and `totalSupply` are
     *  best used with collection identifiers, which will return meaningful information for
     *  the owner.
     */
    event CollectionCreated (uint256 indexed collectionId, bool indexed fungible);

    /**
     * Retrieves the owner of a non-fungible token.
     * @dev Reverts if `nftId` is owned by the zero address. // ERC721 compatibility
     * @dev Reverts if `nftId` does not represent a non-fungible token.
     * @param nftId The token identifier to query.
     * @return Address of the current owner of the token.
     */
    function ownerOf(uint256 nftId) external view returns (address);

    /**
     * Retrieves the total supply of `id`.
     *  If `id` represents a fungible or non-fungible collection, returns the supply of tokens for this collection.
     *  If `id` represents a non-fungible token, returns 1 if the token exists, else 0.
     * @param id The identifier for which to retrieve the supply of.
     * @return The supplies for each identifier in `ids`.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * Introspects whether or not `id` represents a fungible collection.
     *  This function MUST return true even for a fungible collections which is not-yet created.
     * @param id The identifier to query.
     * @return bool True if `id` represents a fungible collection, false otherwise.
     */
    function isFungible(uint256 id) external pure returns (bool);

    /**
     * Introspects the non-fungible collection to which `nftId` belongs.
     *  This function MUST return a value representing a non-fungible collection.
     *  This function MUST return a value for a non-existing token, and SHOULD NOT be used to check the existence of a non-fungible token.
     * @dev Reverts if `nftId` does not represent a non-fungible token.
     * @param nftId The token identifier to query the collection of.
     * @return uint256 the non-fungible collection identifier to which `nftId` belongs.
     */
    function collectionOf(uint256 nftId) external pure returns (uint256);

    /**
     * @notice this definition replaces the original {ERC1155-balanceOf}.
     * Retrieves the balance of `id` owned by account `owner`.
     *  If `id` represents a fungible or non-fungible collection, returns the balance of tokens for this collection.
     *  If `id` represents a non-fungible token, returns 1 if the token is owned by `owner`, else 0.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return The balance of `id` owned by account `owner`.
     */
    // function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * @notice this definition replaces the original {ERC1155-balanceOfBatch}.
     * Retrieves the balances of `ids` owned by accounts `owners`. For each pair:
     *  if `id` represents a fungible or non-fungible collection, returns the balance of tokens for this collection,
     *  if `id` represents a non-fungible token, returns 1 if the token is owned by `owner`, else 0.
     * @param owners The addresses of the token holders
     * @param ids The identifiers to retrieve the balance of.
     * @return The balances of `ids` owned by accounts `owners`.
     */
    // function balanceOfBatch(
    //     address[] calldata owners,
    //     uint256[] calldata ids
    // ) external view returns (uint256[] memory);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC-1155 Multi Token Standard, token receiver
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * Interface for any contract that wants to support transfers from ERC1155 asset contracts.
 * Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {

    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
     * This function MUST revert if it rejects the transfer.
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
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
     * This function MUST revert if it rejects the transfer(s).
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


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC1155/[email protected]

pragma solidity 0.6.8;








/**
 * @title ERC1155Inventory, a contract which manages up to multiple Collections of Fungible and Non-Fungible Tokens
 * @dev In this implementation, with N representing the Non-Fungible Collection mask length, identifiers can represent either:
 * (a) a Fungible Collection:
 *     - most significant bit == 0
 * (b) a Non-Fungible Collection:
 *     - most significant bit == 1
 *     - (256-N) least significant bits == 0
 * (c) a Non-Fungible Token:
 *     - most significant bit == 1
 *     - (256-N) least significant bits != 0
 * with N = 32.
 * 
 */
abstract contract ERC1155Inventory is IERC1155, IERC1155MetadataURI, IERC1155Inventory, ERC165, Context {
    using Address for address;
    using SafeMath for uint256;

    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // Burnt non-fungible token owner's magic value
    uint256 internal constant _BURNT_NFT_OWNER = 1 << 255;

    // Non-fungible bit. If an id has this bit set, it is a non-fungible (either collection or token)
    uint256 internal constant _NF_BIT = 1 << 255;

    // Mask for non-fungible collection (including the nf bit)
    uint256 internal constant _NF_COLLECTION_MASK = uint256(type(uint32).max) << 224;
    uint256 internal constant _NF_TOKEN_MASK = ~_NF_COLLECTION_MASK;

    mapping(address => mapping(address => bool)) internal _operators;
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(uint256 => uint256) internal _supplies;
    mapping(uint256 => uint256) internal _owners;
    mapping(uint256 => address) public creator;

    /**
     * @dev Constructor function
     */
    constructor() internal {
        _registerInterface(type(IERC1155).interfaceId);
        _registerInterface(type(IERC1155MetadataURI).interfaceId);
        _registerInterface(type(IERC1155Inventory).interfaceId);
    }


    //================================== ERC1155 =======================================/

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        _safeTransferFrom(from, to, id, value, data, false);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    function sameNFTCollectionSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory nftIds,
        bytes memory data
    ) public virtual {
        _sameNFTCollectionSafeBatchTransferFrom(from, to, nftIds, data);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     */
    function balanceOf(address owner, uint256 id) public virtual override view returns (uint256) {
        require(owner != address(0), "Inventory: zero address");

        if (isNFT(id)) {
            return _owners[id] == uint256(owner) ? 1 : 0;
        }

        return _balances[id][owner];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     */
    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        virtual
        override
        view
        returns (uint256[] memory)
    {
        require(owners.length == ids.length, "Inventory: inconsistent arrays");

        uint256[] memory balances = new uint256[](owners.length);

        for (uint256 i = 0; i < owners.length; ++i) {
            require(owners[i] != address(0), "Inventory: zero address");

            uint256 id = ids[i];

            if (isNFT(id)) {
                balances[i] = _owners[id] == uint256(owners[i]) ? 1 : 0;
            } else {
                balances[i] = _balances[id][owners[i]];
            }
        }

        return balances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address sender = _msgSender();
        require(operator != sender, "Inventory: self-approval");
        _operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address tokenOwner, address operator) public virtual override view returns (bool) {
        return _operators[tokenOwner][operator];
    }


    //================================== ERC1155MetadataURI =======================================/

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 id) external virtual override view returns (string memory) {
        return _uri(id);
    }


    //================================== ERC1155Inventory  =======================================/

    /**
     * @dev See {IERC1155AssetCollections-isFungible}.
     */
    function isFungible(uint256 id) public virtual override pure returns (bool) {
        return id & _NF_BIT == 0;
    }

    /**
     * @dev See {IERC1155AssetCollections-collectionOf}.
     */
    function collectionOf(uint256 nftId) public virtual override pure returns (uint256) {
        require(isNFT(nftId), "Inventory: not an NFT");
        return nftId & _NF_COLLECTION_MASK;
    }

    /**
     * @dev See {IERC1155AssetCollections-ownerOf}.
     */
    function ownerOf(uint256 nftId) public virtual override view returns (address) {
        address owner = address(_owners[nftId]);
        require(owner != address(0), "Inventory: non-existing NFT");
        return owner;
    }

    /**
     * @dev See {IERC1155AssetCollections-totalSupply}.
     */
    function totalSupply(uint256 id) public virtual override view returns (uint256) {
        if (isNFT(id)) {
            return address(_owners[id]) == address(0) ? 0 : 1;
        } else {
            return _supplies[id];
        }
    }

    //================================== ERC1155Inventory Non-standard helpers =======================================/

    /**
     * @dev Introspects whether an identifier represents an non-fungible token.
     * @param id Identifier to query.
     * @return True if `id` represents an non-fungible token.
     */
    function isNFT(uint256 id) public virtual pure returns (bool) {
        return (id & _NF_BIT) != 0 && (id & _NF_TOKEN_MASK != 0);
    }

    //================================== Metadata Internal =======================================/

    /**
     * @dev (abstract) Returns an URI for a given identifier.
     * @param id Identifier to query the URI of.
     * @return The metadata URI for `id`.
     */
    function _uri(uint256 id) internal virtual view returns (string memory);

    //================================== Inventory Collections Internal =======================================/

    /**
     * Creates a collection (optional).
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function _createCollection(uint256 collectionId) internal virtual {
        require(!isNFT(collectionId), "Inventory: not a collection");
        require(creator[collectionId] == address(0), "Inventory: existing collection");
        creator[collectionId] = _msgSender();
        emit CollectionCreated(collectionId, isFungible(collectionId));
    }

    //================================== Transfer Internal =======================================/

    /**
     * Transfers tokens to another address.
     * @dev Reverts if `isBatch` is false and `to` is the zero address.
     * @dev Reverts if `isBatch` is false the sender is not approved.
     * @dev Reverts if `id` represents a non-fungible collection.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token and is not owned by `from`.
     * @dev Reverts if `id` represents a fungible collection and `value` is 0.
     * @dev Reverts if `id` represents a fungible collection and `from` doesn't have enough balance.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to pass to the receiver contract.
     * @param isBatch Whether this function is called by `_safeBatchTransferFrom`.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool isBatch
    ) internal virtual {
        address sender;
        if (!isBatch) {
            require(to != address(0), "Inventory: transfer to zero");
            sender = _msgSender();
            bool operatable = (from == sender) || _operators[from][sender];
            require(operatable, "Inventory: non-approved sender");
        }

        uint256 collectionId;
        if (isFungible(id)) {
            require(value != 0, "Inventory: zero value");
            collectionId = id;
            _balances[collectionId][from] = _balances[collectionId][from].sub(value);
        } else if (id & _NF_TOKEN_MASK != 0) {
            require(value == 1, "Inventory: wrong NFT value");
            require(uint256(from) == _owners[id], "Inventory: non-owned NFT");
            _owners[id] = uint256(to);
            collectionId = id & _NF_COLLECTION_MASK;
            // cannot underflow as balance is verified through ownership
            _balances[collectionId][from] -= value;
        } else {
            revert("Inventory: not a token id");
        }

        // cannot overflow as supply cannot overflow
        _balances[collectionId][to] += value;

        if (!isBatch) {
            emit TransferSingle(sender, from, to, id, value);
            _callOnERC1155Received(from, to, id, value, data);
        }
    }

    /**
     * Transfers multiple tokens to another address
     * @dev Reverts if `ids` and `values` have inconsistent lengths.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` represents a non-fungible collection.
     * @dev Reverts if one of `ids` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token and is not owned by `from`.
     * @dev Reverts if one of `ids` represents a fungible collection and `value` is 0.
     * @dev Reverts if one of `ids` represents a fungible collection and `from` doesn't have enough balance.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: transfer to zero");
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");
        address sender = _msgSender();
        bool operatable = (from == sender) || _operators[from][sender];
        require(operatable, "Inventory: non-approved sender");

        bool isBatch = true;
        for (uint256 i = 0; i < length; i++) {
            _safeTransferFrom(from, to, ids[i], values[i], data, isBatch);
        }

        emit TransferBatch(sender, from, to, ids, values);
        _callOnERC1155BatchReceived(from, to, ids, values, data);
    }

    /**
     * @dev Transfers multiple non-fungible tokens belonging to the same collection.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `nftIds` does not represent a non-fungible token.
     * @dev Reverts if one of `nftIds` represents a non-fungible token which is not owned by `from`.
     * @dev Reverts if two of `nftIds` have a different collection.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param to Address of the new tokens owner.
     * @param nftIds Identifiers of the non-fungible tokens to mint.
     * @param data Optional data to send along to a receiver contract.
     */
    function _sameNFTCollectionSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory nftIds,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: transfer to zero");

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        address sender = _msgSender();
        bool operatable = (from == sender) || _operators[from][sender];
        require(operatable, "Inventory: non-approved sender");

        uint256 collectionId;
        for (uint256 i = 0; i < length; i++) {
            uint256 nftId = nftIds[i];
            require(isNFT(nftId), "Inventory: not an NFT");
            require(_owners[nftId] == uint256(from), "Inventory: non-owned NFT");
            _owners[nftId] = uint256(to);
            values[i] = 1;
            if (i == 0) {
                collectionId = nftId & _NF_COLLECTION_MASK;
            } else {
                require(collectionId == nftId & _NF_COLLECTION_MASK, "Inventory: not same collection");
            }
        }

        // cannot underflow as balance is verified through ownership
        _balances[collectionId][from] -= length;
        // cannot overflow as supply cannot overflow
        _balances[collectionId][to] += length;

        emit TransferBatch(sender, from, to, nftIds, values);
        _callOnERC1155BatchReceived(sender, to, nftIds, values, data);
    }


    //================================== Minting Internal =======================================/

    /**
     * Mints some token.
     * @dev Reverts if `isBatch` is false and `to` is the zero address.
     * @dev Reverts if `id` represents a non-fungible collection.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token which is owned by a non-zero address.
     * @dev Reverts if `id` represents a fungible collection and `value` is 0.
     * @dev Reverts if `id` represents a fungible collection and there is an overflow of supply.
     * @dev Reverts if `isBatch` is false, `safe` is true and the call to the receiver contract fails or is refused.
     * @dev Emits an {IERC1155-TransferSingle} event if `isBatch` is false.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to mint.
     * @param value Amount of token to mint.
     * @param data Optional data to send along to a receiver contract.
     * @param safe Whether to call the receiver contract.
     * @param isBatch Whether this function is called by `_batchMint`.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool safe,
        bool isBatch
    ) internal virtual {
        if (!isBatch) {
            require(to != address(0), "Inventory: transfer to zero");
        }

        uint256 collectionId;
        if (isFungible(id)) {
            require(value != 0, "Inventory: zero value");
            collectionId = id;
            _supplies[collectionId] = _supplies[collectionId].add(value);
        } else if (id & _NF_TOKEN_MASK != 0) {
            require(value == 1, "Inventory: wrong NFT value");
            require(_owners[id] == 0, "Inventory: existing/burnt NFT");

            _owners[id] = uint256(to);

            collectionId = id & _NF_COLLECTION_MASK;
            // it is virtually impossible that a non-fungible collection balance or supply
            // overflows due to the cost of minting unique tokens
            _supplies[collectionId] += value;
        } else {
            revert("Inventory: not a token id");
        }

        // cannot overflow as supply cannot overflow
        _balances[collectionId][to] += value;

        if (!isBatch) {
            emit TransferSingle(_msgSender(), address(0), to, id, value);

            if (safe) {
                _callOnERC1155Received(address(0), to, id, value, data);
            }
        }
    }

    /**
     * Mints a batch of tokens.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `ids` represents a non-fungible collection.
     * @dev Reverts if one of `ids` represents a non-fungible token and its paired value is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which is owned by a non-zero address.
     * @dev Reverts if one of `ids` represents a fungible collection and its paired value is 0.
     * @dev Reverts if one of `ids` represents a fungible collection and there is an overflow of supply.
     * @dev Reverts if `safe` is true and the call to the receiver contract fails or is refused.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to mint.
     * @param values Amounts of tokens to mint.
     * @param data Optional data to send along to a receiver contract.
     * @param safe Whether to call the receiver contract.
     */
    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data,
        bool safe
    ) internal virtual {
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        require(to != address(0), "Inventory: transfer to zero");

        bool isBatch = true;
        for (uint256 i = 0; i < length; i++) {
            _mint(to, ids[i], values[i], data, safe, isBatch);
        }

        emit TransferBatch(_msgSender(), address(0), to, ids, values);

        if (safe) {
            _callOnERC1155BatchReceived(address(0), to, ids, values, data);
        }
    }

    /**
     * Mints a batch of non-fungible tokens belonging to the same collection.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `nftIds` does not represent a non-fungible token.
     * @dev Reverts if one of `nftIds` represents a non-fungible token which is owned by a non-zero address.
     * @dev Reverts if two of `nftIds` have a different collection.
     * @dev Reverts if `safe` is true and the call to the receiver contract fails or is refused.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param to Address of the new tokens owner.
     * @param nftIds Identifiers of the tokens to mint.
     * @param data Optional data to send along to a receiver contract.
     * @param safe Whether to call the receiver contract.
     */
    function _sameNFTCollectionBatchMint(
        address to,
        uint256[] memory nftIds,
        bytes memory data,
        bool safe
    ) internal virtual {
        require(to != address(0), "Inventory: transfer to zero");
        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 collectionId;
        for (uint256 i = 0; i < length; i++) {
            uint256 nftId = nftIds[i];
            require(isNFT(nftId), "Inventory: not an NFT");
            require(_owners[nftId] == 0, "Inventory: existing/burnt NFT");
            _owners[nftId] = uint256(to);
            values[i] = 1;
            if (i == 0) {
                collectionId = nftId & _NF_COLLECTION_MASK;
            } else {
                require(collectionId == nftId & _NF_COLLECTION_MASK, "Inventory: not same collection");
            }
        }

        // it is virtually impossible that a non-fungible collection balance or supply
        // overflows due to the cost of minting unique tokens
        _balances[collectionId][to] += length;
        _supplies[collectionId] += length;

        emit TransferBatch(_msgSender(), address(0), to, nftIds, values);

        if (safe) {
            _callOnERC1155BatchReceived(address(0), to, nftIds, values, data);
        }
    }

    //================================== Burning Internals =======================================/

    /**
     * Burns some token.
     * @dev Reverts if `isBatch` is false and the sender is not approved.
     * @dev Reverts if `id` represents a non-fungible collection.
     * @dev Reverts if `id` represents a fungible collection and `value` is 0.
     * @dev Reverts if `id` represents a fungible collection and `value` is higher than `from`'s balance.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC1155-TransferSingle} event if `isBatch` is false.
     * @param from Address of the current token owner.
     * @param id Identifier of the token to burn.
     * @param value Amount of token to burn.
     * @param isBatch Whether this function is called by `_batchBurnFrom`.
     */
    function _burnFrom(
        address from,
        uint256 id,
        uint256 value,
        bool isBatch
    ) internal virtual {
        address sender;
        if (!isBatch) {
            sender = _msgSender();
            bool operatable = (from == sender) || _operators[from][sender];
            require(operatable, "Inventory: non-approved sender");
        }

        uint256 collectionId;
        if (isFungible(id)) {
            require(value != 0, "Inventory: zero value");
            collectionId = id;
            _balances[collectionId][from] = _balances[collectionId][from].sub(value);
        } else if (id & _NF_TOKEN_MASK != 0) {
            require(value == 1, "Inventory: wrong NFT value");
            require(_owners[id] == uint256(from), "Inventory: non-owned NFT");
            _owners[id] = _BURNT_NFT_OWNER;
            collectionId = id & _NF_COLLECTION_MASK;
            // cannot underflow as balance is confirmed through ownership
            _balances[collectionId][from] -= value;
        } else {
            revert("Inventory: not a token id");
        }

        // Cannot underflow
        _supplies[collectionId] -= value;

        if (!isBatch) {
            emit TransferSingle(sender, from, address(0), id, value);
        }
    }

    /**
     * Burns multiple tokens.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` represents a non-fungible collection.
     * @dev Reverts if one of `ids` represents a fungible collection and `value` is 0.
     * @dev Reverts if one of `ids` represents a fungible collection and `value` is higher than `from`'s balance.
     * @dev Reverts if one of `ids` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Address of the current tokens owner.
     * @param ids Identifiers of the tokens to burn.
     * @param values Amounts of tokens to burn.
     */
    function _batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual {
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        address sender = _msgSender();
        bool operatable = (from == sender) || _operators[from][sender];
        require(operatable, "Inventory: non-approved sender");

        bool isBatch = true;
        for (uint256 i = 0; i < length; ++i) {
            _burnFrom(from, ids[i], values[i], isBatch);
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    /**
     * Burns multiple non-fungible tokens belonging to the same collection.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `nftIds` does not represent a non-fungible token.
     * @dev Reverts if one of `nftIds` is not owned by `from`.
     * @dev Reverts if there are different collections for `nftIds`.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from address address that will own the minted tokens
     * @param nftIds uint256[] identifiers of the tokens to be minted
     */
    function _sameNFTCollectionBatchBurnFrom(address from, uint256[] memory nftIds) internal virtual {
        address sender = _msgSender();
        bool operatable = (from == sender) || _operators[from][sender];
        require(operatable, "Inventory: non-approved sender");

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 collectionId;
        for (uint256 i = 0; i < length; i++) {
            uint256 nftId = nftIds[i];
            require(isNFT(nftId), "Inventory: not an NFT");
            require(_owners[nftId] == uint256(from), "Inventory: non-owned NFT");
            _owners[nftId] = _BURNT_NFT_OWNER;
            values[i] = 1;
            if (i == 0) {
                collectionId = nftId & _NF_COLLECTION_MASK;
            } else {
                require(collectionId == nftId & _NF_COLLECTION_MASK, "Inventory: not same collection");
            }
        }

        // cannot underflow as balance is confirmed through ownership
        _balances[collectionId][from] -= length;
        // cannot underflow
        _supplies[collectionId] -= length;

        emit TransferBatch(sender, from, address(0), nftIds, values);
    }

    //================================== Token Receiver Calls Internal =======================================/

    /**
     * Calls {IERC1155TokenReceiver-onERC1155Received} on a target address.
     *  The call is not executed if the target address is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous token owner.
     * @param to New token owner.
     * @param id Identifier of the token transferred.
     * @param value Amount of token transferred.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        if (!to.isContract()) {
            return;
        }

        bytes4 retval = IERC1155TokenReceiver(to).onERC1155Received(_msgSender(), from, id, value, data);
        require(retval == _ERC1155_RECEIVED, "Inventory: transfer refused");
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155BatchReceived} on a target address.
     *  The call is not executed if the target address is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous tokens owner.
     * @param to New tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        if (!to.isContract()) {
            return;
        }

        bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(_msgSender(), from, ids, values, data);
        require(retval == _ERC1155_BATCH_RECEIVED, "Inventory: transfer refused");
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


// File @animoca/ethereum-contracts-core_library/contracts/utils/types/[email protected]

pragma solidity 0.6.8;

library UInt256ToDecimalString {

    function toDecimalString(uint256 value) internal pure returns (string memory) {
        // Inspired by OpenZeppelin's String.toString() implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/8b10cb38d8fedf34f2d89b0ed604f2dceb76d6a9/contracts/utils/Strings.sol
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/metadata/[email protected]

pragma solidity 0.6.8;


contract BaseMetadataURI is Ownable {
    using UInt256ToDecimalString for uint256;

    event BaseMetadataURISet(string baseMetadataURI);

    string public baseMetadataURI;

    function setBaseMetadataURI(string calldata baseMetadataURI_) external onlyOwner {
        baseMetadataURI = baseMetadataURI_;
        emit BaseMetadataURISet(baseMetadataURI_);
    }

    function _uri(uint256 id) internal view virtual returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, id.toDecimalString()));
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.6.0;



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


// File @animoca/ethereum-contracts-core_library/contracts/access/[email protected]

pragma solidity 0.6.8;

/**
 * Contract module which allows derived contracts access control over token
 * minting operations.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyMinter`, which can be applied to the minting functions of your contract.
 * Those functions will only be accessible to accounts with the minter role
 * once the modifer is put in place.
 */
contract MinterRole is AccessControl {

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    /**
     * Modifier to make a function callable only by accounts with the minter role.
     */
    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    /**
     * Constructor.
     */
    constructor () internal {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit MinterAdded(_msgSender());
    }

    /**
     * Validates whether or not the given account has been granted the minter role.
     * @param account The account to validate.
     * @return True if the account has been granted the minter role, false otherwise.
     */
    function isMinter(address account) public view returns (bool) {
        require(account != address(0), "MinterRole: address zero cannot be minter");
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * Grants the minter role to a non-minter.
     * @param account The account to grant the minter role to.
     */
    function addMinter(address account) public onlyMinter {
        require(!isMinter(account), "MinterRole: add an account already minter");
        grantRole(DEFAULT_ADMIN_ROLE, account);
        emit MinterAdded(account);
    }

    /**
     * Renounces the granted minter role.
     */
    function renounceMinter() public onlyMinter {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit MinterRemoved(_msgSender());
    }

}


// File contracts/solc-0.6/token/ERC1155/GameeVouchers.sol

pragma solidity ^0.6.8;



contract GameeVouchers is ERC1155Inventory, BaseMetadataURI, MinterRole {
    using UInt256ToDecimalString for uint256;

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "GameeVouchers";
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "GameeVouchers";

    // ===================================================================================================
    //                               Admin Public Functions
    // ===================================================================================================

    /**
     * Creates a collection.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155-URI} event.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function createCollection(uint256 collectionId) external onlyOwner {
        require(isFungible(collectionId), "GameeVouchers: only fungibles");
        _createCollection(collectionId);
    }

    /**
     * Mints a batch of tokens.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `ids` represents a non-fungible collection.
     * @dev Reverts if one of `ids` represents a non-fungible token and its paired value is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which is owned by a non-zero address.
     * @dev Reverts if one of `ids` represents a fungible collection and its paired value is 0.
     * @dev Reverts if one of `ids` represents a fungible collection and there is an overflow of supply.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to mint.
     * @param values Amounts of tokens to mint.
     */
    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external onlyMinter {
        _batchMint(to, ids, values, "", false);
    }

    /**
     * Mints a batch of tokens and calls the receiver function if the receiver is a contract.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `ids` represents a non-fungible collection.
     * @dev Reverts if one of `ids` represents a non-fungible token and its paired value is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which is owned by a non-zero address.
     * @dev Reverts if one of `ids` represents a fungible collection and its paired value is 0.
     * @dev Reverts if one of `ids` represents a fungible collection and there is an overflow of supply.
     * @dev Reverts the call to the receiver contract fails or is refused.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to mint.
     * @param values Amounts of tokens to mint.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external onlyMinter {
        _batchMint(to, ids, values, data, true);
    }

    // ===================================================================================================
    //                                 User Public Functions
    // ===================================================================================================

    /**
     * Burns some token.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` represents a non-fungible collection.
     * @dev Reverts if `id` represents a fungible collection and `value` is 0.
     * @dev Reverts if `id` represents a fungible collection and `value` is higher than `from`'s balance.
     * @dev Reverts if `id` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if `id` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Address of the current token owner.
     * @param id Identifier of the token to burn.
     * @param value Amount of token to burn.
     */
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external {
        _burnFrom(from, id, value, false);
    }

    /**
     * Burns multiple tokens.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` represents a non-fungible collection.
     * @dev Reverts if one of `ids` represents a fungible collection and `value` is 0.
     * @dev Reverts if one of `ids` represents a fungible collection and `value` is higher than `from`'s balance.
     * @dev Reverts if one of `ids` represents a non-fungible token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a non-fungible token which is not owned by `from`.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Address of the current tokens owner.
     * @param ids Identifiers of the tokens to burn.
     * @param values Amounts of tokens to burn.
     */
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external {
        _batchBurnFrom(from, ids, values);
    }

    // ===================================================================================================
    //                                   Internal Functions Overrides
    // ===================================================================================================

    function _uri(uint256 id) internal view override(ERC1155Inventory, BaseMetadataURI) returns (string memory) {
        return BaseMetadataURI._uri(id);
    }

    /**
     * Mints some token.
     * @dev Reverts if `id` does not represent a fungible collection.
     * @dev Reverts if `isBatch` is false and `to` is the zero address.
     * @dev Reverts if `value` is 0.
     * @dev Reverts if there is an overflow of supply.
     * @dev Reverts if `isBatch` is false, `safe` is true and the call to the receiver contract fails or is refused.
     * @dev Emits an {IERC1155-TransferSingle} event if `isBatch` is false.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to mint.
     * @param value Amount of token to mint.
     * @param data Optional data to send along to a receiver contract.
     * @param safe Whether to call the receiver contract.
     * @param isBatch Whether this function is called by `_batchMint`.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool safe,
        bool isBatch
    ) internal virtual override {
        require(isFungible(id), "GameeVouchers: only fungibles");
        super._mint(to, id, value, data, safe, isBatch);
    }
}