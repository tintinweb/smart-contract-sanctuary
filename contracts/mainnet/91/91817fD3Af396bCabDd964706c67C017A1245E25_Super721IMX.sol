// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../utils/Utils.sol";
import "../../access/PermitControl.sol";
import "../../proxy/StubProxyRegistry.sol";
import "../../interfaces/ISuper721IMXLock.sol";

/**
  @title An ERC-721 item creation contract.
  @author Tim Clancy
  @author 0xthrpw
  @author Qazawat Zirak
  This contract represents the NFTs within a single collection. It allows for a
  designated collection owner address to manage the creation of NFTs within this
  collection. The collection owner grants approval to or removes approval from
  other addresses governing their ability to mint NFTs from this collection.
  This contract is forked from the inherited OpenZeppelin dependency, and uses
  ideas inherited from the Super721 reference implementation.
  August 4th, 2021.
*/
contract Super721IMX is PermitControl, ERC165Storage, IERC721 {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  /// The public identifier for the right to set this contract's metadata URI.
  bytes32 public constant SET_URI = keccak256("SET_URI");

  /// The public identifier for the right to set this contract's proxy registry.
  bytes32 public constant SET_PROXY_REGISTRY = keccak256("SET_PROXY_REGISTRY");

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
   *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
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
  /// @dev Supply the magic number for the required ERC-721 interface.

  /// @dev A mask for isolating an item's group ID.
  uint256 private constant GROUP_MASK = uint256(type(uint128).max) << 128;

  /// The public name of this contract.
  string public name;

  string public symbol;

  /**
    The ERC-721 URI for tracking item metadata, supporting {id} substitution.
    For example: https://token-cdn-domain/{id}.json. See the ERC-721 spec for
    more details: https://eips.ethereum.org/EIPS/eip-721#metadata.
  */
  string public metadataUri;

  /// The URI for the storefront-level metadata of contract
  string public contractURI;

  /// A proxy registry address for supporting automatic delegated approval.
  address public proxyRegistryAddress;

  /// The address of the IMX core contract for L2 minting.
  address public imxCoreAddress;

  /// The address of the global lock for all 721IMX instances.
  address public super721IMXLock;

  /// @dev A mapping from each token ID to per-address balances.
  mapping (uint256 => mapping(address => uint256)) public balances;

  /// A mapping from each group ID to per-address balances.
  mapping (uint256 => mapping(address => uint256)) public groupBalances;

  /// A mapping from each address to a collection-wide balance.
  mapping(address => uint256) public totalBalances;

  // Mapping from holder address to their (enumerable) set of owned tokens
  mapping (address => EnumerableSet.UintSet) private _holderTokens;

  // Enumerable mapping from token ids to their owners
  EnumerableMap.UintToAddressMap private _tokenOwners;
  /**
    @dev This is a mapping from each address to per-address operator approvals.
    Operators are those addresses that have been approved to transfer tokens on
    behalf of the approver. Transferring tokens includes the right to burn
    tokens.
  */
  mapping (address => mapping(address => bool)) private operatorApprovals;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

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
    @param burnType The type of burning permitted by this item group.
    @param burnData An optional integer used by some `burnType` values.
  */
  struct ItemGroupInput {
    string name;
    SupplyType supplyType;
    uint256 supplyData;
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

  /**
    A public mapping of optional on-chain metadata for each token ID. A token's
    on-chain metadata is unable to be changed if the item's metadata URI has
    been permanently fixed or if the collection's metadata URI as a whole has
    been frozen.
  */
  mapping (uint256 => string) public blueprints;

  /// Whether or not the metadata URI has been locked to future changes.
  bool public uriLocked;

  /// Whether or not the metadata URI has been locked to future changes.
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
    An event that gets emitted when the contract URI is changed.
    @param oldURI The old metadata URI.
    @param newURI The new metadata URI.
  */
  event ChangeContractURI(string indexed oldURI, string indexed newURI);

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
  event MetadataChanged(address indexed changer, uint256 indexed id,
    string oldMetadata, string indexed newMetadata);

  /**
    An event that indicates we have set a permanent metadata URI for a token.
    @param _value The value of the permanent metadata URI.
    @param _id The token ID associated with the permanent metadata value.
  */
  event PermanentURI(string _value, uint256 indexed _id);

  /**
    An event that indicates we have set a permanent contract URI.
    @param _value The value of the permanent contract URI.
    @param _id The token ID associated with the permanent contract value.
  */
  event PermanentContractURI(string _value, uint256 indexed _id);

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
    } else if (hasRight(_msgSender(), UNIVERSAL, _right)) {
      _;
    } else if (hasRight(_msgSender(), bytes32(groupId), _right)) {
      _;
    } else if (hasRight(_msgSender(), bytes32(_id), _right)) {
      _;
    } else {
      revert("Ix01");
    }
  }

  /**
    Construct a new ERC-721 item collection.
    @param _owner The address of the administrator governing this collection.
    @param _name The name to assign to this item collection contract.
    @param _metadataURI The metadata URI to perform later token ID substitution with.
    @param _contractURI The contract URI. 
    @param _proxyRegistryAddress The address of a proxy registry contract.
    @param _imxCoreAddress The address of the IMX core contract for L2 minting.
  */
  constructor(address _owner, string memory _name, string memory _symbol, string memory _metadataURI,
    string memory _contractURI, address _proxyRegistryAddress, address _imxCoreAddress, address _super721IMXLock) {

    // Do not perform a redundant ownership transfer if the deployer should
    // remain as the owner of the collection.
    if (_owner != owner()) {
      transferOwnership(_owner);
    }

    // Register 721 interfaces
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);

    // Continue initialization.
    name = _name;
    symbol = _symbol;
    metadataUri = _metadataURI;
    contractURI = _contractURI;
    proxyRegistryAddress = _proxyRegistryAddress;
    imxCoreAddress = _imxCoreAddress;
    super721IMXLock = _super721IMXLock;
  }
  /**
  */
  function ownerOf(uint256 tokenId) public view override returns (address) {
      return _tokenOwners.get(tokenId, "Ix02");
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
      address owner = ownerOf(tokenId);
      require(to != owner, "Ix03");

      require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
          "Ix04"
      );

      _tokenApprovals[tokenId] = to;
      emit Approval(ownerOf(tokenId), to, tokenId);
  }
  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual pure override returns (uint256) {
    return 1;
  }

  /**
    Return the item collection's metadata URI. This implementation returns the
    same URI for all tokens within the collection and relies on client-side
    ID substitution per https://eips.ethereum.org/EIPS/eip-721#metadata. Per
    said specification, clients calling this function must replace the {id}
    substring with the actual token ID in hex, not prefixed by 0x, and padded
    to 64 characters in length.
    @return The metadata URI string of the item with ID `_itemId`.
  */
  function tokenURI(uint256 id) external view returns (string memory) {
    if(bytes(metadataUri).length == 0){
        return blueprints[id];
    }
    return Utils.interpolate(metadataUri, id);
  }

  /**
    Allow the item collection owner or an approved manager to update the
    metadata URI of this collection. This implementation relies on a single URI
    for all items within the collection, and as such does not emit the standard
    URI event. Instead, we emit our own event to reflect changes in the URI.
    @param _uri The new URI to update to.
  */
  function setURI(string calldata _uri) external virtual
    hasValidPermit(UNIVERSAL, SET_URI) {
    require(!uriLocked,
      "Ix05");
    string memory oldURI = metadataUri;
    metadataUri = _uri;
    emit ChangeURI(oldURI, _uri);
  }

  /**
    Allow approved manager to update the contract URI. At the end of update, we 
    emit our own event to reflect changes in the URI.

    @param _uri The new contract URI to update to.
   */
  function setContractURI(string calldata _uri) external virtual
    hasValidPermit(UNIVERSAL, SET_URI) {
      require(!contractUriLocked,
        "Ix06");
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
  function setProxyRegistry(address _proxyRegistryAddress) external virtual
    hasValidPermit(UNIVERSAL, SET_PROXY_REGISTRY) {
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

  function balanceOfGroup(address _owner, uint256 _id) public view virtual
  returns (uint256) {
    require(_owner != address(0),
      "Ix07");
    return balances[_id][_owner];
  }

  function balanceOf(address _owner) public override view virtual
  returns (uint256) {
    require(_owner != address(0),
      "Ix08");
    return totalBalances[_owner];
  }

  /**
    Retrieve in a single call the balances of some mulitple particular token
    `_ids` held by corresponding `_owners`.
    @param _owners The owners to check for token balances.
    @param _ids The IDs of tokens to check for balances.
    @return the amount of each token owned by each owner.
  */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external view virtual returns (uint256[] memory) {
    require(_owners.length == _ids.length, "");

    // Populate and return an array of balances.
    uint256[] memory batchBalances = new uint256[](_owners.length);
    for (uint256 i = 0; i < _owners.length; ++i) {
      batchBalances[i] = balanceOfGroup(_owners[i], _ids[i]);
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
    require(_msgSender() != _operator,
      "Ix09");
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
    ERC-721 dictates that any contract which wishes to receive ERC-721 tokens
    must explicitly designate itself as such. This function checks for such
    designation to prevent undesirable token transfers.
    @param _operator The caller who triggers the token transfer.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function _doSafeTransferAcceptanceCheck(address _operator, address _from,
    address _to, uint256 _id, bytes memory _data) private {
    if (_to.isContract()) {
      try IERC721Receiver(_to).onERC721Received(_operator, _from, _id,
        _data) returns (bytes4 response) {
        if (response != IERC721Receiver(_to).onERC721Received.selector) {
          revert("Ix09");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("Ix10");
      }
    }
  }

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _data Additional call data to send with this transfer.
  */

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
      _safeTransferFrom(from, to, tokenId, bytes(""));
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
  public virtual override {
      _safeTransferFrom(from, to, tokenId, data);
  }

  function _safeTransferFrom(address _from, address _to, uint256 _id,
    bytes memory _data) internal  virtual {
    require(_to != address(0),
      "Ix11");
    require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()),
      "Ix12");

    // Validate transfer safety and send tokens away.
    address operator = _msgSender();
    _beforeTokenTransfer(operator, _from, _to, _asSingletonArray(_id),
    _asSingletonArray(1), _data);

    // Retrieve the item's group ID.
    uint256 shiftedGroupId = (_id & GROUP_MASK);
    uint256 groupId = shiftedGroupId >> 128;

    // Update all specially-tracked group-specific balances.
    require(balances[_id][_from] >= 1, "Ix13");
    balances[_id][_from] = balances[_id][_from] - 1;
    balances[_id][_to] = balances[_id][_to] + 1;
    groupBalances[groupId][_from] = groupBalances[groupId][_from] - 1;
    groupBalances[groupId][_to] = groupBalances[groupId][_to] + 1;
    totalBalances[_from] = totalBalances[_from] - 1;
    totalBalances[_to] = totalBalances[_to] + 1;

    _holderTokens[_from].remove(_id);
    _holderTokens[_to].add(_id);

    _tokenOwners.set(_id, _to);

    // Emit the transfer event and perform the safety check.
    emit Transfer(_from, _to, _id);
    _doSafeTransferAcceptanceCheck(operator, _from, _to, _id, _data);
  }

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.
    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _data Additional call data to send with this transfer.
  */

  function safeBatchTransferFrom(address _from, address _to,
    uint256[] memory _ids, bytes memory _data)
    external virtual {
    require(_to != address(0),
      "Ix14");
    require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()),
      "Ix15");

    // Validate transfer and perform all batch token sends.
    _beforeTokenTransfer(_msgSender(), _from, _to, _ids, _asSingletonArray(1), _data);
    for (uint256 i = 0; i < _ids.length; ++i) {

      // Retrieve the item's group ID.
      uint256 groupId = (_ids[i] & GROUP_MASK) >> 128;

      // Update all specially-tracked group-specific balances.
      require(balances[_ids[i]][_from] >= 1, "Ix16");
      balances[_ids[i]][_from] = balances[_ids[i]][_from] - 1;
      balances[_ids[i]][_to] = balances[_ids[i]][_to] + 1;
      groupBalances[groupId][_from] = groupBalances[groupId][_from] - 1;
      groupBalances[groupId][_to] = groupBalances[groupId][_to] + 1;
      totalBalances[_from] = totalBalances[_from] - 1;
      totalBalances[_to] = totalBalances[_to] + 1;

      // Emit the transfer event and perform the safety check.
      emit Transfer(_from, _to, _ids[i]);
      _doSafeTransferAcceptanceCheck(_msgSender(), _from, _to, _ids[i], _data);
    }
  }

  /**
    Create a new NFT item group or configure an existing one. NFTs within a
    group share a group ID in the upper 128-bits of their full item ID.
    Within a group NFTs can be distinguished for the purposes of serializing
    issue numbers.
    @param _groupId The ID of the item group to create or configure.
    @param _data The `ItemGroup` data input.
  */
  function configureGroup(uint256 _groupId, ItemGroupInput memory _data)
    external virtual hasItemRight(_groupId, CONFIGURE_GROUP) {
    require(_groupId != 0,
      "Ix17");

    // If the collection is not locked, we may add a new item group.
    if (!itemGroups[_groupId].initialized) {
      require(!locked,
        "Ix18");
      itemGroups[_groupId] = ItemGroup({
        initialized: true,
        name: _data.name,
        supplyType: _data.supplyType,
        supplyData: _data.supplyData,
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
      if (itemGroups[_groupId].supplyType == SupplyType.Capped) {
        require(_data.supplyType == SupplyType.Capped,
          "Ix19");
        require(_data.supplyData <= itemGroups[_groupId].supplyData,
          "Ix20");

      // The flexible and uncapped types may freely change.
      } else {
        itemGroups[_groupId].supplyType = _data.supplyType;
      }

      // Item supply data may not be reduced below the circulating supply.
      require(_data.supplyData >= itemGroups[_groupId].circulatingSupply,
        "Ix21");
      itemGroups[_groupId].supplyData = _data.supplyData;
      // do we want burnType to be updateable?
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
  function _hasItemRight(uint256 _id, bytes32 _right) private view
    returns (bool) {
    uint256 groupId = (_id & GROUP_MASK) >> 128;
    if (_msgSender() == owner()) {
      return true;
    } else if (hasRight(_msgSender(), UNIVERSAL, _right)) {
      return true;
    } else if (hasRight(_msgSender(), bytes32(groupId), _right)) {
      return true;
    } else if (hasRight(_msgSender(), bytes32(_id), _right)) {
      return true;
    } else {
      return false;
    }
  }

  /**
    This is a private helper function to verify, according to all of our various
    minting and burning rules, whether it would be valid to mint a particular
    item `_id`.
    @param _id The ID of the item to check for minting validity.
    @return The ID of the item that should be minted.
  */
  function _mintChecker(uint256 _id) private view returns (uint256) {

    // Retrieve the item's group ID.
    uint256 shiftedGroupId = (_id & GROUP_MASK);
    uint256 groupId = shiftedGroupId >> 128;
    // console.logUint(groupId);
    require(itemGroups[groupId].initialized,
      "Ix22");

    // If false, owned by address (or NULL_ADDRESS i.e, was burnable)
    // If true, never minted, (or was removed i.e, was replenishable)
    require(!_tokenOwners.contains(_id),
      "Ix23");

    // If we can replenish burnt items, then only our currently-circulating
    // supply matters. Otherwise, historic mints are what determine the cap.
    uint256 currentGroupSupply = itemGroups[groupId].mintCount;
    uint256 currentItemSupply = mintCount[_id];
    if (itemGroups[groupId].burnType == BurnType.Replenishable) {
      currentGroupSupply = itemGroups[groupId].circulatingSupply;
      currentItemSupply = circulatingSupply[_id];
    }

    // If we are subject to a cap on group size, ensure we don't exceed it.
    if (itemGroups[groupId].supplyType != SupplyType.Uncapped) {
      require(currentGroupSupply + 1 <= itemGroups[groupId].supplyData,
        "Ix24");
    }

    return _id;
  }

  /**
    Mint a batch of tokens into existence and send them to the `_recipient`
    address. In order to mint an item, its item group must first have been
    created. Minting an item must obey both the fungibility and size cap of its
    group.
    @param _recipient The address to receive all NFTs within the newly-minted
      group.
    @param _ids The item IDs for the new items to create.
    @param _data Any associated data to use on items minted in this transaction.
  */

  function mintBatch(address _recipient, uint256[] memory _ids,
    bytes memory _data)
    public virtual {
    require(_recipient != address(0), "Super721::mintBatch: mint to the zero address");
    // Validate and perform the mint.
    address operator = _msgSender();
    _beforeTokenTransfer(operator, address(0), _recipient, _ids, _asSingletonArray(1),
      _data);

    // Loop through each of the batched IDs to update storage of special
    // balances and circulation balances.
    for (uint256 i = 0; i < _ids.length; i++) {
      require(_hasItemRight(_ids[i], MINT),
        "Ix25");

      // Retrieve the group ID from the given item `_id` and check mint.
      uint256 shiftedGroupId = (_ids[i] & GROUP_MASK);
      uint256 groupId = shiftedGroupId >> 128;
      uint256 mintedItemId = _mintChecker(_ids[i]);

      // Update storage of special balances and circulating values.
      balances[mintedItemId][_recipient] = balances[mintedItemId][_recipient] + 1;
      groupBalances[groupId][_recipient] = groupBalances[groupId][_recipient] + 1;
      totalBalances[_recipient] = totalBalances[_recipient] + 1;
      mintCount[mintedItemId] = mintCount[mintedItemId] + 1;
      circulatingSupply[mintedItemId] = circulatingSupply[mintedItemId] + 1;
      itemGroups[groupId].mintCount = itemGroups[groupId].mintCount + 1;
      itemGroups[groupId].circulatingSupply =
        itemGroups[groupId].circulatingSupply + 1;

      //_holderTokens[address(0)].remove(_ids[i]);
      _holderTokens[_recipient].add(_ids[i]);

      _tokenOwners.set(_ids[i], _recipient);
      
      // Emit event and handle the safety check.
      emit Transfer(address(0), _recipient, _ids[i]);
      _doSafeTransferAcceptanceCheck(operator, address(0), _recipient, _ids[i], _data);
    }
  }

  /**
    The special, IMX-privileged minting function for centralized L2 support.
  */
  function mintFor(address _to, uint256 quantity, bytes calldata _blueprint) external {
      // check
    require(_msgSender() == imxCoreAddress, "Ix26");
    require(quantity == 1, "Ix27");
    require(!ISuper721IMXLock(super721IMXLock).mintForLocked(), "Ix28");
    // read data
    (uint256 id, bytes memory metadata_) = Utils.split(_blueprint);
    uint256[] memory ids = _asSingletonArray(id);
    // effects
    if(metadata_.length > 0){
        blueprints[id] = string(metadata_);
    }
    mintBatch(_to, ids, _blueprint);
  }

  /**
    This is a private helper function to verify, according to all of our various
    minting and burning rules, whether it would be valid to burn some `_amount`
    of a particular item `_id`.
    @param _id The ID of the item to check for burning validity.
    @return The ID of the item that should have `_amount` burnt for it.
  */
  function _burnChecker(uint256 _id) private view
    returns (uint256) {

    // Retrieve the item's group ID.
    uint256 shiftedGroupId = (_id & GROUP_MASK);
    uint256 groupId = shiftedGroupId >> 128;
    require(itemGroups[groupId].initialized,
      "Ix29");

    // If the item group is non-burnable, then revert.
    if (itemGroups[groupId].burnType == BurnType.None) {
      revert("Ix30");
    }

    // If we can burn items, then we must verify that we do not exceed the cap.
    else if (itemGroups[groupId].burnType == BurnType.Burnable) {
      require(itemGroups[groupId].burnCount + 1
        <= itemGroups[groupId].burnData,
        "Ix31");
    }

    // If the item is replenishable, then ignore checks

    uint256 burntItemId = _id;

    return burntItemId;
  }

  /**
    This function allows an address to destroy some of its items.
    @param _burner The address whose item is burning.
    @param _id The item ID to burn.
    @param _amount The amount of the corresponding item ID to burn.
  */
  // function burn(address _burner, uint256 _id, uint256 _amount)
  //   external virtual hasItemRight(_id, BURN) {
  //   require(_burner != address(0),
  //     "Super721::burn: burn from the zero address");
  //
  //   // Retrieve the group ID from the given item `_id` and check burn validity.
  //   uint256 shiftedGroupId = (_id & GROUP_MASK);
  //   uint256 groupId = shiftedGroupId >> 128;
  //   uint256 burntItemId = _burnChecker(_id, _amount);
  //
  //   // Validate and perform the burn.
  //   address operator = _msgSender();
  //   _beforeTokenTransfer(operator, _burner, address(0),
  //     _asSingletonArray(burntItemId), _asSingletonArray(_amount), "");
  //
  //   // Update storage of special balances and circulating values.
  //   balances[burntItemId][_burner] = balances[burntItemId][_burner]
  //     .sub(_amount,
  //     "Super721::burn: burn amount exceeds balance");
  //   groupBalances[groupId][_burner] = groupBalances[groupId][_burner]
  //     .sub(_amount);
  //   totalBalances[_burner] = totalBalances[_burner].sub(_amount);
  //   burnCount[burntItemId] = burnCount[burntItemId].add(_amount);
  //   circulatingSupply[burntItemId] = circulatingSupply[burntItemId]
  //     .sub(_amount);
  //   itemGroups[groupId].burnCount = itemGroups[groupId].burnCount.add(_amount);
  //   itemGroups[groupId].circulatingSupply =
  //     itemGroups[groupId].circulatingSupply.sub(_amount);
  //
  //   // Emit the burn event.
  //   emit Transfer(operator, address(0), _id);
  // }

  /**
    This function allows an address to destroy multiple different items in a
    single call.
    @param _burner The address whose items are burning.
    @param _ids The item IDs to burn.
  */
  function burnBatch(address _burner, uint256[] memory _ids) external virtual {
    require(_burner != address(0), "Super721::burnBatch: burn from the zero address");

    // Validate and perform the burn.
    address operator = _msgSender();
    _beforeTokenTransfer(operator, _burner, address(0), _ids, _asSingletonArray(1), "");

    // Loop through each of the batched IDs to update storage of special
    // balances and circulation balances.
    for (uint i = 0; i < _ids.length; i++) {
      require(_hasItemRight(_ids[i], BURN),
        "Ix32");

      // Retrieve the group ID from the given item `_id` and check burn.
      uint256 shiftedGroupId = (_ids[i] & GROUP_MASK);
      uint256 groupId = shiftedGroupId >> 128;
      uint256 burntItemId = _burnChecker(_ids[i]);

      // Update storage of special balances and circulating values.
      require(balances[burntItemId][_burner] >= 1, "Ix33");
      balances[burntItemId][_burner] = balances[burntItemId][_burner] - 1;
      groupBalances[groupId][_burner] = groupBalances[groupId][_burner] - 1;
      totalBalances[_burner] = totalBalances[_burner] - 1;
      burnCount[burntItemId] = burnCount[burntItemId] + 1;
      circulatingSupply[burntItemId] = circulatingSupply[burntItemId] - 1;
      itemGroups[groupId].burnCount = itemGroups[groupId].burnCount + 1;
      itemGroups[groupId].circulatingSupply =
        itemGroups[groupId].circulatingSupply - 1;

      _holderTokens[_burner].remove(_ids[i]);
      _holderTokens[address(0)].add(_ids[i]);

      // If burnType is None, burnChecker will revert that
      if(itemGroups[groupId].burnType == BurnType.Burnable)
        _tokenOwners.set(_ids[i], address(0));
      else
        _tokenOwners.remove(_ids[i]);

      // Emit the burn event.
      emit Transfer(operator, address(0), _ids[i]);
    }
  }

  function metadata(uint256 id) 
    external view
    returns(string memory)
    {
        return blueprints[id];
    }

  /**
    Set the on-chain metadata attached to a specific token ID so long as the
    collection as a whole or the token specifically has not had metadata
    editing frozen.
    @param _id The ID of the token to set the `_metadata` for.
    @param _metadata The metadata string to store on-chain.
  */
  function setMetadata(uint256 _id, string memory _metadata)
    external hasItemRight(_id, SET_METADATA) {
    uint groupId = _id >> 128;
    require(!uriLocked && !metadataFrozen[_id] &&  !metadataFrozen[groupId]);
    string memory oldMetadata = blueprints[_id];
    blueprints[_id] = _metadata;
    emit MetadataChanged(_msgSender(), _id, oldMetadata, _metadata);
  }

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on the entire collection to future changes.
  */
  function lockURI() external
    hasValidPermit(UNIVERSAL, LOCK_URI) {
    uriLocked = true;
    emit PermanentURI(metadataUri, 2 ** 256 - 1);
  }

  /**
    Allow the associated manager to forever lock the contract URI to future 
    changes
   */
  function lockContractUri() external
    hasValidPermit(UNIVERSAL, LOCK_URI) {
    contractUriLocked = true;
    emit PermanentContractURI(contractURI, 2 ** 256 - 1);   
  }

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on an item to future changes.
    @param _uri The value of the URI to lock for `_id`.
    @param _id The token ID to lock a metadata URI value into.
  */
  function lockItemURI(string calldata _uri, uint256 _id) external
    hasItemRight(_id, LOCK_ITEM_URI) {
    metadataFrozen[_id] = true;
    emit PermanentURI(_uri, _id);
  }

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on a group of items to future changes.

    @param _uri The value of the URI to lock for `groupId`.
    @param groupId The group ID to lock a metadata URI value into.
  */
  function lockGroupURI(string calldata _uri, uint256 groupId) external
    hasItemRight(groupId, LOCK_ITEM_URI) {
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

  function getApproved(uint256 tokenId) public view override returns (address) {
      require(_tokenOwners.contains(tokenId), "Ix34");

      return _tokenApprovals[tokenId];
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
      require(_tokenOwners.contains(tokenId), "Ix35");
      address owner = ownerOf(tokenId);
      return (spender == owner || _tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender));
  }
  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
      // //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "Ix36");
      safeTransferFrom(from, to, tokenId);
      //
      // require(ownerOf(tokenId) == from, "Super721::transferForm: transfer of token that is not own");
      // require(to != address(0), "Super721::transferForm: transfer to the zero address");
      //
      // _beforeTokenTransfer(_msgSender(), from, to, _asSingletonArray(tokenId), _asSingletonArray(1), "");
      //
      // // Clear approvals from the previous owner
      // //_approve(address(0), tokenId);
      // _tokenApprovals[tokenId] = address(0);
      // emit Approval(ownerOf(tokenId), address(0), tokenId);
      //
      // _holderTokens[from].remove(tokenId);
      // _holderTokens[to].add(tokenId);
      //
      // _tokenOwners.set(tokenId, to);
      //
      // emit Transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
      return _holderTokens[owner].at(index);
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view returns (uint256) {
      // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
      return _tokenOwners.length();
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
      (uint256 tokenId, ) = _tokenOwners.at(index);
      return tokenId;
  }

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

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

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
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
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
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
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
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
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
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
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
pragma solidity ^0.8.8;

library Utils {

    // this is struct for aligning function memory 
    struct Slice { 
        uint length;
        uint pointer;
    }

  function Concat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e)
        internal pure
        returns (string memory)
    {
        bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function Concat(string memory _a, string memory _b, string memory _c, string memory _d)
        internal pure
        returns (string memory)
    {
        return Concat(_a, _b, _c, _d, "");
    }

    function Concat(string memory _a, string memory _b, string memory _c)
        internal pure
        returns (string memory)
    {
        return Concat(_a, _b, _c, "", "");
    }

    function Concat(string memory _a, string memory _b)
        internal pure
        returns (string memory)
    {
        return Concat(_a, _b, "", "", "");
    }

    function uint2str(uint _i)
        internal pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    function copyToMemory(uint _destination, uint _source, uint _length)
        private pure
    {
        // Copy word-length chunks while possible
        for(_length ; _length >= 32; _length -= 32) {
            assembly {
                mstore(_destination, mload(_source))
            }
            _destination += 32;
            _source += 32;
        }

        // Copy remaining bytes
        if(_length >0){
            uint mask = 256 ** (32 - _length) - 1;
            assembly {
                let source := and(mload(_source), not(mask))
                let destination := and(mload(_destination), mask)
                mstore(_destination, or(destination, source))
            }
        }
    }

    // make struct slice out of string
    function toSlice(string memory input)
        internal pure
        returns (Slice memory)
    {
        uint ptr;
        assembly {
            ptr := add(input, 0x20)
        }
        return Slice(bytes(input).length, ptr);
    }

    function findPointer(uint inputLength, uint inputPointer, uint toSearchLength, uint toSearchPointer)
        private pure
        returns (uint)
    {
        uint pointer = inputPointer;

        if (toSearchLength <= inputLength) {
            if (toSearchLength <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - toSearchLength)) - 1));

                bytes32 toSearchdata;
                assembly { toSearchdata := and(mload(toSearchPointer), mask) }

                uint end = inputPointer + inputLength - toSearchLength;
                bytes32 data;
                assembly { data := and(mload(pointer), mask) }

                while (data != toSearchdata) {
                    if (pointer >= end)
                        return inputPointer + inputLength;
                    pointer++;
                    assembly { data := and(mload(pointer), mask) }
                }
                return pointer;
            } else {
                // For long toSearchs, use hashing
                bytes32 hash;
                assembly { hash := keccak256(toSearchPointer, toSearchLength) }

                for (uint i = 0; i <= inputLength - toSearchLength; i++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(pointer, toSearchLength) }
                    if (hash == testHash)
                        return pointer;
                    pointer += 1;
                }
            }
        }
        return inputPointer + inputLength;
    }

    function afterMatch(Slice memory input, Slice memory toSearch)
        internal pure
        returns (Slice memory)
    {
        uint pointer = findPointer(input.length, input.pointer, toSearch.length, toSearch.pointer);
        input.length -= pointer - input.pointer + 1; // escape void space
        input.pointer = pointer +1; // escape token
        return input;
    }

    function beforeMatch(Slice memory input, Slice memory toSearch)
        internal pure
        returns (Slice memory token)
    {
        beforeMatch(input, toSearch, token);
    }

    function beforeMatch(Slice memory input, Slice memory toSearch, Slice memory token)
        internal pure
        returns (Slice memory)
    {
        uint pointer = findPointer(input.length, input.pointer, toSearch.length, toSearch.pointer);
        token.pointer = input.pointer;
        token.length = pointer - input.pointer;
        if (pointer == input.pointer + input.length) {
            // Not found
            input.length = 0;
        } else {
            input.length -= token.length + toSearch.length;
            input.pointer = pointer + toSearch.length;
        }
        return token;
    }

    function toString(Slice memory input)
        internal pure
        returns (string memory)
    {
        string memory result = new string(input.length);
        uint resultPointer;
        assembly { resultPointer := add(result, 32) }

        copyToMemory(resultPointer, input.pointer, input.length);
        return result;
    }

    function split(bytes calldata blob)
        internal
        pure
        returns (uint256, bytes memory)
    {
        int256 index = indexOf(blob, ":", 0);
        require(index >= 0, "Separator must exist");
        // Trim the { and } from the parameters
        uint256 tokenID = toUint(blob[1:uint256(index) - 1]);
        uint256 blueprintLength = blob.length - uint256(index) - 3;
        if (blueprintLength == 0) {
            return (tokenID, bytes(""));
        }
        bytes calldata blueprint = blob[uint256(index) + 2:blob.length - 1];
        return (tokenID, blueprint);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(
        bytes memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _base.length; i++) {
            if (_base[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    function toUint(bytes memory b) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 val = uint256(uint8(b[i]));
            if (val >= 48 && val <= 57) {
                result = result * 10 + (val - 48);
            }
        }
        return result;
    }

    function interpolate(string memory source, uint value) internal pure returns (string memory result){
        Slice memory slice1 = toSlice(source);
        Slice memory slice2 = toSlice(source);
        string memory tokenFirst = "{";
        string memory tokenLast = "}";
        Slice memory firstSlice = toSlice(tokenFirst);
        Slice memory secondSlice = toSlice(tokenLast);
        firstSlice = beforeMatch(slice1, firstSlice);
        secondSlice = afterMatch(slice2, secondSlice);
        string memory first = toString(firstSlice);
        string memory second = toString(secondSlice);
        result = Concat(first, uint2str(value), second);
        return result;
    }
}

/**
 * @title ArrayUtils
 * @author Project Wyvern Developers
 */
library ArrayUtils {

    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     * 
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     */
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        internal pure
    {
        require(array.length == desired.length, "Ux02");
        require(array.length == mask.length, "Ux03");

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     * 
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes memory source)
        internal pure
        returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for { } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address array into a memory location
     *
     * @param index Memory location
     * @param source Address array to write
     * @return End memory index
     */
    function unsafeWriteUintArray(uint index, uint[] memory source)
        internal pure
        returns (uint)
    {   
        for (uint i = 0; i < source.length; i++){
            uint conv = uint(uint160(source[i])) << 0x60;
            assembly {
                mstore(index, conv)
                index := add(index, 0x14)
            }
        }
        return index;
    }

    /**
     * Unsafe write address nested array into a memory location
     *
     * @param index Memory location
     * @param source Address nested array to write
     * @return End memory index
     */
    function unsafeWriteAddressMap(uint index, address[][] memory source)
        internal pure
        returns (uint)
    {   
        for (uint i = 0; i < source.length; i++){
            for (uint j = 0; j < source[i].length; j++){
                uint conv = uint(uint160(source[i][j])) << 0x60;
                assembly {
                    mstore(index, conv)
                    index := add(index, 0x14)
                }
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
        internal pure
        returns (uint)
    {
        uint conv = uint(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
        internal pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
        internal pure
        returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.8;

interface ISuper721IMXLock {

    function mintForLocked() external view returns(bool);

    function toggleMintFor() external;
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