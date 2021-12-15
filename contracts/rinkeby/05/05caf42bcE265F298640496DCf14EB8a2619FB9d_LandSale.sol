// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
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

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

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
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title EIP-2981: NFT Royalty Standard
 *
 * @notice A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs)
 *      to enable universal support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * @author Zach Burks, James Morgan, Blaine Malone, James Seibel
 */
interface EIP2981 is IERC165 {
	/**
	 * @dev ERC165 bytes to add to interface array - set in parent contract
	 *      implementing this standard:
	 *      bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
	 *      bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	 *      _registerInterface(_INTERFACE_ID_ERC2981);
	 *
	 * @notice Called with the sale price to determine how much royalty
	 *      is owed and to whom.
	 * @param _tokenId token ID to calculate royalty info for;
	 *      the NFT asset queried for royalty information
	 * @param _salePrice the price (in any unit, .e.g wei, ERC20 token, et.c.) of the token to be sold;
	 *      the sale price of the NFT asset specified by _tokenId
	 * @return receiver the royalty receiver, an address of who should be sent the royalty payment
	 * @return royaltyAmount royalty amount in the same unit as _salePrice;
	 *      the royalty payment amount for _salePrice
	 */
	function royaltyInfo(
		uint256 _tokenId,
		uint256 _salePrice
	) external view returns (
		address receiver,
		uint256 royaltyAmount
	);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
	/**
	 * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
	 *
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in approve() to indicate an approval event happened
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param value amount of tokens granted to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @return name of the token (ex.: USD Coin)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function name() external view returns (string memory);

	/**
	 * @return symbol of the token (ex.: USDC)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `2`, a balance of `505` tokens should
	 *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * @dev Tokens usually opt for a value of 18, imitating the relationship between
	 *      Ether and Wei. This is the value {ERC20} uses, unless this function is
	 *      overridden;
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including
	 *      {IERC20-balanceOf} and {IERC20-transfer}.
	 *
	 * @return token decimals
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function decimals() external view returns (uint8);

	/**
	 * @return the amount of tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) external view returns (uint256 balance);

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) external returns (bool success);

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC165Spec.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev Solidity issue #3412: The ERC721 interfaces include explicit mutability guarantees for each function.
 *      Mutability guarantees are, in order weak to strong: payable, implicit nonpayable, view, and pure.
 *      Implementation MUST meet the mutability guarantee in this interface and MAY meet a stronger guarantee.
 *      For example, a payable function in this interface may be implemented as nonpayable
 *      (no state mutability specified) in implementing contract.
 *      It is expected a later Solidity release will allow stricter contract to inherit from this interface,
 *      but current workaround is that we edit this interface to add stricter mutability before inheriting:
 *      we have removed all "payable" modifiers.
 *
 * @dev The ERC-165 identifier for this interface is 0x80ac58cd.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721 is ERC165 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external /*payable*/;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external /*payable*/;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param _operator The address which called `safeTransferFrom` function
	/// @param _from The address which previously owned the token
	/// @param _tokenId The NFT identifier which is being transferred
	/// @param _data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x5b5e139f.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Metadata is ERC721 {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x780e9d63.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Enumerable is ERC721 {
	/// @notice Count NFTs tracked by this contract
	/// @return A count of valid NFTs tracked by this contract, where each one of
	///  them has an assigned and queryable owner not equal to the zero address
	function totalSupply() external view returns (uint256);

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index) external view returns (uint256);

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Mintable ERC721 Extension
 *
 * @notice Defines mint capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Basil Gorin
 */
interface MintableERC721 {
	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) external view returns(bool);

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) external;

}

/**
 * @title Batch Mintable ERC721 Extension
 *
 * @notice Defines batch minting capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Basil Gorin
 */
interface BatchMintable {
	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) external;
}

/**
 * @title Burnable ERC721 Extension
 *
 * @notice Defines burn capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what burnable means for ERC721
 *
 * @author Basil Gorin
 */
interface BurnableERC721 {
	/**
	 * @notice Destroys the token with token ID specified
	 *
	 * @dev Should be accessible publicly by token owners.
	 *      May have a restricted access handled by the implementation
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Identifiable Token
 *
 * @notice Marker interface for the smart contracts having TOKEN_UID public property,
 *      usually these are ERC20/ERC721/ERC1155 token smart contracts
 *
 * @dev TOKEN_UID is used as an enhancement to ERC165 and helps better identifying
 *      deployed smart contracts
 *
 * @author Basil Gorin
 */
interface IdentifiableToken {
	/**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 * @dev Example value: 0x0bcafe95bec2350659433fc61cb9c4fbe18719da00059d525154dfe0d6e8c8fd
	 */
	function TOKEN_UID() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../lib/LandLib.sol";

/**
 * @title Land ERC721 Metadata
 *
 * @notice Defines metadata-related capabilities for LandERC721 token.
 *      This interface should be treated as a definition of what metadata is for LandERC721,
 *      and what operations are defined/allowed for it.
 *
 * @author Basil Gorin
 */
interface LandERC721Metadata {
	/**
	 * @notice Presents token metadata in a well readable form,
	 *      with the Internal Land Structure included, as a `PlotView` struct
	 *
	 * @notice Reconstructs the internal land structure of the plot based on the stored
	 *      Tier ID, Plot Size, Generator Version, and Seed
	 *
	 * @param _tokenId token ID to query metadata view for
	 * @return token metadata as a `PlotView` struct
	 */
	function viewMetadata(uint256 _tokenId) external view returns(LandLib.PlotView memory);

	/**
	 * @notice Presents token metadata "as is", without the Internal Land Structure included,
	 *      as a `PlotStore` struct;
	 *
	 * @notice Doesn't reconstruct the internal land structure of the plot, allowing to
	 *      access Generator Version, and Seed fields "as is"
	 *
	 * @param _tokenId token ID to query on-chain metadata for
	 * @return token metadata as a `PlotStore` struct
	 */
	function getMetadata(uint256 _tokenId) external view returns(LandLib.PlotStore memory);

	/**
	 * @notice Verifies if token has its metadata set on-chain; for the tokens
	 *      in existence metadata is immutable, it can be set once, and not updated
	 *
	 * @dev If `exists(_tokenId) && hasMetadata(_tokenId)` is true, `setMetadata`
	 *      for such a `_tokenId` will always throw
	 *
	 * @param _tokenId token ID to check metadata existence for
	 * @return true if token ID specified has metadata associated with it
	 */
	function hasMetadata(uint256 _tokenId) external view returns(bool);

	/**
	 * @dev Sets/updates token metadata on-chain; same metadata struct can be then
	 *      read back using `getMetadata()` function, or it can be converted to
	 *      `PlotView` using `viewMetadata()` function
	 *
	 * @dev The metadata supplied is validated to satisfy (regionId, x, y) uniqueness;
	 *      non-intersection of the sites coordinates within a plot is guaranteed by the
	 *      internal land structure generator algorithm embedded into the `viewMetadata()`
	 *
	 * @dev Metadata for non-existing tokens can be set and updated unlimited
	 *      amount of times without any restrictions (except the constraints above)
	 * @dev Metadata for an existing token can only be set, it cannot be updated
	 *      (`setMetadata` will throw if metadata already exists)
	 *
	 * @param _tokenId token ID to set/updated the metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function setMetadata(uint256 _tokenId, LandLib.PlotStore memory _plot) external;

	/**
	 * @dev Removes token metadata
	 *
	 * @param _tokenId token ID to remove metadata for
	 */
	function removeMetadata(uint256 _tokenId) external;

	/**
	 * @dev Mints the token and assigns the metadata supplied
	 *
	 * @dev Creates new token with the token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Consider minting with `safeMint` (and setting metadata before),
	 *      for the "safe mint" like behavior
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId token ID to mint and set metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function mintWithMetadata(address _to, uint256 _tokenId, LandLib.PlotStore memory _plot) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Pair Price Oracle, a.k.a. Pair Oracle
 *
 * @notice Generic interface used to consult on the Uniswap-like token pairs conversion prices;
 *      one pair oracle is used to consult on the exchange rate within a single token pair
 *
 * @notice See also: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/building-an-oracle
 *
 * @author Basil Gorin
 */
interface PairOracle {
	/**
	 * @notice Updates the oracle with the price values if required, for example
	 *      the cumulative price at the start and end of a period, etc.
	 *
	 * @dev This function is part of the oracle maintenance flow
	 */
	function update() external;

	/**
	 * @notice For a pair of tokens A/B (sell/buy), consults on the amount of token B to be
	 *      bought if the specified amount of token A to be sold
	 *
	 * @dev This function is part of the oracle usage flow
	 *
	 * @param token token A (token to sell) address
	 * @param amountIn amount of token A to sell
	 * @return amountOut amount of token B to be bought
	 */
	function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

/**
 * @title Oracle Registry
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 *
 * @author Basil Gorin
 */
interface OracleRegistry {
	/**
	 * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
	 *
	 * @param tokenA token A (token to sell) address
	 * @param tokenB token B (token to buy) address
	 * @return pairOracle pair price oracle address for A/B token pair
	 */
	function getOracle(address tokenA, address tokenB) external view returns(address pairOracle);
}

/**
 * @title Land Sale Oracle Interface
 *
 * @notice Supports the Land Sale with the ETH/ILV conversion required,
 *       marker interface is required to support ERC165 lookups
 *
 * @author Basil Gorin
 */
interface LandSaleOracle {
	/**
	 * @notice Powers the ETH/ILV Land token price conversion, used when
	 *      selling the land for sILV to determine how much sILV to accept
	 *      instead of the nominated ETH price
	 *
	 * @notice Note that sILV price is considered to be equal to ILV price
	 *
	 * @param ethOut amount of ETH sale contract is expecting to get
	 * @return ilvIn amount of sILV sale contract should accept instead
	 */
	function ethToIlv(uint256 ethOut) external returns(uint256 ilvIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Land Library
 *
 * @notice A library defining data structures related to land plots (used in Land ERC721 token),
 *      and functions transforming these structures between view and internal (packed) representations,
 *      in both directions.
 *
 * @notice Due to some limitations Solidity has (ex.: allocating array of structures in storage),
 *      and due to the specific nature of internal land structure
 *      (landmark and resource sites data is deterministically derived from a pseudo random seed),
 *      it is convenient to separate data structures used to store metadata on-chain (store),
 *      and data structures used to present metadata via smart contract ABI (view)
 *
 * @notice Introduces helper functions to detect and deal with the resource site collisions
 *
 * @author Basil Gorin
 */
library LandLib {
	/**
	 * @title Resource Site View
	 *
	 * @notice Resource Site, bound to a coordinates (x, y) within the land plot
	 *
	 * @notice Resources can be of two major types, each type having three subtypes:
	 *      - Element (Carbon, Silicon, Hydrogen), or
	 *      - Fuel (Crypton, Hyperion, Solon)
	 *
	 * @dev View only structure, used in public API/ABI, not used in on-chain storage
	 */
	struct Site {
		/**
		 * @dev Site type:
		 *        1) Carbon (element),
		 *        2) Silicon (element),
		 *        3) Hydrogen (element),
		 *        4) Crypton (fuel),
		 *        5) Hyperion (fuel),
		 *        6) Solon (fuel)
		 */
		uint8 typeId;

		/**
		 * @dev x-coordinate within a plot
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within a plot
		 */
		uint16 y;
	}

	/**
	 * @title Land Plot View
	 *
	 * @notice Land Plot, bound to a coordinates (x, y) within the region,
	 *      with a rarity defined by the tier ID, sites, and (optionally)
	 *      a landmark, positioned on the internal coordinate grid of the
	 *      specified size within a plot.
	 *
	 * @notice Land plot coordinates and rarity are predefined (stored off-chain).
	 *      Number of sites (and landmarks - 0/1) is defined by the land rarity.
	 *      Positions of sites, types of sites/landmark are randomized and determined
	 *      upon land plot creation.
	 *
	 * @dev View only structure, used in public API/ABI, not used in on-chain storage
	 */
	struct PlotView {
		/**
		 * @dev Region ID defines the region on the map in IZ:
		 *        1) Abyssal Basin
		 *        2) Brightland Steppes
		 *        3) Shardbluff Labyrinth
		 *        4) Crimson Waste
		 *        5) Halcyon Sea
		 *        6) Taiga Boreal
		 *        7) Crystal Shores
		 */
		uint8 regionId;

		/**
		 * @dev x-coordinate within the region
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within the region
		 */
		uint16 y;

		/**
		 * @dev Tier ID defines land rarity and number of sites within the plot
		 */
		uint8 tierId;

		/**
		 * @dev Plot size, limits the (x, y) coordinates for the sites
		 */
		uint16 size;

		/**
		 * @dev Landmark Type ID:
		 *        0) no Landmark
		 *        1) Carbon Landmark,
		 *        2) Silicon Landmark,
		 *        3) Hydrogen Landmark (Eternal Spring),
		 *        4) Crypton Landmark,
		 *        5) Hyperion Landmark,
		 *        6) Solon Landmark (Fallen Star),
		 *        7) Arena
		 *
		 * @dev Landmark is always positioned in the center of internal grid
		 */
		uint8 landmarkTypeId;

		/**
		 * @dev Number of Element Sites (Carbon, Silicon, or Hydrogen) this plot contains,
		 *      matches the number of element sites in sites[] array
		 */
		uint8 elementSites;

		/**
		 * @dev Number of Fuel Sites (Crypton, Hyperion, or Solon) this plot contains,
		 *      matches the number of fuel sites in sites[] array
		 */
		uint8 fuelSites;

		/**
		 * @dev Element/fuel sites within the plot
		 */
		Site[] sites;
	}

	/**
	 * @title Land Plot Store
	 *
	 * @notice Land Plot data structure as it is stored on-chain
	 *
	 * @notice Contains the data required to generate `PlotView` structure:
	 *      - regionId, x, y, tierId, size, landmarkTypeId, elementSites, and fuelSites are copied as is
	 *      - version and seed are used to derive array of sites (together with elementSites, and fuelSites)
	 *
	 * @dev On-chain optimized structure, has limited usage in public API/ABI
	 */
	struct PlotStore {
		/**
		 * @dev Region ID defines the region on the map in IZ:
		 *        1) Abyssal Basin
		 *        2) Brightland Steppes
		 *        3) Shardbluff Labyrinth
		 *        4) Crimson Waste
		 *        5) Halcyon Sea
		 *        6) Taiga Boreal
		 *        7) Crystal Shores
		 */
		uint8 regionId;

		/**
		 * @dev x-coordinate within the region
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within the region
		 */
		uint16 y;

		/**
		 * @dev Tier ID defines land rarity and number of sites within the plot
		 */
		uint8 tierId;

		/**
		 * @dev Plot Size, limits the (x, y) coordinates for the sites
		 */
		uint16 size;

		/**
		 * @dev Landmark Type ID:
		 *        0) no Landmark
		 *        1) Carbon Landmark,
		 *        2) Silicon Landmark,
		 *        3) Hydrogen Landmark (Eternal Spring),
		 *        4) Crypton Landmark,
		 *        5) Hyperion Landmark,
		 *        6) Solon Landmark (Fallen Star),
		 *        7) Arena
		 *
		 * @dev Landmark is always positioned in the center of internal grid
		 */
		uint8 landmarkTypeId;

		/**
		 * @dev Number of Element Sites (Carbon, Silicon, or Hydrogen) this plot contains
		 */
		uint8 elementSites;

		/**
		 * @dev Number of Fuel Sites (Crypton, Hyperion, or Solon) this plot contains
		 */
		uint8 fuelSites;

		/**
		 * @dev Generator Version, reserved for the future use in order to tweak the
		 *      behavior of the internal land structure algorithm
		 */
		uint8 version;

		/**
		 * @dev Pseudo-random Seed to generate Internal Land Structure,
		 *      should be treated as already used to derive Landmark Type ID
		 */
		uint160 seed;
	}


	/**
	 * @dev Expands `PlotStore` data struct into a `PlotView` view struct
	 *
	 * @dev Derives internal land structure (resource sites the plot has)
	 *      from Number of Element/Fuel Sites, Plot Size, and Seed;
	 *      Generator Version is not currently used
	 *
	 * @param store on-chain `PlotStore` data structure to expand
	 * @return `PlotView` view struct, expanded from the on-chain data
	 */
	function plotView(PlotStore memory store) internal pure returns(PlotView memory) {
		// copy most of the fields as is, derive resource sites array inline
		return PlotView({
			regionId:       store.regionId,
			x:              store.x,
			y:              store.y,
			tierId:         store.tierId,
			size:           store.size,
			landmarkTypeId: store.landmarkTypeId,
			elementSites:   store.elementSites,
			fuelSites:      store.fuelSites,
			// derive the resource sites from Number of Element/Fuel Sites, Plot Size, and Seed
			sites:          getResourceSites(store.seed, store.elementSites, store.fuelSites, store.size, 2)
		});
	}

	/**
	 * @dev Based on the random seed, tier ID, and plot size, determines the
	 *      internal land structure (resource sites the plot has)
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @param seed random seed to consume and derive the internal structure
	 * @param elementSites number of element sites plot has
	 * @param fuelSites number of fuel sites plot has
	 * @param gridSize plot size `N` of the land plot to derive internal structure for
	 * @param siteSize implied size `n` of the resource sites
	 * @return sites randomized array of resource sites
	 */
	function getResourceSites(
		uint256 seed,
		uint8 elementSites,
		uint8 fuelSites,
		uint16 gridSize,
		uint8 siteSize
	) internal pure returns(Site[] memory sites) {
		// derive the total number of sites
		uint8 totalSites = elementSites + fuelSites;

		// denote the grid (plot) size `N`
		// denote the resource site size `n`

		// transform coordinate system (1): normalization (x, y) => (x / n, y / n)
		// if `N` is odd this cuts off border coordinates x = N - 1, y = N - 1
		uint16 normalizedSize = gridSize / siteSize;

		// after normalization (1) is applied, isomorphic grid becomes effectively larger
		// due to borders capturing effect, for example if N = 4, and n = 2:
		//      | .. |                                              |....|
		// grid |....| becomes |..| normalized which is effectively |....|
		//      |....|         |..|                                 |....|
		//      | .. |                                              |....|
		// transform coordinate system (2): cut the borders, and reduce grid size to be multiple of 2
		// if `N/2` is odd this cuts off border coordinates x = N/2 - 1, y = N/2 - 1
		normalizedSize = (normalizedSize - 2) / 2 * 2;

		// define coordinate system: isomorphic grid on a square of size [size, size]
		// transform coordinate system (3): pack isomorphic grid on a rectangle of size [size, 1 + size / 2]
		// transform coordinate system (4): (x, y) -> y * size + x (two-dimensional Cartesian -> one-dimensional segment)
		// generate site coordinates in a transformed coordinate system (on a one-dimensional segment)
		uint16[] memory coords; // define temporary array to determine sites' coordinates
		// cut off four elements in the end of the segment to reserve space in the center for a landmark
		(seed, coords) = getCoords(seed, totalSites, normalizedSize * (1 + normalizedSize / 2) - 4);

		// allocate number of sites required
		sites = new Site[](totalSites);

		// define the variables used inside the loop outside the loop to help compiler optimizations
		// site type ID
		uint8 typeId;
		// site coordinates (x, y)
		uint16 x;
		uint16 y;

		// determine the element and fuel sites one by one
		for(uint8 i = 0; i < totalSites; i++) {
			// determine next random number in the sequence, and random site type from it
			(seed, typeId) = nextRndUint8(seed, i < elementSites? 1: 4, 3);

			// determine x and y
			// reverse transform coordinate system (4): x = size % i, y = size / i
			// (back from one-dimensional segment to two-dimensional Cartesian)
			x = coords[i] % normalizedSize;
			y = coords[i] / normalizedSize;

			// reverse transform coordinate system (3): unpack isomorphic grid onto a square of size [size, size]
			// fix the "(0, 0) left-bottom corner" of the isomorphic grid
			if(2 * (1 + x + y) < normalizedSize) {
				x += normalizedSize / 2;
				y += 1 + normalizedSize / 2;
			}
			// fix the "(size, 0) right-bottom corner" of the isomorphic grid
			else if(2 * x > normalizedSize && 2 * x > 2 * y + normalizedSize) {
				x -= normalizedSize / 2;
				y += 1 + normalizedSize / 2;
			}

			// move the site from the center (four positions near the center) to a free spot
			if(x >= normalizedSize / 2 - 1 && x <= normalizedSize / 2 && y >= normalizedSize / 2 - 1 && y <= normalizedSize / 2) {
				// `x` is aligned over the free space in the end of the segment
				// x += normalizedSize / 2 + 2 * (normalizedSize / 2 - x) + 2 * (normalizedSize / 2 - y) - 4;
				x += 5 * normalizedSize / 2 - 2 * (x + y) - 4;
				// `y` is fixed over the free space in the end of the segment
				y = normalizedSize / 2;
			}

			// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
			// if `N` is odd this recover previously cut off border coordinates x = N - 1, y = N - 1
			uint16 offset = gridSize / siteSize % 2 + gridSize % siteSize;

			// based on the determined site type and coordinates, allocate the site
			sites[i] = Site({
			typeId: typeId,
				// reverse transform coordinate system (2): recover borders (x, y) => (x + 1, y + 1)
				// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
				// reverse transform coordinate system (1): (x, y) => (n * x, n * y), where n is site size
				// if `N` is odd this recover previously cut off border coordinates x = N - 1, y = N - 1
				x: (1 + x) * siteSize + offset,
				y: (1 + y) * siteSize + offset
			});
		}
	}

	/**
	 * @dev Based on the random seed and tier ID determines the landmark type of the plot.
	 *      Random seed is consumed for tiers 3 and 4 to randomly determine one of three
	 *      possible landmark types.
	 *      Tier 5 has its landmark type predefined (arena), lower tiers don't have a landmark.
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @param seed random seed to consume and derive the landmark type based on
	 * @param tierId tier ID of the land plot
	 * @return landmarkTypeId landmark type defined by its ID
	 */
	function getLandmark(uint256 seed, uint8 tierId) internal pure returns(uint8 landmarkTypeId) {
		// depending on the tier, land plot can have a landmark
		// tier 3 has an element landmark (1, 2, 3)
		if(tierId == 3) {
			// derive random element landmark
			return uint8(1 + seed % 3);
		}
		// tier 4 has a fuel landmark (4, 5, 6)
		if(tierId == 4) {
			// derive random fuel landmark
			return uint8(4 + seed % 3);
		}
		// tier 5 has an arena landmark
		if(tierId == 5) {
			// 7 - arena landmark
			return 7;
		}

		// lower tiers (0, 1, 2) don't have any landmark
		// tiers greater than 5 are not defined
		return 0;
	}

	/**
	 * @dev Derives an array of integers with no duplicates from the random seed;
	 *      each element in the array is within [0, size) bounds and represents
	 *      a two-dimensional Cartesian coordinate point (x, y) presented as one-dimensional
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive coordinates from
	 * @param length number of elements to generate
	 * @param size defines array element bounds [0, size)
	 * @return nextSeed next pseudo-random "used" seed
	 * @return coords the resulting array of length `n` with random non-repeating elements
	 *      in [0, size) range
	 */
	function getCoords(
		uint256 seed,
		uint8 length,
		uint16 size
	) internal pure returns(uint256 nextSeed, uint16[] memory coords) {
		// allocate temporary array to store (and determine) sites' coordinates
		coords = new uint16[](length);

		// generate site coordinates one by one
		for(uint8 i = 0; i < coords.length; i++) {
			// get next number and update the seed
			(seed, coords[i]) = nextRndUint16(seed, 0, size);
		}

		// sort the coordinates
		sort(coords);

		// find the if there are any duplicates, and while there are any
		for(int256 i = findDup(coords); i >= 0; i = findDup(coords)) {
			// regenerate the element at duplicate position found
			(seed, coords[uint256(i)]) = nextRndUint16(seed, 0, size);
			// sort the coordinates again
			// TODO: check if this doesn't degrade the performance significantly (note the pivot in quick sort)
			sort(coords);
		}

		// return the updated and used seed
		return (seed, coords);
	}

	/**
	 * @dev Based on the random seed, generates next random seed, and a random value
	 *      not lower than given `offset` value and able to have `options` different
	 *      and equiprobable values, that is in the [offset, offset + options) range
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param offset the minimum possible output
	 * @param options number of different possible values to output
	 * @return nextSeed next pseudo-random "used" seed
	 * @return rndVal random value in the [offset, offset + options) range
	 */
	function nextRndUint8(
		uint256 seed,
		uint8 offset,
		uint8 options
	) internal pure returns(
		uint256 nextSeed,
		uint8 rndVal
	) {
		// generate next random seed first
		nextSeed = uint256(keccak256(abi.encodePacked(seed)));

		// derive random value with the desired properties from
		// the newly generated seed
		rndVal = offset + uint8(nextSeed % options);
	}

	/**
	 * @dev Based on the random seed, generates next random seed, and a random value
	 *      not lower than given `offset` value and able to have `options` different
	 *      possible values
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param offset the minimum possible output
	 * @param options number of different possible values to output
	 * @return nextSeed next pseudo-random "used" seed
	 * @return rndVal random value in the [offset, offset + options) range
	 */
	function nextRndUint16(
		uint256 seed,
		uint16 offset,
		uint16 options
	) internal pure returns(
		uint256 nextSeed,
		uint16 rndVal
	) {
		// generate next random seed first
		nextSeed = uint256(keccak256(abi.encodePacked(seed)));

		// derive random value with the desired properties from
		// the newly generated seed
		rndVal = offset + uint16(nextSeed % options);
	}

	/**
	 * @dev Plot location is a combination of (regionId, x, y), it's effectively
	 *      a 3-dimensional coordinate, unique for each plot
	 *
	 * @dev The function extracts plot location from the plot and represents it
	 *      in a packed form of 3 integers constituting the location: regionId | x | y
	 *
	 * @param plot `PlotView` view structure to extract location from
	 * @return Plot location (regionId, x, y) as a packed integer
	 */
/*
	function loc(PlotView memory plot) internal pure returns(uint40) {
		// tightly pack the location data and return
		return uint40(plot.regionId) << 32 | uint32(plot.y) << 16 | plot.x;
	}
*/

	/**
	 * @dev Plot location is a combination of (regionId, x, y), it's effectively
	 *      a 3-dimensional coordinate, unique for each plot
	 *
	 * @dev The function extracts plot location from the plot and represents it
	 *      in a packed form of 3 integers constituting the location: regionId | x | y
	 *
	 * @param plot `PlotStore` data store structure to extract location from
	 * @return Plot location (regionId, x, y) as a packed integer
	 */
	function loc(PlotStore memory plot) internal pure returns(uint40) {
		// tightly pack the location data and return
		return uint40(plot.regionId) << 32 | uint32(plot.y) << 16 | plot.x;
	}

	/**
	 * @dev Site location is a combination of (x, y), unique for each site within a plot
	 *
	 * @dev The function extracts site location from the site and represents it
	 *      in a packed form of 2 integers constituting the location: x | y
	 *
	 * @param site `Site` view structure to extract location from
	 * @return Site location (x, y) as a packed integer
	 */
/*
	function loc(Site memory site) internal pure returns(uint32) {
		// tightly pack the location data and return
		return uint32(site.y) << 16 | site.x;
	}
*/

	/**
	 * @dev Finds first pair of repeating elements in the array
	 *
	 * @dev Assumes the array is sorted ascending:
	 *      returns `-1` if array is strictly monotonically increasing,
	 *      index of the first duplicate found otherwise
	 *
	 * @param arr an array of elements to check
	 * @return index found duplicate index, or `-1` if there are no repeating elements
	 */
	function findDup(uint16[] memory arr) internal pure returns (int256 index) {
		// iterate over the array [1, n], leaving the space in the beginning for pair comparison
		for(uint256 i = 1; i < arr.length; i++) {
			// verify if there is a strict monotonically increase violation
			if(arr[i - 1] >= arr[i]) {
				// return false if yes
				return int256(i - 1);
			}
		}

		// return `-1` if no violation was found - array is strictly monotonically increasing
		return -1;
	}

	/**
	 * @dev Sorts an array of integers using quick sort algorithm
	 *
	 * @dev Quick sort recursive implementation
	 *      Source:   https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
	 *      See also: https://www.geeksforgeeks.org/quick-sort/
	 *
	 * @param arr an array to sort
	 */
	function sort(uint16[] memory arr) internal pure {
		quickSort(arr, 0, int256(arr.length) - 1);
	}

	/**
	 * @dev Quick sort recursive implementation
	 *      Source:     https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
	 *      Discussion: https://blog.cotten.io/thinking-in-solidity-6670c06390a9
	 *      See also:   https://www.geeksforgeeks.org/quick-sort/
	 */
	// TODO: review the implementation code
	function quickSort(uint16[] memory arr, int256 left, int256 right) internal pure {
		int256 i = left;
		int256 j = right;
		if(i >= j) {
			return;
		}
		uint16 pivot = arr[uint256(left + (right - left) / 2)];
		while(i <= j) {
			while(arr[uint256(i)] < pivot) {
				i++;
			}
			while(pivot < arr[uint256(j)]) {
				j--;
			}
			if(i <= j) {
				(arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
				i++;
				j--;
			}
		}
		if(left < j) {
			quickSort(arr, left, j);
		}
		if(i < right) {
			quickSort(arr, i, right);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC20Spec.sol";
import "../interfaces/ERC721Spec.sol";
import "../interfaces/IdentifiableSpec.sol";
import "../interfaces/PriceOracleSpec.sol";
import "../token/LandERC721.sol";
import "../utils/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Land Sale
 *
 * @notice Enables the Land NFT sale via dutch auction mechanism
 *
 * @notice The proposed volume of land is approximately 100,000 plots, split amongst the 7 regions.
 *      The volume is released over a series of staggered sales with the first sale featuring
 *      about 20,000 land plots (tokens).
 *
 * @notice Land plots are sold in sequences, each sequence groups tokens which are sold in parallel.
 *      Sequences start selling one by one with the configurable time interval between their start.
 *      A sequence is available for a sale for a fixed (configurable) amount of time, meaning they
 *      can overlap (tokens from several sequences are available on sale simultaneously) if this
 *      amount of time is bigger than interval between sequences start.
 *
 * @notice The sale operates in a configurable time interval which should be aligned with the
 *      total number of sequences, their duration, and start interval.
 *      Sale smart contract has no idea of the total number of sequences and doesn't validate
 *      if these timings are correctly aligned.
 *
 * @notice Starting prices of the plots are defined by the plot tier in ETH, and are configurable
 *      within the sale contract per tier ID.
 *      Token price declines over time exponentially, price halving time is configurable.
 *      The exponential price decline simulates the price drop requirement which may be formulates
 *      something like "the price drops by 'x' % every 'y' minutes".
 *      For example, if x = 2, and y = 1, "the price drops by 2% every minute", the halving
 *      time is around 34 minutes.
 *
 * @notice Sale accepts ETH and sILV as a payment currency, sILV price is supplied by on-chain
 *      price oracle (sILV price is assumed to be equal to ILV price)
 *
 * @notice The data required to mint a plot includes (see `PlotData` struct):
 *      - token ID, defines a unique ID for the land plot used as ERC721 token ID
 *      - sequence ID, defines the time frame when the plot is available for sale
 *      - region ID (1 - 7), determines which tileset to use in game,
 *      - coordinates (x, y) on the overall world map, indicating which grid position the land sits in,
 *      - tier ID (1 - 5), the rarity of the land, tier is used to create the list of sites,
 *      - size (w, h), defines an internal coordinate system within a plot,
 *
 * @notice Since minting a plot requires at least 32 bytes of data and due to a significant
 *      amount of plots to be minted (about 100,000), pre-storing this data on-chain
 *      is not a viable option (2,000,000,000 of gas only to pay for the storage).
 *      Instead, we represent the whole land plot data collection on sale as a Merkle tree
 *      structure and store the root of the Merkle tree on-chain.
 *      To buy a particular plot, the buyer must know the entire collection and be able to
 *      generate and present the Merkle proof for this particular plot.
 *
 * @notice The input data is a collection of `PlotData` structures; the Merkle tree is built out
 *      from this collection, and the tree root is stored on the contract by the data manager.
 *      When buying a plot, the buyer also specifies the Merkle proof for a plot data to mint.
 *
 * @dev Merkle proof verification is based on OpenZeppelin implementation, see
 *      https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
 *
 * @author Basil Gorin
 */
contract LandSale is AccessControl {
	// Use Zeppelin MerkleProof Library to verify Merkle proofs
	using MerkleProof for bytes32[];

	/**
	 * @title Plot Data, a.k.a. Sale Data
	 *
	 * @notice Data structure modeling the data entry required to mint a single plot.
	 *      The contract is initialized with the Merkle root of the plots collection Merkle tree.
	 * @dev When buying a plot this data structure must be supplied together with the
	 *      Merkle proof allowing to verify the plot data belongs to the original collection.
	 */
	struct PlotData {
		/// @dev Token ID, defines a unique ID for the land plot used as ERC721 token ID
		uint32 tokenId;
		/// @dev Sequence ID, defines the time frame when the plot is available for sale
		uint32 sequenceId;
		/// @dev Region ID defines the region on the map in IZ
		uint8 regionId;
		/// @dev x-coordinate within the region plot
		uint16 x;
		/// @dev y-coordinate within the region plot
		uint16 y;
		/// @dev Tier ID defines land rarity and number of sites within the plot
		uint8 tierId;
		/// @dev Plot size, limits the (x, y) coordinates for the sites
		uint16 size;
	}

	/**
	 * @notice Deployed LandERC721 token address to mint tokens of
	 *      (when they are bought via the sale)
	 */
	address public immutable targetNftContract;

	/**
	 * @notice Deployed sILV (Escrowed Illuvium) ERC20 token address,
	 *      accepted as a payment option alongside ETH
	 * @dev Note: sILV ERC20 implementation never returns "false" on transfers,
	 *      it throws instead; we don't use any additional libraries like SafeERC20
	 *      to transfer sILV therefore
	 */
	address public immutable sIlvContract;

	/**
	 * @notice Land Sale Price Oracle is used to convert the token prices from USD
	 *      to ETH or sILV (ILV)
	 */
	address public immutable priceOracle;

	/**
	 * @notice Input data root, Merkle tree root for the collection of plot data elements,
	 *      available on sale
	 *
	 * @notice Merkle root effectively "compresses" the (potentially) huge collection of elements
	 *      and allows to store it in a single 256-bits storage slot on-chain
	 */
	bytes32 public root;

	/**
	 * @dev Sale start unix timestamp, this is the time when sale activates,
	 *      the time when the first sequence sale starts, that is
	 *      when tokens of the first sequence become available on sale
	 * @dev The sale is active after the start (inclusive)
	 */
	uint32 public saleStart;

	/**
	 * @dev Sale end unix timestamp, this is the time when sale deactivates,
	 *      and tokens of the last sequence become unavailable
	 * @dev The sale is active before the end (exclusive)
	 */
	uint32 public saleEnd;

	/**
	 * @dev Price halving time, the time required for a token price to reduce to the
	 *      half of its initial value
	 * @dev Defined in seconds
	 */
	uint32 public halvingTime;

	/**
	 * @dev Time flow quantum, price update interval, used by the price calculation algorithm,
	 *      the time is rounded down to be multiple of quantum when performing price calculations;
	 *      setting this value to one effectively disables its effect;
	 * @dev Defined in seconds
	 */
	uint32 public timeFlowQuantum;

	/**
	 * @dev Sequence duration, time limit of how long a token / sequence can be available
	 *      for sale, first sequence stops selling at `saleStart + seqDuration`, second
	 *      sequence stops selling at `saleStart + seqOffset + seqDuration`, and so on
	 * @dev Defined in seconds
	 */
	uint32 public seqDuration;

	/**
	 * @dev Sequence start offset, first sequence starts selling at `saleStart`,
	 *      second sequence starts at `saleStart + seqOffset`, third at
	 *      `saleStart + 2 * seqOffset` and so on at `saleStart + n * seqOffset`,
	 *      where `n` is zero-based sequence ID
	 * @dev Defined in seconds
	 */
	uint32 public seqOffset;

	/**
	 * @dev Tier start prices, starting token price for each (zero based) Tier ID,
	 *      defined in ETH, can be converted into sILV via Uniswap/Sushiswap price oracle,
	 *      sILV price is defined to be equal to ILV price
	 */
	uint96[] public startPrices;

	/**
	 * @dev Sale beneficiary address, if set - used to send funds obtained from the sale;
	 *      If not set - contract accumulates the funds on its own deployed address
	 */
	address payable public beneficiary;

	/**
	 * @notice Enables the sale, buying tokens public function
	 *
	 * @notice Note: sale could be activated/deactivated by either sale manager, or
	 *      data manager, since these roles control sale params, and items on sale;
	 *      However both sale and data managers require some advanced knowledge about
	 *      the use of the functions they trigger, while switching the "sale active"
	 *      flag is very simple and can be done much more easier
	 *
	 * @dev Feature FEATURE_SALE_ACTIVE must be enabled in order for
	 *      `buy()` function to be able to succeed
	 */
	uint32 public constant FEATURE_SALE_ACTIVE = 0x0000_0001;

	/**
	 * @notice Data manager is responsible for supplying the valid input plot data collection
	 *      Merkle root which then can be used to mint tokens, meaning effectively,
	 *      that data manager may act as a minter on the target NFT contract
	 *
	 * @dev Role ROLE_DATA_MANAGER allows setting the Merkle tree root via setInputDataRoot()
	 */
	uint32 public constant ROLE_DATA_MANAGER = 0x0001_0000;

	/**
	 * @notice Sale manager is responsible for sale initialization:
	 *      setting up sale start/end, halving time, sequence params, and starting prices
	 *
	 * @dev  Role ROLE_SALE_MANAGER allows sale initialization via initialize()
	 */
	uint32 public constant ROLE_SALE_MANAGER = 0x0002_0000;

	/**
	 * @notice Withdrawal manager is responsible for withdrawing funds obtained in sale
	 *      from the sale smart contract via pull/push mechanisms:
	 *      1) Pull: no pre-setup is required, withdrawal manager executes the
	 *         withdraw function periodically to withdraw funds
	 *      2) Push: withdrawal manager sets the `beneficiary` address which is used
	 *         by the smart contract to send funds to when users purchase land NFTs
	 *
	 * @dev Role ROLE_WITHDRAWAL_MANAGER allows to set the `beneficiary` address via
	 *      - setBeneficiary()
	 * @dev Role ROLE_WITHDRAWAL_MANAGER allows pull withdrawals of funds:
	 *      - withdraw()
	 *      - withdrawTo()
	 */
	uint32 public constant ROLE_WITHDRAWAL_MANAGER = 0x0004_0000;

	/**
	 * @notice People do mistake and may send ERC20 tokens by mistake; since
	 *      NFT smart contract is not designed to accept and hold any ERC20 tokens,
	 *      it allows the rescue manager to "rescue" such lost tokens
	 *
	 * @notice Rescue manager is responsible for "rescuing" ERC20 tokens accidentally
	 *      sent to the smart contract, except the sILV which is a payment token
	 *      and can be withdrawn by the withdrawal manager only
	 *
	 * @dev Role ROLE_RESCUE_MANAGER allows withdrawing any ERC20 tokens stored
	 *      on the smart contract balance
	 */
	uint32 public constant ROLE_RESCUE_MANAGER = 0x0008_0000;

	/**
	 * @dev Fired in setInputDataRoot()
	 *
	 * @param _by an address which executed the operation
	 * @param _root new Merkle root value
	 */
	event RootChanged(address indexed _by, bytes32 _root);

	/**
	 * @dev Fired in initialize()
	 *
	 * @param _by an address which executed the operation
	 * @param _saleStart sale start time, and first sequence start time
	 * @param _saleEnd sale end time, should match with the last sequence end time
	 * @param _halvingTime price halving time, the time required for a token price
	 *      to reduce to the half of its initial value
	 * @param _timeFlowQuantum time flow quantum, price update interval, used by
	 *      the price calculation algorithm to update prices
	 * @param _seqDuration sequence duration, time limit of how long a token / sequence
	 *      can be available for sale
	 * @param _seqOffset sequence start offset, each sequence starts `_seqOffset`
	 *      later after the previous one
	 * @param _startPrices tier start prices, starting token price for each (zero based) Tier ID
	 */
	event Initialized(
		address indexed _by,
		uint32 _saleStart,
		uint32 _saleEnd,
		uint32 _halvingTime,
		uint32 _timeFlowQuantum,
		uint32 _seqDuration,
		uint32 _seqOffset,
		uint96[] _startPrices
	);

	/**
	 * @dev Fired in setBeneficiary
	 *
	 * @param _by an address which executed the operation
	 * @param _beneficiary new beneficiary address or zero-address
	 */
	event BeneficiaryUpdated(address indexed _by, address indexed _beneficiary);

	/**
	 * @dev Fired in withdraw() and withdrawTo()
	 *
	 * @param _by an address which executed the operation
	 * @param _to an address which received the funds withdrawn
	 * @param _eth amount of ETH withdrawn
	 * @param _sIlv amount of sILV withdrawn
	 */
	event Withdrawn(address indexed _by, address indexed _to, uint256 _eth, uint256 _sIlv);

	/**
	 * @dev Fired in buy()
	 *
	 * @param _by an address which had bought the plot
	 * @param _tokenId Token ID, part of the off-chain plot metadata supplied externally
	 * @param _sequenceId Sequence ID, part of the off-chain plot metadata supplied externally
	 * @param _plot on-chain plot metadata minted token, contains values copied from off-chain
	 *      plot metadata supplied externally, and generated values such as seed
	 * @param _eth ETH price of the lot
	 * @param _sIlv sILV price of the lot (zero if paid in ETH)
	 */
	event PlotBought(
		address indexed _by,
		uint32 indexed _tokenId,
		uint32 indexed _sequenceId,
		LandLib.PlotStore _plot,
		uint256 _eth,
		uint256 _sIlv
	);

	/**
	 * @dev Creates/deploys sale smart contract instance and binds it to
	 *      1) the target NFT smart contract address to be used to mint tokens (Land ERC721),
	 *      2) sILV (Escrowed Illuvium) contract address to be used as one of the payment options
	 *      3) Price Oracle contract address to be used to determine ETH/sILV price
	 *
	 * @param _nft target NFT smart contract address
	 * @param _sIlv sILV (Escrowed Illuvium) contract address
	 * @param _oracle price oracle contract address
	 */
	constructor(address _nft, address _sIlv, address _oracle) AccessControl(msg.sender) {
		// verify the inputs are set
		require(_nft != address(0), "target contract is not set");
		require(_sIlv != address(0), "sILV contract is not set");
		require(_oracle != address(0), "oracle address is not set");

		// verify the inputs are valid smart contracts of the expected interfaces
		require(
			IERC165(_nft).supportsInterface(type(ERC721).interfaceId)
			&& IERC165(_nft).supportsInterface(type(MintableERC721).interfaceId)
			&& IERC165(_nft).supportsInterface(type(LandERC721Metadata).interfaceId),
			"unexpected target type"
		);
		// for the sILV ERC165 check is unavailable, but TOKEN_UID check is available
		require(
			IdentifiableToken(_sIlv).TOKEN_UID() == 0xac3051b8d4f50966afb632468a4f61483ae6a953b74e387a01ef94316d6b7d62,
			"unexpected sILV UID"
		);
		require(IERC165(_oracle).supportsInterface(type(LandSaleOracle).interfaceId), "unexpected oracle type");

		// assign the addresses
		targetNftContract = _nft;
		sIlvContract = _sIlv;
		priceOracle = _oracle;
	}

	/**
	 * @dev `startPrices` getter; the getters solidity creates for arrays
	 *      may be inconvenient to use if we need an entire array to be read
	 *
	 * @return `startPrices` as is - as an array of uint96
	 */
	function getStartPrices() public view returns(uint96[] memory) {
		// read `startPrices` array into memory and return
		return startPrices;
	}

	/**
	 * @notice Restricted access function to update input data root (Merkle tree root),
	 *       and to define, effectively, the tokens to be created by this smart contract
	 *
	 * @dev Requires executor to have `ROLE_DATA_MANAGER` permission
	 *
	 * @param _root Merkle tree root for the input plot data collection
	 */
	function setInputDataRoot(bytes32 _root) public {
		// verify the access permission
		require(isSenderInRole(ROLE_DATA_MANAGER), "access denied");

		// update input data Merkle tree root
		root = _root;

		// emit an event
		emit RootChanged(msg.sender, _root);
	}

	/**
	 * @notice Verifies the validity of a plot supplied (namely, if it's registered for the sale)
	 *      based on the Merkle root of the plot data collection (already defined on the contract),
	 *      and the Merkle proof supplied to validate the particular plot data
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the plot data collection elements via `web3.utils.soliditySha3`, making sure
	 *         the packing order and types are exactly as defined in `PlotData` struct
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed collection, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given plot data element the proof is constructed by hashing it (as in step 1),
	 *         and querying the MerkleTree for a proof, providing the hashed plot data element as a leaf
	 *
	 * @dev See also: https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
	 *
	 * @param plotData plot data to verify
	 * @param proof Merkle proof for the plot data supplied
	 * @return true if plot is valid (belongs to registered collection), false otherwise
	 */
	function isPlotValid(PlotData memory plotData, bytes32[] memory proof) public view returns(bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(
				plotData.tokenId,
				plotData.sequenceId,
				plotData.regionId,
				plotData.x,
				plotData.y,
				plotData.tierId,
				plotData.size
			));

		// verify the proof supplied, and return the verification result
		return proof.verify(root, leaf);
	}

	/**
	 * @dev Restricted access function to set up sale parameters, all at once,
	 *      or any subset of them
	 *
	 * @dev To skip parameter initialization, set it to `-1`,
	 *      that is a maximum value for unsigned integer of the corresponding type;
	 *      for `_startPrices` use a single array element with the `-1` value to skip
	 *
	 * @dev Example: following initialization will update only `_seqDuration` and `_seqOffset`,
	 *      leaving the rest of the fields unchanged
	 *      initialize(
	 *          0xFFFFFFFF, // `_saleStart` unchanged
	 *          0xFFFFFFFF, // `_saleEnd` unchanged
	 *          0xFFFFFFFF, // `_halvingTime` unchanged
	 *          21600,      // `_seqDuration` updated to 6 hours
	 *          3600,       // `_seqOffset` updated to 1 hour
	 *          [0xFFFFFFFFFFFFFFFFFFFFFFFF] // `_startPrices` unchanged
	 *      )
	 *
	 * @dev Sale start and end times should match with the number of sequences,
	 *      sequence duration and offset, if `n` is number of sequences, then
	 *      the following equation must hold:
	 *         `saleStart + (n - 1) * seqOffset + seqDuration = saleEnd`
	 *      Note: `n` is unknown to the sale contract and there is no way for it
	 *      to accurately validate other parameters of the equation above
	 *
	 * @dev Input params are not validated; to get an idea if these params look valid,
	 *      refer to `isActive() `function, and it's logic
	 *
	 * @dev Requires transaction sender to have `ROLE_SALE_MANAGER` role
	 *
	 * @param _saleStart sale start time, and first sequence start time
	 * @param _saleEnd sale end time, should match with the last sequence end time
	 * @param _halvingTime price halving time, the time required for a token price
	 *      to reduce to the half of its initial value
	 * @param _timeFlowQuantum time flow quantum, price update interval, used by
	 *      the price calculation algorithm to update prices
	 * @param _seqDuration sequence duration, time limit of how long a token / sequence
	 *      can be available for sale
	 * @param _seqOffset sequence start offset, each sequence starts `_seqOffset`
	 *      later after the previous one
	 * @param _startPrices tier start prices, starting token price for each (zero based) Tier ID
	 */
	function initialize(
		uint32 _saleStart,           // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _saleEnd,             // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _halvingTime,         // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _timeFlowQuantum,     // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _seqDuration,         // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _seqOffset,           // <<<--- keep type in sync with the body type(uint32).max !!!
		uint96[] memory _startPrices // <<<--- keep type in sync with the body type(uint96).max !!!
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_SALE_MANAGER), "access denied");

		// Note: no input validation at this stage, initial params state is invalid anyway,
		//       and we're not limiting sale manager to set these params back to this state

		// set/update sale parameters (allowing partial update)
		// 0xFFFFFFFF, 32 bits
		if(_saleStart != type(uint32).max) {
			saleStart = _saleStart;
		}
		// 0xFFFFFFFF, 32 bits
		if(_saleEnd != type(uint32).max) {
			saleEnd = _saleEnd;
		}
		// 0xFFFFFFFF, 32 bits
		if(_halvingTime != type(uint32).max) {
			halvingTime = _halvingTime;
		}
		// 0xFFFFFFFF, 32 bits
		if(_timeFlowQuantum != type(uint32).max) {
			timeFlowQuantum = _timeFlowQuantum;
		}
		// 0xFFFFFFFF, 32 bits
		if(_seqDuration != type(uint32).max) {
			seqDuration = _seqDuration;
		}
		// 0xFFFFFFFF, 32 bits
		if(_seqOffset != type(uint32).max) {
			seqOffset = _seqOffset;
		}
		// 0xFFFFFFFFFFFFFFFFFFFFFFFF, 96 bits
		if(_startPrices.length != 1 || _startPrices[0] != type(uint96).max) {
			startPrices = _startPrices;
		}

		// emit an event
		emit Initialized(msg.sender, saleStart, saleEnd, halvingTime, timeFlowQuantum, seqDuration, seqOffset, startPrices);
	}

	/**
	 * @notice Verifies if sale is in the active state, meaning that it is properly
	 *      initialized with the sale start/end times, sequence params, etc., and
	 *      that the current time is within the sale start/end bounds
	 *
	 * @notice Doesn't check if the plot data Merkle root `root` is set or not;
	 *      active sale state doesn't guarantee that an item can be actually bought
	 *
	 * @dev The sale is defined as active if all of the below conditions hold:
	 *      - sale start is now or in the past
	 *      - sale end is in the future
	 *      - halving time is not zero
	 *      - sequence duration is not zero
	 *      - there is at least one starting price set (zero price is valid)
	 *
	 * @return true if sale is active, false otherwise
	 */
	function isActive() public view returns(bool) {
		// calculate sale state based on the internal sale params state and return
		return saleStart <= now32() && now32() < saleEnd
			&& halvingTime > 0
			&& timeFlowQuantum > 0
			&& seqDuration > 0
			&& startPrices.length > 0;
	}

	/**
	 * @dev Restricted access function to update the sale beneficiary address, the address
	 *      can be set, updated, or "unset" (deleted, set to zero)
	 *
	 * @dev Setting the address to non-zero value effectively activates funds withdrawal
	 *      mechanism via the push pattern
	 *
	 * @dev Setting the address to zero value effectively deactivates funds withdrawal
	 *      mechanism via the push pattern (pull mechanism can be used instead)
	 */
	function setBeneficiary(address payable _beneficiary) public {
		// check the access permission
		require(isSenderInRole(ROLE_WITHDRAWAL_MANAGER), "access denied");

		// update the beneficiary address
		beneficiary = _beneficiary;

		// emit an event
		emit BeneficiaryUpdated(msg.sender, _beneficiary);
	}

	/**
	 * @dev Restricted access function to withdraw funds on the contract balance,
	 *      sends funds back to transaction sender
	 *
	 * @dev Withdraws both ETH and sILV balances if `_ethOnly` is set to false,
	 *      withdraws only ETH is `_ethOnly` is set to true
	 *
	 * @param _ethOnly a flag indicating whether to withdraw sILV or not
	 */
	function withdraw(bool _ethOnly) public {
		// delegate to `withdrawTo`
		withdrawTo(payable(msg.sender), _ethOnly);
	}

	/**
	 * @dev Restricted access function to withdraw funds on the contract balance,
	 *      sends funds to the address specified
	 *
	 * @dev Withdraws both ETH and sILV balances if `_ethOnly` is set to false,
	 *      withdraws only ETH is `_ethOnly` is set to true
	 *
	 * @param _to an address to send funds to
	 * @param _ethOnly a flag indicating whether to withdraw sILV or not
	 */
	function withdrawTo(address payable _to, bool _ethOnly) public {
		// check the access permission
		require(isSenderInRole(ROLE_WITHDRAWAL_MANAGER), "access denied");

		// verify withdrawal address is set
		require(_to != address(0), "recipient not set");

		// ETH value to send
		uint256 ethBalance = address(this).balance;

		// sILV value to send
		uint256 sIlvBalance = _ethOnly? 0: ERC20(sIlvContract).balanceOf(address(this));

		// verify there is a balance to send
		require(ethBalance > 0 || sIlvBalance > 0, "zero balance");

		// if there is ETH to send
		if(ethBalance > 0) {
			// send the entire balance to the address specified
			_to.transfer(ethBalance);
		}

		// if there is sILV to send
		if(sIlvBalance > 0) {
			// send the entire balance to the address specified
			ERC20(sIlvContract).transfer(_to, sIlvBalance);
		}

		// emit en event
		emit Withdrawn(msg.sender, _to, ethBalance, sIlvBalance);
	}

	/**
	 * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
	 *      the tokens are rescued via `transfer` function call on the
	 *      contract address specified and with the parameters specified:
	 *      `_contract.transfer(_to, _value)`
	 *
	 * @dev Doesn't allow to rescue sILV tokens, use withdraw/withdrawTo instead
	 *
	 * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
	 *
	 * @param _contract smart contract address to execute `transfer` function on
	 * @param _to to address in `transfer(_to, _value)`
	 * @param _value value to transfer in `transfer(_to, _value)`
	 */
	function rescueErc20(address _contract, address _to, uint256 _value) public {
		// verify the access permission
		require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

		// verify rescue manager is not trying to withdraw sILV:
		// we have a withdrawal manager to help with that
		require(_contract != sIlvContract, "sILV access denied");

		// perform the transfer as requested, without any checks
		ERC20(_contract).transfer(_to, _value);
	}

	/**
	 * @notice Determines the dutch auction price value for a token in a given
	 *      sequence `sequenceId`, given tier `tierId`, now (block.timestamp)
	 *
	 * @dev Throws if `now` is outside the [saleStart, saleEnd) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 */
	function tokenPriceNow(uint32 sequenceId, uint16 tierId) public view returns(uint256) {
		// delegate to `tokenPriceAt` using current time as `t`
		return tokenPriceAt(sequenceId, tierId, now32());
	}

	/**
	 * @notice Determines the dutch auction price value for a token in a given
	 *      sequence `sequenceId`, given tier `tierId`, at a given time `t`
	 *
	 * @dev Throws if `t` is outside the [saleStart, saleEnd) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 * @param t the time of interest, time to evaluate the price at
	 */
	function tokenPriceAt(uint32 sequenceId, uint16 tierId, uint32 t) public view returns(uint256) {
		// calculate sequence sale start
		uint32 seqStart = saleStart + sequenceId * seqOffset;
		// calculate sequence sale end
		uint32 seqEnd = seqStart + seqDuration;

		// verify `t` is in a reasonable bounds [saleStart, saleEnd)
		require(saleStart <= t && t < saleEnd, "invalid time");

		// ensure `t` is in `[seqStart, seqEnd)` bounds; no price exists outside the bounds
		require(seqStart <= t && t < seqEnd, "invalid sequence");

		// verify the initial price is set (initialized) for the tier specified
		require(startPrices.length > tierId, "invalid tier");

		// convert `t` from "absolute" to "relative" (within a sequence)
		t -= seqStart;

		// apply the time flow quantum: make `t` multiple of quantum
		t /= timeFlowQuantum;
		t *= timeFlowQuantum;

		// calculate the price based on the derived params - delegate to `price`
		return price(startPrices[tierId], halvingTime, t);
	}

	/**
	 * @dev Calculates dutch auction price after the time of interest has passed since
	 *      the auction has started
	 *
	 * @dev The price is assumed to drop exponentially, according to formula:
	 *      p(t) = p0 * 2^(-t/t0)
	 *      The price halves every t0 seconds passed from the start of the auction
	 *
	 * @dev Calculates with the precision p0 * 2^(-1/256), meaning the price updates
	 *      every t0 / 256 seconds
	 *      For example, if halving time is one hour, the price updates every 14 seconds
	 *
	 * @param p0 initial price
	 * @param t0 price halving time
	 * @param t elapsed time
	 * @return price after `t` seconds passed, `p = p0 * 2^(-t/t0)`
	 */
	function price(uint256 p0, uint256 t0, uint256 t) public pure returns(uint256) {
		// perform very rough price estimation first by halving
		// the price as many times as many t0 intervals have passed
		uint256 p = p0 >> t / t0;

		// if price halves (decreases by 2 times) every t0 seconds passed,
		// than every t0 / 2 seconds passed it decreases by sqrt(2) times (2 ^ (1/2)),
		// every t0 / 2 seconds passed it decreases 2 ^ (1/4) times, and so on

		// we've prepared a small cheat sheet here with the pre-calculated values for
		// the roots of the degree of two 2 ^ (1 / 2 ^ n)
		// for the resulting function to be monotonically decreasing, it is required
		// that (2 ^ (1 / 2 ^ n)) ^ 2 <= 2 ^ (1 / 2 ^ (n - 1))
		// to emulate floating point values, we present them as nominator/denominator
		// roots of the degree of two nominators:
		uint56[8] memory sqrNominator = [
			1_414213562373095, // 2 ^ (1/2)
			1_189207115002721, // 2 ^ (1/4)
			1_090507732665257, // 2 ^ (1/8) *
			1_044273782427413, // 2 ^ (1/16) *
			1_021897148654116, // 2 ^ (1/32) *
			1_010889286051700, // 2 ^ (1/64)
			1_005429901112802, // 2 ^ (1/128) *
			1_002711275050202  // 2 ^ (1/256)
		];
		// roots of the degree of two denominator:
		uint56 sqrDenominator =
			1_000000000000000;

		// perform up to 8 iterations to increase the precision of the calculation
		// dividing the halving time `t0` by two on every step
		for(uint8 i = 0; i < sqrNominator.length && t > 0 && t0 > 1; i++) {
			// determine the reminder of `t` which requires the precision increase
			t %= t0;
			// halve the `t0` for the next iteration step
			t0 /= 2;
			// if elapsed time `t` is big enough and is "visible" with `t0` precision
			if(t >= t0) {
				// decrease the price accordingly to the roots of the degree of two table
				p = p * sqrDenominator / sqrNominator[i];
			}
			// if elapsed time `t` is big enough and is "visible" with `2 * t0` precision
			// (this is possible sometimes due to rounding errors when halving `t0`)
			if(t >= 2 * t0) {
				// decrease the price again accordingly to the roots of the degree of two table
				p = p * sqrDenominator / sqrNominator[i];
			}
		}

		// return the result
		return p;
	}

	/**
	 * @notice Sells a plot of land (Land ERC721 token) from the sale to executor.
	 *      Executor must supply the metadata for the land plot and a Merkle tree proof
	 *      for the metadata supplied.
	 *
	 * @notice Metadata for all the plots is stored off-chain and is publicly available
	 *      to buy plots and to generate Merkle proofs
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the plot data collection elements via `web3.utils.soliditySha3`, making sure
	 *         the packing order and types are exactly as defined in `PlotData` struct
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed collection, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given plot data element the proof is constructed by hashing it (as in step 1),
	 *         and querying the MerkleTree for a proof, providing the hashed plot data element as a leaf
	 *
	 * @dev Requires FEATURE_SALE_ACTIVE feature to be enabled
	 *
	 * @dev Throws if current time is outside the [saleStart, saleEnd) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @dev See also: https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
	 *
	 * @param plotData plot data to buy
	 * @param proof Merkle proof for the plot data supplied
	 */
	function buy(PlotData memory plotData, bytes32[] memory proof) public payable {
		// verify sale is in active state
		require(isFeatureEnabled(FEATURE_SALE_ACTIVE), "sale disabled");

		// check if sale is active (and initialized)
		require(isActive(), "inactive sale");

		// make sure plot data Merkle root was set (sale has something on sale)
		require(root != 0x00, "empty sale");

		// verify the plot supplied is a valid/registered plot
		require(isPlotValid(plotData, proof), "invalid plot");

		// process the payment, save the ETH/sILV lot prices
		uint256 pEth;
		uint256 pIlv;
		// a note on reentrancy: `_processPayment` may execute a fallback function on the smart contract buyer,
		// which would be the last execution statement inside `_processPayment`; this execution is reentrancy safe
		// not only because 2,300 transfer function is used, but primarily because all the "give" logic is executed after
		// external call, while the "withhold" logic is executed before the external call
		(pEth, pIlv) = _processPayment(plotData.sequenceId, plotData.tierId);

		// generate the random seed to derive internal land structure (landmark and sites)
		// hash the token ID, block timestamp and tx executor address to get a seed
		uint256 seed = uint256(keccak256(abi.encodePacked(plotData.tokenId, now32(), msg.sender)));

		// allocate the land plot metadata in memory (it will be used several times)
		LandLib.PlotStore memory plot = LandLib.PlotStore({
			regionId: plotData.regionId,
			x: plotData.x,
			y: plotData.y,
			tierId: plotData.tierId,
			size: plotData.size,
			// use generated seed to derive the Landmark Type ID, seed is considered "used" after that
			landmarkTypeId: LandLib.getLandmark(seed, plotData.tierId),
			elementSites: 3 * plotData.tierId,
			fuelSites: plotData.tierId < 2? plotData.tierId: 3 * (plotData.tierId - 1),
			version: 1,
			// store low 160 bits of the "used" seed in the plot structure
			seed: uint160(seed)
		});

		// mint the token with metadata - delegate to `mintWithMetadata`
		LandERC721Metadata(targetNftContract).mintWithMetadata(msg.sender, plotData.tokenId, plot);

		// emit an event
		emit PlotBought(msg.sender, plotData.tokenId, plotData.sequenceId, plot, pEth, pIlv);
	}

	/**
	 * @dev Charges tx executor in ETH/sILV, based on if ETH is supplied in the tx or not:
	 *      - if ETH is supplied, charges ETH only (throws if value supplied is not enough)
	 *      - if ETH is not supplied, charges sILV only (throws if sILV transfer fails)
	 *
	 * @dev Sends the change (for ETH payment - if any) back to transaction executor
	 *
	 * @dev Internal use only, throws on any payment failure
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 */
	function _processPayment(uint32 sequenceId, uint16 tierId) private returns(uint256 pEth, uint256 pIlv) {
		// determine current token price
		pEth = tokenPriceNow(sequenceId, tierId);

		// current land sale version doesn't support free tiers (ID: 0)
		require(pEth != 0, "unsupported tier");

		// if ETH is not supplied, try to process sILV payment
		if(msg.value == 0) {
			// convert price `p` to ILV/sILV
			pIlv = LandSaleOracle(priceOracle).ethToIlv(pEth);

			// verify sender sILV balance and allowance to improve error messaging
			// note: `transferFrom` would fail anyway, but sILV deployed into the mainnet
			//       would just fail with "arithmetic underflow" without any hint for the cause
			require(ERC20(sIlvContract).balanceOf(msg.sender) >= pIlv, "not enough funds available");
			require(ERC20(sIlvContract).allowance(msg.sender, address(this)) >= pIlv, "not enough funds supplied");

			// if beneficiary address is set, transfer the funds directly to the beneficiary
			// otherwise, transfer the funds to the sale contract for the future pull withdrawal
			// note: sILV.transferFrom always throws on failure and never returns `false`, however
			//       to keep this code "copy-paste safe" we do require it to return `true` explicitly
			require(ERC20(sIlvContract).transferFrom(msg.sender, beneficiary != address(0)? beneficiary: address(this), pIlv));

			// no need for the change processing here since we're taking the amount ourselves

			// return ETH price and sILV price actually charged
			return (pEth, pIlv);
		}

		// process ETH payment otherwise

		// ensure amount of ETH send
		require(msg.value >= pEth, "not enough ETH");

		// if beneficiary address is set
		if(beneficiary != address(0)) {
			// transfer the funds directly to the beneficiary
			// note: beneficiary cannot be a smart contract with complex fallback function
			//       by design, therefore we're using the 2,300 gas transfer
			beneficiary.transfer(pEth);
		}
		// if beneficiary address is not set, funds remain on
		// the sale contract address for the future pull withdrawal

		// if there is any change sent in the transaction
		// (most of the cases there will be a change since this is a dutch auction)
		if(msg.value > pEth) {
			// transfer the change back to the transaction executor (buyer)
			// note: calling the sale contract by other smart contracts with complex fallback functions
			//       is not supported by design, therefore we're using the 2,300 gas transfer
			payable(msg.sender).transfer(msg.value - pEth);
		}

		// return the ETH price charged
		return (pEth, 0);
	}

	/**
	 * @dev Testing time-dependent functionality may be difficult;
	 *      we override time in the helper test smart contract (mock)
	 *
	 * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
	 */
	function now32() public view virtual returns (uint32) {
		// return current block timestamp
		return uint32(block.timestamp);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/LandERC721Spec.sol";
import "../lib/LandLib.sol";
import "./RoyalERC721.sol";

/**
 * @title Land ERC721
 *
 * @notice Land ERC721 (a.k.a Land Plot, Land, or Land NFT) represents land plots in Illuvium: Zero (IZ).
 *      Each token is a piece of land (land plot) on the overall world map in IZ.
 *
 * @notice Land plot is uniquely identified by its region and coordinates (x, y) within the region.
 *      There can be only one plot with the given coordinates (x, y) in a given region.
 *
 * @notice Land plot has internal coordinate system used to place the structures (off-chain).
 *      Land plot may contain "sites" with the resources,
 *      a Landmark, increasing the resource production / decreasing resource losses,
 *      or a special type of Landmark - Arena, used to host tournaments.
 *      Sites are positioned on the plot and have their own coordinates (x, y) within a plot.
 *      Number of sites depends on the land plot rarity (tier).
 *      Landmark may exist only in the rare land plots (tier 3 or higher) and resides in the center of the plot.
 *
 * @notice Land plot does not contain details on the structures, these details are stored off-chain.
 *      The fundamental value of the Land is always drawn from the underlying Land NFT,
 *      which produces Fuel in the form of an ERC20 tokens.
 *
 * @notice Land plot metadata is immutable and includes (see `LandView` structure):
 *      - Region ID (1 - 7), determines which tileset to use in game,
 *      - Coordinates (x, y) on the overall world map, indicating which grid position the land sits in,
 *      - Tier ID (1 - 5), the rarity of the land, tier is used to create the list of sites,
 *      - Plot Size, defines an internal coordinate system within a plot,
 *      - Internal Land Structure
 *        - enumeration of sites, each site metadata including:
 *          - Type ID (1 - 6), defining the type of the site:
 *            1) Carbon,
 *            2) Silicon,
 *            3) Hydrogen,
 *            4) Crypton,
 *            5) Hyperion,
 *            6) Solon
 *          - Coordinates (x, y) on the land plot
 *        - Landmark Type ID:
 *            0) no Landmark,
 *            1) Carbon Landmark,
 *            2) Silicon Landmark,
 *            3) Hydrogen Landmark (Eternal Spring),
 *            4) Crypton Landmark,
 *            5) Hyperion Landmark,
 *            6) Solon Landmark (Fallen Star),
 *            7) Arena
 *
 * @notice Region ID, Coordinates (x, y), Tier ID, and Plot Size are stored as is, while Internal Land Structure
 *      is derived from Tier ID, Plot Size, and a Seed (see `LandStore` structure)
 *
 * @notice A note on Region, Coordinates (x, y), Tier, Plot Size, and Internal Land Structure.
 *      Land Plot smart contract stores Region, Coordinates (x, y), Tier, Plot Size, and Internal Land Structure
 *      as part of the land metadata on-chain, however the use of these values within the smart contract is limited.
 *      Effectively that means that helper smart contracts, backend, or frontend applications can, to some extent,
 *      treat these values at their own decision, may redefine, enrich, or ignore their meaning.
 *
 * @notice Land NFTs are minted by the trusted helper smart contract(s) (see `LandSale`), which are responsible
 *      for supplying the correct metadata.
 *      Land NFT contract itself doesn't store the Merkle root of the valid land metadata, and
 *      has a limited constraint validation for NFTs it mints/tracks, it guarantees:
 *         - (regionId, x, y) uniqueness
 *         - non-intersection of the sites coordinates within a plot
 *         - correspondence of the number of resource sites and their types to the land tier
 *         - correspondence of the landmark type to the land tier
 *
 * @dev Minting a token requires its metadata to be supplied before or during the minting process;
 *      Burning the token destroys its metadata;
 *      Metadata can be pre-allocated: it can be set/updated/removed for non-existing tokens, and
 *      once the token is minted, its metadata becomes "frozen" - immutable, it cannot be changed or removed.
 *
 * @notice Refer to "Illuvium: Zero" design documents for additional information about the game.
 *      Refer to "Illuvium Land Sale On-chain Architecture" for additional information about
 *      the technical design of the Land ERC721 token and Land Sale smart contracts and their interaction.
 *
 * @author Basil Gorin
 */
contract LandERC721 is RoyalERC721, LandERC721Metadata {
	// Use Land Library to generate Internal Land Structure, extract plot coordinates, etc.
	using LandLib for LandLib.PlotView;
	using LandLib for LandLib.PlotStore;

	/**
	 * @inheritdoc IdentifiableToken
	 */
	uint256 public constant override TOKEN_UID = 0x805d1eb685f9eaad4306ed05ef803361e9c0b3aef93774c4b118255ab3f9c7d1;

	/**
	 * @notice Metadata storage for tokens (land plots)
	 * @notice Accessible via `getMetadata(uint256)`
	 *
	 * @dev Maps token ID => token Metadata (PlotData struct)
	 */
	mapping(uint256 => LandLib.PlotStore) internal plots;

	/**
	 * @notice Auxiliary data structure tracking all the occupied land plot
	 *      locations, and used to guarantee the (regionId, x, y) uniqueness
	 *
	 * @dev Maps packed plot location (regionId, x, y) => token ID
	 */
	mapping(uint256 => uint256) public plotLocations;

	/**
	 * @notice Metadata provider is responsible for writing tokens' metadata
	 *      (for an arbitrary token - be it an existing token or non-existing one)
	 * @notice The limitation is that for an existing token its metadata can
	 *      be written only once, it is impossible to modify existing
	 *      token's metadata, its effectively immutable
	 *
	 * @dev Role ROLE_METADATA_PROVIDER allows writing tokens' metadata
	 *      (calling `setMetadata` function)
	 * @dev ROLE_TOKEN_CREATOR and ROLE_METADATA_PROVIDER roles are usually
	 *      used together, since the token should always be created with the
	 *      metadata supplied
	 */
	uint32 public constant ROLE_METADATA_PROVIDER = 0x0040_0000;

	/**
	 * @dev Fired in `setMetadata()` when token metadata is set/updated
	 *
	 * @param _tokenId token ID which metadata was updated/set
	 * @param _plot new token metadata
	 */
	event MetadataUpdated(uint256 indexed _tokenId, LandLib.PlotStore _plot);

	/**
	 * @dev Fired in `removeMetadata()` when token metadata is removed
	 *
	 * @param _tokenId token ID which metadata was removed
	 * @param _plot old token metadata (which was removed)
	 */
	event MetadataRemoved(uint256 indexed _tokenId, LandLib.PlotStore _plot);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * param _name token name (ERC721Metadata)
	 * param _symbol token symbol (ERC721Metadata)
	 * param _owner smart contract owner having full privileges
	 */
	function postConstruct() public virtual initializer {
		// execute all parent initializers in cascade
		RoyalERC721._postConstruct("Land", "LND", msg.sender);
	}

	/**
	 * @inheritdoc IERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		// calculate based on own and inherited interfaces
		return super.supportsInterface(interfaceId)
			|| interfaceId == type(LandERC721Metadata).interfaceId;
	}

	/**
	 * @notice Presents token metadata in a well readable form,
	 *      with the Internal Land Structure included, as a `PlotView` struct
	 *
	 * @notice Reconstructs the internal land structure of the plot based on the stored
	 *      Tier ID, Plot Size, Generator Version, and Seed
	 *
	 * @param _tokenId token ID to query metadata view for
	 * @return token metadata as a `PlotView` struct
	 */
	function viewMetadata(uint256 _tokenId) public view virtual override returns(LandLib.PlotView memory) {
		// use Land Library to convert internal representation into the Plot view
		return plots[_tokenId].plotView();
	}

	/**
	 * @notice Presents token metadata "as is", without the Internal Land Structure included,
	 *      as a `PlotStore` struct;
	 *
	 * @notice Doesn't reconstruct the internal land structure of the plot, allowing to
	 *      access Generator Version, and Seed fields "as is"
	 *
	 * @param _tokenId token ID to query on-chain metadata for
	 * @return token metadata as a `PlotStore` struct
	 */
	function getMetadata(uint256 _tokenId) public view override returns(LandLib.PlotStore memory) {
		// simply return the plot metadata as it is stored
		return plots[_tokenId];
	}

	/**
	 * @notice Verifies if token has its metadata set on-chain; for the tokens
	 *      in existence metadata is immutable, it can be set once, and not updated
	 *
	 * @dev If `exists(_tokenId) && hasMetadata(_tokenId)` is true, `setMetadata`
	 *      for such a `_tokenId` will always throw
	 *
	 * @param _tokenId token ID to check metadata existence for
	 * @return true if token ID specified has metadata associated with it
	 */
	function hasMetadata(uint256 _tokenId) public view virtual override returns(bool) {
		// determine plot existence based on its metadata stored
		return plots[_tokenId].seed != 0;
	}

	/**
	 * @dev Sets/updates token metadata on-chain; same metadata struct can be then
	 *      read back using `getMetadata()` function, or it can be converted to
	 *      `PlotView` using `viewMetadata()` function
	 *
	 * @dev The metadata supplied is validated to satisfy (regionId, x, y) uniqueness;
	 *      non-intersection of the sites coordinates within a plot is guaranteed by the
	 *      internal land structure generator algorithm embedded into the `viewMetadata()`
	 *
	 * @dev Metadata for non-existing tokens can be set and updated unlimited
	 *      amount of times without any restrictions (except the constraints above)
	 * @dev Metadata for an existing token can only be set, it cannot be updated
	 *      (`setMetadata` will throw if metadata already exists)
	 *
	 * @dev Requires executor to have ROLE_METADATA_PROVIDER permission
	 *
	 * @param _tokenId token ID to set/updated the metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function setMetadata(uint256 _tokenId, LandLib.PlotStore memory _plot) public virtual override {
		// verify the access permission
		require(isSenderInRole(ROLE_METADATA_PROVIDER), "access denied");

		// validate the metadata
		require(_plot.size >= 32, "too small");

		// metadata cannot be updated for existing token
		require(!exists(_tokenId), "token exists");

		// ensure the location of the plot is not yet taken
		require(plotLocations[_plot.loc()] == 0, "spot taken");

		// register the plot location
		plotLocations[_plot.loc()] = _tokenId;

		// write metadata into the storage
		plots[_tokenId] = _plot;

		// emit an event
		emit MetadataUpdated(_tokenId, _plot);
	}

	/**
	 * @dev Restricted access function to remove token metadata
	 *
	 * @dev Requires executor to have ROLE_METADATA_PROVIDER permission
	 *
	 * @param _tokenId token ID to remove metadata for
	 */
	function removeMetadata(uint256 _tokenId) public virtual override {
		// verify the access permission
		require(isSenderInRole(ROLE_METADATA_PROVIDER), "access denied");

		// remove token metadata - delegate to `_removeMetadata`
		_removeMetadata(_tokenId);
	}

	/**
	 * @dev Internal helper function to remove token metadata
	 *
	 * @param _tokenId token ID to remove metadata for
	 */
	function _removeMetadata(uint256 _tokenId) private {
		// verify token doesn't exist
		require(!exists(_tokenId), "token exists");

		// read the plot - it will be logged into event anyway
		LandLib.PlotStore memory _plot = plots[_tokenId];

		// erase token metadata
		delete plots[_tokenId];

		// unregister the plot location
		delete plotLocations[_plot.loc()];

		// emit an event first - to log the data which will be deleted
		emit MetadataRemoved(_tokenId, _plot);
	}

	/**
	 * @dev Restricted access function to mint the token
	 *      and assign the metadata supplied
	 *
	 * @dev Creates new token with the token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Consider minting with `safeMint` (and setting metadata before),
	 *      for the "safe mint" like behavior
	 *
	 * @dev Requires executor to have ROLE_METADATA_PROVIDER
	 *      and ROLE_TOKEN_CREATOR permissions
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId token ID to mint and set metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function mintWithMetadata(address _to, uint256 _tokenId, LandLib.PlotStore memory _plot) public virtual override {
		// simply create token metadata and mint it in the correct order:

		// 1. set the token metadata via `setMetadata`
		setMetadata(_tokenId, _plot);

		// 2. mint the token via `mint`
		mint(_to, _tokenId);
	}

	/**
	 * @inheritdoc UpgradeableERC721
	 *
	 * @dev Overridden function is required to ensure
	 *      - zero token ID is not minted
	 *      - token Metadata exists when minting
	 */
	function _mint(address _to, uint256 _tokenId) internal virtual override {
		// zero token ID is invalid (see `plotLocations` mapping)
		require(_tokenId != 0, "zero ID");

		// verify the metadata for the token already exists
		require(hasMetadata(_tokenId), "no metadata");

		// mint the token - delegate to `super._mint`
		super._mint(_to, _tokenId);
	}

	/**
	 * @inheritdoc UpgradeableERC721
	 *
	 * @dev Overridden function is required to erase token Metadata when burning
	 */
	function _burn(uint256 _tokenId) internal virtual override {
		// burn the token itself - delegate to `super._burn`
		super._burn(_tokenId);

		// remove token metadata - delegate to `_removeMetadata`
		_removeMetadata(_tokenId);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/EIP2981Spec.sol";
import "./UpgradeableERC721.sol";

/**
 * @title Royal ER721
 *
 * @dev Supports EIP-2981 royalties on NFT secondary sales
 *      Supports OpenSea contract metadata royalties
 *      Introduces fake "owner" to support OpenSea collections
 *
 * @author Basil Gorin
 */
abstract contract RoyalERC721 is EIP2981, UpgradeableERC721 {
	/**
	 * @dev OpenSea expects NFTs to be "Ownable", that is having an "owner",
	 *      we introduce a fake "owner" here with no authority
	 */
	address public owner;

	/**
	 * @notice Address to receive EIP-2981 royalties from secondary sales
	 *         see https://eips.ethereum.org/EIPS/eip-2981
	 */
	address public royaltyReceiver;

	/**
	 * @notice Percentage of token sale price to be used for EIP-2981 royalties from secondary sales
	 *         see https://eips.ethereum.org/EIPS/eip-2981
	 *
	 * @dev Has 2 decimal precision. E.g. a value of 500 would result in a 5% royalty fee
	 */
	uint16 public royaltyPercentage; // default OpenSea value is 750

	/**
	 * @notice Contract level metadata to define collection name, description, and royalty fees.
	 *         see https://docs.opensea.io/docs/contract-level-metadata
	 *
	 * @dev Should be set by URI manager, empty by default
	 */
	string public contractURI;

	/**
	 * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
	 *      the amount of storage used by a contract always adds up to the 50.
	 *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[47] private __gap;

	/**
	 * @notice Royalty manager is responsible for managing the EIP2981 royalty info
	 *
	 * @dev Role ROLE_ROYALTY_MANAGER allows updating the royalty information
	 *      (executing `setRoyaltyInfo` function)
	 */
	uint32 public constant ROLE_ROYALTY_MANAGER = 0x0010_0000;

	/**
	 * @notice Owner manager is responsible for setting/updating an "owner" field
	 *
	 * @dev Role ROLE_OWNER_MANAGER allows updating the "owner" field
	 *      (executing `setOwner` function)
	 */
	uint32 public constant ROLE_OWNER_MANAGER = 0x0020_0000;

	/**
	 * @dev Fired in setContractURI()
	 *
	 * @param _by an address which executed update
	 * @param _value new contractURI value
	 */
	event ContractURIUpdated(address indexed _by, string _value);

	/**
	 * @dev Fired in setRoyaltyInfo()
	 *
	 * @param _by an address which executed update
	 * @param _receiver new royaltyReceiver value
	 * @param _percentage new royaltyPercentage value
	 */
	event RoyaltyInfoUpdated(
		address indexed _by,
		address indexed _receiver,
		uint16 _percentage
	);

	/**
	 * @dev Fired in setOwner()
	 *
	 * @param _by an address which set the new "owner"
	 * @param _oldVal previous "owner" address
	 * @param _newVal new "owner" address
	 */
	event OwnerUpdated(address indexed _by, address indexed _oldVal, address indexed _newVal);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _name token name (ERC721Metadata)
	 * @param _symbol token symbol (ERC721Metadata)
	 * @param _owner smart contract owner having full privileges
	 */
	function _postConstruct(string memory _name, string memory _symbol, address _owner) internal virtual override initializer {
		// execute all parent initializers in cascade
		UpgradeableERC721._postConstruct(_name, _symbol, _owner);

		// initialize the "owner" as a deployer account
		owner = msg.sender;

		// contractURI is as an empty string by default (zero-length array)
		// contractURI = "";
	}

	/**
	 * @dev Restricted access function which updates the contract URI
	 *
	 * @dev Requires executor to have ROLE_URI_MANAGER permission
	 *
	 * @param _contractURI new contract URI to set
	 */
	function setContractURI(string memory _contractURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// update the contract URI
		contractURI = _contractURI;

		// emit an event first
		emit ContractURIUpdated(msg.sender, _contractURI);
	}

	/**
	 * @notice EIP-2981 function to calculate royalties for sales in secondary marketplaces.
	 *         see https://eips.ethereum.org/EIPS/eip-2981
	 *
	 * @inheritdoc EIP2981
	 */
	function royaltyInfo(
		uint256,
		uint256 _salePrice
	) external view virtual override returns (
		address receiver,
		uint256 royaltyAmount
	) {
		// simply calculate the values and return the result
		return (royaltyReceiver, _salePrice * royaltyPercentage / 100_00);
	}

	/**
	 * @dev Restricted access function which updates the royalty info
	 *
	 * @dev Requires executor to have ROLE_ROYALTY_MANAGER permission
	 *
	 * @param _royaltyReceiver new royalty receiver to set
	 * @param _royaltyPercentage new royalty percentage to set
	 */
	function setRoyaltyInfo(address _royaltyReceiver, uint16 _royaltyPercentage) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_ROYALTY_MANAGER), "access denied");

		// verify royalty percentage is zero if receiver is also zero
		require(_royaltyReceiver != address(0) || _royaltyPercentage == 0, "invalid receiver");

		// update the values
		royaltyReceiver = _royaltyReceiver;
		royaltyPercentage = _royaltyPercentage;

		// emit an event first
		emit RoyaltyInfoUpdated(msg.sender, _royaltyReceiver, _royaltyPercentage);

	}

	/**
	 * @notice Checks if the address supplied is an "owner" of the smart contract
	 *      Note: an "owner" doesn't have any authority on the smart contract and is "nominal"
	 *
	 * @return true if the caller is the current owner.
	 */
	function isOwner(address _addr) public view virtual returns(bool) {
		// just evaluate and return the result
		return _addr == owner;
	}

	/**
	 * @dev Restricted access function to set smart contract "owner"
	 *      Note: an "owner" set doesn't have any authority, and cannot even update "owner"
	 *
	 * @dev Requires executor to have ROLE_OWNER_MANAGER permission
	 *
	 * @param _owner new "owner" of the smart contract
	 */
	function transferOwnership(address _owner) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_OWNER_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit OwnerUpdated(msg.sender, owner, _owner);

		// update "owner"
		owner = _owner;
	}

	/**
	 * @inheritdoc IERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, UpgradeableERC721) returns (bool) {
		// construct the interface support from EIP-2981 and super interfaces
		return interfaceId == type(EIP2981).interfaceId || super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC20Spec.sol";
import "../interfaces/ERC721SpecExt.sol";
import "../interfaces/IdentifiableSpec.sol";
import "../utils/UpgradeableAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/**
 * @title Upgradeable ERC721 Implementation
 *
 * @notice Zeppelin based ERC721 implementation, supporting token enumeration
 *      (ERC721EnumerableUpgradeable) and flexible token URI management (ERC721URIStorageUpgradeable)
 *
 * // TODO: consider allowing to override each individual token URI
 *
 * @dev Based on Zeppelin ERC721EnumerableUpgradeable and ERC721URIStorageUpgradeable with some modifications
 *      to tokenURI function
 *
 * @author Basil Gorin
 */
abstract contract UpgradeableERC721 is IdentifiableToken, MintableERC721, BurnableERC721, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, UpgradeableAccessControl {
	/**
	 * @dev Base URI is used to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 *
	 * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
	 */
	string public baseURI;

	/**
	 * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
	 *      the amount of storage used by a contract always adds up to the 50.
	 *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;

	/**
	 * @notice Enables ERC721 transfers of the tokens
	 *      (transfer by the token owner himself)
	 * @dev Feature FEATURE_TRANSFERS must be enabled in order for
	 *      `transferFrom()` function to succeed when executed by token owner
	 */
	uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

	/**
	 * @notice Enables ERC721 transfers on behalf
	 *      (transfer by someone else on behalf of token owner)
	 * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
	 *      `transferFrom()` function to succeed whe executed by approved operator
	 * @dev Token owner must call `approve()` or `setApprovalForAll()`
	 *      first to authorize the transfer on behalf
	 */
	uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

	/**
	 * @notice Enables token owners to burn their own tokens
	 *
	 * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
	 *      `burn()` function to succeed when called by token owner
	 */
	uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

	/**
	 * @notice Enables approved operators to burn tokens on behalf of their owners
	 *
	 * @dev Feature FEATURE_BURNS_ON_BEHALF must be enabled in order for
	 *      `burn()` function to succeed when called by approved operator
	 */
	uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (calling `mint` function)
	 */
	uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

	/**
	 * @notice Token destroyer is responsible for destroying (burning)
	 *      tokens owned by an arbitrary address
	 * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
	 *      (calling `burn` function)
	 */
	uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      part of the token URI ERC721Metadata interface
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0004_0000;

	/**
	 * @notice People do mistakes and may send ERC20 tokens by mistake; since
	 *      NFT smart contract is not designed to accept and hold any ERC20 tokens,
	 *      it allows the rescue manager to "rescue" such lost tokens
	 *
	 * @notice Rescue manager is responsible for "rescuing" ERC20 tokens accidentally
	 *      sent to the smart contract
	 *
	 * @dev Role ROLE_RESCUE_MANAGER allows withdrawing any ERC20 tokens stored
	 *      on the smart contract balance
	 */
	uint32 public constant ROLE_RESCUE_MANAGER = 0x0008_0000;

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string oldVal, string newVal);

	/**
	 * @dev Fired in setTokenURI()
	 *
	 * @param _by an address which executed update
	 * @param tokenId token ID which URI was updated
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event TokenURIUpdated(address indexed _by, uint256 tokenId, string oldVal, string newVal);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _name token name (ERC721Metadata)
	 * @param _symbol token symbol (ERC721Metadata)
	 * @param _owner smart contract owner having full privileges
	 */
	function _postConstruct(string memory _name, string memory _symbol, address _owner) internal virtual initializer {
		// execute all parent initializers in cascade
		__ERC721_init(_name, _symbol);
		__ERC721Enumerable_init_unchained();
		__ERC721URIStorage_init_unchained();
		UpgradeableAccessControl._postConstruct(_owner);

		// initialize self
		baseURI = "";
	}

	/**
	 * @inheritdoc IERC165Upgradeable
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
		// calculate based on own and inherited interfaces
		return ERC721EnumerableUpgradeable.supportsInterface(interfaceId)
			|| interfaceId == type(MintableERC721).interfaceId
			|| interfaceId == type(BurnableERC721).interfaceId;
	}

	/**
	 * @dev Restricted access function which updates base URI used to construct
	 *      ERC721Metadata.tokenURI
	 *
	 * @dev Requires executor to have ROLE_URI_MANAGER permission
	 *
	 * @param __baseURI new base URI to set
	 */
	function setBaseURI(string memory __baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, __baseURI);

		// and update base URI
		baseURI = __baseURI;
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		// just return stored public value to support Zeppelin impl
		return baseURI;
	}

	/**
	 * @dev Sets the token URI for the token defined by its ID
	 *
	 * @param _tokenId an ID of the token to set URI for
	 * @param _tokenURI token URI to set
	 */
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// we do not verify token existence: we want to be able to
		// preallocate token URIs before tokens are actually minted

		// emit an event first - to log both old and new values
		emit TokenURIUpdated(msg.sender, _tokenId, "zeppelin", _tokenURI);

		// and update token URI - delegate to ERC721URIStorage
		_setTokenURI(_tokenId, _tokenURI);
	}

	/**
	 * @inheritdoc ERC721URIStorageUpgradeable
	 */
	function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual override {
		// delegate to ERC721URIStorage impl
		return super._setTokenURI(_tokenId, _tokenURI);
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function tokenURI(uint256 _tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
		// delegate to ERC721URIStorage impl
		return ERC721URIStorageUpgradeable.tokenURI(_tokenId);
	}

	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) public view virtual override returns(bool) {
		// delegate to super implementation
		return _exists(_tokenId);
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) public virtual override {
		// mint token - delegate to `_mint`
		_mint(_to, _tokenId);
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) public virtual override {
		// mint token safely - delegate to `_safeMint`
		_safeMint(_to, _tokenId, _data);
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) public virtual override {
		// mint token safely - delegate to `_safeMint`
		_safeMint(_to, _tokenId);
	}

	/**
	 * @dev Destroys the token with token ID specified
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
	 *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
	 *
	 * @dev Can be disabled by the contract creator forever by disabling
	 *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
	 *      its own roles to burn tokens and to enable burning features
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) public virtual override {
		// burn token - delegate to `_burn`
		_burn(_tokenId);
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function _mint(address _to, uint256 _tokenId) internal virtual override {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// delegate to super implementation
		super._mint(_to, _tokenId);
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function _burn(uint256 _tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
		// read token owner data
		// verifies token exists under the hood
		address _from = ownerOf(_tokenId);

		// check if caller has sufficient permissions to burn tokens
		// and if not - check for possibility to burn own tokens or to burn on behalf
		if(!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
			// if `_from` is equal to sender, require own burns feature to be enabled
			// otherwise require burns on behalf feature to be enabled
			require(_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)
				   || _from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF),
				      _from == msg.sender? "burns are disabled": "burns on behalf are disabled");

			// verify sender is either token owner, or approved by the token owner to burn tokens
			require(_from == msg.sender || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender), "access denied");
		}

		// delegate to the super implementation with URI burning
		ERC721URIStorageUpgradeable._burn(_tokenId);
	}

	/**
	 * @inheritdoc ERC721Upgradeable
	 */
	function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
		// for transfers only - verify if transfers are enabled
		require(_from == address(0) || _to == address(0) // won't affect minting/burning
			   || _from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)
			   || _from != msg.sender && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF),
			      _from == msg.sender? "transfers are disabled": "transfers on behalf are disabled");

		// delegate to ERC721Enumerable impl
		ERC721EnumerableUpgradeable._beforeTokenTransfer(_from, _to, _tokenId);
	}

	/**
	 * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
	 *      the tokens are rescued via `transfer` function call on the
	 *      contract address specified and with the parameters specified:
	 *      `_contract.transfer(_to, _value)`
	 *
	 * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
	 *
	 * @param _contract smart contract address to execute `transfer` function on
	 * @param _to to address in `transfer(_to, _value)`
	 * @param _value value to transfer in `transfer(_to, _value)`
	 */
	function rescueErc20(address _contract, address _to, uint256 _value) public {
		// verify the access permission
		require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

		// perform the transfer as requested, without any checks
		ERC20(_contract).transfer(_to, _value);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if a specific operation is permitted globally and/or
 *      if a particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable public functions
 *      of the smart contract (used by a wide audience).
 * @notice User roles are designed to control the access to restricted functions
 *      of the smart contract (used by a limited set of maintainers).
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @author Basil Gorin
 */
abstract contract AccessControl {
	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,  setting the contract owner to have full privileges
	 *
	 * @param _owner smart contract owner having full privileges
	 */
	constructor(address _owner) {
		// contract creator has full privileges
		userRoles[_owner] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Upgradeable Access Control List // ERC1967Proxy
 *
 * @notice Access control smart contract provides an API to check
 *      if a specific operation is permitted globally and/or
 *      if a particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable public functions
 *      of the smart contract (used by a wide audience).
 * @notice User roles are designed to control the access to restricted functions
 *      of the smart contract (used by a limited set of maintainers).
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @dev This is an upgradeable version of the ACL, based on Zeppelin implementation for ERC1967,
 *      see https://docs.openzeppelin.com/contracts/4.x/upgradeable
 *      see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable
 *      see https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
 *
 * @author Basil Gorin
 */
abstract contract UpgradeableAccessControl is UUPSUpgradeable {
	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
	 *      the amount of storage used by a contract always adds up to the 50.
	 *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;

	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @notice Upgrade manager is responsible for smart contract upgrades,
	 *      see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable
	 *      see https://docs.openzeppelin.com/contracts/4.x/upgradeable
	 *
	 * @dev Role ROLE_UPGRADE_MANAGER allows passing the _authorizeUpgrade() check
	 * @dev Role ROLE_UPGRADE_MANAGER has single bit at position 254 enabled
	 */
	uint256 public constant ROLE_UPGRADE_MANAGER = 0x4000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @dev UUPS initializer, sets the contract owner to have full privileges
	 *
	 * @param _owner smart contract owner having full privileges
	 */
	function _postConstruct(address _owner) internal virtual initializer {
		// grant owner full privileges
		userRoles[_owner] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Returns an address of the implementation smart contract,
	 *      see ERC1967Upgrade._getImplementation()
	 *
	 * @return the current implementation address
	 */
	function getImplementation() public view virtual returns(address) {
		// delegate to `ERC1967Upgrade._getImplementation()`
		return _getImplementation();
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}

	/**
	 * @inheritdoc UUPSUpgradeable
	 */
	function _authorizeUpgrade(address) internal virtual override {
		// caller must have a permission to upgrade the contract
		require(isSenderInRole(ROLE_UPGRADE_MANAGER), "access denied");
	}
}