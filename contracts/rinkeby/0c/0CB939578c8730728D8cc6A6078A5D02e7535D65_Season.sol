// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IGovernable } from '../Governance/IGovernable.sol';

interface ISeasonFactory is IGovernable {
    function handleIndividualScoreIncrease(address user, uint16 score) external;

    function handleSeasonNftTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint16 score
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISeason {
    struct AddInitialVaultPoolArgs {
        address vaultPoolAddr;
        uint32 weight;
    }

    function initialize(
        uint32 _startBlock,
        uint32 _endBlock,
        uint256 _anonPerBlock,
        address _anonToken,
        AddInitialVaultPoolArgs[] calldata _initialVaultPools,
        string memory name_,
        string memory symbol_,
        bytes32 _initialDescription
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SeasonScores } from './SeasonScores.sol';
import { SeasonFactory } from '../SeasonFactory.sol';
import { ISeason } from './ISeason.sol';

/// @title Season Implementation
/// @notice This root contract inherits all the other contracts in this directory
/// @dev Clones of this contract are deployed using ERC-1167 proxies
contract Season is ISeason, SeasonScores {
    /// @notice This function is used to initialize state of this contract
    /// @dev Contract should be immediately initialized on deployed
    function initialize(
        uint32 _startBlock,
        uint32 _endBlock,
        uint256 _anonPerBlock,
        address _anonToken,
        ISeason.AddInitialVaultPoolArgs[] calldata _initialVaultPools,
        string memory name_,
        string memory symbol_,
        bytes32 _initialDescription
    ) external override {
        __SeasonBase_init(_startBlock, _endBlock, _anonPerBlock, _anonToken);
        __SeasonVaultPools_init(_initialVaultPools);
        __ERC721_init(name_, symbol_);
        __SeasonScores_init(_initialDescription);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISeasonFactory } from '../ISeasonFactory.sol';

/// @notice Base abstract contract for Seasons
abstract contract SeasonBase {
    uint32 public startBlock;
    uint32 public endBlock;

    uint256 public anonPerBlock;
    address public anonToken;

    ISeasonFactory public seasonFactory;

    /// @notice This internal function initializes base state variables
    /// @param _startBlock: The block from which season starts
    /// @param _endBlock: The block at which season ends
    /// @param _anonPerBlock: Amount of ANON Tokens per block
    /// @param _anonToken: Address of ANON ERC20
    function __SeasonBase_init(
        uint32 _startBlock,
        uint32 _endBlock,
        uint256 _anonPerBlock,
        address _anonToken
    ) internal {
        require(anonToken == address(0), 'SeasonBase:init:A');
        require(_anonToken != address(0), 'SeasonBase:init:B');
        require(_startBlock <= _endBlock, 'SeasonBase:init:C');

        startBlock = _startBlock;
        endBlock = _endBlock;
        anonPerBlock = _anonPerBlock;
        anonToken = _anonToken;

        seasonFactory = ISeasonFactory(msg.sender);
    }

    /// @notice Uses governance address in Season Factory
    function governance() public view returns (address) {
        return seasonFactory.governance();
    }

    /// @notice Uses team multisig address from Season Factory
    function teamMultisig() public view returns (address) {
        return seasonFactory.teamMultisig();
    }

    /// @notice Methods which are critical and require a timelock
    modifier onlyGovernance() {
        require(msg.sender == governance(), 'SeasonBase:onlyGovernance');
        _;
    }

    /// @notice Methods which are not that critical and do not require a timelock
    modifier onlyGovernanceOrTeamMultisig() {
        require(msg.sender == teamMultisig(), 'SeasonBase:onlyGovernance');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20, ERC20Burnable } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { CInt64 } from '../../libraries/CInt64.sol';
import { SeasonNFT } from './SeasonNFT.sol';
import { SeasonVaultPools } from './SeasonVaultPools.sol';
import { PRECISION_FACTOR } from '../../constants.sol';

/// @notice Logic for Farming ANON tokens in Seasons
abstract contract SeasonFarm is SeasonNFT, SeasonVaultPools {
    using SafeERC20 for IERC20;
    using CInt64 for uint64;
    using CInt64 for uint256;

    // Keeps track of user vault pool deposits and farmed rewards
    // bytes32 x1
    struct UserNFTVaultDeposit {
        uint64 depositedCompressed;
        uint64 accAnonRewardPerVaultDepositTokenLastCompressed;
        uint64 farmedCompressed; // locked + unlocked; unlocked = farmed * score / 100
        uint64 claimedCompressed; // some of unlocked tokens that the user claimed
    }

    // nft id => vault pool address => UserNFTVaultDeposit struct
    mapping(uint256 => mapping(address => UserNFTVaultDeposit)) internal userNftVaultDeposits; // getter added below

    event Deposit(uint256 indexed nftId, address vaultPoolAddr, uint256 amount);
    event Claim(uint256 indexed nftId, address vaultPoolAddr, uint256 amount);
    event Withdraw(uint256 indexed nftId, address vaultPoolAddr, uint256 amount);

    struct DepositArgs {
        address vaultPoolAddr;
        uint256 amount;
    }

    /// @notice Used by user for the first time to create their season NFT and deposit vault share tokens in it
    /// @param teamId season team for the user's season nft
    /// @param depositArgsArr addresses and amounts of vault pools (that has ERC20 share tokens)
    function mintAndDeposit(uint8 teamId, DepositArgs[] calldata depositArgsArr) external {
        // mint the new NFT
        uint256 nftId = ++lastNftId;
        _mint(msg.sender, nftId);

        // initialize user struct
        userNfts[nftId] = UserNFT({ teamId: teamId, individualScore: 0, teamScoreToExclude: teamScores[teamId] }); // SSTORE

        // Pull all deposit tokens from user
        for (uint256 i; i < depositArgsArr.length; i++) {
            _deposit(nftId, depositArgsArr[i].vaultPoolAddr, depositArgsArr[i].amount);
        }
    }

    /// @notice Deposit vault share tokens
    /// @param nftId: The transfrable nft's token id on which the deposits will be recorded
    /// @param depositArgsArr: list of vault pool addresses and their amounts
    function deposit(uint256 nftId, DepositArgs[] calldata depositArgsArr) public {
        require(_exists(nftId), 'SeasonFarm:deposit:D');
        for (uint256 i; i < depositArgsArr.length; i++) {
            _deposit(nftId, depositArgsArr[i].vaultPoolAddr, depositArgsArr[i].amount);
        }
    }

    /// @notice Claim unlocked ANON tokens from user's pools
    function claim(
        uint256 nftId,
        address[] calldata vaultPoolAddr,
        address beneficiary
    ) public onlyApprovedOrOwner(nftId) {
        for (uint256 i; i < vaultPoolAddr.length; i++) {
            _claim(nftId, vaultPoolAddr[i], beneficiary);
        }
    }

    /// @notice Withdraws all principal and unlocked tokens
    function withdraw(
        uint256 nftId,
        address[] calldata vaultPoolAddr,
        address beneficiary
    ) external onlyApprovedOrOwner(nftId) {
        for (uint256 i; i < vaultPoolAddr.length; i++) {
            _withdraw(nftId, vaultPoolAddr[i], beneficiary);
        }
    }

    /// @notice Getter for vaultPools that exposes the decompressed values
    function getUserNftVaultDeposits(uint256 nftId, address vaultPoolAddr)
        external
        view
        returns (
            uint256 deposited,
            uint256 accAnonRewardPerVaultDepositTokenLast,
            uint256 farmed,
            uint256 claimed
        )
    {
        UserNFTVaultDeposit memory unvd = userNftVaultDeposits[nftId][vaultPoolAddr];
        deposited = unvd.depositedCompressed.decompress();
        accAnonRewardPerVaultDepositTokenLast = unvd.accAnonRewardPerVaultDepositTokenLastCompressed.decompress();
        farmed = unvd.farmedCompressed.decompress();
        claimed = unvd.claimedCompressed.decompress();
    }

    function _deposit(
        uint256 nftId,
        address vaultPoolAddr,
        uint256 amount
    ) private {
        require(amount > 0, 'SeasonFarm:_deposit:P');

        UserNFTVaultDeposit memory userNftVaultDeposit = _updateUserNFTVaultDeposit(nftId, vaultPoolAddr);

        // used compressed value
        uint64 amountCompressed = amount.compress();
        amount = amountCompressed.decompress(); // to prevent collecting dust from the user

        IERC20(vaultPoolAddr).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(nftId, vaultPoolAddr, amount);

        // update total deposited amount in vault pool
        // vaultPool.totalDepositsCompressed = vaultPool.totalDepositsCompressed.cadd(amountCompressed);
        // vaultPools[vaultPoolAddr] = vaultPool; // SSTORE

        // update deposit amount in user
        userNftVaultDeposit.depositedCompressed = userNftVaultDeposit.depositedCompressed.cadd(amountCompressed);
        userNftVaultDeposits[nftId][vaultPoolAddr] = userNftVaultDeposit; // SSTORE
    }

    function _claim(
        uint256 nftId,
        address vaultPoolAddr,
        address beneficiary
    ) internal returns (UserNFTVaultDeposit memory userNftVaultDeposit, uint256 unclaimedRewards) {
        require(beneficiary != address(0), 'SeasonFarm:_claim:N');
        UserNFT memory userNft = userNfts[nftId];
        userNftVaultDeposit = _updateUserNFTVaultDeposit(nftId, vaultPoolAddr);

        uint16 score = userNft.individualScore + teamScores[userNft.teamId] - userNft.teamScoreToExclude;

        // decompressing stored values
        uint256 farmed = userNftVaultDeposit.farmedCompressed.decompress();
        uint256 claimed = userNftVaultDeposit.claimedCompressed.decompress();

        // only allow a partial claiming of farmed amount based on score
        uint256 maxClaimAmount = (farmed * Math.min(10000, score)) / 10000;
        uint64 maxClaimAmountCompressed = maxClaimAmount.compress();
        maxClaimAmount = maxClaimAmountCompressed.decompress(); // rounding down the max claim amount
        if (maxClaimAmount > claimed) {
            // update claimed value
            userNftVaultDeposit.claimedCompressed = maxClaimAmountCompressed;
            userNftVaultDeposits[nftId][vaultPoolAddr] = userNftVaultDeposit; // SSTORE

            // calculating pending reward to transfer
            uint256 transferAmount = maxClaimAmount - claimed;
            IERC20(anonToken).safeTransfer(beneficiary, transferAmount);
            emit Claim(nftId, vaultPoolAddr, transferAmount);
        }
        unclaimedRewards = farmed - maxClaimAmount;
    }

    function _withdraw(
        uint256 nftId,
        address vaultPoolAddr,
        address beneficiary
    ) private {
        (UserNFTVaultDeposit memory userNftVaultDeposit, uint256 unclaimedRewards) = _claim(
            nftId,
            vaultPoolAddr,
            beneficiary
        );
        // decompressing stored values
        uint256 amount = userNftVaultDeposit.depositedCompressed.decompress();

        // subtracting the withdrawal amount from total deposits
        // vaultPool.totalDepositsCompressed = vaultPool.totalDepositsCompressed.csubUint256(amount);
        // vaultPools[vaultPoolAddr] = vaultPool; // SSTORE

        // updating user state
        userNftVaultDeposit.depositedCompressed = 0; // 0 decompresses to zero
        userNftVaultDeposits[nftId][vaultPoolAddr] = userNftVaultDeposit; // SSTORE

        // sending principal amount to user
        emit Withdraw(nftId, vaultPoolAddr, amount);
        IERC20(vaultPoolAddr).safeTransfer(beneficiary, amount);

        // burning unclaimable rewards (due to user score not reaching 100%)
        if (unclaimedRewards > 0) {
            ERC20Burnable(anonToken).burn(unclaimedRewards);
        }
    }

    function _updateUserNFTVaultDeposit(uint256 nftId, address poolAddr)
        private
        returns (UserNFTVaultDeposit memory userNftVaultDeposit)
    {
        userNftVaultDeposit = userNftVaultDeposits[nftId][poolAddr]; // SLOAD
        VaultPool memory vaultPool = _updateVaultPool(poolAddr);
        {
            // decompressing stored values
            uint256 accRewardPerVaultShareToken = vaultPool.accAnonRewardPerVaultDepositTokenCompressed.decompress();
            uint256 accRewardPerVaultShareTokenLast = userNftVaultDeposit
                .accAnonRewardPerVaultDepositTokenLastCompressed
                .decompress();
            uint256 deposited = userNftVaultDeposit.depositedCompressed.decompress();

            // calculating the increase in the user farmed rewards
            uint256 increase = ((accRewardPerVaultShareToken - accRewardPerVaultShareTokenLast) * deposited) /
                PRECISION_FACTOR;

            userNftVaultDeposit.farmedCompressed = userNftVaultDeposit.farmedCompressed.caddUint256(increase);
            userNftVaultDeposit.accAnonRewardPerVaultDepositTokenLastCompressed = vaultPool
                .accAnonRewardPerVaultDepositTokenCompressed;
        }
        userNftVaultDeposits[nftId][poolAddr] = userNftVaultDeposit; // SSTORE
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import { SeasonBase } from './SeasonBase.sol';

/// @notice Logic for managing the User's participation NFT
abstract contract SeasonNFT is SeasonBase, ERC721Upgradeable {
    // increased before minting a new nft
    uint256 public lastNftId;

    // NFT parameters, score unit is bps, takes values from 0 to 10_000
    struct UserNFT {
        uint8 teamId;
        uint16 individualScore; // earned by doing tasks
        uint16 teamScoreToExclude; // teamScore when user joins
    }

    // nft id => UserNFT struct
    mapping(uint256 => UserNFT) internal userNfts;

    // team id => team score
    mapping(uint8 => uint16) public teamScores;

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'SeasonNFT:onlyApprovedOrOwner');
        _;
    }

    // getter function for frontend
    function getUserNft(uint256 nftId)
        external
        view
        returns (
            address owner,
            uint8 teamId,
            uint16 individualScore,
            uint16 teamScore,
            uint16 teamScoreWithoutExclude
        )
    {
        owner = ownerOf(nftId);

        UserNFT memory _userNFT = userNfts[nftId];
        uint16 _teamScore = teamScores[_userNFT.teamId];

        teamId = _userNFT.teamId;
        individualScore = _userNFT.individualScore;
        teamScore = _teamScore - _userNFT.teamScoreToExclude;
        teamScoreWithoutExclude = _teamScore;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // only allow holding one nft at an address, because we don't want scores of
        //  same seasons nfts to be doublt counted for amplification in staking contract
        if (to != address(0)) {
            require(balanceOf(to) == 0, 'SeasonNFT:_beforeTokenTransfer:E');
        }

        seasonFactory.handleSeasonNftTransfer(from, to, tokenId, userNfts[tokenId].individualScore);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { MerkleProof } from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import { SeasonFarm } from './SeasonFarm.sol';

/// @notice Logic for updating scores to seasons
abstract contract SeasonScores is SeasonFarm {
    // ipfs hash is 34 bytes, and the first two bytes are 0x1220 (SHA-256, 32 byte length)
    // we exclude these 2 bytes for optimisation, and the client requires to convert this bytes32
    // value into a 34 bytes multihash encoded in base58.
    // ipfs hash => merkle root
    mapping(bytes32 => bytes32) public batchMerkleRoots;

    /// @dev To prevent replay proves
    // token id, task id => isProved
    mapping(uint256 => mapping(uint16 => bool)) public proved;

    event Description(bytes32 ipfsHash);
    event Submission(uint256 nftId, bytes32 ipfsHash, uint256 timestamp);
    event Prove(uint256 tokenId, uint16 taskId);
    event Batch(bytes32 merkleRoot, bytes32 ipfsHash);

    /// @notice This internal function initializes the description
    /// @param initialDescriptionIpfsHash: Initial Description, containing all the tasks
    function __SeasonScores_init(bytes32 initialDescriptionIpfsHash) internal {
        emit Description(initialDescriptionIpfsHash);
    }

    /// @notice This function emits the IPFS hash of the description/tasks list which is to be displayed in UI.
    /// @dev This is not stored in a variable because it is only utilized by frontend client
    ///     and not on the smart contracts.
    /// @param ipfsHash: the ipfs hash without the first two bytes
    function updateDescription(bytes32 ipfsHash) external onlyGovernanceOrTeamMultisig {
        emit Description(ipfsHash);
    }

    /// @notice Broadcasts IPFS hash for user submission
    /// @param ipfsHash: the ipfs hash without the first two bytes
    /// @dev This is submission for tasks that are done offchain. Contract has no idea to verify
    ///     how if user actually did the offchain task. So these need to be verified by a community member
    ///     and then uploaded to this contract by "addMerkleRoot" method through a governance proposal.
    function submit(uint256 nftId, bytes32 ipfsHash) external onlyApprovedOrOwner(nftId) {
        // timestamp is there to prevent extra call to query timestamp in UI
        emit Submission(nftId, ipfsHash, block.timestamp);
    }

    /// @notice This function allows governance to add a batch of approved tasks (done by users offchain,
    ///     then seen and verified by Anon team)
    /// @param _ipfsHash: ipfs hash of the list of approved tasks
    /// @param _merkleRoot: merkle root of all the approved tasks, which individual users can later prove
    ///     to claim their score.
    function addMerkleRoot(bytes32 _ipfsHash, bytes32 _merkleRoot) public onlyGovernance {
        require(batchMerkleRoots[_ipfsHash] == bytes32(0), 'SeasonScores:addMerkleRoot:M');
        batchMerkleRoots[_ipfsHash] = _merkleRoot;
        emit Batch(_merkleRoot, _ipfsHash);
    }

    struct MerkleTreeLeaf {
        address season;
        uint16 taskId;
        bool isIndividual;
        uint16 score;
        uint48 nftId;
    }

    struct ProveArgs {
        bytes32 batchIpfsHash;
        MerkleTreeLeaf leaf;
        bytes32[] proof;
    }

    struct ClaimArgs {
        uint256 nftId;
        address[] vaultPoolAddrArray;
        address beneficiary;
    }

    /// @notice This function is used by users to perform multiple proves, and claim in the same tx
    /// @param proveArgsArray: array of all the prove args
    /// @param claimArgs: if user wants to withdraw their rewards in the same transaction
    function proveMultipleAndClaim(ProveArgs[] calldata proveArgsArray, ClaimArgs calldata claimArgs) external {
        for (uint256 i; i < proveArgsArray.length; i++) {
            prove(proveArgsArray[i]);
        }

        if (claimArgs.vaultPoolAddrArray.length > 0) {
            // reverts if caller is not owner of nftId
            claim(claimArgs.nftId, claimArgs.vaultPoolAddrArray, claimArgs.beneficiary);
        }
    }

    /// @notice This function is used by users to prove that their task (that they did offchain) is
    ///     seen and approved by governance.
    /// @param args: leaf in the merkle tree
    function prove(ProveArgs calldata args) public {
        bytes32 root = batchMerkleRoots[args.batchIpfsHash];
        require(root != bytes32(0), 'SeasonScores:prove:Z');
        require(args.leaf.season == address(this), 'SeasonScores:prove:A');
        require(!proved[args.leaf.nftId][args.leaf.taskId], 'SeasonScores:prove:C');
        require(
            MerkleProof.verify(
                args.proof,
                root,
                keccak256(
                    abi.encodePacked(
                        args.leaf.season,
                        args.leaf.taskId,
                        args.leaf.isIndividual,
                        args.leaf.score,
                        args.leaf.nftId
                    )
                )
            ),
            'SeasonScores:prove:V'
        );

        // preventing replays
        proved[args.leaf.nftId][args.leaf.taskId] = true;

        // increase individual score for the task doer regardless the task was individual or team
        userNfts[args.leaf.nftId].individualScore = uint16(
            Math.min(10000, userNfts[args.leaf.nftId].individualScore + args.leaf.score)
        );
        seasonFactory.handleIndividualScoreIncrease(ownerOf(args.leaf.nftId), args.leaf.score);

        // if the task was team task, then increment team score and also ensure task doer is not
        //  double awarded
        if (!args.leaf.isIndividual) {
            teamScores[userNfts[args.leaf.nftId].teamId] += args.leaf.score;
            userNfts[args.leaf.nftId].teamScoreToExclude += args.leaf.score; // subtract from user's self team score
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20, ERC20Burnable } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { CInt64 } from '../../libraries/CInt64.sol';
import { SeasonBase } from './SeasonBase.sol';
import { PRECISION_FACTOR } from '../../constants.sol';
import { ISeason } from './ISeason.sol';

/// @notice Logic for managing vault pool state in seasons
abstract contract SeasonVaultPools is SeasonBase {
    using CInt64 for uint64;
    using CInt64 for uint256;

    uint32 public totalWeight;
    uint32 public numberOfVaultPools;

    // Vaults which have ERC20 ownership shares
    // Multiple vaults are added by the governance for allowing users to deposit and farm ANON tokens
    // Anon per block for the season is distributed proportionally among these vault pools based on their weights.
    // bytes32 x1
    struct VaultPool {
        // uint64 totalDepositsCompressed; // vaultPool.balanceOf(this)
        uint64 accAnonRewardPerVaultDepositTokenCompressed;
        uint32 lastUpdateBlock;
        uint32 weight;
        bool isInitialized;
    }

    // vault address => VaultPool struct
    mapping(address => VaultPool) internal vaultPools; // getter added below

    event VaultPoolWeightUpdated(address poolToken, uint32 weight);

    function __SeasonVaultPools_init(ISeason.AddInitialVaultPoolArgs[] calldata _initialVaultPools) internal {
        require(_initialVaultPools.length > 0, 'SeasonVP:init:Z');

        uint32 _totalWeight;

        for (uint256 i; i < _initialVaultPools.length; i++) {
            VaultPool memory vaultPool;
            vaultPool.weight = _initialVaultPools[i].weight;
            vaultPool.lastUpdateBlock = startBlock - 1;
            vaultPool.isInitialized = true;

            vaultPools[_initialVaultPools[i].vaultPoolAddr] = vaultPool; // SSTORE

            _totalWeight += _initialVaultPools[i].weight;

            emit VaultPoolWeightUpdated(_initialVaultPools[i].vaultPoolAddr, _initialVaultPools[i].weight);
        }

        // single SSTORE
        totalWeight = _totalWeight;
        numberOfVaultPools = uint32(_initialVaultPools.length);
    }

    /// @notice Updates weight of vault pool
    /// @param vaultPoolAddr: Address of the vault pool
    /// @param weight: new weight to be set
    /// @param vaultPoolAddrArray: array of addresses of all the active vault pools
    /// @dev Before adding a new vault (or changing weight of a single vault pool), we need to
    ///     update accumulated rewards for all the vault pools. Since sc does not maintain an
    ///     enumerable list of vault pools, it depends on external entity (client) to query the
    ///     events and and provide a list of addresses. Then this list is verified.
    function addOrUpdateVaultPoolWeight(
        address vaultPoolAddr,
        uint32 weight,
        address[] calldata vaultPoolAddrArray
    ) external onlyGovernance {
        // ensure provided vaultPoolArr has correct length
        require(vaultPoolAddrArray.length == numberOfVaultPools, 'SeasonVP:addOrUVPW:L'); // SLOAD

        // update all the vault pool state, this is needed since after this block
        //     rewards will be based on the new weights proportion
        VaultPool memory vaultPool = _updateAllVaultPools(vaultPoolAddrArray, vaultPoolAddr);

        // single SLOAD
        uint32 _numberOfVaultPools = numberOfVaultPools;
        uint32 _totalWeight = totalWeight;
        if (!vaultPool.isInitialized) {
            // if this is a new vault pool
            // vaultPool would be empty, initialize the necessary props
            vaultPool.lastUpdateBlock = uint32(block.number);
            vaultPool.isInitialized = true;
            _numberOfVaultPools++;
        }

        // update global sum of all pool weights
        // single SSTORE
        totalWeight = _totalWeight + weight - vaultPool.weight;
        numberOfVaultPools = _numberOfVaultPools;

        // update vault pool state
        vaultPool.weight = weight;
        vaultPools[vaultPoolAddr] = vaultPool; // SSTORE

        emit VaultPoolWeightUpdated(vaultPoolAddr, weight);
    }

    /// @notice Getter for vaultPools that exposes the decompressed values
    function getVaultPool(address vaultPoolAddr)
        external
        view
        returns (
            uint256 totalDeposits,
            uint256 accAnonRewardPerVaultDepositToken,
            uint32 lastUpdateBlock,
            uint32 weight,
            bool isInitialized
        )
    {
        VaultPool memory vaultPool = vaultPools[vaultPoolAddr];
        totalDeposits = IERC20(vaultPoolAddr).balanceOf(address(this)); // vaultPool.totalDepositsCompressed.decompressRoundingUp(); // rounded up for less rewards to users
        accAnonRewardPerVaultDepositToken = vaultPool.accAnonRewardPerVaultDepositTokenCompressed.decompress();
        lastUpdateBlock = vaultPool.lastUpdateBlock;
        weight = vaultPool.weight;
        isInitialized = vaultPool.isInitialized;
    }

    /// @notice Update rewards for a vault pool
    /// @dev This internal method is also used in SeasonRewards.sol to update vault pool state before
    ///     any user interaction.
    /// @param vaultPoolAddr: Address of vault pool to be updated
    /// @return vaultPool : gives the updated vault pool object
    function _updateVaultPool(address vaultPoolAddr) internal returns (VaultPool memory vaultPool) {
        vaultPool = vaultPools[vaultPoolAddr]; // SLOAD

        // check if the vault pool is initialized (in use)
        require(vaultPool.isInitialized, 'SeasonVP:_updateVaultPool:I');

        // do not update if season is not yet started
        if (block.number < startBlock) {
            return vaultPool;
        }

        uint256 fromBlock = Math.max(startBlock - 1, vaultPool.lastUpdateBlock);
        uint256 toBlock = Math.min(endBlock, uint32(block.number));
        vaultPool.lastUpdateBlock = uint32(toBlock);
        // rounded up for processing slightly less rewards to users, to ensure contract does not loose money
        uint256 totalVaultPoolTokenDeposits = IERC20(vaultPoolAddr).balanceOf(address(this)); // vaultPool.totalDepositsCompressed.decompressRoundingUp();

        if (totalVaultPoolTokenDeposits > 0) {
            // if there were any deposits, record the rewards for them
            uint256 increase = (((toBlock - fromBlock) * anonPerBlock * vaultPool.weight * PRECISION_FACTOR) /
                totalWeight) / totalVaultPoolTokenDeposits;
            vaultPool.accAnonRewardPerVaultDepositTokenCompressed = vaultPool
                .accAnonRewardPerVaultDepositTokenCompressed
                .caddUint256(increase);
        } else {
            // if there were no deposits then burn the reward for those blocks
            uint256 unrewardableTokens = ((toBlock - fromBlock) * anonPerBlock * vaultPool.weight) / totalWeight;
            ERC20Burnable(anonToken).burn(unrewardableTokens);
        }

        vaultPools[vaultPoolAddr] = vaultPool; // SSTORE
    }

    /// @notice Used to update all the vault pools
    /// @param vaultPoolAddrArray: list of addresses of vault pools,
    /// @param addrToCheck: while going through the for loop also check if this address exists
    /// @return vaultPoolToUpdate : gives an initialized VaultPool object if exists, else the object
    ///     it's initialized prop as false
    function _updateAllVaultPools(address[] calldata vaultPoolAddrArray, address addrToCheck)
        private
        returns (VaultPool memory vaultPoolToUpdate)
    {
        uint160 last;

        for (uint256 i; i < vaultPoolAddrArray.length; i++) {
            address vaultPoolAddr = vaultPoolAddrArray[i];

            // check if the array is sorted, by comparing last element to current
            uint160 current = uint160(vaultPoolAddr);
            require(current > last, 'SeasonVP:_updateAllVP:S');
            last = current;

            // update vault pool state
            VaultPool memory vaultPool = _updateVaultPool(vaultPoolAddr); // SLOAD + SSTORE

            if (addrToCheck == vaultPoolAddr) {
                vaultPoolToUpdate = vaultPool;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';
import { Governable } from '../Governance/Governable.sol';
import { ISeason } from './Season/ISeason.sol';
import { IScoreUpdateCallbackReceiver } from '../Callbacks/IScoreUpdateCallbackReceiver.sol';

/// @title The Season Factory Contract
contract SeasonFactory is Governable {
    using SafeERC20 for IERC20;

    address public immutable anonToken;
    address public seasonImplementation; // changable

    // season address => is valid
    mapping(address => bool) public isValidSeason;

    event SeasonCreated(address seasonAddr);
    event SeasonImplementationChanged(address newSeasonImplementation);

    modifier onlySeason() {
        // callable by Season contract (the child contract)
        require(isValidSeason[msg.sender], 'SeasonFactory:onlySeason:V');
        _;
    }

    constructor(address anonToken_) {
        anonToken = anonToken_;
    }

    struct InitializeSeasonArgs {
        uint32 startBlock; // The block from which season starts
        uint32 endBlock; // The block at which season ends
        uint256 anonPerBlock; // Amount of ANON Tokens per block
        address fundsFrom; // Address that pays the rewards
        ISeason.AddInitialVaultPoolArgs[] initalVaultPools; // Vault addresses and weights
        string name; // Season NFT Name
        string symbol; // Season NFT Symbol
        bytes32 initialDescription;
    }

    /// @notice Allows governance to create a new season
    /// @param args: Arguments required to initialize a created season
    /// @dev Need allowance by fundsFrom of (endBlock - startBlock + 1) * anonPerBlock ANON tokens
    function createSeason(InitializeSeasonArgs calldata args) external onlyGovernance {
        require(seasonImplementation != address(0), 'SeasonFactory:createSeason:Z');
        address season = Clones.clone(seasonImplementation);
        _initializeSeason(season, args);
    }

    /// @notice Changes the season implementation bytecode
    /// @dev seasons created before this are not affected
    /// @param newSeasonImplementation: Address of the new implementation
    function changeSeasonImplementation(address newSeasonImplementation, InitializeSeasonArgs calldata args)
        external
        onlyGovernance
    {
        seasonImplementation = newSeasonImplementation;
        emit SeasonImplementationChanged(newSeasonImplementation);

        // if initialize season args are provided then initialize
        if (args.anonPerBlock != 0) {
            _initializeSeason(newSeasonImplementation, args);
        }
    }

    /// @notice Initializes a season after it's deployment
    /// @param season: Address of freshly deployed season contract
    /// @param args: Create season args required to pass to the Season.initialize method
    function _initializeSeason(address season, InitializeSeasonArgs calldata args) internal {
        IERC20(anonToken).safeTransferFrom(
            args.fundsFrom,
            season,
            (args.endBlock - args.startBlock + 1) * args.anonPerBlock
        );
        ISeason(season).initialize(
            args.startBlock,
            args.endBlock,
            args.anonPerBlock,
            anonToken,
            args.initalVaultPools,
            args.name,
            args.symbol,
            args.initialDescription
        );

        isValidSeason[season] = true;

        emit SeasonCreated(season);
    }

    /**
        Tracking individual scores for better UX in AnonStaking & Governance
     */
    IScoreUpdateCallbackReceiver public callback;
    mapping(address => uint32) public userIndividualScoreSum;

    event NftTransfer(address season, address from, address to, uint256 nftId);

    /// @notice Changes the callback logic
    /// @dev This is to be used when a new contract is added to the ecosystem which requires
    ///     to be triggered whenever score updates.
    /// @param callback_: new callback contract
    function setCallback(IScoreUpdateCallbackReceiver callback_) external onlyGovernance {
        callback = callback_;
    }

    /// @notice Called by season contract when score of a user increases
    /// @param user: Address of user who owns an NFT whose score is increasing
    /// @param score: Amount of score that is increased in the NFT
    function handleIndividualScoreIncrease(address user, uint16 score) external onlySeason {
        userIndividualScoreSum[user] += score;

        IScoreUpdateCallbackReceiver _callback = callback;
        // if callback contract not yet set then do not call
        if (address(_callback) != address(0)) {
            _callback.handleIndividualScoreChanged(user);
        }
    }

    /// @notice Called by season contract when a user is transferring their NFT to someone
    /// @param from: the user who is transferring their nft
    /// @param to: the user who is receiving the nft
    /// @param score: score in the nft
    function handleSeasonNftTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint16 score
    ) external onlySeason {
        emit NftTransfer(msg.sender, from, to, tokenId);

        if (from != address(0)) {
            userIndividualScoreSum[from] -= score;
        }
        if (to != address(0)) {
            userIndividualScoreSum[to] += score;
        }

        IScoreUpdateCallbackReceiver _callback = callback;
        // if callback contract not yet set then do not call
        if (address(_callback) != address(0)) {
            _callback.handleIndividualScoreChanged(from);
            _callback.handleIndividualScoreChanged(to);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IScoreUpdateCallbackReceiver {
    function handleIndividualScoreChanged(address userAddr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Context } from '@openzeppelin/contracts/utils/Context.sol';

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance` and `onlyGovernanceOrTeamMultisig`, which can be applied to your functions
 * to restrict their use to the caller.
 */
abstract contract Governable is Context {
    address private _governance;
    address private _teamMultisig;

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event TeamMultisigTransferred(address indexed previousTeamMultisig, address indexed newTeamMultisig);

    /**
     * @dev Initializes the contract setting the deployer as the initial governance and team multisig.
     */
    constructor() {
        address msgSender = _msgSender();

        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);

        _teamMultisig = msgSender;
        emit TeamMultisigTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current governance.
     */
    function governance() public view virtual returns (address) {
        return _governance;
    }

    /**
     * @dev Returns the address of the current team multisig.
     */
    function teamMultisig() public view virtual returns (address) {
        return _teamMultisig;
    }

    /**
     * @dev Throws if called by any account other than the governance.
     */
    modifier onlyGovernance() {
        require(governance() == _msgSender(), 'Governable: caller is not the gov');
        _;
    }

    /**
     * @dev Throws if called by any account other than the governance or team multisig.
     */
    modifier onlyGovernanceOrTeamMultisig() {
        require(
            teamMultisig() == _msgSender() || governance() == _msgSender(),
            'Governable: caller is not the gov or multisig'
        );
        _;
    }

    /**
     * @dev Transfers governance to a new account (`newGovernance`).
     * Can only be called by the current governance.
     */
    function transferGovernance(address newGovernance) public virtual onlyGovernance {
        require(newGovernance != address(0), 'Governable: new gov is the zero address');
        emit GovernanceTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }

    /**
     * @dev Transfers teamMultisig to a new account (`newTeamMultisig`).
     * Can only be called by the current teamMultisig or current governance.
     */
    function transferTeamMultisig(address newTeamMultisig) public virtual onlyGovernanceOrTeamMultisig {
        require(newTeamMultisig != address(0), 'Governable: new multisig is the zero address');
        emit TeamMultisigTransferred(_teamMultisig, newTeamMultisig);
        _teamMultisig = newTeamMultisig;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernable {
    function governance() external view returns (address);

    function teamMultisig() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

uint256 constant PRECISION_FACTOR = 1e18;

uint8 constant ANON_DECIMALS = 18;
uint256 constant ANON_TOTAL_SUPPLY = 10_000_000 * (10**ANON_DECIMALS);

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library CInt64 {
    /**
     * CInt Core
     */

    function compress(uint256 full) internal pure returns (uint64 cint) {
        unchecked {
            uint8 bits = mostSignificantBit(full);
            if (bits <= 55) {
                cint = uint64(full) << 8;
            } else {
                bits -= 55;
                cint = (uint64(full >> bits) << 8) + bits;
            }
        }
    }

    function decompress(uint64 cint) internal pure returns (uint256 full) {
        unchecked {
            uint8 bits = uint8(cint % (1 << 9));
            full = uint256(cint >> 8) << bits;
        }
    }

    function decompressRoundingUp(uint64 cint) internal pure returns (uint256 full) {
        unchecked {
            uint8 bits = uint8(cint % (1 << 9));
            full = (uint256(cint >> 8) << bits) + (uint256(1 << bits) - 1);
        }
    }

    function mostSignificantBit(uint256 val) internal pure returns (uint8 bit) {
        unchecked {
            if (val >= 0x100000000000000000000000000000000) {
                val >>= 128;
                bit += 128;
            }
            if (val >= 0x10000000000000000) {
                val >>= 64;
                bit += 64;
            }
            if (val >= 0x100000000) {
                val >>= 32;
                bit += 32;
            }
            if (val >= 0x10000) {
                val >>= 16;
                bit += 16;
            }
            if (val >= 0x100) {
                val >>= 8;
                bit += 8;
            }
            if (val >= 0x10) {
                val >>= 4;
                bit += 4;
            }
            if (val >= 0x4) {
                val >>= 2;
                bit += 2;
            }
            if (val >= 0x2) bit += 1;
        }
    }

    /**
     * CInt Math
     */

    function cadd(uint64 a, uint64 b) internal pure returns (uint64 cint) {
        cint = compress(decompress(a) + decompress(b));
    }

    function caddUint256(uint64 a, uint256 b) internal pure returns (uint64 cint) {
        cint = compress(decompress(a) + b);
    }

    function csub(uint64 a, uint64 b) internal pure returns (uint64 cint) {
        cint = compress(decompress(a) - decompress(b));
    }

    function csubUint256(uint64 a, uint256 b) internal pure returns (uint64 cint) {
        cint = compress(decompress(a) - b);
    }

    function cmul(uint64 a, uint64 b) internal pure returns (uint64 cint) {
        cint = compress(decompress(a) * decompress(b));
    }

    function cdiv(uint64 a, uint64 b) internal pure returns (uint64 cint) {
        cint = compress(decompress(a) / decompress(b));
    }

    function cmuldiv(
        uint64 a,
        uint64 b,
        uint64 c
    ) internal pure returns (uint64 cint) {
        cint = compress((decompress(a) * decompress(b)) / decompress(c));
    }
}

