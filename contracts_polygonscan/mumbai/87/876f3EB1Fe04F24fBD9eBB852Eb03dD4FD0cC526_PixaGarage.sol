/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
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

        return super.tokenURI(tokenId);
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
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract Pixag is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    constructor(address marketplaceAddress) ERC721("Pixa Garage", "PIXAG") {
        contractAddress = marketplaceAddress;
    }

    function createToken(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true);
        return newItemId;
    }

    function deleteToken(uint256 id) public {
        _burn(id);
    }

    function transferToken(address from, address to, uint256 tokenId) external {
        require(ownerOf(tokenId) == from, "From address must be token owner");
        _transfer(from, to, tokenId);
    }
}

contract PixaGarage is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

  Counters.Counter private _colorsMinted;

  address payable owner;

  uint256 colorPrice = 0.002 ether;

  uint256 private _colorsSupply = 4096;

  uint256 private maxColorsPerAccount = 16;

  uint256 private _totalListings;

  event ProductListed(
      uint256 indexed itemId
  );

  event MarketItemDeleted(uint256 itemId);

  constructor() {
    owner = payable(msg.sender);
  }

  modifier onlyItemOwner(uint256 id) {
        require(
            idToMarketItem[id].owner == msg.sender,
            "Only product owner can do this operation"
        );
        _;
    }



  struct MarketItem {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    address payable creator;
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
    string dominantColor;
    bool assetColor;
    string name;
    uint256 timestamp;
  }

  mapping(uint256 => MarketItem) private idToMarketItem;

  mapping(address => uint256) private addressToColorsNum;

  mapping(string => uint256) private colors;

  mapping(address => string) private ownerName;

  event MarketItemCreated (
    uint256 indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address creator,
    address seller,
    address owner,
    uint256 price,
    bool sold,
    string dominantColor,
    bool assetColor,
    string name,
    uint256 timestamp
  );

  event ProductSold(
    uint256 indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address creator,
    address seller,
    address owner,
    uint256 price
  );

  function getColorPrice() public view returns (uint256) {
    return colorPrice;
  }

  function getTotalListings() public view returns (uint256) {
    return _totalListings;
  }

  function getColorsSupply() public view returns (uint256) {
    return _colorsSupply;
  }

  function fetchSingleItem(uint256 id)
        public
        view
        returns (MarketItem memory)
  {
      return idToMarketItem[id];
  }

  function fetchMyColors(uint256 page, uint256 limit)
        public
        view
        returns (MarketItem[] memory)
  {
      uint256 totalItemsCount = _itemIds.current();
      uint256 itemCount = 0;
      uint256 currentIndex = 0;

      for (uint256 i = 0; i < totalItemsCount; i++) {
        if (idToMarketItem[i + 1].assetColor && idToMarketItem[i + 1].owner == msg.sender) {
          itemCount += 1;
          if (itemCount == limit) {
            break;
          }
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint256 i = page; i < totalItemsCount; i++) {
        if (idToMarketItem[i + 1].assetColor && idToMarketItem[i + 1].owner == msg.sender) {
          uint256 currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
          if (currentIndex == limit) {
            break;
          }
        }
      }
      return items;
  }
  
  function loadColors(uint256 page, uint256 limit)
        public
        view
        returns (MarketItem[] memory)
  {
      uint256 totalItemsCount = _itemIds.current();
      uint256 itemCount = 0;
      uint256 currentIndex = 0;

      for (uint256 i = page; i < totalItemsCount; i++) {
        if (idToMarketItem[i + 1].assetColor) {
          itemCount += 1;
          if (itemCount == limit) {
            break;
          }
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint256 i = page; i < totalItemsCount; i++) {
        if (idToMarketItem[i + 1].assetColor) {
          uint256 currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
          if (currentIndex == limit) {
            break;
          }
        }
      }
      return items;
  }

  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price,
    string memory dominantColor,
    string memory name,
    bool assetColor,
    bool onlyCreate
  ) public payable nonReentrant {
    require(price > 0, "Price must be at least 1 wei");
    if (assetColor) require(msg.value == colorPrice, "Price must be equal to color price");
    if (assetColor==true) {
      if (addressToColorsNum[msg.sender] == maxColorsPerAccount) {
        deleteToken(nftContract, tokenId);
        revert("Maximum number of colors minted by this account");
      }
      if (colors[dominantColor] != 0) {
        deleteToken(nftContract, tokenId);
        revert("Color exists");
      }
      if (_colorsMinted.current() == getColorsSupply()) {
        revert("All Colors Minted!");
      }
      addressToColorsNum[msg.sender]++;
      _colorsMinted.increment();
      colors[dominantColor] = tokenId;
    }
    
    _itemIds.increment();
    bool isColor = assetColor || onlyCreate;
    address whoOwnsIt = msg.sender;
    if (!assetColor && !onlyCreate) whoOwnsIt = address(0);
    uint256 itemId = _itemIds.current();
    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(msg.sender),
      payable(whoOwnsIt),
      price,
      isColor,
      dominantColor,
      assetColor,
      name,
      block.timestamp
    );
    if (!assetColor && !onlyCreate) IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    if (assetColor) {
      _totalListings += colorPrice;
      payable(owner).transfer(colorPrice);
    }
    
    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      msg.sender,
      whoOwnsIt,
      idToMarketItem[itemId].price,
      isColor,
      idToMarketItem[itemId].dominantColor,
      idToMarketItem[itemId].assetColor,
      idToMarketItem[itemId].name,
      block.timestamp
    );
  }

  function setNameForAddress(
    string memory name    
  ) public payable nonReentrant {
    ownerName[msg.sender] = name;
  }

  function createMarketSale(
    address nftContract,
    uint256 itemId
    ) public payable nonReentrant {
    uint256 price = idToMarketItem[itemId].price;
    uint256 tokenId = idToMarketItem[itemId].tokenId;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");
    uint256 forDominant = calculatePercentage(price);
    uint256 forSeller = price - forDominant; 
    string memory dominantColor = idToMarketItem[itemId].dominantColor;
    uint256 winnerId = 0;
    uint itemCount = _itemIds.current();
    if (!idToMarketItem[itemId].assetColor) {
      for (uint256 i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].tokenId != tokenId && idToMarketItem[i + 1].assetColor && keccak256(bytes(idToMarketItem[i + 1].dominantColor)) == keccak256(bytes(dominantColor))) {
            winnerId = i + 1;
        }
      }
      if (winnerId == 0) {
        forSeller = price;
        idToMarketItem[itemId].seller.transfer(forSeller);
      }
      else {
        uint amountPerWinner = forDominant;
        idToMarketItem[winnerId].seller.transfer(amountPerWinner);
        idToMarketItem[itemId].seller.transfer(forSeller);
      }
    }
    else {
      idToMarketItem[itemId].seller.transfer(price);
    }
    
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;
    idToMarketItem[itemId].timestamp = block.timestamp;
    _itemsSold.increment();
    
    MarketItem memory productSold = idToMarketItem[itemId];
    emit ProductSold(
        productSold.itemId,
        productSold.nftContract,
        productSold.tokenId,
        productSold.creator,
        productSold.seller,
        payable(msg.sender),
        productSold.price
    );
  }

        
  function fetchSoldItemsByColor(uint page, uint limit, string memory color) public view returns (MarketItem[] memory) {
    uint256 totalItemsCount = _itemIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;
    if (page > totalItemsCount) page = totalItemsCount;
    MarketItem memory colorItem;

    for (uint256 i = 0;i<totalItemsCount;i++) {
      if (idToMarketItem[i].assetColor && keccak256(bytes(idToMarketItem[i].dominantColor)) == keccak256(bytes(color))) {
        colorItem = idToMarketItem[i];
        break;
      }
    }
    if (colorItem.itemId == 0) {
      MarketItem[] memory emptyItems = new MarketItem[](0);
      return emptyItems;
    }
    for (uint256 i = totalItemsCount - page; i > 0; i--) {
      if (!idToMarketItem[i].assetColor && idToMarketItem[i].timestamp > colorItem.timestamp && keccak256(bytes(idToMarketItem[i].dominantColor)) == keccak256(bytes(color))) {
        itemCount += 1;
        if (itemCount == limit) {
          break;
        }
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = totalItemsCount - page; i > 0; i--) {
      if (!idToMarketItem[i].assetColor && idToMarketItem[i].timestamp > colorItem.timestamp && keccak256(bytes(idToMarketItem[i].dominantColor)) == keccak256(bytes(color))) {
        uint256 currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
        if (currentIndex == limit) {
          break;
        }
      }
    }
    return items;
  }

  function fetchMarketItems(uint page, uint limit) public view returns (MarketItem[] memory) {
    uint256 totalItemsCount = _itemIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;
    if (page > totalItemsCount) page = totalItemsCount;

    for (uint256 i = totalItemsCount - page; i > 0; i--) {
      if (idToMarketItem[i].sold == false) {
        itemCount += 1;
        if (itemCount == limit) {
          break;
        }
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = totalItemsCount - page; i > 0; i--) {
      if (idToMarketItem[i].sold == false) {
        uint256 currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
        if (currentIndex == limit) {
          break;
        }
      }
    }
    return items;
  }

  function fetchMarketItemsByName(string memory name) public view returns (MarketItem[] memory) {
    uint256 totalItemsCount = _itemIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = totalItemsCount; i > 0; i--) {
      if (idToMarketItem[i].sold == false && contains(name, idToMarketItem[i].name)) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = totalItemsCount; i > 0; i--) {
      if (idToMarketItem[i].sold == false && contains(name, idToMarketItem[i].name)) {
        uint256 currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
  
  function calculatePercentage(uint amount) public pure returns (uint) {
    return amount * 1000 / 10000;
  }
  function fetchMyNFTs(uint page, uint limit) public view returns (MarketItem[] memory) {
    uint256 totalItemCount = _itemIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;
    if (page > totalItemCount) page = totalItemCount;

    for (uint256 i = totalItemCount - page; i > 0; i--) {
      if (idToMarketItem[i].owner == msg.sender) {
        itemCount += 1;
        if (itemCount == limit) {
          break;
        }
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = totalItemCount - page; i > 0; i--) {
      if (idToMarketItem[i].owner == msg.sender) {
        uint256 currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
        if (currentIndex == limit) {
          break;
        }
      }
    }
    return items;
  }

  function fetchWhatISold(uint page, uint limit) public view returns (MarketItem[] memory) {
    uint256 totalItemCount = _itemIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;
    if (page > totalItemCount) page = totalItemCount;

    for (uint256 i = totalItemCount - page; i > 0; i--) {
      if (idToMarketItem[i].owner != msg.sender && idToMarketItem[i].creator == msg.sender && idToMarketItem[i].sold && !idToMarketItem[i].assetColor) {
        itemCount += 1;
        if (itemCount == limit) {
          break;
        }
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = totalItemCount - page; i > 0; i--) {
      if (idToMarketItem[i].owner != msg.sender && idToMarketItem[i].creator == msg.sender && idToMarketItem[i].sold && !idToMarketItem[i].assetColor) {
        uint256 currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
        if (currentIndex == limit) {
          break;
        }
      }
    }
    return items;
  }

  function fetchItemsForSell(uint page, uint limit) public view returns (MarketItem[] memory) {
    uint256 totalItemCount = _itemIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;
    if (page > totalItemCount) page = totalItemCount;

    for (uint256 i =totalItemCount - page; i > 0; i--) {
      if (idToMarketItem[i].seller == msg.sender && !idToMarketItem[i].sold && !idToMarketItem[i].assetColor) {
        itemCount += 1;
        if (itemCount == limit) {
          break;
        }
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = totalItemCount - page; i > 0; i--) {
      if (idToMarketItem[i].seller == msg.sender && !idToMarketItem[i].sold && !idToMarketItem[i].assetColor) {
        uint256 currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
        if (currentIndex == limit) {
          break;
        }
      }
    }
    return items;
  }
  
  function putItemToResell(address nftContract, uint256 itemId, uint256 newPrice)
        public
        payable
        nonReentrant
        onlyItemOwner(itemId)
    {
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(msg.sender == idToMarketItem[itemId].owner && msg.sender == idToMarketItem[itemId].creator, "Not allowed");
        require(newPrice > 0, "Price must be at least 1 wei");
        //instantiate a NFT contract object with the matching type
        Pixag tokenContract = Pixag(nftContract);
        //call the custom transfer token method   
        tokenContract.transferToken(msg.sender, address(this), tokenId);

        address payable oldOwner = idToMarketItem[itemId].owner;
        idToMarketItem[itemId].owner = payable(address(0));
        idToMarketItem[itemId].seller = oldOwner;
        idToMarketItem[itemId].price = newPrice;
        idToMarketItem[itemId].sold = false;
        // if (!idToMarketItem[itemId].assetColor) _itemsSold.decrement();

        emit ProductListed(itemId);
    }

  function deleteToken(address nftContract, uint256 tokenId)
        private
    {
        Pixag tokenContract = Pixag(nftContract);
        tokenContract.deleteToken(tokenId);
    }

  function contains(string memory what, string memory where) public pure returns (bool) {
    bytes memory whatBytes = bytes (what);
    bytes memory whereBytes = bytes (where);

    if (whereBytes.length < whatBytes.length) return false;

    bool found = false;
    for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
        bool flag = true;
        for (uint j = 0; j < whatBytes.length; j++)
            if (whereBytes [i + j] != whatBytes [j]) {
                flag = false;
                break;
            }
        if (flag) {
            found = true;
            break;
        }
    }
    return (found);
}

}