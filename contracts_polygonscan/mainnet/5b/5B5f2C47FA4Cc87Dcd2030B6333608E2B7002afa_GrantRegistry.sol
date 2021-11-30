// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IMetadataPointer.sol";

/**
 * @notice The Gitcoin GrantRegistry contract keeps track of all grants that have been created.
 * It is designed to be a singleton, i.e. there is only one instance of a GrantRegistry which
 * tracks all grants. It behaves as follows:
 *   - Anyone can create a grant by calling `createGrant`
 *   - A grant's `owner` can edit their grant using the `updateGrant` family of method
 *   - The `getAllGrants` and `getGrants` view methods are used to fetch grant data
 */
contract GrantRegistry {
  // --- Data ---
  /// @notice Number of grants stored in this registry
  uint96 public grantCount;

  /// @notice Grant object
  struct Grant {
    // Slot 1 (within this struct)
    // Using a uint96 for the grant ID means a max of 2^96-1 = 7.9e28 grants
    uint96 id; // grant ID, as
    address owner; // grant owner (has permissions to modify grant information)
    // Slot 2
    // Using uint48 for timestamps means a maximum timestamp of 2^48-1 = 281474976710655 = year 8.9 million
    uint48 createdAt; // timestamp the grant was created, uint48
    uint48 lastUpdated; // timestamp the grant data was last updated in this registry
    address payee; // address that receives funds donated to this grant
    // Slots 3+
    MetaPtr metaPtr; // metadata pointer
  }

  /// @notice Mapping from Grant ID to grant data
  mapping(uint96 => Grant) public grants;

  // --- Events ---
  /// @notice Emitted when a new grant is created
  event GrantCreated(uint96 indexed id, address indexed owner, address indexed payee, MetaPtr metaPtr, uint256 time);

  /// @notice Emitted when a grant's owner is changed
  event GrantUpdated(uint96 indexed id, address indexed owner, address indexed payee, MetaPtr metaPtr, uint256 time);

  // --- Core methods ---
  /**
   * @notice Create a new grant in the registry
   * @param _owner Grant owner (has permissions to modify grant information)
   * @param _payee Address that receives funds donated to this grant
   * @param _metaPtr metadata pointer
   */
  function createGrant(
    address _owner,
    address _payee,
    MetaPtr calldata _metaPtr
  ) external {
    uint96 _id = grantCount;
    grants[_id] = Grant(_id, _owner, uint48(block.timestamp), uint48(block.timestamp), _payee, _metaPtr);
    emit GrantCreated(_id, _owner, _payee, _metaPtr, block.timestamp);
    grantCount += 1;
  }

  /**
   * @notice Update the owner of a grant
   * @param _id ID of grant to update
   * @param _owner New owner address
   */
  function updateGrantOwner(uint96 _id, address _owner) external {
    Grant storage grant = grants[_id];
    require(msg.sender == grant.owner, "GrantRegistry: Not authorized");
    grant.owner = _owner;
    grant.lastUpdated = uint48(block.timestamp);
    emit GrantUpdated(grant.id, grant.owner, grant.payee, grant.metaPtr, block.timestamp);
  }

  /**
   * @notice Update the payee of a grant
   * @param _id ID of grant to update
   * @param _payee New payee address
   */
  function updateGrantPayee(uint96 _id, address _payee) external {
    Grant storage grant = grants[_id];
    require(msg.sender == grant.owner, "GrantRegistry: Not authorized");
    grant.payee = _payee;
    grant.lastUpdated = uint48(block.timestamp);
    emit GrantUpdated(grant.id, grant.owner, grant.payee, grant.metaPtr, block.timestamp);
  }

  /**
   * @notice Update the metadata pointer of a grant
   * @param _id ID of grant to update
   * @param _metaPtr New URL that points to grant metadata
   */
  function updateGrantMetaPtr(uint96 _id, MetaPtr calldata _metaPtr) external {
    Grant storage grant = grants[_id];
    require(msg.sender == grant.owner, "GrantRegistry: Not authorized");
    grant.metaPtr = _metaPtr;
    grant.lastUpdated = uint48(block.timestamp);
    emit GrantUpdated(grant.id, grant.owner, grant.payee, grant.metaPtr, block.timestamp);
  }

  /**
   * @notice Update multiple fields of a grant at once
   * @dev To leave a field unchanged, you must pass in the same value as the current value
   * @param _id ID of grant to update
   * @param _owner New owner address
   * @param _payee New payee address
   * @param _metaPtr New URL that points to grant metadata
   */
  function updateGrant(
    uint96 _id,
    address _owner,
    address _payee,
    MetaPtr calldata _metaPtr
  ) external {
    Grant memory _grant = grants[_id];
    require(msg.sender == _grant.owner, "GrantRegistry: Not authorized");
    grants[_id] = Grant(_id, _owner, _grant.createdAt, uint48(block.timestamp), _payee, _metaPtr);
    emit GrantUpdated(_id, _owner, _payee, _metaPtr, block.timestamp);
  }

  // --- View functions ---
  /**
   * @notice Returns an array of all grants and their on-chain data
   * @dev May run out of gas for large values `grantCount`, depending on the node's RpcGasLimit. In these cases,
   * `getGrants` can be used to fetch a subset of grants and aggregate the results of various calls off-chain
   */
  function getAllGrants() external view returns (Grant[] memory) {
    return getGrants(0, grantCount);
  }

  /**
   * @notice Returns a range of grants and their on-chain data
   * @param _startId Grant ID of first grant to return, inclusive, i.e. this grant ID is included in return data
   * @param _endId Grant ID of last grant to return, exclusive, i.e. this grant ID is NOT included in return data
   */
  function getGrants(uint96 _startId, uint96 _endId) public view returns (Grant[] memory) {
    require(_endId <= grantCount, "GrantRegistry: _endId must be <= grantCount");
    require(_startId <= _endId, "GrantRegistry: Invalid ID range");
    Grant[] memory grantList = new Grant[](_endId - _startId);
    for (uint96 i = _startId; i < _endId; i++) {
      grantList[i - _startId] = grants[i]; // use index of `i - _startId` so index starts at zero
    }
    return grantList;
  }

  /**
   * @notice Returns the address that will be used to pay out donations for a given grant
   * @dev The payee may be set to null address
   * @param _id Grant ID used to retrieve the payee address in the registry
   */
  function getGrantPayee(uint96 _id) public view returns (address) {
    require(_id < grantCount, "GrantRegistry: Grant does not exist");
    return grants[_id].payee;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.6;

struct MetaPtr {
  // Protocol ID corresponding to a specific protocol. More info at https://github.com/dcgtc/protocol-ids
  uint256 protocol;
  // Pointer to fetch metadata for the specified protocol
  string pointer;
}