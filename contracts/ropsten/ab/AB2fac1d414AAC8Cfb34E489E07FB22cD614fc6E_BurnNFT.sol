// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import 'base64-sol/base64.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract BurnNFT is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event NewToken(address _minter, uint256 _tokenId, uint256 _baseFee);

    uint public limit;
    uint256 public price;
    address public beneficiary;
    uint256 public minBaseFee = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public maxBaseFee = 1;

    mapping(uint256 => uint256) public tokenBaseFee;

    constructor(uint _limit, uint256 _price, address _beneficiary) ERC721("BurnyBanner", "BURN") {
      limit = _limit;
      price = _price;
      beneficiary = _beneficiary;
    }

    function mint() public payable returns (uint256) {

        require(msg.value >= price, "insufficient value");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(newItemId <= limit, "limit reached");

        _mint(msg.sender, newItemId);

        uint256 baseFee = block.basefee;
        tokenBaseFee[newItemId] = baseFee;

        if(baseFee > maxBaseFee) {
          maxBaseFee = baseFee;
        }
        if(baseFee < minBaseFee) {
          minBaseFee = baseFee;
        }

        emit NewToken(msg.sender, newItemId, baseFee);

        return newItemId;
    }

    function withdrawFunds() public {
      require(msg.sender == beneficiary, 'only beneficiary can withdraw');
      // get the amount of Ether stored in this contract
      uint amount = address(this).balance;

      // send all Ether to owner
      // Owner can receive Ether since the address of owner is payable
      (bool success,) = beneficiary.call{value: amount}("");
      require(success, "Failed to send Ether");
    }

    function totalSupply() public view returns (uint256) {
      return _tokenIds.current();
    }

    function generateSVGofTokenById(uint256 _tokenId) public virtual view returns (string memory) {

        uint height = 250;
        uint fireHeight;

        if(minBaseFee == maxBaseFee) {
          fireHeight = 0;
        } else {
          fireHeight = height*(uint(100)-(uint(100)*(tokenBaseFee[_tokenId]-minBaseFee)/(maxBaseFee-minBaseFee))) / uint(100);
        }

        string memory svg = string(abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 200 323.6"><defs><style><![CDATA[#Fire_to_move {transform: translate(0px,',
          Strings.toString(fireHeight),
          'px)}]]></style><linearGradient id="linear-gradient" x1="100" x2="100" y2="323.6" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#524984"/><stop offset="1" stop-color="#1b1a38"/></linearGradient><linearGradient id="linear-gradient-2" x1="100" y1="323.6" x2="100" y2="151.933" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#ffbd58"/><stop offset="1" stop-color="#f6ec47"/></linearGradient><clipPath id="clip-path"><rect y="0.419" width="200" height="151.587" fill="none"/></clipPath><linearGradient id="linear-gradient-3" x1="27.34" y1="22.637" x2="27.34" y2="153.025" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#f16e5c"/><stop offset="1" stop-color="#ffbd58"/></linearGradient><linearGradient id="linear-gradient-4" x1="30.946" y1="55.833" x2="30.946" y2="156.043" xlink:href="#linear-gradient-2"/><linearGradient id="linear-gradient-5" x1="101.387" y1="22.637" x2="101.387" y2="153.025" xlink:href="#linear-gradient-3"/><linearGradient id="linear-gradient-6" x1="104.992" y1="55.833" x2="104.992" y2="156.043" xlink:href="#linear-gradient-2"/><linearGradient id="linear-gradient-7" x1="175.433" y1="22.637" x2="175.433" y2="153.025" xlink:href="#linear-gradient-3"/><linearGradient id="linear-gradient-8" x1="179.038" y1="55.833" x2="179.038" y2="156.043" xlink:href="#linear-gradient-2"/><linearGradient id="linear-gradient-9" x1="35.977" y1="279.671" x2="164.023" y2="279.671" xlink:href="#linear-gradient"/></defs><g id="Layer_2" data-name="Layer 2"><rect width="200" height="323.6" fill="url(#linear-gradient)"/><g id="Fire_to_move" data-name="Fire to move"><rect y="151.933" width="200" height="171.667" fill="url(#linear-gradient-2)"/><g clip-path="url(#clip-path)"><path d="M-6.277,151.056c-.441-10.632-16.813-27.431-9.259-42.713S4.609,97.109,7.442,82.218c0,0,9.916,8.384,1.1,18.834,0,0,12.748-3.29,12.275-12.7s1.417-13.715-7.082-15.674S-7.509,56.616,4.767,41.725c0,0,2.36,12.54,13.22,7.054s19.83-22.728.944-23.12c0,0,11.8-7.054,18.886.392s-8.971,23.512-3.3,27.43S47.732,58.576,47.26,67.2,32.151,83.655,37.345,87.574,55.87,88.88,56.19,84.644c.314-4.171-7.514-9.218-.9-17.447A16.349,16.349,0,0,0,63.9,77.516c9.443,4.833,11.69,15.543,2.245,23.381-6.452,5.356-14.321-3-15.266,5.094-.547,4.7,20.081,11.343,18.183,25.39C65.574,157.2,77.943,152.73,37.345,152.73-8.194,152.73-6.277,151.056-6.277,151.056Z" fill="url(#linear-gradient-3)"/><path d="M31.38,156.043c-59.517,0-32.292-6.3-25.806-14.088C16.848,128.411-4.676,128.72-4.2,116.964a23.853,23.853,0,0,1,8.5-17.634s-4.957,13.911,2.125,14.3S20.964,109.039,24.6,96.055c6.374-22.784.472-35.128-8.027-40.222a37.474,37.474,0,0,1,17.871,8.475c5.68,5.143-4.452,15.03-4.179,23.266.709,21.361,33.365,4.31,30.375-5.095,0,0,9.128,12.932-2.754,14.891C36.43,100.908,37.345,115.2,45.371,119.9s5.792,14.23,13.04,21.478C67.969,150.94,83.3,156.043,31.38,156.043Z" fill="url(#linear-gradient-4)"/><path d="M67.769,151.056c-.441-10.632-16.813-27.431-9.258-42.713S78.656,97.109,81.488,82.218c0,0,9.916,8.384,1.1,18.834,0,0,12.747-3.29,12.275-12.7s1.416-13.715-7.082-15.674S66.537,56.616,78.813,41.725c0,0,2.361,12.54,13.22,7.054s19.83-22.728.944-23.12c0,0,11.8-7.054,18.886.392s-8.971,23.512-3.3,27.43,13.22,5.095,12.748,13.716S106.2,83.655,111.391,87.574s18.525,1.306,18.845-2.93c.315-4.171-7.514-9.218-.9-17.447a16.349,16.349,0,0,0,8.614,10.319c9.443,4.833,11.69,15.543,2.246,23.381-6.453,5.356-14.322-3-15.266,5.094-.548,4.7,20.081,11.343,18.182,25.39-3.488,25.814,8.881,21.349-31.717,21.349C65.853,152.73,67.769,151.056,67.769,151.056Z" fill="url(#linear-gradient-5)"/><path d="M105.426,156.043c-59.517,0-32.292-6.3-25.806-14.088,11.274-13.544-10.25-13.235-9.778-24.991a23.853,23.853,0,0,1,8.5-17.634s-4.958,13.911,2.124,14.3,14.546-4.594,18.178-17.578c6.374-22.784.472-35.128-8.026-40.222a37.473,37.473,0,0,1,17.87,8.475c5.681,5.143-4.451,15.03-4.178,23.266.708,21.361,33.365,4.31,30.374-5.095,0,0,9.128,12.932-2.754,14.891-21.453,3.538-20.538,17.83-12.512,22.533s5.792,14.23,13.04,21.478C142.016,150.94,157.351,156.043,105.426,156.043Z" fill="url(#linear-gradient-6)"/><path d="M141.816,151.056c-.441-10.632-16.813-27.431-9.259-42.713S152.7,97.109,155.535,82.218c0,0,9.915,8.384,1.1,18.834,0,0,12.747-3.29,12.275-12.7s1.417-13.715-7.082-15.674-21.246-16.067-8.971-30.958c0,0,2.361,12.54,13.22,7.054s19.83-22.728.945-23.12c0,0,11.8-7.054,18.885.392s-8.97,23.512-3.3,27.43,13.22,5.095,12.748,13.716-15.108,16.458-9.915,20.377,18.526,1.306,18.845-2.93c.315-4.171-7.513-9.218-.9-17.447a16.349,16.349,0,0,0,8.614,10.319c9.443,4.833,11.689,15.543,2.245,23.381-6.453,5.356-14.322-3-15.266,5.094-.548,4.7,20.081,11.343,18.183,25.39-3.489,25.814,8.881,21.349-31.718,21.349C139.9,152.73,141.816,151.056,141.816,151.056Z" fill="url(#linear-gradient-7)"/><path d="M179.472,156.043c-59.516,0-32.291-6.3-25.806-14.088,11.275-13.544-10.25-13.235-9.777-24.991a23.853,23.853,0,0,1,8.5-17.634s-4.957,13.911,2.125,14.3,14.545-4.594,18.177-17.578c6.374-22.784.472-35.128-8.026-40.222a37.478,37.478,0,0,1,17.871,8.475c5.68,5.143-4.452,15.03-4.179,23.266.708,21.361,33.365,4.31,30.375-5.095,0,0,9.128,12.932-2.754,14.891-21.453,3.538-20.539,17.83-12.512,22.533s5.791,14.23,13.039,21.478C216.062,150.94,231.4,156.043,179.472,156.043Z" fill="url(#linear-gradient-8)"/></g></g></g><g id="Layer_3" data-name="Layer 3"><g opacity="0.7"><polygon points="100 221.366 100 277.295 32.114 178.129 100 221.366" fill="#6ca8f8"/><path d="M100,277.8a.5.5,0,0,1-.413-.218L31.7,178.412a.5.5,0,0,1,.681-.7l67.887,43.236a.5.5,0,0,1,.231.422V277.3a.5.5,0,0,1-.352.477A.507.507,0,0,1,100,277.8Zm-66.092-97.93L99.5,275.679V221.64Z" fill="#fff"/><polygon points="167.886 178.129 100 277.295 100 221.366 167.886 178.129" fill="#ce9efa"/><path d="M100,277.8a.507.507,0,0,1-.148-.023.5.5,0,0,1-.352-.477V221.366a.5.5,0,0,1,.232-.422l67.886-43.236a.5.5,0,0,1,.681.7l-67.886,99.165A.5.5,0,0,1,100,277.8Zm.5-56.155v54.039l65.592-95.814Z" fill="#fff"/><polygon points="167.886 164.16 100 125.585 100 207.397 167.886 164.16" fill="#ce9efa"/><path d="M100,207.9a.509.509,0,0,1-.241-.062.5.5,0,0,1-.259-.438V125.585a.5.5,0,0,1,.747-.434l67.886,38.575a.5.5,0,0,1,.022.856l-67.886,43.236A.5.5,0,0,1,100,207.9Zm.5-81.453v80.041l66.417-42.3Z" fill="#fff"/><polygon points="167.886 164.16 100 46.305 100 125.585 167.886 164.16" fill="#87fcda"/><path d="M167.886,164.66a.5.5,0,0,1-.247-.065L99.753,126.02a.5.5,0,0,1-.253-.435V46.305a.5.5,0,0,1,.933-.249l67.886,117.855a.5.5,0,0,1-.433.749ZM100.5,125.294l66.036,37.524L100.5,48.175Z" fill="#fff"/><polygon points="100 46.305 100 125.585 32.114 164.16 100 46.305" fill="#ce9efa"/><path d="M32.114,164.66a.5.5,0,0,1-.355-.147.5.5,0,0,1-.078-.6L99.567,46.056a.5.5,0,0,1,.933.249v79.28a.5.5,0,0,1-.253.435L32.361,164.6A.5.5,0,0,1,32.114,164.66ZM99.5,48.175,33.464,162.818,99.5,125.294Z" fill="#fff"/><polygon points="100 125.585 100 207.397 32.114 164.16 100 125.585" fill="#6ca8f8"/><path d="M100,207.9a.5.5,0,0,1-.268-.079L31.845,164.582a.5.5,0,0,1,.022-.856l67.886-38.575a.5.5,0,0,1,.747.434V207.4a.5.5,0,0,1-.5.5ZM33.083,164.185l66.417,42.3V126.444Z" fill="#fff"/></g><path d="M100,277.8a.5.5,0,0,1-.413-.218L31.7,178.412a.5.5,0,0,1,.681-.7l67.887,43.236a.5.5,0,0,1,.231.422V277.3a.5.5,0,0,1-.352.477A.507.507,0,0,1,100,277.8Zm-66.092-97.93L99.5,275.679V221.64Z" fill="#fff"/><path d="M100,277.8a.507.507,0,0,1-.148-.023.5.5,0,0,1-.352-.477V221.366a.5.5,0,0,1,.232-.422l67.886-43.236a.5.5,0,0,1,.681.7l-67.886,99.165A.5.5,0,0,1,100,277.8Zm.5-56.155v54.039l65.592-95.814Z" fill="#fff"/><path d="M100,207.9a.509.509,0,0,1-.241-.062.5.5,0,0,1-.259-.438V125.585a.5.5,0,0,1,.747-.434l67.886,38.575a.5.5,0,0,1,.022.856l-67.886,43.236A.5.5,0,0,1,100,207.9Zm.5-81.453v80.041l66.417-42.3Z" fill="#fff"/><path d="M167.886,164.66a.5.5,0,0,1-.247-.065L99.753,126.02a.5.5,0,0,1-.253-.435V46.305a.5.5,0,0,1,.933-.249l67.886,117.855a.5.5,0,0,1-.433.749ZM100.5,125.294l66.036,37.524L100.5,48.175Z" fill="#fff"/><path d="M32.114,164.66a.5.5,0,0,1-.355-.147.5.5,0,0,1-.078-.6L99.567,46.056a.5.5,0,0,1,.933.249v79.28a.5.5,0,0,1-.253.435L32.361,164.6A.5.5,0,0,1,32.114,164.66ZM99.5,48.175,33.464,162.818,99.5,125.294Z" fill="#fff"/><path d="M100,207.9a.5.5,0,0,1-.268-.079L31.845,164.582a.5.5,0,0,1,.022-.856l67.886-38.575a.5.5,0,0,1,.747.434V207.4a.5.5,0,0,1-.5.5ZM33.083,164.185l66.417,42.3V126.444Z" fill="#fff"/><path d="M17.806,278.974v30.333a174.191,174.191,0,0,1,31.75-7.458V271.515A174.135,174.135,0,0,0,17.806,278.974Z" fill="#4f4680" stroke="#fff" stroke-linecap="round" stroke-linejoin="round"/><path d="M49.556,295.4v6.454s-4.64-3.487-13.579-3.755A80.194,80.194,0,0,1,49.556,295.4Z" fill="#baacd1" stroke="#fff" stroke-linecap="round" stroke-linejoin="round"/><path d="M182.194,278.974v30.333a174.191,174.191,0,0,0-31.75-7.458V271.515A174.135,174.135,0,0,1,182.194,278.974Z" fill="#232042" stroke="#fff" stroke-linecap="round" stroke-linejoin="round"/><path d="M150.444,295.4v6.454s4.64-3.487,13.579-3.755A80.194,80.194,0,0,0,150.444,295.4Z" fill="#baacd1" stroke="#fff" stroke-linecap="round" stroke-linejoin="round"/><path d="M100,261.248c-39.532,0-64.023,6.512-64.023,6.512v30.334s24.491-6.512,64.023-6.512,64.023,6.512,64.023,6.512V267.76S139.532,261.248,100,261.248Z" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" fill="url(#linear-gradient-9)"/><path d="M190.494,314.176H9.506a.5.5,0,0,1-.5-.5V9.924a.5.5,0,0,1,.5-.5H190.494a.5.5,0,0,1,.5.5V313.676A.5.5,0,0,1,190.494,314.176Zm-180.488-1H189.994V10.424H10.006Z" fill="#fff"/><path d="M52.059,271.445l12.311-1.374.4,3.586-8.112.906.261,2.339,7.347-.82.374,3.345-7.348.821.271,2.427,8.222-.918.4,3.608-12.42,1.387Z" fill="#fff"/><path d="M67.1,269.871l4.254-.349,1.261,15.349-4.254.349Z" fill="#fff"/><path d="M74.506,269.25l6.614-.349c3.867-.2,6.478,1.663,6.656,5.047l0,.044c.193,3.647-2.5,5.706-6.3,5.907l-2.131.112.232,4.395-4.263.225Zm6.71,7.314c1.494-.079,2.4-.942,2.332-2.15l0-.044c-.07-1.319-1.05-1.95-2.567-1.87l-2.021.107.214,4.064Z" fill="#fff"/><path d="M89.323,275.249l7.213-.145.073,3.65L89.4,278.9Z" fill="#fff"/><path d="M100.46,272.257l-2.6.607-.8-3.3,4.515-1.261,3.1.011-.053,15.512-4.2-.015Z" fill="#fff"/><path d="M106.524,281.669l2.548-2.768a5.764,5.764,0,0,0,3.675,1.812c1.407.052,2.269-.62,2.311-1.719v-.044c.042-1.122-.856-1.816-2.2-1.866a4.663,4.663,0,0,0-2.491.677l-2.475-1.524.731-7.767,10.291.386-.132,3.518-6.927-.26-.219,2.326a5.417,5.417,0,0,1,2.484-.457c2.77.1,5.219,1.736,5.093,5.079v.044c-.128,3.407-2.822,5.377-6.56,5.236A8.588,8.588,0,0,1,106.524,281.669Z" fill="#fff"/><path d="M120.3,282.2l2.668-2.651a5.764,5.764,0,0,0,3.591,1.973c1.4.115,2.294-.519,2.384-1.615l0-.044c.092-1.118-.776-1.851-2.113-1.961a4.652,4.652,0,0,0-2.519.566l-2.4-1.632,1.076-7.727,10.262.843-.289,3.508-6.907-.567-.322,2.314a5.422,5.422,0,0,1,2.5-.347c2.763.227,5.136,1.967,4.862,5.3l0,.044c-.279,3.4-3.058,5.245-6.785,4.939A8.587,8.587,0,0,1,120.3,282.2Z" fill="#fff"/><path d="M143.355,280.209a4.656,4.656,0,0,1-3.415.816c-2.945-.387-4.884-2.529-4.491-5.518l.006-.044c.442-3.36,3.325-5.2,6.816-4.742a6.024,6.024,0,0,1,4.459,2.385c.967,1.258,1.457,3.1,1.087,5.914l0,.043c-.654,4.975-3.592,8.074-8.152,7.474a8.372,8.372,0,0,1-5.108-2.513l2.37-2.664a5.138,5.138,0,0,0,3.112,1.653C142.26,283.305,143.085,281.416,143.355,280.209Zm.54-3.769,0-.044a2.069,2.069,0,0,0-1.906-2.382,2.017,2.017,0,0,0-2.411,1.792l-.006.044a2.016,2.016,0,0,0,1.919,2.294A1.985,1.985,0,0,0,143.9,276.44Z" fill="#fff"/></g></svg>'
          ));

        return svg;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {

        require(_exists(id), "ERC721: token does not exist");

        string memory name = string(abi.encodePacked('Burny boy ',Strings.toString(id)));
        string memory readableBaseFee = '';

        if(tokenBaseFee[id]/uint(1000000000) > 0) {
          readableBaseFee = string(abi.encodePacked(Strings.toString(tokenBaseFee[id]/uint(1000000000)), ' Gwei'));
        } else {
          readableBaseFee = string(abi.encodePacked(Strings.toString(tokenBaseFee[id]), ' wei'));
        }

        string memory description = string(abi.encodePacked('When this was minted, the basefee was ',readableBaseFee));
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

        return
            string(
                abi.encodePacked(
                    'data:application/json,',
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                )
            );
    }
}

