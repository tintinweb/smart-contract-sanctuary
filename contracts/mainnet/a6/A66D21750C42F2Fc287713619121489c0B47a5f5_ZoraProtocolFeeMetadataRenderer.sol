// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/// Shared public library for on-chain NFT functions
interface IPublicSharedMetadata {
    /// @param unencoded bytes to base64-encode
    function base64Encode(bytes memory unencoded)
        external
        pure
        returns (string memory);

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        external
        pure
        returns (string memory);

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        external
        pure
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC721TokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title ZoraProtocolFeeSettings
/// @author tbtstl <[email protected]>
/// @notice This contract allows an optional fee percentage and recipient to be set for individual ZORA modules
contract ZoraProtocolFeeSettings is ERC721 {
    struct FeeSetting {
        uint16 feeBps;
        address feeRecipient;
    }

    address public metadata;
    address public owner;
    address public minter;
    mapping(address => FeeSetting) public moduleFeeSetting;

    event MetadataUpdated(address indexed newMetadata);
    event OwnerUpdated(address indexed newOwner);
    event ProtocolFeeUpdated(address indexed module, address feeRecipient, uint16 feeBps);

    // Only allow the module fee owner to access the function
    modifier onlyModuleOwner(address _module) {
        uint256 tokenId = moduleToTokenId(_module);
        require(ownerOf(tokenId) == msg.sender, "onlyModuleOwner");

        _;
    }

    constructor() ERC721("ZORA Module Fee Switch", "ZORF") {
        _setOwner(msg.sender);
    }

    /// @notice Initialize the Protocol Fee Settings
    /// @param _minter The address that can mint new NFTs (expected ZoraProposalManager address)
    function init(address _minter, address _metadata) external {
        require(msg.sender == owner, "init only owner");
        require(minter == address(0), "init already initialized");

        minter = _minter;
        metadata = _metadata;
    }

    /// @notice Mint a new protocol fee setting for a module
    /// @param _to, the address to send the protocol fee setting token to
    /// @param _module, the module for which the minted token will represent
    function mint(address _to, address _module) external returns (uint256) {
        require(msg.sender == minter, "mint onlyMinter");
        uint256 tokenId = moduleToTokenId(_module);
        _mint(_to, tokenId);

        return tokenId;
    }

    /// @notice Sets fee parameters for ZORA protocol.
    /// @param _module The module to apply the fee settings to
    /// @param _feeRecipient The fee recipient address to send fees to
    /// @param _feeBps The bps of transaction value to send to the fee recipient
    function setFeeParams(
        address _module,
        address _feeRecipient,
        uint16 _feeBps
    ) external onlyModuleOwner(_module) {
        require(_feeBps <= 10000, "setFeeParams must set fee <= 100%");
        require(_feeRecipient != address(0) || _feeBps == 0, "setFeeParams fee recipient cannot be 0 address if fee is greater than 0");

        moduleFeeSetting[_module] = FeeSetting(_feeBps, _feeRecipient);

        emit ProtocolFeeUpdated(_module, _feeRecipient, _feeBps);
    }

    /// @notice Sets the owner of the contract
    /// @param _owner the new owner
    function setOwner(address _owner) external {
        require(msg.sender == owner, "setOwner onlyOwner");
        _setOwner(_owner);
    }

    function setMetadata(address _metadata) external {
        require(msg.sender == owner, "setMetadata onlyOwner");
        _setMetadata(_metadata);
    }

    /// @notice Computes the fee for a given uint256 amount
    /// @param _module The module to compute the fee for
    /// @param _amount The amount to compute the fee for
    /// @return amount to be paid out to the fee recipient
    function getFeeAmount(address _module, uint256 _amount) external view returns (uint256) {
        return (_amount * moduleFeeSetting[_module].feeBps) / 10000;
    }

    /// @notice returns the module address for a given token ID
    /// @param _tokenId The token ID
    function tokenIdToModule(uint256 _tokenId) public pure returns (address) {
        return address(uint160(_tokenId));
    }

    /// @notice returns the token ID for a given module
    /// @dev we don't worry about losing the top 20 bytes when going from uint256 -> uint160 since we know token ID must have derived from an address
    /// @param _module The module address
    function moduleToTokenId(address _module) public pure returns (uint256) {
        return uint256(uint160(_module));
    }

    function _setOwner(address _owner) private {
        owner = _owner;

        emit OwnerUpdated(_owner);
    }

    function _setMetadata(address _metadata) private {
        metadata = _metadata;

        emit MetadataUpdated(_metadata);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(metadata != address(0), "ERC721Metadata: no metadata address");

        return IERC721TokenURI(metadata).tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract ModuleNamingSupportV1 {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

interface IProtocolFeeNFTTokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import {IProtocolFeeNFTTokenURI} from "./IProtocolFeeNFTTokenURI.sol";
import {IPublicSharedMetadata} from "@zoralabs/nft-editions-contracts/contracts/IPublicSharedMetadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ZoraProtocolFeeSettings} from "@zoralabs/v3/dist/contracts/auxiliary/ZoraProtocolFeeSettings/ZoraProtocolFeeSettings.sol";
import {ModuleNamingSupportV1} from "@zoralabs/v3/dist/contracts/common/ModuleNamingSupport/ModuleNamingSupportV1.sol";
import {PtMonoFont} from "./test/PtMonoFont.sol";

interface IZorbRenderer {
    function zorbForAddress(address user) external view returns (string memory);
}

/// @notice ZoraProtocolFeeMetadataRenderer - v3 periphery contract renderer for protocol fee NFTs
/// @author iain <[email protected]>
contract ZoraProtocolFeeMetadataRenderer is IProtocolFeeNFTTokenURI {
    IPublicSharedMetadata private immutable sharedMetadata;
    IZorbRenderer private immutable zorbRenderer;
    PtMonoFont private immutable font;
    ZoraProtocolFeeSettings public immutable feeSettings;

    /// @notice Constructor for the v3-periphery metadata renderer contract
    /// @param _feeSettings Link to v3 Fee settings
    /// @param _sharedMetadata Link to metadata renderer contract
    /// @param _zorbRenderer zorb project svg renderer
    /// @param _font link to the font style
    constructor(
        ZoraProtocolFeeSettings _feeSettings,
        IPublicSharedMetadata _sharedMetadata,
        IZorbRenderer _zorbRenderer,
        PtMonoFont _font
    ) {
        feeSettings = _feeSettings;
        sharedMetadata = _sharedMetadata;
        zorbRenderer = _zorbRenderer;
        font = _font;
    }

    /// @notice Internal helper for rendering fee string within embedded svg
    /// @param module address of v3 module to render fee information for
    function renderFee(address module) internal view returns (bytes memory) {
        (uint16 feeBps, address feeRecipient) = feeSettings.moduleFeeSetting(
            module
        );

        string memory feeRecipientString = "Not configured";
        if (feeRecipient != address(0x0)) {
            feeRecipientString = Strings.toHexString(
                uint256(uint160(feeRecipient))
            );
        }

        uint256 feeDecimalPart = feeBps % 100;
        string memory feeDecimalString;
        if (feeDecimalPart > 0) {
            feeDecimalString = string(
                abi.encodePacked(".", Strings.toString(feeDecimalPart))
            );
        }

        return
            abi.encodePacked(
                '<tspan x="427" y="752.977">',
                Strings.toString(feeBps / 100),
                feeDecimalString,
                "%",
                "</tspan>",
                '</text><text text-anchor="start"><tspan x="55" y="830">',
                feeRecipientString,
                "</tspan></text></svg>"
            );
    }

    /// @notice Getter that takes a module address and returns a truncated address or name if it exists
    /// @param module address for the module to render
    function attemptGetModuleName(address module)
        internal
        view
        returns (string memory)
    {
        try ModuleNamingSupportV1(module).name() returns (string memory name) {
            return name;
        } catch {
            return
                string(
                    abi.encodePacked(
                        Strings.toHexString(uint256(uint160(module)) >> 80),
                        unicode"…"
                    )
                );
        }
    }

    /// @notice Render SVG image string as bytes for the given module address.
    /// @param module svg module address
    function renderSVG(address module) public view returns (bytes memory) {
        string memory moduleName = attemptGetModuleName(module);

        return
            abi.encodePacked(
                '<svg width="500" height="900" viewBox="0 0 500 900" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><style>'
                "svg {background:#000; margin: 0 auto;} @font-face { font-family: CourierFont; src: url('",
                font.font(),
                "') format('opentype');} text { font-family: CourierFont; fill: white; white-space: pre; letter-spacing: 0.05em; font-size: 14px; } text.eyebrow { fill-opacity: 0.4; }"
                '</style></defs><rect x="38" y="683" width="422" height="44" rx="1" fill="black" /><rect x="38.5" y="683.5" width="421" height="43" rx="0.5" stroke="white" stroke-opacity="0.08" /><rect x="39" y="41" width="422" height="65" rx="1" fill="black" /> <rect x="39.5" y="41.5" width="421" height="64" rx="0.5" stroke="white" stroke-opacity="0.08" /><rect x="39" y="105" width="422" height="35" rx="1" fill="black" /><rect x="39.5" y="105.5" width="421" height="34" rx="0.5" stroke="white" stroke-opacity="0.08" /><path transform="translate(57, 57)" fill-rule="evenodd" clip-rule="evenodd" d="M2.07683 0V6.21526H28.2708L5.44618 14.2935C3.98665 14.8571 2.82212 15.6869 1.96814 16.7828C1.11416 17.8787 0.539658 19.0842 0.244645 20.3836C-0.0503676 21.6986 -0.0814215 23.0294 0.16701 24.3914C0.415442 25.7534 0.896778 26.9902 1.64207 28.1174C2.37184 29.229 3.36557 30.1526 4.5922 30.8571C5.83436 31.5616 7.29389 31.9217 8.98633 31.9217H50.8626L50.8703 31.8988C51.1535 31.914 51.4386 31.9217 51.7255 31.9217C60.4671 31.9217 67.5474 24.7828 67.5474 15.9687C67.5474 12.3143 66.333 8.94525 64.2882 6.25304L89.4471 6.2935C90.5651 6.2935 91.388 6.60661 91.9159 7.23284C92.4594 7.85906 92.7078 8.54791 92.6767 9.29937C92.6457 10.0508 92.3351 10.7397 91.7606 11.3659C91.1706 11.9921 90.3322 12.3052 89.2142 12.3052L67.7534 12.3563V12.7123L98.8254 31.9742V31.9061H105.036L104.912 9.04895C104.912 8.45404 105.036 7.93741 105.285 7.46774C105.533 7.01373 105.875 6.65365 106.309 6.43447C106.744 6.21529 107.257 6.13701 107.816 6.19964C108.375 6.26226 108.98 6.5284 109.617 6.98241L143.947 32V24.3444L113.467 2.12919C111.992 1.0333 110.377 0.391416 108.67 0.172238C106.962 -0.0469397 105.362 0.125272 103.887 0.673217C102.412 1.22116 101.186 2.12919 100.223 3.41294C99.2447 4.6967 98.7633 6.29357 98.7633 8.2192V24.7626L87.2423 18.1135L90.0682 18.0665C92.0091 18.0508 93.6084 17.5812 94.8971 16.6888C96.1858 15.7808 97.133 14.6692 97.7385 13.3385C98.3441 11.9921 98.608 10.5518 98.5459 8.98626C98.4838 7.43636 98.0801 5.98039 97.3193 4.66532C96.5585 3.35025 95.4716 2.23871 94.0431 1.36199C92.6146 0.485282 90.829 0.0469261 88.6863 0.0469261H59.4304L52.8915 0.041576C52.5116 0.0140175 52.1279 0 51.741 0C51.3629 0 50.9878 0.0133864 50.6163 0.0397145L2.07683 0ZM37.7103 8.5589L7.86839 20.227C7.23178 20.4932 6.79703 20.9315 6.56412 21.5264C6.33122 22.1213 6.28464 22.7319 6.43991 23.3425C6.59518 23.953 6.93677 24.501 7.43364 24.9706C7.9305 25.4403 8.59816 25.6751 9.42109 25.6751L39.1905 25.7073C37.1293 23.0135 35.9035 19.6361 35.9035 15.9687C35.9035 13.2949 36.5565 10.7739 37.7103 8.5589ZM61.3522 15.9687C61.3522 10.6145 57.0357 6.26223 51.741 6.26223C46.4308 6.26223 42.1143 10.6145 42.1298 15.9687C42.1298 21.3072 46.4308 25.6595 51.741 25.6595C57.0357 25.6595 61.3522 21.3229 61.3522 15.9687Z" fill="white" />'
                '<text><tspan x="57" y="125.076">The NFT Marketplace Protocol</tspan></text><rect x="38" y="726" width="422" height="44" rx="1" fill="black" /><rect x="38.5" y="726.5" width="421" height="43" rx="0.5" stroke="white" stroke-opacity="0.08" />'
                '<rect x="38" y="769" width="422" height="83" rx="1" fill="black" /><rect x="38.5" y="769.5" width="421" height="82" rx="0.5" stroke="white" stroke-opacity="0.08" />'
                '<image transform="translate(158, 360) scale(1.2)" href="',
                zorbRenderer.zorbForAddress(module),
                '" alt="ZORB" />'
                '<path d="M248.5 370.5C292.683 370.5 328.5 406.317 328.5 450.5C328.5 494.683 292.683 530.5 248.5 530.5C204.317 530.5 168.5 494.683 168.5 450.5C168.5 406.317 204.317 370.5 248.5 370.5Z" stroke="black" stroke-opacity="0.1" />'
                '<text class="eyebrow"><tspan x="53" y="708.076">Module</tspan></text><text class="eyebrow"><tspan x="53" y="752.977">Fee</tspan></text><text class="eyebrow"><tspan x="53" y="800.977">Fee Recipient</tspan></text><text text-anchor="end"><tspan x="427" y="708.076">',
                moduleName,
                '</tspan></text><text text-anchor="end">',
                renderFee(module)
            );
    }

    /// @notice tokenURI getter function for the contract
    /// @param tokenId id of token to render derived from the module address
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        address moduleAddress = feeSettings.tokenIdToModule(tokenId);
        feeSettings.ownerOf(tokenId); // ensure owner
        string memory moduleName = attemptGetModuleName(moduleAddress);

        return
            sharedMetadata.encodeMetadataJSON(
                abi.encodePacked(
                    '{"name": "Zora Module ',
                    moduleName,
                    ' Fee Settings", "description": "Zora Fee Settings: ',
                    moduleName,
                    '", "image": "data:image/svg+xml;base64,',
                    sharedMetadata.base64Encode(renderSVG(moduleAddress)),
                    '"}'
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

/// @notice PtMonoFont deployed for corruptions
contract PtMonoFont {
    // based off the very excellent PT Mono font

    /*
    Copyright (c) 2011, ParaType Ltd. (http://www.paratype.com/public),
    with Reserved Font Names "PT Sans", "PT Serif", "PT Mono" and "ParaType".

    This Font Software is licensed under the SIL Open Font License, Version 1.1.
    This license is copied below, and is also available with a FAQ at:
    http://scripts.sil.org/OFL


    -----------------------------------------------------------
    SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
    -----------------------------------------------------------

    PREAMBLE
    The goals of the Open Font License (OFL) are to stimulate worldwide
    development of collaborative font projects, to support the font creation
    efforts of academic and linguistic communities, and to provide a free and
    open framework in which fonts may be shared and improved in partnership
    with others.

    The OFL allows the licensed fonts to be used, studied, modified and
    redistributed freely as long as they are not sold by themselves. The
    fonts, including any derivative works, can be bundled, embedded, 
    redistributed and/or sold with any software provided that any reserved
    names are not used by derivative works. The fonts and derivatives,
    however, cannot be released under any other type of license. The
    requirement for fonts to remain under this license does not apply
    to any document created using the fonts or their derivatives.

    DEFINITIONS
    "Font Software" refers to the set of files released by the Copyright
    Holder(s) under this license and clearly marked as such. This may
    include source files, build scripts and documentation.

    "Reserved Font Name" refers to any names specified as such after the
    copyright statement(s).

    "Original Version" refers to the collection of Font Software components as
    distributed by the Copyright Holder(s).

    "Modified Version" refers to any derivative made by adding to, deleting,
    or substituting -- in part or in whole -- any of the components of the
    Original Version, by changing formats or by porting the Font Software to a
    new environment.

    "Author" refers to any designer, engineer, programmer, technical
    writer or other person who contributed to the Font Software.

    PERMISSION & CONDITIONS
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of the Font Software, to use, study, copy, merge, embed, modify,
    redistribute, and sell modified and unmodified copies of the Font
    Software, subject to the following conditions:

    1) Neither the Font Software nor any of its individual components,
    in Original or Modified Versions, may be sold by itself.

    2) Original or Modified Versions of the Font Software may be bundled,
    redistributed and/or sold with any software, provided that each copy
    contains the above copyright notice and this license. These can be
    included either as stand-alone text files, human-readable headers or
    in the appropriate machine-readable metadata fields within text or
    binary files as long as those fields can be easily viewed by the user.

    3) No Modified Version of the Font Software may use the Reserved Font
    Name(s) unless explicit written permission is granted by the corresponding
    Copyright Holder. This restriction only applies to the primary font name as
    presented to the users.

    4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
    Software shall not be used to promote, endorse or advertise any
    Modified Version, except to acknowledge the contribution(s) of the
    Copyright Holder(s) and the Author(s) or with their explicit written
    permission.

    5) The Font Software, modified or unmodified, in part or in whole,
    must be distributed entirely under this license, and must not be
    distributed under any other license. The requirement for fonts to
    remain under this license does not apply to any document created
    using the Font Software.

    TERMINATION
    This license becomes null and void if any of the above conditions are
    not met.

    DISCLAIMER
    THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
    OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
    DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
    OTHER DEALINGS IN THE FONT SOFTWARE.
    */

    string public constant font = "data:font/otf;base64,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";
}