/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// File: contracts/ECDSA.sol

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }


    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {

        if (uint(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }


    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {

        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: contracts/IERC721Receiver.sol


pragma solidity ^0.8.0;

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
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: contracts/IERC165.sol



pragma solidity ^0.8.0;
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
// File: contracts/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
// File: contracts/IERC721Enumerable.sol


pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint index)
    external
    view
    returns (uint tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint index) external view returns (uint);
}
// File: contracts/IERC721Metadata.sol


pragma solidity ^0.8.0;

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
    function tokenURI(uint tokenId) external view returns (string memory);
}

// File: contracts/ERC165.sol



pragma solidity ^0.8.0;


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
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File: contracts/Context.sol



pragma solidity ^0.8.0;
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

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}

    function _msgSender() internal view returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: contracts/Ownable.sol




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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
   */
    constructor ()  {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Strings.sol



pragma solidity ^0.8.0;
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint temp = value;
        uint length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint value, uint length)
    internal
    pure
    returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// File: contracts/Address.sol



pragma solidity ^0.8.0;
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
        target.call{value : weiValue}(data);
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
// File: contracts/ERC721.sol



pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint) private _balances;

    // Mapping from token ID to approved address
    mapping(uint => address) private _tokenApprovals;

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
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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
    function tokenURI(uint tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
    function approve(address to, uint tokenId) public virtual override {
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
    function getApproved(uint tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        uint tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint tokenId)
    internal
    view
    virtual
    returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint tokenId,
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
    function _mint(address to, uint tokenId) internal virtual {
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
    function _burn(uint tokenId) internal virtual {
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
        uint tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
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
    function _approve(address to, uint tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                    "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
        uint tokenId
    ) internal virtual {}
}

// File: contracts/ERC721Enumerable.sol



pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint => uint)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint => uint) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint => uint) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721)
    returns (bool)
    {
        return
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint index)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint index)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
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
        uint tokenId
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
     * @param tokenId uint ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint tokenId) private {
        uint length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint tokenId)
    private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint lastTokenId = _ownedTokens[from][lastTokenIndex];

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
     * @param tokenId uint ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint lastTokenIndex = _allTokens.length - 1;
        uint tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
// File: contracts/Base64.sol



pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}
// File: contracts/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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
// File: contracts/CryptoMechsSingle.sol



pragma solidity ^0.8.0;






contract CryptoMechs is ERC721Enumerable, Ownable {

    constructor()ERC721("CryptoMechs", "CM")
    {
        //createBuildingBlockFactory();
    }

    bool arePartsGenerated = false;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private tokenId_;
    uint16 constant maxTokens = 8888;
    uint slotsAvailable = 8888;
    uint maxMintsPerAddress = 3;

    uint16 mintTokenID = 1;

    mapping (address => uint256) pendingWithdrawals;

    mapping(uint256 => uint16[]) mergedParts; // reference of NFT id => list of mech part IDs that constitute it
    bool areMechsRevealed;

    uint256 internal numPartTypes = 8;

    // data packing uint structures
    uint8[] internal partRarities;
    uint16[] internal partIndexRanges; //indices of different part types, i.e. 0 => 20 is legs, 20 => 40 is SHOULDERS etc.
    uint16[] internal partBalances;
    uint16[] internal partTypeCounts;
    mapping(uint256 => uint16) partIndices;

    mapping(address => uint256) reservedSlotCounters;
    mapping(address => uint256[]) reservedSlotIDs;

    uint public slotPrice = 0.08 ether;

    // part types
    uint constant LEGS = 1;
    uint constant SHOULDERS = 2;
    uint constant COCKPIT = 3;
    uint constant ARM = 4;
    uint constant WEAPON = 5;
    uint constant GADGET = 6;
    uint constant SHIELD = 7;
    uint constant BACKPACK = 8;

    function setPrice(uint _amount) external onlyOwner {
        slotPrice = _amount;
    }

    string private constant Sig_WORD = "private";
    address private _signerAddress = 0x956231B802D9494296acdE7B3Ce3890c8b0438b8;


    // part slots
    uint constant SLOT_LEGS = 1;
    uint constant SLOT_SHOULDERS = 2;
    uint constant SLOT_COCKPIT = 3;
    uint constant SLOT_ARM_RIGHT = 4;
    uint constant SLOT_ARM_LEFT = 5;
    uint constant SLOT_WEAPON_RIGHT = 6;
    uint constant SLOT_WEAPON_LEFT = 7;
    uint constant SLOT_WEAPON_TOP = 8;
    uint constant SLOT_BACKPACK = 9;

    uint constant MAX_PLAYER_SPOTS = 8;


    string unrevealed = "https://cryptomechs.s3.eu-west-2.amazonaws.com/CryptoMechsParts/UnrevealedMech.png";

    function baseTokenURI() public pure returns (string memory) {
        return "https://cryptomechs.s3.eu-west-2.amazonaws.com/";
    }

    function partTokenURI() public pure returns (string memory) {
        return "https://cryptomechs.s3.eu-west-2.amazonaws.com/CryptoMechsParts/";
    }

    function contractURI() public pure returns (string memory) {
        return ""; //TODO
    }

    function getMaxTokens() public pure returns(uint256)
    {
        return maxTokens;
    }

    function getAvailableTokens() public view returns(uint256)
    {
        return maxTokens - mintTokenID;
    }

    function getBagParts(uint256 bagID) public view returns (uint16[] memory partIDs)
    {
        return mergedParts[bagID];
    }

    function matchAddresSigner(bytes memory signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender, Sig_WORD)))
        );
        return _signerAddress == hash.recover(signature);
    }



    /**
    * @dev Creates mech building block definitions and assigns the balance of each
    * @param partTypesSeparators indices of mech partTypes
    * i.e. 0 to 20 is LEGS, 20 to 40 is SHOULDERS and so on (gas optimized this way instead of saving every index individually)
    * @param numParts - The balance of each part i.e. #LEG_001 => 30, #ARM_011 => 50 and so on.
    * @param rarities - rarity of each mech part i.e. #LEG_001 => rarity 1, #LEG_010 => rarity 5
    */
    function batchCreatePartDefs(uint16[] memory partTypesSeparators, uint16[] memory numParts, uint8[] memory rarities) public onlyOwner
    {
        partRarities = rarities;
        partIndexRanges = partTypesSeparators;
        numPartTypes = partTypesSeparators.length - 1;

        partTypeCounts = new uint16[](partTypesSeparators.length - 1);

        for (uint i = 1; i < partTypesSeparators.length; ++i)
        {
            partTypeCounts[i-1] = partTypesSeparators[i] - partTypesSeparators[i-1];
        }

        partBalances = numParts;
    }

    function createBuildingBlockFactory() external onlyOwner
    {
        partIndexRanges = [0,23,58,133,141,220,236,248,276];
        partBalances = [60,60,545,854,854,854,546,410,410,413,413,413,854,546,854,546,413,341,341,546,413,342,342,363,363,105,318,476,476,363,529,476,476,476,363,363,528,106,476,476,364,317,363,318,318,318,105,105,476,363,529,363,363,529,529,529,529,529,119,119,119,119,79,79,119,119,79,79,79,79,79,119,119,363,363,119,119,120,120,363,79,79,79,79,363,363,158,158,158,158,158,79,79,79,79,79,79,119,119,119,119,119,1589,1589,1589,79,79,79,119,119,363,363,119,119,119,119,119,119,363,363,363,79,79,119,119,79,79,79,79,1589,158,158,158,513,456,4,513,171,171,256,1367,41,77,219,293,329,41,77,219,293,329,41,77,219,293,329,329,41,293,78,77,219,293,329,41,77,219,294,330,42,77,219,293,329,41,219,41,77,293,219,293,329,41,77,219,293,329,41,77,219,293,329,330,219,294,220,294,329,42,78,220,293,329,41,77,329,293,77,41,77,219,293,329,41,77,219,293,330,42,220,235,392,628,235,235,235,392,392,628,392,392,628,628,235,392,627,180,266,1245,711,711,355,355,711,355,266,266,355,476,204,272,272,204,119,119,79,204,204,272,204,119,79,204,119,476,272,119,204,272,272,476,120,81,476,272,476];
        partRarities = [3,4,2,1,2,3,1,3,4,3,4,5,1,2,1,2,4,5,3,2,3,4,5,1,3,4,5,3,2,1,1,1,2,4,4,2,1,5,3,2,1,4,1,2,3,4,5,4,3,2,1,2,4,1,3,5,2,4,1,2,1,3,3,4,1,3,2,4,5,2,5,1,3,1,3,2,4,3,5,1,2,4,3,4,1,3,1,3,2,4,5,4,2,3,5,1,2,1,4,3,4,5,1,1,2,2,3,5,2,4,1,3,1,2,3,1,3,4,2,4,5,3,1,1,3,2,4,3,5,1,5,4,3,4,1,4,2,3,5,2,1,5,4,3,2,1,5,4,3,2,1,5,4,3,2,1,1,5,2,4,4,3,2,1,5,4,3,2,1,5,4,3,2,1,5,3,5,4,2,3,2,1,5,4,3,2,1,5,4,3,2,1,1,3,2,5,3,1,5,4,3,2,1,5,4,1,2,4,5,4,3,2,1,5,4,3,2,1,5,3,4,3,2,4,4,4,3,3,2,3,3,2,2,4,3,2,5,4,1,2,4,3,5,2,1,4,5,3,1,3,2,2,3,4,4,5,3,3,2,3,4,5,3,4,1,2,4,3,2,2,1,4,5,1,2,1];

        partTypeCounts = new uint16[](partIndexRanges.length - 1);
        for (uint i = 1; i < partIndexRanges.length; ++i)
        {
            partTypeCounts[i-1] = partIndexRanges[i] - partIndexRanges[i-1];
        }
        arePartsGenerated = true;
    }

    /**
    * @dev Swap parts between 2 mech NFTs
    * @param partsToSwap the parts to wap in form [nft1_id, nft2_id, slot1_id, slot2_id]
    * swaps slot1_id from nft1_id with slot2_id of nft2_id
    * params are flat list multiple of 4
    */
    function swapBagContents(uint16[] memory partsToSwap) public
    {
        require(partsToSwap.length >= 4 && partsToSwap.length % 4 == 0, "INVALID PARAMETER FORMAT");

        for (uint i = 0; i < partsToSwap.length; i+=4)
        {
            uint16 b1 = partsToSwap[i];
            uint16 b2 = partsToSwap[i + 1];
            uint16 s1 = partsToSwap[i + 2];
            uint16 s2 = partsToSwap[i + 3];
            require (s1 < 9 && s2 < 9, "CAN ONLY SWAP BETWEEN 9 PARTS");
            require(ownerOf(b1) == msg.sender, "MUST OWN MECH");
            require(ownerOf(b2) == msg.sender, "MUST OWN MECH");

            if (s1 == SLOT_WEAPON_TOP || s1 == SLOT_WEAPON_LEFT || s1 == SLOT_WEAPON_RIGHT)
            {
                require(s2 == SLOT_WEAPON_TOP || s2 == SLOT_WEAPON_LEFT || s2 == SLOT_WEAPON_RIGHT, "CAN ONLY SWAP BETWEEN VALID SLOTS OF SAME TYPE");
            }
            else if (s1 == SLOT_ARM_RIGHT || s1 == SLOT_ARM_LEFT)
            {
                require (s2 == SLOT_ARM_RIGHT || s2 == SLOT_ARM_LEFT, "CAN ONLY SWAP BETWEEN VALID SLOTS OF SAME TYPE");
            }
            else
            {
                require (s1 == s2, "CAN ONLY SWAP BETWEEN VALID SLOTS OF SAME TYPE");
            }

            uint16 temp = mergedParts[b1][s1];
            mergedParts[b1][s1] = mergedParts[b2][s2];
            mergedParts[b2][s2] = temp;

            //isMechRevealed[b1] = false;
            //isMechRevealed[b2] = false;
        }
    }

    function GetPartType(uint256 partID) public view returns(uint partType)
    {
        for (uint i = 1; i < partIndexRanges.length; ++i)
        {
            if (partID <= partIndexRanges[i] && partID > partIndexRanges[i-1])
            {
                return i;
            }
        }
        return 0;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return formatTokenURI(_tokenId, imageURI(mergedParts[ _tokenId]));
    }

    function imageURI(uint16[] memory parts) public pure returns (string memory)
    {
        bool useAmpersand = false;
        string memory bagURL = "https://www.cryptomechs.org/nftbag?";
        for (uint i = 0; i < parts.length; ++i)
        {
            if (useAmpersand) bagURL = string(abi.encodePacked(bagURL, "&"));
            if (parts[i] == 0) continue;
            useAmpersand = true;
            bagURL = string(abi.encodePacked(bagURL, "b", uint2str(i+1), "=", uint2str(parts[i])));
        }
        return bagURL;
    }

    function getPartTypeFromSlot(uint256 slot) public pure returns (uint)
    {
        if (slot == SLOT_LEGS)
            return LEGS;
        if (slot == SLOT_SHOULDERS)
            return SHOULDERS;
        if (slot == SLOT_COCKPIT)
            return COCKPIT;
        if (slot == SLOT_ARM_LEFT || slot == SLOT_ARM_RIGHT)
            return ARM;
        if (slot == SLOT_WEAPON_RIGHT || slot == SLOT_WEAPON_LEFT || slot == SLOT_WEAPON_TOP)
            return WEAPON;
        if (slot == SLOT_BACKPACK)
            return BACKPACK;

        return WEAPON;
    }

    function getPartTypeText(uint256 partID) public view returns (string memory)
    {
        uint partType = GetPartType(partID);
        if (partType == LEGS)
            return "LEGS";
        if (partType == SHOULDERS)
            return "SHOULDERS";
        if (partType == COCKPIT)
            return "COCKPIT";
        if (partType == ARM)
            return "ARM";
        if (partType == WEAPON)
            return "WEAPON";
        if (partType == SHIELD)
            return "SHIELD";
        if (partType == GADGET)
            return "GADGET";
        if (partType == BACKPACK)
            return "BACKPACK";

        return "DEFAULT";
    }

    function formatTokenURI(uint256 bagID, string memory imgURI) public view returns (string memory)
    {
        string memory parts = "";
        uint16[] memory partIDs = mergedParts[bagID];
        string memory comma = "";
        bool useComma = false;
        for (uint i = 0; i < partIDs.length; ++i)
        {
            if (useComma) comma = ",";
            uint16 partID = partIDs[i];
            if (partID == 0) continue;
            useComma = true;
            uint8 rarity = partRarities[partID - 1];
            //uint8 rarity = 2;

            parts = string(abi.encodePacked(parts, comma,
                '{"trait_type": "', getPartTypeText(partID), ' ID"', ', "value": "',
                getPartTypeText(partID), ' #', uint2str(partID), '" }',
                ', {"trait_type": "', getPartTypeText(partID), ' Rarity',
                '", "value": ',
                uint2str(rarity), "}"
                ));
        }

        //string memory tempImage = string(abi.encodePacked("https://storage.googleapis.com/opensea-prod.appspot.com/puffs/", uint2str(bagID),".png"));
        string memory tempImage = unrevealed;
        if (areMechsRevealed)
        {
            tempImage = string(abi.encodePacked(baseTokenURI(), uint2str(bagID), ".png"));
        }

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            "Mech #", uint2str(bagID),
                            '", "description":"One of 8888 mechs of the CryptoMechs collection. To view the building blocks of this mech, follow this url: ',
                            imgURI,
                            '", "external_url":"',imgURI,
                            '", "image":"', tempImage,
                            '", "attributes": [', parts, "]}"
                        )
                    )
                )
            )
        );
    }

    bool public isPreSale;
    bool public isFreeSale;
    bool public isMainSale;

    function togglePreSale () external onlyOwner {
        isPreSale = !isPreSale;
    }

    function toggleFreeSale () external onlyOwner {
        isFreeSale = !isFreeSale;
    }

    function toggleMainSale () external onlyOwner {
        isMainSale = !isMainSale;
    }
    uint public freeSaleMaxLimit = 1000;
    uint public preSaleMaxLimit = 100;

    function setFreeSaleMaxLimit (uint _amount) external onlyOwner {
        freeSaleMaxLimit = _amount;
    }

    function setPreSaleMaxLimit (uint _amount) external onlyOwner {
        preSaleMaxLimit = _amount;
    }

    function _mintRandom(uint tokenAmount, bytes memory signature) external payable {
        require(arePartsGenerated, "MINTING NOT ENABLED YET");
        require(reservedSlotCounters[msg.sender] + tokenAmount <= maxMintsPerAddress, "MAX MINT LIMIT REACHED");

        //if (isFreeSale) {
        //    require (tokenId_.current()+tokenAmount <= freeSaleMaxLimit, "MAX FREESALE LIMIT REACHED");
        //    for (uint i = 0; i < tokenAmount; i++) {
        //        tokenId_.increment();
        //        mintRandom(tokenId_.current());
        //reserveSlot(tokenId_.current());
        //    }
        //}
        //else
        if (isPreSale) {
            require (tokenId_.current()+tokenAmount <= preSaleMaxLimit, "MAX PRESALE LIMIT REACHED");
            require (slotPrice*tokenAmount <= msg.value, "NOT ENOUGH MONEY SENT");
            require(matchAddresSigner(signature), "DIRECT_MINT_DISALLOWED");
            //reserveSlots(tokenAmount);
            for (uint i = 0; i < tokenAmount; i++) {
                tokenId_.increment();
                mintRandom(tokenId_.current());
                //reserveSlot(tokenId_.current());
            }
            pendingWithdrawals[owner()] += msg.value;
        }
        else if (isMainSale) {
            require (tokenId_.current() + tokenAmount <= maxTokens, "MAX LIMIT REACHED!");
            require (slotPrice*tokenAmount <= msg.value, "NOT ENOUGH MONEY SENT");
            for (uint i = 0; i < tokenAmount; i++) {
                tokenId_.increment();
                mintRandom(tokenId_.current());
                //reserveSlot(tokenId_.current());
            }
            pendingWithdrawals[owner()] += msg.value;
        }
    }

    /*
        function mintReserved() public
        {
            require(reservedSlotCounters[msg.sender] < reservedSlotIDs[msg.sender].length, "ALL RESERVED MINTED");
            mintRandom(reservedSlotIDs[msg.sender][reservedSlotCounters[msg.sender]]);
            reservedSlotCounters[msg.sender]++;
        }

        function mintAllReserved() public
        {
            uint counter = reservedSlotCounters[msg.sender];
            uint max =  reservedSlotIDs[msg.sender].length;
            require(counter < max, "ALL RESERVED MINTED");
            while (counter < max)
            {
                mintRandom(reservedSlotIDs[msg.sender][counter]);
                counter++;
            }
            reservedSlotCounters[msg.sender] = counter;
        }
    */

    function mintRandom(uint tokenId) internal
    {
        uint16 slot = (uint16) (tokenId - 1);
        uint16[] memory partIDs = new uint16[](9);

        for (uint i = 1; i <= 9; ++i)
        {
            uint partType = getPartTypeFromSlot(i);

            if (i == SLOT_WEAPON_RIGHT || i == SLOT_WEAPON_LEFT || i == SLOT_WEAPON_TOP)
            {
                if (i == SLOT_WEAPON_RIGHT && partTypeCounts[SHIELD - 1] > 0)
                {
                    partType = SHIELD;
                }
                else if (i == SLOT_WEAPON_TOP && partTypeCounts[GADGET - 1] > 0)
                {
                    partType = GADGET;
                }
            }

            uint16 fromI = partIndexRanges[partType - 1];
            uint16 to = fromI + partTypeCounts[partType - 1];

            uint16 index = fromI + (slot % (to - fromI));
            if (partType == WEAPON && i != SLOT_WEAPON_LEFT)
            {
                index = fromI + ((slot + 1) % (to - fromI));
            }
            if (partType == ARM && i != SLOT_ARM_RIGHT)
            {
                index = fromI + ((slot + 1) % (to - fromI));
            }

            uint16 partIndex = index + 1;
            if (partIndices[index] != 0)
            {
                partIndex = partIndices[index];
            }

            if (partBalances[index] > 0)
            {
                partBalances[index] -= 1;
            }
            else
            {
                if (index != to)
                {
                    partBalances[index] = partBalances[to];
                    uint16 toPartIndex = to + 1;
                    if (partIndices[to] != 0)
                    {
                        toPartIndex = partIndices[to];
                    }
                    partIndices[index] = toPartIndex;
                }
                partTypeCounts[partType - 1] = partTypeCounts[partType - 1] - 1;
            }

            if (partBalances[index] > 0)
                partIDs[i-1] = partIndex;
            else
                partIDs[i-1] = 0;
        }

        _mint(msg.sender, tokenId);
        mergedParts[tokenId] = partIDs;
        reservedSlotCounters[msg.sender]++;
    }

    function RevealMechs() external onlyOwner
    {
        areMechsRevealed = true;
    }

    //function reserveSlot(uint tokenID) private
    //{
    //    reservedSlotIDs[msg.sender].push(tokenID);
    //    slotsAvailable--;
    //}

    function withdrawRoyalties() public
    {
        address payable receiver = payable(msg.sender);
        uint amount = pendingWithdrawals[receiver];
        require(amount > 0, "NO ROYALTIES AVAILABLE");
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[receiver] = 0;
        receiver.transfer(amount);
    }

    function withdraw() public onlyOwner {
        require(msg.sender == owner(), "Only authorized minters can withdraw");

        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(msg.sender);

        uint amount = pendingWithdrawals[receiver];
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[receiver] = 0;
        address payable _dylanAddress = payable (0x3384392f12f90C185a43861E0547aFF77BD5134A);
        uint dylanTransfer =  (amount*(3))/(100);
        _dylanAddress.transfer(dylanTransfer);
        receiver.transfer(amount);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str)
    {
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    //tokens held by user
    function tokensOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }
}