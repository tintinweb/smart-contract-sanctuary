/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// contract with transaction func
library SafeMath 
{
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
    
    // Token URI
   //string private _tokenURI;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    struct nftdeails
    {
        string mintname;
        uint256 timeofmint;
        string nftowner;
        string description;
        uint256 copies;
    }
    
    mapping(uint256 => nftdeails) nftinfo;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    //     string memory baseURI = _baseURI();
    //     return bytes(baseURI).length > 0
    //         ? string(abi.encodePacked(baseURI, tokenId.toString()))
    //         : '';
    // }

    // /**
    //  * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    //  * token will be the concatenation of the `baseURI` and the `tokenId`. Empty 
    //  * by default, can be overriden in child contracts.
    //  */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    
    
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    
    
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
     
     
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
            
    function mint(address to, uint256 tokenId,string memory _tokenURI,string memory _mintname,uint256 _timeperiod,string memory _nftowner,uint256 _copies,string memory description) internal 
    {
        _mint(to,tokenId);
        _setTokenURI(tokenId, _tokenURI);
        nftinfo[tokenId].mintname = _mintname;
        nftinfo[tokenId].timeofmint = _timeperiod;
        nftinfo[tokenId].nftowner = _nftowner;
        nftinfo[tokenId].copies = _copies;
        nftinfo[tokenId].description = description;
        
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual 
    {
        //require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


contract MyToken is ERC721{
    
    using SafeMath for uint256;
    address devwallet = address(0x6a17a6BE25b2BBBD3F6DCe4444ffC016aeC77FC3);
    //address token = address(0xfC713AAB72F97671bADcb14669248C4e922fe2Bb);
    //0x6a17a6BE25b2BBBD3F6DCe4444ffC016aeC77FC3
    //0xcf02a6293aeF1B5684aF8b0E73C5c5B2b92C6f7f
    struct collectioninfo
    {
        address collectionowner;
        bytes Cname;
        bytes Dname;
        bytes websiteURL;
        bytes description;
        bytes imghash;
        uint256 marketfees;
    }
    
    struct auction
    {
        uint256 time;
        uint256 minprice;
        bool inlist;
        uint256 biddingamount;
        
    }
    
    struct fixedsale
    {
         uint256 price;
         bool inlist;
    }
    
    uint256 public tokenidmint;
    uint256 public collectionform;
    uint256 csdogefees = 2; 
    address owner;
    mapping(uint256 => fixedsale) nftprice; 
    mapping(uint256 => uint256 []) public collectionstored;
    mapping(uint256 =>collectioninfo) collection;
    mapping(address => uint256 []) public userinfo;
    mapping(address => uint256) public totalcollection;
    mapping(uint256=>uint256) public totalnft;
    uint256 []  salenft;
    uint256 [] auctionnft;
    mapping(uint256=>uint256) public salenftlist;
    mapping(uint256=>uint256) public auctionnftlist;
    mapping(uint256=>mapping(uint256=>uint256)) idnumber;
    mapping(uint256 =>auction) timeforauction;
    mapping(uint256 =>mapping(address => uint256)) amountforauction;
    mapping(uint256 => uint256) public nftcollectionid;
    mapping(uint256 => address) finalowner;
    mapping(string => bool) stopduplicate;
    uint256 [] csdoge; 
    mapping(uint256=>uint256) csdogenumber;
    mapping(uint256 => bool) public csdogechoice;
    mapping(uint256 => uint256) csdogenftcopies;
    mapping(uint256 => uint256) totalcsdogecopies;
    
     
     
    constructor(string memory name_, string memory symbol_,address _owner) ERC721(name_, symbol_) 
    {
       owner = _owner;
       collectionform+=1;
       collection[collectionform].collectionowner = devwallet;
       collection[collectionform].Cname = bytes('csdoge');
       collection[collectionform].Dname = bytes('csdoge');
       collection[collectionform].websiteURL = bytes('csdoge');
       collection[collectionform].description = bytes('csdoge');
       collection[collectionform].imghash = bytes('csdoge');
       collection[collectionform].marketfees = 1;
       userinfo[devwallet].push(collectionform);
       totalcollection[devwallet]=collectionform;
       stopduplicate['csdoge']=true;
    }
    
    function create(uint256 collectionid,address to,string memory _tokenURI,string memory _mintname,string memory _nftowner,uint256 _copies,string memory description,bool copy) public 
    {
        if(!copy)
        {
           require(!stopduplicate[_tokenURI],"value not allowed");   
        }
        tokenidmint+=1;
        uint256 timeperiod = block.timestamp;
        collectionstored[collectionid].push(tokenidmint);
        totalnft[collectionid]+=1;
        idnumber[collectionid][tokenidmint]=totalnft[collectionid]-1;
        nftcollectionid[tokenidmint]=collectionid;
        mint(to,tokenidmint,_tokenURI,_mintname,timeperiod,_nftowner,_copies,description);
        stopduplicate[_tokenURI]=true;
    }
    
    function createcsdoge(uint256 collectionid,address to,string memory _tokenURI,string memory _mintname,string memory _nftowner,string memory description,uint256 copies) public 
    {
        require(msg.sender == devwallet,"not devwallet");
        require(!stopduplicate[_tokenURI],"value not allowed");
        tokenidmint+=1;
        uint256 timeperiod = block.timestamp;
        collectionstored[collectionid].push(tokenidmint);
        totalnft[collectionid]+=1;
        idnumber[collectionid][tokenidmint]=totalnft[collectionid]-1;
        nftcollectionid[tokenidmint]=collectionid;
        mint(to,tokenidmint,_tokenURI,_mintname,timeperiod,_nftowner,1,description);
        stopduplicate[_tokenURI]=true;
        csdogenumber[tokenidmint]=csdoge.length;
        csdoge.push(tokenidmint);
        csdogenftcopies[tokenidmint] = copies;
        totalcsdogecopies[tokenidmint] = copies;
    }
    
    function createcollection(string memory _Cname,string memory _Dname,string memory _wensiteURL,string memory _description,string memory _imghash,uint256 _marketfee) public 
    {
        require(!stopduplicate[_imghash],"value not allowed");
        collectionform+=1;
        collection[collectionform].collectionowner = msg.sender;
        collection[collectionform].Cname = bytes(_Cname);
        collection[collectionform].Dname = bytes(_Dname);
        collection[collectionform].websiteURL = bytes(_wensiteURL);
        collection[collectionform].description = bytes(_description);
        collection[collectionform].imghash = bytes(_imghash);
        collection[collectionform].marketfees = _marketfee;
        userinfo[msg.sender].push(collectionform);
        totalcollection[msg.sender]=collectionform;
        stopduplicate[_imghash]=true;
    }
    
    function collectiondetails(uint256 id) public view returns(uint256,address,string memory,string memory,string memory,string memory,string memory,uint256)
    {
        string memory Cname  = string(collection[id].Cname);  
        string memory Dname  = string(collection[id].Dname);  
        string memory URL  = string(collection[id].websiteURL);  
        string memory description  = string(collection[id].description);  
        string memory imghash  = string(collection[id].imghash);  
        uint256 value = id;
        uint256 fees = collection[value].marketfees;
        address collectionowners =  collection[value].collectionowner;
        return (value,collectionowners,Cname,Dname,URL,description,imghash,fees);
    }
    
    function nftinformation(uint256 id) public view returns(uint256,string memory,uint256,string memory,uint256,string memory,string memory,uint256,address)
    {
        uint256 value = id;
        return (id,nftinfo[id].mintname,nftinfo[id].timeofmint,nftinfo[id].nftowner,nftinfo[value].copies,nftinfo[value].description,tokenURI(value),nftcollectionid[value],ownerOf(value));
    }
    
    function fixedsales(uint256 tokenid,uint256 price,bool csdogeb) public
    {
        require(!timeforauction[tokenid].inlist,"already in sale");
        require(!nftprice[tokenid].inlist,"already in sale");
        require(ownerOf(tokenid) == msg.sender,"You are not owner");
        nftprice[tokenid].price  = price;
        nftprice[tokenid].inlist = true;
        salenftlist[tokenid]     = salenft.length;
        salenft.push(tokenid);
        address firstowner = ownerOf(tokenid);
        transferFrom(firstowner,address(this), tokenid);
        csdogechoice[tokenid] = csdogeb;
    }
        
    function buynft(uint256 _collectionid,uint256 tokenid,address token) public payable
    {
        uint256 val = uint256(100)-csdogefees;
       
        if(csdogechoice[tokenid])
        {
            uint256 totalamount = nftprice[tokenid].price;
            uint256 amount   = (totalamount*uint256(val)/uint256(100));
            uint256 ownerinterest = (totalamount*uint256(csdogefees)/uint256(100)); 
            IERC20(token).transferFrom(msg.sender,address(this),totalamount);
            address firstowner    = ownerOf(tokenid);
            IERC20(token).transfer(firstowner,amount);
            IERC20(token).transfer(devwallet,ownerinterest);
        }
        else
        {
            uint256 values = msg.value;
            require(values >= nftprice[tokenid].price,"price should be greater");
            uint256 amount   = (values*uint256(val)/uint256(100));
            uint256 ownerinterest = (values*uint256(csdogefees)/uint256(100)); 
            address firstowner    = ownerOf(tokenid);
            (bool success,)  = firstowner.call{ value: amount}("");
            require(success, "refund failed");
            (bool csdoges,)  = devwallet.call{ value: ownerinterest}("");
            require(csdoges, "refund failed");
        }
        _transfer(address(this),msg.sender,tokenid);
        nftinfo[tokenid].timeofmint = block.timestamp;
        changecollection(_collectionid,tokenid);
    }
    
    function changecollection(uint256 _collectionid,uint256 tokenid) internal
    {
       delete collectionstored[_collectionid][(idnumber[_collectionid][tokenid])];
       collectionstored[(totalcollection[msg.sender])].push(tokenid);
       totalnft[(totalcollection[msg.sender])]+=1;
       idnumber[(totalcollection[msg.sender])][tokenid]=totalnft[(totalcollection[msg.sender])]-1;
       nftprice[tokenid].price= 0;
       nftprice[tokenid].inlist=false;
       nftcollectionid[tokenid]=totalcollection[msg.sender];
       delete salenft[(salenftlist[tokenid])];
       delete csdoge[(csdogenumber[tokenid])];
    }
    
    function listofsalenft(uint256 tokenid) public view returns(uint256 [] memory,uint256 [] memory,uint256,uint256)
    {
        return (salenft,auctionnft,timeforauction[tokenid].minprice,nftprice[tokenid].price);
    }
    
    function startauction(uint256 tokenid,uint256 price,uint256 endday,uint256 endhours) public 
    {
        require(!timeforauction[tokenid].inlist,"already in sale");
        require(!nftprice[tokenid].inlist,"already in sale");
        require(ownerOf(tokenid) == msg.sender,"You are not owner");
        timeforauction[tokenid].time = block.timestamp +(endday * uint256(86400)) + (endhours*uint256(3600));
        timeforauction[tokenid].minprice =price;
        timeforauction[tokenid].inlist=true;
        auctionnftlist[tokenid]=auctionnft.length;
        auctionnft.push(tokenid);
        address firstowner = ownerOf(tokenid);
        transferFrom(firstowner,address(this), tokenid);
    }
    
    function timing(uint256 tokenid) public view returns(uint256)
    {
        if(timeforauction[tokenid].time>=block.timestamp)
        {
            return (timeforauction[tokenid].time-block.timestamp);
        }
        else
        {
            return uint256(0);
        }
    }
    
    function buyauction(uint256 tokenid) public payable
    {
        require(msg.value >= timeforauction[tokenid].minprice,"amount should be greater");
        require(msg.value >= timeforauction[tokenid].biddingamount,"previous bidding amount");
        require(timeforauction[tokenid].time >= block.timestamp,"auction end");
        timeforauction[tokenid].biddingamount=msg.value;
        amountforauction[tokenid][msg.sender] = msg.value;
        finalowner[tokenid]=msg.sender;
        uint256 values = msg.value;
        (bool success,)  = address(this).call{ value:values}("");
        require(success, "refund failed");
    }
    
    function auctiondetail(uint256 tokenid) public view returns(uint256,address) 
    {
        return (timeforauction[tokenid].biddingamount,finalowner[tokenid]);
    }
    
    function claim(uint256 collectionid,uint256 tokenid) public
    {
        uint256 val = uint256(100)-csdogefees;
        if(finalowner[tokenid] == msg.sender)
        {
            uint256 totalamount = timeforauction[tokenid].biddingamount;
            uint256 amount   = (totalamount*uint256(val)/uint256(100));
            uint256 ownerinterest = (totalamount*uint256(csdogefees)/uint256(100)); 
            address firstowner    = ownerOf(tokenid);
            (bool success,)  = firstowner.call{ value: amount}("");
            require(success, "refund failed");
            (bool csdoges,)  = devwallet.call{ value: ownerinterest}("");
            require(csdoges, "refund failed");
            _transfer(address(this),msg.sender,tokenid);
            changeauctioncollection(collectionid,tokenid);
        }
        else
        {
            uint256 amount = amountforauction[tokenid][msg.sender];
            (bool success,) = msg.sender.call{value:amount}("");
            require(success,"refund failed");
        }
    }
    
    function changeauctioncollection(uint256 _collectionid,uint256 tokenid) internal
    {
       delete collectionstored[_collectionid][(idnumber[_collectionid][tokenid])];
       collectionstored[(totalcollection[msg.sender])].push(tokenid);
       totalnft[(totalcollection[msg.sender])]+=1;
       idnumber[(totalcollection[msg.sender])][tokenid]=totalnft[(totalcollection[msg.sender])]-1;
       timeforauction[tokenid].minprice= 0;
       timeforauction[tokenid].biddingamount=0;
       timeforauction[tokenid].inlist=false;
       timeforauction[tokenid].time=0;
       nftcollectionid[tokenid]=totalcollection[msg.sender];
       delete auctionnft[(auctionnftlist[tokenid])];
    }
    
    function csdogenft() public view returns(uint256 [] memory)
    {
        return (csdoge);
    }
    
    function  csdogeinfo(uint256 tokenid) public view returns(bool,uint256,uint256)
    {
        return (csdogechoice[tokenid],csdogenftcopies[tokenid],totalcsdogecopies[tokenid]);
    }
    
    function collectionnft(uint256 collectionid) public view returns(uint [] memory)
    {
        return (collectionstored[collectionid]);
    }
    
    function totalcollectiondetails() public view returns(uint [] memory)
    {
        return userinfo[msg.sender];
    }
    
    function buycopies(address token,uint256 tokenid) public payable
    {
        if(csdogechoice[tokenid])
        {
            uint256 amount = nftprice[tokenid].price;
            IERC20(token).transferFrom(msg.sender,address(this),amount);
            address firstowner    = ownerOf(tokenid);
            IERC20(token).transfer(firstowner,amount);
        }
        else
        {
           uint256 values = msg.value;
           require(values >= nftprice[tokenid].price,"price should be greater");
           address firstowner    = ownerOf(tokenid);
           (bool success,)  = firstowner.call{ value: values}("");
           require(success, "refund failed");
        }
        uint256 collectionid = totalcollection[msg.sender];
        create(collectionid,msg.sender,tokenURI(tokenid),nftinfo[tokenid].mintname,nftinfo[tokenid].nftowner,1,nftinfo[tokenid].description,true);
        csdogenftcopies[tokenid]-=1;
    }
    
    function burncopies(uint256 copiesnumber,uint256 tokenid) public 
    {
        require(msg.sender == devwallet,"not devwallet");
        csdogenftcopies[tokenid]=copiesnumber;
    }
    
    receive() payable external {}
}