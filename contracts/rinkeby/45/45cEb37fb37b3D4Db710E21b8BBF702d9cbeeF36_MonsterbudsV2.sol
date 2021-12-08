// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address _newowner) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(_newowner);
    }

    function __Ownable_init_unchained(address _newowner) internal initializer {
        _setOwner(_newowner);
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
    function transferOwnership(address payable newOwner) public virtual onlyOwner {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

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
        require(owner != address(0), "ERC721: query for nonexistent token");
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

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal initializer {
    }
    using StringsUpgradeable for uint256;

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
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        if (AddressUpgradeable.isContract(signer)) {
            try IERC1271Upgradeable(signer).isValidSignature(hash, signature) returns (bytes4 magicValue) {
                return magicValue == IERC1271Upgradeable(signer).isValidSignature.selector;
            } catch {
                return false;
            }
        } else {
            return ECDSAUpgradeable.recover(hash, signature) == signer;
        }
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
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0 <0.8.12;

interface IMonsterBudsV2 {
    
    // Events Section 

    /**
     * @dev Emitted when new tokens are minted by user.
    */

    event TokenDetails(
        address owner,          // owner address of token 
        string[] tokenURI,      // newly created token uri's
        uint256[] tokenId,      // newly created token Id's
        uint256 totalValue       // total price to create them
    );

    /**
     * @dev Emitted when token is purchased by buyer.
    */

    event buyTransfer(
        address indexed sellerAddress,     // sender address
        address indexed buyerAddress,       // buyer address
        uint256 indexed tokenId,           // purchase token id
        uint256 price                      // price of token id
    );

    /**
     * @dev Emitted when new token is minted from two owned tokens.
    */

    event breedSelf(
        address indexed selfAddress,  // msg.sender address
        uint256 motherTokenId,        
        uint256 donorTokenId,
        string tokenURI,             // child seed uri 
        uint256 newTokenId,          // new minted child id 
        uint256 sktFeePrice          // fee to skt wallet 
    );

    /**
     * @dev Emitted when new tokens is minted by hybreed between owned and another users tokens.
    */

    event hybreed(
        address indexed requesterEthAddress,  // msg.sender address
        address indexed accepterEthAddress,   // wallet address of accepter
        uint256 motherTokenId,                // token id of msg.sender
        uint256 donorTokenId,                 // token id of accepter
        string tokenURI,                      // new minted child uri
        uint256 newTokenId,                   // new minted child id
        uint256 breedReqId,                   // breed request id
        uint256 sktFeePrice,                  // fee to skt wallet
        uint256 accepterFeePrice              // fee to accepter
    );

    /**
     * @dev Emitted when free token is minted by ppp user.
    */

    event FreeTokenDetails(
        uint256 parentTokenId,
        address owner,          // owner address of token 
        string tokenURI,      // newly created token uri
        uint256 tokenId,    // newly created token Id
        bool status
    );

    event ListTokenDetails(
        address owner,          // owner address of token 
        uint256 tokenId,
        uint256 tokenPrice,
        uint256 expiryTime
    );

    event DeListTokenDetails(
        address owner,          // owner address of token 
        uint256 tokenId
    );



    /**
     * @dev mints the ERC721 NFT tokens.
     * 
     * Returns
     * - array of newly token counts.
     *
     * Emits a {TokenDetails} event.
    */
    
    function createCollectible(uint256 quantity) external payable returns (uint256[] memory);

    /**
     * @dev user can create new ERC721 token by hybriding with another token.
     *
     * Returns
     * - new token count.
     *
     * Emits a {hybreed} event.
    */

    function hybreedCollectiable( uint256 req_token_id, uint256 accept_token_id, uint256 breed_req_id) external payable returns (uint256);

    /**
     * @dev free mint for ppp users.
     *
     * Returns
     * - new token count.
     *
     * Emits a {FreeTokenDetails} event.
    */
    function freeMint() external returns(uint256);

    //function createPPPcollectible() external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract MonsterBudHolders is OwnableUpgradeable{
    
    // mapping of ppp address with their status
    mapping(address => bool) public holders;

    /**
     * @dev Emitted when `ppp user address` status is set to true.
    */
    event AddHolder(address pppUser, bool status);

    /**
     * @dev adds 484 ppp users at one time.
     * @param _pppUser array of address to be added.
     * @param _status status in boolean.
     *
     * Requirements
     * - array must have 484 address.
     * - only owner must call this method.
     *
     * Emits a {AddHolder} event.
    */
    
    function addPPPUserStatus(address[484] calldata _pppUser, bool _status) onlyOwner external {
        for(uint i = 0; i < 484; i++){
            holders[_pppUser[i]] = _status;
            emit AddHolder(_pppUser[i], _status);        
        }
    }

    /**
     * @dev checks where user address can use free mint.
     * @param _pppUser user address.
     *
     * Returns
     * - status in boolean.
    */

    function checkPPPUser(address _pppUser) external view returns(bool){
        require(_pppUser != address(0x00), "$MONSTERBUDS: zero address can not be ppp user");
        return holders[_pppUser];
    }

    /**
     * @dev It destroy the contract and returns all balance of this contract to owner.
     *
     * Returns
     * - only owner can call this method.
    */ 

    function selfDestruct() 
        public 
        onlyOwner{
    
        payable(owner()).transfer(address(this).balance);
        //selfdestruct(payable(address(this)));
    }

    /**
     * @dev It destroy the contract and returns all balance of this contract to owner.
     *
     * Returns
     * - only owner can call this method.
    */ 

    function ERC20tokensWithdraw()
        public
        onlyOwner{

    }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./MonsterBudHolders.sol";
import "./IMonsterBudsV2.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";


/**
 * @dev Implementation of the {IMonsterBuds} interface.
 * This Contract states the 
 * 
 */

contract MonsterbudsV2 is MonsterBudHolders, ERC721URIStorageUpgradeable, IMonsterBudsV2 {
    using StringsUpgradeable for uint256;
    
    // token count
    uint256 private tokenCounter;

    // percentage denominator
    uint private percentDeno;

    // percent of fees
    uint private feeMargin;
    
    // new Item count
    uint256 private newItemId;

    // SKT Wallet address
    address private feeSKTWallet;

    // smartcontract community address
    address private SmartContractCommunity;

    // array of token ids
    uint256[] private tokenIds;

    // array of token URI's
    string[] private tokenUris;

    // token price
    uint private tokenValue;

    // breed price
    uint private breedValue; 

    // token URI
    string private beforeUri;

    string private afterUri;

    // status where buy should be allowed or not
    bool buyONorOFFstatus;

    // mapping of token Id with their prices
    mapping(uint256 => uint256) public listPrices;


    // status where self breed should be allowed or not
    bool selfBreedStatus;

    // status where hybrid should be allowed or not
    bool hybridStatus;

    struct breedInfomation{
        address user;
        uint breedCount;
        uint256 timstamp;
    }

    struct breedInfomation1{
        uint256 tokenId;
        uint breedCount;
        uint256 timstamp;
    }

    mapping (address => breedInfomation) public breedInfo;
    mapping (uint256 => breedInfomation1) public breedingInfo;

       // mapping of ppp address with their status
    mapping(uint256 => bool) public pppMintStatus;

    mapping (address => mapping(uint256 => uint256)) public tokenListing;

    struct tokenListDetails{
        uint256 tokenId;
        uint256 price;
        uint256 expiryTime;
    }

    struct tokenListDetailss{
        uint256 tokenId;
        address listedOwner;
        uint256 price;
        uint256 expiryTime;
    }


    mapping(uint256 => tokenListDetails) public tokenListInfo;

    mapping(uint256 => tokenListDetailss) public tokenListInformation;

    struct Order{
        address buyer;
        address owner; 
        uint256 token_id;
        string tokenUri;
        uint256 expiryTimestamp;
        uint256 price;
        bytes32 signKey;
        bytes32 signature;
    }

    struct PurchaseOrder{
        uint256 token_id;
        uint256 expiryTimestamp;
        uint256 price;
        bytes32 signKey;
        bytes32 signature;
    }

    struct SelfBreed{
        uint256 req_token_id;
        uint256 accept_token_id;
        bytes32 signKey;
    }


    //bytes32
    // functions Sections

    /**
     * @dev calculates the 5 percent fees
    */

    function feeCalulation(uint256 _totalPrice) private view returns (uint256) {
        uint256 fee = feeMargin * _totalPrice;
        uint256 fees = fee / percentDeno;
        return fees;
    }

    /**
     * @dev sets the token listing.
    */

    // function list(uint256 token_id, uint256 price, uint256 expiry_time) external returns(uint256){
    //    require(ownerOf(token_id) == msg.sender, "$MONSTERBUDS: You are not owner of token");
    //    if(tokenListInformation[token_id].listedOwner == msg.sender){
    //        require(tokenListInformation[token_id].expiryTime <= block.timestamp, "$MONSTERBUDS: Already listed");
    //    }
    //    tokenListDetailss storage data = tokenListInformation[token_id];
    //    data.tokenId = token_id;
    //    data.listedOwner = msg.sender;
    //    data.price = price;
    //    data.expiryTime = expiry_time;

    //    emit ListTokenDetails(ownerOf(token_id), token_id, price, expiry_time);
    //    return price;  
    // }

    // function delist(uint256 token_id) external{        

    //    require(ownerOf(token_id) == msg.sender, "$MONSTERBUDS: You are not owner of token");
    //    require(tokenListInformation[token_id].tokenId != 0, "$MONSTERBUDS: token is not listed");
    //    delete tokenListInformation[token_id];
    //    emit DeListTokenDetails(ownerOf(token_id), token_id);
    // }

    /**
     * @dev sets the status of Buy Tokens function.
    */

    function updateBuyStatus(bool _status) external onlyOwner returns (bool){
        buyONorOFFstatus = _status;
        return buyONorOFFstatus;
    }

    /**
     * @dev sets the status of self breed Tokens function.
    */

    function updateSelfBreedStatus(bool _status) external onlyOwner returns (bool){
        selfBreedStatus = _status;
        return selfBreedStatus;
    }

    /**
     * @dev sets the status of hybrid Tokens function.
    */

    function updateHybridStatus(bool _status) external onlyOwner returns (bool){
        hybridStatus = _status;
        return hybridStatus;
    }

    /**
     * @dev concates the two string and token id to create new URI. 
          *
     * @param _before token uri before part.
     * @param _after token uri after part.
     * @param _token_id token Id.
     *
     * Returns
     * - token uri
    */

    function uriConcate(string memory _before, uint256 _token_id, string memory _after) private pure returns (string memory){
        string memory token_uri = string( abi.encodePacked(_before, _token_id.toString(), _after));
        return token_uri;
    }

    /**
     * @dev updates the token price(in ETH)
     *  
     * @param _ethValue updated ETH price of token minting.
     *
     * Requirements:
     * - `_ethValue` must be pass.
     * - only owner can update value.
    */

    function updateTokenMintRate(uint256 _ethValue) external onlyOwner returns (uint256){
        tokenValue = _ethValue; // update the eth value of token
        return tokenValue;
    }

    /**
     * @dev updates the percent denominator. 
     * For the fee margin in points the denominator should be increased
     *  
     * @param _no denominator(100, 1000, 10000)
     * Requirements:
     * - only owner can update value.
    */

    function updatepercentDenominator(uint256 _no) external onlyOwner returns (uint256){
        percentDeno = _no; // update the eth value of token
        return percentDeno;
    }

    /**
     * @dev updates the token URI. 
     *
     * @param tokenId token Id.
     * @param token_uri token uri.
     *
     * Requirements:
     * - only owner can update ant token URI.
    */

    function updateTokenUri(uint256 tokenId, string memory token_uri) external onlyOwner returns (bool){
        _setTokenURI(tokenId, token_uri); // update the uri of token
        return true;
    } 

    /**
     * @dev updates the breed price(in ETH). 
     *
     * @param _ethValue updated ETH price of breeding.
     *  
     * Requirements:
     * - only owner can update value.
    */

    function updateBreedValue(uint256 _ethValue) external onlyOwner returns (uint256){
        breedValue = _ethValue; // update the eth value of breed value
        return breedValue;
    }

    /**
     * @dev updates the default Token URI. 
     *
     * @param _before token uri before part.
     * @param _after token uri after part.
     *
     * Requirements:
     * - only owner can update default URI.
    */

    function updateDefaultUri(string memory _before, string memory _after) external onlyOwner returns (bool){
        beforeUri = _before; // update the before uri for SKT
        afterUri = _after; // update the after uri for SKT
        return true;
    }

    /**
     * @dev updates the SKT Wallet Address. 
     * 
     * @param nextOwner updated SKT wallet address.
     *  
     * Requirements:
     * - only owner can update value.
     * - `nextOwner` cannot be zero address.
    */

    function updateFeeSKTWallet(address payable nextOwner) external onlyOwner returns (address){
        require(nextOwner != address(0x00), "$MONSTERBUDS: cannot be zero address");
        feeSKTWallet = nextOwner; // update the fee wallet for SKT
        return feeSKTWallet;
    }

    /**
     * @dev updates the SmartContract Community Wallet Address.
     * 
     * @param nextOwner updated smart contract community wallet address.
     *  
     * Requirements:
     * - only owner can update value.
     * - `nextOwner` must not be zero address.
    */

    function updateSKTCommunityWallet(address payable nextOwner) external onlyOwner returns (address){
        require(nextOwner != address(0x00), "$MONSTERBUDS: cannot be zero address");
        SmartContractCommunity = nextOwner; // update commuinty wallet
        return SmartContractCommunity;
    }

    /**
     * @dev updates the percent of fees. 
     * - `nextFeeMargin` must be pass.
     *  
     * Requirements:
     * - only owner can update value.
    */

    function updateFeeMargin(uint256 nextMargin) external onlyOwner returns (uint256){
        feeMargin = nextMargin; // update fee percent
        return feeMargin;
    }

    /**
     * @dev mints the ERC721 NFT tokens.
     *
     * @param quantity number of tokens that to be minted.
     *  
     * Requirements:
     * - `quantity` must be from 1 to 28.
     * - ETH amount must be quantity * token price.
     * 
     * Returns
     * - array of newly token counts.
     *
     * Emits a {TokenDetails} event.
    */

    function createCollectible(uint quantity) external payable override returns (uint256[] memory){

        uint256 totalAmount = (tokenValue * quantity); // total amount
        uint256 count = tokenCounter + (quantity-1);
        require(count <= 10420, "$MONSTERBUDS: Total supply has reached");
        require(quantity <= 28 && totalAmount == msg.value, "$MONSTERBUDS: Cannot mint more than max buds or price is incorrect");
        delete tokenIds; // delete the privious tokenIDs array
        delete tokenUris;
        string memory _uri;

        for (uint i = 0; i < quantity; i++) {
            // loop to mint no of seeds
            newItemId = tokenCounter;
            _uri = uriConcate(beforeUri, newItemId, afterUri);
            _safeMint(msg.sender, newItemId); // mint new seed
            _setTokenURI(newItemId, _uri); // set uri to new seed
            breedInfomation1 storage new_data = breedingInfo[newItemId];
            new_data.tokenId = newItemId;
            new_data.breedCount = 0;
            new_data.timstamp = block.timestamp + 1200;
            tokenIds.push(newItemId);
            tokenUris.push(_uri);
            tokenCounter = tokenCounter + 1;
        }

        payable(owner()).transfer(msg.value); // transfer the ethers to smart contract owner

        emit TokenDetails(msg.sender, tokenUris, tokenIds, msg.value);

        return tokenIds;
    }


    /**
     * @dev user can create new ERC721 token by hybriding with another token.
     * 
     * @param req_token_id token Id of msg.sender.
     * @param accept_token_id token Id of accepter address.
     * @param breed_req_id request Id send by msg.sender to accepter.
     *
     * Returns
     * - new token count.
     *
     * Emits a {hybreed} event.
    */

    function hybreedCollectiable( uint256 req_token_id,uint256 accept_token_id, uint256 breed_req_id) external override payable returns (uint256) {
        address payable accepter_token_address = payable(ownerOf(accept_token_id));
        address owner_req = (ownerOf(req_token_id));

        //require(hybridStatus == true && block.timestamp >= breedInfo[req_token_id].timstamp && block.timestamp >= breedInfo[accept_token_id].timstamp, "$MONSTERBUDS: Breeding is closed");
        require(accepter_token_address != msg.sender && owner_req == msg.sender, "$MONSTERBUDS: can not hybrid");

        uint256 breedFee = breedValue * 2; // 0.008 Eth breed Value * 2
        require(breedFee == msg.value, "$MONSTERBUDS: Amount is incorrect");

        newItemId = tokenCounter;
        string memory seed_token_uri = uriConcate(beforeUri, newItemId, afterUri);

        _safeMint(msg.sender, newItemId); // mint child seed
        _setTokenURI(newItemId, seed_token_uri); // set token uri for child seed

        accepter_token_address.transfer(breedValue); // send 0.008 to accepter address
        payable(feeSKTWallet).transfer(breedValue);
        // send 0.008 to skt fee wallet
        emit hybreed(
            msg.sender,
            accepter_token_address,
            req_token_id,
            accept_token_id,
            seed_token_uri,
            newItemId,
            breed_req_id,
            breedValue,
            breedValue
        );

        return newItemId;
    }

    /**
     * @dev user can create new ERC721 token by self breeding with owned two tokens.
     * 
     * @param breed struct for breeding info.
     * @param signature verify.
     *
     * Returns
     * - new token count.
     *
     * Emits a {breedSelf} event.
    */

    function selfBreedCollectiable(SelfBreed calldata breed, bytes calldata signature) external payable returns (uint256) {
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(owner(), breed.signKey, signature);
        require(status == true, "$MONSTERBUDS: cannot breed[ERROR]");
        require(breedValue == msg.value, "$MONSTERBUDS: Amount is incorrect");
        require(breed.req_token_id >= 10 && breed.accept_token_id >= 10, "$MONSTERBUDS: PPP Monsters cannot breed");  // 865
        
        address owner_req = (ownerOf(breed.req_token_id));
        address owner_accept = (ownerOf(breed.accept_token_id));

        require(selfBreedStatus == true,"$MONSTERBUDS: Breeding is closed");
        require(owner_req == owner_accept && owner_req == msg.sender && breed.req_token_id != breed.accept_token_id, "$MONSTERBUDS: Cannot Self Breed");
        require(breedingInfo[breed.req_token_id].breedCount < 2 && breedingInfo[breed.accept_token_id].breedCount < 2, "$MONSTERBUDS: Exceeds max breed count");
        require(block.timestamp >= breedingInfo[breed.req_token_id].timstamp && block.timestamp >= breedingInfo[breed.accept_token_id].timstamp,"$MONSTERBUDS: cannot breed now");
       

        newItemId = tokenCounter;
        string memory seed_token_uri = uriConcate(beforeUri, newItemId, afterUri);

        _safeMint(msg.sender, newItemId); // mint new child seed
        _setTokenURI(newItemId, seed_token_uri); // set child uri
        uint countOfReq = breedingInfo[breed.req_token_id].breedCount;
        uint countOfAccept = breedingInfo[breed.accept_token_id].breedCount;

        breedInfomation1 storage new_data = breedingInfo[newItemId];
        new_data.tokenId = newItemId;
        new_data.breedCount = 0;
        new_data.timstamp = block.timestamp + 1200;

        tokenCounter = tokenCounter + 1;
        breedInfomation1 storage req_data = breedingInfo[breed.req_token_id];
        req_data.tokenId = breed.req_token_id;
        req_data.breedCount = countOfReq + 1;
        req_data.timstamp = block.timestamp + 300;

        breedInfomation1 storage accept_data = breedingInfo[breed.accept_token_id];
        accept_data.tokenId = breed.accept_token_id;
        accept_data.breedCount = countOfAccept + 1;
        accept_data.timstamp = block.timestamp + 300;
    

        payable(feeSKTWallet).transfer(msg.value); // send 0.008 to skt fee wallet

        emit breedSelf(
            msg.sender,
            breed.req_token_id,
            breed.accept_token_id,
            seed_token_uri,
            newItemId,
            msg.value
        );

        return newItemId;
    }


    /**
     * @dev free mint for ppp users.
     *
     * Requirements
     * - user address must be ppp user.
     * - user address must not be zero address.
     *
     * Returns
     * - new token count.
     *
     * Emits a {FreeTokenDetails} event.
    */

    function freeMint() external override returns(uint256) {
        require(holders[msg.sender] == true, "$MONSTERBUDS: Not PPP User");
        string memory _uri;
        holders[msg.sender] = false;
        newItemId = tokenCounter;
        string memory before_ = "https://s3.amazonaws.com/assets.monsterbuds.io/Monster-Uri/PPP_Ticket_";
        string memory after_ = ".json";
        _uri = uriConcate(before_, newItemId, after_);
        _safeMint(msg.sender, newItemId); // mint new seed
        _setTokenURI(newItemId, _uri); // set uri to new seed
        tokenCounter = tokenCounter + 1;

        emit FreeTokenDetails(0, msg.sender, _uri, newItemId, false);

        return newItemId;
    }


    function createPPPCollectiable(uint256 _tokenId) external returns (uint256){
        require(_tokenId <= 260 && ownerOf(_tokenId) == msg.sender ,"$MONSTERBUDS: Not a PPP token or owner of PPP token");
        require(pppMintStatus[_tokenId] == false, "$MONSTERBUDS: Token is already minted by selected PPP token ID");

        newItemId = tokenCounter;
        string memory token_uri = uriConcate(beforeUri, newItemId, afterUri);
        _safeMint(msg.sender, newItemId); // mint child seed
        _setTokenURI(newItemId, token_uri); // set token uri for child seed
        breedInfomation1 storage new_data = breedingInfo[newItemId];
        new_data.tokenId = newItemId;
        new_data.breedCount = 0;
        new_data.timstamp = block.timestamp + 1200;

        tokenCounter = tokenCounter + 1;
        pppMintStatus[_tokenId] = true;

        emit FreeTokenDetails(_tokenId, msg.sender, token_uri, newItemId, true);
        return newItemId;

    }

    function orderCheck(Order memory order) private returns(bool){
        address payable owner = payable(ownerOf(order.token_id));
        bytes32 hashS = keccak256(abi.encodePacked(msg.sender));
        bytes32 hashR = keccak256(abi.encodePacked(owner));
        bytes32 hashT = keccak256(abi.encodePacked(order.price));
        bytes32 hashV = keccak256(abi.encodePacked(order.token_id));
        bytes32 hashP = keccak256(abi.encodePacked(order.expiryTimestamp));
        bytes32 sign  = keccak256(abi.encodePacked(hashV, hashP, hashT, hashR, hashS));

        require(order.expiryTimestamp >= block.timestamp, "MONSTERBUDS: expired time");
        require(sign == order.signKey, "$MONSTERBUDS: ERROR");
        require(order.price == msg.value, "MONSTERBUDS: Price is incorrect");

        uint256 feeAmount = feeCalulation(msg.value);
        payable(feeSKTWallet).transfer(feeAmount); // transfer 5% ethers of msg.value to skt fee wallet
        payable(SmartContractCommunity).transfer(feeAmount); // transfer 5% ethers of msg.value to commuinty

        uint256 remainAmount = msg.value - (feeAmount + feeAmount);
        payable(order.owner).transfer(remainAmount); // transfer remaining 90% ethers of msg.value to owner of token
        _transfer(order.owner, msg.sender, order.token_id); // transfer the ownership of token to buyer

        emit buyTransfer(order.owner, msg.sender, order.token_id, msg.value);
        return true;
    }

    function purchase(Order memory order, bytes memory signature) external payable returns(bool){

        require(buyONorOFFstatus == true, "$MONSTERBUDS: Marketplace for buying is closed");
        orderCheck(order);
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(owner(), order.signature, signature);
        require(status == true, "$MONSTERBUDS: cannot purchase the token");
        return true;
    }

    function orderCheck1(PurchaseOrder memory order) private returns(bool){
        address payable owner = payable(ownerOf(order.token_id));
        bytes32 sign  = keccak256(abi.encodePacked(order.price, order.token_id));

        require(order.expiryTimestamp >= block.timestamp, "MONSTERBUDS: expired time");
        require(sign == order.signKey, "$MONSTERBUDS: ERROR");
        require(order.price == msg.value, "MONSTERBUDS: Price is incorrect");
        require(owner != msg.sender, "MONSTERBUDS: Cannot buy owned token");

        uint256 feeAmount = feeCalulation(msg.value);
        payable(feeSKTWallet).transfer(feeAmount); // transfer 5% ethers of msg.value to skt fee wallet
        payable(SmartContractCommunity).transfer(feeAmount); // transfer 5% ethers of msg.value to commuinty

        uint256 remainAmount = msg.value - (feeAmount + feeAmount);
        payable(owner).transfer(remainAmount); // transfer remaining 90% ethers of msg.value to owner of token
        _transfer(owner, msg.sender, order.token_id); // transfer the ownership of token to buyer

        emit buyTransfer(owner, msg.sender, order.token_id, msg.value);
        return true;
    }

   function purchaseCollectible(PurchaseOrder memory order, bytes memory signature) external payable returns(bool){

        require(buyONorOFFstatus == true, "$MONSTERBUDS: Marketplace for buying is closed");
        orderCheck1(order);
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(owner(), order.signature, signature);
        require(status == true, "$MONSTERBUDS: cannot purchase the token");
        return true;
    }

}