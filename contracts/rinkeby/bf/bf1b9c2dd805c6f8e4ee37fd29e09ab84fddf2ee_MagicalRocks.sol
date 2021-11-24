/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

/**
 * 
 * china keeps messing with my money, so i made this epic on-chain nft to keep my funds safu
 * no more china fud
 * 
 * there will be 100 china fud nfts
 * if you dont get one, you are simply ngmi
 * 
 * /

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol

pragma solidity ^0.8.0;



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
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
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

// File: @openzeppelin/contracts/access/Ownable.sol

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


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MagicalRocks is ERC721Enumerable, Ownable {
    
    uint256 private constant _maxMint = 5;
    uint256 private constant _price = 10000000000000000; //0.01 ETH;
    uint public constant MAX_ENTRIES = 100;
    
    constructor() ERC721("Magical Rocks", "MGRK")  {
        mint(msg.sender, 0);
    }
    
    function mint(address _to, uint256 num) public payable {
        uint256 supply = totalSupply();
        
        if(msg.sender != owner()) {
          require(balanceOf(msg.sender) + num < _maxMint, "u try mint 2 many");
          require( num < _maxMint,"u try mint 2 many" );
          require( msg.value >= _price,"Ether sent is not correct" );
        }
        
        require( supply + num < MAX_ENTRIES,"Exceeds maximum supply" );
        for(uint256 i; i < num; i++){
          _safeMint( _to, supply + i );
        }
    }
    
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function getPrice() public view returns (uint256){
        if(msg.sender == owner()) {
            return 0;
        }
        return _price;
    }
    
    function getMaxMint() public view returns (uint256) {
        return _maxMint;
    }
    
    function getImageData() public view returns (string memory) {
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 64 64"><path stroke="#000" d="M31 6h4m-8 1h4m4 0h5M25 8h2m13 0h1M22 9h3m16 0h5m-26 1h2m24 0h3m-29 1h1m28 0h2m-33 1h2m30 0h1m-36 1h3m33 0h1m-41 1h4m36 0h1M7 15h4m41 0h1M5 16h2m46 0h1M5 17h1m48 0h1M5 18h1m49 0h1M5 19h1m49 0h1M4 20h1m51 0h1M4 21h1m52 0h2M4 22h1m54 0h1M3 23h1m56 0h2M2 24h1m58 0h1M2 25h1m58 0h1M1 26h1m59 0h1M1 27h1m60 0h1M0 28h1m62 0h1M0 29h1m62 0h1M0 30h1m62 0h1M0 31h1m62 0h1M0 32h1m62 0h1M0 33h1m61 0h1M0 34h1m61 0h1M0 35h1m61 0h1M0 36h1m61 0h1M0 37h1m62 0h1M1 38h1m61 0h1M1 39h1m61 0h1M1 40h1m61 0h1M2 41h1m60 0h1M3 42h1m59 0h1M4 43h1m58 0h1M4 44h1m58 0h1M4 45h1m58 0h1M5 46h1m57 0h1M5 47h2m56 0h1M7 48h3m53 0h1m-54 1h1m51 0h1m-52 1h6m45 0h1m-46 1h3m39 0h3m-42 1h1m36 0h2m-38 1h2m6 0h1m25 0h2m-34 1h2m1 0h3m1 0h6m18 0h1m-30 1h1m10 0h2m14 0h2m-16 1h1m10 0h3m-13 1h1m5 0h4m-9 1h5"/><path stroke="#6e8095" d="M31 7h4m-8 1h7m1 0h5M25 9h6m4 0h6m-19 1h8m4 0h11m-24 1h9m3 0h12m-24 1h9m2 0h12m-26 1h25m-28 1h27m-31 1h5m2 0h23M7 16h8m4 0h21M6 17h7m8 0h6M6 19h1m1 0h2m-4 1h5m1 0h1m-6 1h6m-5 1h2m1 0h2m-2 1h3m3 0h2m-9 1h4m3 0h2M9 25h4m1 0h2M2 26h1m6 0h2m3 0h2M2 27h1m6 0h4m2 0h1m-8 1h7m-8 1h8M2 30h3m4 0h2m-9 1h2m16 3h1M6 36h2m-2 1h1m-1 2h1"/><path stroke="#3c4b60" d="M34 8h1m-4 1h4m-5 1h4m-4 1h3m13 0h1m-27 1h1m9 0h2m15 0h3m-2 1h3m-1 1h1m-34 1h1m32 0h1m-36 1h2m1 0h1m31 0h3m-40 1h5m33 0h2M6 18h6m1 0h6m33 0h1M7 19h1m2 0h10M5 20h1m5 0h1m1 0h4m1 0h2m30 0h1M5 21h2m6 0h7m35 0h1M5 22h3m2 0h1m2 0h3m1 0h2m36 0h1M4 23h2m1 0h4m3 0h3M3 24h7m4 0h3m28 0h1m1 0h3M3 25h4m1 0h1m4 0h1m2 0h2m25 0h1m1 0h5m4 0h1M3 26h6m2 0h3m2 0h1m24 0h1m3 0h2m1 0h5m1 0h2M3 27h6m4 0h2m18 0h1m13 0h7m2 0h3M1 28h7m25 0h1m9 0h2m5 0h2M1 29h6m25 0h2m14 0h3M1 30h1m3 0h4m2 0h1m1 0h1m9 0h1M1 31h1m2 0h4m1 0h1m12 0h1M1 32h9m2 0h1m8 0h2M1 33h11m9 0h1M1 34h11M1 35h11m7 0h1M1 36h5m2 0h1m2 0h2M1 37h5m1 0h2m-7 1h6m6 0h2M2 39h4m1 0h4m2 0h3M2 40h4m3 0h7m-6 1h5m-2 1h2m17 0h2m-20 1h1m16 0h4m-4 1h3m-4 1h4m-4 1h3"/><path stroke="#4f6178" d="M45 10h1m1 1h2m2 4h1m-3 1h1m-31 1h2m28 0h2m2 0h1m-4 1h2m1 0h2m-5 1h5m-4 1h5m-5 1h4m1 0h1m-20 1h1m14 0h3m1 0h3m-18 1h1m11 0h7m-24 1h1m9 0h1m7 0h7m-19 1h1m8 0h2m2 0h6m-19 1h3m2 0h1m5 0h1m2 0h5m-20 1h6m7 0h2m4 0h1m-16 1h5m2 0h4M6 40h1"/><path stroke="#354255" d="M45 11h1m-2 1h1m-4 3h1m-2 1h1m7 0h1m-31 1h1m8 0h1m1 0h5m-15 1h1m29 0h1m-2 1h1m-2 1h3m-13 1h2m1 0h1m7 0h3m-13 1h4m9 0h1m-15 1h2m3 0h1m1 0h3m3 0h2m-11 1h2m7 0h1m1 0h1m-19 1h2m5 0h1m11 0h1m7 2h1m-37 1h1m34 0h1m-37 1h1m37 0h1m-1 1h1m-40 1h1m38 0h1m-6 1h1m4 0h1m-16 3h1m10 0h4m-15 1h3m8 0h2m1 0h1m-4 1h5m-5 1h5m-8 1h1m2 0h5M7 40h1m23 0h1m21 0h1m1 0h8M3 41h3m47 0h1m2 0h7m-9 1h1m2 0h6m-7 1h7m-33 1h1m3 0h1m21 0h7m-5 1h5m-5 1h5m-33 1h1m28 0h4m-4 1h4m-4 1h2"/><path stroke="#121721" d="M45 12h1m-3 1h1m-2 1h1m-15 3h1m5 0h6m-20 1h2m1 0h2m-5 1h1m4 8h1m-2 1h1m-2 1h1m-3 5h1m-2 1h1m-2 1h1m-2 1h1m-2 1h1m-2 1h1m-1 1h1M6 41h1m1 0h1m21 0h2m-22 1h1m19 0h1m-19 1h1m17 0h1m-18 1h2m19 1h1m-2 1h1m-5 1h1m1 0h2m-4 1h1m-13 1h2m4 0h2m3 0h2"/><path stroke="#1a2130" d="M46 12h1m0 1h1m-5 2h1m4 0h1m-6 1h3m-5 1h1m3 0h2m-7 1h2m3 0h3m-9 1h9m-15 1h1m3 0h10m-11 1h1m2 0h1m1 0h7m-6 1h5m-8 1h2m2 0h1m5 0h1m2 0h1m-11 5h1m13 0h1m-12 1h3m3 0h5"/><path stroke="#03070c" d="M44 13h1m-23 5h1m7 0h4m24 11h2m-9 1h4m-35 6h1m-2 1h1m19 0h1m5 0h2m-29 1h1m21 0h1m5 0h3m-32 1h1m23 0h2m4 0h3m-9 1h7m1 0h1M7 41h1m33 0h4M5 42h1m2 0h1m30 0h5m6 0h3m-43 1h1m27 0h5m4 0h2m1 0h2m-40 1h1m26 0h5m-32 1h1m26 0h8m9 0h1m-44 1h1m20 0h2m4 0h9m6 0h3M7 47h1m25 0h5m3 0h10m6 0h1m-36 1h2m9 0h5m1 0h19m-47 1h1m7 0h1m1 0h2m8 0h1m1 0h16m1 0h9m-42 1h5m5 0h20m2 0h10m-39 1h1m3 0h9m1 0h25m-38 1h36m-34 1h6m1 0h25m-30 1h1m10 0h18m-16 1h14m-13 1h10m-9 1h4"/><path stroke="#0a0e15" d="M45 13h1m-2 1h3m-5 1h1m1 0h3m-6 1h2m3 0h1m-7 1h1m1 0h3m2 0h1m-11 1h3m2 0h3m-12 1h6m-7 1h1m1 0h3m2 4h1m4 6h1m12 0h4m-17 1h2m4 0h2m-7 1h1m4 0h2m-3 1h5m2 0h1m-7 1h5m1 0h2m-7 1h1m-8 3h2m-3 1h4m1 1h1m1 0h1m-11 1h1m4 0h2m3 0h3m-9 1h2m7 0h1m-11 1h1m1 0h2m2 0h1m2 0h2m-16 1h1m5 0h7m-13 1h1m8 0h1m4 0h4m-20 1h4m9 0h2m3 0h1m-17 1h3m12 0h4m-19 1h1m-9 1h1m1 0h1m16 0h1m-28 1h1m2 0h2m20 0h2m-28 1h3m9 0h1"/><path stroke="#090c13" d="M46 13h1m-4 1h1m3 1h1m-1 1h1m-21 2h3m4 0h3m-15 1h1m2 0h8m-12 1h1m3 0h7m-5 1h4m-3 1h2m17 0h1m-20 1h1m28 5h3m-17 1h2m11 0h2m2 0h1m-16 1h1m1 0h4m4 0h1m-10 6h1m0 1h1m-30 2h1m7 0h2m-11 1h2m6 0h3m-12 1h1m1 0h1m3 2h2m-3 1h4m10 0h1m-16 1h4m11 0h1m-17 1h4m-4 1h4m-4 1h3m9 0h2m25 0h1m-39 1h1m40 1h1m-18 7h1"/><path stroke="#171c29" d="M47 14h1m0 3h1m-1 1h1m0 1h1m-2 3h2m-3 1h2m-9 1h1m2 0h2m-5 1h1m2 5h1m2 1h4m2 0h9m-15 1h4m2 0h5m1 0h4m-16 1h3m5 0h2m1 0h5m-16 1h4m5 0h1m2 0h4m-14 1h3m1 0h6m-8 1h8m2 0h1m-12 1h9m-8 1h8m-7 1h4m1 0h2m-7 1h2m1 0h1m-8 1h3m4 0h2m-10 1h4m5 0h2m-13 1h1m9 0h2m-20 1h2m13 0h5m-20 1h2m10 0h4m-38 1h1m36 0h3m-3 1h2m8 2h1m-38 1h1m34 0h2"/><path stroke="#202837" d="M48 14h2m-1 1h1m3 9h1m-10 1h1m5 0h1"/><path stroke="#141a26" d="M16 15h1m0 1h1m-6 2h1m12 0h2m-6 1h1m1 0h2m-8 1h1m2 0h1m1 0h3m-9 2h1M6 23h1m20 1h1M7 25h1m18 0h2m-3 1h2m34 3h1m-50 1h1m33 0h1m9 0h1m4 0h1M8 31h1m1 0h3m48 0h1m-52 1h2m17 3h1m16 0h1M9 36h2m17 0h2M9 37h5m13 0h3m18 0h1M8 38h6m2 0h1m9 0h5m18 0h1m-39 1h2m15 0h3m19 0h1M8 40h1m19 0h3M9 41h1m5 0h1m1 0h1m6 0h6m2 0h1M4 42h1m4 0h1m1 0h2m2 0h5m3 0h7m1 0h1m-21 1h1m1 0h1m1 0h7m2 0h6m-15 1h6m4 0h5m-17 1h7m4 0h6m27 0h1m-43 1h4m4 0h7m-15 1h4m4 0h6m29 0h1m-44 1h4m5 0h5m1 0h1m-15 1h1m8 0h3m-5 1h1"/><path stroke="#262e3d" d="M20 21h6m-6 1h2m-3 1h2m-2 1h1m-7 9h1m-2 1h1m15 0h1m-1 1h1m-2 1h1m-2 1h1m-2 2h1m-7 2h3m-2 1h2"/><path stroke="#181c25" d="M26 21h1m4 0h1m-5 2h1m-9 17h2m1 2h1"/><path stroke="#191f27" d="M32 21h1"/><path stroke="#2e374a" d="M33 21h2"/><path stroke="#505f76" d="M35 21h1m0 1h1m-1 1h1m-2 1h1m-22 7h1"/><path stroke="#586a82" d="M19 22h1m-2 3h1m-2 1h2m-2 1h1m14 1h1m-20 3h1m-1 1h1m-2 1h1m-1 2h1m0 1h2m-1 1h2"/><path stroke="#dff3ff" d="M22 22h1m3 0h2m2 0h3m2 0h1m-15 1h2m3 0h1m2 0h3m3 0h1m-16 1h2m3 0h2m1 0h2m3 0h2m-16 1h3m2 0h2m2 0h2m2 0h2m-15 1h2m3 0h1m2 0h2m3 0h2m-16 1h2m3 0h2m1 0h2m4 0h1m-16 1h2m3 0h2m2 0h1m4 0h1m-15 1h2m2 0h2m2 0h2m3 0h2m-16 1h2m3 0h2m1 0h2m3 0h2m-16 1h2m3 0h2m2 0h2m2 0h2m-15 1h2m3 0h1m2 0h2m3 0h2m-16 1h2m3 0h2m1 0h2m2 0h3m-16 1h2m3 0h2m2 0h2m2 0h2m-15 1h1m3 0h2m2 0h2m2 0h3m-13 1h4m2 0h2m2 0h2m-11 1h2m2 0h2m3 0h1m-7 1h2m3 0h2m-7 1h1m3 0h2m-3 1h3m-3 1h2"/><path stroke="#fff" d="M23 22h3m7 0h2m-12 1h3m6 0h3m-13 1h3m5 0h3m-11 1h2m6 0h2m-11 1h3m5 0h3m-12 1h3m5 0h4m-13 1h3m5 0h4m-12 1h2m6 0h3m-12 1h3m5 0h3m-12 1h3m6 0h2m-11 1h3m5 0h3m-12 1h3m5 0h2m-11 1h3m6 0h2m-12 1h3m6 0h2m-2 1h2m-3 1h3m-4 1h3m-4 1h3m-2 1h1"/><path stroke="#465367" d="M50 22h1m0 2h1m7 3h1m1 1h2"/><path stroke="#0a2548" d="M37 24h2m-5 3h2m5 2h1m-6 5h2"/><path stroke="#144a88" d="M36 25h1m4 3h1M31 39h1"/><path stroke="#25a8fa" d="M37 25h2m-3 1h1m1 0h1m0 1h1m-5 1h1m4 0h1m-6 1h1m4 0h1m-5 1h1m4 0h1m-10 1h2m3 0h1m4 0h1m-11 1h1m1 0h1m2 0h1m4 0h1m-12 1h1m3 0h1m2 0h1m4 0h1m-14 1h2m3 0h1m3 0h1m4 0h1m-14 1h1m4 0h1m2 0h1m3 0h1m-12 1h1m4 0h1m2 0h1m1 0h1m-11 1h1m4 0h1m3 0h1m-9 1h1m4 0h1m-5 1h1m4 0h1m-6 1h1m3 0h1m-4 1h1m1 0h1m-2 1h1"/><path stroke="#09203d" d="M39 25h1m-6 1h2m6 4h1m0 1h1m-1 1h1m0 1h2m-9 10h1"/><path stroke="#73cdfa" d="M37 26h1m-1 1h2m-3 1h1m2 0h1m-4 1h2m1 0h1m-3 1h1m2 0h1m-3 1h1m2 0h1m-9 1h1m4 0h2m1 0h1m-9 1h2m4 0h1m2 0h1m-11 1h1m1 0h1m5 0h1m2 0h1m-12 1h1m2 0h1m4 0h2m-9 1h1m1 0h2m4 0h1m-9 1h1m2 0h1m-3 1h1m2 0h1m-3 1h1m2 0h1m-4 1h2m-1 1h1"/><path stroke="#3068a8" d="M39 26h2m-1 1h1m-9 3h4m-5 1h1m2 0h3m-6 1h1m3 0h2"/><path stroke="#91a3b6" d="M16 27h1m-2 1h2m-2 1h2m-3 1h2"/><path stroke="#6cc4fc" d="M36 27h1"/><path stroke="#1c5392" d="M34 28h1m-1 1h1m1 4h2m-6 5h1m-1 1h2m-2 1h2m-1 1h2m-1 1h1"/><path stroke="#9edcfc" d="M37 28h2m-1 1h1m-1 1h2m-1 1h2m-1 1h1m-9 1h1m7 0h2m-9 1h1m7 0h2m-10 1h2m7 0h1m-9 1h1m-1 1h2m-1 1h2m-1 1h2m-1 1h1"/><path stroke="#040e1b" d="M42 29h1m-13 4h1m7 1h1m6 1h1"/><path stroke="#6f839b" d="M31 30h1m-2 1h1"/><path stroke="#242a37" d="M14 32h1"/><path stroke="#3971b1" d="M30 32h1"/><path stroke="#04101e" d="M44 32h1m-2 4h1m-1 1h2m-2 1h1m-5 2h2m-2 1h1m-3 1h1m-2 1h1"/><path stroke="#09203c" d="M29 33h1"/><path stroke="#081e38" d="M29 34h1m15 0h1m-16 1h1m-1 1h2m-2 1h2"/><path stroke="#071a32" d="M37 35h1m-7 3h1m3 4h1"/><path stroke="#02070f" d="M38 35h1m5 0h1m-7 1h2m4 0h2m-8 1h1m1 0h1m1 0h1m-4 1h1m1 0h2m-3 1h1m-3 2h1m-1 1h1m-4 1h1"/><path stroke="#02070d" d="M6 42h2m-3 1h5m-5 1h7m-7 1h7m-6 1h7m-5 1h7m-5 1h5m-3 1h4"/></svg>';
        return svg;
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory output = string(abi.encodePacked(getImageData()));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name":"Magical Rock #', toString(tokenId), '","description":"Woah.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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