/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.8.7;

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

        (bool success, ) = recipient.call{ value: amount }("");
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
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
        uint256 tokenId
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
        uint256 tokenId,
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (
                bytes4 retval
            ) {
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

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)")
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash));
    }
}

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));
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

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] += 1;

        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
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
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer == ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
    }
}

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC721Tradable is ContextMixin, Ownable, ERC721, NativeMetaTransaction {
    address public proxyRegistryAddress;
    uint256 private _currentTokenId = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) Ownable() {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            proxyRegistryAddress != address(0) && address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}

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

library Packed16BitArray {
    using Packed16BitArray for Packed16BitArray.PackedArray;

    struct PackedArray {
        uint256[] array;
        uint256 length;
    }

    // Verifies that the higher level count is correct, and that the last uint256 is left packed with 0's
    function initStruct(uint256[] memory _arr, uint256 _len)
        internal
        pure
        returns (PackedArray memory)
    {
        uint256 actualLength = _arr.length;
        uint256 len0 = _len / 16;
        require(actualLength == len0 + 1, "Invalid arr length");

        uint256 len1 = _len % 16;
        uint256 leftPacked = uint256(_arr[len0] >> (len1 * 16));
        require(leftPacked == 0, "Invalid uint256 packing");

        return PackedArray(_arr, _len);
    }

    function getValue(PackedArray storage ref, uint256 _index) internal view returns (uint16) {
        require(_index < ref.length, "Invalid index");
        uint256 aid = _index / 16;
        uint256 iid = _index % 16;
        return uint16(ref.array[aid] >> (iid * 16));
    }

    function biDirectionalSearch(
        PackedArray storage ref,
        uint256 _startIndex,
        uint16 _delta
    ) internal view returns (uint16[2] memory hits) {
        uint16 startVal = ref.getValue(_startIndex);

        // Search down
        if (startVal >= _delta && _startIndex > 0) {
            uint16 tempVal = startVal;
            uint256 tempIdx = _startIndex - 1;
            uint16 target = startVal - _delta;

            while (tempVal >= target) {
                tempVal = ref.getValue(tempIdx);
                if (tempVal == target) {
                    hits[0] = tempVal;
                    break;
                }
                if (tempIdx == 0) {
                    break;
                } else {
                    tempIdx--;
                }
            }
        }
        {
            // Search up
            uint16 tempVal = startVal;
            uint256 tempIdx = _startIndex + 1;
            uint16 target = startVal + _delta;

            while (tempVal <= target) {
                if (tempIdx >= ref.length) break;
                tempVal = ref.getValue(tempIdx++);
                if (tempVal == target) {
                    hits[1] = tempVal;
                    break;
                }
            }
        }
    }

    function setValue(
        PackedArray storage ref,
        uint256 _index,
        uint16 _value
    ) internal {
        uint256 aid = _index / 16;
        uint256 iid = _index % 16;

        // 1. Do an && between old value and a mask
        uint256 mask = uint256(~(uint256(65535) << (iid * 16)));
        uint256 masked = ref.array[aid] & mask;
        // 2. Do an |= between (1) and positioned _value
        mask = uint256(_value) << (iid * 16);
        ref.array[aid] = masked | mask;
    }

    function extractIndex(PackedArray storage ref, uint256 _index) internal {
        // Get value at the end
        uint16 endValue = ref.getValue(ref.length - 1);
        ref.setValue(_index, endValue);
        // TODO - could get rid of this and rely on length if need to reduce gas
        // ref.setValue(ref.length - 1, 0);
        ref.length--;
    }
}

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

/// @title MathBlocks, Primes
/********************************************
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM *
 * MMMMMMMMMMMMNmdddddddddddddddddmNMMMMMMM *
 * MMMMMMMMMmhyssooooooooooooooooosyhNMMMMM *
 * MMMMMMMmyso+/::::::::::::::::::/osyMMMMM *
 * MMMMMMhys+::/+++++++++++++++++/:+syNMMMM *
 * MMMMNyso/:/+/::::+/:::/+:::::::+oshMMMMM *
 * MMMMmys/-//:/++:/+://-++-+oooossydMMMMMM *
 * MMMMNyso+//+s+/:+/:+/:+/:+syddmNMMMMMMMM *
 * MMMMMNdyyyyso/:++:/+:/+/:+syNMMMMMMMMMMM *
 * MMMMMMMMMhso/:/+/:++:/++-+symMMMMMMMMMMM *
 * MMMMMMMMdys+:/++:/++:/++:/+syNMMMMMMMMMM *
 * MMMMMMMNys+:/++/:+s+:/+++:/oydMMMMMMMMMM *
 * MMMMMMMmys+:/+/:/oso/:///:/sydMMMMMMMMMM *
 * MMMMMMMMhso+///+osyso+///osyhMMMMMMMMMMM *
 * MMMMMMMMMmhyssyyhmMdhyssyydNMMMMMMMMMMMM *
 * MMMMMMMMMMMMMNMMMMMMMMMNMMMMMMMMMMMMMMMM *
 *******************************************/
struct CoreData {
    bool isPrime;
    uint16 primeIndex;
    uint8 primeFactorCount;
    uint16[2] parents;
    uint32 lastBred;
}

struct RentalData {
    bool isRentable;
    bool whitelistOnly;
    uint96 studFee;
    uint32 deadline;
    uint16[6] suitors;
}

struct PrimeData {
    uint16[2] sexyPrimes;
    uint16[2] twins;
    uint16[2] cousins;
}

struct NumberData {
    CoreData core;
    PrimeData prime;
}

struct Activity {
    uint8 tranche0;
    uint8 tranche1;
}

enum Attribute {
    TAXICAB_NUMBER,
    PERFECT_NUMBER,
    EULERS_LUCKY_NUMBER,
    UNIQUE_PRIME,
    FRIENDLY_NUMBER,
    COLOSSALLY_ABUNDANT_NUMBER,
    FIBONACCI_NUMBER,
    REPDIGIT_NUMBER,
    WEIRD_NUMBER,
    TRIANGULAR_NUMBER,
    SOPHIE_GERMAIN_PRIME,
    STRONG_PRIME,
    FRUGAL_NUMBER,
    SQUARE_NUMBER,
    EMIRP,
    MAGIC_NUMBER,
    LUCKY_NUMBER,
    GOOD_PRIME,
    HAPPY_NUMBER,
    UNTOUCHABLE_NUMBER,
    SEMIPERFECT_NUMBER,
    HARSHAD_NUMBER,
    EVIL_NUMBER
}

contract TokenAttributes {
    bytes32 public attributesRootHash;
    mapping(uint256 => uint256) internal packedTokenAttrs;

    event RevealedAttributes(uint256 tokenId, uint256 attributes);

    constructor(bytes32 _attributesRootHash) {
        attributesRootHash = _attributesRootHash;
    }

    /***************************************
                    ATTRIBUTES
    ****************************************/

    function revealAttributes(
        uint256 _tokenId,
        uint256 _attributes,
        bytes32[] memory _merkleProof
    ) public {
        bytes32 leaf = keccak256(abi.encodePacked(_tokenId, _attributes));
        require(MerkleProof.verify(_merkleProof, attributesRootHash, leaf), "Invalid merkle proof");
        packedTokenAttrs[_tokenId] = _attributes;
        emit RevealedAttributes(_tokenId, _attributes);
    }

    function getAttributes(uint256 _tokenId) public view returns (bool[23] memory attributes) {
        uint256 packed = packedTokenAttrs[_tokenId];
        for (uint8 i = 0; i < 23; i++) {
            attributes[i] = _getAttr(packed, i);
        }
        return attributes;
    }

    function _getAttr(uint256 _packed, uint256 _attribute) internal pure returns (bool attribute) {
        uint256 flag = (_packed >> _attribute) & uint256(1);
        attribute = flag == 1;
    }
}

library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

library PrimesTokenURI {
    string internal constant DESCRIPTION = "Primes is MathBlocks Collection #1.";
    string internal constant STYLE =
        "<style>.p #bg{fill:#ddd} .c #bg{fill:#222} .p .factor,.p #text{fill:#222} .c .factor,.c #text{fill:#ddd} .sexy{fill:#e44C21} .cousin{fill:#348C47} .twin {fill:#3C4CE1} #grid .factor{r: 8} .c #icons *{fill: #ddd} .p #icons * {fill:#222} #icons .stroke *{fill:none} #icons .stroke {fill:none;stroke:#222;stroke-width:8} .c #icons .stroke{stroke:#ddd} .square{stroke-width:2;fill:none;stroke:#222;r:8} .c .square{stroke:#ddd} #icons #i-4 circle{stroke-width:20}</style>";

    function tokenURI(
        uint256 _tokenId,
        NumberData memory _numberData,
        uint16[] memory _factors,
        bool[23] memory _attributeValues
    ) public pure returns (string memory output) {
        string[24] memory parts;

        // 23 attributes revealed with merkle proof
        for (uint8 i = 0; i < 23; i++) {
            parts[i] = _attributeValues[i]
                ? string(abi.encodePacked('{ "value": "', _attributeNames(i), '" }'))
                : "";
        }

        // Last attribute: Unit/Prime/Composite
        parts[23] = string(
            abi.encodePacked(
                '{ "value": "',
                _tokenId == 1 ? "Unit" : _numberData.core.isPrime ? "Prime" : "Composite",
                '" }'
            )
        );

        string memory json = string(
            abi.encodePacked(
                '{ "name": "Primes #',
                _toString(_tokenId),
                '", "description": "',
                DESCRIPTION,
                '", "attributes": [',
                _getAttributes(parts),
                '], "image": "',
                _getImage(_tokenId, _numberData, _factors, _attributeValues),
                '" }'
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json)))
        );
    }

    function _getImage(
        uint256 _tokenId,
        NumberData memory _numberData,
        uint16[] memory _factors,
        bool[23] memory _attributeValues
    ) internal pure returns (string memory output) {
        // 350x350 canvas
        // padding: 14
        // 14x14 grid (bottom row for icons etc)
        // grid square: 23
        // inner square: 16 (circle r=8)
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350">',
                _svgContent(_tokenId, _numberData, _factors, _attributeValues),
                "</svg>"
            )
        );

        output = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }

    function _svgContent(
        uint256 _tokenId,
        NumberData memory _numberData,
        uint16[] memory _factors,
        bool[23] memory _attributeValues
    ) internal pure returns (string memory output) {
        output = string(
            abi.encodePacked(
                STYLE,
                '<g class="',
                _numberData.core.isPrime && _tokenId != 1 ? "p" : "c",
                '"><rect id="bg" width="100%" height="100%" />',
                _circles(_tokenId, _numberData, _factors),
                _text(_tokenId),
                _icons(_tokenId, _numberData.core.isPrime, _attributeValues),
                "</g>"
            )
        );
    }

    function _text(uint256 _tokenId) internal pure returns (string memory output) {
        uint256[] memory digits = _getDigits(_tokenId);

        // 16384 has an extra row; move the text to the top right to avoid an overlap
        uint256 dx = _tokenId == 16384 ? 277 : 18;
        uint256 dy = _tokenId == 16384 ? 18 : 318;

        output = string(
            abi.encodePacked(
                '<g id="text" transform="translate(',
                _toString(dx),
                ",",
                _toString(dy),
                ')">',
                _getNumeralPath(digits, 0),
                _getNumeralPath(digits, 1),
                _getNumeralPath(digits, 2),
                _getNumeralPath(digits, 3),
                _getNumeralPath(digits, 4),
                "</g>"
            )
        );
    }

    function _getNumeralPath(uint256[] memory _digits, uint256 _index)
        internal
        pure
        returns (string memory output)
    {
        if (_digits.length <= _index) {
            return output;
        }
        output = string(
            abi.encodePacked(
                '<g transform="translate(',
                _toString(_index * 12),
                ',0)"><path d="',
                _getNumeralPathD(_digits[_index]),
                '" /></g>'
            )
        );
    }

    // Space Mono numerals
    function _getNumeralPathD(uint256 _digit) internal pure returns (string memory) {
        if (_digit == 0) {
            return
                "M0 5.5a6 6 0 0 1 1.3-4C2 .4 3.3 0 4.7 0c1.5 0 2.7.5 3.5 1.4a6 6 0 0 1 1.3 4.1v3c0 1.8-.5 3.2-1.3 4.1-.8 1-2 1.4-3.5 1.4s-2.6-.5-3.5-1.4C.4 11.6 0 10.3 0 8.5v-3Zm4.7 7c1 0 1.8-.3 2.4-1 .5-.8.7-1.8.7-3.1V5.6L7.7 4 7 2.6l-1-.8c-.4-.2-.9-.3-1.4-.3-.5 0-1 0-1.3.3l-1 .8c-.3.4-.5.8-.6 1.3l-.2 1.7v2.8c0 1.3.3 2.3.8 3 .5.8 1.3 1.1 2.3 1.1ZM3.5 7c0-.3.1-.6.4-.9.2-.2.5-.3.8-.3.4 0 .7 0 .9.3.2.3.4.6.4.9 0 .3-.2.6-.4.9-.2.2-.5.3-.9.3-.3 0-.6 0-.8-.3-.3-.3-.4-.6-.4-.9Z";
        } else if (_digit == 1) {
            return "M4 12.2V1h-.2L1.6 6H0L2.5.2h3.2v12h3.8v1.4H.2v-1.5H4Z";
        } else if (_digit == 2) {
            return
                "M9.2 12.2v1.5h-9v-2.3c0-.6 0-1.1.2-1.6.2-.4.5-.8.9-1.1.4-.4.8-.7 1.4-.9l1.8-.5c1.1-.3 2-.7 2.5-1.1.5-.5.7-1 .7-1.8l-.1-1.1-.6-1c-.2-.2-.5-.4-1-.5-.3-.2-.7-.3-1.3-.3a3 3 0 0 0-2.3.9c-.5.6-.8 1.4-.8 2.4v.9H0v-1l.3-1.8c.2-.5.5-1 1-1.5.3-.4.8-.8 1.4-1a5 5 0 0 1 2-.4c.8 0 1.5.1 2 .4.6.2 1.1.5 1.5 1 .4.3.7.7.9 1.2.2.5.2 1 .2 1.5v.4c0 1-.3 1.9-1 2.6-.6.7-1.6 1.2-3 1.6-1.2.2-2.1.6-2.7 1-.6.5-.9 1.1-.9 2v.5h7.5Z";
        } else if (_digit == 3) {
            return
                "M3.3 7V4.8L7.7 2v-.2H.1V.3h9v2.4L4.7 5.5v.3h.8a3.7 3.7 0 0 1 4 3.8v.3a3.8 3.8 0 0 1-1.3 3A4.8 4.8 0 0 1 4.9 14c-.8 0-1.5-.1-2-.3a4.4 4.4 0 0 1-2.5-2.4C0 10.7 0 10.2 0 9.5v-1h1.6v1c0 .4 0 .8.2 1.2l.7 1 1 .6a3.8 3.8 0 0 0 2.5 0 3 3 0 0 0 1-.6c.3-.2.5-.5.6-.9.2-.3.2-.7.2-1v-.2c0-.8-.2-1.4-.7-1.9-.5-.4-1.2-.7-2-.7H3.4Z";
        } else if (_digit == 4) {
            return "M4.7.3h3.1v9.4H10v1.5H8v2.5H6.1v-2.5H0V9L4.7.3ZM1.4 9.5v.2h4.8V1H6L1.4 9.5Z";
        } else if (_digit == 5) {
            return
                "M.2 7.4V.3h8.5v1.5H1.8v4.8H2l.5-.8a3.4 3.4 0 0 1 1.7-1l1.1-.2c.7 0 1.2.1 1.7.3a3.9 3.9 0 0 1 2.3 2.2c.2.6.3 1.1.3 1.8v.3c0 .7-.1 1.3-.3 1.9-.2.5-.5 1-1 1.5-.3.4-.8.8-1.4 1a5 5 0 0 1-2 .4c-.8 0-1.5-.1-2.1-.3-.6-.3-1.1-.6-1.5-1-.5-.4-.8-.9-1-1.4C.1 10.7 0 10 0 9.3V9h1.6v.4c0 1 .3 1.9.9 2.4.6.5 1.4.8 2.3.8.6 0 1 0 1.4-.3l1-.7.6-1.1L8 9V9a3 3 0 0 0-.8-2c-.2-.3-.5-.5-.9-.7a2.6 2.6 0 0 0-1.8 0 2 2 0 0 0-.6.2l-.4.4-.2.5h-3Z";
        } else if (_digit == 6) {
            return
                "M7.5 4.2c0-.8-.3-1.5-.8-2s-1.2-.8-2.1-.8l-1.2.3c-.4.1-.7.3-1 .6a3.2 3.2 0 0 0-.8 2.4v2h.2c.4-.6.8-1 1.4-1.4.5-.3 1.2-.5 1.9-.5.6 0 1.2.1 1.7.4.5.1 1 .4 1.3.8l1 1.4.2 1.9v.2A4.5 4.5 0 0 1 8 12.8c-.4.3-.9.7-1.5.9a5.2 5.2 0 0 1-3.7 0c-.6-.2-1-.5-1.5-1-.4-.3-.7-.8-1-1.3L0 9.6v-5c0-.7.1-1.3.4-1.9.2-.5.5-1 1-1.4.4-.4.9-.8 1.4-1a5.4 5.4 0 0 1 3.6 0 4 4 0 0 1 2.7 3.9H7.5Zm-2.8 8.4c.4 0 .9 0 1.2-.2l1-.7c.3-.2.5-.6.6-1 .2-.3.2-.7.2-1.2v-.2c0-.4 0-.9-.2-1.2a2.7 2.7 0 0 0-1.6-1.6c-.4-.2-.8-.2-1.2-.2a3.1 3.1 0 0 0-2.2.8 3 3 0 0 0-.9 2.1v.4c0 .4 0 .8.2 1.2a2.7 2.7 0 0 0 1.6 1.6l1.3.2Z";
        } else if (_digit == 7) {
            return
                "M0 .3h9v2.3l-5.7 8.6-.6 1a2 2 0 0 0-.2 1v.5H.9V12.4a3.9 3.9 0 0 1 .7-1.3l.5-.8L7.6 2v-.2H0V.3Z";
        } else if (_digit == 8) {
            return
                "M4.5 14a6 6 0 0 1-1.8-.3L1.2 13l-.9-1.2c-.2-.4-.3-1-.3-1.5v-.2A3.3 3.3 0 0 1 .8 8a3.3 3.3 0 0 1 1.7-1v-.3a3 3 0 0 1-.8-.4c-.3-.1-.5-.4-.7-.6a3 3 0 0 1-.6-1.9v-.2A3.2 3.2 0 0 1 1.4 1a5.4 5.4 0 0 1 3.1-1h.1C5.4 0 6 0 6.5.3c.5.1 1 .4 1.3.7A3.1 3.1 0 0 1 9 3.5v.2c0 .4 0 .7-.2 1 0 .4-.2.7-.5.9a3 3 0 0 1-.6.6 3 3 0 0 1-.9.4V7a3.7 3.7 0 0 1 1.8 1 3.3 3.3 0 0 1 .7 2.2v.2A3.3 3.3 0 0 1 8.1 13l-1.4.7a6 6 0 0 1-1.9.3h-.3Zm.3-1.5c.9 0 1.6-.2 2.1-.6.6-.5.8-1 .8-1.8V10c0-.8-.3-1.4-.8-1.8-.6-.5-1.3-.7-2.2-.7-1 0-1.7.2-2.3.7-.5.4-.8 1-.8 1.8v.1c0 .7.3 1.3.8 1.8.6.4 1.3.6 2.2.6h.2ZM4.7 6a3 3 0 0 0 2-.6c.4-.5.7-1 .7-1.6v-.1A2 2 0 0 0 6.6 2a3 3 0 0 0-2-.6 3 3 0 0 0-2 .6A2 2 0 0 0 2 3.7c0 .7.2 1.2.7 1.7a3 3 0 0 0 2 .6Z";
        } else {
            return
                "M1.8 9.8c0 .8.3 1.5.8 2a3 3 0 0 0 2.1.8c.5 0 .9-.1 1.2-.3.4-.1.7-.3 1-.6.3-.3.5-.6.6-1 .2-.4.2-.9.2-1.4v-2h-.2c-.3.6-.7 1-1.3 1.4-.5.3-1.2.5-1.9.5a5 5 0 0 1-1.7-.3A3.8 3.8 0 0 1 .3 6.6C.1 6.1 0 5.5 0 4.8v-.2c0-.7.1-1.3.3-1.9A4.2 4.2 0 0 1 2.8.3 5 5 0 0 1 4.7 0 4.9 4.9 0 0 1 8 1.3c.4.4.8.8 1 1.4.2.5.3 1.1.3 1.8v4.8a5 5 0 0 1-.3 2 4.3 4.3 0 0 1-2.5 2.4 5.5 5.5 0 0 1-3.6 0L1.5 13l-1-1.3-.3-1.8h1.6Zm2.9-8.4c-.5 0-1 .1-1.3.3a2.8 2.8 0 0 0-1.6 1.6l-.2 1.2v.3c0 .4 0 .8.2 1.2l.7 1 1 .5c.3.2.7.2 1.2.2.4 0 .8 0 1.2-.2a3 3 0 0 0 1-.6l.6-1c.2-.3.2-.7.2-1v-.4c0-.5 0-.9-.2-1.2-.1-.4-.3-.7-.6-1-.3-.3-.6-.5-1-.6-.3-.2-.8-.3-1.2-.3Z";
        }
    }

    function _getIconGeometry(uint256 _attribute) internal pure returns (string memory) {
        if (_attribute == 0) {
            // Taxicab Number
            return
                '<rect y="45" width="15" height="15" rx="2"/><rect x="15" y="30" width="15" height="15" rx="2"/><rect x="30" y="15" width="15" height="15" rx="2"/><path d="M45 2c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H47a2 2 0 0 1-2-2V2Z"/><path d="M45 32c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H47a2 2 0 0 1-2-2V32Z"/><path d="M30 47c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H32a2 2 0 0 1-2-2V47Z"/><path d="M0 17c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V17Z"/><path d="M15 2c0-1.1.9-2 2-2h11a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H17a2 2 0 0 1-2-2V2Z"/>';
        } else if (_attribute == 1) {
            // Perfect Number
            return
                '<g class="stroke"><path d="m12 12 37 37"/><path d="m12 49 37-37"/><path d="M5.4 30H56"/><path d="M30.7 55.3V4.7"/></g>';
        } else if (_attribute == 2) {
            // Euler's Lucky Numbers
            return
                '<path d="M30.8 7.3c-10 0-15.4 5.9-16.4 17.8 0 .6.3.8 1 .8h29c.6 0 1-.2 1-.8C44.8 13.2 40 7.3 30.7 7.3Zm2.3 52c-8.8 0-15.6-2.4-20.2-7.2C8.3 47 6 39.9 6 30c0-10 2.2-17.3 6.6-22A23.8 23.8 0 0 1 30.8 1C45 1 52.5 9.4 53.4 26.2c0 1.7-.5 3.2-1.8 4.4a6.2 6.2 0 0 1-4.5 1.7h-32c-.5 0-.8.3-.8 1C15 46.5 21.5 53 34 53c4 0 8.3-.8 12.6-2.3.8-.3 1.5-.2 2.3.3.7.4 1 1 1 2 0 2.4-1 4-3.3 4.5-4.6 1.1-9 1.7-13.4 1.7Z"/>';
        } else if (_attribute == 3) {
            // Unique Prime
            return '<circle class="stroke" cx="30" cy="30" r="20"/>';
        } else if (_attribute == 4) {
            // Friendly Number
            return
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M30 60a30 30 0 1 0 0-60 30 30 0 0 0 0 60ZM17.5 31c3.6 0 6.5-4.3 6.5-9.5S21 12 17.5 12c-3.6 0-6.5 4.3-6.5 9.5s3 9.5 6.5 9.5ZM49 21.5c0 5.2-3 9.5-6.5 9.5-3.6 0-6.5-4.3-6.5-9.5s3-9.5 6.5-9.5c3.6 0 6.5 4.3 6.5 9.5Zm-2.8 21.9a4 4 0 1 0-6.4-4.8c-5.1 7-15.2 7.3-20.6 0a4 4 0 0 0-6.4 4.8 20.5 20.5 0 0 0 33.4 0Z"/>';
        } else if (_attribute == 5) {
            // Colossally Abundant Number
            return
                '<path d="M34 4a4 4 0 0 0-8 0v22H4a4 4 0 0 0 0 8h22v22a4 4 0 0 0 8 0V34h22a4 4 0 0 0 0-8H34V4Z"/>';
        } else if (_attribute == 6) {
            // Fibonacci Number
            return
                '<path class="stroke" d="M31.3 23a.6.6 0 0 0 0-.4.6.6 0 0 0-.5-.2h-.3a.8.8 0 0 0-.5.3l-.1.4v.3a1 1 0 0 0 .5.7 1.2 1.2 0 0 0 .9.2l.5-.2.4-.5.2-.5a1.7 1.7 0 0 0-.3-1.3 2 2 0 0 0-1.3-.8h-.9l-.8.4c-.3.1-.5.4-.7.7-.2.3-.3.6-.3 1a3 3 0 0 0 .5 2.2 3.3 3.3 0 0 0 2.2 1.4h1.5a4 4 0 0 0 1.4-.7c.5-.3.9-.7 1.2-1.2a5.1 5.1 0 0 0-.2-5.6 5.8 5.8 0 0 0-3.9-2.4c-.8-.2-1.7-.2-2.6 0a7 7 0 0 0-2.5 1.2 8 8 0 0 0-2 2.1c-.5.9-.9 1.9-1 3a8.8 8.8 0 0 0 1.5 6.7 10 10 0 0 0 6.6 4.1c1.4.3 3 .3 4.4 0a13 13 0 0 0 7.8-5.6c1-1.6 1.6-3.4 2-5.2a15.2 15.2 0 0 0-2.7-11.6 17.2 17.2 0 0 0-11.5-7.2c-2.4-.4-5-.4-7.6.2-2.6.6-5.2 1.7-7.5 3.3a22.6 22.6 0 0 0-6 6.4 24.5 24.5 0 0 0-3.3 8.9A26.3 26.3 0 0 0 11 43a29.7 29.7 0 0 0 19.8 12.4A33.5 33.5 0 0 0 54.2 51"/>';
        } else if (_attribute == 7) {
            // Repdigit Number
            return
                '<g class="stroke"><path d="M44 20.8h13.8V7"/><path d="M12 11a25.4 25.4 0 0 1 36 0l9.8 9.8"/><path d="M16 37.2H2.3V51"/><path d="M48 47a25.4 25.4 0 0 1-36 0l-9.8-9.8"/></g>';
        } else if (_attribute == 8) {
            // Weird Number
            return
                '<path d="M28.8 41.6c-1.8 0-3.3-1.5-3-3.3.1-1.3.4-2.4.7-3.3a17 17 0 0 1 3.6-5.4l4.6-4.7c2-2.3 3-4.7 3-7.2s-.7-4.4-2-5.8c-1.3-1.4-3.2-2.1-5.6-2.1-2.4 0-4.3.6-5.8 1.9-.6.6-1.1 1.2-1.5 2-.8 1.6-2.1 3.1-3.9 3.1-1.8 0-3.3-1.5-2.9-3.2.6-2.4 1.8-4.4 3.7-6 2.7-2.3 6.1-3.5 10.4-3.5 4.4 0 7.9 1.2 10.3 3.6 2.5 2.4 3.7 5.6 3.7 9.8 0 4-1.9 8.1-5.6 12.1l-3.9 3.8a10 10 0 0 0-2.3 5c-.3 1.7-1.7 3.2-3.5 3.2Zm-3.5 11.1c0-1 .3-1.9 1-2.6.6-.7 1.5-1.1 2.8-1.1 1.3 0 2.2.4 2.9 1 .6.8 1 1.7 1 2.7 0 1-.4 2-1 2.7-.7.6-1.6 1-2.9 1-1.3 0-2.2-.4-2.9-1-.6-.7-1-1.6-1-2.7Z"/>';
        } else if (_attribute == 9) {
            // Triangular Number
            return
                '<path d="M2 51 28.2 8.6a2 2 0 0 1 3.4 0L58.1 51a2 2 0 0 1-1.7 3.1H3.6A2 2 0 0 1 2 51Z"/>';
        } else if (_attribute == 10) {
            // Sophie Germain Prime
            return
                '<path d="M11.6 32.2c-4.1-1.4-7-3.1-9-5.1C1 25.1 0 22.7 0 19.9c0-3.2 1-5.8 3-7.6 2-1.9 4.8-2.8 8.3-2.8 3.3 0 6.2.4 8.7 1.2.8.3 1.4.7 1.9 1.5.5.7.7 1.5.7 2.3 0 .6-.3 1.1-.8 1.5-.5.3-1 .3-1.7 0a21 21 0 0 0-8.3-1.7c-1.9 0-3.4.5-4.4 1.5-1 1-1.6 2.3-1.6 4a6 6 0 0 0 1.5 4c1 1.1 2.4 2 4.3 2.6 4.7 1.7 8 3.4 9.8 5.4 1.9 2 2.8 4.5 2.8 7.5 0 3.7-1 6.5-3.3 8.4-2.2 1.9-5.5 2.8-9.9 2.8-2.8 0-5.4-.4-7.7-1.3-1.6-.7-2.5-2-2.5-4 0-.7.3-1.1.8-1.4.6-.3 1-.3 1.6 0a15 15 0 0 0 7.3 1.8c5.2 0 7.8-2.1 7.8-6.3 0-1.6-.5-3-1.6-4.1-1-1.1-2.7-2.1-5.1-3Z"/><path d="M47.6 50.5c-5.5 0-10-1.9-13.5-5.6A20.8 20.8 0 0 1 28.8 30c0-6.3 1.8-11.3 5.3-15 3.6-3.7 8.4-5.5 14.6-5.5 2.5 0 4.8.2 7 .5a3.1 3.1 0 0 1 2.5 3.1c0 .7-.3 1.2-.8 1.6a2 2 0 0 1-1.7.3c-2-.5-4-.7-6.5-.7-4.6 0-8.2 1.4-10.7 4C36 21 34.8 25 34.8 30a17 17 0 0 0 3.7 11.5c2.4 2.8 5.6 4.2 9.7 4.2 2 0 4-.3 5.8-.9.2 0 .3-.2.3-.5V31.5c0-.3-.1-.5-.4-.5H45c-.7 0-1.2-.2-1.7-.6-.4-.5-.6-1-.6-1.7s.2-1.2.6-1.7c.5-.4 1-.7 1.7-.7h11.8a3 3 0 0 1 2.2 1 3 3 0 0 1 .9 2.2v15.4c0 1-.3 1.8-.8 2.6s-1.2 1.3-2 1.6c-2.9 1-6 1.4-9.6 1.4Z"/>';
        } else if (_attribute == 11) {
            // Strong Prime
            return
                '<g class="stroke"><path d="M4 28h52"/><path d="M16 40V15"/><path d="M10 34V21"/><path d="M43.6 40V15"/><path d="M50 34.8V20.2"/></g>';
        } else if (_attribute == 12) {
            // Frugal Number
            return
                '<circle cx="8" cy="29" r="8"/><circle cx="30" cy="29" r="8"/><circle cx="52" cy="29" r="8"/>';
        } else if (_attribute == 13) {
            // Square Number
            return '<rect width="60" height="60" rx="2"/>';
        } else if (_attribute == 14) {
            // EMIRP
            return
                '<path d="m14.8 27.7 21.4-16.1a4 4 0 0 0 1.6-3.2V4a2 2 0 0 0-3.2-1.6L2.3 26.8l-.6.4c-.9.6-1.7 1.2-1.7 2.1 0 .7.3 1.4.7 1.7l33.8 28a2 2 0 0 0 3.3-1.5v-5.1a4 4 0 0 0-1.4-3L14.7 30.8a2 2 0 0 1 .1-3.2ZM59.8 5v52.6a2 2 0 0 1-3.3 1.5L22.7 31a2 2 0 0 1 0-3l34-25.7c1.2-1 3.1 1 3.1 2.6Z"/>';
        } else if (_attribute == 15) {
            // Magic Number
            return
                '<path d="M28.1 2.9a2 2 0 0 1 3.8 0l5.5 16.9a2 2 0 0 0 2 1.4H57a2 2 0 0 1 1.2 3.6L44 35.3a2 2 0 0 0-.7 2.2l5.5 17a2 2 0 0 1-3.1 2.2L31.2 46.2a2 2 0 0 0-2.4 0L14.4 56.7a2 2 0 0 1-3-2.2l5.4-17a2 2 0 0 0-.7-2.2L1.7 24.8a2 2 0 0 1 1.2-3.6h17.8a2 2 0 0 0 1.9-1.4l5.5-17Z"/>';
        } else if (_attribute == 16) {
            // Lucky Number
            return
                '<path d="M31.3 23.8a2 2 0 0 1-2.6 0C20.3 16.4 16 12.4 16 7.5 16 3.4 19.3 0 23.5 0a9 9 0 0 1 4.8 1.3c1 .7 2.4.7 3.4 0C33 .5 34.7 0 36.3 0 40.5 0 44 3.2 44 7.3c0 5-4.3 9.1-12.7 16.5Z"/><path d="M23.8 28.7C16.4 20.3 12.4 16 7.3 16c-4 0-7.3 3.5-7.3 7.7 0 1.7.5 3.3 1.3 4.6.7 1 .7 2.4 0 3.4A9 9 0 0 0 0 36.5C0 40.7 3.4 44 7.5 44c4.9 0 9-4.3 16.3-12.7a2 2 0 0 0 0-2.6Z"/><path d="M52.7 44c-5 0-9.1-4.3-16.5-12.7a2 2 0 0 1 0-2.6C43.6 20.3 47.6 16 52.5 16c4 0 7.5 3.3 7.5 7.5a9 9 0 0 1-1.3 4.8c-.7 1-.7 2.4 0 3.4.8 1.3 1.3 3 1.3 4.6 0 4.2-3.2 7.7-7.3 7.7Z"/><path d="M28.7 36.2C20.3 43.6 16 47.6 16 52.7c0 4 3.5 7.3 7.7 7.3 1.7 0 3.3-.5 4.6-1.3 1-.7 2.4-.7 3.4 0a9 9 0 0 0 4.8 1.3c4.2 0 7.5-3.4 7.5-7.5 0-4.9-4.3-9-12.7-16.3a2 2 0 0 0-2.6 0Z"/>';
        } else if (_attribute == 17) {
            // Good Prime
            return
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M56.6 8.3c2 1.4 2.5 4.2 1 6.3l-29.2 42a4.5 4.5 0 0 1-7.3.1L2.4 32.2a4.5 4.5 0 1 1 7.2-5.4l15 19.6 25.7-37c1.4-2 4.2-2.5 6.3-1Z"/>';
        } else if (_attribute == 18) {
            // Happy Number
            return
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M30 60a30 30 0 1 0 0-60 30 30 0 0 0 0 60ZM17.5 23c5 0 6.5 3.7 6.5-1.5S21 12 17.5 12c-3.6 0-6.5 4.3-6.5 9.5s1.5 1.5 6.5 1.5ZM49 21.5c0 5.2-2 1.5-6.5 1.5-5 0-6.5 3.7-6.5-1.5s3-9.5 6.5-9.5c3.6 0 6.5 4.3 6.5 9.5Zm-2.8 21.9c1.3-1.8 1.4-5.6-.8-5.6H13.6a4 4 0 0 0-.8 5.6 20.5 20.5 0 0 0 33.4 0Z"/>';
        } else if (_attribute == 19) {
            // Untouchable Number
            return
                '<path d="M8.8 2.2a4 4 0 0 0-5.6 5.6l21.6 21.7L3.2 51.2a4 4 0 1 0 5.6 5.6l21.7-21.6 21.7 21.6a4 4 0 1 0 5.6-5.6L36.2 29.5 57.8 7.8a4 4 0 1 0-5.6-5.6L30.5 23.8 8.8 2.2Z"/>';
        } else if (_attribute == 20) {
            // Semiperfect Number
            return
                '<path fill-rule="evenodd" clip-rule="evenodd" d="M42.7 1a4 4 0 0 1 4 4v50.6a4 4 0 1 1-8 0V40.2l-11.9 12a4 4 0 1 1-5.6-5.7l12.1-12.2H17a4 4 0 0 1 0-8h15.3L21.2 15a4 4 0 1 1 5.6-5.6l12 11.8V5a4 4 0 0 1 4-4Z"/>';
        } else if (_attribute == 21) {
            // Harshad Number
            return
                '<path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0Z"/><path d="M3.2 57.8a4 4 0 0 1 0-5.6l49-49a4 4 0 0 1 5.6 5.6l-49 49a4 4 0 0 1-5.6 0Z"/><path d="M52 60a8 8 0 1 0 0-16 8 8 0 0 0 0 16Z"/>';
        } else if (_attribute == 22) {
            // Evil Number
            return
                '<path d="M28.3 2.6 23 11a2 2 0 0 0 1.7 3.1H26v12h-7a6 6 0 0 1-6-6v-6h.4a2 2 0 0 0 1.8-3L13 7.4V7h-.3l-2.5-4.2a2 2 0 0 0-3.4 0l-5 8.2a2 2 0 0 0 1.8 3H5v6a14 14 0 0 0 14 14h7v22a4 4 0 1 0 8 0V34h8a14 14 0 0 0 14-14v-6h.4a2 2 0 0 0 1.8-3L56 7.4V7h-.3l-2.5-4.2a2 2 0 0 0-3.4 0l-5 8.2a2 2 0 0 0 1.8 3H48v6a6 6 0 0 1-6 6h-8V14h1.3a2 2 0 0 0 1.7-3l-5.3-8.4a2 2 0 0 0-3.4 0Z"/>';
        } else if (_attribute == 23) {
            // Unit
            return
                '<path d="M30-.5c.7 0 1.4.2 2 .5h12a4 4 0 0 1 0 8h-9.5v44H44a4 4 0 0 1 0 8H32a4.5 4.5 0 0 1-4 0H17a4 4 0 0 1 0-8h8.5V8H17a4 4 0 0 1 0-8h11c.6-.3 1.3-.5 2-.5Z"/>';
        } else if (_attribute == 24) {
            // Prime
            return '<circle cx="30" cy="30" r="30"/>';
        } else {
            // Composite
            return '<circle class="stroke" cx="30" cy="30" r="26"/>';
        }
    }

    function _icons(
        uint256 _tokenId,
        bool _isPrime,
        bool[23] memory _attributeValues
    ) internal pure returns (string memory output) {
        string memory icons;
        uint256 count = 0;
        for (uint256 i = 24; i > 0; i--) {
            string memory icon;

            if (i == 24) {
                uint256 specialIdx = _tokenId == 1 ? 23 : _isPrime ? 24 : 25;
                icon = _getIconGeometry(specialIdx);
            } else if (_attributeValues[i - 1]) {
                icon = _getIconGeometry(i - 1);
            } else {
                continue;
            }

            // icon geom width = 60
            // scale = 16/60 = 0.266
            // spacing = (60/16) * 23 = 86.25
            uint256 x = ((count * 1e2) * (8625)) / 1e2;
            icons = string(
                abi.encodePacked(
                    icons,
                    '<g id="i-',
                    _toString(i),
                    '" transform="scale(.266) translate(-',
                    _toDecimalString(x, 2),
                    ',0)">',
                    icon,
                    "</g>"
                )
            );
            count = count + 1;
        }
        output = string(
            abi.encodePacked('<g id="icons" transform="translate(317,317)">', icons, "</g>")
        );
    }

    function _circles(
        uint256 _tokenId,
        NumberData memory _numberData,
        uint16[] memory _factors
    ) internal pure returns (string memory output) {
        uint256 nFactor = _factors.length;
        string memory factorStr;
        string memory twinStr;
        string memory cousinStr;
        string memory sexyStr;
        string memory squareStr;

        {
            bool[14][] memory factorRows = _getBitRows(_factors);
            for (uint256 i = 0; i < nFactor; i++) {
                for (uint256 j = 0; j < 14; j++) {
                    if (factorRows[i][j]) {
                        factorStr = string(abi.encodePacked(factorStr, _circle(j, i, "factor")));
                    }
                }
            }
        }

        {
            uint16[] memory squares = _getSquares(_tokenId);
            bool[14][] memory squareRows = _getBitRows(squares);

            for (uint256 i = 0; i < squareRows.length; i++) {
                for (uint256 j = 0; j < 14; j++) {
                    if (squareRows[i][j]) {
                        squareStr = string(
                            abi.encodePacked(squareStr, _circle(j, nFactor + i, "square"))
                        );
                    }
                }
            }
            squareStr = string(abi.encodePacked('<g opacity=".2">', squareStr, "</g>"));
        }

        {
            bool[14][] memory twinRows = _getBitRows(_numberData.prime.twins);
            bool[14][] memory cousinRows = _getBitRows(_numberData.prime.cousins);
            bool[14][] memory sexyRows = _getBitRows(_numberData.prime.sexyPrimes);

            for (uint256 i = 0; i < 2; i++) {
                for (uint256 j = 0; j < 14; j++) {
                    if (twinRows[i][j]) {
                        twinStr = string(
                            abi.encodePacked(twinStr, _circle(j, nFactor + i, "twin"))
                        );
                    }
                    if (cousinRows[i][j]) {
                        cousinStr = string(
                            abi.encodePacked(cousinStr, _circle(j, nFactor + 2 + i, "cousin"))
                        );
                    }
                    if (sexyRows[i][j]) {
                        sexyStr = string(
                            abi.encodePacked(sexyStr, _circle(j, nFactor + 4 + i, "sexy"))
                        );
                    }
                }
            }
        }

        output = string(
            abi.encodePacked(
                '<g id="grid" transform="translate(26,26)">',
                squareStr,
                twinStr,
                cousinStr,
                sexyStr,
                factorStr,
                "</g>"
            )
        );
    }

    function _getSquares(uint256 _tokenId) internal pure returns (uint16[] memory) {
        uint16[] memory squares = new uint16[](14);
        if (_tokenId > 1) {
            for (uint256 i = 0; i < 14; i++) {
                uint256 square = _tokenId**(i + 2);
                if (square > 16384) {
                    break;
                }
                squares[i] = uint16(square);
            }
        }
        return squares;
    }

    function _circle(
        uint256 _xIndex,
        uint256 _yIndex,
        string memory _class
    ) internal pure returns (string memory output) {
        string memory duration;

        uint256 index = (_yIndex * 14) + _xIndex + 1;
        if (index == 1) {
            duration = "40";
        } else {
            uint256 reciprocal = (1e6 * 1e6) / (1e6 * index);
            duration = _toDecimalString(reciprocal * 40, 6);
        }

        output = string(
            abi.encodePacked(
                '<circle r="8" cx="',
                _toString(23 * _xIndex),
                '" cy="',
                _toString(23 * _yIndex),
                '" class="',
                _class,
                '">',
                '<animate attributeName="opacity" values="1;.3;1" dur="',
                duration,
                's" repeatCount="indefinite"/>',
                "</circle>"
            )
        );
    }

    function _getBits(uint16 _input) internal pure returns (bool[14] memory) {
        bool[14] memory bits;
        for (uint8 i = 0; i < 14; i++) {
            uint16 flag = (_input >> i) & uint16(1);
            bits[i] = flag == 1;
        }
        return bits;
    }

    function _getBitRows(uint16[] memory _inputs) internal pure returns (bool[14][] memory) {
        bool[14][] memory rows = new bool[14][](_inputs.length);
        for (uint8 i = 0; i < _inputs.length; i++) {
            rows[i] = _getBits(_inputs[i]);
        }
        return rows;
    }

    function _getBitRows(uint16[2] memory _inputs) internal pure returns (bool[14][] memory) {
        bool[14][] memory rows = new bool[14][](_inputs.length);
        for (uint8 i = 0; i < _inputs.length; i++) {
            rows[i] = _getBits(_inputs[i]);
        }
        return rows;
    }

    function _getAttributes(string[24] memory _parts) internal pure returns (string memory output) {
        for (uint256 i = 0; i < _parts.length; i++) {
            string memory input = _parts[i];

            if (bytes(input).length == 0) {
                continue;
            }

            output = string(abi.encodePacked(output, bytes(output).length > 0 ? "," : "", input));
        }
        return output;
    }

    function _getDigits(uint256 _value) internal pure returns (uint256[] memory) {
        if (_value == 0) {
            uint256[] memory zero = new uint256[](1);
            return zero;
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        uint256[] memory result = new uint256[](digits);
        temp = _value;
        while (temp != 0) {
            digits -= 1;
            result[digits] = uint256(temp % 10);
            temp /= 10;
        }
        return result;
    }

    function _toString(uint256 _value) internal pure returns (string memory) {
        uint256[] memory digits = _getDigits(uint256(_value));
        bytes memory buffer = new bytes(digits.length);
        for (uint256 i = 0; i < digits.length; i++) {
            buffer[i] = bytes1(uint8(48 + digits[i]));
        }
        return string(buffer);
    }

    function _toDecimalString(uint256 _value, uint256 _decimals)
        internal
        pure
        returns (string memory)
    {
        if (_decimals == 0 || _value == 0) {
            return _toString(_value);
        }

        uint256[] memory digits = _getDigits(_value);
        uint256 len = digits.length;
        bool undersized = len <= _decimals;

        // Index of the decimal point
        uint256 ptIdx = undersized ? 1 : len - _decimals;

        // Leading zeroes
        uint256 leading = undersized ? 1 + (_decimals - len) : 0;

        // Create buffer for total length
        uint256 bufferLen = len + 1 + leading;
        bytes memory buffer = new bytes(bufferLen);
        uint256 offset = 0;

        // Fill buffer
        for (uint256 i = 0; i < bufferLen; i++) {
            if (i == ptIdx) {
                // Add decimal point
                buffer[i] = bytes1(uint8(46));
                offset++;
            } else if (leading > 0 && i <= leading) {
                // Add leading zero
                buffer[i] = bytes1(uint8(48));
                offset++;
            } else {
                // Add digit with index offset for added bytes
                buffer[i] = bytes1(uint8(48 + digits[i - offset]));
            }
        }

        return string(buffer);
    }

    function _attributeNames(uint256 _i) internal pure returns (string memory) {
        string[23] memory attributeNames = [
            "Taxicab",
            "Perfect",
            "Euler's Lucky Number",
            "Unique Prime",
            "Friendly",
            "Colossally Abundant",
            "Fibonacci",
            "Repdigit",
            "Weird",
            "Triangular",
            "Sophie Germain Prime",
            "Strong Prime",
            "Frugal",
            "Square",
            "Emirp",
            "Magic",
            "Lucky",
            "Good Prime",
            "Happy",
            "Untouchable",
            "Semiperfect",
            "Harshad",
            "Evil"
        ];
        return attributeNames[_i];
    }
}

// SPDX-License-Identifier: GPL-3.0
/// @title MathBlocks, Primes
/********************************************
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM *
 * MMMMMMMMMMMMNmdddddddddddddddddmNMMMMMMM *
 * MMMMMMMMMmhyssooooooooooooooooosyhNMMMMM *
 * MMMMMMMmyso+/::::::::::::::::::/osyMMMMM *
 * MMMMMMhys+::/+++++++++++++++++/:+syNMMMM *
 * MMMMNyso/:/+/::::+/:::/+:::::::+oshMMMMM *
 * MMMMmys/-//:/++:/+://-++-+oooossydMMMMMM *
 * MMMMNyso+//+s+/:+/:+/:+/:+syddmNMMMMMMMM *
 * MMMMMNdyyyyso/:++:/+:/+/:+syNMMMMMMMMMMM *
 * MMMMMMMMMhso/:/+/:++:/++-+symMMMMMMMMMMM *
 * MMMMMMMMdys+:/++:/++:/++:/+syNMMMMMMMMMM *
 * MMMMMMMNys+:/++/:+s+:/+++:/oydMMMMMMMMMM *
 * MMMMMMMmys+:/+/:/oso/:///:/sydMMMMMMMMMM *
 * MMMMMMMMhso+///+osyso+///osyhMMMMMMMMMMM *
 * MMMMMMMMMmhyssyyhmMdhyssyydNMMMMMMMMMMMM *
 * MMMMMMMMMMMMMNMMMMMMMMMNMMMMMMMMMMMMMMMM *
 *******************************************/
contract Primes is ERC721Tradable, ReentrancyGuard, TokenAttributes {
    using Packed16BitArray for Packed16BitArray.PackedArray;

    // Periods
    uint256 internal constant RESCUE_SALE_GRACE_PERIOD = 48 hours;
    uint256 internal constant WHITELIST_ONLY_PERIOD = 24 hours;
    uint256 internal constant BATCH_0_GRACE_PERIOD = 2 hours;
    uint256 internal constant BATCH_1_GRACE_PERIOD = 2 hours;
    uint256 internal constant BATCH_2_GRACE_PERIOD = 12 hours;

    // Prices: 0.05 ETH for FLC, 0.075 for EGS
    uint256 internal constant BATCH_0_PRICE = 5e16;
    uint256 internal constant BATCH_1_PRICE = 75e15;

    Packed16BitArray.PackedArray internal packedPrimes;

    Packed16BitArray.PackedArray internal batch0;
    Packed16BitArray.PackedArray internal batch1;
    Packed16BitArray.PackedArray internal batch2;

    bytes32 public whitelistRootHash;

    mapping(uint256 => CoreData) public data;
    mapping(uint256 => RentalData) public rental;
    mapping(address => Activity) public users;

    address public auctionHouse;

    uint256 public batchStartTime;
    uint256 public nonce;
    address public immutable setupAddr;
    uint256 public immutable BREEDING_COOLDOWN;

    event Initialized();
    event PrimeClaimed(uint256 tokenId);
    event BatchStarted(uint256 batchId);
    event Bred(uint16 tokenId, uint256 parent1, uint256 parent2);
    event Listed(uint16 tokenId);
    event UnListed(uint16 tokenId);

    constructor(
        address _dao,
        uint256 _breedCooldown,
        address _proxyRegistryAddress,
        bytes32 _attributesRootHash,
        bytes32 _whitelistRootHash
    )
        ERC721Tradable("Primes", "PRIME", _proxyRegistryAddress)
        TokenAttributes(_attributesRootHash)
    {
        setupAddr = msg.sender;
        transferOwnership(_dao);
        BREEDING_COOLDOWN = _breedCooldown;
        whitelistRootHash = _whitelistRootHash;
    }

    /***************************************
                    VIEWS
    ****************************************/

    function fetchPrime(uint256 _index) public view returns (uint16 primeNumber) {
        return packedPrimes.getValue(_index);
    }

    function getNumberData(uint256 _tokenId) public view returns (NumberData memory) {
        require(_tokenId <= 2**14, "Number too large");
        CoreData memory core = data[_tokenId];
        return
            NumberData({
                core: core,
                prime: PrimeData({
                    sexyPrimes: sexyPrimes(core.primeIndex),
                    twins: twins(core.primeIndex),
                    cousins: cousins(core.primeIndex)
                })
            });
    }

    function getSuitors(uint256 _tokenId) public view returns (uint16[6] memory) {
        return rental[_tokenId].suitors;
    }

    function getParents(uint256 _tokenId) public view returns (uint16[2] memory) {
        return data[_tokenId].parents;
    }

    /***************************************
                    BREEDING
    ****************************************/

    function breedPrimes(
        uint16 _parent1,
        uint16 _parent2,
        uint256 _attributes,
        bytes32[] memory _merkleProof
    ) external nonReentrant {
        BreedInput memory input1 = _getInput(_parent1);
        BreedInput memory input2 = _getInput(_parent2);
        require(input1.owns && input2.owns, "Breeder must own input token");
        _breed(input1, input2, _attributes, _merkleProof);
    }

    function crossBreed(
        uint16 _parent1,
        uint16 _parent2,
        uint256 _attributes,
        bytes32[] memory _merkleProof
    ) external payable nonReentrant {
        BreedInput memory input1 = _getInput(_parent1);
        BreedInput memory input2 = _getInput(_parent2);
        require(input1.owns, "Must own first input");
        require(input2.rentalData.isRentable, "Must be rentable");
        require(msg.value >= input2.rentalData.studFee, "Must pay stud fee");
        payable(input2.owner).transfer((msg.value * 9) / 10);
        require(block.timestamp < input2.rentalData.deadline, "Rental passed deadline");
        if (input2.rentalData.whitelistOnly) {
            bool isSuitor;
            for (uint256 i = 0; i < 6; i++) {
                isSuitor = isSuitor || input2.rentalData.suitors[i] == _parent1;
            }
            require(isSuitor, "Must be whitelisted suitor");
        }
        _breed(input1, input2, _attributes, _merkleProof);
    }

    function _breed(
        BreedInput memory _input1,
        BreedInput memory _input2,
        uint256 _attributes,
        bytes32[] memory _merkleProof
    ) internal {
        // VALIDATION
        // 1. Check less than max uint16
        uint256 childVal = uint256(_input1.id) * uint256(_input2.id);
        require(childVal <= 2**14, "Number too large");
        uint16 scaledVal = uint16(childVal);

        // 2. Number doesn't exist
        require(!_exists(scaledVal), "Number already taken");

        // 3. Tokens passed cooldown
        require(
            block.timestamp > _input1.tokenData.lastBred + BREEDING_COOLDOWN &&
                block.timestamp > _input2.tokenData.lastBred + BREEDING_COOLDOWN,
            "Cannot breed so quickly"
        );

        // 4. Composites can't self-breed
        require(
            !(_input1.id == _input2.id && !_input1.tokenData.isPrime),
            "Composites cannot self-breed"
        );

        // Breed
        data[_input1.id].lastBred = uint32(block.timestamp);
        data[_input2.id].lastBred = uint32(block.timestamp);
        data[scaledVal] = CoreData({
            isPrime: false,
            primeIndex: 0,
            primeFactorCount: _input1.tokenData.primeFactorCount +
                _input2.tokenData.primeFactorCount,
            parents: [_input1.id, _input2.id],
            lastBred: uint32(block.timestamp)
        });
        _safeMint(msg.sender, scaledVal);
        if (_attributes > 0) {
            revealAttributes(scaledVal, _attributes, _merkleProof);
        }
        _burnAfterBreeding(_input1, _input2);

        emit Bred(scaledVal, _input1.id, _input2.id);
    }

    function _burnAfterBreeding(BreedInput memory _input1, BreedInput memory _input2) internal {
        // Both primes, no burn
        if (_input1.tokenData.isPrime && _input2.tokenData.isPrime) return;
        // One prime,
        if (_input1.tokenData.isPrime) {
            require(_input2.owns, "Breeder must own burning");
            _burn(_input2.id);
        } else if (_input2.tokenData.isPrime) {
            require(_input1.owns, "Breeder must own burning");
            _burn(_input1.id);
        }
        // No primes, both burn
        else {
            require(_input1.owns && _input2.owns, "Breeder must own burning");
            _burn(_input1.id);
            _burn(_input2.id);
        }
    }

    function list(
        uint16 _tokenId,
        uint96 _fee,
        uint32 _deadline,
        uint16[] memory _suitors
    ) external {
        require(msg.sender == ownerOf(_tokenId), "Must own said token");

        uint16[6] memory suitors;
        uint256 len = _suitors.length;
        if (len > 0) {
            require(len < 6, "Max 6 suitors");
            for (uint256 i = 0; i < len; i++) {
                suitors[i] = _suitors[i];
            }
        }

        rental[_tokenId] = RentalData({
            isRentable: true,
            whitelistOnly: len > 0,
            studFee: _fee,
            deadline: _deadline,
            suitors: suitors
        });

        emit Listed(_tokenId);
    }

    function unlist(uint16 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "Must own said token");

        uint16[6] memory empty6;
        rental[_tokenId] = RentalData(false, false, 0, 0, empty6);

        emit UnListed(_tokenId);
    }

    struct BreedInput {
        bool owns;
        address owner;
        uint16 id;
        CoreData tokenData;
        RentalData rentalData;
    }

    function _getInput(uint16 _breedInput) internal view returns (BreedInput memory) {
        address owner = ownerOf(_breedInput);
        return
            BreedInput({
                owns: owner == msg.sender,
                owner: owner,
                id: _breedInput,
                tokenData: data[_breedInput],
                rentalData: rental[_breedInput]
            });
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        uint16[6] memory empty6;
        rental[tokenId] = RentalData(false, false, 0, 0, empty6);
    }

    /***************************************
                    TOKEN URI
    ****************************************/

    function tokenURI(uint256 _tokenId) public view override returns (string memory output) {
        NumberData memory numberData = getNumberData(_tokenId);
        bool[23] memory attributeValues = getAttributes(_tokenId);
        uint16[] memory factors = getPrimeFactors(uint16(_tokenId), numberData);
        return PrimesTokenURI.tokenURI(_tokenId, numberData, factors, attributeValues);
    }

    function getPrimeFactors(uint16 _tokenId, NumberData memory _numberData)
        public
        view
        returns (uint16[] memory factors)
    {
        factors = _getFactors(_tokenId, _numberData.core);
        factors = _insertion(factors);
    }

    function _getFactors(uint16 _tokenId, CoreData memory _core)
        internal
        view
        returns (uint16[] memory factors)
    {
        if (_core.isPrime) {
            factors = new uint16[](1);
            factors[0] = _tokenId;
        } else {
            uint16[] memory parent1Factors = _getFactors(_core.parents[0], data[_core.parents[0]]);
            uint256 len1 = parent1Factors.length;
            uint16[] memory parent2Factors = _getFactors(_core.parents[1], data[_core.parents[1]]);
            uint256 len2 = parent2Factors.length;
            factors = new uint16[](len1 + len2);
            for (uint256 i = 0; i < len1; i++) {
                factors[i] = parent1Factors[i];
            }
            for (uint256 i = 0; i < len2; i++) {
                factors[len1 + i] = parent2Factors[i];
            }
        }
    }

    function _insertion(uint16[] memory _arr) internal pure returns (uint16[] memory) {
        uint256 length = _arr.length;
        for (uint256 i = 1; i < length; i++) {
            uint16 key = _arr[i];
            uint256 j = i - 1;
            while ((int256(j) >= 0) && (_arr[j] > key)) {
                _arr[j + 1] = _arr[j];
                unchecked {
                    j--;
                }
            }
            unchecked {
                _arr[j + 1] = key;
            }
        }
        return _arr;
    }

    function sexyPrimes(uint256 _primeIndex) public view returns (uint16[2] memory matches) {
        if (_primeIndex > 0) {
            matches = packedPrimes.biDirectionalSearch(_primeIndex, 6);
            if (_primeIndex == 4) {
                // 7: 1 is not prime but is in packedPrimes; exclude it here
                matches[0] = 0;
            }
        }
    }

    function twins(uint256 _primeIndex) public view returns (uint16[2] memory matches) {
        if (_primeIndex > 0) {
            matches = packedPrimes.biDirectionalSearch(_primeIndex, 2);
            if (_primeIndex == 2) {
                // 3: 1 is not prime but is in packedPrimes; exclude it here
                matches[0] = 0;
            }
        }
    }

    function cousins(uint256 _primeIndex) public view returns (uint16[2] memory matches) {
        if (_primeIndex > 0) {
            matches = packedPrimes.biDirectionalSearch(_primeIndex, 4);
            if (_primeIndex == 3) {
                // 5: 1 is not prime but is in packedPrimes; exclude it here
                matches[0] = 0;
            }
        }
    }

    /***************************************
                    MINTING
    ****************************************/

    function mintRandomPrime(
        uint256 _batch0Cap,
        uint256 _batch1Cap,
        bytes32[] memory _merkleProof
    ) external payable {
        mintRandomPrimes(1, _batch0Cap, _batch1Cap, _merkleProof);
    }

    function mintRandomPrimes(
        uint256 _count,
        uint256 _batch0Cap,
        uint256 _batch1Cap,
        bytes32[] memory _merkleProof
    ) public payable nonReentrant {
        (bool active, uint256 batchId, uint256 remaining, ) = batchCheck();
        require(active && batchId < 2, "Batch not active");
        require(remaining >= _count, "Not enough Primes available");
        require(_count <= 20, "Cannot mint >20 Primes at once");

        uint256 unitPrice = batchId == 0 ? BATCH_0_PRICE : BATCH_1_PRICE;
        require(msg.value >= _count * unitPrice, "Requires value");

        _validateUser(batchId, _count, _batch0Cap, _batch1Cap, _merkleProof);
        for (uint256 i = 0; i < _count; i++) {
            _getPrime(batchId);
        }
    }

    function getNextPrime() external nonReentrant returns (uint256 tokenId) {
        require(msg.sender == auctionHouse, "Must be the auctioneer");

        (bool active, uint256 batchId, uint256 remaining, ) = batchCheck();
        require(active && batchId == 2, "Batch not active");
        require(remaining > 0, "No more Primes");

        uint256 idx = batch2.length - 1;
        uint16 primeIndex = batch2.getValue(idx);
        batch2.extractIndex(idx);

        tokenId = _mintLocal(msg.sender, primeIndex);
    }

    // After each batch has begun, the DAO can mint to ensure no bottleneck
    function rescueSale() external onlyOwner nonReentrant {
        (bool active, uint256 batchId, uint256 remaining, ) = batchCheck();
        require(active, "Batch not active");
        require(
            block.timestamp > batchStartTime + RESCUE_SALE_GRACE_PERIOD,
            "Must wait for sale to elapse"
        );
        uint256 rescueCount = remaining < 20 ? remaining : 20;
        for (uint256 i = 0; i < rescueCount; i++) {
            _getPrime(batchId);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    function batchCheck()
        public
        view
        returns (
            bool active,
            uint256 batch,
            uint256 remaining,
            uint256 startTime
        )
    {
        uint256 ts = batchStartTime;
        if (ts == 0) {
            return (false, 0, 0, 0);
        }
        if (batch0.length > 0) {
            startTime = batchStartTime + BATCH_0_GRACE_PERIOD;
            return (block.timestamp > startTime, 0, batch0.length, startTime);
        }
        if (batch1.length > 0) {
            startTime = batchStartTime + BATCH_1_GRACE_PERIOD;
            return (block.timestamp > startTime, 1, batch1.length, startTime);
        }
        startTime = batchStartTime + BATCH_2_GRACE_PERIOD;
        return (block.timestamp > startTime, 2, batch2.length, startTime);
    }

    /***************************************
                MINTING - INTERNAL
    ****************************************/

    function _getPrime(uint256 _batchId) internal {
        uint256 seed = _rand();
        uint16 primeIndex;
        if (_batchId == 0) {
            uint256 idx = seed % batch0.length;
            primeIndex = batch0.getValue(idx);
            batch0.extractIndex(idx);
            _triggerTimestamp(_batchId, batch0.length);
        } else if (_batchId == 1) {
            uint256 idx = seed % batch1.length;
            primeIndex = batch1.getValue(idx);
            batch1.extractIndex(idx);
            _triggerTimestamp(_batchId, batch1.length);
        } else {
            revert("Invalid batchId");
        }

        _mintLocal(msg.sender, primeIndex);
    }

    function _mintLocal(address _beneficiary, uint16 _primeIndex)
        internal
        returns (uint256 tokenId)
    {
        uint16[2] memory empty;
        tokenId = fetchPrime(_primeIndex);
        data[tokenId] = CoreData({
            isPrime: true,
            primeIndex: _primeIndex,
            primeFactorCount: 1,
            parents: empty,
            lastBred: uint32(block.timestamp)
        });
        _safeMint(_beneficiary, tokenId);
        emit PrimeClaimed(tokenId);
    }

    function _validateUser(
        uint256 _batchId,
        uint256 _count,
        uint256 _batch0Cap,
        uint256 _batch1Cap,
        bytes32[] memory _merkleProof
    ) internal {
        if (block.timestamp < batchStartTime + WHITELIST_ONLY_PERIOD) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _batch0Cap, _batch1Cap));
            require(
                MerkleProof.verify(_merkleProof, whitelistRootHash, leaf),
                "Invalid merkle proof"
            );

            uint8 countAfter = (
                _batchId == 0 ? users[msg.sender].tranche0 : users[msg.sender].tranche1
            ) + uint8(_count);

            if (_batchId == 0) {
                require(countAfter <= _batch0Cap, "Exceeding cap");
                users[msg.sender].tranche0 = countAfter;
            } else {
                require(countAfter <= _batch1Cap, "Exceeding cap");
                users[msg.sender].tranche1 = countAfter;
            }
        }
    }

    function _triggerTimestamp(uint256 _batchId, uint256 _len) internal {
        if (_len == 0) {
            batchStartTime = block.timestamp;
            emit BatchStarted(_batchId + 1);
        }
    }

    function _rand() internal virtual returns (uint256 seed) {
        nonce++;
        seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
                            (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                        block.number,
                    nonce
                )
            )
        );
    }

    /***************************************
                INITIALIZING
    ****************************************/

    modifier onlyInitializer() {
        require(msg.sender == setupAddr, "Only initializer");
        _;
    }

    function initPrimes(uint256[] calldata _data, uint256 _length) external onlyInitializer {
        require(packedPrimes.length == 0, "Already initialized");
        packedPrimes = Packed16BitArray.initStruct(_data, _length);
    }

    function initBatch0(uint256[] calldata _data, uint256 _length) external onlyInitializer {
        require(batch0.length == 0, "Already initialized");
        batch0 = Packed16BitArray.initStruct(_data, _length);
    }

    function initBatch1(uint256[] calldata _data, uint256 _length) external onlyInitializer {
        require(batch1.length == 0, "Already initialized");
        batch1 = Packed16BitArray.initStruct(_data, _length);
    }

    function initBatch2(uint256[] calldata _data, uint256 _length) external onlyInitializer {
        require(batch2.length == 0, "Already initialized");
        batch2 = Packed16BitArray.initStruct(_data, _length);
    }

    function start(address _auctionHouse) external onlyInitializer {
        require(
            packedPrimes.length > 0 && batch0.length > 0 && batch1.length > 0 && batch2.length > 0,
            "Not initialized"
        );
        batchStartTime = block.timestamp;
        auctionHouse = _auctionHouse;

        _mintLocal(owner(), 0);

        emit Initialized();
    }
}