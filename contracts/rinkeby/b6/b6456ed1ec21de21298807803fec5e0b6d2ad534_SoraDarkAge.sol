/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: MIT

// Scroll down to the bottom to find the contract of interest. 

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


pragma solidity ^0.8.0;

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


// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/[email protected]/utils/introspection/IERC165.sol";

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


// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


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
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";

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


// File: @openzeppelin/[email protected]/utils/Address.sol


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


// File: @openzeppelin/[email protected]/utils/Context.sol


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


// File: @openzeppelin/[email protected]/utils/Strings.sol


pragma solidity ^0.8.0;

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


// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/[email protected]/utils/introspection/IERC165.sol";

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


// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Enumerable.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";

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


// File: @openzeppelin/[email protected]/access/Ownable.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/[email protected]/utils/Context.sol";

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


// File: @openzeppelin/[email protected]/security/ReentrancyGuard.sol


pragma solidity ^0.8.0;

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

// File: /Users/User/Documents/nftcompose/bd/contracts/SDA.rogue.sol

pragma solidity ^0.8.0;

// import "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";
// import "@openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol";
// import "@openzeppelin/[email protected]/utils/Address.sol";
// import "@openzeppelin/[email protected]/utils/Context.sol";
// import "@openzeppelin/[email protected]/utils/Strings.sol";
// import "@openzeppelin/[email protected]/utils/introspection/ERC165.sol";

/**
 * This is a modified version of the ERC721 class, where we only store
 * the address of the minter into an _owners array upon minting.
 *
 * It is based on EGGTOMATOES (0x22b4da0a3bda3eb6a6adb278fac894386a361f73), 
 * which is based on Toy Boggers (0xbf662a0e4069b58dfb9bcebebae99a6f13e06f5a).
 *
 * While this saves on minting gas costs, it means that the the balanceOf
 * function needs to do a bruteforce search through all the tokens.
 *
 * For small amounts of tokens (e.g. 8888), RPC services like Infura
 * can still query the function. 
 *
 * It also means any future contracts that reads the balanceOf function 
 * in a non-view function will incur a very nasty gas fee. 
 * 
 * Yes, this is a amazingly disgusting trick... 
 * only use it if you understand the tradeoffs.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    
    using Address for address;
    
    string private _name;
    
    string private _symbol;
    
    mapping(uint256 => address) internal _owners;

    uint256 internal _ownersLength;
    
    mapping(uint256 => address) private _tokenApprovals;
    
    mapping(address => mapping(address => bool)) private _operatorApprovals;     
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }     
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint count = 0;
        uint n = 8888;
        for (uint i = 0; i < n; ++i) {
            if (owner == _owners[i]) {
                ++count;
            }
        }
        return count;
    }
    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }     
    
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
  
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _ownersLength && _owners[tokenId] != address(0);
    }
  
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
  
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
  
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
  
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners[tokenId] = to;
        _ownersLength++;

        emit Transfer(address(0), to, tokenId);
    }
  
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }
  
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
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
  
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
  
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
  
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity ^0.8.0;

// import "@openzeppelin/[email protected]/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256 tokenId) {
        uint256 count = 0;
        uint256 n = _ownersLength;
        for (uint256 i = 0; i < n; ++i) {
            if (owner == _owners[i]) {
                if (count == index) {
                    return i;
                } else {
                    ++count;
                }
            }
        }
        require(false, "ERC721Enum: owner ioob");
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _ownersLength;
    }
    
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enum: global ioob");
        return index;
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// import "@openzeppelin/[email protected]/access/Ownable.sol";
// import "@openzeppelin/[email protected]/security/ReentrancyGuard.sol";

contract SoraDarkAge is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint;
    
    uint public constant TOKEN_PRICE = 80000000000000000; // 0.08 ETH

    uint public constant GENESIS_OWNER_TOKEN_PRICE = 50000000000000000; // 0.05 ETH

    uint public constant MAX_TOKENS_PER_PUBLIC_MINT = 10; // Only applies during public sale.

    uint public constant MAX_TOKENS = 8888;

    address public constant GENESIS_BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @dev 1: presale, 2: public sale, 3: genesis claim, 4: genesis burn, 255: closed.
    uint public saleState; 

    /// @dev A mapping of the token names.
    mapping(uint => string) public tokenNames;

    // @dev Whether the presale slot has been used. One slot per address.
    mapping(address => bool) public presaleUsed;

    /// @dev 256-bit words, each representing 256 booleans.
    mapping(uint => uint) internal genesisClaimedMap;

    /// @dev The license text/url for every token.
    string public LICENSE = "https://www.nftlicense.org"; 

    /// @dev Link to a Chainrand NFT 
    ///      which contains all the information needed to reproduce
    ///      the traits with a locked Chainlink VRF result.
    string public PROVENANCE; 

    /// @dev The base URI
    string public baseURI;

    event TokenNameChanged(address _by, uint _tokenId, string _name);

    event LicenseSet(string _license);

    event ProvenanceSet(string _provenance);

    event SaleClosed();

    event PreSaleOpened();

    event PublicSaleOpened();

    event GenesisClaimOpened();

    event GenesisBurnOpened();

    IERC721 internal genesisContract = IERC721(0x16199F94b2889fd0eE3d7153e8536819E9803D23);

    constructor() 
    ERC721("Sora Dark Age", "SDA") { 
        saleState = 255;
        baseURI = "https://sorasdreamworld.io/tokens/dark/";
    }
    
    /// @dev Withdraws Ether for the owner.    
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    /// @dev Sets the provenance.
    function setProvenance(string memory _provenance) public onlyOwner {
        PROVENANCE = _provenance;
        emit ProvenanceSet(_provenance);
    }

    /// @dev Sets base URI for all token IDs. 
    ///      e.g. https://sorasdreamworld.io/tokens/dark/
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /// @dev Open the pre-sale. 
    function openPreSale() public onlyOwner {
        saleState = 1;
        emit PreSaleOpened();
    }

    /// @dev Open the public sale. 
    function openPublicSale() public onlyOwner {
        saleState = 2;
        emit PublicSaleOpened();
    }

    /// @dev Open the claim phase. 
    function openGenesisClaim() public onlyOwner {
        saleState = 3;
        emit GenesisClaimOpened();
    }

    /// @dev Open the burn phase. 
    function openGenesisBurn() public onlyOwner {
        saleState = 4;
        emit GenesisBurnOpened();
    }

    /// @dev Close the sale.
    function closeSale() public onlyOwner {
        saleState = 255;
        emit SaleClosed();
    }

    /// @dev Mint just one NFT.
    function mintOne(address _toAddress) internal {
        uint mintIndex = totalSupply();
        require(mintIndex < MAX_TOKENS, "Not enough tokens available.");
        _safeMint(_toAddress, mintIndex);
    }

    /// @dev Force mint for the addresses. 
    //       Can be called anytime.
    //       If called right after the creation of the contract, the tokens 
    //       are assigned sequentially starting from id 0. 
    function forceMint(address[] memory _addresses) public onlyOwner { 
        for (uint i = 0; i < _addresses.length; ++i) {
            mintOne(_addresses[i]);
        }
    }
    
    /// @dev Self mint for the owner. 
    ///      Can be called anytime.
    ///      This does not require the sale to be open.
    function selfMint(uint _numTokens) public onlyOwner { 
        for (uint i = 0; i < _numTokens; ++i) {
            mintOne(msg.sender);
        }
    }
    
    /// @dev Sets the license text.
    function setLicense(string memory _license) public onlyOwner {
        LICENSE = _license;
        emit LicenseSet(_license);
    }

    /// @dev Returns the license for tokens.
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Token not found.");
        return LICENSE;
    }
    
    /// @dev Mints tokens.
    function mint(uint _numTokens) public payable nonReentrant {
        require(saleState < 3, "Not open.");
        require(_numTokens > 0, "Minimum number to mint is 1.");
        
        address sender = msg.sender;
        bool hasGenesisToken = genesisContract.balanceOf(sender) > 0;
        uint effectiveTokenPrice = hasGenesisToken ? GENESIS_OWNER_TOKEN_PRICE : TOKEN_PRICE;
        
        require(msg.value >= effectiveTokenPrice * _numTokens, "Wrong Ether value.");

        if (saleState == 1) {
            require(hasGenesisToken, "You don't have a Genesis token.");
            require(!presaleUsed[sender], "Presale slot already used.");
            presaleUsed[sender] = true;
            require(_numTokens <= 1, "Tokens per mint exceeded.");
        } else { // 2
            require(_numTokens <= MAX_TOKENS_PER_PUBLIC_MINT, "Tokens per mint exceeded.");
        }
        for (uint i = 0; i < _numTokens; ++i) {
            mintOne(sender);
        }
    }

    /// @dev Returns whether the genesis token has been claimed.
    function checkGenesisClaimed(uint _genesisId) public view returns(bool) {
        uint t = _genesisId;
        uint q = t >> 8;
        uint r = t & 255;
        uint m = genesisClaimedMap[q];
        return m & (1 << r) != 0;
    }

    /// @dev Returns an array of uints representing whether the token has been claimed.
    function genesisClaimed(uint[] memory _genesisIds) public view returns(bool[] memory) {
        uint n = _genesisIds.length;
        bool[] memory a = new bool[](n);
        for (uint i = 0; i < n; ++i) {
            a[i] = checkGenesisClaimed(_genesisIds[i]);
        }
        return a;
    }

    /// @dev Use the genesis tokens to claim free mints.
    function genesisClaim(uint[] memory _genesisIds) public nonReentrant {
        require(saleState == 3, "Not open.");
        uint n = _genesisIds.length;
        require(n > 0 && n % 3 == 0, 
            "Number of Genesis tokens must be a positive multiple of 3.");
        address sender = msg.sender;
        for (uint i = 0; i < n; i += 3) {
            for (uint j = 0; j < 3; ++j) {
                uint t = _genesisIds[i + j];
                uint q = t >> 8;
                uint r = t & 255;
                uint m = genesisClaimedMap[q];
                uint b = 1 << r;
                require(m & b == 0 && genesisContract.ownerOf(t) == sender, 
                    "A Genesis token cannot be used!");
                genesisClaimedMap[q] = m | b;
            }
            mintOne(sender);
        }
    }

    /// @dev Burns the genesis tokens for free mints.
    function genesisBurn(uint[] memory _genesisIds) public nonReentrant {
        require(saleState == 4, "Not open.");
        uint n = _genesisIds.length;
        require(n > 0 && n & 1 == 0, 
            "Number of Genesis tokens must be a positive multiple of 2.");
        address sender = msg.sender;
        for (uint i = 0; i < n; i += 2) {
            genesisContract.transferFrom(sender, GENESIS_BURN_ADDRESS, _genesisIds[i]);
            genesisContract.transferFrom(sender, GENESIS_BURN_ADDRESS, _genesisIds[i + 1]);
            mintOne(sender);
        }   
    }

    /// @dev Returns an array of the token ids under the owner.
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint[] memory a = new uint[](balanceOf(_owner));
        uint j = 0;
        uint n = 8888;
        for (uint i; i < n; ++i) {
            if (_owner == _owners[i]) {
                a[j++] = i;
            }
        }
        return a;
    }
    
    /// @dev Change the token name.
    function changeTokenName(uint _id, string memory _name) public {
        require(ownerOf(_id) == msg.sender, "You do not own this token.");
        require(sha256(bytes(_name)) != sha256(bytes(tokenNames[_id])), "Name unchanged.");
        tokenNames[_id] = _name;
        emit TokenNameChanged(msg.sender, _id, _name);
    }

    /// @dev Returns the token's URI for the metadata.
    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        require(_id <= totalSupply(), "Token not found.");
        return string(abi.encodePacked(baseURI, _id.toString()));
    }
}