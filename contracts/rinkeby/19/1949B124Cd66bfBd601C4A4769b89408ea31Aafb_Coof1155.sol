// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./access/PermitControl.sol";
import "./proxy/StubProxyRegistry.sol";
import "./OnChainMeta.sol";

interface IVaxx {
  function vaccinate() external;
  function balanceOf ( address _owner, uint256 _id ) external view returns ( uint256 );
}

/**
  @title An ERC-1155 item creation contract.
  @author Tim Clancy
  @author 0xthrpw

  November 13th, 2021.
*/
contract Coof1155 is PermitControl, OnChainMeta, ERC165, IERC1155, IERC1155MetadataURI {
  using Address for address;
  using SafeMath for uint256;

  /// @dev Supply the magic number for the required ERC-1155 interface.
  bytes4 private constant INTERFACE_ERC1155 = 0xd9b67a26;

  /// @dev Supply the magic number for the required ERC-1155 metadata extension.
  bytes4 private constant INTERFACE_ERC1155_METADATA_URI = 0x0e89341c;

  /// @dev A mask for isolating an item's group ID.
  uint256 private constant GROUP_MASK = uint256(uint128(~0)) << 128;

  /// The public name of this contract.
  string public name;

  /**
    The ERC-1155 URI for tracking item metadata, supporting {id} substitution.
    For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
    more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
  */
  //string public metadataUri;

  /// A proxy registry address for supporting automatic delegated approval.
  address public proxyRegistryAddress;

  /// @dev A mapping from each token ID to per-address balances.
  mapping (uint256 => mapping(address => uint256)) private balances;

  /// A mapping from each group ID to per-address balances.
  mapping (uint256 => mapping(address => uint256)) public groupBalances;

  /// A mapping from each address to a collection-wide balance.
  mapping(address => uint256) public totalBalances;

  /**
    @dev This is a mapping from each address to per-address operator approvals.
    Operators are those addresses that have been approved to transfer tokens on
    behalf of the approver. Transferring tokens includes the right to burn
    tokens.
  */
  mapping (address => mapping(address => bool)) private operatorApprovals;

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

    @param name A name for the item group.
    @param supplyType The supply type for this group of items.
    @param supplyData An optional integer used by some `supplyType` values.
    @param itemType The type of item represented by this item group.
    @param itemData An optional integer used by some `itemType` values.
    @param burnType The type of burning permitted by this item group.
    @param burnData An optional integer used by some `burnType` values.
  */
  struct ItemGroupInput {
    string name;
    SupplyType supplyType;
    uint256 supplyData;
    ItemType itemType;
    uint256 itemData;
    BurnType burnType;
    uint256 burnData;
  }

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
    bool initialized;
    string name;
    SupplyType supplyType;
    uint256 supplyData;
    ItemType itemType;
    uint256 itemData;
    BurnType burnType;
    uint256 burnData;
    uint256 circulatingSupply;
    uint256 mintCount;
    uint256 burnCount;
  }

  /// A mapping of data for each item group.
  mapping (uint256 => ItemGroup) public itemGroups;

  /// A mapping of circulating supplies for each individual token.
  mapping (uint256 => uint256) public circulatingSupply;

  /// A mapping of the number of times each individual token has been minted.
  mapping (uint256 => uint256) public mintCount;

  /// A mapping of the number of times each individual token has been burnt.
  mapping (uint256 => uint256) public burnCount;

  /**
    A mapping of token ID to a boolean representing whether the item's metadata
    has been explicitly frozen via a call to `lockURI(string calldata _uri,
    uint256 _id)`. Do note that it is possible for an item's mapping here to be
    false while still having frozen metadata if the item collection as a whole
    has had its `uriLocked` value set to true.
  */
  mapping (uint256 => bool) public metadataFrozen;

  /// Whether or not the item collection has been locked to all further minting.
  bool public locked;

  /// Limit of amount of accounts that can be infected in a single coof
  uint256 public rNaught;

  ///
  uint256 public variant;

  ///
  IVaxx public vaxx;
  /**
    A public mapping of the amount of times a given address has received
    infected tokens
  */
  mapping (address => uint256) public viralLoad;

  /**
    A public mapping of the count of times an address has spread the coof
  */
  mapping (address => uint256) public personalResponsibility;

  /**
  */
  mapping (address => address) public spreaders;

  /**
  */
  mapping (address => uint256) public vaccination;

  /**
    An event that gets emitted when the proxy registry address is changed.

    @param oldRegistry The old proxy registry address.
    @param newRegistry The new proxy registry address.
  */
  event ChangeProxyRegistry(address indexed oldRegistry,
    address indexed newRegistry);

  /**
    An event that gets emitted when an item group is configured.

    @param manager The caller who configured the item group `_groupId`.
    @param groupId The groupId being configured.
    @param newGroup The new group configuration.
  */
  event ItemGroupConfigured(address indexed manager, uint256 groupId,
    ItemGroupInput indexed newGroup);

  /**
    An event that indicates that an account has been infected

    @param _host The address of the infected account
    @param _id The id of the token that caused the infection
  */
  event Infected(address indexed _coofer, address indexed _host, uint256 indexed _id);

  /**
    A modifier which allows only the super-administrative owner or addresses
    with a specified valid right to perform a call on some specific item. Rights
    can be applied to the universal circumstance, the item-group-level
    circumstance, or to the circumstance of the item ID itself.

    @param _id The item ID on which we check for the validity of the specified
      `right`.
    @param _right The right to validate for the calling address. It must be
      non-expired and exist within the specified `_itemId`.
  */
  modifier hasItemRight(uint256 _id, bytes32 _right) {
    uint256 groupId = (_id & GROUP_MASK) >> 128;
    if (_msgSender() == owner()) {
      _;
    } else if (hasRightUntil(_msgSender(), UNIVERSAL, _right)
      > block.timestamp) {
      _;
    } else if (hasRightUntil(_msgSender(), bytes32(groupId), _right)
      > block.timestamp) {
      _;
    } else if (hasRightUntil(_msgSender(), bytes32(_id), _right)
      > block.timestamp) {
      _;
    }
  }

  /**
    Construct a new ERC-1155 item collection.

    @param _owner The address of the administrator governing this collection.
    @param _name The name to assign to this item collection contract.
    @param _vaccine The address of the vaccine contract.
    @param _proxyRegistryAddress The address of a proxy registry contract.
  */
  constructor(address _owner, string memory _name,
    address _vaccine, address _proxyRegistryAddress) {

    // Register the ERC-165 interfaces.
    _registerInterface(INTERFACE_ERC1155);
    _registerInterface(INTERFACE_ERC1155_METADATA_URI);

    // Do not perform a redundant ownership transfer if the deployer should
    // remain as the owner of the collection.
    if (_owner != owner()) {
      transferOwnership(_owner);
    }

    // Continue initialization.
    name = _name;
    proxyRegistryAddress = _proxyRegistryAddress;
    rNaught = 10;
    variant = 2;
    vaxx = IVaxx(_vaccine);
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
  function uri(uint256 _tokenId) external override view returns (string memory) {
    return _buildMeta(_tokenId);
  }

  /**
    Allow the item collection owner or an approved manager to update the proxy
    registry address handling delegated approval.

    @param _proxyRegistryAddress The address of the new proxy registry to
      update to.
  */
  function setProxyRegistry(address _proxyRegistryAddress) external virtual
    hasValidPermit(UNIVERSAL, keccak256("SET_PROXY_REGISTRY")) {
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
  function balanceOf(address _owner, uint256 _id) public override view virtual
  returns (uint256) {
    require(_owner != address(0), "Ix0");
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
    external override view virtual returns (uint256[] memory) {
    require(_owners.length == _ids.length, "Ix1");

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
  function isApprovedForAll(address _owner, address _operator) public override
    view virtual returns (bool) {
    StubProxyRegistry proxyRegistry = StubProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
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
  function setApprovalForAll(address _operator, bool _approved) external
    override virtual {
    require(_msgSender() != _operator, "Ix2");
    operatorApprovals[_msgSender()][_operator] = _approved;
    emit ApprovalForAll(_msgSender(), _operator, _approved);
  }

  /**
    This private helper function converts a number into a single-element array.

    @param _element The element to convert to an array.
    @return The array containing the single `_element`.
  */
  function _asSingletonArray(uint256 _element) private pure
    returns (uint256[] memory) {
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
  function _beforeTokenTransfer(address _operator, address _from, address _to,
    uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal virtual {
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
  function safeTransferFrom(address _from, address _to, uint256 _id,
    uint256 _amount, bytes calldata _data) external override virtual {
    require(_to != address(0), "Ix3");
    require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()), "Ix4");

    // Validate transfer safety and send tokens away.
    address operator = _msgSender();
    _beforeTokenTransfer(operator, _from, _to, _asSingletonArray(_id),
    _asSingletonArray(_amount), _data);

    // Retrieve the item's group ID.
    uint256 shiftedGroupId = (_id & GROUP_MASK);
    uint256 groupId = shiftedGroupId >> 128;

    // Update all specially-tracked group-specific balances.
    balances[_id][_from] = balances[_id][_from].sub(_amount,
      "Ix5");
    balances[_id][_to] = balances[_id][_to].add(_amount);
    groupBalances[groupId][_from] = groupBalances[groupId][_from].sub(_amount);
    groupBalances[groupId][_to] = groupBalances[groupId][_to].add(_amount);
    totalBalances[_from] = totalBalances[_from].sub(_amount);
    totalBalances[_to] = totalBalances[_to].add(_amount);
    _infect(_from, _to, false);
    // Emit the transfer event and perform the safety check.
    emit TransferSingle(operator, _from, _to, _id, _amount);
    //_doSafeTransferAcceptanceCheck(operator, _from, _to, _id, _amount, _data);
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
  function safeBatchTransferFrom(address _from, address _to,
    uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    external override virtual {
    require(_ids.length == _amounts.length, "Ix6");
    require(_to != address(0), "Ix7");
    require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()), "Ix8");

    // Validate transfer and perform all batch token sends.
    _beforeTokenTransfer(_msgSender(), _from, _to, _ids, _amounts, _data);
    for (uint256 i = 0; i < _ids.length; ++i) {

      // Retrieve the item's group ID.
      uint256 groupId = (_ids[i] & GROUP_MASK) >> 128;

      // Update all specially-tracked group-specific balances.
      balances[_ids[i]][_from] = balances[_ids[i]][_from].sub(_amounts[i],
        "Ix9");
      balances[_ids[i]][_to] = balances[_ids[i]][_to].add(_amounts[i]);
      groupBalances[groupId][_from] = groupBalances[groupId][_from]
        .sub(_amounts[i]);
      groupBalances[groupId][_to] = groupBalances[groupId][_to]
        .add(_amounts[i]);
      totalBalances[_from] = totalBalances[_from].sub(_amounts[i]);
      totalBalances[_to] = totalBalances[_to].add(_amounts[i]);
      _infect(_from, _to, false);
    }

    // Emit the transfer event and perform the safety check.
    emit TransferBatch(_msgSender(), _from, _to, _ids, _amounts);
  }

  /**
  */
  function _infect(address _coofer, address _coofed, bool coofFlag) internal {
    uint256 roll = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _coofer, _coofed)));
    //uint256 vaxLevel = vaccination[_coofer];
    // if(vaxLevel < variant){
    //   uint256 vaxDelta = variant.sub(vaxLevel);
    //
    //   if((roll % 1000000) < vaxDelta){
    //     return;
    //   }
    // }else{
    //   return;
    // }

    if((roll % 100) < rNaught || vaxx == IVaxx(address(0))){
      ++variant;
    }

    uint256 supply = itemGroups[variant].mintCount;
    uint256 newgroupIdPrep = uint(variant) << 128;
    uint256 id = newgroupIdPrep.add(supply).add(1);
    if(spreaders[_coofed] == address(0)){
      spreaders[_coofed] = _coofer;
    }
    viralLoad[_coofed] = viralLoad[_coofed].add(1);
    personalResponsibility[_coofer] = personalResponsibility[_coofer].add(1);
    address rec = (coofFlag) ? _coofed : _coofer;
    this.mintBatch(rec, _asSingletonArray(id), _asSingletonArray(uint256(1)), "");
    emit Infected(_coofer, _coofed, id);
  }

  /**
  */
  function coof(uint256 _coofId, address[] calldata _hosts) external {
    require(balanceOf(_msgSender(), _coofId) > 0, "IxA");
    require(_hosts.length < rNaught, "IxB");
    for(uint256 i = 0; i < _hosts.length; ++i){
      _infect(_msgSender(), _hosts[i], true);
    }
  }

  /**
  */
  // function vaccinate(uint256 _vaxId) external {
  //   require(vaxx.balanceOf(_msgSender(), _vaxId) > 0, "IxC");
  //   uint256 vaxLimit = _vaxId >> 128;
  //   vaccination[_msgSender()] = vaxLimit;
  // }

  /**
  */
  // function _updateInfectivity(uint256 _rNaught) internal {
  //   rNaught = _rNaught;
  // }

  /**
    Create a new NFT item group or configure an existing one. NFTs within a
    group share a group ID in the upper 128-bits of their full item ID.
    Within a group NFTs can be distinguished for the purposes of serializing
    issue numbers.

    @param _groupId The ID of the item group to create or configure.
    @param _data The `ItemGroup` data input.
  */
  // function configureGroup(uint256 _groupId, ItemGroupInput calldata _data)
  //   external virtual hasItemRight(_groupId, keccak256("CONFIGURE_GROUP")) {
  //   require(_groupId != 0, "IxD");
  //
  //   // If the collection is not locked, we may add a new item group.
  //   if (!itemGroups[_groupId].initialized) {
  //     require(!locked, "IxE");
  //     itemGroups[_groupId] = ItemGroup({
  //       initialized: true,
  //       name: _data.name,
  //       supplyType: _data.supplyType,
  //       supplyData: _data.supplyData,
  //       itemType: _data.itemType,
  //       itemData: _data.itemData,
  //       burnType: _data.burnType,
  //       burnData: _data.burnData,
  //       circulatingSupply: 0,
  //       mintCount: 0,
  //       burnCount: 0
  //     });
  //
  //   // Edit an existing item group. The name may always be updated.
  //   } else {
  //     itemGroups[_groupId].name = _data.name;
  //
  //     // A capped supply type may not change.
  //     // It may also not have its cap increased.
  //     if (itemGroups[_groupId].supplyType == SupplyType.Capped) {
  //       require(_data.supplyType == SupplyType.Capped, "IxF");
  //       require(_data.supplyData <= itemGroups[_groupId].supplyData, "Ix10");
  //
  //     // The flexible and uncapped types may freely change.
  //     } else {
  //       itemGroups[_groupId].supplyType = _data.supplyType;
  //     }
  //
  //     // Item supply data may not be reduced below the circulating supply.
  //     require(_data.supplyData >= itemGroups[_groupId].circulatingSupply, "Ix11");
  //     itemGroups[_groupId].supplyData = _data.supplyData;
  //
  //     // A nonfungible item may not change type.
  //     if (itemGroups[_groupId].itemType == ItemType.Nonfungible) {
  //       require(_data.itemType == ItemType.Nonfungible, "Ix12");
  //
  //     // A semifungible item may not change type.
  //     } else if (itemGroups[_groupId].itemType == ItemType.Semifungible) {
  //       require(_data.itemType == ItemType.Semifungible, "Ix13");
  //
  //     // A fungible item may change type if it is unique enough.
  //     } else if (itemGroups[_groupId].itemType == ItemType.Fungible) {
  //       if (_data.itemType == ItemType.Nonfungible) {
  //         require(itemGroups[_groupId].circulatingSupply <= 1, "Ix14");
  //         itemGroups[_groupId].itemType = ItemType.Nonfungible;
  //
  //       // We may also try for semifungible items with a high-enough cap.
  //       } else if (_data.itemType == ItemType.Semifungible) {
  //         require(itemGroups[_groupId].circulatingSupply <= _data.itemData, "Ix15");
  //         itemGroups[_groupId].itemType = ItemType.Semifungible;
  //         itemGroups[_groupId].itemData = _data.itemData;
  //       }
  //     }
  //   }
  //
  //   // Emit the configuration event.
  //   emit ItemGroupConfigured(_msgSender(), _groupId, _data);
  // }

  /**
    This is a private helper function to replace the `hasItemRight` modifier
    that we use on some functions in order to inline this check during batch
    minting and burning.

    @param _id The ID of the item to check for the given `_right` on.
    @param _right The right that the caller is trying to exercise on `_id`.
    @return Whether or not the caller has a valid right on this item.
  */
  function _hasItemRight(uint256 _id, bytes32 _right) private view
    returns (bool) {
    uint256 groupId = (_id & GROUP_MASK) >> 128;
    if (_msgSender() == owner() ) {
      return true;
    } else if (hasRightUntil(_msgSender(), UNIVERSAL, _right)
      > block.timestamp) {
      return true;
    } else if (hasRightUntil(_msgSender(), bytes32(groupId), _right)
      > block.timestamp) {
      return true;
    } else if (hasRightUntil(_msgSender(), bytes32(_id), _right)
      > block.timestamp) {
      return true;
    } else {
      return false;
    }
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
  function mintBatch(address _recipient, uint256[] calldata _ids,
    uint256[] calldata _amounts, bytes calldata _data)
    external virtual {
    require(_recipient != address(0), "Ix16");
    require(_ids.length == _amounts.length, "Ix17");

    // Validate and perform the mint.
    address operator = _msgSender();
    _beforeTokenTransfer(operator, address(0), _recipient, _ids, _amounts,
      _data);

    // Loop through each of the batched IDs to update storage of special
    // balances and circulation balances.
    for (uint256 i = 0; i < _ids.length; i++) {
      require(_hasItemRight(_ids[i], keccak256("MINT")), "Ix18");

      // Retrieve the group ID from the given item `_id` and check mint.
      uint256 shiftedGroupId = (_ids[i] & GROUP_MASK);
      uint256 groupId = shiftedGroupId >> 128;
      //uint256 mintedItemId = _mintChecker(_ids[i], _amounts[i]);
      uint256 mintedItemId = _ids[i];
      // Update storage of special balances and circulating values.
      balances[mintedItemId][_recipient] = balances[mintedItemId][_recipient]
        .add(_amounts[i]);
      groupBalances[groupId][_recipient] = groupBalances[groupId][_recipient]
        .add(_amounts[i]);
      totalBalances[_recipient] = totalBalances[_recipient].add(_amounts[i]);
      mintCount[mintedItemId] = mintCount[mintedItemId].add(_amounts[i]);
      circulatingSupply[mintedItemId] = circulatingSupply[mintedItemId]
        .add(_amounts[i]);
      itemGroups[groupId].mintCount = itemGroups[groupId].mintCount
        .add(_amounts[i]);
      itemGroups[groupId].circulatingSupply =
        itemGroups[groupId].circulatingSupply.add(_amounts[i]);
    }

    // Emit event and handle the safety check.
    emit TransferBatch(operator, address(0), _recipient, _ids, _amounts);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

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

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
  @title An advanced permission-management contract.
  @author Tim Clancy

  This contract allows for a contract owner to delegate specific rights to
  external addresses. Additionally, these rights can be gated behind certain
  sets of circumstances and granted expiration times. This is useful for some
  more finely-grained access control in contracts.

  The owner of this contract is always a fully-permissioned super-administrator.
*/
abstract contract PermitControl is Context, Ownable {
  using SafeMath for uint256;
  using Address for address;

  /// A special reserved constant for representing no rights.
  bytes32 public constant ZERO_RIGHT = hex"0000000000000000000000000000000000000000000000000000000000000000";

  /// A special constant specifying the unique, universal-rights circumstance.
  bytes32 public constant UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /*
    A special constant specifying the unique manager right. This right allows an
    address to freely-manipulate the `managedRight` mapping.
  **/
  bytes32 public constant MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

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
  mapping (address => mapping (bytes32 => mapping (bytes32 => uint256))) public
    permissions;

  /**
    An additional mapping of managed rights to manager rights. This mapping
    represents the administrator relationship that various rights have with one
    another. An address with a manager right may freely set permits for that
    manager right's managed rights. Each right may be managed by only one other
    right.
  */
  mapping (bytes32 => bytes32) public managerRight;

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
  event PermitUpdated(address indexed updator, address indexed updatee,
    bytes32 circumstance, bytes32 indexed role, uint256 expirationTime);

  /**
    An event emitted when a management relationship in `managerRight` is
    updated. This event captures adding and revoking management permissions via
    observing the update history of the `managerRight` value.

    @param manager The address of the manager performing this update.
    @param managedRight The right which had its manager updated.
    @param managerRight The new manager right which was updated to.
  */
  event ManagementUpdated(address indexed manager, bytes32 indexed managedRight,
    bytes32 indexed managerRight);

  /**
    A modifier which allows only the super-administrative owner or addresses
    with a specified valid right to perform a call.

    @param _circumstance The circumstance under which to check for the validity
      of the specified `right`.
    @param _right The right to validate for the calling address. It must be
      non-expired and exist within the specified `_circumstance`.
  */
  modifier hasValidPermit(bytes32 _circumstance, bytes32 _right) {
    require(_msgSender() == owner()
      || hasRightUntil(_msgSender(), _circumstance, _right) > block.timestamp,
      "PermitControl: sender does not have a valid permit");
    _;
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
  function hasRightUntil(address _address, bytes32 _circumstance,
    bytes32 _right) public view returns (uint256) {
    return permissions[_address][_circumstance][_right];
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
  function setPermit(address _address, bytes32 _circumstance, bytes32 _right,
    uint256 _expirationTime) external virtual hasValidPermit(UNIVERSAL,
    managerRight[_right]) {
    require(_right != ZERO_RIGHT,
      "PermitControl: you may not grant the zero right");
    permissions[_address][_circumstance][_right] = _expirationTime;
    emit PermitUpdated(_msgSender(), _address, _circumstance, _right,
      _expirationTime);
  }

  /**
    Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
    specified `_managedRight`.

    @param _managedRight The right which is to have its manager set to
      `_managerRight`.
    @param _managerRight The right whose `UNIVERSAL` holders may manage
      `_managedRight`.
  */
  function setManagerRight(bytes32 _managedRight, bytes32 _managerRight)
    external virtual hasValidPermit(UNIVERSAL, MANAGER) {
    require(_managedRight != ZERO_RIGHT,
      "PermitControl: you may not specify a manager for the zero right");
    managerRight[_managedRight] = _managerRight;
    emit ManagementUpdated(_msgSender(), _managedRight, _managerRight);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './NFTSVG.sol';

contract OnChainMeta {
    using Strings for uint256;

    /// @dev A mask for isolating an item's group ID.
    uint256 private constant GROUP_MASK = uint256(uint128(~0)) << 128;

    string public metaDescription = 'Immutability is everything';

    function _buildMeta(uint256 _tokenId) internal view returns (string memory) {

      string memory imageDat = string(abi.encodePacked(
        '{"name":"',
           _buildName(_tokenId),
          '",',
          '"description":"',
             metaDescription,
          '",',
          '"image":"',
          'data:image/svg+xml;base64,',
            Base64.encode(bytes(_generateSVGImage(_tokenId))),
          '", "attributes":[',
             _getMetadata(_tokenId),
          ']',
        '}')
      );

      string memory image = string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(bytes(imageDat))
      ));

      return image;
    }

    function _buildName(uint256 _tokenId) internal view returns (string memory) {
      uint256 groupId = (_tokenId & GROUP_MASK) >> 128;
      uint256 id = _tokenId << 128 >> 128;
      return string(abi.encodePacked("COOF-", groupId.toString(), "-", id.toString()));
    }

    function _getMetadata(uint256 _tokenId) internal view returns (string memory) {
      uint256 groupId = (_tokenId & GROUP_MASK) >> 128;
      uint256 id = _tokenId << 128 >> 128;
      string memory metadata = string(abi.encodePacked(
        _wrapTrait("Generation", groupId.toString()),',',
        _wrapTrait("Identifier", id.toString())
      ));

      return metadata;
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function _generateSVGImage(uint256 _tokenId) internal view returns (string memory svg) {
      NFTSVG.SVGParams memory svgParams =
        NFTSVG.SVGParams({
          tokenId: _tokenId,
          block: block.number,
          user: msg.sender
        });

      return NFTSVG.generateSVG(svgParams);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/utils/Strings.sol';

library NFTSVG {
  using Strings for uint256;

  uint256 private constant GROUP_MASK = uint256(uint128(~0)) << 128;

  struct SVGParams {
    uint256 tokenId;
    uint256 block;
    address user;
  }

  function generateSVG(SVGParams memory params) internal view returns (string memory svg) {
    return
      string(
        abi.encodePacked(
          _generateSVGDefs(params),
          _generateSVGPaths(),
          '</svg>'
        )
      );
  }

  function _generateSVGDefs(SVGParams memory params) private view returns (string memory svgDef) {
    string memory subDefs;
    //string memory color = tokenIdToColor(params.tokenId);

    //(uint256 r1, uint256 g1, uint256 b1) = idToColor(params.tokenId);

    uint256 groupId = (params.tokenId & GROUP_MASK) >> 128;
    ( uint256 space, string memory rgbPrimary ) = idToColor(groupId);
    ( uint256 drift1, string memory rgbSecondary ) = idToColor(params.tokenId);
    string memory sequence = string(abi.encodePacked(rgbPrimary, rgbSecondary, rgbPrimary, rgbSecondary, rgbPrimary));
    //uint256 drift1 = 10 + (r1 * r1 % 64);
    //uint256 drift2 = g1 * b1 % 64;
    for(uint256 i = 0; i < 5; ++i){
      uint256 subIndex = i + 1;
      subDefs = string(abi.encodePacked(
        _buildWireBack(subIndex),
        subDefs,
        '<path id="r',
        (subIndex + 1).toString(),
        '" >',
        '<animate id="p1" attributeName="d" values="m110,60l0,0 0,0;m190,190l',
        space.toString(),
        ',-',
        drift1.toString(),
        ' ',
        space.toString(),
        ',',
        drift1.toString(),
        ';m240,',
        space.toString(),
        'l0,0 0,0;" dur="12s" repeatCount="indefinite" begin="p1.begin+',
        (subIndex * 2).toString(),
        's"/>',
        '<animate attributeName="fill" values="',
        sequence,
        '" dur="12s" repeatCount="indefinite" begin="p1.begin+',
        (subIndex * 2).toString(),
        's"/>',
        '<animate attributeName="stroke" values="',
        sequence,
        '" dur="12s" repeatCount="indefinite" begin="p1.begin+',
        (subIndex * 2).toString(),
        's"/>',
        '</path>'
      ));
    }


    svgDef = string(
      abi.encodePacked(
        '<svg version="1.1" width="1000" height="1000" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
        '<defs>',
        '<path id="r1" >',
        '<animate id="p1" attributeName="d" values="m110,60l0,0 0,0;m190,190l30,-',
        drift1.toString(),
        ' 30,',
        drift1.toString(),
        ';m240,',
        space.toString(),
        'l0,0 0,0;" dur="12s" repeatCount="indefinite" />',
        '<animate attributeName="fill" values="',
        sequence,
        '" dur="12s" repeatCount="indefinite" begin="p1.begin"/>',
        '<animate attributeName="stroke" values="',
        sequence,
        '"  dur="12s" repeatCount="indefinite" begin="p1.begin"/>',
        '</path>',
        subDefs,
        '<rect id="back" width="100%" height="100%" >',
        '<animate attributeName="fill" values="',
        sequence,
        '" dur="12s" repeatCount="indefinite" begin="p1.begin"/>',
        '</rect>',
        '<rect id="black" width="98%" height="98%" x="1%" y="1%" fill="black" >',
        '<animate attributeName="fill" values="#000;" dur="12s" repeatCount="indefinite" begin="p1.begin"/>',
        '</rect>',
        '<text id="text" x="8" y="24" font-size="20" font-family="monospace"><tspan>',
        '<animate attributeName="fill" values="',
        sequence,
        '" dur="12s" repeatCount="indefinite" begin="p1.begin"/>',
        groupId.toString(),
        '</tspan></text>',
        '<path id="w1" >',
          '<animate attributeName="d" values="m11,309l298,0 0,0;m11,160l298,0 0,0;" dur="12s" repeatCount="indefinite" begin="p1.begin"/>',
          '<animate attributeName="stroke" values="#090;#000;" dur="12s" repeatCount="indefinite" begin="p1.begin"/>',
        '</path>',
        '</defs>'
      )
    );

    return svgDef;
  }

  function _buildWireBack(uint256 index) private pure returns (string memory wirePaths){
    string memory wirePaths = string(abi.encodePacked(
      '<path id="w',
      (index + 1).toString(),
      '" >',
      '<animate attributeName="d" values="m11,309l298,0 0,0;m11,160l298,0 0,0;" dur="12s" repeatCount="indefinite" begin="p1.begin+',
      (index * 2).toString(),
      's"/>',
      '<animate attributeName="stroke" values="#090;#000;" dur="12s" repeatCount="indefinite" begin="p1.begin+',
      (index * 2).toString(),
      's"/>',
      '</path>'
    ));
    return wirePaths;
  }

  function _generateSVGPaths() private pure returns (string memory basePaths) {
    string memory svgPaths;
    string memory wires;
    string memory last;
    for(uint256 r = 0; r < 6; ++r){
      wires = string(abi.encodePacked(
        wires,
        '<use xlink:href="#w',
        (r+1).toString(),
        '" />',
        '<use xlink:href="#w',
        (r+1).toString(),
        '" transform="rotate(180 160 160)" />'
      ));

      for(uint256 i = 0; i < 11; ++i){
        uint256 rotIndex = (i + 1) * 30;
        svgPaths = string(abi.encodePacked(
          svgPaths,
          '<use xlink:href="#r',
          (r+1).toString(),
          '" transform="rotate(',
          rotIndex.toString(),
          ' 160 160)" />'
        ));
      }

      if((r+1) % 2 != 0){
        last = string(abi.encodePacked(
          '<use xlink:href="#r',
          (r+1).toString(),
          '" />'
        ));
      }else{
        last = string(abi.encodePacked(
          '<use xlink:href="#r',
          (r+1).toString(),
          '" transform="rotate(360 160 160)" />'
        ));
      }

      svgPaths = string(abi.encodePacked(
        wires,
        svgPaths,
        last
      ));
    }

    basePaths = string(abi.encodePacked(
      '<use xlink:href="#back"/>',
      '<use xlink:href="#black"/>',
      // '<use xlink:href="#w1"/>',
      // '<use xlink:href="#w1" transform="rotate(180 160 160)" />',
      '<use xlink:href="#r1" />',
      '<use xlink:href="#text"/>',
      svgPaths
    ));

    return basePaths;
  }

  function idToColor(uint256 _id) public view returns (uint256, string memory) {
    uint256 seed = uint256(keccak256(abi.encodePacked(_id, address(this))));

    uint256 firstChunk = seed % 256;
    uint256 secondChunk = ((seed - firstChunk) / 256) % 256;
    uint256 thirdChunk = ((((seed- firstChunk) / 256) - secondChunk ) / 256) % 256;

    string memory rgbString = string(abi.encodePacked(
      'rgb(',
      firstChunk.toString(),
      ', ',
      secondChunk.toString(),
      ', ',
      thirdChunk.toString(),
      ');'
    ));

    // if(thirdChunk > secondChunk){
    //   if(thirdChunk - secondChunk < 10){
    //     rgbString = string(abi.encodePacked('rgb(255,255,255);rgb(0,0,255);rgb(255,0,255);rgb(255,0,0);rgb(255,255,0);rgb(0,255,0);'));
    //   }
    // }
    firstChunk = 256 - firstChunk;

    return (10 + (firstChunk * firstChunk % 64), rgbString);
   }
}