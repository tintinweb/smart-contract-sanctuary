/**
 *Submitted for verification at polygonscan.com on 2021-12-08
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
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

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

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

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
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

contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );

    bytes32 internal domainSeperator;

    constructor(string memory name, string memory version) public {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                getChainID(),
                address(this)
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeperator() private view returns (bytes32) {
        return domainSeperator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version)
        public
        EIP712Base(name, version)
    {}

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx =
            MetaTransaction({
                nonce: nonces[userAddress],
                from: userAddress,
                functionSignature: functionSignature
            });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );
        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) =
            address(this).call(
                abi.encodePacked(functionSignature, userAddress)
            );

        require(success, "Function call not successfull");
        nonces[userAddress] = nonces[userAddress].add(1);
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }

    function _msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    // To recieve ether in contract
    receive() external payable {}
}

abstract contract Ownable {
    mapping(uint256 => address payable) internal _owners;

    function msgSender() private view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    modifier notOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) != msgSender());
        _;
    }

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msgSender());
        _;
    }

    function ownerOf(uint256 _tokenId) public view returns (address payable) {
        address payable owner = _owners[_tokenId];
        require(owner != address(0));
        return owner;
    }
}

library Strings {
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract CreatorsHubOpenBase is
    ERC165Storage,
    IERC1155,
    IERC1155MetadataURI,
    EIP712MetaTransaction("ERC1155", "1"),
    Ownable
{
    using SafeMath for uint256;
    using Address for address;

    address private _owner;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from account to true / false mint approvals
    mapping(address => bool) private _mintApprovals;

    // Mapping from account to root operators approvals
    mapping(address => bool) internal _rootOperators;

    mapping(uint256 => string) private _metaFileUrl;

    // Mapping from token ID to proof checksums
    mapping(uint256 => string[]) private _proofChecksums;

    // Mapping from token ID to secret field
    mapping(uint256 => string) private _secretFields;

    // Mapping from token ID to fees lock (true/false)
    mapping(uint256 => bool) private _feesLock;

    // Mapping from token ID to flag (paused = true, active = false)
    mapping(uint256 => bool) internal _isPaused;

    // Mapping from token ID to amount (reedmable if > 0)
    mapping(uint256 => uint256) internal _redeemable;

    // Mapping from token ID to array of addresses
    mapping(uint256 => address[]) internal _redeemed_by;

    struct Listing {
        uint256 initialPrice;
        uint256 price;
        bool biddingEnabled;
        uint256 activeTill;
        address payable currentBidder;
        bool operatorBid;
    }

    struct Fee {
        string name;
        address payable recipient;
        uint256 value; // 185 basis points = 1.85%
        bool percentage;
    }
    // Mapping from token ID to array of fees (initial sale)
    mapping(uint256 => Fee[]) internal _creatorFees;

    // Mapping from token ID to array of fees (reselling)
    mapping(uint256 => Fee[]) internal _resellerFees;

    // Mapping from token ID to account price
    mapping(uint256 => mapping(address => Listing)) internal _tokenListings;

    function addCreatorFees(uint256 tokenId, Fee[] memory fees) public {
        require(_feesLock[tokenId] == false, "Fees locked");
        require(
            _owners[tokenId] == _msgSender() ||
                _rootOperators[_msgSender()] == true,
            "Must be owner or operator"
        );
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i].percentage == true) {
                require(
                    fees[i].value < 10000,
                    "Fee must be between 1-10000 basis points"
                );
                require(
                    fees[i].value > 0,
                    "Fee must be between 1-10000 basis points"
                );
            }
            _creatorFees[tokenId].push(fees[i]);
        }
    }

    function addResellerFees(uint256 tokenId, Fee[] memory fees) public {
        require(_feesLock[tokenId] == false, "Fees locked");
        require(
            _owners[tokenId] == _msgSender() ||
                _rootOperators[_msgSender()] == true,
            "Must be owner or operator"
        );
        for (uint256 i = 0; i < fees.length; i++) {
            _resellerFees[tokenId].push(fees[i]);
        }
    }

    modifier notPaused(uint256 _tokenId) {
        require(_isPaused[_tokenId] != true, "Cannot trade paused token");
        _;
    }

    function pauseToken(uint256 tokenId, bool isPausedFlag) public {
        require(_rootOperators[_msgSender()] == true, "Must be operator");
        _isPaused[tokenId] = isPausedFlag;
    }

    function lockFees(uint256 tokenId) public {
        require(
            _owners[tokenId] == _msgSender() ||
                _rootOperators[_msgSender()] == true,
            "Must be owner or operator"
        );
        _feesLock[tokenId] = true;
    }

    function getListing(uint256 tokenId, address seller)
        public
        view
        returns (Listing memory)
    {
        return _tokenListings[tokenId][seller];
    }

    function getCreatorFees(uint256 tokenId)
        public
        view
        returns (Fee[] memory)
    {
        return _creatorFees[tokenId];
    }

    function getResellerFees(uint256 tokenId)
        public
        view
        returns (Fee[] memory)
    {
        return _resellerFees[tokenId];
    }

    function setTokenPrice(
        uint256 _tokenId,
        uint256 price,
        bool biddingEnabled,
        uint256 numberOfDays
    ) public {
        require(
            _balances[_tokenId][_msgSender()] > 0,
            "Caller must own given token"
        );
        if (_tokenListings[_tokenId][_msgSender()].biddingEnabled) {
            require(
                _tokenListings[_tokenId][_msgSender()].currentBidder ==
                    payable(0),
                "Auction in progress"
            );
        }

        if (numberOfDays > 0) {
            _tokenListings[_tokenId][_msgSender()] = Listing(
                price,
                price,
                biddingEnabled,
                block.timestamp + (numberOfDays * 1 days), // active for x days from now
                payable(0),
                false
            );
        } else {
            _tokenListings[_tokenId][_msgSender()] = Listing(
                price,
                price,
                biddingEnabled,
                0, // active for unlimited time
                payable(0),
                false
            );
        }
    }

    function setTokenPriceOperator(
        address ownerAddr,
        uint256 _tokenId,
        uint256 price,
        bool biddingEnabled,
        uint256 numberOfDays
    ) public {
        require(_rootOperators[_msgSender()] == true, "Must be operator");
        require(
            _balances[_tokenId][ownerAddr] > 0,
            "Owner must own given token"
        );
        if (_tokenListings[_tokenId][ownerAddr].biddingEnabled) {
            require(
                _tokenListings[_tokenId][ownerAddr].currentBidder ==
                    payable(0),
                "Auction in progress"
            );
        }

        if (numberOfDays > 0) {
            _tokenListings[_tokenId][ownerAddr] = Listing(
                price,
                price,
                biddingEnabled,
                block.timestamp + (numberOfDays * 1 days), // active for x days from now
                payable(0),
                false
            );
        } else {
            _tokenListings[_tokenId][ownerAddr] = Listing(
                price,
                price,
                biddingEnabled,
                0, // active for unlimited time
                payable(0),
                false
            );
        }
    }

    function addMetaFileUrl(uint256 id, string memory url) public {
        require(
            _owners[id] == _msgSender() || _rootOperators[_msgSender()] == true,
            "Must be owner or operator"
        );
        require(bytes(_metaFileUrl[id]).length == 0, "File url already set");

        _metaFileUrl[id] = url;
    }

    function setSecretField(uint256 id, string memory secret) public {
        require(
            _owners[id] == _msgSender() || _rootOperators[_msgSender()] == true,
            "Must be owner or operator"
        );
        require(bytes(_secretFields[id]).length == 0, "Secret already set");

        _secretFields[id] = secret;
    }

    function getSecretField(uint256 id) public view returns (string memory) {
        require(_balances[id][_msgSender()] > 0, "Caller must own given token");

        return _secretFields[id];
    }

    function getMetaFileUrl(uint256 id) public view returns (string memory) {
        return _metaFileUrl[id];
    }

    function addProofChecksums(uint256 id, string[] memory checksums) public {
        require(
            _owners[id] == _msgSender() || _rootOperators[_msgSender()] == true,
            "Must be owner or operator"
        );

        for (uint256 i = 0; i < checksums.length; i++) {
            _proofChecksums[id].push(checksums[i]);
        }
    }

    function getChecksums(uint256 id) public view returns (string[] memory) {
        return _proofChecksums[id];
    }

    function allowRedeem(uint256 tokenId) public {
        require(
            _owners[tokenId] == _msgSender() || _rootOperators[_msgSender()] == true,
            "Must be owner or operator"
        );
        require(
            _redeemable[tokenId] == 0,
            "Redeem already allowed"
        );
        _redeemable[tokenId] = _balances[tokenId][_msgSender()];
    }

    function redeem(uint256 tokenId, address customerAddr) public {
        require(
            _owners[tokenId] == _msgSender() || _rootOperators[_msgSender()] == true,
            "Must be owner or operator"
        );
        require(
            _redeemed_by[tokenId].length < _redeemable[tokenId],
            "Token cannot be redeemed"
        );
        _redeemed_by[tokenId].push(customerAddr);
    }

     function redeemedBy(uint256 tokenId) public view returns (address[] memory) {
        require(
            _redeemable[tokenId] > 0,
            "Token cannot be redeemed"
        );

        return _redeemed_by[tokenId];
    }

    // Used as the URI for all token types by relying on ID substition, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    event TokenUpgrade(uint256 oldId, uint256 newId);

    constructor(string memory tokenUri) {
        _setURI(tokenUri);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);

        _rootOperators[_msgSender()] = true;
        _owner = _msgSender();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substituion mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        if(bytes(_metaFileUrl[tokenId]).length == 0) {
            return string(abi.encodePacked(_uri, Strings.uint2str(tokenId)));
        } else {
            return _metaFileUrl[tokenId];
        }
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(
                accounts[i] != address(0),
                "ERC1155: batch balance query for the zero address"
            );
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

/**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address account,
        address operator
    ) public override view returns (bool isOperator) {
        return true;
    //     // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
    //    if (operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
    //         return true;
    //     }
    //     return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][from] = _balances[id][from].sub(
            amount,
            "ERC1155: insufficient balance for transfer"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            "0x0"
        );

        _balances[id][from] = _balances[id][from].sub(
            amount,
            "ERC1155: insufficient balance for transfer"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, "0x0");
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substituion mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function setURI(string memory newuri) internal virtual {
        require(_rootOperators[_msgSender()] == true, "Must be operator");
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(account != address(0), "ERC1155: mint to the zero address");
        require(
            _owners[id] == address(0),
            "You are not allowed to mint given id"
        );

        address caller = _msgSender();

        _beforeTokenTransfer(
            caller,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] = _balances[id][account].add(amount);
        _owners[id] = payable(caller);

        emit TransferSingle(caller, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            caller,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(
            _rootOperators[_msgSender()] == true,
            "Caller is not root operator"
        );
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
            _owners[ids[i]] = payable(to);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

abstract contract Auctionable is Ownable, CreatorsHubOpenBase {
    event Bid(
        address indexed _bidder,
        uint256 indexed _amount,
        uint256 indexed _tokenId
    );
    event AcceptBid(
        address indexed _bidder,
        address indexed _seller,
        uint256 _amount,
        uint256 indexed _tokenId
    );
    event CancelBid(
        address indexed _bidder,
        uint256 indexed _amount,
        uint256 indexed _tokenId
    );
    event Sold(
        address indexed _buyer,
        address indexed _seller,
        uint256 _amount,
        uint256 indexed _tokenId
    );

    function clearBid(uint256 _tokenId, address seller) private {
        _tokenListings[_tokenId][seller].currentBidder = payable(0);
        _tokenListings[_tokenId][seller].price = _tokenListings[_tokenId][
            seller
        ]
            .initialPrice;
        _tokenListings[_tokenId][seller].operatorBid = false;
    }

    function returnCurrentBid(uint256 _tokenId, address seller) private {
        uint256 currentBid = _tokenListings[_tokenId][seller].price;
        address payable currentBidder =
            _tokenListings[_tokenId][seller].currentBidder;
        if (
            currentBidder != address(0) &&
            !_tokenListings[_tokenId][seller].operatorBid
        ) {
            currentBidder.transfer(currentBid);
        }
    }

    function isGreaterBid(uint256 _tokenId, address seller)
        private
        view
        returns (bool)
    {
        return msg.value > _tokenListings[_tokenId][seller].price;
    }

    function bid(uint256 _tokenId, address seller)
        public
        payable
        notPaused(_tokenId)
    {
        require(
            _tokenListings[_tokenId][seller].biddingEnabled,
            "Must be auction"
        );
        require(seller != _msgSender(), "Seller cannot bid");
        require(isGreaterBid(_tokenId, seller), "Current bid is higher");
        if (_tokenListings[_tokenId][seller].activeTill != 0) {
            require(
                _tokenListings[_tokenId][seller].activeTill > block.timestamp,
                "Listing expired"
            );
        }
        returnCurrentBid(_tokenId, seller);
        _tokenListings[_tokenId][seller].currentBidder = payable(_msgSender());
        _tokenListings[_tokenId][seller].price = msg.value;
        _tokenListings[_tokenId][seller].operatorBid = false;
        emit Bid(_msgSender(), msg.value, _tokenId);
    }

    function operatorBid(
        uint256 _tokenId,
        address seller,
        uint256 price,
        address bidder
    ) public payable notPaused(_tokenId) {
        require(_rootOperators[_msgSender()] == true, "Must be operator");
        require(
            _tokenListings[_tokenId][seller].biddingEnabled,
            "Must be auction"
        );
        require(
            price > _tokenListings[_tokenId][seller].price,
            "Current bid is higher"
        );
        if (_tokenListings[_tokenId][seller].activeTill != 0) {
            require(
                _tokenListings[_tokenId][seller].activeTill > block.timestamp,
                "Listing expired"
            );
        }
        returnCurrentBid(_tokenId, seller);
        _tokenListings[_tokenId][seller].currentBidder = payable(bidder);
        _tokenListings[_tokenId][seller].price = price;
        _tokenListings[_tokenId][seller].operatorBid = true;
        emit Bid(bidder, price, _tokenId);
    }

    function operatorCancelBid(uint256 _tokenId, address seller)
        public
        payable
    {
        require(_rootOperators[_msgSender()] == true, "Must be operator");
        require(
            _tokenListings[_tokenId][seller].biddingEnabled,
            "Must be auction"
        );
        require(
            _tokenListings[_tokenId][seller].currentBidder != address(0),
            "No bid to cancel"
        );
        address payable bidder = _tokenListings[_tokenId][seller].currentBidder;
        uint256 bidAmount = _tokenListings[_tokenId][seller].price;
        returnCurrentBid(_tokenId, seller);
        clearBid(_tokenId, seller);
        emit CancelBid(bidder, bidAmount, _tokenId);
    }

    function acceptBid(uint256 _tokenId) public notPaused(_tokenId) {
        require(
            _tokenListings[_tokenId][_msgSender()].biddingEnabled,
            "Must be auction"
        );
        require(
            balanceOf(_msgSender(), _tokenId) > 0,
            "Seller does not own token anymore"
        );
        uint256 currentBid = _tokenListings[_tokenId][_msgSender()].price;
        address currentBidder =
            _tokenListings[_tokenId][_msgSender()].currentBidder;
        if (!_tokenListings[_tokenId][_msgSender()].operatorBid) {
            payout(_tokenId, _msgSender());
        }
        transferFrom(_msgSender(), currentBidder, _tokenId, 1);
        clearBid(_tokenId, _msgSender());
        emit AcceptBid(currentBidder, _msgSender(), currentBid, _tokenId);
    }

    function payout(uint256 _tokenId, address _seller) private {
        uint256 totalPrice = _tokenListings[_tokenId][_seller].price;
        uint256 allFees = 0;

        if (_seller == _owners[_tokenId]) {
            Fee[] memory fees = getCreatorFees(_tokenId);
            for (uint256 i = 0; i < fees.length; ++i) {
                if (fees[i].percentage) {
                    uint256 fee = (fees[i].value * totalPrice) / 10000;
                    allFees += fee;
                    fees[i].recipient.transfer(fee);
                } else {
                    allFees += fees[i].value;
                    fees[i].recipient.transfer(fees[i].value);
                }
            }
        } else {
            Fee[] memory fees = getResellerFees(_tokenId);
            for (uint256 i = 0; i < fees.length; ++i) {
                if (fees[i].percentage) {
                    uint256 fee = (fees[i].value * totalPrice) / 10000;
                    allFees += fee;
                    fees[i].recipient.transfer(fee);
                } else {
                    allFees += fees[i].value;
                    fees[i].recipient.transfer(fees[i].value);
                }
            }
        }
        payable(_seller).transfer(totalPrice - allFees);
    }

    function cancelBid(uint256 _tokenId, address seller) public {
        address payable bidder = _tokenListings[_tokenId][seller].currentBidder;
        require(
            _msgSender() == bidder || _msgSender() == seller,
            "You must be last bidder or owner"
        );
        uint256 bidAmount = _tokenListings[_tokenId][seller].price;
        returnCurrentBid(_tokenId, seller);
        clearBid(_tokenId, seller);
        emit CancelBid(bidder, bidAmount, _tokenId);
    }

    function buy(uint256 _tokenId, address seller)
        public
        payable
        notOwnerOf(_tokenId)
        notPaused(_tokenId)
    {
        uint256 salePrice = _tokenListings[_tokenId][seller].price;
        uint256 sentPrice = msg.value;
        address buyer = _msgSender();
        require(
            balanceOf(seller, _tokenId) > 0,
            "Seller does not own token anymore"
        );
        require(salePrice > 0, "Cannot buy this token");
        require(
            _tokenListings[_tokenId][seller].biddingEnabled == false,
            "Cannot buy, auction in progress"
        );
        require(sentPrice >= salePrice, "Insufficient value sent");
        if (_tokenListings[_tokenId][seller].activeTill != 0) {
            require(
                _tokenListings[_tokenId][seller].activeTill > block.timestamp,
                "Listing expired"
            );
        }
        payout(_tokenId, seller);
        clearBid(_tokenId, seller);
        transferFrom(seller, buyer, _tokenId, 1);
        Sold(buyer, seller, sentPrice, _tokenId);
    }
}

contract OpenAuctionableERC1155 is
    CreatorsHubOpenBase("https://creatorshub.license.rocks/api/public/metaFile/"),
    Auctionable
{
    constructor() {}
}