/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

/*                                      .--.   
                                      !      \ 
                                      \      | 
                                       '.__.'


                                 -                                  --                   
                               /- \-                              --  \-                 
                             /-     \           -\              -/      \-               
             -            /--        \-       /- -\           -/          \-             
           -/ \-        /-             \    /-     \       --/              \-           
         -/     \-    /-                \---        -\   -/                   \--        
       -/         \ --                    \-          --/                       \-      
     -/            \-                       \       -/            On-chain        \-    
   -/                \-                      \-   -/             Mountains          \-  
 -/                    \                       \-/                                    \-
________________________________________________________________________________________

5000 beautiful animated mountain views with realistic atmospheric effects. Generated and stored completely on-chain. No IPFS.
Unique linear mint system for each wallet with 10 different scenes:

1st mint - you get Sunrise, 
2th - Day,
3th - Cloudy Day, 
4th - Sunset,
5th - Night Stars, 
6th - Night Crescent, 
7th - Night Moon, 
8th - Mars, 
9th - Mars Sunset, 
10th - Halloween Mystic Night,
all next - random scene.

Website: http://onchainmountains.art 
Twitter: https://twitter.com/Chain_Mountains

*/

// SPDX-License-Identifier: MIT

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




/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";


    /**
     * @dev Converts a `hex string` to uint256
     */
     function fromHex(string memory c) internal pure returns (uint256) {
        string memory s1 = Strings.substr(c,0,1);
        string memory s2 = Strings.substr(c,1,2);
        uint a;
        uint b;
        
        if (bytes1(bytes(s1)) >= bytes1('0') && bytes1(bytes(s1)) <= bytes1('9')) {
            a = strToUint(s1);
        }
        if (bytes1(bytes(s1)) >= bytes1('a') && bytes1(bytes(s1)) <= bytes1('f')) {
            a = 10 + uint256(uint8(bytes1(bytes(s1)))) -  uint256(uint8(bytes1('a')));
        }
        
        if (bytes1(bytes(s2)) >= bytes1('0') && bytes1(bytes(s2)) <= bytes1('9')) {
            b = strToUint(s2);
        }
        if (bytes1(bytes(s2)) >= bytes1('a') && bytes1(bytes(s2)) <= bytes1('f')) {
            b = 10 + uint256(uint8(bytes1(bytes(s2)))) -  uint256(uint8(bytes1('a')));
        }
        return b + 16 * a;
     }
     
    
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
            return "00";
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
        return Strings.substr(string(buffer), 2,4);
    }
    
      function strToUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (b[i] >= 0x30 && b[i] <= 0x39) {
                result = result * 10 + (uint(uint8((b[i]))) - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; // this was missing
    }

    function substr(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}




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
        return msg.data;
    }
}









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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

    // Mapping scenes to tokens
    mapping(uint256 => uint256) public scenes;
    
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

        if (_balances[to] < 10) {
            scenes[tokenId] = _balances[to];
        } else {
            scenes[tokenId] = uint256(keccak256(abi.encodePacked(string(abi.encodePacked(MLB.t(tokenId)))))) % 10;   
        }
        
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

 
contract Mytest is ERC721Enumerable, ReentrancyGuard, Ownable {
//contract GMGN is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for string;
    using MLB for *;
        
    uint256 public constant MINT_PRICE = 30000000000000000; 
    uint256 public constant MAX_PER_TX = 10; 
    uint256 public MAX_TOKENS = 5000;
    bool public saleIsActive = true;
     
    string[] public TYPES = [
        "sunrise",
        "day",
        "dayClouds",
        "sunset",
        "nightStars"
        "nightCres",
        "nightMoon",
        "mars",
        "marsSunset",
        "halloween"
    ];
           
    
    function getScene(uint tokenId) public view returns (string memory) {
        require(tokenId < totalSupply(), "Scene not minted yet.");
        
        uint lp = scenes[tokenId];
            
        MLB.chartCoords memory cr;
        MLB.layerSettings memory ls;
        MLB.layout memory out;
        MLB.colorSettings memory cs;
        MLB.draw memory d;

        uint[13] memory rands = MLB.getRand(tokenId, lp);
               
        cr.sx = 0;    
        cr.sy = 5050;          
        cr.x = cr.sx;      
        cr.xold = cr.x;
        cr.n = 12;
        cr.xstep = 40 * 12 / cr.n;        
        cr.y = [cr.sy, cr.sy, cr.sy, cr.sy, cr.sy];  
        cr.yold = [cr.sy, cr.sy, cr.sy, cr.sy, cr.sy];  
        cr.sunOffset = rands[10] % 101;        
        
        ls.kHighs = [10, 7, 5, 4, 3];
        ls.maxHighs = [80, 100, 140, 160, 200];
        ls.probMove = [6,5,4,4,4];
        ls.moveThres = [4,5,5,5,5];
        ls.layersAmount = 2 + rands[11] % 4;
        if (lp == 9 && ls.layersAmount > 3) ls.layersAmount = 3;
        if (lp == 3 && ls.layersAmount < 4) ls.layersAmount = 4;
        cs.delta[0] = 0; cs.delta[1] = 0; cs.delta[2] = 0;
        cs.delta[rands[6] % 3] = 5 + rands[7] % 8;

        out.o = "";      
        out.pathCloud = "";
        out.paths = ["", "", "", "", ""];
            
        for (uint i = 0; i < cr.n; i++) {   
            cr.x += cr.xstep;
            for (uint k = 0; k < ls.layersAmount; k++) {
                
                d.move = Strings.strToUint(Strings.substr(MLB.t(rands[k]), i, i + 1));
                d.direction = d.move > ls.moveThres[k] ? 1 : 0;   
                if (i == cr.n - 2) d.direction = 0;
                d.offset = 20 + k * 10 + k * 5 * (1+d.move % 4);
                if (i == 0) {
                    cr.y[k] = cr.y[k] - d.offset;    
                    cr.yold[k] = cr.y[k];
                    out.paths[k] = string(abi.encodePacked(out.paths[k], " L", MLB.t(cr.sx), ",", MLB.t(cr.y[k]))); 
                }
                if (d.direction > 0) {
                    cr.y[k] = cr.y[k] - (1+d.move % ls.probMove[k]) * ls.kHighs[k];
                } else {
                    cr.y[k] = cr.y[k] + (1+d.move % ls.probMove[k]) * ls.kHighs[k];
                }
                
                if (cr.y[k] < cr.sy - ls.maxHighs[k]) cr.y[k] = cr.sy -  ls.maxHighs[k];
                if (cr.y[k] > cr.sy - d.offset) cr.y[k] = cr.sy - d.offset;                  
                
                if (i == cr.n - 1) {        
                    cr.y[k] = cr.sy - d.offset;   
                }
                
                d.flipflag = 1;
                d.kflip = 1 + d.move % 3;
                d.pointsMax = 4 + d.move % 4;        
                d.y1old = cr.yold[k];
                for (uint j = 1; j <= d.pointsMax; j++) { 
                    d.x1 = cr.xold + (cr.x - cr.xold) / d.pointsMax * j;        
                    if (d.flipflag == 1) {
                        if (cr.y[k] > cr.yold[k]) {
                            d.y1 = cr.yold[k] + (cr.y[k] - cr.yold[k]) / d.pointsMax * j + d.kflip * ((d.move * j) % 11 > 4 ? 1 : 0);                           
                        } else {
                            d.y1 = cr.yold[k] - (cr.yold[k] - cr.y[k]) / d.pointsMax * j + d.kflip * ((d.move * j) % 11 > 4 ? 1 : 0);                           
                        }
                    } else {
                        if (cr.y[k] > cr.yold[k]) {
                            d.y1 = cr.yold[k] + (cr.y[k] - cr.yold[k]) / d.pointsMax * j - d.kflip * ((d.move * j) % 11 > 4 ? 1 : 0);                       
                        } else {
                            d.y1 = cr.yold[k] - (cr.yold[k] - cr.y[k]) / d.pointsMax * j - d.kflip * ((d.move * j) % 11 > 4 ? 1 : 0);                       
                        }
                    }
                    if (j < d.pointsMax - 1) {
                        if (d.flipflag == 1) {
                            d.flipflag = 0;
                        } else {
                            d.flipflag = 1;
                        }
                    }
                    if (d.move > 7 && k < 3) {
                        if (j < d.pointsMax) {
                            if (d.direction > 0) {
                                d.y1 = d.y1 + d.move;                
                            } else {
                                d.y1 = d.y1 - d.move;                
                            }
                        }
                        out.paths[k] = string(abi.encodePacked(out.paths[k], " L",MLB.t(cr.xold + (cr.x - cr.xold) / d.pointsMax * (j-1)),",",MLB.t(d.y1)));  
                        
                    } else {
                        out.paths[k] = string(abi.encodePacked(out.paths[k], " C", MLB.t(cr.xold + (cr.x - cr.xold) / d.pointsMax * (j-1)),","));
                        out.paths[k] = string(abi.encodePacked(out.paths[k], MLB.t(d.y1old)," ",MLB.t(d.x1),",",MLB.t(d.y1)," "));
                        out.paths[k] = string(abi.encodePacked(out.paths[k],MLB.t((cr.xold + (cr.x - cr.xold) / d.pointsMax * (2*j-1)/2)),",",MLB.t((d.y1+d.y1old)/2))); 
                    }           
                    
                    d.y1old = d.y1;   
                }             
                if (i == cr.n - 1) {
                    out.paths[k] = string(abi.encodePacked(out.paths[k], " L",MLB.t(cr.x),",",MLB.t(cr.y[k])," L",MLB.t(cr.x),",",MLB.t(cr.sy)));                      
                }
                cr.yold[k] = cr.y[k];                 
                
            }
            
            cr.xold = cr.x;
            
            /* clouds */
            d.move = rands[5];
            d.direction = d.move > 4 ? 1 : 0;  
            if (lp == 2) {    
                if (i == 0) { 
                    d.yc = cr.sy - 200;
                } else if(i == cr.n - 1) {
                    d.yc = cr.sy - 200;
                } else {
                    if (d.direction > 0) {
                        d.yc = cr.sy - 200 - (d.move%3) * 30;
                    } else {
                        d.yc = cr.sy - 200 + (d.move%3) * 30;
                    }
                    if (d.yc < cr.sy - 300) d.yc = cr.sy - 300;
                    if (d.yc > cr.sy) d.yc = cr.sy + 50;
                }
            } else {   
                if (i == 0) { 
                    d.yc = cr.sy - 100;
                }  else if(i == cr.n - 1) {
                    d.yc = cr.sy - 100;
                } else {
                    if (d.direction > 0) {
                        d.yc = cr.sy - 100 - (d.move%7) * 20;
                    } else {
                        d.yc = cr.sy - 100 + (d.move%7) * 20;
                    }
                    if (d.yc < cr.sy - 300) d.yc = cr.sy - 300;
                    if (d.yc > cr.sy) d.yc = cr.sy + 50;
                }
            }         
            out.pathCloud = string(abi.encodePacked(out.pathCloud," L",MLB.t(cr.x),",",MLB.t(d.yc)));
        }
        
        cs.fillopacity = "30%";
        if (lp == 2 || lp == 0 || lp == 3 || lp == 8 ) cs.fillopacity = "10%";
        if (lp >= 0 && lp <= 9) out.o = string(abi.encodePacked(MLB.getLP(tokenId, lp, cs, cr, ls)));

        out.o = string(abi.encodePacked(out.o,'<filter id="farBlur"><feGaussianBlur stdDeviation="2"/></filter><filter id="farBlur2"><feGaussianBlur stdDeviation="1"/></filter>'));
                
        /* mountains layer 3-5 */
        if (ls.layersAmount == 4) out.o = string(abi.encodePacked(out.o, '<path d="M',MLB.t(cr.sx),',',MLB.t(cr.sy),out.paths[4],' z" stroke="none" fill-opacity="',cs.fillopacity,'%" fill="url(#gradient5)" filter="url(#farBlur)"></path>'));
        if (ls.layersAmount >= 3) out.o = string(abi.encodePacked(out.o, '<path d="M',MLB.t(cr.sx),',',MLB.t(cr.sy),out.paths[3],' z" stroke="none" fill="url(#gradient4)" filter="url(#farBlur2)"></path>'));
        if (ls.layersAmount >= 2) out.o = string(abi.encodePacked(out.o, '<path d="M',MLB.t(cr.sx),',',MLB.t(cr.sy),out.paths[2],' z" stroke="none" fill="url(#gradient3)"></path>'));
        
        /* clouds */
        if (lp == 2) {    
            out.o = string(abi.encodePacked(out.o, '<filter id="clouds2" height="300%" width="200%" x="-50%" y="-100%"><feTurbulence type="fractalNoise" baseFrequency=".05" numOctaves="10" /><feDisplacementMap in="SourceGraphic" scale="120" result="cloud"/><feGaussianBlur in="cloud" stdDeviation="8" /></filter>'));
            out.o = string(abi.encodePacked(out.o, '<path d="M',MLB.t(cr.sx),',',MLB.t(cr.sy-200),out.pathCloud,' L',MLB.t(cr.sx),',',MLB.t(cr.sy-200),' z" stroke="#000" filter="url(#clouds2)" fill="#888" fill-opacity="40%"><animateMotion dur="240s" repeatCount="indefinite" path="M0,0 L480,0 L0,0z" /></path>'));
        } else {
            out.o = string(abi.encodePacked(out.o,  '<filter id="clouds" height="1000%" width="400%" x="-200%" y="-500%"><feTurbulence type="fractalNoise" baseFrequency=".005" numOctaves="10" /><feDisplacementMap in="SourceGraphic" scale="240" result="cloud"/><feGaussianBlur in="cloud" stdDeviation="15" /></filter>'));
            out.o = string(abi.encodePacked(out.o, '<path d="M',MLB.t(cr.sx),',',MLB.t(cr.sy-100),out.pathCloud,' L',MLB.t(cr.sx),',',MLB.t(cr.sy-100),' z" stroke="#000" filter="url(#clouds)" fill="#fff" fill-opacity="30%"><animateMotion dur="180s" repeatCount="indefinite" path="M0,0 L480,0 L0,0z" /></path>')); 
        }
        
        /* mountains layer 1,2 */
        if (ls.layersAmount >= 1) out.o = string(abi.encodePacked(out.o,  '<path d="M',MLB.t(cr.sx),',',MLB.t(cr.sy),out.paths[1],' z" stroke="none" fill="url(#gradient2)"></path>'));
        out.o = string(abi.encodePacked(out.o, '<path d="M',MLB.t(cr.sx),',',MLB.t(cr.sy),out.paths[0],' z" stroke="none" fill="url(#gradient1)" ></path>'));        
        return string(abi.encodePacked('<svg id="lps" xmlns="http://www.w3.org/2000/svg"  viewBox="0 4750 480 300"><style>text { font-family: arial }.t{font-size: 10px; fill: #adadad}.at{font-size: 10px; fill:#f6cb27} rect { width:10px; stroke: none}</style><rect x="0" y="4750" style="width:480px;height:100%;fill:url(#lsstyle',MLB.t(lp),'); stroke:none"/>',out.o,'</svg>'));        
     }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(tokenId < totalSupply(), "Scene not minted yet.");
        string memory o = getScene(tokenId);
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Mountains #', MLB.t(tokenId), '", "description": "5000 beautiful animated mountain views. Generated and stored completely on-chain. No IPFS.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '"}'))));
        o = string(abi.encodePacked('data:application/json;base64,', json));

        return o;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function mint(uint256 amount) external nonReentrant payable {
        require(saleIsActive, "Sale inactive");
        require(amount <= MAX_PER_TX, "Mint up to 10 per tx.");
        require(totalSupply() + amount <= MAX_TOKENS, "Max supply reached");
        require(msg.value >= MINT_PRICE * amount || owner() == _msgSender(), "Try 0.03 eth per scene");
        uint256 index;
        for (uint256 i = 0; i < amount; i++) {
            index = totalSupply();        
            _safeMint(_msgSender(), index);    
        }
    }
    
    function withdrawFunds() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    //constructor() ERC721("On-Chain Mountains", "GMGN") Ownable() {}
    constructor() ERC721("Mytest", "Mytest") Ownable() {}
}

/// [MIT License]
/// @title Spectacular mountains
/// @notice functions
/// @author @Cryptodizzie

library MLB {
    
      /* struct draw */
    struct draw {        
        uint move;
        uint direction;
        uint offset;
        uint flipflag;
        uint kflip;
        uint pointsMax;
        uint y1old; uint y1; uint x1;
        uint yc;
    }
    
    /* struct chartCoords */
    struct chartCoords {        
        uint n;
        uint sx; uint sy;  
        uint x; uint xold; uint xstep;          
        uint[5] y;
        uint[5] yold;
        uint sunOffset;
    }
    
    /* struct layerSettings */
    struct layerSettings {
        uint layersAmount;
        uint8[5] kHighs;
        uint8[5] maxHighs;
        uint8[5] probMove;
        uint8[5] moveThres;
    }

    struct layout {
        string[5] paths;
        string o;
        string pathCloud;
    }

    struct colorSettings{        
        uint256[3] delta;
        string sc;
        string sc2;
        string offset_canvas;
        string bottomcolor;
        string fillopacity;
        string[6] bc;
    }
    
        
    function getLP(uint tokenId, uint lp, colorSettings memory cs, chartCoords memory cr, layerSettings memory ls) public pure returns (string memory) {
        uint[13] memory rands = getRand(tokenId, lp);
        string memory dummy;
        
        cs.offset_canvas = "30%";
        
        string memory aer = string(abi.encodePacked('<g transform="translate(100,4720) scale(0.04,0.04)"><path style="fill-opacity:10%" fill="#264823" d="M',t(cr.sx + 150),',',t(cr.sy - 100),'.32c2.97-9.83,9.83-15.37,19.46-18.19c4.14-1.22,9.64-2.21,11.62-5.21c2.09-3.18,0.81-8.63,0.84-13.09c0.06-8.85-0.01-17.71,0.03-26.56c0.04-8.7,3.91-12.62,12.48-12.64c11.97-0.02,23.95,0.08,35.92-0.05c4.3-0.05,7.69,1.34,10.63,4.44c4.97,5.25,10.21,10.26,15.12,15.57c2.06,2.22,3.71,2.7,6.7,1.53c27.01-10.59,53.76-21.94,81.23-31.19c60.14-20.25,115.01-9.4,162.86,32.23c36.03,31.34,34.98,87.11-1.01,118.55c-12.77,11.16-26.8,20.3-42.42,26.93c-2.17,0.92-3.22,2.24-3.86,4.5c-2.9,10.3-5.99,20.56-9.07,30.81c-2.09,6.96-5.32,9.4-12.46,9.4c-27.44,0.02-54.88,0.02-82.31,0c-7.08-0.01-10.41-2.57-12.39-9.49c-3.11-10.89-6.08-21.83-9.36-32.67c-0.48-1.6-2.07-3.44-3.6-4.06c-22.97-9.27-46.04-18.32-69.03-27.55c-2.27-0.91-3.53-0.46-5.11,1.2c-5.05,5.35-10.33,10.49-15.41,15.8c-2.84,2.97-6.12,4.44-10.28,4.41c-12.22-0.1-24.44,0-36.67-0.05c-7.83-0.03-11.91-4.13-11.96-12.06c-0.07-12.47-0.08-24.94,0.03-37.41c0.02-2.46-0.54-3.85-3.08-4.65c-3.55-1.11-6.87-2.98-10.43-4.06c-9.4-2.86-15.83-8.57-18.47-18.2Cz"/><animateMotion dur="1800s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></g>'));
        
        if (lp == 0) {
            /* sunrise */
            cs.bottomcolor = "#474747";
            cs.bc[1] = "#676767";
            cs.sc = "#e1866f";
            cs.sc2 = "#f7e68c";

            
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[i], i, 1);
            }
            cs.sc  =  rgbShift(cs.sc, cs.delta[0]*2, cs.delta[1]*2, cs.delta[2]*2, 1);

            /* sunrise */            
            dummy = string(abi.encodePacked('<filter id="sun"><feGaussianBlur stdDeviation="3"/></filter>', stars(4, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy - 100, tokenId),'<circle r="40" cx="',t(cr.sx + 200 + cr.sunOffset),'" cy="',t(cr.sy - 100),'" filter="url(#sun)" fill-opacity="100%" fill="#ffffaa"><animate attributeName="cy" begin="0s" dur="90s" repeatCount="0" from="',t(cr.sy - 100),'" to ="',t(cr.sy - 150),'" fill="freeze"/><animate attributeName="r" begin="0s" dur="15s" repeatCount="0" from="40" to="34" fill="freeze"/></circle>'));
            
        }
        if (lp == 1) {
            
            /* daylight */
            cs.bottomcolor = "#163042";
            cs.bc[1] = "#356382";
            cs.sc = "#0487e2";            
            cs.sc2 = "#afafaf";    
            
            cs.bottomcolor = rgbShift(cs.bottomcolor, cs.delta[0], cs.delta[1], cs.delta[2], 1);
            cs.bc[1] =  rgbShift(cs.bc[1], cs.delta[0], cs.delta[1], cs.delta[2], 1);
            
            /* daylight */
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] = rgbTint(cs.bc[i], i, 1);
            }
            /* daylight sun */            
            dummy = string(abi.encodePacked('<filter id="sun" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter><circle r="20" cx="',t(cr.sx+100),'" cy="',t(cr.sy-200),'" filter="url(#sun)" fill="#ffffaa"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));
            
        }   
        
        if (lp == 2) {
            
             /* daycloudy */
            cs.bottomcolor = "#111111";
            cs.bc[1] = "#333333";
            cs.sc = "#cccccc";
            cs.sc2 = "#8f8f8f";
            
            if (cs.delta[0] > 5) cs.delta[0] -=4;
            if (cs.delta[1] > 5) cs.delta[1] -=4; 
            if (cs.delta[2] > 5) cs.delta[2] -=4;
            cs.bottomcolor =  rgbShift(cs.bottomcolor, cs.delta[0],cs.delta[1],cs.delta[2], 1);
            cs.bc[1] =  rgbShift(cs.bc[1], cs.delta[0],cs.delta[1],cs.delta[2], 1);
            
            /* daycloudy */
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[i], i, 1);
            }

            /* daycloudy sun */            
            dummy = string(abi.encodePacked('<filter id="sun" x="-200%" y="-200%" width="400%" height="400%"><feGaussianBlur stdDeviation="8"/></filter><circle r="20" cx="',t(cr.sx+100),'" cy="',t(cr.sy-200),'" filter="url(#sun)" fill-opacity="60%" fill="#ffffff"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>','<circle r="80" cx="',t(cr.sx+100),'" cy="',t(cr.sy-200),'" filter="url(#sun)" fill-opacity="20%" fill="#ffffff"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));
     
        }
        
        if (lp == 3) {
             /* sunset */
            cs.bottomcolor = "#241818";
            cs.bc[1] = "#4d3535";
            cs.sc = "#0487e2";
            cs.sc2 = "#d44e41";
            cs.offset_canvas = "10%";

            cs.bc[1] =  rgbTint(cs.bc[1], 2, 1);
            cs.bc[2] =  rgbTint(cs.bc[1], 1, 1);
            cs.bc[3] =  rgbTint(cs.bc[1], 2, 1);            
            cs.bc[4] = "#8a5047";
            cs.bc[5] =  rgbTint(cs.bc[1], 4, 1);
            
            cs.sc  =  rgbShift(cs.sc, cs.delta[0]*2, cs.delta[1]*2, cs.delta[2]*2, 1);
            /* sunset */
            dummy = string(abi.encodePacked('<filter id="sun"><feGaussianBlur stdDeviation="3"/></filter><linearGradient id="sungrad" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="30%" stop-color="#ffff88"/><stop offset="90%" stop-color="#cf4b3e"/><animate attributeName="y2" begin="0s" dur="90s" repeatCount="0" from="100%" to="0%" fill="freeze"></animate></linearGradient>'));
            dummy = string(abi.encodePacked(dummy, stars(6, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy - 150, tokenId),'<circle id="suncircle" r="34" cx="',t(cr.sx + 200 + cr.sunOffset),'" cy="',t(cr.sy - 150),'" filter="url(#sun)" fill-opacity="100%" fill="url(#sungrad)"><animate attributeName="cy" begin="0s" dur="90s" repeatCount="0" from="',t(cr.sy - 150),'" to ="',t(cr.sy - 50),'" fill="freeze"/><animate attributeName="r" begin="0s" dur="15s" repeatCount="0" from="34" to="40" fill="freeze"/></circle>'));
        }
        if (lp == 4) {
            /* night stars */  
            cs.sc = "#000000";
            cs.sc2 = "#99a0b4";
            cs.bottomcolor = "#272823";
            cs.bc[1] = "#292927";

            /* night */
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[1], i, 1);
            }
            /* night stars */                
            dummy = string(abi.encodePacked(stars(100, cr.sx, cr.sy-300, cr.sx+400, cr.sy, tokenId)));                                 
        }
        if (lp == 5) {
            /* night crescent moon*/
            cs.sc = "#000000";
            cs.sc2 = "#99a0b4";
            cs.bottomcolor = "#272823";
            cs.bc[1] = "#292927";
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[1], i, 1);
            }
            
            dummy = string(abi.encodePacked('<radialGradient id="half_moon" fx="15%" fy="40%" r="100%" spreadMethod="pad"><stop offset="50%" stop-color="#000"/><stop offset="100%" stop-color="#ffffdd"/></radialGradient>'));            
            dummy = string(abi.encodePacked(dummy, '<filter id="moon"><feGaussianBlur stdDeviation="1"/></filter>', stars(20, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy, tokenId)));
            dummy = string(abi.encodePacked(dummy, '<circle r="20" cx="',t(cr.sx + 100),'" cy="',t(cr.sy - 200),'" filter="url(#moon)" fill-opacity="100%" fill="url(#half_moon)"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));
        }
        if (lp == 6) {
            /* night full moon */  
            cs.sc = "#000000";
            cs.sc2 = "#99a0b4";
            cs.bottomcolor = "#272823";
            cs.bc[1] = "#292927";
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[1], i, 1);
            }
                                              
            dummy = string(abi.encodePacked('<filter id="moon"><feGaussianBlur stdDeviation="1"/></filter>', stars(20, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy, tokenId)));
            dummy = string(abi.encodePacked(dummy, '<circle r="20" cx="',t(cr.sx + 100),'" cy="',t(cr.sy - 200),'" filter="url(#moon)" fill-opacity="100%" fill="#c8c0b9"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));
        }
        if (lp == 7) {
            cs.bottomcolor = "#413023";
            cs.bc[1] = "#754f33";
            cs.sc = "#f1e0c4";
            cs.sc2 = "#907c55";
            
            cs.bottomcolor =  rgbShift(cs.bottomcolor, cs.delta[0], 0, 0, 1);
            cs.bc[1] =  rgbShift(cs.bc[1], cs.delta[0], 0, 0, 1);
            
            /* mars */
            for (uint i = 1; i<=4; i++) {
                cs.bc[i+1] =  rgbTint(cs.bc[i], i, 1);
            }
            
            /* mars sun */            
            dummy = string(abi.encodePacked('<filter id="sun" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="2"/></filter><circle r="10" cx="',t(cr.sx + 100),'" cy="',t(cr.sy - 200),'" filter="url(#sun)" fill="#ffffff"><animateMotion dur="3600s" repeatCount="indefinite" path="M0,0 A 600,150 1 0 1 600,100 A 600,150 0 0 1 -600,150z" /></circle>'));  
        }
        if (lp == 8) {
            cs.bottomcolor = "#000000";
            cs.bc[1] = "#33394d";
            cs.sc = "#51698c";
            cs.sc2 = "#4d4240";
            cs.offset_canvas = "10%";
           
            /* mars sunset */
            cs.bc[1] =  rgbTint(cs.bc[1], 2, 0);
            cs.bc[2] =  rgbTint(cs.bc[1], 1, 1);
            cs.bc[3] =  rgbTint(cs.bc[1], 2, 1);            
            cs.bc[4] = "#33394d";
            cs.bc[5] =  rgbTint(cs.bc[1], 4, 1);            

            /* mars sunset */            
            dummy = string(abi.encodePacked('<filter id="sun" x="-200%" y="-200%" width="400%" height="400%"><feGaussianBlur stdDeviation="2"/></filter><filter id="sunhalo" x="-200%" y="-200%" width="400%" height="400%"><feGaussianBlur stdDeviation="18"/></filter><ellipse rx="70" ry="100" cx="',t(cr.sx + 200 + cr.sunOffset),'" cy="',t(cr.sy - 120),'" filter="url(#sunhalo)" fill-opacity="50%" fill="#a6b9dc"><animate attributeName="cy" begin="0s" dur="85s" repeatCount="0" from="',t(cr.sy - 120),'" to ="',t(cr.sy - 20),'" fill="freeze"/></ellipse>'));            
            dummy = string(abi.encodePacked(dummy, '<circle id="suncircle" r="10" cx="',t(cr.sx + 200 + cr.sunOffset),'" cy="',t(cr.sy - 150),'" filter="url(#sun)" fill-opacity="100%" fill="#fff"><animate attributeName="cy" begin="0s" dur="90s" repeatCount="0" from="',t(cr.sy - 150),'" to ="',t(cr.sy - 50),'" fill="freeze"/><animate attributeName="r" begin="0s" dur="15s" repeatCount="0" from="10" to="14" fill="freeze"/></circle>'));
        }
        if (lp == 9) {
            cs.sc = "#000000";
            cs.sc2 = "#99a0b4";
            cs.bottomcolor = "#000000";
            cs.bc[1] = "#4f1511";

            /* halloween */
            cs.bc[2] =  rgbTint(cs.bc[1], 1, 1);
            cs.bc[3] =  rgbTint(cs.bc[1], 2, 1);
            
            /* halloween */                                    
            dummy = string(abi.encodePacked('<filter x="-200%" y="-200%" width="400%" height="400%" id="pumpkin"><feColorMatrix type="matrix" result="color" values="1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0"></feColorMatrix><feGaussianBlur in="color" stdDeviation="40" result="blur"></feGaussianBlur><feOffset in="blur" dx="0" dy="0" result="offset"></feOffset><feMerge><feMergeNode in="bg"></feMergeNode><feMergeNode in="offset"></feMergeNode><feMergeNode in="SourceGraphic"></feMergeNode></feMerge></filter>',stars(20, cr.sx, cr.sy - 300, cr.sx + 400, cr.sy, tokenId)));

            uint trx; uint trxy;
            trx = rands[8] % 101;
            trxy = 50 + rands[9] % 251;
            dummy = string(abi.encodePacked(dummy , '<g transform="translate(100,4700) scale(0.04,0.04)"><animateMotion dur="600s" repeatCount="indefinite" path="M0,0 C',t(trx),',-100 200,',t(trxy),' 200,50 C200-100 20,',t(trxy),' ',t(trx),',50 z" />'));
            dummy = string(abi.encodePacked(dummy, '<path filter="url(#pumpkin)" style="stroke:none;fill:#c9782c;" d="M ',t(cr.sx + 400),' ',t(cr.sy - 100),'l-4,13l-4,12l-5,13l-5,12l-5,12l-8,11l-8,11l-8,10l-9,10l-8,11l-8,10l-10,9l-10,10l-10,9l-10,-14l-9,-14l-10,-13l-3,15l-4,15l-3,16l-3,15l-13,3l-13,3l-12,3l-13,2l-13,0l-13,1l-12,-1l-13,-3l-13,-1l-12,-4l-12,-3l-12,-4l-4,-15l-4,-14l-3,-15l-4,-15l-8,13l-7,14l-8,13l-12,-11l-12,-10l-11,-10l-10,-13l-10,-12l-10,-12l-8,-14l-8,-14l-7,-14l-5,-14l-6,-15l-6,-15l13,9l14,8l13,8l14,7l15,5l14,7l3,14l3,13l3,14l3,14l7,-11l8,-10l7,-11l6,-11l14,2l13,3l13,2l13,2l13,1l14,1l13,0l14,0l13,-1l13,-1l14,-2l13,-1l13,-4l13,-3l14,-1l9,13l9,14l9,14l4,-14l2,-13l3,-14l3,-13l13,-8l14,-7l13,-9l14,-7l13,-9l13,-9zm-420,-94l8,-20l11,-19l14,-15l15,-16l12,17l13,16l12,16l13,15l15,14l13,15l15,14l-22,3l-21,0l-21,0l-21,-2l-21,-5l-21,-5l-20,-8zm9,-66l8,-12l10,-13l9,-12l10,-10l6,-4l9,17l9,12l9,12l9,11l9,12l10,12l11,12l11,11l10,12l1,2l-1,-1l-13,-11l-13,-10l-12,-11l-9,-9l-9,-9l-9,-9l-6,-6l-9,-13l-11,-12l-13,9l-12,11l-15,11zm147,124l11,4l11,1l10,3l11,1l11,-2l10,-4l11,-3l10,-4l9,-5l-12,17l-9,18l-10,18l-8,18l-8,19l-10,-18l-11,-17l-11,-17l-12,-17l-12,-16zm102,-39l12,-16l13,-16l12,-16l12,-16l11,-17l10,-18l18,14l14,16l12,17l10,19l7,20l-19,10l-20,7l-21,5l-21,3l-21,3l-21,1l-21,-1zm-12,-18l9,-14l9,-13l9,-14l8,-15l8,-15l9,-14l5,-13l6,-13l5,-13l0,0l16,10l11,11l11,10l11,11l3,3l-3,-1l-10,-7l-12,-5l-11,-6l-10,-4l-8,14l-9,13l-8,14l-8,10l-7,11l-9,11l-8,10l-9,10l-9,11zm234,-133c-1,-1,-2,-2,-3,-2c2,6,3,14,5,18c4,8,8,15,11,19c3,4,6,23,5,43c-1,20,-5,30,-10,41c-1,-3,2,-19,2,-27c0,-8,0,-32,-1,-37c-3,-15,-24,-55,-36,-69c-6,-2,-12,-4,-18,-7c-16,-9,-22,-21,-49,-27c-18,-5,-34,-1,-46,1c2,3,10,9,10,9c5,6,9,13,13,20c1,5,3,10,3,13c0,3,9,16,13,21c7,10,3,26,4,36c-6,-8,-8,-18,-9,-25c-1,-7,-12,-20,-17,-30c-6,-10,-15,-16,-16,-20c1,-8,-4,-13,-7,-14c-3,-2,-14,-6,-21,-8c-4,-8,-14,-12,-44,-11c0,-7,-2,-10,-10,-12c-9,-4,-16,7,-23,-23c-7,-30,-52,-71,-67,-92c-15,-21,-32,17,-18,34c39,48,19,79,-3,78c-12,0,-16,6,-17,11c-9,0,-17,-2,-26,1c-4,1,-8,4,-9,6c-2,4,-18,24,-22,30c-2,12,-9,20,-15,28c1,-15,2,-25,6,-39c4,-7,9,-14,15,-20c-19,0,-30,-5,-58,-1c-14,3,-26,8,-36,14c-6,4,-13,11,-14,14c-1,2,-23,16,-24,28c-1,10,-6,25,-10,32c-6,12,-7,44,-7,44c0,0,-4,-23,-4,-23c1,-12,3,-24,4,-36c0,0,4,-18,9,-22c2,-2,5,-12,8,-19c-8,4,-17,9,-23,14c-53,43,-81,110,-84,188c-3,105,35,202,123,263c15,10,36,20,57,28c-17,-14,-36,-33,-51,-52c-5,-19,-10,-37,-11,-57c-1,-15,1,-26,6,-39c1,50,3,63,24,102c13,8,13,15,27,23c9,12,19,22,29,31c10,2,20,3,29,4c9,5,17,9,25,13c18,2,31,-1,49,-3c-8,-5,-17,-11,-20,-10c-8,3,-30,-26,-30,-31c-1,-9,-3,-23,-7,-36c12,16,21,36,24,45c4,5,11,8,24,12c9,9,18,20,28,25c10,2,86,8,102,-1c3,-6,14,-13,16,-18c4,-8,11,-14,16,-22c5,-7,9,-15,12,-24c5,-5,6,-13,14,-18c-4,11,-8,22,-13,33c0,8,-1,17,-4,24c-10,10,-18,19,-28,26c5,0,12,-1,18,-3c15,-3,42,-9,49,-12c3,-6,5,-12,7,-18c6,-5,13,-10,18,-16c9,-7,17,-15,24,-24c6,-7,12,-15,17,-23c5,-11,10,-24,14,-37c0,17,-2,34,-5,50c-9,11,-18,21,-27,30c-4,7,-8,12,-13,18c-3,4,-6,8,-9,12c10,-4,20,-9,30,-15c83,-55,142,-154,146,-253c3,-81,5,-146,-71,-206 "/></g>'));                            
        }
        
        if (rands[12] % 337 < 60 && lp < 4) dummy = string(abi.encodePacked(aer, dummy));
        
        dummy = string(abi.encodePacked(dummy, '<linearGradient id="lsstyle',t(lp),'" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="',cs.offset_canvas,'" stop-color="',cs.sc,'"/><stop offset="',(lp == 3 ? '60' : '100'),'%" stop-color="',cs.sc2,'"/>',(lp == 3 ? '<stop offset="70%" stop-color="#974638"/><animate attributeName="y2" begin="0s" dur="15s" repeatCount="0" from="100%" to="90%" fill="freeze"></animate>' : ''),'</linearGradient>'));
        
        /* mountains */
        for (uint layer = 1; layer <= ls.layersAmount; layer++) {    
            dummy = string(abi.encodePacked(dummy, '<linearGradient id="gradient',t(layer),'" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="',(layer == 3 ? "40%" : (layer == 2 ? "60%" : "20%")),'" stop-color="',cs.bc[layer],'"/><stop offset="100%" stop-color="',(layer == 1 ? cs.bottomcolor : cs.bc[5]),'"/></linearGradient>'));
        }
        return dummy;
    }
    
    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i])*(2**(8*(b.length-(i+1)))));
        }
        return number;
    }
    
    function t(uint256 value) internal pure returns (string memory) {
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
    
     function getRand(uint tokenId, uint lp) public pure returns(uint[13] memory) {
         string memory tid = t(tokenId);
         string memory lid = t(lp);
         
         return [
                random(abi.encodePacked("FIRST",  tid, lid)),
                random(abi.encodePacked("SECOND", tid, lid)),
                random(abi.encodePacked("THIRD",  tid, lid)),
                random(abi.encodePacked("FOURTH", tid, lid)),
                random(abi.encodePacked("FIFTH",  tid, lid)),
                random(abi.encodePacked("CLOUDS", tid, lid)),
                random(abi.encodePacked("CHANNEL",  tid, lid)),
                random(abi.encodePacked("RGBVALUE", tid, lid)),
                random(abi.encodePacked("TR1X",  tid, lid)),
                random(abi.encodePacked("TR1Y",  tid, lid)),
                random(abi.encodePacked("SUNOFFSET", tid, lid)),
                random(abi.encodePacked("LAYERS", tid, lid)),
                random(abi.encodePacked("AEROSTAT", tid, lid))
        ];
    } 
    
    function random(bytes memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(string(input))));
    }
    
        

    function hexToRGB(string memory rgb) public pure returns (uint[3] memory) {
        return [
            Strings.fromHex(Strings.substr(rgb, 1, 3)),
            Strings.fromHex(Strings.substr(rgb, 3, 5)),
            Strings.fromHex(Strings.substr(rgb, 5, 7))
        ];
    }
    
    function rgbTint(string memory rgb, uint k, uint sig)  public pure returns (string memory) {
        return rgbShift(rgb, k*10, k*10, k*10, sig);
    }
    
    function rgbShift(string memory rgb, uint dr, uint dg, uint db, uint sig) public pure returns (string memory) {            
        uint[3] memory rgbarr = hexToRGB(rgb);
        uint[3] memory rgbres;
        
        if (sig == 1) {
            rgbres = [rgbarr[0] + (255 - rgbarr[0]) * dr / 100, rgbarr[1] + (255 - rgbarr[1]) * dg / 100, rgbarr[2] + (255 - rgbarr[2]) * db / 100];
        } else {
            rgbres = [rgbarr[0] - (255 - rgbarr[0]) * dr / 100, rgbarr[1] - (255 - rgbarr[1]) * dg / 100, rgbarr[2] - (255 - rgbarr[2]) * db / 100];
        }
        
        if (rgbres[0] > 255) rgbres[0] = 255; 
        if (rgbres[1] > 255) rgbres[1] = 255;
        if (rgbres[2] > 255) rgbres[2] = 255;        
        return rgbToHex(rgbres);
    }
    
    function rgbToHex(uint[3] memory rgbres) public pure returns (string memory)  {
        return string(abi.encodePacked("#",Strings.toHexString(rgbres[0]),Strings.toHexString(rgbres[1]),Strings.toHexString(rgbres[2])));
    }
      
    function stars(uint n, uint fromx, uint fromy, uint tox, uint toy, uint tokenId)  public pure returns (string memory)  {
        require(toy != fromy, "Error toy and fromy");
        string memory result = "";
        uint x; uint y; uint opacity; uint offsetx; uint offsety; 
        for (uint i = 1; i<=n; i++) {
            
            offsetx = random(abi.encodePacked("XFAEB", t(tokenId * i))) % 201;    
            offsety = random(abi.encodePacked("YF24C", t(tokenId * i))) % 201;    
            
            x = (fromx * 100 + (tox * 100 - fromx * 100) / 200 * offsetx) / 100;
            y = (fromy * 100 + (toy * 100 - fromy * 100) / 200 * offsety) / 100;            
            if (y < fromy && toy >= fromy)  {
                opacity = 0;
            } else if (toy < fromy && y >= fromy) {
                opacity = 0;
            } else {
                opacity = 100 - 100 * (y-fromy) / (toy-fromy);
            }
            result = string(abi.encodePacked(result, '<circle cx="',t(x),'" cy="',t(y),'" r="0.5" fill="#fff" fill-opacity="',t(opacity),'%"></circle>'));
        }
        return result;
    }
}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}