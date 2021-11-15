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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {IMetaDataGenerator} from './interfaces/IMetaDataGenerator.sol';
import {ICryptoPiggies} from './interfaces/ICryptoPiggies.sol';

/**
 * @dev Implementation of the Non-Fungible Token CryptoPiggies which uses a MetaDataGenerator to generate MetaData fully on-chain
 * Each piggy stores some eth, which can be redeemed by breaking the piggie, so there is a hard floor for sellers.
 */

contract CryptoPiggies is ERC721, ICryptoPiggies {
    address payable public override treasury;
    IMetaDataGenerator public immutable override METADATAGENERATOR;

    mapping(uint256 => Piggy) piggies;

    uint256 public constant MINT_MASK = 0xfffff;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MINT_VALUE = MINT_PRICE / 2;
    uint256 public constant FLIP_MIN_COST = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT = 20;

    uint256 internal _supply = 0;
    uint256 internal _broken = 0;

    constructor(address payable treasury_, IMetaDataGenerator generator)
        ERC721('CryptoPiggies', 'CPig')
    {
        treasury = treasury_;
        METADATAGENERATOR = generator;
    }

    function setTreasury(address payable treasury_) public {
        require(treasury == msg.sender, 'caller not treasury');
        treasury = treasury_;
    }

    /**
     * @dev Mints CryptoPiggies to the msg.sender when receiving ETH directly.
     *      Computes the number of CryptoPiggies from the msg.value
     */
    receive() external payable override {
        uint256 piggiesToMint = msg.value / MINT_PRICE;
        giftPiggies(piggiesToMint > MAX_MINT ? MAX_MINT : piggiesToMint, msg.sender);
    }

    /**
     * @dev Mints CryptoPiggies to the msg.sender
     * @param piggiesToMint the amount of CryptoPiggies to mint
     */
    function mintPiggies(uint256 piggiesToMint) public payable override {
        giftPiggies(piggiesToMint, msg.sender);
    }

    /**
     * @dev Minting CryptoPiggies to another account than msg.sender
     * @param piggiesToMint the amount of CryptoPiggies to mint
     * @param to the address to receive those CryptoPiggies
     */
    function giftPiggies(uint256 piggiesToMint, address to) public payable override {
        uint256 supply = _supply;
        require(piggiesToMint > 0, 'cannot mint 0 piggies');
        require(piggiesToMint <= MAX_MINT, 'exceeds max mint');
        require(supply + piggiesToMint <= MAX_SUPPLY, 'exceeds max supply');
        require(msg.value >= MINT_PRICE * piggiesToMint, 'insufficient eth');
        _supply = _supply + piggiesToMint;
        for (uint256 i = 0; i < piggiesToMint; i++) {
            _mintPiggie(to, supply + i);
        }
        treasury.transfer(MINT_VALUE * piggiesToMint);
        uint256 refundAmount = msg.value - piggiesToMint * MINT_PRICE;
        payable(msg.sender).transfer(refundAmount);
    }

    /**
     * @dev Destroy CryptoPiggies to redeem the ETH they hold
     * @param tokenIds the CryptoPiggies to destroy
     * @param to the receiver of the funds
     */
    function breakPiggies(uint256[] memory tokenIds, address payable to) external override {
        uint256 fundsInBroken = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            fundsInBroken += _breakPiggie(tokenId);
        }
        _broken += tokenIds.length;
        to.transfer(fundsInBroken);

        emit Break(tokenIds.length, fundsInBroken, to);
    }

    /**
     * @dev Resets the trait mask to the initial mask
     * @param tokenId the CryptoPiggy to reset
     */
    function resetTraitMask(uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'caller is not approved nor owner');
        piggies[tokenId].traitMask = MINT_MASK;
        piggies[tokenId].flipCost = FLIP_MIN_COST;
        emit ResetMask(tokenId);
    }

    /**
     * @dev Update multiple traits at once
     * @param tokenId the CryptoPiggy to update traits on
     * @param positions the traits to flip
     * @param onOffs whether to turn the trait on or off
     */
    function updateMultipleTraits(
        uint256 tokenId,
        uint256[] memory positions,
        bool[] memory onOffs
    ) public payable override {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'caller is not approved nor owner');
        require(positions.length == onOffs.length, 'length mismatch');
        uint256 costOfFlipping = 0;
        for (uint256 i = 0; i < positions.length; i++) {
            costOfFlipping += piggies[tokenId].flipCost * (2**i);
        }
        require(msg.value >= costOfFlipping, 'insufficient eth');

        Piggy memory piggie = piggies[tokenId];
        for (uint256 i = 0; i < positions.length; i++) {
            require(positions[i] > 4, 'cannot flip piggy or colors');
            if (onOffs[i]) {
                piggie.traitMask = newMask(piggie.traitMask, 15, positions[i]);
                emit TurnTraitOn(tokenId, positions[i]);
            } else {
                piggie.traitMask = newMask(piggie.traitMask, 0, positions[i]);
                emit TurnTraitOff(tokenId, positions[i]);
            }
        }

        piggie.flipCost = piggie.flipCost * (2 * (positions.length));
        piggie.balance += msg.value / 2;
        piggies[tokenId] = piggie;

        treasury.transfer(msg.value / 2);
    }

    /**
     * @dev Turn on a nibble (4 bits) in the trait mask.
     * @param tokenId the CryptoPiggy to update mask for
     * @param position nibble index from the right to flip
     */
    function turnTraitOn(uint256 tokenId, uint256 position) public payable override {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'caller is not approved nor owner');
        _updateTraitMask(tokenId, 15, position);
        emit TurnTraitOn(tokenId, position);
    }

    /**
     * @dev Turn off a nibble (4 bits) in the trait mask.
     * @param tokenId the CryptoPiggy to update mask for
     * @param position nibble index from the right to flip
     */
    function turnTraitOff(uint256 tokenId, uint256 position) public payable override {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'caller is not approved nor owner');
        _updateTraitMask(tokenId, 0, position);
        emit TurnTraitOff(tokenId, position);
    }

    /**
     * @dev Donates ETH from msg.value directly to a CryptoPiggy
     * @param tokenId the CryptoPiggy to donate to
     */

    function deposit(uint256 tokenId) public payable override {
        require(_exists(tokenId), 'cannot deposit to non-existing piggy');
        piggies[tokenId].balance += msg.value;
        emit Deposit(tokenId, msg.value);
    }

    /**
     * @dev Generates SVG image for CryptoPiggy with the activeGene and balance
     * @param tokenId the CryptoPiggy to generate image for
     * @return SVG contents
     */
    function getSVG(uint256 tokenId) public view override returns (string memory) {
        return METADATAGENERATOR.getSVG(activeGeneOf(tokenId), piggyBalance(tokenId));
    }

    /**
     * @dev Generates MetaData for a specific CryptoPiggy using its activeGene and balance
     * @param tokenId the CryptoPiggy to generate metadata for
     * @return Base64 encoded MetaData for the CryptoPiggy
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        IMetaDataGenerator.MetaDataParams memory params = IMetaDataGenerator.MetaDataParams(
            tokenId,
            activeGeneOf(tokenId),
            piggyBalance(tokenId),
            ownerOf(tokenId)
        );
        return METADATAGENERATOR.tokenURI(params);
    }

    function totalSupply() external view returns (uint256) {
        return _supply;
    }

    function broken() external view override returns (uint256) {
        return _broken;
    }

    function geneOf(uint256 tokenId) external view override returns (uint256) {
        return piggies[tokenId].gene;
    }

    function traitMaskOf(uint256 tokenId) external view override returns (uint256) {
        return piggies[tokenId].traitMask;
    }

    function activeGeneOf(uint256 tokenId) public view override returns (uint256) {
        return piggies[tokenId].gene & piggies[tokenId].traitMask;
    }

    function piggyBalance(uint256 tokenId) public view override returns (uint256) {
        return piggies[tokenId].balance;
    }

    function flipCost(uint256 tokenId) external view override returns (uint256) {
        return piggies[tokenId].flipCost;
    }

    function getPiggy(uint256 tokenId) external view override returns (Piggy memory) {
        return piggies[tokenId];
    }

    // Internal functions

    function _mintPiggie(address to, uint256 tokenId) internal {
        // Semi gameable gene
        uint256 gene = uint256(
            keccak256(
                abi.encode(
                    blockhash(block.number),
                    // blockhash(block.number - 50), // This is why coverage is fuckeds
                    gasleft(),
                    msg.sender,
                    to,
                    tokenId,
                    _supply,
                    _broken
                )
            )
        );
        piggies[tokenId] = Piggy(gene, MINT_MASK, MINT_VALUE, FLIP_MIN_COST);
        _mint(to, tokenId);
    }

    function _breakPiggie(uint256 tokenId) internal returns (uint256 balance) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'caller is not approved nor owner');
        balance = piggies[tokenId].balance;
        delete piggies[tokenId];
        _burn(tokenId);
    }

    function _updateTraitMask(
        uint256 tokenId,
        uint256 replaceValue,
        uint256 position
    ) internal {
        require(position > 4, 'cannot flip piggy or colors');
        Piggy memory piggie = piggies[tokenId];
        require(msg.value >= piggie.flipCost, 'insufficient eth');
        piggie.traitMask = newMask(piggie.traitMask, replaceValue, position);
        piggie.flipCost += piggie.flipCost;
        piggie.balance += msg.value / 2;
        piggies[tokenId] = piggie;

        treasury.transfer(msg.value / 2);
    }

    function newMask(
        uint256 mask,
        uint256 replacement,
        uint256 position
    ) internal pure virtual returns (uint256) {
        uint256 rhs = position > 0 ? mask % 16**position : 0;
        uint256 lhs = (mask / (16**(position + 1))) * (16**(position + 1));
        uint256 insert = replacement * 16**position;
        return lhs + insert + rhs;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IMetaDataGenerator} from './IMetaDataGenerator.sol';

interface ICryptoPiggies is IERC721 {
    struct Piggy {
        uint256 gene;
        uint256 traitMask;
        uint256 balance;
        uint256 flipCost;
    }

    // Events

    event ResetMask(uint256 tokenId);
    event TurnTraitOn(uint256 tokenId, uint256 position);
    event TurnTraitOff(uint256 tokenId, uint256 position);
    event Deposit(uint256 tokenId, uint256 amount);
    event Break(uint256 piggiesBroken, uint256 amount, address to);

    // Functions for minting

    receive() external payable;

    function mintPiggies(uint256 piggiesToMint) external payable;

    function giftPiggies(uint256 piggiesToMint, address to) external payable;

    // Breaking

    function breakPiggies(uint256[] memory tokenIds, address payable to) external;

    // Manipulating mask

    function resetTraitMask(uint256 tokenId) external;

    function turnTraitOn(uint256 tokenId, uint256 position) external payable;

    function turnTraitOff(uint256 tokenId, uint256 position) external payable;

    function updateMultipleTraits(
        uint256 tokenId,
        uint256[] memory position,
        bool[] memory onOff
    ) external payable;

    // Depositing eth into a piggy

    function deposit(uint256 tokenId) external payable;

    // Views

    function getSVG(uint256 tokenId) external view returns (string memory);

    function piggyBalance(uint256 tokenId) external view returns (uint256);

    function geneOf(uint256 tokenId) external view returns (uint256);

    function traitMaskOf(uint256 tokenId) external view returns (uint256);

    function activeGeneOf(uint256 tokenId) external view returns (uint256);

    function getPiggy(uint256 tokenId) external view returns (Piggy memory);

    function flipCost(uint256 tokenId) external view returns (uint256);

    function broken() external view returns (uint256);

    function treasury() external view returns (address payable);

    function METADATAGENERATOR() external view returns (IMetaDataGenerator);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IMetaDataGenerator {
    struct MetaDataParams {
        uint256 tokenId;
        uint256 activeGene;
        uint256 balance;
        address owner;
    }

    struct Attribute {
        uint256 layer;
        uint256 scene;
    }

    struct EncodedData {
        uint8[576] composite;
        uint256[] colorPalette;
        string[] attributes;
    }

    function getSVG(uint256 activeGene, uint256 balance) external view returns (string memory);

    function tokenURI(MetaDataParams memory params) external view returns (string memory);

    function getEncodedData(uint256 activeGene) external view returns (EncodedData memory);

    function ossified() external view returns (bool);
}

