/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// Sources flattened with hardhat v2.2.0 https://hardhat.org

// File openzeppelin-solidity/contracts/utils/introspection/[email protected]

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


// File openzeppelin-solidity/contracts/token/ERC721/[email protected]



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


// File openzeppelin-solidity/contracts/token/ERC721/[email protected]



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
    function onERC721Received(address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// File openzeppelin-solidity/contracts/token/ERC721/extensions/[email protected]



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
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File openzeppelin-solidity/contracts/token/ERC721/extensions/[email protected]



pragma solidity ^0.8.0;

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


// File openzeppelin-solidity/contracts/utils/[email protected]



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


// File openzeppelin-solidity/contracts/utils/[email protected]



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


// File openzeppelin-solidity/contracts/utils/[email protected]



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


// File openzeppelin-solidity/contracts/utils/introspection/[email protected]



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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File openzeppelin-solidity/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;








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
    mapping(uint => string) public uri;
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return uri[tokenId];
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            IERC721Receiver(to).onERC721Received(from, tokenId, _data);
        }
        return true;
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
    
    pragma solidity ^ 0.8.0;
    contract GreenPointLandReserves{
        address THIS = address(this);
        uint $ = 1e18;
        uint genesis;
        Totem public totemNFT;
        ERC20 MVT = ERC20(0x3D46454212c61ECb7b31248047Fa033120B88668);
        ERC20 MDT = ERC20(0x32A087D5fdF8c84eC32554c56727a7C81124544E);
        ERC20 COLOR = ERC20(0xe324C8cF74899461Ef7aD2c3EB952DA7819aabc5);
        Oracle public ORACLE = Oracle(address(0));
        
        address public GLR_nonprofit;
        address public DEV;
        address public oracleTeller;
        uint public GLR_funds;
        uint public devPot;

        constructor(){
            genesis = block.timestamp;
            nextFloorRaisingTime = genesis + 86400 * 45;
            totemNFT = new Totem("Totem","TOTEM");
            GLR_nonprofit = msg.sender;
            DEV = msg.sender;
            oracleTeller = msg.sender;
        }

        function shiftOwnership(address addr) public{
            require(msg.sender == GLR_nonprofit);
            GLR_nonprofit = addr;
        }

        function GLR_pullFunds() public{
            require(msg.sender == GLR_nonprofit && GLR_funds > 0);
            uint cash = GLR_funds;
            GLR_funds = 0;
            (bool success, ) = GLR_nonprofit.call{value:cash}("");
            require(success, "Transfer failed.");
        }

        function Dev_pullFunds() public{
            require(msg.sender == DEV && devPot > 0);
            uint cash = devPot;
            devPot = 0;
            (bool success, ) = DEV.call{value:cash}("");
            require(success, "Transfer failed.");
        }

        function shiftDev(address addr) public{
            require(msg.sender == DEV);
            DEV = addr;
        }

        function shiftOracleTeller(address addr) public{
            require(msg.sender == oracleTeller);
            oracleTeller = addr;
        }

        function setOracle(address addr) public{
            require(msg.sender == oracleTeller);
            ORACLE = Oracle(addr);
        }

        function globalData() public view returns(uint _MVT_to_rollout, uint _mvt5xHodlPool, uint _nextFloorRaisingTime, uint _floorPrice, uint _totalACRESupply, uint _totalAcreWeight, uint _totalTotemWeight){
            return (MVT_to_rollout, mvt5xHodlPool, nextFloorRaisingTime, floorPrice, _totalSupply, totalShares[ETHpool], totalTotemWeight);
        }
        
        function userData(address account) public view returns(uint acreBalance, uint totemWeight, uint acreDividends, uint totemDividends, bool MDT_approval, bool MVT_approval){
            return (balanceOf(account), shares[MVTpool][account], dividendsOf(ETHpool, account) + earnings[ETHpool][account], dividendsOf(MVTpool, account) + earnings[MVTpool][account], MDT.allowance(account,THIS)>$*1000000, MVT.allowance(account,THIS)>$*1000000);
        }

        function userData2(address account) public view returns(uint MDT_balance, uint MVT_balance, uint colorDividends){
            return ( MDT.balanceOf(account), MVT.balanceOf(account), colorDividendsOf(account) + earnings[COLORpool][account] );
        }

        uint mvt5xHodlPool;
        event PurchaseAcre(address boughtFor, uint acreBought);
        function purchaseAcre(address buyFor) public payable{
            if( buyFor == address(0) ){
                buyFor = msg.sender;
            }

            require(msg.value > 0 && msg.sender == tx.origin);
            uint MONEY = msg.value;
            uint forDev;
            if(block.timestamp - genesis <= 86400*365){forDev = MONEY * 6/1000;}
            devPot += forDev;

            uint val = MONEY - forDev;
            mint(buyFor, val);
            uint forBuyingMVT = val * (_totalSupply - totalTotemWeight + builder_totalShares) / _totalSupply;
            GLR_funds += val - forBuyingMVT;
            mvt5xHodlPool += forBuyingMVT;
            emit PurchaseAcre(buyFor, val);
            rolloutDepositedMVTRewards();
        }

        uint nextFloorRaisingTime;
        uint floorPrice = 0.00002 ether;
        bool firstBump = true;
        event Sell_MVT(uint mvtSold, uint cashout,uint forManifest,uint forDaily);
        function sell_MVT(uint amount) public{
            address payable sender = payable(msg.sender);
            require( MVT.transferFrom(sender, THIS, amount) );
            uint NOW = block.timestamp;
            
            if(NOW >= nextFloorRaisingTime){
                if(firstBump){
                    firstBump = false;
                    floorPrice = floorPrice * 10;
                }else{
                    floorPrice = floorPrice * 3;
                }
                nextFloorRaisingTime += 300 * 86400;
            }

            uint cost = floorPrice*amount/$;
            require( mvt5xHodlPool >= cost && cost > 0 );
            mvt5xHodlPool -= cost;

            uint forManifest = amount * ( totalTotemWeight - builder_totalShares) / _totalSupply;
            uint forDaily =  amount  - forManifest;
            MVT_to_rollout += forDaily;
            storeUpCommunityRewards(forManifest);
            emit Sell_MVT(amount, cost,forManifest, forDaily);
            (bool success, ) = sender.call{value:cost}("");
            require(success, "Transfer failed.");
        }

        mapping(uint => mapping(address => uint)) public  shares;
        mapping(uint => uint) public totalShares;
        mapping(uint => uint)  earningsPer;
        mapping(uint => mapping(address => uint)) payouts;
        mapping(uint => mapping(address => uint)) public  earnings;
        uint256 constant scaleFactor = 0x10000000000000000;
        uint constant ETHpool = 0;
        uint constant MVTpool = 1;
        uint constant COLORpool = 2;

        function withdraw(uint pool) public{
            address payable sender = payable(msg.sender);
            require(pool>=0 && pool<=2);


            if(pool == COLORpool){
                update(ETHpool, sender);
            }else{
                update(pool, sender);
            }

            if(pool == ETHpool){
                testClean(sender);
            }
            

            uint earned = earnings[pool][sender];
            earnings[pool][sender] = 0;
            require(earned > 0);

            if(pool == ETHpool){
                (bool success, ) = sender.call{value:earned}("");
                require(success, "Transfer failed.");
            }else if(pool == MVTpool){
                MVT.transfer(sender, earned);
            }else if(pool == COLORpool){
                COLOR.transfer(sender, earned);
            }
        }

        function addShares(uint pool, address account, uint amount) internal{
            update(pool, account);
            totalShares[pool] += amount;
            shares[pool][account] += amount;
        }

        function removeShares(uint pool, address account, uint amount) internal{
            update(pool, account);
            totalShares[pool] -= amount;
            shares[pool][account] -= amount;
        }

        function dividendsOf(uint pool, address account) public view returns(uint){
            uint owedPerShare = earningsPer[pool] - payouts[pool][account];
            return shares[pool][account] * owedPerShare / scaleFactor;
        }
        function colorDividendsOf(address account) public view returns(uint){
            uint owedPerShare = earningsPer[COLORpool] - payouts[COLORpool][account];
            return shares[ETHpool][account] * owedPerShare / scaleFactor;
        }
        
        function update(uint pool, address account) internal {
            uint newMoney = dividendsOf(pool, account);
            payouts[pool][account] = earningsPer[pool];
            earnings[pool][account] += newMoney;
            if(pool == ETHpool){
                newMoney = colorDividendsOf(account);
                payouts[COLORpool][account] = earningsPer[COLORpool];
                earnings[COLORpool][account] += newMoney;
            }
        }

        event PayEthToAcreStakers(uint amount);
        function payEthToAcreStakers() payable public{
            uint val = msg.value;
            require(totalShares[ETHpool]>0);
            earningsPer[ETHpool] += val * scaleFactor / totalShares[ETHpool];
            emit PayEthToAcreStakers(val);
        }

        event PayColor( uint amount );
        function tokenFallback(address from, uint value, bytes calldata _data) external{
            if(msg.sender == address(COLOR) ){
                require(totalShares[ETHpool]>0);
                earningsPer[COLORpool] += value * scaleFactor / totalShares[ETHpool];
                emit PayColor(value);
            }else{
                revert("no want");
            }
        }


        mapping(uint => uint) public  builder_shares;
        uint public builder_totalShares;
        uint builder_earningsPer;
        mapping(uint => uint) builder_payouts;
        mapping(uint => uint) public  builder_earnings;
        function builder_addShares(uint TOTEM, uint amount) internal{
            if(!totemManifest[TOTEM]){
                builder_update(TOTEM);
                builder_totalShares += amount;
                builder_shares[TOTEM] += amount;
            }
        }

        function builder_removeShares(uint TOTEM, uint amount) internal{
            if(!totemManifest[TOTEM]){
                builder_update(TOTEM);
                builder_totalShares -= amount;
                builder_shares[TOTEM] -= amount;
            }
        }

        function builder_dividendsOf(uint TOTEM) public view returns(uint){
            uint owedPerShare = builder_earningsPer - builder_payouts[TOTEM];
            return builder_shares[TOTEM] * owedPerShare / scaleFactor;
        }
        
        function builder_update(uint TOTEM) internal{
            uint newMoney = builder_dividendsOf(TOTEM);
            builder_payouts[TOTEM] = builder_earningsPer;
            builder_earnings[TOTEM] += newMoney;        
        }

        uint public MVT_to_rollout;
        uint public lastRollout;

        event DepositMVTForRewards(address addr, uint amount);
        function depositMVTForRewards(uint amount) public{
            require(MVT.transferFrom(msg.sender, THIS, amount));
            storeUpCommunityRewards(amount);
            emit DepositMVTForRewards(msg.sender, amount);
        }

        function storeUpCommunityRewards(uint amount)internal{
            if( builder_totalShares == 0 ){
                storedUpBuilderMVT += amount;
            }else{
                builder_earningsPer += ( amount + storedUpBuilderMVT ) * scaleFactor / builder_totalShares;
                storedUpBuilderMVT = 0;
            }
        }

        event RolloutDepositedMVTRewards(uint amountToDistribute);
        function rolloutDepositedMVTRewards() public{
            uint NOW = block.timestamp;
            if( (NOW - lastRollout) > 86400 && totalShares[MVTpool] > 0 &&  MVT_to_rollout > 0){
                lastRollout = NOW;
                uint amountToDistribute = MVT_to_rollout * (totalTotemWeight-totalShares[MVTpool]) / _totalSupply;
                MVT_to_rollout -= amountToDistribute;
                earningsPer[MVTpool] += amountToDistribute * scaleFactor / totalShares[MVTpool];
                emit RolloutDepositedMVTRewards(amountToDistribute);
            }
        }

        string public name = "Acre";
        string public symbol = "ACRE";
        uint8 constant public decimals = 18;
        mapping(address => uint256) public balances;
        uint _totalSupply;

        mapping(address => mapping(address => uint)) approvals;

        event Transfer(
            address indexed from,
            address indexed to,
            uint256 amount,
            bytes data
        );
        event Transfer(
            address indexed from,
            address indexed to,
            uint256 amount
        );
        
        event Mint(
            address indexed addr,
            uint256 amount
        );

        function mint(address _address, uint _value) internal{
            balances[_address] += _value;
            _totalSupply += _value;
            if(!isContract(msg.sender)) addShares(ETHpool, _address, _value);
            emit Mint(_address, _value);
        }

        function totalSupply() public view returns (uint256) {
            return _totalSupply;
        }

        function balanceOf(address _owner) public view returns (uint256 balance) {
            return balances[_owner];
        }

        function transfer(address _to, uint _value) public virtual returns (bool) {
            bytes memory empty;
            return transferToAddress(_to, _value, empty);
        }

        function transfer(address _to, uint _value, bytes memory _data) public virtual returns (bool) {
            if( isContract(_to) ){
                return transferToContract(_to, _value, _data);
            }else{
                return transferToAddress(_to, _value, _data);
            }
        }

        //function that is called when transaction target is an address
        function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool) {
            moveTokens(msg.sender, _to, _value);
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }

        //function that is called when transaction target is a contract
        function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool) {
            moveTokens(msg.sender, _to, _value);
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }

        function testClean(address addr) public {
            if(isContract(addr)){
                clean(addr);
            }
        }

        function clean(address addr) internal{
            uint _shares = shares[ETHpool][addr];
            if( _shares > 0 ){
                removeShares(ETHpool, addr, _shares);
                uint earned = earnings[ETHpool][addr];
                earnings[ETHpool][addr] = 0;

                require( totalShares[ETHpool] > 0 );
                earningsPer[ETHpool] += earned * scaleFactor / totalShares[ETHpool];
                emit PayEthToAcreStakers(earned);
            }
        }

        function moveTokens(address _from, address _to, uint _amount) internal virtual{
            require( _amount <= balances[_from] );
            //update balances
            balances[_from] -= _amount;
            balances[_to] += _amount;

            if(!isContract(_from) ){
                if(_to != THIS ){
                    require( MVT.transferFrom(_from, THIS, _amount) );
                    storeUpCommunityRewards(_amount);
                }
                removeShares(ETHpool, _from, _amount);
            }else{
                clean(_from);
            }

            if( !isContract(_to) ){
                addShares(ETHpool, _to, _amount);
            }else{
                clean(_to);
            }

            emit Transfer(_from, _to, _amount);
        }

        function allowance(address src, address guy) public view returns (uint) {
            return approvals[src][guy];
        }
        
        function transferFrom(address src, address dst, uint amount) public returns (bool){
            address sender = msg.sender;
            require(approvals[src][sender] >=  amount);
            require(balances[src] >= amount);
            approvals[src][sender] -= amount;
            moveTokens(src,dst,amount);
            bytes memory empty;
            emit Transfer(sender, dst, amount, empty);
            return true;
        }

        event Approval(address indexed src, address indexed guy, uint amount);
        function approve(address guy, uint amount) public returns (bool) {
            address sender = msg.sender;
            approvals[sender][guy] = amount;

            emit Approval( sender, guy, amount );
            return true;
        }

        function isContract(address _addr) public view returns (bool is_contract) {
            uint length;
            assembly {
                //retrieve the size of the code on target address, this needs assembly
                length := extcodesize(_addr)
            }
            if(length>0) {
                return true;
            }else {
                return false;
            }
        }

        uint NFTcount;
        
        mapping(address => uint[]) public totemsHad;
        mapping(address => mapping(uint => bool)) public alreadyHadAtleastOnce;

        uint totalTotemWeight;
        event AcreToTotem(address account, uint amount, bool autoStake);
        function acreToTotem(uint amount, bool autoStake) public returns(uint TOTEM_ID){
            address sender = msg.sender;
            require( MDT.transferFrom(sender, THIS, $) );

            totemNFT.mintUniqueTokenTo(autoStake?THIS:sender, NFTcount, amount);

            if(autoStake){
                stakeNFT(sender, NFTcount);
            }else{
                builder_addShares(NFTcount, amount);
                totemsHad[sender].push(NFTcount);
                alreadyHadAtleastOnce[sender][NFTcount] = true;
            }

            NFTcount += 1;
            totalTotemWeight += amount;
            moveTokens(sender, THIS, amount);
            bytes memory empty;
            emit Transfer(sender, THIS, amount, empty);
            emit AcreToTotem(sender, amount, autoStake);
            return NFTcount - 1;
        }

        uint storedUpBuilderMVT;
        event TotemToMDT(address lastOwner, uint totemID, bool preventBurn);
        mapping(uint => bool) public totemManifest;
        function totemToMDT(uint totemID, bool preventBurn) public{
            address sender = msg.sender;
            require( sender == staker[totemID] && !totemManifest[totemID] && !requestLocked[totemID]);
            require( MDT.transfer(sender, $) );
            uint totemWeight = totemNFT.getWeight(totemID);
            removeShares( MVTpool, sender, totemWeight );
            staker[totemID] = address(0);

            uint burnage;
            if(preventBurn){
                require( MVT.transferFrom(sender,THIS, totemWeight) );
                storeUpCommunityRewards(totemWeight);
            }else{
                burnage = totemWeight * totalTotemWeight / _totalSupply;
            }
            storeUpCommunityRewards(builder_dividendsOf(totemID)+builder_earnings[totemID]);
            
            moveTokens(THIS, sender, totemWeight - burnage);
            _totalSupply -= burnage;
            balances[THIS] -= burnage;

            totalTotemWeight -= totemWeight;
            
            emit TotemToMDT(sender, totemID, preventBurn);
        }

        mapping(uint => address) public staker;
        mapping(uint => uint) public lastMove;
        event StakeNFT(address who, uint tokenID);
        function stakeNFT(address who, uint256 tokenID) internal{
            staker[tokenID] = who;

            if( !alreadyHadAtleastOnce[who][tokenID] ){
                totemsHad[who].push(tokenID);
                alreadyHadAtleastOnce[who][tokenID] = true;
            }

            addShares( MVTpool, who, totemNFT.getWeight(tokenID) );
            emit StakeNFT(who, tokenID);
        }

        event UnstakeNFT(address unstaker, uint tokenID);
        function unstakeNFT(uint tokenID) public{
            address sender = msg.sender;
            require(staker[tokenID] == sender && !requestLocked[tokenID] && block.timestamp-lastMove[tokenID]>=86400 );
            uint weight = totemNFT.getWeight(tokenID);
            lastMove[tokenID] = block.timestamp;
            removeShares( MVTpool, sender, weight );
            staker[tokenID] = address(0);
            builder_addShares(tokenID, weight);

            totemNFT.transferFrom(THIS, sender, tokenID);
            emit UnstakeNFT(sender, tokenID);
        }

        function viewTotems(address account, uint[] memory totems) public view returns(uint[] memory tokenIDs, bool[] memory accountIsCurrentlyStaking, uint[] memory acreWeight, bool[] memory owned, bool[] memory manifested, bool[] memory staked, uint[] memory manifestEarnings, uint[] memory lastMoved,bool[] memory pendingManifest){
            uint L;
            if(totems.length==0){
                L = totemsHad[account].length;
            }else{
                L = totems.length;
            }

            tokenIDs = new uint[](L);
            acreWeight = new uint[](L);
            accountIsCurrentlyStaking = new bool[](L);
            owned = new bool[](L);
            manifested = new bool[](L);
            staked = new bool[](L);
            pendingManifest = new bool[](L);
            manifestEarnings = new uint[](L);
            lastMoved = new uint[](L);

            uint tID;
            for(uint c = 0; c<L; c+=1){
                if(totems.length==0){
                    tID = totemsHad[account][c];
                }else{
                    tID = totems[c];
                }
                tokenIDs[c] = tID;
                acreWeight[c] = totemNFT.getWeight(tID);
                accountIsCurrentlyStaking[c] = staker[tID] == account;
                staked[c] = totemNFT.ownerOf(tID) == THIS;
                manifested[c] = totemManifest[tID];
                pendingManifest[c] = requestLocked[tID];
                manifestEarnings[c] = builder_dividendsOf(tID) + builder_earnings[tID];
                lastMoved[c] = lastMove[tID];
                owned[c] = ( staker[tID] == account || totemNFT.ownerOf(tID) == account );
            }
        }

        function onERC721Received(address from, uint256 tokenID, bytes memory _data) external returns(bytes4) {
            bytes4 empty;
            require( msg.sender == address(totemNFT) && block.timestamp-lastMove[tokenID]>=86400 );
            lastMove[tokenID] = block.timestamp;
            builder_removeShares(tokenID, totemNFT.getWeight(tokenID) );
            stakeNFT(from, tokenID);
            return empty;
        }

        mapping(uint=>address) public theWork; //noita
        mapping(uint=>uint) workingTotem;
        mapping(uint=>string) public txt;
        mapping(uint=>bool) requestLocked;
        event OracleRequest(address buidlr, uint totemID, uint earningsToManifest, address _theWork, string text, uint ticketID);
        function oracleRequest(uint totemID, string memory _txt, address contract_optional) public payable returns(uint ticketID){
            address sender = msg.sender;
            require( staker[totemID] == sender && !totemManifest[totemID] && !requestLocked[totemID] );
            uint ID = ORACLE.fileRequestTicket{value: msg.value}(1, true);
            workingTotem[ID] = totemID;
            theWork[totemID] = contract_optional;
            txt[totemID] = _txt;
            requestLocked[totemID] = true;
            emit OracleRequest(sender, totemID, builder_dividendsOf(totemID)+builder_earnings[totemID], contract_optional, _txt, ID);
            return ID;
        }

        event CommunityReward(address buidlr, uint totemID, uint reward, address contractBuilt, string text, uint ticketID);
        event RequestRejected(uint totemID, uint ticketID);
        function oracleIntFallback(uint ticketID, bool requestRejected, uint numberOfOptions, uint[] memory optionWeights, int[] memory intOptions) public{
            uint optWeight;
            uint positive;
            uint negative;
            uint totemID = workingTotem[ticketID];
            require( msg.sender == address(ORACLE) );

            for(uint i; i < numberOfOptions; i+=1){
                optWeight = optionWeights[i];
                if(intOptions[i]>0){
                    positive += optWeight;
                }else{
                    negative += optWeight;
                }
            }

            if(!requestRejected && positive>negative){
                //emit event and give reward
                if(!totemManifest[totemID]){
                    totemManifest[totemID] = true;
                    uint earned = builder_earnings[totemID];
                    if(earned>0){
                        if( staker[totemID]==address(0) ){
                            storeUpCommunityRewards(earned);
                        }else{
                            earnings[MVTpool][staker[totemID]] += earned;
                        }
                    }
                    emit CommunityReward(staker[totemID], totemID, earned, theWork[totemID], txt[totemID], ticketID );
                }
            }else{
                emit RequestRejected(totemID,ticketID);
            }
            requestLocked[totemID] = false;
        }
    }

    abstract contract Oracle{
        function fileRequestTicket( uint8 returnType, bool subjective) public virtual payable returns(uint ticketID);
    }

    abstract contract ERC20{
        function totalSupply() external virtual view returns (uint256);
        function balanceOf(address account) external virtual view returns (uint256);
        function allowance(address owner, address spender) external virtual view returns (uint256);
        function transfer(address recipient, uint256 amount) external virtual returns (bool);
        function approve(address spender, uint256 amount) external virtual returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
    }

    contract Totem is ERC721 {
        constructor (string memory _name, string memory _symbol)
            ERC721(_name, _symbol)
        {
            greenpoint = msg.sender;
        }

        address greenpoint;
        mapping(uint => uint)  weight;
        function mintUniqueTokenTo(
            address _to,
            uint256 _tokenId,
            uint _weight
        ) public {
            require(msg.sender == greenpoint);
            super._mint(_to, _tokenId);
            weight[_tokenId] = _weight;
        }

        function getWeight(uint ID) public view returns(uint){
            return weight[ID];
        }

        mapping(uint => string) desiredURI;
        mapping(uint => uint) workingTotem;
        event URI_request(uint totemID, string desiredURI, uint ticketID);
        function uriRequest(uint ID, string memory _desiredURI) public payable returns(uint){
            require( msg.sender == ownerOf(ID) );
            uint otID = GreenPointLandReserves(greenpoint).ORACLE().fileRequestTicket{value:msg.value}(1,true);
            desiredURI[otID] = _desiredURI;
            workingTotem[otID] = ID;
            emit URI_request(ID, _desiredURI, otID);
            return otID;
        }

        event AcceptedURI(uint totemID);
        event RejectedURI(uint totemID);
        function oracleIntFallback(uint ticketID, bool requestRejected, uint numberOfOptions, uint[] memory optionWeights, int[] memory intOptions) public{
            uint optWeight;
            uint positive;
            uint negative;
            
            require( msg.sender == address( GreenPointLandReserves(greenpoint).ORACLE() ) );

            for(uint i; i < numberOfOptions; i+=1){
                optWeight = optionWeights[i];
                if(intOptions[i]>0){
                    positive += optWeight;
                }else{
                    negative += optWeight;
                }
            }
            uint totemID = workingTotem[ticketID];
            if(!requestRejected && positive>negative && !GreenPointLandReserves(greenpoint).totemManifest(totemID) ){
                uri[totemID] = desiredURI[ticketID];
                emit AcceptedURI(totemID);
            }else{
                emit RejectedURI(totemID);
            }
        }

    }

    abstract contract ERC223ReceivingContract{
        function tokenFallback(address _from, uint _value, bytes calldata _data) external virtual;
    }