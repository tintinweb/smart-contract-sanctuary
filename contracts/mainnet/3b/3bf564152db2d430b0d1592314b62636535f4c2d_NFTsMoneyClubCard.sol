/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

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





interface INFTMoneyClubCard {
    function acceptPartnerFee() external payable returns (bool);
    function hasUser(address _user) external view returns (bool, bool);
    function mint(uint256 _parentTokenID, bool _wannaVIP) external payable ;
    function upgradeToVIP() external  payable  ;
    function upgradeTokenToVIP(uint256 _tokenID) external payable;
    function buyService(uint256 _parentTokenID, uint32 _serviceID) external payable ;
    function distributePartnerFee(address _partner) external ;
    function setUserImage(string memory _hash) external ;
    function claimReward() external  ;
    function claimCommissionPool() external ;
    function availableRewardForUser(address _user) external  view returns(uint256);
    function getUserRefData(address user) external view returns(bool, uint256, uint256, uint32, uint32, uint8, uint32, uint8, uint8, uint64, string memory);
}














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
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
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







/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721Upgradeable.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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
    uint256[46] private __gap;
}












/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}




contract NFTsMoneyClubCard is ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, INFTMoneyClubCard
{

    // bytes32 public constant MANAGER = keccak256("MANAGER");
    uint256 public constant e12 = 10**12;

    struct User{
        uint64 parentTokenID; // token ID of the parent token;
        uint32 ePower; //Earning Power
        uint32 vPower; //Voting Power
        uint8 refBonus; //referralBonus, %
        uint32 refCount; //amount of referrals
        uint8 discount; //user's discount, %
        uint8 xFactor; //magic happens here...
        bool vip; //VIP Status flag.
        uint64 rank; //user Rank
        uint256 directRefBonusBalance;//amount of ETH distributed to a user as a direct referral bonus
        uint256 directRefBonusBalanceWithdrawn;
        //userpool or vippool related withdrawals;
        uint256 pendingReward; //how many tokens user was rewarded with, pending to withdraw
        uint256 totalRewarded; //total amount of ETH rewarded to user from pool (userPool/vipPool)
        uint256 rewardDebt; // Reward debt. See explanation below.
        //NFT Metadata
        string imageHash; // imageHash in IPFS
    }

     // Info of each pool.
    struct Pool {
        uint256 totalAmountDistributed;// total amount of reward distributed to pool shareholders
        uint256 accTokenPerShare; // Accumulated Tokens per share, times 1e12. share = ePower
        uint256 totalDeposited; //total tokens deposited in address of a pool [ePower]
    }

    mapping(uint256 => User) userData; //tokenID => User
    string private baseURIStr;
    /**
    Max values for:
    [0] max ePower
    [1] max vPower
    [2] max refBonus
    [3] max discount
    [4] max xFactor
    [5] refCount value when a User becomes VIP
    [6] max user pool percent value
    [7] vip pool commission from service [percent]
    [8] ref Level2 percent value
    [9] commission pool distribution percent when service bought
    [10] max totalSupply
    [11] vip pool commission when buying/upgrading to VIP [percent]
    */
    uint32[12] public settings;
    uint256[2] public cardPrices; //card prices [0] - userPrice [1] - vipPrice
    mapping(uint32 => uint256) public servicePrices;

    uint256 private directRefBonusBalance; //[ETH]
    // uint256 public userPoolBalance; //[ETH]
    // uint256 public vipPoolBalance; //[ETH]
    uint256 private commissionPoolBalance; //[ETH]

    Pool private userPool;
    Pool private vipPool;

    uint128 public totalVPower;
    uint128 public totalVIPs;

    address payable public commissionPoolDistributor;

    mapping(address => uint256) private whitelistedServiceContracts;
    mapping(address => uint256) private undistributedServiceContractsBalance;

    uint8 private storageVersion;

    event MintBonuses(uint256 indexed tokenID, uint256 price, uint256 refBonus, uint256 userBonus, uint256 vipBonus, uint256 commission);
    event UpgradeBonuses(uint256 indexed tokenID, uint256 price, uint256 refBonus, uint256 userBonus, uint256 vipBonus, uint256 commission);
    event ServiceBonuses(uint256 indexed tokenID, uint256 price, uint256 refBonus, uint256 userBonus, uint256 vipBonus, uint256 commission);

    event ServicePriceSet(uint256 indexed id, uint256 price);
    event RewardClaimed(uint256 indexed tokenID, uint256 directRefBonus, uint256 poolRewardPayout);
    event XFactorUpdated(address indexed user, uint256 indexed tokenID, uint8 xFactor);
    event RankUpdated(address indexed user, uint256 indexed tokenID, uint64 rank);

    function initialize() public initializer {
        __ERC721Enumerable_init();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ERC721_init_unchained("NFTs Money Club Card", "NMCC");
        // _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        baseURIStr = "ipfs://";
        settings = [
            uint32(1000), //[0] max ePower
            uint32(1000), //[1] max vPower
            uint32(25), //[2] max refBonus
            uint32(20), //[3] max discount
            uint32(10), //[4] max xFactor
            uint32(100), //[5] refCount value when a User becomes VIP
            uint32(45), //[6] max user pool percent value
            uint32(5), //[7] vip pool commission from service [percent]
            uint32(5),  //[8] ref Level2 percent value;
            uint32(20), //[9] commission pool distribution percent when service bought
            uint32(50000), //[10] max totalSupply
            uint32(25) //vip pool commission when buying/upgrading to VIP [percent]
            ];
        cardPrices = [100000000000000000, 2000000000000000000]; //0.1 && 2 ETH
        storageVersion = version();
    }

    function version() public pure returns (uint8){
        return uint8(5);
    }

    function updateStorage() public {
        require (storageVersion < version(), "Can't upgrade. Already done!");
        storageVersion = version();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIStr;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721EnumerableUpgradeable) returns (bool){
        return  super.supportsInterface(interfaceId)
                || interfaceId == type(IERC721Upgradeable).interfaceId
                || interfaceId == type(IERC721EnumerableUpgradeable).interfaceId
                || interfaceId == type(IERC721MetadataUpgradeable).interfaceId;
    }

    //*************** OWNER FUNCTIONS ******************************* */

    function setBaseURI(string memory _baseURIStr) public onlyOwner(){
        baseURIStr = _baseURIStr;
    }

    function pause() public onlyOwner() {
        super._pause();
    }

    function unpause() public onlyOwner() {
        super._unpause();
    }

    function updateSettings(uint256 _id, uint32 _value) public onlyOwner(){
        require(_id < settings.length,"Index out of bound");
        settings[_id] = _value;
    }

    function updateCardPrices(uint256 _id, uint256 _value) public onlyOwner(){
        require(_id < cardPrices.length,"Index out of bound");
        cardPrices[_id] = _value;
    }

    function setServicePrice(uint32 _id, uint256 _value) public onlyOwner(){
        servicePrices[_id] = _value;
        emit ServicePriceSet(_id, _value);
    }

    function setCommissionPoolDistributor(address payable _address) public onlyOwner(){
        commissionPoolDistributor = _address;
    }

    function setUserXFactor(uint256 _tokenID, uint8 _xFactor) public onlyOwner() {
        require(_exists(_tokenID), "Token doesn't exist");
        userData[_tokenID].xFactor = _xFactor;
        emit XFactorUpdated(ownerOf(_tokenID), _tokenID, _xFactor);
    }

    function setUserRank(uint256 _tokenID, uint64 _rank) public onlyOwner() {
        require(_exists(_tokenID), "Token doesn't exist");
        userData[_tokenID].rank = _rank;
        emit RankUpdated(ownerOf(_tokenID), _tokenID, _rank);
    }

    function whitelistServiceContract(address _contract, uint256 _parentTokenID) public onlyOwner() {
        whitelistedServiceContracts[_contract] = _parentTokenID;
    }

    function delistServiceContract(address _contract) public onlyOwner(){
        delete whitelistedServiceContracts[_contract];
    }

    //*************** PUBLIC FUNCTIONS ******************************* */
    function mintRegular(uint256 _parentTokenID) public payable whenNotPaused(){
        mint(_parentTokenID, false);
    }

    function mintVIP(uint256 _parentTokenID) public payable whenNotPaused(){
        mint(_parentTokenID, true);
    }

    function mint(uint256 _parentTokenID, bool _wannaVIP) public override payable whenNotPaused(){
        require(!isContract(msg.sender), "Contract calls are not available");
        require(totalSupply() <= settings[10], "No more cards allowed");
        require(balanceOf(msg.sender) == 0, "NFTs Club Card already minted for this address");
        uint256 requiredValue = _price(_wannaVIP);
        if(_exists(_parentTokenID)){
            requiredValue = requiredValue * 9 / 10; //10% discount applied
        }
        require(msg.value >= requiredValue, "Not enough money sent");

        if(_exists(_parentTokenID)){
            userData[_parentTokenID].refCount++;

            if(!userData[_parentTokenID].vip && userData[_parentTokenID].refCount >= settings[5]){
                _moveUserToVIPPool(_parentTokenID);
            }

            if(userData[_parentTokenID].refBonus < settings[2]){
                userData[_parentTokenID].refBonus++;
            }
            // else if(userData[_parentTokenID].ePower + 10 < settings[0]){
            //     _increaseEPower(_parentTokenID, 10);
            // }

        }

        // Mint User Card
        bool userVip = _wannaVIP ? true: (_random(0,1000,"vip") > 990);
        uint256 userEPower = userVip ? uint32(800): _random(100, settings[0], "epower");
        uint256 mintedTokenID = totalSupply() + 1;
        _safeMint(msg.sender, mintedTokenID);
         //deposit user ePower into the pool (therefore the user is immediately eligible for rewards)
        if(userVip){
            vipPool.totalDeposited += userEPower;
        }else{
            userPool.totalDeposited += userEPower;
        }
        //distributing money

        //1. refBonus for Parent (layer 1)
        uint256 thisRefBonus = 0;
        if(_exists(_parentTokenID)){
            thisRefBonus = requiredValue*userData[_parentTokenID].refBonus / 100;
            userData[_parentTokenID].directRefBonusBalance += thisRefBonus;
            //1.1. refBonus for Parent (layer 2)
            if(_exists(userData[_parentTokenID].parentTokenID) ){
                uint256 level2Bonus = requiredValue * settings[8] / 100;
                thisRefBonus += level2Bonus;
                userData[userData[_parentTokenID].parentTokenID].directRefBonusBalance += level2Bonus;
            }
        }
        directRefBonusBalance += thisRefBonus;

        //2. vipPoolBalance
        uint256 thisVipPoolBonus = requiredValue * (userVip?settings[11]:settings[7]) / 100;
        vipPool.accTokenPerShare += thisVipPoolBonus * e12 / vipPool.totalDeposited;
        vipPool.totalAmountDistributed += thisVipPoolBonus;


        //3. userPoolBalance
        uint256 thisUserPoolBonus = 0;
        if(!userVip){
            thisUserPoolBonus = requiredValue * settings[6] / 100 - thisRefBonus;
            userPool.accTokenPerShare += thisUserPoolBonus * e12 / userPool.totalDeposited;
            userPool.totalAmountDistributed += thisUserPoolBonus;
        }

        //4. commissionPoolBalance
        uint256 thisCommissionPoolBonus = 0;
        if(thisVipPoolBonus+thisUserPoolBonus+thisRefBonus < requiredValue){
            thisCommissionPoolBonus = requiredValue - (thisVipPoolBonus + thisUserPoolBonus + thisRefBonus);
        }
        commissionPoolBalance += thisCommissionPoolBonus;

        //event
        emit MintBonuses(mintedTokenID, requiredValue, thisRefBonus, thisUserPoolBonus, thisVipPoolBonus, thisCommissionPoolBonus);

        //distribute rewards on the user in the pool
        uint256 userRewardDebt;
        if(userVip){
            totalVIPs++;
            userRewardDebt = userEPower * vipPool.accTokenPerShare / e12;
        }else{
            userRewardDebt = userEPower * userPool.accTokenPerShare / e12;
        }

        userData[mintedTokenID] = User({
            parentTokenID: uint64(_parentTokenID),
            ePower: uint32(userEPower),
            vPower: userVip ? settings[1]: uint32(_random(100,settings[1],"vpower")),
            refBonus: userVip ? uint8(settings[2]) : uint8(_random(10, settings[2],"refbonus")),
            refCount: 0,
            discount: userVip ? uint8(settings[3]) :  uint8(_random(5, settings[3],"discount")),
            xFactor: uint8(_random(5, settings[4],"xfactor")),
            vip: userVip,
            rank: 0,
            directRefBonusBalance: 0,
            directRefBonusBalanceWithdrawn: 0,
            pendingReward: 0,
            totalRewarded: 0,
            rewardDebt: userRewardDebt,
            imageHash: ""
        });

        totalVPower += userData[mintedTokenID].vPower;

        //send remaining value of ETH back to user;
        if(msg.value > requiredValue){
            address payable receiver = payable(msg.sender);
            receiver.transfer(msg.value - requiredValue);
        }

    }

    function upgradeToVIP() public override payable whenNotPaused() {
        upgradeTokenToVIP(tokenOfOwnerByIndex(msg.sender,0));
    }

    function upgradeTokenToVIP(uint256 _tokenID) public override payable whenNotPaused() {
        require(!isContract(msg.sender), "Contract calls are not available");
        require(_exists(_tokenID), "Incorrect tokenID");
        require(!userData[_tokenID].vip, "Already VIP");

        uint256 requiredValue = _price(true) - _price(false); //price difference
        uint256 _parentTokenID = userData[_tokenID].parentTokenID;

        if(_exists(_parentTokenID)){
            requiredValue = requiredValue * 9 / 10; //10% discount applied
        }
        require(msg.value >= requiredValue, "Not enough money sent");

        //move User to VIP pool
        _moveUserToVIPPool(_tokenID);

        if(userData[_tokenID].vPower < settings[1]){
            totalVPower += (settings[1] - userData[_tokenID].vPower); //add the difference
            userData[_tokenID].vPower = settings[1];
        }
        userData[_tokenID].refBonus = userData[_tokenID].refBonus > settings[2] ? userData[_tokenID].refBonus : uint8(settings[2]);
        userData[_tokenID].discount = userData[_tokenID].discount > settings[3] ? userData[_tokenID].discount : uint8(settings[3]);
        //distributing money

        //1. refBonus for Parent (layer 1)
        uint256 thisRefBonus = 0;
        if(_exists(_parentTokenID)){
            thisRefBonus = requiredValue*userData[_parentTokenID].refBonus/100;
            userData[_parentTokenID].directRefBonusBalance += thisRefBonus;
            //1.1. refBonus for Parent (layer 2)
            if(_exists(userData[_parentTokenID].parentTokenID) ){
                uint256 level2Bonus = requiredValue * settings[8] / 100;
                thisRefBonus += level2Bonus;
                userData[userData[_parentTokenID].parentTokenID].directRefBonusBalance += level2Bonus;
            }
        }
        directRefBonusBalance += thisRefBonus;

        //2. vipPoolBalance
        uint256 thisVipPoolBonus = requiredValue * settings[11] / 100;
        vipPool.accTokenPerShare += thisVipPoolBonus * e12 / vipPool.totalDeposited;
        vipPool.totalAmountDistributed += thisVipPoolBonus;

        //3. userPoolBalance
        uint256 thisUserPoolBonus = 0;

        //4. commissionPoolBalance
        uint256 thisCommissionPoolBonus = 0;
        if(thisVipPoolBonus+thisUserPoolBonus+thisRefBonus < requiredValue){
            thisCommissionPoolBonus = requiredValue - (thisVipPoolBonus + thisUserPoolBonus + thisRefBonus);
        }
        commissionPoolBalance += thisCommissionPoolBonus;

        //event
        emit UpgradeBonuses(_tokenID, requiredValue, thisRefBonus, thisUserPoolBonus, thisVipPoolBonus, thisCommissionPoolBonus);

        //send remaining value of ETH back to user;
        if(msg.value > requiredValue){
            address payable receiver = payable(msg.sender);
            receiver.transfer(msg.value - requiredValue);
        }
    }

    function buyService(uint256 _parentTokenID, uint32 _serviceID) public override payable whenNotPaused() {
        // require(_serviceID < servicePrices.length, "Service ID Invalid");
        uint256 requiredValue = servicePrices[_serviceID];
        if(_exists(_parentTokenID)){
            //apply discount
            requiredValue = requiredValue * (100 - userData[_parentTokenID].discount) / 100;
            if(userData[_parentTokenID].ePower + 100 < settings[0]){
                _increaseEPower(_parentTokenID, 100);
            }
        }
        // distribute money
        _distributeServiceFee(requiredValue, _parentTokenID);

        //send remaining value of ETH back to user;
        if(msg.value > requiredValue){
            address payable receiver = payable(msg.sender);
            receiver.transfer(msg.value - requiredValue);
        }
    }

    function acceptPartnerFee() external override payable returns (bool) {
        if(msg.value > 0) {
            undistributedServiceContractsBalance[msg.sender] += msg.value;
            return true;
        } else {
            return false;
        }
    }

    function distributePartnerFee(address _partner) public override whenNotPaused(){
        uint256 toDistribute = undistributedServiceContractsBalance[_partner];
        require(toDistribute > 0, "Nothing to distribute");
        require(whitelistedServiceContracts[_partner] > 0, "Partner referral not set");
        undistributedServiceContractsBalance[_partner] = 0;
        _distributeServiceFee(toDistribute, whitelistedServiceContracts[_partner]);
    }

    function setUserImage(string memory _hash) public override whenNotPaused(){
        uint256 _tokenID = tokenOfOwnerByIndex(msg.sender,0);
        userData[_tokenID].imageHash = _hash;
    }

    function burn(uint256 _tokenId) external whenNotPaused() {
        _burn(_tokenId);
    }

    function claimReward() public override whenNotPaused() {
        uint256 _tokenID = tokenOfOwnerByIndex(msg.sender,0);
        require(!isContract(msg.sender), "Contract calls are not available");
        require(ownerOf(_tokenID) == msg.sender, "Not a token owner");
        uint256 directRefBonusPayout = userData[_tokenID].directRefBonusBalance - userData[_tokenID].directRefBonusBalanceWithdrawn;
        if(directRefBonusPayout > 0){
            userData[_tokenID].directRefBonusBalanceWithdrawn += directRefBonusPayout;
        }
        uint256 poolRewardPayout = 0;

        uint256 accTokenPerShare = userData[_tokenID].vip ? vipPool.accTokenPerShare : userPool.accTokenPerShare;
        userData[_tokenID].pendingReward += userData[_tokenID].ePower * accTokenPerShare / e12 - userData[_tokenID].rewardDebt;
        userData[_tokenID].rewardDebt = userData[_tokenID].ePower * accTokenPerShare / e12;

        if(userData[_tokenID].pendingReward > 0){
            userData[_tokenID].totalRewarded += userData[_tokenID].pendingReward;
            poolRewardPayout = userData[_tokenID].pendingReward;
            userData[_tokenID].pendingReward = 0;
        }
        require (directRefBonusBalance >= directRefBonusPayout, "Ref bonus account balance low");
        directRefBonusBalance -= directRefBonusPayout;
        if(userData[_tokenID].vip){
            require(vipPool.totalAmountDistributed >= poolRewardPayout, "VIP Pool balance low");
            vipPool.totalAmountDistributed -= poolRewardPayout;
        }else{
            require(userPool.totalAmountDistributed >= poolRewardPayout, "User Pool balance low");
            userPool.totalAmountDistributed -= poolRewardPayout;
        }

        emit RewardClaimed (_tokenID, directRefBonusPayout, poolRewardPayout);
        //send remaining value of ETH back to user;
        if(directRefBonusPayout + poolRewardPayout > 0){
            address payable receiver = payable(msg.sender);
            receiver.transfer(directRefBonusPayout + poolRewardPayout);
        }
    }

    function claimCommissionPool() public override whenNotPaused() {
        require(msg.sender == commissionPoolDistributor, "Not an commission pool distributor");
        uint256 amount = commissionPoolBalance;
        commissionPoolBalance = 0;
        (bool success,) = commissionPoolDistributor.call{value: amount}("");
        require(success, "Distribution in external contract failed");
    }
    //***************** VIEW Functions ************************/

    function getUndestributedServiceContractBalance(address _serviceContract) public view returns(uint256){
        return undistributedServiceContractsBalance[_serviceContract];
    }

    function getServiceContractReferral(address _serviceContract) public view returns(uint256){
        return whitelistedServiceContracts[_serviceContract];
    }

    function currentPriceRegular(uint256 _parentTokenID) public view returns(uint256) {
        if(_exists(_parentTokenID))
            return _price(false) * 9 / 10;
        else
            return _price(false);
    }

    function currentPriceVIP(uint256 _parentTokenID) public view returns(uint256) {
        if(_exists(_parentTokenID))
            return _price(true) * 9 / 10;
        else
            return _price(true);
    }

    function getServicePrice(uint32 _index) public view returns(uint256){
        return servicePrices[_index];
    }

    function availableRewardForUser(address _user) public override view returns(uint256){
        return availableReward(tokenOfOwnerByIndex(_user,0));
    }

    function availableReward(uint256 _tokenID) public view returns(uint256){
        uint256 availablePoolReward = userData[_tokenID].pendingReward;
        uint256 accTokenPerShare = userData[_tokenID].vip ? vipPool.accTokenPerShare : userPool.accTokenPerShare;
        availablePoolReward += userData[_tokenID].ePower * accTokenPerShare / e12 - userData[_tokenID].rewardDebt;
        return availablePoolReward +
        (userData[_tokenID].directRefBonusBalance - userData[_tokenID].directRefBonusBalanceWithdrawn);
    }

    function getUserRefData(address user) public override view returns(bool, uint256, uint256, uint32, uint32, uint8, uint32, uint8, uint8, uint64, string memory){
        uint256 userTokenID = tokenOfOwnerByIndex(user,0);
        return(
            userData[userTokenID].vip,
            userTokenID ,//tokenID
            userData[userTokenID].parentTokenID,
            userData[userTokenID].ePower,
            userData[userTokenID].vPower,
            userData[userTokenID].refBonus,
            userData[userTokenID].refCount,
            userData[userTokenID].discount,
            userData[userTokenID].xFactor,
            userData[userTokenID].rank,
            userData[userTokenID].imageHash
        );
    }

    function getUserBonusData(address user) public view returns(uint256,uint256,uint256,uint256,uint256){
        uint256 userTokenID = tokenOfOwnerByIndex(user,0);
        uint256 accTokenPerShare = userData[userTokenID].vip ? vipPool.accTokenPerShare : userPool.accTokenPerShare;
        return(
            userTokenID ,//tokenID
            userData[userTokenID].directRefBonusBalance,
            userData[userTokenID].directRefBonusBalanceWithdrawn,
            userData[userTokenID].pendingReward + userData[userTokenID].ePower * accTokenPerShare / e12 - userData[userTokenID].rewardDebt, //claimable pool reward
            userData[userTokenID].totalRewarded
        );
    }

    function getUserPoolData(address user) public view returns(uint256, bool, uint256,uint256,uint256,uint256){
        uint256 userTokenID = tokenOfOwnerByIndex(user,0);
        uint256 accTokenPerShare = userData[userTokenID].vip ? vipPool.accTokenPerShare : userPool.accTokenPerShare;
        return(
            userTokenID ,//tokenID
            userData[userTokenID].vip,
            userData[userTokenID].pendingReward,
            userData[userTokenID].rewardDebt,
            userData[userTokenID].totalRewarded,
            userData[userTokenID].pendingReward + userData[userTokenID].ePower * accTokenPerShare / e12 - userData[userTokenID].rewardDebt //claimable pool reward
        );
    }

    function getPoolData(bool vip) public view returns(uint256, uint256, uint256){
        if(vip){
            return (vipPool.accTokenPerShare, vipPool.totalAmountDistributed, vipPool.totalDeposited);
        }
        else{
            return (userPool.accTokenPerShare, userPool.totalAmountDistributed, userPool.totalDeposited);
        }
    }

    function contractBalances() public view returns(uint256, uint256, uint256, uint256){
        return (directRefBonusBalance, userPool.totalAmountDistributed, vipPool.totalAmountDistributed, commissionPoolBalance);
    }

    function hasUser(address _user) public override view returns (bool, bool) {
        uint256 userTokenID = tokenOfOwnerByIndex(_user,0);
        return(userTokenID > 0, userTokenID > 0 ? userData[userTokenID].vip : false);
    }

    function tokenIDByUser(address owner) external view returns (uint256){
        if(balanceOf(owner) > 0){
            return tokenOfOwnerByIndex(owner,0);
        } else
            return 0;
    }
    //***************** INTERNAL Functions ************************/

    function _moveUserToVIPPool(uint256 _tokenID) private {
        require(!userData[_tokenID].vip, "Already VIP");
        //when user leaves userPool, his pending reward to be withdrawn. Withdrawing into directRefBonuses sub account
        userData[_tokenID].pendingReward += userData[_tokenID].ePower * userPool.accTokenPerShare / e12 - userData[_tokenID].rewardDebt;
        // userData[_tokenID].rewardDebt = userData[_tokenID].ePower * userPool.accTokenPerShare / e12; //this variable will change to the one from VIP pool

        if(userData[_tokenID].pendingReward > 0){
            userData[_tokenID].totalRewarded += userData[_tokenID].pendingReward;//?
            userData[_tokenID].directRefBonusBalance += userData[_tokenID].pendingReward;
            //moving money from userPool subAcct to directRefBonus subacct
            userPool.totalAmountDistributed -= userData[_tokenID].pendingReward;
            directRefBonusBalance += userData[_tokenID].pendingReward;
            //reset pendingReward
            userData[_tokenID].pendingReward = 0;
        }

        //remove from userPool
        // userData[_tokenID].ePower = userData[_tokenID].ePower > 800 ? userData[_tokenID].ePower : uint32(800); //should be 0 here.
        userPool.totalDeposited -= userData[_tokenID].ePower;
        //change userEPower to VIP
        userData[_tokenID].ePower = userData[_tokenID].ePower > 800 ? userData[_tokenID].ePower : uint32(800);
        //add to vipPool
        vipPool.totalDeposited += userData[_tokenID].ePower;
        userData[_tokenID].rewardDebt = userData[_tokenID].ePower * vipPool.accTokenPerShare / e12;
        //set VIP
        userData[_tokenID].vip = true;
        totalVIPs++;
    }

    function _random(uint256 _min, uint256 _max, string memory seed) private view returns(uint256){
        require (_min < _max, "Random: invalid params");
        uint256 base =  uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.coinbase, seed)));
        return _min + base % (_max - _min);
    }

    function _price(bool _vip) public view returns(uint256) {
        if(_vip){
            return cardPrices[1] + 10000000000000000 * totalVIPs;
        }else{
            return cardPrices[0];
        }

    }

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
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function _increaseEPower(uint256 _tokenID, uint32 ePowerIncrement) private {
        Pool storage _pool = userData[_tokenID].vip ? vipPool : userPool;
        userData[_tokenID].pendingReward += userData[_tokenID].ePower * _pool.accTokenPerShare / e12 - userData[_tokenID].rewardDebt;
        //deposit more ePower
        userData[_tokenID].ePower += ePowerIncrement;
        _pool.totalDeposited += ePowerIncrement;
        //record reward debt
        userData[_tokenID].rewardDebt = userData[_tokenID].ePower * _pool.accTokenPerShare / e12;
    }

    function _distributeServiceFee(uint256 requiredValue, uint256 _parentTokenID) private {
        // refBonus -> ParentTokenID.directRefBonusBalance (if exists)
        // 5% - ParentTokenID2.directRefBonusBalance (if exists)
        // 5% -> VIPPool;
        // 20% -> CommissionPool;
        // what's left -> userpool;

        //1. refBonus for Parent (layer 1)
        uint256 thisRefBonus = 0;
        if(_exists(_parentTokenID)){
            thisRefBonus = requiredValue*userData[_parentTokenID].refBonus/100;
            userData[_parentTokenID].directRefBonusBalance += thisRefBonus;
            //1.1. refBonus for Parent (layer 2)
            if(_exists(userData[_parentTokenID].parentTokenID) ){
                uint256 level2Bonus = requiredValue * settings[8] / 100;
                thisRefBonus += level2Bonus;
                userData[userData[_parentTokenID].parentTokenID].directRefBonusBalance += level2Bonus;
            }
        }
        directRefBonusBalance += thisRefBonus;

        //2. vipPoolBalance
        uint256 thisVipPoolBonus = requiredValue * settings[7] / 100;
        if(vipPool.totalDeposited>0){
            vipPool.accTokenPerShare += thisVipPoolBonus * e12 / vipPool.totalDeposited;
            vipPool.totalAmountDistributed += thisVipPoolBonus;
            // vipPoolBalance += thisVipPoolBonus;
        }
        else
            thisVipPoolBonus = 0;


        //3. commissionPoolBalance
        uint256 thisCommissionPoolBonus = requiredValue * settings[9] / 100;
        commissionPoolBalance += thisCommissionPoolBonus;

        //4. userPoolBalance
        uint256 thisUserPoolBonus = 0;
        if(thisVipPoolBonus+thisCommissionPoolBonus+thisRefBonus < requiredValue){
            thisUserPoolBonus = requiredValue - (thisVipPoolBonus + thisCommissionPoolBonus + thisRefBonus);
            if(userPool.totalDeposited>0) {
                userPool.accTokenPerShare += thisUserPoolBonus * e12 / userPool.totalDeposited;
                userPool.totalAmountDistributed += thisUserPoolBonus;
                // userPoolBalance += thisUserPoolBonus;
            }
            else
                thisUserPoolBonus = 0;
        }
        //event
        emit ServiceBonuses(_parentTokenID, requiredValue, thisRefBonus, thisUserPoolBonus, thisVipPoolBonus, thisCommissionPoolBonus);
    }


}