// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../access/PermitControl.sol";
import "../../proxy/StubProxyRegistry.sol";
import "../../libraries/DFStorage.sol";
import "./interfaces/ISuper1155.sol";

/**
  @title An ERC-1155 item creation contract.
  @author Tim Clancy
  @author Qazawat Zirak
  @author Rostislav Khlebnikov
  @author Nikita Elunin

  This contract represents the NFTs within a single collection. It allows for a
  designated collection owner address to manage the creation of NFTs within this
  collection. The collection owner grants approval to or removes approval from
  other addresses governing their ability to mint NFTs from this collection.

  This contract is forked from the inherited OpenZeppelin dependency, and uses
  ideas from the original ERC-1155 reference implementation.

  July 19th, 2021.
*/
contract Super1155 is
    PermitControl,
    ERC165Storage,
    IERC1155,
    IERC1155MetadataURI
{
    using Address for address;

    uint256 MAX_INT = type(uint256).max;

    /// The public identifier for the right to set this contract's metadata URI.
    bytes32 public constant SET_URI = keccak256("SET_URI");

    /// The public identifier for the right to set this contract's proxy registry.
    bytes32 public constant SET_PROXY_REGISTRY =
        keccak256("SET_PROXY_REGISTRY");

    /// The public identifier for the right to configure item groups.
    bytes32 public constant CONFIGURE_GROUP = keccak256("CONFIGURE_GROUP");

    /// The public identifier for the right to mint items.
    bytes32 public constant MINT = keccak256("MINT");

    /// The public identifier for the right to burn items.
    bytes32 public constant BURN = keccak256("BURN");

    /// The public identifier for the right to set item metadata.
    bytes32 public constant SET_METADATA = keccak256("SET_METADATA");

    /// The public identifier for the right to lock the metadata URI.
    bytes32 public constant LOCK_URI = keccak256("LOCK_URI");

    /// The public identifier for the right to lock an item's metadata.
    bytes32 public constant LOCK_ITEM_URI = keccak256("LOCK_ITEM_URI");

    /// The public identifier for the right to disable item creation.
    bytes32 public constant LOCK_CREATION = keccak256("LOCK_CREATION");

    /// The public identifier for the right to update transfer state.
    bytes32 public constant TRANSFER_LOCK = keccak256("TRANSFER_LOCK");

    /// @dev Supply the magic number for the required ERC-1155 interface.
    bytes4 private constant INTERFACE_ERC1155 = 0xd9b67a26;

    /// @dev Supply the magic number for the required ERC-1155 metadata extension.
    bytes4 private constant INTERFACE_ERC1155_METADATA_URI = 0x0e89341c;

    /// @dev A mask for isolating an item's group ID.
    uint256 private constant GROUP_MASK = uint256(type(uint128).max) << 128;

    /// The public name of this contract.
    string public name;

    /// Variable that is needed to lock the transfers.
    bool transferLocked = true;

    /**
    The ERC-1155 URI for tracking item metadata, supporting {id} substitution.
    For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
    more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
  */
    string public metadataUri;

    /// The URI for the storefront-level metadata of contract
    string public contractURI;

    /// A proxy registry address for supporting automatic delegated approval.
    address public proxyRegistryAddress;

    /// @dev A mapping from each token ID to per-address balances.
    mapping(uint256 => mapping(address => uint256)) private balances;

    /// A mapping from each group ID to per-address balances.
    mapping(uint256 => mapping(address => uint256)) public groupBalances;

    /// A mapping from each address to a collection-wide balance.
    mapping(address => uint256) public totalBalances;

    /**
    @dev This is a mapping from each address to per-address operator approvals.
    Operators are those addresses that have been approved to transfer tokens on
    behalf of the approver. Transferring tokens includes the right to burn
    tokens.
  */
    mapping(address => mapping(address => bool)) private operatorApprovals;

    /**
    This struct defines the settings for a particular item group and is tracked
    in storage.

    @param initialized Whether or not this `ItemGroup` has been initialized.
    @param name A name for the item group.
    @param supplyType The supply type for this group of items.
    @param supplyData An optional integer used by some `supplyType` values.
    @param itemType The type of item represented by this item group.
    @param itemData An optional integer used by some `itemType` values.
    @param burnType The type of burning permitted by this item group.
    @param burnData An optional integer used by some `burnType` values.
    @param circulatingSupply The number of individual items within this group in
      circulation.
    @param mintCount The number of times items in this group have been minted.
    @param burnCount The number of times items in this group have been burnt.
  */
    struct ItemGroup {
        uint256 burnData;
        uint256 circulatingSupply;
        uint256 mintCount;
        uint256 burnCount;
        uint256 supplyData;
        uint256 itemData;
        bool initialized;
        DFStorage.SupplyType supplyType;
        DFStorage.ItemType itemType;
        DFStorage.BurnType burnType;
        string name;
    }

    /// A mapping of data for each item group.
    mapping(uint256 => ItemGroup) public itemGroups;

    /// A mapping of circulating supplies for each individual token.
    mapping(uint256 => uint256) public circulatingSupply;

    /// A mapping of the number of times each individual token has been minted.
    mapping(uint256 => uint256) public mintCount;

    /// A mapping of the number of times each individual token has been burnt.
    mapping(uint256 => uint256) public burnCount;

    /**
    A mapping of token ID to a boolean representing whether the item's metadata
    has been explicitly frozen via a call to `lockURI(string calldata _uri,
    uint256 _id)`. Do note that it is possible for an item's mapping here to be
    false while still having frozen metadata if the item collection as a whole
    has had its `uriLocked` value set to true.
  */
    mapping(uint256 => bool) public metadataFrozen;

    /**
    A public mapping of optional on-chain metadata for each token ID. A token's
    on-chain metadata is unable to be changed if the item's metadata URI has
    been permanently fixed or if the collection's metadata URI as a whole has
    been frozen.
  */
    mapping(uint256 => string) public metadata;

    /// Whether or not the metadata URI has been locked to future changes.
    bool public uriLocked;

    /// Whether or not the contract URI has been locked to future changes.
    bool public contractUriLocked;

    /// Whether or not the item collection has been locked to all further minting.
    bool public locked;

    /**
    An event that gets emitted when the metadata collection URI is changed.

    @param oldURI The old metadata URI.
    @param newURI The new metadata URI.
  */
    event ChangeURI(string indexed oldURI, string indexed newURI);

    /**
    An event that gets emitted when the proxy registry address is changed.

    @param oldRegistry The old proxy registry address.
    @param newRegistry The new proxy registry address.
  */
    event ChangeProxyRegistry(
        address indexed oldRegistry,
        address indexed newRegistry
    );

    /**
    An event that gets emitted when an item group is configured.

    @param manager The caller who configured the item group `_groupId`.
    @param groupId The groupId being configured.
    @param newGroup The new group configuration.
  */
    event ItemGroupConfigured(
        address indexed manager,
        uint256 groupId,
        DFStorage.ItemGroupInput indexed newGroup
    );

    /**
    An event that gets emitted when the item collection is locked to further
    creation.

    @param locker The caller who locked the collection.
  */
    event CollectionLocked(address indexed locker);

    /**
    An event that gets emitted when a token ID has its on-chain metadata
    changed.

    @param changer The caller who triggered the metadata change.
    @param id The ID of the token which had its metadata changed.
    @param oldMetadata The old metadata of the token.
    @param newMetadata The new metadata of the token.
  */
    event MetadataChanged(
        address indexed changer,
        uint256 indexed id,
        string oldMetadata,
        string indexed newMetadata
    );

    /**
    An event that indicates we have set a permanent metadata URI for a token.

    @param _value The value of the permanent metadata URI.
    @param _id The token ID associated with the permanent metadata value.
  */
    event PermanentURI(string _value, uint256 indexed _id);

    /**
    An event that emmited when the contract URI is changed

    @param oldURI The old contract URI
    @param newURI The new contract URI
   */
    event ChangeContractURI(string indexed oldURI, string indexed newURI);

    /**
    An event that indicates we have set a permanent contract URI.

    @param _value The value of the permanent contract URI.
    @param _id The token ID associated with the permanent metadata value.
  */
    event PermanentContractURI(string _value, uint256 indexed _id);

    /**
    A modifier needed to control transfers during and after the auction.
  */
    modifier transferLock() {
        require(!transferLocked, "Super1155: Transfer is currently locked.");
        _;
    }

    /**
    Construct a new ERC-1155 item collection.

    @param _name The name to assign to this item collection contract.
    @param _metadataURI The metadata URI to perform later token ID substitution with.
    @param _contractURI The contract URI.
    @param _proxyRegistryAddress The address of a proxy registry contract.
  */
    constructor(
        address _owner,
        string memory _name,
        string memory _metadataURI,
        string memory _contractURI,
        address _proxyRegistryAddress
    ) {
        // Register the ERC-165 interfaces.
        _registerInterface(INTERFACE_ERC1155);
        _registerInterface(INTERFACE_ERC1155_METADATA_URI);

        setPermit(_msgSender(), UNIVERSAL, CONFIGURE_GROUP, MAX_INT);

        if (_owner != owner()) {
            transferOwnership(_owner);
        }
        // Continue initialization.
        name = _name;
        metadataUri = _metadataURI;
        contractURI = _contractURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
    Return a version number for this contract's interface.
  */
    function version() external pure virtual override returns (uint256) {
        return 1;
    }

    /**
    Return the item collection's metadata URI. This implementation returns the
    same URI for all tokens within the collection and relies on client-side
    ID substitution per https://eips.ethereum.org/EIPS/eip-1155#metadata. Per
    said specification, clients calling this function must replace the {id}
    substring with the actual token ID in hex, not prefixed by 0x, and padded
    to 64 characters in length.

    @return The metadata URI string of the item with ID `_itemId`.
  */
    function uri(uint256) external view returns (string memory) {
        return metadataUri;
    }

    /**
    Allow the item collection owner or an approved manager to update the
    metadata URI of this collection. This implementation relies on a single URI
    for all items within the collection, and as such does not emit the standard
    URI event. Instead, we emit our own event to reflect changes in the URI.

    @param _uri The new URI to update to.
  */
    function setURI(string calldata _uri)
        external
        virtual
        hasValidPermit(UNIVERSAL, SET_URI)
    {
        require(
            !uriLocked,
            "Super1155: the collection URI has been permanently locked"
        );
        string memory oldURI = metadataUri;
        metadataUri = _uri;
        emit ChangeURI(oldURI, _uri);
    }

    /**
    Allow the item collection owner or an associated manager to update transfer state.
  */
    function unlockTransfer()
        external
        hasValidPermit(UNIVERSAL, TRANSFER_LOCK)
    {
        transferLocked = false;
    }

    /**
    Allow approved manager to update the contract URI. At the end of update, we 
    emit our own event to reflect changes in the URI.

    @param _uri The new contract URI to update to.
  */
    function setContractUri(string calldata _uri)
        external
        virtual
        hasValidPermit(UNIVERSAL, SET_URI)
    {
        require(
            !contractUriLocked,
            "Super1155: the contract URI has been permanently locked"
        );
        string memory oldContractUri = contractURI;
        contractURI = _uri;
        emit ChangeContractURI(oldContractUri, _uri);
    }

    /**
    Allow the item collection owner or an approved manager to update the proxy
    registry address handling delegated approval.

    @param _proxyRegistryAddress The address of the new proxy registry to
      update to.
  */
    function setProxyRegistry(address _proxyRegistryAddress)
        external
        virtual
        hasValidPermit(UNIVERSAL, SET_PROXY_REGISTRY)
    {
        address oldRegistry = proxyRegistryAddress;
        proxyRegistryAddress = _proxyRegistryAddress;
        emit ChangeProxyRegistry(oldRegistry, _proxyRegistryAddress);
    }

    /**
    Retrieve the balance of a particular token `_id` for a particular address
    `_owner`.

    @param _owner The owner to check for this token balance.
    @param _id The ID of the token to check for a balance.
    @return The amount of token `_id` owned by `_owner`.
  */
    function balanceOf(address _owner, uint256 _id)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            _owner != address(0),
            "ERC1155: balance query for the zero address"
        );
        return balances[_id][_owner];
    }

    /**
    Retrieve in a single call the balances of some mulitple particular token
    `_ids` held by corresponding `_owners`.

    @param _owners The owners to check for token balances.
    @param _ids The IDs of tokens to check for balances.
    @return the amount of each token owned by each owner.
  */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        require(
            _owners.length == _ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        // Populate and return an array of balances.
        uint256[] memory batchBalances = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            batchBalances[i] = balanceOf(_owners[i], _ids[i]);
        }
        return batchBalances;
    }

    /**
    This function returns true if `_operator` is approved to transfer items
    owned by `_owner`. This approval check features an override to explicitly
    whitelist any addresses delegated in the proxy registry.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
    @return Whether `_operator` may transfer items owned by `_owner`.
  */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        returns (bool)
    {
        if (
            StubProxyRegistry(proxyRegistryAddress).proxies(_owner) == _operator
        ) {
            return true;
        }

        // We did not find an explicit whitelist in the proxy registry.
        return operatorApprovals[_owner][_operator];
    }

    /**
    Enable or disable approval for a third party `_operator` address to manage
    (transfer or burn) all of the caller's tokens.

    @param _operator The address to grant management rights over all of the
      caller's tokens.
    @param _approved The status of the `_operator`'s approval for the caller.
  */
    function setApprovalForAll(address _operator, bool _approved)
        external
        virtual
    {
        require(
            _msgSender() != _operator,
            "ERC1155: setting approval status for self"
        );
        operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    /**
    This private helper function converts a number into a single-element array.

    @param _element The element to convert to an array.
    @return The array containing the single `_element`.
  */
    function _asSingletonArray(uint256 _element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = _element;
        return array;
    }

    /**
    An inheritable and configurable pre-transfer hook that can be overridden.
    It fires before any token transfer, including mints and burns.

    @param _operator The caller who triggers the token transfer.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual {}

    /**
    ERC-1155 dictates that any contract which wishes to receive ERC-1155 tokens
    must explicitly designate itself as such. This function checks for such
    designation to prevent undesirable token transfers.

    @param _operator The caller who triggers the token transfer.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _amount The amount of the specific `_id` to transfer.
    @param _data Additional call data to send with this transfer.
  */
    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) private {
        if (_to.isContract()) {
            try
                IERC1155Receiver(_to).onERC1155Received(
                    _operator,
                    _from,
                    _id,
                    _amount,
                    _data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(_to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    /**
    The batch equivalent of `_doSafeTransferAcceptanceCheck()`.

    @param _operator The caller who triggers the token transfer.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) private {
        if (_to.isContract()) {
            try
                IERC1155Receiver(_to).onERC1155BatchReceived(
                    _operator,
                    _from,
                    _ids,
                    _amounts,
                    _data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(_to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual transferLock {
        require(
            _ids.length == _amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(_to != address(0), "ERC1155: transfer to the zero address");
        require(
            _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        // Validate transfer and perform all batch token sends.
        _beforeTokenTransfer(_msgSender(), _from, _to, _ids, _amounts, _data);
        for (uint256 i = 0; i < _ids.length; ++i) {
            // Retrieve the item's group ID.
            uint256 groupId = (_ids[i] & GROUP_MASK) >> 128;

            // Update all specially-tracked group-specific balances.
            require(
                balances[_ids[i]][_from] >= _amounts[i],
                "ERC1155: insufficient balance for transfer"
            );
            balances[_ids[i]][_from] = balances[_ids[i]][_from] - _amounts[i];
            balances[_ids[i]][_to] = balances[_ids[i]][_to] + _amounts[i];
            groupBalances[groupId][_from] =
                groupBalances[groupId][_from] -
                _amounts[i];
            groupBalances[groupId][_to] =
                groupBalances[groupId][_to] +
                _amounts[i];
            totalBalances[_from] = totalBalances[_from] - _amounts[i];
            totalBalances[_to] = totalBalances[_to] + _amounts[i];
        }

        // Emit the transfer event and perform the safety check.
        emit TransferBatch(_msgSender(), _from, _to, _ids, _amounts);
        _doSafeBatchTransferAcceptanceCheck(
            _msgSender(),
            _from,
            _to,
            _ids,
            _amounts,
            _data
        );
    }

    /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _amount The amount of the specific `_id` to transfer.
    @param _data Additional call data to send with this transfer.
  */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external virtual {
        safeBatchTransferFrom(
            _from,
            _to,
            _asSingletonArray(_id),
            _asSingletonArray(_amount),
            _data
        );
    }

    /**
    Create a new NFT item group or configure an existing one. NFTs within a
    group share a group ID in the upper 128-bits of their full item ID.
    Within a group NFTs can be distinguished for the purposes of serializing
    issue numbers.

    @param _groupId The ID of the item group to create or configure.
    @param _data The `ItemGroup` data input.
  */
    function configureGroup(
        uint256 _groupId,
        DFStorage.ItemGroupInput calldata _data
    ) external {
        require(_groupId != 0, "Super1155: group ID 0 is invalid");
        require(
            _hasItemRight(_groupId, CONFIGURE_GROUP),
            "Super1155: you don't have rights to configure group"
        );

        // If the collection is not locked, we may add a new item group.
        if (!itemGroups[_groupId].initialized) {
            require(
                !locked,
                "Super1155: the collection is locked so groups cannot be created"
            );
            itemGroups[_groupId] = ItemGroup({
                initialized: true,
                name: _data.name,
                supplyType: _data.supplyType,
                supplyData: _data.supplyData,
                itemType: _data.itemType,
                itemData: _data.itemData,
                burnType: _data.burnType,
                burnData: _data.burnData,
                circulatingSupply: 0,
                mintCount: 0,
                burnCount: 0
            });

            // Edit an existing item group. The name may always be updated.
        } else {
            itemGroups[_groupId].name = _data.name;

            // A capped supply type may not change.
            // It may also not have its cap increased.
            if (
                itemGroups[_groupId].supplyType == DFStorage.SupplyType.Capped
            ) {
                require(
                    _data.supplyType == DFStorage.SupplyType.Capped,
                    "Super1155: you may not uncap a capped supply type"
                );
                require(
                    _data.supplyData <= itemGroups[_groupId].supplyData,
                    "Super1155: you may not increase the supply of a capped type"
                );

                // The flexible and uncapped types may freely change.
            } else {
                itemGroups[_groupId].supplyType = _data.supplyType;
            }

            // Item supply data may not be reduced below the circulating supply.
            require(
                _data.supplyData >= itemGroups[_groupId].circulatingSupply,
                "Super1155: you may not decrease supply below the circulating amount"
            );
            itemGroups[_groupId].supplyData = _data.supplyData;

            // A nonfungible item may not change type.
            if (
                itemGroups[_groupId].itemType == DFStorage.ItemType.Nonfungible
            ) {
                require(
                    _data.itemType == DFStorage.ItemType.Nonfungible,
                    "Super1155: you may not alter nonfungible items"
                );

                // A semifungible item may not change type.
            } else if (
                itemGroups[_groupId].itemType == DFStorage.ItemType.Semifungible
            ) {
                require(
                    _data.itemType == DFStorage.ItemType.Semifungible,
                    "Super1155: you may not alter nonfungible items"
                );

                // A fungible item may change type if it is unique enough.
            } else if (
                itemGroups[_groupId].itemType == DFStorage.ItemType.Fungible
            ) {
                if (_data.itemType == DFStorage.ItemType.Nonfungible) {
                    require(
                        itemGroups[_groupId].circulatingSupply <= 1,
                        "Super1155: the fungible item is not unique enough to change"
                    );
                    itemGroups[_groupId].itemType = DFStorage
                        .ItemType
                        .Nonfungible;

                    // We may also try for semifungible items with a high-enough cap.
                } else if (_data.itemType == DFStorage.ItemType.Semifungible) {
                    require(
                        itemGroups[_groupId].circulatingSupply <=
                            _data.itemData,
                        "Super1155: the fungible item is not unique enough to change"
                    );
                    itemGroups[_groupId].itemType = DFStorage
                        .ItemType
                        .Semifungible;
                    itemGroups[_groupId].itemData = _data.itemData;
                }
            }
        }

        // Emit the configuration event.
        emit ItemGroupConfigured(_msgSender(), _groupId, _data);
    }

    /**
    This is a private helper function to replace the `hasItemRight` modifier
    that we use on some functions in order to inline this check during batch
    minting and burning.

    @param _id The ID of the item to check for the given `_right` on.
    @param _right The right that the caller is trying to exercise on `_id`.
    @return Whether or not the caller has a valid right on this item.
  */
    function _hasItemRight(uint256 _id, bytes32 _right)
        private
        view
        returns (bool)
    {
        uint256 groupId = _id >> 128;
        if (_msgSender() == owner()) {
            return true;
        }
        if (hasRight(_msgSender(), UNIVERSAL, _right)) {
            return true;
        }
        if (hasRight(_msgSender(), bytes32(groupId), _right)) {
            return true;
        }
        if (hasRight(_msgSender(), bytes32(_id), _right)) {
            return true;
        }
        return false;
    }

    /**
    This is a private helper function to verify, according to all of our various
    minting and burning rules, whether it would be valid to mint some `_amount`
    of a particular item `_id`.

    @param _id The ID of the item to check for minting validity.
    @param _amount The amount of the item to try checking mintability for.
    @return The ID of the item that should have `_amount` minted for it.
  */
    function _mintChecker(uint256 _id, uint256 _amount)
        private
        view
        returns (uint256)
    {
        // Retrieve the item's group ID.
        uint256 shiftedGroupId = (_id & GROUP_MASK);
        uint256 groupId = shiftedGroupId >> 128;
        require(
            itemGroups[groupId].initialized,
            "Super1155: you cannot mint a non-existent item group"
        );

        // If we can replenish burnt items, then only our currently-circulating
        // supply matters. Otherwise, historic mints are what determine the cap.
        uint256 currentGroupSupply = itemGroups[groupId].mintCount;
        uint256 currentItemSupply = mintCount[_id];
        if (itemGroups[groupId].burnType == DFStorage.BurnType.Replenishable) {
            currentGroupSupply = itemGroups[groupId].circulatingSupply;
            currentItemSupply = circulatingSupply[_id];
        }

        // If we are subject to a cap on group size, ensure we don't exceed it.
        if (itemGroups[groupId].supplyType != DFStorage.SupplyType.Uncapped) {
            require(
                (currentGroupSupply + _amount) <=
                    itemGroups[groupId].supplyData,
                "Super1155: you cannot mint a group beyond its cap"
            );
        }

        // Do not violate nonfungibility rules.
        if (itemGroups[groupId].itemType == DFStorage.ItemType.Nonfungible) {
            require(
                (currentItemSupply + _amount) <= 1,
                "Super1155: you cannot mint more than a single nonfungible item"
            );

            // Do not violate semifungibility rules.
        } else if (
            itemGroups[groupId].itemType == DFStorage.ItemType.Semifungible
        ) {
            require(
                (currentItemSupply + _amount) <= itemGroups[groupId].itemData,
                "Super1155: you cannot mint more than the alloted semifungible items"
            );
        }

        // Fungible items are coerced into the single group ID + index one slot.
        uint256 mintedItemId = _id;
        if (itemGroups[groupId].itemType == DFStorage.ItemType.Fungible) {
            mintedItemId = shiftedGroupId + 1;
        }
        return mintedItemId;
    }

    /**
    Mint a batch of tokens into existence and send them to the `_recipient`
    address. In order to mint an item, its item group must first have been
    created. Minting an item must obey both the fungibility and size cap of its
    group.

    @param _recipient The address to receive all NFTs within the newly-minted
      group.
    @param _ids The item IDs for the new items to create.
    @param _amounts The amount of each corresponding item ID to create.
    @param _data Any associated data to use on items minted in this transaction.
  */
    function mintBatch(
        address _recipient,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external {
        require(_recipient != address(0), "ERC1155: mint to the zero address");
        require(
            _ids.length == _amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        // Validate and perform the mint.
        address operator = _msgSender();
        _beforeTokenTransfer(
            operator,
            address(0),
            _recipient,
            _ids,
            _amounts,
            _data
        );

        // Loop through each of the batched IDs to update storage of special
        // balances and circulation balances.
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _hasItemRight(_ids[i], MINT),
                "Super1155: you do not have the right to mint that item"
            );

            // Retrieve the group ID from the given item `_id` and check mint.
            uint256 groupId = _ids[i] >> 128;
            uint256 mintedItemId = _mintChecker(_ids[i], _amounts[i]);

            // Update storage of special balances and circulating values.
            balances[mintedItemId][_recipient] =
                balances[mintedItemId][_recipient] +
                _amounts[i];
            groupBalances[groupId][_recipient] =
                groupBalances[groupId][_recipient] +
                _amounts[i];
            totalBalances[_recipient] = totalBalances[_recipient] + _amounts[i];
            mintCount[mintedItemId] = mintCount[mintedItemId] + _amounts[i];
            circulatingSupply[mintedItemId] =
                circulatingSupply[mintedItemId] +
                _amounts[i];
            itemGroups[groupId].mintCount =
                itemGroups[groupId].mintCount +
                _amounts[i];
            itemGroups[groupId].circulatingSupply =
                itemGroups[groupId].circulatingSupply +
                _amounts[i];
        }

        // Emit event and handle the safety check.
        emit TransferBatch(operator, address(0), _recipient, _ids, _amounts);
        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            _recipient,
            _ids,
            _amounts,
            _data
        );
    }

    /**
    This is a private helper function to verify, according to all of our various
    minting and burning rules, whether it would be valid to burn some `_amount`
    of a particular item `_id`.

    @param _id The ID of the item to check for burning validity.
    @param _amount The amount of the item to try checking burning for.
    @return The ID of the item that should have `_amount` burnt for it.
  */
    function _burnChecker(uint256 _id, uint256 _amount)
        private
        view
        returns (uint256)
    {
        // Retrieve the item's group ID.
        uint256 shiftedGroupId = (_id & GROUP_MASK);
        uint256 groupId = shiftedGroupId >> 128;
        require(
            itemGroups[groupId].initialized,
            "Super1155: you cannot burn a non-existent item group"
        );

        // If the item group is non-burnable, then revert.
        if (itemGroups[groupId].burnType == DFStorage.BurnType.None) {
            revert("Super1155: you cannot burn a non-burnable item group");
        }

        // If we can burn items, then we must verify that we do not exceed the cap.
        if (itemGroups[groupId].burnType == DFStorage.BurnType.Burnable) {
            require(
                (itemGroups[groupId].burnCount + _amount) <=
                    itemGroups[groupId].burnData,
                "Super1155: you may not exceed the burn limit on this item group"
            );
        }

        // Fungible items are coerced into the single group ID + index one slot.
        uint256 burntItemId = _id;
        if (itemGroups[groupId].itemType == DFStorage.ItemType.Fungible) {
            burntItemId = shiftedGroupId + 1;
        }
        return burntItemId;
    }

    /**
    This function allows an address to destroy multiple different items in a
    single call.

    @param _burner The address whose items are burning.
    @param _ids The item IDs to burn.
    @param _amounts The amounts of the corresponding item IDs to burn.
  */
    function burnBatch(
        address _burner,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public virtual {
        require(_burner != address(0), "ERC1155: burn from the zero address");
        require(
            _ids.length == _amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        // Validate and perform the burn.
        address operator = _msgSender();
        _beforeTokenTransfer(operator, _burner, address(0), _ids, _amounts, "");

        // Loop through each of the batched IDs to update storage of special
        // balances and circulation balances.
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _hasItemRight(_ids[i], BURN),
                "Super1155: you do not have the right to burn that item"
            );

            // Retrieve the group ID from the given item `_id` and check burn.
            uint256 groupId = _ids[i] >> 128;
            uint256 burntItemId = _burnChecker(_ids[i], _amounts[i]);

            // Update storage of special balances and circulating values.
            require(
                balances[burntItemId][_burner] >= _amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
            balances[burntItemId][_burner] =
                balances[burntItemId][_burner] -
                _amounts[i];
            groupBalances[groupId][_burner] =
                groupBalances[groupId][_burner] -
                _amounts[i];
            totalBalances[_burner] = totalBalances[_burner] - _amounts[i];
            burnCount[burntItemId] = burnCount[burntItemId] + _amounts[i];
            circulatingSupply[burntItemId] =
                circulatingSupply[burntItemId] -
                _amounts[i];
            itemGroups[groupId].burnCount =
                itemGroups[groupId].burnCount +
                _amounts[i];
            itemGroups[groupId].circulatingSupply =
                itemGroups[groupId].circulatingSupply -
                _amounts[i];
        }

        // Emit the burn event.
        emit TransferBatch(operator, _burner, address(0), _ids, _amounts);
    }

    /**
    This function allows an address to destroy some of its items.

    @param _burner The address whose item is burning.
    @param _id The item ID to burn.
    @param _amount The amount of the corresponding item ID to burn.
  */
    function burn(
        address _burner,
        uint256 _id,
        uint256 _amount
    ) external virtual {
        require(
            _hasItemRight(_id, BURN),
            "Super1155: you don't have rights to burn"
        );
        burnBatch(_burner, _asSingletonArray(_id), _asSingletonArray(_amount));
    }

    /**
    Set the on-chain metadata attached to a specific token ID so long as the
    collection as a whole or the token specifically has not had metadata
    editing frozen.

    @param _id The ID of the token to set the `_metadata` for.
    @param _metadata The metadata string to store on-chain.
  */
    function setMetadata(uint256 _id, string memory _metadata) external {
        require(
            _hasItemRight(_id, SET_METADATA),
            "Super1155: you don't have rights to setMetadata"
        );
        uint256 groupId = _id >> 128;
        require(
            !uriLocked && !metadataFrozen[_id] && !metadataFrozen[groupId],
            "Super1155: you cannot edit this metadata because it is frozen"
        );
        string memory oldMetadata = metadata[_id];
        metadata[_id] = _metadata;
        emit MetadataChanged(_msgSender(), _id, oldMetadata, _metadata);
    }

    /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on the entire collection to future changes.
  */
    function lockURI() external hasValidPermit(UNIVERSAL, LOCK_URI) {
        uriLocked = true;
        emit PermanentURI(metadataUri, 2**256 - 1);
    }

    /** 
    Allow the associated manager to forever lock the contract URI to future 
    changes
  */
    function lockContractUri() external hasValidPermit(UNIVERSAL, LOCK_URI) {
        contractUriLocked = true;
        emit PermanentContractURI(contractURI, 2**256 - 1);
    }

    /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on an item to future changes.

    @param _uri The value of the URI to lock for `_id`.
    @param _id The token ID to lock a metadata URI value into.
  */
    function lockURI(string calldata _uri, uint256 _id) external {
        require(
            _hasItemRight(_id, LOCK_ITEM_URI),
            "Super1155: you don't have rights to lock URI"
        );
        metadataFrozen[_id] = true;
        emit PermanentURI(_uri, _id);
    }

    /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on a group of items to future changes.

    @param _uri The value of the URI to lock for `groupId`.
    @param groupId The group ID to lock a metadata URI value into.
  */
    function lockGroupURI(string calldata _uri, uint256 groupId) external {
        require(
            _hasItemRight(groupId, LOCK_ITEM_URI),
            "Super1155: you don't have rights to lock group URI"
        );
        metadataFrozen[groupId] = true;
        emit PermanentURI(_uri, groupId);
    }

    /**
    Allow the item collection owner or an associated manager to forever lock
    this contract to further item minting.
  */
    function lock() external virtual hasValidPermit(UNIVERSAL, LOCK_CREATION) {
        locked = true;
        emit CollectionLocked(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
  @title An advanced permission-management contract.
  @author Tim Clancy

  This contract allows for a contract owner to delegate specific rights to
  external addresses. Additionally, these rights can be gated behind certain
  sets of circumstances and granted expiration times. This is useful for some
  more finely-grained access control in contracts.

  The owner of this contract is always a fully-permissioned super-administrator.

  August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
  using Address for address;

  /// A special reserved constant for representing no rights.
  bytes32 public constant ZERO_RIGHT = hex"00000000000000000000000000000000";

  /// A special constant specifying the unique, universal-rights circumstance.
  bytes32 public constant UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /*
    A special constant specifying the unique manager right. This right allows an
    address to freely-manipulate the `managedRight` mapping.
  **/
  bytes32 public constant MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /**
    A mapping of per-address permissions to the circumstances, represented as
    an additional layer of generic bytes32 data, under which the addresses have
    various permits. A permit in this sense is represented by a per-circumstance
    mapping which couples some right, represented as a generic bytes32, to an
    expiration time wherein the right may no longer be exercised. An expiration
    time of 0 indicates that there is in fact no permit for the specified
    address to exercise the specified right under the specified circumstance.

    @dev Universal rights MUST be stored under the 0xFFFFFFFFFFFFFFFFFFFFFFFF...
    max-integer circumstance. Perpetual rights may be given an expiry time of
    max-integer.
  */
  mapping( address => mapping( bytes32 => mapping( bytes32 => uint256 )))
    public permissions;

  /**
    An additional mapping of managed rights to manager rights. This mapping
    represents the administrator relationship that various rights have with one
    another. An address with a manager right may freely set permits for that
    manager right's managed rights. Each right may be managed by only one other
    right.
  */
  mapping( bytes32 => bytes32 ) public managerRight;

  /**
    An event emitted when an address has a permit updated. This event captures,
    through its various parameter combinations, the cases of granting a permit,
    updating the expiration time of a permit, or revoking a permit.

    @param updator The address which has updated the permit.
    @param updatee The address whose permit was updated.
    @param circumstance The circumstance wherein the permit was updated.
    @param role The role which was updated.
    @param expirationTime The time when the permit expires.
  */
  event PermitUpdated(
    address indexed updator,
    address indexed updatee,
    bytes32 circumstance,
    bytes32 indexed role,
    uint256 expirationTime
  );

//   /**
//     A version of PermitUpdated for work with setPermits() function.
    
//     @param updator The address which has updated the permit.
//     @param updatees The addresses whose permit were updated.
//     @param circumstances The circumstances wherein the permits were updated.
//     @param roles The roles which were updated.
//     @param expirationTimes The times when the permits expire.
//   */
//   event PermitsUpdated(
//     address indexed updator,
//     address[] indexed updatees,
//     bytes32[] circumstances,
//     bytes32[] indexed roles,
//     uint256[] expirationTimes
//   );

  /**
    An event emitted when a management relationship in `managerRight` is
    updated. This event captures adding and revoking management permissions via
    observing the update history of the `managerRight` value.

    @param manager The address of the manager performing this update.
    @param managedRight The right which had its manager updated.
    @param managerRight The new manager right which was updated to.
  */
  event ManagementUpdated(
    address indexed manager,
    bytes32 indexed managedRight,
    bytes32 indexed managerRight
  );

  /**
    A modifier which allows only the super-administrative owner or addresses
    with a specified valid right to perform a call.

    @param _circumstance The circumstance under which to check for the validity
      of the specified `right`.
    @param _right The right to validate for the calling address. It must be
      non-expired and exist within the specified `_circumstance`.
  */
  modifier hasValidPermit(
    bytes32 _circumstance,
    bytes32 _right
  ) {
    require(_msgSender() == owner()
      || hasRight(_msgSender(), _circumstance, _right),
      "P1");
    _;
  }

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual pure returns (uint256) {
    return 1;
  }

  /**
    Determine whether or not an address has some rights under the given
    circumstance, and if they do have the right, until when.

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return The timestamp in seconds when the `_right` expires. If the timestamp
      is zero, we can assume that the user never had the right.
  */
  function hasRightUntil(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (uint256) {
    return permissions[_address][_circumstance][_right];
  }

   /**
    Determine whether or not an address has some rights under the given
    circumstance,

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return true or false, whether user has rights and time is valid.
  */
  function hasRight(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (bool) {
    return permissions[_address][_circumstance][_right] > block.timestamp;
  }

  /**
    Set the permit to a specific address under some circumstances. A permit may
    only be set by the super-administrative contract owner or an address holding
    some delegated management permit.

    @param _address The address to assign the specified `_right` to.
    @param _circumstance The circumstance in which the `_right` is valid.
    @param _right The specific right to assign.
    @param _expirationTime The time when the `_right` expires for the provided
      `_circumstance`.
  */
  function setPermit(
    address _address,
    bytes32 _circumstance,
    bytes32 _right,
    uint256 _expirationTime
  ) public virtual hasValidPermit(UNIVERSAL, managerRight[_right]) {
    require(_right != ZERO_RIGHT,
      "P2");
    permissions[_address][_circumstance][_right] = _expirationTime;
    emit PermitUpdated(_msgSender(), _address, _circumstance, _right,
      _expirationTime);
  }

//   /**
//     Version of setPermit() that works with multiple addresses in one transaction.

//     @param _addresses The array of addresses to assign the specified `_right` to.
//     @param _circumstances The array of circumstances in which the `_right` is 
//                           valid.
//     @param _rights The array of specific rights to assign.
//     @param _expirationTimes The array of times when the `_rights` expires for 
//                             the provided _circumstance`.
//   */
//   function setPermits(
//     address[] memory _addresses,
//     bytes32[] memory _circumstances, 
//     bytes32[] memory _rights, 
//     uint256[] memory _expirationTimes
//   ) public virtual {
//     require((_addresses.length == _circumstances.length)
//              && (_circumstances.length == _rights.length)
//              && (_rights.length == _expirationTimes.length),
//              "leghts of input arrays are not equal"
//     );
//     bytes32 lastRight;
//     for(uint i = 0; i < _rights.length; i++) {
//       if (lastRight != _rights[i] || (i == 0)) { 
//         require(_msgSender() == owner() || hasRight(_msgSender(), _circumstances[i], _rights[i]), "P1");
//         require(_rights[i] != ZERO_RIGHT, "P2");
//         lastRight = _rights[i];
//       }
//       permissions[_addresses[i]][_circumstances[i]][_rights[i]] = _expirationTimes[i];
//     }
//     emit PermitsUpdated(
//       _msgSender(), 
//       _addresses,
//       _circumstances,
//       _rights,
//       _expirationTimes
//     );
//   }

  /**
    Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
    specified `_managedRight`.

    @param _managedRight The right which is to have its manager set to
      `_managerRight`.
    @param _managerRight The right whose `UNIVERSAL` holders may manage
      `_managedRight`.
  */
  function setManagerRight(
    bytes32 _managedRight,
    bytes32 _managerRight
  ) external virtual hasValidPermit(UNIVERSAL, MANAGER) {
    require(_managedRight != ZERO_RIGHT,
      "P3");
    managerRight[_managedRight] = _managerRight;
    emit ManagementUpdated(_msgSender(), _managedRight, _managerRight);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/**
  @title A proxy registry contract.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.
*/
abstract contract StubProxyRegistry {

  /**
    This mapping relates an addresses to its own personal `OwnableDelegateProxy`
    which allow it to proxy functionality to the various callers contained in
    `authorizedCallers`.
  */
  mapping(address => address) public proxies;
}

pragma solidity ^0.8.8;

library DFStorage {
    /**
    @notice This struct is a source of mapping-free input to the `addPool` function.

    @param name A name for the pool.
    @param startTime The timestamp when this pool begins allowing purchases.
    @param endTime The timestamp after which this pool disallows purchases.
    @param purchaseLimit The maximum number of items a single address may
      purchase from this pool.
    @param singlePurchaseLimit The maximum number of items a single address may
      purchase from this pool in a single transaction.
    @param requirement A PoolRequirement requisite for users who want to
      participate in this pool.
  */
    struct PoolInput {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 purchaseLimit;
        uint256 singlePurchaseLimit;
        address collection;
    }

    /**
    @notice This struct tracks information about a prerequisite for a user to
    participate in a pool.

    /**
    @notice This enumeration type specifies the different assets that may be used to
    complete purchases from this mint shop.

    @param Point This specifies that the asset being used to complete
      this purchase is non-transferrable points from a `Staker` contract.
    @param Ether This specifies that the asset being used to complete
      this purchase is native Ether currency.
    @param Token This specifies that the asset being used to complete
      this purchase is an ERC-20 token.
  */
    enum AssetType {
        Ether,
        Token
    }

    /**
    @notice This struct tracks information about a single asset with the associated
    price that an item is being sold in the shop for. It also includes an
    `asset` field which is used to convey optional additional data about the
    asset being used to purchase with.

    @param assetType The `AssetType` type of the asset being used to buy.
    @param asset Some more specific information about the asset to charge in.
     If the `assetType` is Point, we use this address to find the specific
     Staker whose points are used as the currency.
     If the `assetType` is Ether, we ignore this field.
     If the `assetType` is Token, we use this address to find the
     ERC-20 token that we should be specifically charging with.
    @param price The amount of the specified `assetType` and `asset` to charge.
  */
    struct Price {
        AssetType assetType;
        address asset;
        uint256 startPrice;
        uint256 finalPrice;
        uint256 priceDeductionRate;
        // uint256 reducingEnd;
        // uint256 priceReducePeriod;
        // uint256 priceReduceStep;
    }
  /**
    This enumeration lists the various supply types that each item group may
    use. In general, the administrator of this collection or those permissioned
    to do so may move from a more-permissive supply type to a less-permissive.
    For example: an uncapped or flexible supply type may be converted to a
    capped supply type. A capped supply type may not be uncapped later, however.

    @param Capped There exists a fixed cap on the size of the item group. The
      cap is set by `supplyData`.
    @param Uncapped There is no cap on the size of the item group. The value of
      `supplyData` cannot be set below the current circulating supply but is
      otherwise ignored.
    @param Flexible There is a cap which can be raised or lowered (down to
      circulating supply) freely. The value of `supplyData` cannot be set below
      the current circulating supply and determines the cap.
  */
  enum SupplyType {
    Capped,
    Uncapped,
    Flexible
  }

  /**
    This enumeration lists the various item types that each item group may use.
    In general, these are static once chosen.

    @param Nonfungible The item group is truly nonfungible where each ID may be
      used only once. The value of `itemData` is ignored.
    @param Fungible The item group is truly fungible and collapses into a single
      ID. The value of `itemData` is ignored.
    @param Semifungible The item group may be broken up across multiple
      repeating token IDs. The value of `itemData` is the cap of any single
      token ID in the item group.
  */
  enum ItemType {
    Nonfungible,
    Fungible,
    Semifungible
  }

  /**
    This enumeration lists the various burn types that each item group may use.
    These are static once chosen.

    @param None The items in this group may not be burnt. The value of
      `burnData` is ignored.
    @param Burnable The items in this group may be burnt. The value of
      `burnData` is the maximum that may be burnt.
    @param Replenishable The items in this group, once burnt, may be reminted by
      the owner. The value of `burnData` is ignored.
  */
  enum BurnType {
    None,
    Burnable,
    Replenishable
  }

  /**
    This struct is a source of mapping-free input to the `configureGroup`
    function. It defines the settings for a particular item group.
   
    @param supplyData An optional integer used by some `supplyType` values.
    @param itemData An optional integer used by some `itemType` values.
    @param burnData An optional integer used by some `burnType` values.
    @param name A name for the item group.
    @param supplyType The supply type for this group of items.
    @param itemType The type of item represented by this item group.
    @param burnType The type of burning permitted by this item group.
    
  */
  struct ItemGroupInput {
    uint256 supplyData;
    uint256 itemData;
    uint256 burnData;
    SupplyType supplyType;
    ItemType itemType;
    BurnType burnType;
    string name;
  }


  /**
    This structure is used at the moment of NFT purchase.
    @param whiteListId Id of a whiteList.
    @param index Element index in the original array
    @param allowance The quantity is available to the user for purchase.
    @param node Base hash of the element.
    @param merkleProof Proof that the user is on the whitelist.
  */
  struct WhiteListInput {
    uint256 whiteListId;
    uint256 index; 
    uint256 allowance;
    bytes32 node; 
    bytes32[] merkleProof;
  }


  /**
    This structure is used at the moment of NFT purchase.
    @param _accesslistId Id of a whiteList.
    @param _merkleRoot Hash root of merkle tree.
    @param _startTime The start date of the whitelist
    @param _endTime The end date of the whitelist
    @param _price The price that applies to the whitelist
    @param _token Token with which the purchase will be made
  */
  struct WhiteListCreate {
    uint256 _accesslistId;
    bytes32 _merkleRoot;
    uint256 _startTime; 
    uint256 _endTime; 
    uint256 _price; 
    address _token;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "../../../libraries/DFStorage.sol";

/**
  @title An interface for the `Super1155` ERC-1155 item collection contract.
  @author 0xthrpw
  @author Tim Clancy

  August 12th, 2021.
*/
interface ISuper1155 {

  /// The public identifier for the right to set this contract's metadata URI.
  function SET_URI () external view returns (bytes32);

  /// The public identifier for the right to set this contract's proxy registry.
  function SET_PROXY_REGISTRY () external view returns (bytes32);

  /// The public identifier for the right to configure item groups.
  function CONFIGURE_GROUP () external view returns (bytes32);

  /// The public identifier for the right to mint items.
  function MINT () external view returns (bytes32);

  /// The public identifier for the right to burn items.
  function BURN () external view returns (bytes32);

  /// The public identifier for the right to set item metadata.
  function SET_METADATA () external view returns (bytes32);

  /// The public identifier for the right to lock the metadata URI.
  function LOCK_URI () external view returns (bytes32);

  /// The public identifier for the right to lock an item's metadata.
  function LOCK_ITEM_URI () external view returns (bytes32);

  /// The public identifier for the right to disable item creation.
  function LOCK_CREATION () external view returns (bytes32);

  /// The public name of this contract.
  function name () external view returns (string memory);

  /**
    The ERC-1155 URI for tracking item metadata, supporting {id} substitution.
    For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
    more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
  */
  function metadataUri () external view returns (string memory);

  /// A proxy registry address for supporting automatic delegated approval.
  function proxyRegistryAddress () external view returns (address);

  /// A mapping from each group ID to per-address balances.
  function groupBalances (uint256, address) external view returns (uint256);

  /// A mapping from each address to a collection-wide balance.
  function totalBalances (address) external view returns (uint256);

  /// A mapping of data for each item group.
  // function itemGroups (uint256) external view returns (ItemGroup memory);
  /* function itemGroups (uint256) external view returns (bool initialized, string memory _name, uint8 supplyType, uint256 supplyData, uint8 itemType, uint256 itemData, uint8 burnType, uint256 burnData, uint256 _circulatingSupply, uint256 _mintCount, uint256 _burnCount); */

  /// A mapping of circulating supplies for each individual token.
  function circulatingSupply (uint256) external view returns (uint256);

  /// A mapping of the number of times each individual token has been minted.
  function mintCount (uint256) external view returns (uint256);

  /// A mapping of the number of times each individual token has been burnt.
  function burnCount (uint256) external view returns (uint256);

  /**
    A mapping of token ID to a boolean representing whether the item's metadata
    has been explicitly frozen via a call to `lockURI(string calldata _uri,
    uint256 _id)`. Do note that it is possible for an item's mapping here to be
    false while still having frozen metadata if the item collection as a whole
    has had its `uriLocked` value set to true.
  */
  function metadataFrozen (uint256) external view returns (bool);

  /**
    A public mapping of optional on-chain metadata for each token ID. A token's
    on-chain metadata is unable to be changed if the item's metadata URI has
    been permanently fixed or if the collection's metadata URI as a whole has
    been frozen.
  */
  function metadata (uint256) external view returns (string memory);

  /// Whether or not the metadata URI has been locked to future changes.
  function uriLocked () external view returns (bool);

  /// Whether or not the item collection has been locked to all further minting.
  function locked () external view returns (bool);

  /**
    Return a version number for this contract's interface.
  */
  function version () external view returns (uint256);

  /**
    Return the item collection's metadata URI. This implementation returns the
    same URI for all tokens within the collection and relies on client-side
    ID substitution per https://eips.ethereum.org/EIPS/eip-1155#metadata. Per
    said specification, clients calling this function must replace the {id}
    substring with the actual token ID in hex, not prefixed by 0x, and padded
    to 64 characters in length.

    @return The metadata URI string of the item with ID `_itemId`.
  */
  function uri (uint256) external view returns (string memory);

  /**
    Allow the item collection owner or an approved manager to update the
    metadata URI of this collection. This implementation relies on a single URI
    for all items within the collection, and as such does not emit the standard
    URI event. Instead, we emit our own event to reflect changes in the URI.

    @param _uri The new URI to update to.
  */
  function setURI (string memory _uri) external;

  /**
    Allow the item collection owner or an approved manager to update the proxy
    registry address handling delegated approval.

    @param _proxyRegistryAddress The address of the new proxy registry to
      update to.
  */
  function setProxyRegistry (address _proxyRegistryAddress) external;

  /**
    Retrieve the balance of a particular token `_id` for a particular address
    `_owner`.

    @param _owner The owner to check for this token balance.
    @param _id The ID of the token to check for a balance.
    @return The amount of token `_id` owned by `_owner`.
  */
  function balanceOf (address _owner, uint256 _id) external view returns (uint256);

  /**
    Retrieve in a single call the balances of some mulitple particular token
    `_ids` held by corresponding `_owners`.

    @param _owners The owners to check for token balances.
    @param _ids The IDs of tokens to check for balances.
    @return the amount of each token owned by each owner.
  */
  function balanceOfBatch (address[] memory _owners, uint256[] memory _ids) external view returns (uint256[] memory);

  /**
    This function returns true if `_operator` is approved to transfer items
    owned by `_owner`. This approval check features an override to explicitly
    whitelist any addresses delegated in the proxy registry.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
    @return Whether `_operator` may transfer items owned by `_owner`.
  */
  function isApprovedForAll (address _owner, address _operator) external view returns (bool);

  /**
    Enable or disable approval for a third party `_operator` address to manage
    (transfer or burn) all of the caller's tokens.

    @param _operator The address to grant management rights over all of the
      caller's tokens.
    @param _approved The status of the `_operator`'s approval for the caller.
  */
  function setApprovalForAll (address _operator, bool _approved) external;

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _amount The amount of the specific `_id` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeTransferFrom (address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external;

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeBatchTransferFrom (address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

  /**
    Create a new NFT item group or configure an existing one. NFTs within a
    group share a group ID in the upper 128-bits of their full item ID.
    Within a group NFTs can be distinguished for the purposes of serializing
    issue numbers.

    @param _groupId The ID of the item group to create or configure.
    @param _data The `ItemGroup` data input.
  */
  function configureGroup (uint256 _groupId, DFStorage.ItemGroupInput calldata _data) external;

  /**
    Mint a batch of tokens into existence and send them to the `_recipient`
    address. In order to mint an item, its item group must first have been
    created. Minting an item must obey both the fungibility and size cap of its
    group.

    @param _recipient The address to receive all NFTs within the newly-minted
      group.
    @param _ids The item IDs for the new items to create.
    @param _amounts The amount of each corresponding item ID to create.
    @param _data Any associated data to use on items minted in this transaction.
  */
  function mintBatch (address _recipient, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

  /**
    This function allows an address to destroy some of its items.

    @param _burner The address whose item is burning.
    @param _id The item ID to burn.
    @param _amount The amount of the corresponding item ID to burn.
  */
  function burn (address _burner, uint256 _id, uint256 _amount) external;

  /**
    This function allows an address to destroy multiple different items in a
    single call.

    @param _burner The address whose items are burning.
    @param _ids The item IDs to burn.
    @param _amounts The amounts of the corresponding item IDs to burn.
  */
  function burnBatch (address _burner, uint256[] memory _ids, uint256[] memory _amounts) external;

  /**
    Set the on-chain metadata attached to a specific token ID so long as the
    collection as a whole or the token specifically has not had metadata
    editing frozen.

    @param _id The ID of the token to set the `_metadata` for.
    @param _metadata The metadata string to store on-chain.
  */
  function setMetadata (uint256 _id, string memory _metadata) external;

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on the entire collection to future changes.

    @param _uri The value of the URI to lock for `_id`.
  */
  function lockURI(string calldata _uri) external;

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on an item to future changes.

    @param _uri The value of the URI to lock for `_id`.
    @param _id The token ID to lock a metadata URI value into.
  */
  function lockURI(string calldata _uri, uint256 _id) external;


  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on a group of items to future changes.

    @param _uri The value of the URI to lock for `groupId`.
    @param groupId The group ID to lock a metadata URI value into.
  */
  function lockGroupURI(string calldata _uri, uint256 groupId) external;

  /**
    Allow the item collection owner or an associated manager to forever lock
    this contract to further item minting.
  */
  function lock() external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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