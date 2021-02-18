// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {IFactory} from "../factory/IFactory.sol";
import {IInstanceRegistry} from "../factory/InstanceRegistry.sol";
import {ProxyFactory} from "../factory/ProxyFactory.sol";

import {IUniversalVault} from "./Crucible.sol";

/// @title CrucibleFactory
contract CrucibleFactory is IFactory, IInstanceRegistry, ERC721 {
    address private immutable _template;

    constructor(address template) ERC721("Alchemist Crucible v1", "CRUCIBLE-V1") {
        require(template != address(0), "CrucibleFactory: invalid template");
        _template = template;
    }

    /* registry functions */

    function isInstance(address instance) external view override returns (bool validity) {
        return ERC721._exists(uint256(instance));
    }

    function instanceCount() external view override returns (uint256 count) {
        return ERC721.totalSupply();
    }

    function instanceAt(uint256 index) external view override returns (address instance) {
        return address(ERC721.tokenByIndex(index));
    }

    /* factory functions */

    function create(bytes calldata) external override returns (address vault) {
        return create();
    }

    function create2(bytes calldata, bytes32 salt) external override returns (address vault) {
        return create2(salt);
    }

    function create() public returns (address vault) {
        // create clone and initialize
        vault = ProxyFactory._create(
            _template,
            abi.encodeWithSelector(IUniversalVault.initialize.selector)
        );

        // mint nft to caller
        ERC721._safeMint(msg.sender, uint256(vault));

        // emit event
        emit InstanceAdded(vault);

        // explicit return
        return vault;
    }

    function create2(bytes32 salt) public returns (address vault) {
        // create clone and initialize
        vault = ProxyFactory._create2(
            _template,
            abi.encodeWithSelector(IUniversalVault.initialize.selector),
            salt
        );

        // mint nft to caller
        ERC721._safeMint(msg.sender, uint256(vault));

        // emit event
        emit InstanceAdded(vault);

        // explicit return
        return vault;
    }

    /* getter functions */

    function getTemplate() external view returns (address template) {
        return _template;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
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
        return _tokenOwners.contains(tokenId);
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
     d*
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

interface IFactory {
    function create(bytes calldata args) external returns (address instance);

    function create2(bytes calldata args, bytes32 salt) external returns (address instance);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface IInstanceRegistry {
    /* events */

    event InstanceAdded(address instance);
    event InstanceRemoved(address instance);

    /* view functions */

    function isInstance(address instance) external view returns (bool validity);

    function instanceCount() external view returns (uint256 count);

    function instanceAt(uint256 index) external view returns (address instance);
}

/// @title InstanceRegistry
contract InstanceRegistry is IInstanceRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* storage */

    EnumerableSet.AddressSet private _instanceSet;

    /* view functions */

    function isInstance(address instance) external view override returns (bool validity) {
        return _instanceSet.contains(instance);
    }

    function instanceCount() external view override returns (uint256 count) {
        return _instanceSet.length();
    }

    function instanceAt(uint256 index) external view override returns (address instance) {
        return _instanceSet.at(index);
    }

    /* admin functions */

    function _register(address instance) internal {
        require(_instanceSet.add(instance), "InstanceRegistry: already registered");
        emit InstanceAdded(instance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

library ProxyFactory {
    /* functions */

    function _create(address logic, bytes memory data) internal returns (address proxy) {
        // deploy clone
        proxy = Clones.clone(logic);

        // attempt initialization
        if (data.length > 0) {
            (bool success, bytes memory err) = proxy.call(data);
            require(success, string(err));
        }

        // explicit return
        return proxy;
    }

    function _create2(
        address logic,
        bytes memory data,
        bytes32 salt
    ) internal returns (address proxy) {
        // deploy clone
        proxy = Clones.cloneDeterministic(logic, salt);

        // attempt initialization
        if (data.length > 0) {
            (bool success, bytes memory err) = proxy.call(data);
            require(success, string(err));
        }

        // explicit return
        return proxy;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import {EIP712} from "./EIP712.sol";
import {ERC1271} from "./ERC1271.sol";
import {OwnableERC721} from "./OwnableERC721.sol";
import {IRageQuit} from "../aludel/Aludel.sol";

interface IUniversalVault {
    /* user events */

    event Locked(address delegate, address token, uint256 amount);
    event Unlocked(address delegate, address token, uint256 amount);
    event RageQuit(address delegate, address token, bool notified, string reason);

    /* data types */

    struct LockData {
        address delegate;
        address token;
        uint256 balance;
    }

    /* initialize function */

    function initialize() external;

    /* user functions */

    function lock(
        address token,
        uint256 amount,
        bytes calldata permission
    ) external;

    function unlock(
        address token,
        uint256 amount,
        bytes calldata permission
    ) external;

    function rageQuit(address delegate, address token)
        external
        returns (bool notified, string memory error);

    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function transferETH(address to, uint256 amount) external payable;

    /* pure functions */

    function calculateLockID(address delegate, address token)
        external
        pure
        returns (bytes32 lockID);

    /* getter functions */

    function getPermissionHash(
        bytes32 eip712TypeHash,
        address delegate,
        address token,
        uint256 amount,
        uint256 nonce
    ) external view returns (bytes32 permissionHash);

    function getNonce() external view returns (uint256 nonce);

    function owner() external view returns (address ownerAddress);

    function getLockSetCount() external view returns (uint256 count);

    function getLockAt(uint256 index) external view returns (LockData memory lockData);

    function getBalanceDelegated(address token, address delegate)
        external
        view
        returns (uint256 balance);

    function getBalanceLocked(address token) external view returns (uint256 balance);

    function checkBalances() external view returns (bool validity);
}

/// @title Crucible
/// @notice Vault for isolated storage of staking tokens
/// @dev Warning: not compatible with rebasing tokens
contract Crucible is
    IUniversalVault,
    EIP712("UniversalVault", "1.0.0"),
    ERC1271,
    OwnableERC721,
    Initializable
{
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /* constant */

    // Hardcoding a gas limit for rageQuit() is required to prevent gas DOS attacks
    // the gas requirement cannot be determined at runtime by querying the delegate
    // as it could potentially be manipulated by a malicious delegate who could force
    // the calls to revert.
    // The gas limit could alternatively be set upon vault initialization or creation
    // of a lock, but the gas consumption trade-offs are not favorable.
    // Ultimately, to avoid a need for fixed gas limits, the EVM would need to provide
    // an error code that allows for reliably catching out-of-gas errors on remote calls.
    uint256 public constant RAGEQUIT_GAS = 500000;
    bytes32 public constant LOCK_TYPEHASH =
        keccak256("Lock(address delegate,address token,uint256 amount,uint256 nonce)");
    bytes32 public constant UNLOCK_TYPEHASH =
        keccak256("Unlock(address delegate,address token,uint256 amount,uint256 nonce)");

    /* storage */

    uint256 private _nonce;
    mapping(bytes32 => LockData) private _locks;
    EnumerableSet.Bytes32Set private _lockSet;

    /* initialization function */

    function initializeLock() external initializer {}

    function initialize() external override initializer {
        OwnableERC721._setNFT(msg.sender);
    }

    /* ether receive */

    receive() external payable {}

    /* internal overrides */

    function _getOwner() internal view override(ERC1271) returns (address ownerAddress) {
        return OwnableERC721.owner();
    }

    /* pure functions */

    function calculateLockID(address delegate, address token)
        public
        pure
        override
        returns (bytes32 lockID)
    {
        return keccak256(abi.encodePacked(delegate, token));
    }

    /* getter functions */

    function getPermissionHash(
        bytes32 eip712TypeHash,
        address delegate,
        address token,
        uint256 amount,
        uint256 nonce
    ) public view override returns (bytes32 permissionHash) {
        return
            EIP712._hashTypedDataV4(
                keccak256(abi.encode(eip712TypeHash, delegate, token, amount, nonce))
            );
    }

    function getNonce() external view override returns (uint256 nonce) {
        return _nonce;
    }

    function owner()
        public
        view
        override(IUniversalVault, OwnableERC721)
        returns (address ownerAddress)
    {
        return OwnableERC721.owner();
    }

    function getLockSetCount() external view override returns (uint256 count) {
        return _lockSet.length();
    }

    function getLockAt(uint256 index) external view override returns (LockData memory lockData) {
        return _locks[_lockSet.at(index)];
    }

    function getBalanceDelegated(address token, address delegate)
        external
        view
        override
        returns (uint256 balance)
    {
        return _locks[calculateLockID(delegate, token)].balance;
    }

    function getBalanceLocked(address token) public view override returns (uint256 balance) {
        uint256 count = _lockSet.length();
        for (uint256 index; index < count; index++) {
            LockData storage _lockData = _locks[_lockSet.at(index)];
            if (_lockData.token == token && _lockData.balance > balance)
                balance = _lockData.balance;
        }
        return balance;
    }

    function checkBalances() external view override returns (bool validity) {
        // iterate over all token locks and validate sufficient balance
        uint256 count = _lockSet.length();
        for (uint256 index; index < count; index++) {
            // fetch storage lock reference
            LockData storage _lockData = _locks[_lockSet.at(index)];
            // if insufficient balance and no∏t shutdown, return false
            if (IERC20(_lockData.token).balanceOf(address(this)) < _lockData.balance) return false;
        }
        // if sufficient balance or shutdown, return true
        return true;
    }

    /* user functions */

    /// @notice Lock ERC20 tokens in the vault
    /// access control: called by delegate with signed permission from owner
    /// state machine: anytime
    /// state scope:
    /// - insert or update _locks
    /// - increase _nonce
    /// token transfer: none
    /// @param token Address of token being locked
    /// @param amount Amount of tokens being locked
    /// @param permission Permission signature payload
    function lock(
        address token,
        uint256 amount,
        bytes calldata permission
    )
        external
        override
        onlyValidSignature(
            getPermissionHash(LOCK_TYPEHASH, msg.sender, token, amount, _nonce),
            permission
        )
    {
        // get lock id
        bytes32 lockID = calculateLockID(msg.sender, token);

        // add lock to storage
        if (_lockSet.contains(lockID)) {
            // if lock already exists, increase amount
            _locks[lockID].balance = _locks[lockID].balance.add(amount);
        } else {
            // if does not exist, create new lock
            // add lock to set
            assert(_lockSet.add(lockID));
            // add lock data to storage
            _locks[lockID] = LockData(msg.sender, token, amount);
        }

        // validate sufficient balance
        require(
            IERC20(token).balanceOf(address(this)) >= _locks[lockID].balance,
            "UniversalVault: insufficient balance"
        );

        // increase nonce
        _nonce += 1;

        // emit event
        emit Locked(msg.sender, token, amount);
    }

    /// @notice Unlock ERC20 tokens in the vault
    /// access control: called by delegate with signed permission from owner
    /// state machine: after valid lock from delegate
    /// state scope:
    /// - remove or update _locks
    /// - increase _nonce
    /// token transfer: none
    /// @param token Address of token being unlocked
    /// @param amount Amount of tokens being unlocked
    /// @param permission Permission signature payload
    function unlock(
        address token,
        uint256 amount,
        bytes calldata permission
    )
        external
        override
        onlyValidSignature(
            getPermissionHash(UNLOCK_TYPEHASH, msg.sender, token, amount, _nonce),
            permission
        )
    {
        // get lock id
        bytes32 lockID = calculateLockID(msg.sender, token);

        // validate existing lock
        require(_lockSet.contains(lockID), "UniversalVault: missing lock");

        // update lock data
        if (_locks[lockID].balance > amount) {
            // substract amount from lock balance
            _locks[lockID].balance = _locks[lockID].balance.sub(amount);
        } else {
            // delete lock data
            delete _locks[lockID];
            assert(_lockSet.remove(lockID));
        }

        // increase nonce
        _nonce += 1;

        // emit event
        emit Unlocked(msg.sender, token, amount);
    }

    /// @notice Forcibly cancel delegate lock
    /// @dev This function will attempt to notify the delegate of the rage quit using
    ///      a fixed amount of gas.
    /// access control: only owner
    /// state machine: after valid lock from delegate
    /// state scope:
    /// - remove item from _locks
    /// token transfer: none
    /// @param delegate Address of delegate
    /// @param token Address of token being unlocked
    function rageQuit(address delegate, address token)
        external
        override
        onlyOwner
        returns (bool notified, string memory error)
    {
        // get lock id
        bytes32 lockID = calculateLockID(delegate, token);

        // validate existing lock
        require(_lockSet.contains(lockID), "UniversalVault: missing lock");

        // attempt to notify delegate
        if (delegate.isContract()) {
            // check for sufficient gas
            require(gasleft() >= RAGEQUIT_GAS, "UniversalVault: insufficient gas");

            // attempt rageQuit notification
            try IRageQuit(delegate).rageQuit{gas: RAGEQUIT_GAS}() {
                notified = true;
            } catch Error(string memory res) {
                notified = false;
                error = res;
            } catch (bytes memory) {
                notified = false;
            }
        }

        // update lock storage
        assert(_lockSet.remove(lockID));
        delete _locks[lockID];

        // emit event
        emit RageQuit(delegate, token, notified, error);
    }

    /// @notice Transfer ERC20 tokens out of vault
    /// access control: only owner
    /// state machine: when balance >= max(lock) + amount
    /// state scope: none
    /// token transfer: transfer any token
    /// @param token Address of token being transferred
    /// @param to Address of the recipient
    /// @param amount Amount of tokens to transfer
    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwner {
        // check for sufficient balance
        require(
            IERC20(token).balanceOf(address(this)) >= getBalanceLocked(token).add(amount),
            "UniversalVault: insufficient balance"
        );
        // perform transfer
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @notice Transfer ERC20 tokens out of vault
    /// access control: only owner
    /// state machine: when balance >= amount
    /// state scope: none
    /// token transfer: transfer any token
    /// @param to Address of the recipient
    /// @param amount Amount of ETH to transfer
    function transferETH(address to, uint256 amount) external payable override onlyOwner {
        // perform transfer
        TransferHelper.safeTransferETH(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

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

pragma solidity ^0.7.0;

import "./IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
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
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/* solhint-disable max-line-length */

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */

    constructor(string memory name, string memory version) {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import {ECDSA} from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

interface IERC1271 {
    function isValidSignature(bytes32 _messageHash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);
}

library SignatureChecker {
    function isValidSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        if (Address.isContract(signer)) {
            bytes4 selector = IERC1271.isValidSignature.selector;
            (bool success, bytes memory returndata) =
                signer.staticcall(abi.encodeWithSelector(selector, hash, signature));
            return success && abi.decode(returndata, (bytes4)) == selector;
        } else {
            return ECDSA.recover(hash, signature) == signer;
        }
    }
}

/// @title ERC1271
/// @notice Module for ERC1271 compatibility
abstract contract ERC1271 is IERC1271 {
    // Valid magic value bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant VALID_SIG = IERC1271.isValidSignature.selector;
    // Invalid magic value
    bytes4 internal constant INVALID_SIG = bytes4(0);

    modifier onlyValidSignature(bytes32 permissionHash, bytes memory signature) {
        require(
            isValidSignature(permissionHash, signature) == VALID_SIG,
            "ERC1271: Invalid signature"
        );
        _;
    }

    function _getOwner() internal view virtual returns (address owner);

    function isValidSignature(bytes32 permissionHash, bytes memory signature)
        public
        view
        override
        returns (bytes4)
    {
        return
            SignatureChecker.isValidSignature(_getOwner(), permissionHash, signature)
                ? VALID_SIG
                : INVALID_SIG;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title OwnableERC721
/// @notice Use ERC721 ownership for access control
contract OwnableERC721 {
    address private _nftAddress;

    modifier onlyOwner() {
        require(owner() == msg.sender, "OwnableERC721: caller is not the owner");
        _;
    }

    function _setNFT(address nftAddress) internal {
        _nftAddress = nftAddress;
    }

    function nft() public view virtual returns (address nftAddress) {
        return _nftAddress;
    }

    function owner() public view virtual returns (address ownerAddress) {
        return IERC721(_nftAddress).ownerOf(uint256(address(this)));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import {IFactory} from "../factory/IFactory.sol";
import {IInstanceRegistry} from "../factory/InstanceRegistry.sol";
import {IUniversalVault} from "../crucible/Crucible.sol";
import {IRewardPool} from "./RewardPool.sol";
import {Powered} from "./Powered.sol";

interface IRageQuit {
    function rageQuit() external;
}

interface IAludel is IRageQuit {
    /* admin events */

    event AludelCreated(address rewardPool, address powerSwitch);
    event AludelFunded(uint256 amount, uint256 duration);
    event BonusTokenRegistered(address token);
    event VaultFactoryRegistered(address factory);
    event VaultFactoryRemoved(address factory);

    /* user events */

    event Staked(address vault, uint256 amount);
    event Unstaked(address vault, uint256 amount);
    event RewardClaimed(address vault, address recipient, address token, uint256 amount);

    /* data types */

    struct AludelData {
        address stakingToken;
        address rewardToken;
        address rewardPool;
        RewardScaling rewardScaling;
        uint256 rewardSharesOutstanding;
        uint256 totalStake;
        uint256 totalStakeUnits;
        uint256 lastUpdate;
        RewardSchedule[] rewardSchedules;
    }

    struct RewardSchedule {
        uint256 duration;
        uint256 start;
        uint256 shares;
    }

    struct VaultData {
        uint256 totalStake;
        StakeData[] stakes;
    }

    struct StakeData {
        uint256 amount;
        uint256 timestamp;
    }

    struct RewardScaling {
        uint256 floor;
        uint256 ceiling;
        uint256 time;
    }

    struct RewardOutput {
        uint256 lastStakeAmount;
        uint256 newStakesCount;
        uint256 reward;
        uint256 newTotalStakeUnits;
    }

    /* user functions */

    function stake(
        address vault,
        uint256 amount,
        bytes calldata permission
    ) external;

    function unstakeAndClaim(
        address vault,
        address recipient,
        uint256 amount,
        bytes calldata permission
    ) external;

    /* getter functions */

    function getAludelData() external view returns (AludelData memory aludel);

    function getBonusTokenSetLength() external view returns (uint256 length);

    function getBonusTokenAtIndex(uint256 index) external view returns (address bonusToken);

    function getVaultFactorySetLength() external view returns (uint256 length);

    function getVaultFactoryAtIndex(uint256 index) external view returns (address factory);

    function getVaultData(address vault) external view returns (VaultData memory vaultData);

    function isValidAddress(address target) external view returns (bool validity);

    function isValidVault(address target) external view returns (bool validity);

    function getCurrentUnlockedRewards() external view returns (uint256 unlockedRewards);

    function getFutureUnlockedRewards(uint256 timestamp)
        external
        view
        returns (uint256 unlockedRewards);

    function getCurrentVaultReward(address vault) external view returns (uint256 reward);

    function getCurrentStakeReward(address vault, uint256 stakeAmount)
        external
        view
        returns (uint256 reward);

    function getFutureVaultReward(address vault, uint256 timestamp)
        external
        view
        returns (uint256 reward);

    function getFutureStakeReward(
        address vault,
        uint256 stakeAmount,
        uint256 timestamp
    ) external view returns (uint256 reward);

    function getCurrentVaultStakeUnits(address vault) external view returns (uint256 stakeUnits);

    function getFutureVaultStakeUnits(address vault, uint256 timestamp)
        external
        view
        returns (uint256 stakeUnits);

    function getCurrentTotalStakeUnits() external view returns (uint256 totalStakeUnits);

    function getFutureTotalStakeUnits(uint256 timestamp)
        external
        view
        returns (uint256 totalStakeUnits);

    /* pure functions */

    function calculateTotalStakeUnits(StakeData[] memory stakes, uint256 timestamp)
        external
        pure
        returns (uint256 totalStakeUnits);

    function calculateStakeUnits(
        uint256 amount,
        uint256 start,
        uint256 end
    ) external pure returns (uint256 stakeUnits);

    function calculateUnlockedRewards(
        RewardSchedule[] memory rewardSchedules,
        uint256 rewardBalance,
        uint256 sharesOutstanding,
        uint256 timestamp
    ) external pure returns (uint256 unlockedRewards);

    function calculateRewardFromStakes(
        StakeData[] memory stakes,
        uint256 unstakeAmount,
        uint256 unlockedRewards,
        uint256 totalStakeUnits,
        uint256 timestamp,
        RewardScaling memory rewardScaling
    ) external pure returns (RewardOutput memory out);

    function calculateReward(
        uint256 unlockedRewards,
        uint256 stakeAmount,
        uint256 stakeDuration,
        uint256 totalStakeUnits,
        RewardScaling memory rewardScaling
    ) external pure returns (uint256 reward);
}

/// @title Aludel
/// @notice Reward distribution contract with time multiplier
/// Access Control
/// - Power controller:
///     Can power off / shutdown the Aludel
///     Can withdraw rewards from reward pool once shutdown
/// - Proxy owner:
///     Can change arbitrary logic / state by upgrading the Aludel
///     Is unable to operate on user funds due to UniversalVault
///     Is unable to operate on reward pool funds when reward pool is offline / shutdown
/// - Aludel admin:
///     Can add funds to the Aludel, register bonus tokens, and whitelist new vault factories
///     Is a subset of proxy owner permissions
/// - User:
///     Can deposit / withdraw / ragequit
/// Aludel State Machine
/// - Online:
///     Aludel is operating normally, all functions are enabled
/// - Offline:
///     Aludel is temporarely disabled for maintenance
///     User deposits and withdrawls are disabled, ragequit remains enabled
///     Users can withdraw their stake through rageQuit() but forego their pending reward
///     Should only be used when downtime required for an upgrade
/// - Shutdown:
///     Aludel is permanently disabled
///     All functions are disabled with the exception of ragequit
///     Users can withdraw their stake through rageQuit()
///     Power controller can withdraw from the reward pool
///     Should only be used if Proxy Owner role is compromized
contract Aludel is IAludel, Powered, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /* constants */

    // An upper bound on the number of active stakes per vault is required to prevent
    // calls to rageQuit() from reverting.
    // With 30 stakes in a vault, ragequit costs 432811 gas which is conservatively lower
    // than the hardcoded limit of 500k gas on the vault.
    // This limit is configurable and could be increased in a future deployment.
    // Ultimately, to avoid a need for fixed upper bounds, the EVM would need to provide
    // an error code that allows for reliably catching out-of-gas errors on remote calls.
    uint256 public constant MAX_STAKES_PER_VAULT = 30;
    uint256 public constant MAX_REWARD_TOKENS = 50;
    uint256 public constant BASE_SHARES_PER_WEI = 1000000;

    /* storage */

    AludelData private _aludel;
    mapping(address => VaultData) private _vaults;
    EnumerableSet.AddressSet private _bonusTokenSet;
    EnumerableSet.AddressSet private _vaultFactorySet;

    /* initializer */

    /// @notice Initizalize Aludel
    /// access control: only proxy constructor
    /// state machine: can only be called once
    /// state scope: set initialization variables
    /// token transfer: none
    /// @param ownerAddress address The admin address
    /// @param rewardPoolFactory address The factory to use for deploying the RewardPool
    /// @param powerSwitchFactory address The factory to use for deploying the PowerSwitch
    /// @param stakingToken address The address of the staking token for this Aludel
    /// @param rewardToken address The address of the reward token for this Aludel
    /// @param rewardScaling RewardScaling The config for reward scaling floor, ceiling, and time
    constructor(
        address ownerAddress,
        address rewardPoolFactory,
        address powerSwitchFactory,
        address stakingToken,
        address rewardToken,
        RewardScaling memory rewardScaling
    ) {
        // the scaling floor must be smaller than ceiling
        require(rewardScaling.floor <= rewardScaling.ceiling, "Aludel: floor above ceiling");

        // setting rewardScalingTime to 0 would cause divide by zero error
        // to disable reward scaling, use rewardScalingFloor == rewardScalingCeiling
        require(rewardScaling.time != 0, "Aludel: scaling time cannot be zero");

        // deploy power switch
        address powerSwitch = IFactory(powerSwitchFactory).create(abi.encode(ownerAddress));

        // deploy reward pool
        address rewardPool = IFactory(rewardPoolFactory).create(abi.encode(powerSwitch));

        // set internal configs
        Ownable.transferOwnership(ownerAddress);
        Powered._setPowerSwitch(powerSwitch);

        // commit to storage
        _aludel.stakingToken = stakingToken;
        _aludel.rewardToken = rewardToken;
        _aludel.rewardPool = rewardPool;
        _aludel.rewardScaling = rewardScaling;

        // emit event
        emit AludelCreated(rewardPool, powerSwitch);
    }

    /* getter functions */

    function getBonusTokenSetLength() external view override returns (uint256 length) {
        return _bonusTokenSet.length();
    }

    function getBonusTokenAtIndex(uint256 index)
        external
        view
        override
        returns (address bonusToken)
    {
        return _bonusTokenSet.at(index);
    }

    function getVaultFactorySetLength() external view override returns (uint256 length) {
        return _vaultFactorySet.length();
    }

    function getVaultFactoryAtIndex(uint256 index)
        external
        view
        override
        returns (address factory)
    {
        return _vaultFactorySet.at(index);
    }

    function isValidVault(address target) public view override returns (bool validity) {
        // validate target is created from whitelisted vault factory
        for (uint256 index = 0; index < _vaultFactorySet.length(); index++) {
            if (IInstanceRegistry(_vaultFactorySet.at(index)).isInstance(target)) {
                return true;
            }
        }
        // explicit return
        return false;
    }

    function isValidAddress(address target) public view override returns (bool validity) {
        // sanity check target for potential input errors
        return
            target != address(this) &&
            target != address(0) &&
            target != _aludel.stakingToken &&
            target != _aludel.rewardToken &&
            target != _aludel.rewardPool &&
            !_bonusTokenSet.contains(target);
    }

    /* Aludel getters */

    function getAludelData() external view override returns (AludelData memory aludel) {
        return _aludel;
    }

    function getCurrentUnlockedRewards() public view override returns (uint256 unlockedRewards) {
        // calculate reward available based on state
        return getFutureUnlockedRewards(block.timestamp);
    }

    function getFutureUnlockedRewards(uint256 timestamp)
        public
        view
        override
        returns (uint256 unlockedRewards)
    {
        // get reward amount remaining
        uint256 remainingRewards = IERC20(_aludel.rewardToken).balanceOf(_aludel.rewardPool);
        // calculate reward available based on state
        unlockedRewards = calculateUnlockedRewards(
            _aludel.rewardSchedules,
            remainingRewards,
            _aludel.rewardSharesOutstanding,
            timestamp
        );
        // explicit return
        return unlockedRewards;
    }

    function getCurrentTotalStakeUnits() public view override returns (uint256 totalStakeUnits) {
        // calculate new stake units
        return getFutureTotalStakeUnits(block.timestamp);
    }

    function getFutureTotalStakeUnits(uint256 timestamp)
        public
        view
        override
        returns (uint256 totalStakeUnits)
    {
        // return early if no change
        if (timestamp == _aludel.lastUpdate) return _aludel.totalStakeUnits;
        // calculate new stake units
        uint256 newStakeUnits =
            calculateStakeUnits(_aludel.totalStake, _aludel.lastUpdate, timestamp);
        // add to cached total
        totalStakeUnits = _aludel.totalStakeUnits.add(newStakeUnits);
        // explicit return
        return totalStakeUnits;
    }

    /* vault getters */

    function getVaultData(address vault)
        external
        view
        override
        returns (VaultData memory vaultData)
    {
        return _vaults[vault];
    }

    function getCurrentVaultReward(address vault) external view override returns (uint256 reward) {
        // calculate rewards
        return
            calculateRewardFromStakes(
                _vaults[vault]
                    .stakes,
                _vaults[vault]
                    .totalStake,
                getCurrentUnlockedRewards(),
                getCurrentTotalStakeUnits(),
                block
                    .timestamp,
                _aludel
                    .rewardScaling
            )
                .reward;
    }

    function getFutureVaultReward(address vault, uint256 timestamp)
        external
        view
        override
        returns (uint256 reward)
    {
        // calculate rewards
        return
            calculateRewardFromStakes(
                _vaults[vault]
                    .stakes,
                _vaults[vault]
                    .totalStake,
                getFutureUnlockedRewards(timestamp),
                getFutureTotalStakeUnits(timestamp),
                timestamp,
                _aludel
                    .rewardScaling
            )
                .reward;
    }

    function getCurrentStakeReward(address vault, uint256 stakeAmount)
        external
        view
        override
        returns (uint256 reward)
    {
        // calculate rewards
        return
            calculateRewardFromStakes(
                _vaults[vault]
                    .stakes,
                stakeAmount,
                getCurrentUnlockedRewards(),
                getCurrentTotalStakeUnits(),
                block
                    .timestamp,
                _aludel
                    .rewardScaling
            )
                .reward;
    }

    function getFutureStakeReward(
        address vault,
        uint256 stakeAmount,
        uint256 timestamp
    ) external view override returns (uint256 reward) {
        // calculate rewards
        return
            calculateRewardFromStakes(
                _vaults[vault]
                    .stakes,
                stakeAmount,
                getFutureUnlockedRewards(timestamp),
                getFutureTotalStakeUnits(timestamp),
                timestamp,
                _aludel
                    .rewardScaling
            )
                .reward;
    }

    function getCurrentVaultStakeUnits(address vault)
        public
        view
        override
        returns (uint256 stakeUnits)
    {
        // calculate stake units
        return getFutureVaultStakeUnits(vault, block.timestamp);
    }

    function getFutureVaultStakeUnits(address vault, uint256 timestamp)
        public
        view
        override
        returns (uint256 stakeUnits)
    {
        // calculate stake units
        return calculateTotalStakeUnits(_vaults[vault].stakes, timestamp);
    }

    /* pure functions */

    function calculateTotalStakeUnits(StakeData[] memory stakes, uint256 timestamp)
        public
        pure
        override
        returns (uint256 totalStakeUnits)
    {
        for (uint256 index; index < stakes.length; index++) {
            // reference stake
            StakeData memory stakeData = stakes[index];
            // calculate stake units
            uint256 stakeUnits =
                calculateStakeUnits(stakeData.amount, stakeData.timestamp, timestamp);
            // add to running total
            totalStakeUnits = totalStakeUnits.add(stakeUnits);
        }
    }

    function calculateStakeUnits(
        uint256 amount,
        uint256 start,
        uint256 end
    ) public pure override returns (uint256 stakeUnits) {
        // calculate duration
        uint256 duration = end.sub(start);
        // calculate stake units
        stakeUnits = duration.mul(amount);
        // explicit return
        return stakeUnits;
    }

    function calculateUnlockedRewards(
        RewardSchedule[] memory rewardSchedules,
        uint256 rewardBalance,
        uint256 sharesOutstanding,
        uint256 timestamp
    ) public pure override returns (uint256 unlockedRewards) {
        // return 0 if no registered schedules
        if (rewardSchedules.length == 0) {
            return 0;
        }

        // calculate reward shares locked across all reward schedules
        uint256 sharesLocked;
        for (uint256 index = 0; index < rewardSchedules.length; index++) {
            // fetch reward schedule storage reference
            RewardSchedule memory schedule = rewardSchedules[index];

            // caculate amount of shares available on this schedule
            // if (now - start) < duration
            //   sharesLocked = shares - (shares * (now - start) / duration)
            // else
            //   sharesLocked = 0
            uint256 currentSharesLocked = 0;
            if (timestamp.sub(schedule.start) < schedule.duration) {
                currentSharesLocked = schedule.shares.sub(
                    schedule.shares.mul(timestamp.sub(schedule.start)).div(schedule.duration)
                );
            }

            // add to running total
            sharesLocked = sharesLocked.add(currentSharesLocked);
        }

        // convert shares to reward
        // rewardLocked = sharesLocked * rewardBalance / sharesOutstanding
        uint256 rewardLocked = sharesLocked.mul(rewardBalance).div(sharesOutstanding);

        // calculate amount available
        // unlockedRewards = rewardBalance - rewardLocked
        unlockedRewards = rewardBalance.sub(rewardLocked);

        // explicit return
        return unlockedRewards;
    }

    function calculateRewardFromStakes(
        StakeData[] memory stakes,
        uint256 unstakeAmount,
        uint256 unlockedRewards,
        uint256 totalStakeUnits,
        uint256 timestamp,
        RewardScaling memory rewardScaling
    ) public pure override returns (RewardOutput memory out) {
        uint256 stakesToDrop = 0;
        while (unstakeAmount > 0) {
            // fetch vault stake storage reference
            StakeData memory lastStake = stakes[stakes.length.sub(stakesToDrop).sub(1)];

            // calculate stake duration
            uint256 stakeDuration = timestamp.sub(lastStake.timestamp);

            uint256 currentAmount;
            if (lastStake.amount > unstakeAmount) {
                // set current amount to remaining unstake amount
                currentAmount = unstakeAmount;
                // amount of last stake is reduced
                out.lastStakeAmount = lastStake.amount.sub(unstakeAmount);
            } else {
                // set current amount to amount of last stake
                currentAmount = lastStake.amount;
                // add to stakes to drop
                stakesToDrop += 1;
            }

            // update remaining unstakeAmount
            unstakeAmount = unstakeAmount.sub(currentAmount);

            // calculate reward amount
            uint256 currentReward =
                calculateReward(
                    unlockedRewards,
                    currentAmount,
                    stakeDuration,
                    totalStakeUnits,
                    rewardScaling
                );

            // update cumulative reward
            out.reward = out.reward.add(currentReward);

            // update cached unlockedRewards
            unlockedRewards = unlockedRewards.sub(currentReward);

            // calculate time weighted stake
            uint256 stakeUnits = currentAmount.mul(stakeDuration);

            // update cached totalStakeUnits
            totalStakeUnits = totalStakeUnits.sub(stakeUnits);
        }

        // explicit return
        return
            RewardOutput(
                out.lastStakeAmount,
                stakes.length.sub(stakesToDrop),
                out.reward,
                totalStakeUnits
            );
    }

    function calculateReward(
        uint256 unlockedRewards,
        uint256 stakeAmount,
        uint256 stakeDuration,
        uint256 totalStakeUnits,
        RewardScaling memory rewardScaling
    ) public pure override returns (uint256 reward) {
        // calculate time weighted stake
        uint256 stakeUnits = stakeAmount.mul(stakeDuration);

        // calculate base reward
        // baseReward = unlockedRewards * stakeUnits / totalStakeUnits
        uint256 baseReward = 0;
        if (totalStakeUnits != 0) {
            // scale reward according to proportional weight
            baseReward = unlockedRewards.mul(stakeUnits).div(totalStakeUnits);
        }

        // calculate scaled reward
        // if no scaling or scaling period completed
        //   reward = baseReward
        // else
        //   minReward = baseReward * scalingFloor / scalingCeiling
        //   bonusReward = baseReward
        //                 * (scalingCeiling - scalingFloor) / scalingCeiling
        //                 * duration / scalingTime
        //   reward = minReward + bonusReward
        if (stakeDuration >= rewardScaling.time || rewardScaling.floor == rewardScaling.ceiling) {
            // no reward scaling applied
            reward = baseReward;
        } else {
            // calculate minimum reward using scaling floor
            uint256 minReward = baseReward.mul(rewardScaling.floor).div(rewardScaling.ceiling);

            // calculate bonus reward with vested portion of scaling factor
            uint256 bonusReward =
                baseReward
                    .mul(stakeDuration)
                    .mul(rewardScaling.ceiling.sub(rewardScaling.floor))
                    .div(rewardScaling.ceiling)
                    .div(rewardScaling.time);

            // add minimum reward and bonus reward
            reward = minReward.add(bonusReward);
        }

        // explicit return
        return reward;
    }

    /* admin functions */

    /// @notice Add funds to the Aludel
    /// access control: only admin
    /// state machine:
    ///   - can be called multiple times
    ///   - only online
    /// state scope:
    ///   - increase _aludel.rewardSharesOutstanding
    ///   - append to _aludel.rewardSchedules
    /// token transfer: transfer staking tokens from msg.sender to reward pool
    /// @param amount uint256 Amount of reward tokens to deposit
    /// @param duration uint256 Duration over which to linearly unlock rewards
    function fund(uint256 amount, uint256 duration) external onlyOwner onlyOnline {
        // validate duration
        require(duration != 0, "Aludel: invalid duration");

        // create new reward shares
        // if existing rewards on this Aludel
        //   mint new shares proportional to % change in rewards remaining
        //   newShares = remainingShares * newReward / remainingRewards
        // else
        //   mint new shares with BASE_SHARES_PER_WEI initial conversion rate
        //   store as fixed point number with same  of decimals as reward token
        uint256 newRewardShares;
        if (_aludel.rewardSharesOutstanding > 0) {
            uint256 remainingRewards = IERC20(_aludel.rewardToken).balanceOf(_aludel.rewardPool);
            newRewardShares = _aludel.rewardSharesOutstanding.mul(amount).div(remainingRewards);
        } else {
            newRewardShares = amount.mul(BASE_SHARES_PER_WEI);
        }

        // add reward shares to total
        _aludel.rewardSharesOutstanding = _aludel.rewardSharesOutstanding.add(newRewardShares);

        // store new reward schedule
        _aludel.rewardSchedules.push(RewardSchedule(duration, block.timestamp, newRewardShares));

        // transfer reward tokens to reward pool
        TransferHelper.safeTransferFrom(
            _aludel.rewardToken,
            msg.sender,
            _aludel.rewardPool,
            amount
        );

        // emit event
        emit AludelFunded(amount, duration);
    }

    /// @notice Add vault factory to whitelist
    /// @dev use this function to enable stakes to vaults coming from the specified
    ///      factory contract
    /// access control: only admin
    /// state machine:
    ///   - can be called multiple times
    ///   - not shutdown
    /// state scope:
    ///   - append to _vaultFactorySet
    /// token transfer: none
    /// @param factory address The address of the vault factory
    function registerVaultFactory(address factory) external onlyOwner notShutdown {
        // add factory to set
        require(_vaultFactorySet.add(factory), "Aludel: vault factory already registered");

        // emit event
        emit VaultFactoryRegistered(factory);
    }

    /// @notice Remove vault factory from whitelist
    /// @dev use this function to disable new stakes to vaults coming from the specified
    ///      factory contract.
    ///      note: vaults with existing stakes from this factory are sill able to unstake
    /// access control: only admin
    /// state machine:
    ///   - can be called multiple times
    ///   - not shutdown
    /// state scope:
    ///   - remove from _vaultFactorySet
    /// token transfer: none
    /// @param factory address The address of the vault factory
    function removeVaultFactory(address factory) external onlyOwner notShutdown {
        // remove factory from set
        require(_vaultFactorySet.remove(factory), "Aludel: vault factory not registered");

        // emit event
        emit VaultFactoryRemoved(factory);
    }

    /// @notice Register bonus token for distribution
    /// @dev use this function to enable distribution of any ERC20 held by the RewardPool contract
    /// access control: only admin
    /// state machine:
    ///   - can be called multiple times
    ///   - only online
    /// state scope:
    ///   - append to _bonusTokenSet
    /// token transfer: none
    /// @param bonusToken address The address of the bonus token
    function registerBonusToken(address bonusToken) external onlyOwner onlyOnline {
        // verify valid bonus token
        _validateAddress(bonusToken);

        // verify bonus token count
        require(_bonusTokenSet.length() < MAX_REWARD_TOKENS, "Aludel: max bonus tokens reached ");

        // add token to set
        assert(_bonusTokenSet.add(bonusToken));

        // emit event
        emit BonusTokenRegistered(bonusToken);
    }

    /// @notice Rescue tokens from RewardPool
    /// @dev use this function to rescue tokens from RewardPool contract
    ///      without distributing to stakers or triggering emergency shutdown
    /// access control: only admin
    /// state machine:
    ///   - can be called multiple times
    ///   - only online
    /// state scope: none
    /// token transfer: transfer requested token from RewardPool to recipient
    /// @param token address The address of the token to rescue
    /// @param recipient address The address of the recipient
    /// @param amount uint256 The amount of tokens to rescue
    function rescueTokensFromRewardPool(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner onlyOnline {
        // verify recipient
        _validateAddress(recipient);

        // check not attempting to unstake reward token
        require(token != _aludel.rewardToken, "Aludel: invalid address");

        // check not attempting to wthdraw bonus token
        require(!_bonusTokenSet.contains(token), "Aludel: invalid address");

        // transfer tokens to recipient
        IRewardPool(_aludel.rewardPool).sendERC20(token, recipient, amount);
    }

    /* user functions */

    /// @notice Stake tokens
    /// @dev anyone can stake to any vault if they have valid permission
    /// access control: anyone
    /// state machine:
    ///   - can be called multiple times
    ///   - only online
    ///   - when vault exists on this Aludel
    /// state scope:
    ///   - append to _vaults[vault].stakes
    ///   - increase _vaults[vault].totalStake
    ///   - increase _aludel.totalStake
    ///   - increase _aludel.totalStakeUnits
    ///   - increase _aludel.lastUpdate
    /// token transfer: transfer staking tokens from msg.sender to vault
    /// @param vault address The address of the vault to stake from
    /// @param amount uint256 The amount of staking tokens to stake
    function stake(
        address vault,
        uint256 amount,
        bytes calldata permission
    ) external override onlyOnline {
        // verify vault is valid
        require(isValidVault(vault), "Aludel: vault is not registered");

        // verify non-zero amount
        require(amount != 0, "Aludel: no amount staked");

        // fetch vault storage reference
        VaultData storage vaultData = _vaults[vault];

        // verify stakes boundary not reached
        require(
            vaultData.stakes.length < MAX_STAKES_PER_VAULT,
            "Aludel: MAX_STAKES_PER_VAULT reached"
        );

        // update cached sum of stake units across all vaults
        _updateTotalStakeUnits();

        // store amount and timestamp
        vaultData.stakes.push(StakeData(amount, block.timestamp));

        // update cached total vault and Aludel amounts
        vaultData.totalStake = vaultData.totalStake.add(amount);
        _aludel.totalStake = _aludel.totalStake.add(amount);

        // call lock on vault
        IUniversalVault(vault).lock(_aludel.stakingToken, amount, permission);

        // emit event
        emit Staked(vault, amount);
    }

    /// @notice Unstake staking tokens and claim reward
    /// @dev rewards can only be claimed when unstaking
    /// access control: only owner of vault
    /// state machine:
    ///   - when vault exists on this Aludel
    ///   - after stake from vault
    ///   - can be called multiple times while sufficient stake remains
    ///   - only online
    /// state scope:
    ///   - decrease _aludel.rewardSharesOutstanding
    ///   - decrease _aludel.totalStake
    ///   - increase _aludel.lastUpdate
    ///   - modify _aludel.totalStakeUnits
    ///   - modify _vaults[vault].stakes
    ///   - decrease _vaults[vault].totalStake
    /// token transfer:
    ///   - transfer reward tokens from reward pool to recipient
    ///   - transfer bonus tokens from reward pool to recipient
    /// @param vault address The vault to unstake from
    /// @param recipient address The recipient to send reward to
    /// @param amount uint256 The amount of staking tokens to unstake
    function unstakeAndClaim(
        address vault,
        address recipient,
        uint256 amount,
        bytes calldata permission
    ) external override onlyOnline {
        // fetch vault storage reference
        VaultData storage vaultData = _vaults[vault];

        // verify non-zero amount
        require(amount != 0, "Aludel: no amount unstaked");

        // validate recipient
        _validateAddress(recipient);

        // check for sufficient vault stake amount
        require(vaultData.totalStake >= amount, "Aludel: insufficient vault stake");

        // check for sufficient Aludel stake amount
        // if this check fails, there is a bug in stake accounting
        assert(_aludel.totalStake >= amount);

        // update cached sum of stake units across all vaults
        _updateTotalStakeUnits();

        // get reward amount remaining
        uint256 remainingRewards = IERC20(_aludel.rewardToken).balanceOf(_aludel.rewardPool);

        // calculate vested portion of reward pool
        uint256 unlockedRewards =
            calculateUnlockedRewards(
                _aludel.rewardSchedules,
                remainingRewards,
                _aludel.rewardSharesOutstanding,
                block.timestamp
            );

        // calculate vault time weighted reward with scaling
        RewardOutput memory out =
            calculateRewardFromStakes(
                vaultData.stakes,
                amount,
                unlockedRewards,
                _aludel.totalStakeUnits,
                block.timestamp,
                _aludel.rewardScaling
            );

        // update stake data in storage
        if (out.newStakesCount == 0) {
            // all stakes have been unstaked
            delete vaultData.stakes;
        } else {
            // some stakes have been completely or partially unstaked
            // delete fully unstaked stakes
            while (vaultData.stakes.length > out.newStakesCount) vaultData.stakes.pop();
            // update partially unstaked stake
            vaultData.stakes[out.newStakesCount.sub(1)].amount = out.lastStakeAmount;
        }

        // update cached stake totals
        vaultData.totalStake = vaultData.totalStake.sub(amount);
        _aludel.totalStake = _aludel.totalStake.sub(amount);
        _aludel.totalStakeUnits = out.newTotalStakeUnits;

        // unlock staking tokens from vault
        IUniversalVault(vault).unlock(_aludel.stakingToken, amount, permission);

        // emit event
        emit Unstaked(vault, amount);

        // only perform on non-zero reward
        if (out.reward > 0) {
            // calculate shares to burn
            // sharesToBurn = sharesOutstanding * reward / remainingRewards
            uint256 sharesToBurn =
                _aludel.rewardSharesOutstanding.mul(out.reward).div(remainingRewards);

            // burn claimed shares
            _aludel.rewardSharesOutstanding = _aludel.rewardSharesOutstanding.sub(sharesToBurn);

            // transfer bonus tokens from reward pool to recipient
            if (_bonusTokenSet.length() > 0) {
                for (uint256 index = 0; index < _bonusTokenSet.length(); index++) {
                    // fetch bonus token address reference
                    address bonusToken = _bonusTokenSet.at(index);

                    // calculate bonus token amount
                    // bonusAmount = bonusRemaining * reward / remainingRewards
                    uint256 bonusAmount =
                        IERC20(bonusToken).balanceOf(_aludel.rewardPool).mul(out.reward).div(
                            remainingRewards
                        );

                    // transfer bonus token
                    IRewardPool(_aludel.rewardPool).sendERC20(bonusToken, recipient, bonusAmount);

                    // emit event
                    emit RewardClaimed(vault, recipient, bonusToken, bonusAmount);
                }
            }

            // transfer reward tokens from reward pool to recipient
            IRewardPool(_aludel.rewardPool).sendERC20(_aludel.rewardToken, recipient, out.reward);

            // emit event
            emit RewardClaimed(vault, recipient, _aludel.rewardToken, out.reward);
        }
    }

    /// @notice Exit Aludel without claiming reward
    /// @dev This function should never revert when correctly called by the vault.
    ///      A max number of stakes per vault is set with MAX_STAKES_PER_VAULT to
    ///      place an upper bound on the for loop in calculateTotalStakeUnits().
    /// access control: only callable by the vault directly
    /// state machine:
    ///   - when vault exists on this Aludel
    ///   - when active stake from this vault
    ///   - any power state
    /// state scope:
    ///   - decrease _aludel.totalStake
    ///   - increase _aludel.lastUpdate
    ///   - modify _aludel.totalStakeUnits
    ///   - delete _vaults[vault]
    /// token transfer: none
    function rageQuit() external override {
        // fetch vault storage reference
        VaultData storage _vaultData = _vaults[msg.sender];

        // revert if no active stakes
        require(_vaultData.stakes.length != 0, "Aludel: no stake");

        // update cached sum of stake units across all vaults
        _updateTotalStakeUnits();

        // emit event
        emit Unstaked(msg.sender, _vaultData.totalStake);

        // update cached totals
        _aludel.totalStake = _aludel.totalStake.sub(_vaultData.totalStake);
        _aludel.totalStakeUnits = _aludel.totalStakeUnits.sub(
            calculateTotalStakeUnits(_vaultData.stakes, block.timestamp)
        );

        // delete stake data
        delete _vaults[msg.sender];
    }

    /* convenience functions */

    function _updateTotalStakeUnits() private {
        // update cached totalStakeUnits
        _aludel.totalStakeUnits = getCurrentTotalStakeUnits();
        // update cached lastUpdate
        _aludel.lastUpdate = block.timestamp;
    }

    function _validateAddress(address target) private view {
        // sanity check target for potential input errors
        require(isValidAddress(target), "Aludel: invalid address");
    }

    function _truncateStakesArray(StakeData[] memory array, uint256 newLength)
        private
        pure
        returns (StakeData[] memory newArray)
    {
        newArray = new StakeData[](newLength);
        for (uint256 index = 0; index < newLength; index++) {
            newArray[index] = array[index];
        }
        return newArray;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import {Powered} from "./Powered.sol";

interface IRewardPool {
    function sendERC20(
        address token,
        address to,
        uint256 value
    ) external;

    function rescueERC20(address[] calldata tokens, address recipient) external;
}

/// @title Reward Pool
/// @notice Vault for isolated storage of reward tokens
contract RewardPool is IRewardPool, Powered, Ownable {
    /* initializer */

    constructor(address powerSwitch) {
        Powered._setPowerSwitch(powerSwitch);
    }

    /* user functions */

    /// @notice Send an ERC20 token
    /// access control: only owner
    /// state machine:
    ///   - can be called multiple times
    ///   - only online
    /// state scope: none
    /// token transfer: transfer tokens from self to recipient
    /// @param token address The token to send
    /// @param to address The recipient to send to
    /// @param value uint256 Amount of tokens to send
    function sendERC20(
        address token,
        address to,
        uint256 value
    ) external override onlyOwner onlyOnline {
        TransferHelper.safeTransfer(token, to, value);
    }

    /* emergency functions */

    /// @notice Rescue multiple ERC20 tokens
    /// access control: only power controller
    /// state machine:
    ///   - can be called multiple times
    ///   - only shutdown
    /// state scope: none
    /// token transfer: transfer tokens from self to recipient
    /// @param tokens address[] The tokens to rescue
    /// @param recipient address The recipient to rescue to
    function rescueERC20(address[] calldata tokens, address recipient)
        external
        override
        onlyShutdown
    {
        // only callable by controller
        require(
            msg.sender == Powered.getPowerController(),
            "RewardPool: only controller can withdraw after shutdown"
        );

        // assert recipient is defined
        require(recipient != address(0), "RewardPool: recipient not defined");

        // transfer tokens
        for (uint256 index = 0; index < tokens.length; index++) {
            // get token
            address token = tokens[index];
            // get balance
            uint256 balance = IERC20(token).balanceOf(address(this));
            // transfer token
            TransferHelper.safeTransfer(token, recipient, balance);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import {IPowerSwitch} from "./PowerSwitch.sol";

interface IPowered {
    function isOnline() external view returns (bool status);

    function isOffline() external view returns (bool status);

    function isShutdown() external view returns (bool status);

    function getPowerSwitch() external view returns (address powerSwitch);

    function getPowerController() external view returns (address controller);
}

/// @title Powered
/// @notice Helper for calling external PowerSwitch
contract Powered is IPowered {
    /* storage */

    address private _powerSwitch;

    /* modifiers */

    modifier onlyOnline() {
        _onlyOnline();
        _;
    }

    modifier onlyOffline() {
        _onlyOffline();
        _;
    }

    modifier notShutdown() {
        _notShutdown();
        _;
    }

    modifier onlyShutdown() {
        _onlyShutdown();
        _;
    }

    /* initializer */

    function _setPowerSwitch(address powerSwitch) internal {
        _powerSwitch = powerSwitch;
    }

    /* getter functions */

    function isOnline() public view override returns (bool status) {
        return IPowerSwitch(_powerSwitch).isOnline();
    }

    function isOffline() public view override returns (bool status) {
        return IPowerSwitch(_powerSwitch).isOffline();
    }

    function isShutdown() public view override returns (bool status) {
        return IPowerSwitch(_powerSwitch).isShutdown();
    }

    function getPowerSwitch() public view override returns (address powerSwitch) {
        return _powerSwitch;
    }

    function getPowerController() public view override returns (address controller) {
        return IPowerSwitch(_powerSwitch).getPowerController();
    }

    /* convenience functions */

    function _onlyOnline() private view {
        require(isOnline(), "Powered: is not online");
    }

    function _onlyOffline() private view {
        require(isOffline(), "Powered: is not offline");
    }

    function _notShutdown() private view {
        require(!isShutdown(), "Powered: is shutdown");
    }

    function _onlyShutdown() private view {
        require(isShutdown(), "Powered: is not shutdown");
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IPowerSwitch {
    /* admin events */

    event PowerOn();
    event PowerOff();
    event EmergencyShutdown();

    /* data types */

    enum State {Online, Offline, Shutdown}

    /* admin functions */

    function powerOn() external;

    function powerOff() external;

    function emergencyShutdown() external;

    /* view functions */

    function isOnline() external view returns (bool status);

    function isOffline() external view returns (bool status);

    function isShutdown() external view returns (bool status);

    function getStatus() external view returns (State status);

    function getPowerController() external view returns (address controller);
}

/// @title PowerSwitch
/// @notice Standalone pausing and emergency stop functionality
contract PowerSwitch is IPowerSwitch, Ownable {
    /* storage */

    IPowerSwitch.State private _status;

    /* initializer */

    constructor(address owner) {
        // sanity check owner
        require(owner != address(0), "PowerSwitch: invalid owner");
        // transfer ownership
        Ownable.transferOwnership(owner);
    }

    /* admin functions */

    /// @notice Turn Power On
    /// access control: only admin
    /// state machine: only when offline
    /// state scope: only modify _status
    /// token transfer: none
    function powerOn() external override onlyOwner {
        require(_status == IPowerSwitch.State.Offline, "PowerSwitch: cannot power on");
        _status = IPowerSwitch.State.Online;
        emit PowerOn();
    }

    /// @notice Turn Power Off
    /// access control: only admin
    /// state machine: only when online
    /// state scope: only modify _status
    /// token transfer: none
    function powerOff() external override onlyOwner {
        require(_status == IPowerSwitch.State.Online, "PowerSwitch: cannot power off");
        _status = IPowerSwitch.State.Offline;
        emit PowerOff();
    }

    /// @notice Shutdown Permanently
    /// access control: only admin
    /// state machine:
    /// - when online or offline
    /// - can only be called once
    /// state scope: only modify _status
    /// token transfer: none
    function emergencyShutdown() external override onlyOwner {
        require(_status != IPowerSwitch.State.Shutdown, "PowerSwitch: cannot shutdown");
        _status = IPowerSwitch.State.Shutdown;
        emit EmergencyShutdown();
    }

    /* getter functions */

    function isOnline() external view override returns (bool status) {
        return _status == State.Online;
    }

    function isOffline() external view override returns (bool status) {
        return _status == State.Offline;
    }

    function isShutdown() external view override returns (bool status) {
        return _status == State.Shutdown;
    }

    function getStatus() external view override returns (IPowerSwitch.State status) {
        return _status;
    }

    function getPowerController() external view override returns (address controller) {
        return Ownable.owner();
    }
}