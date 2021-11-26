pragma solidity 0.7.4;

import "../utils/TieredOwnable.sol";
import "../interfaces/ISkyweaverAssets.sol";
import "../interfaces/IRewardFactory.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";

/**
 * @notice Keep track of players participation in Conquest and used to issue rewards.
 * @dev This contract must be at least a TIER 1 owner of the silverCardFactory and
 *      goldCardFactory.
 */
contract Conquest is IERC1155TokenReceiver, TieredOwnable {
  using SafeMath for uint256;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // Parameters
  uint256 constant internal TIME_BETWEEN_CONQUESTS = 1 seconds; // Seconds that must elapse between two conquest
  uint256 constant internal ENTRIES_DECIMALS = 2;               // Amount of decimals conquest entries have
  uint256 constant internal CARDS_DECIMALS = 2;                 // Number of decimals cards have

  // Contracts
  IRewardFactory immutable public silverCardFactory; // Factory that mints Silver cards
  IRewardFactory immutable public goldCardFactory;   // Factory that mints Gold cards
  ISkyweaverAssets immutable public skyweaverAssets; // ERC-1155 Skyweaver assets contract
  uint256 immutable public conquestEntryID;          // Conquest entry token id

  // Mappings
  mapping(address => bool) public isActiveConquest;    // Whether a given player is currently in a conquest
  mapping(address => uint256) public conquestsEntered; // Number of conquest a given player has entered so far
  mapping(address => uint256) public nextConquestTime; // Time when the next conquest can be started for players

  // Event
  event ConquestEntered(address user, uint256 nConquests);


  /***********************************|
  |            Constructor            |
  |__________________________________*/

  /**
   * @notice Link factories and skyweaver assets, store initial parameters
   * @param _firstOwner               Address of the first owner
   * @param _skyweaverAssetsAddress   The address of the ERC-1155 Assets Token contract
   * @param _silverCardFactoryAddress The address of the Silver Card Factory
   * @param _goldCardFactoryAddress   The address of the Gold Card Factory
   * @param _conquestEntryTokenId     Conquest entry token id
   */
  constructor(
    address _firstOwner,
    address _skyweaverAssetsAddress,
    address _silverCardFactoryAddress,
    address _goldCardFactoryAddress,
    uint256 _conquestEntryTokenId
  ) TieredOwnable(_firstOwner) public 
  {
    require(
      _skyweaverAssetsAddress != address(0) &&
      _silverCardFactoryAddress != address(0) &&
      _goldCardFactoryAddress != address(0),
      "Conquest#constructor: INVALID_INPUT"
    );

    // Store parameters
    skyweaverAssets = ISkyweaverAssets(_skyweaverAssetsAddress);
    silverCardFactory = IRewardFactory(_silverCardFactoryAddress);
    goldCardFactory = IRewardFactory(_goldCardFactoryAddress);
    conquestEntryID = _conquestEntryTokenId;
  }

  
  /***********************************|
  |      Receiver Method Handler      |
  |__________________________________*/

  /**
   * @notice Prevents receiving Ether or calls to unsupported methods
   */
  fallback () external {
    revert("Conquest#_: UNSUPPORTED_METHOD");
  }

  /**
   * @notice Players entering conquest with conquest entry token
   * @dev Payload is passed to and verified by onERC1155BatchReceived()
   */
  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id, 
    uint256 _amount, 
    bytes calldata _data
  )
    external override returns(bytes4)
  {
    // Convert payload to arrays to pass to onERC1155BatchReceived()
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ids[0] = _id;
    amounts[0] = _amount;

    // Will revert call if doesn't pass
    onERC1155BatchReceived(_operator, _from, ids, amounts, _data);
    
    // Return success
    return IERC1155TokenReceiver.onERC1155Received.selector;
  }

  /**
   * @notice Conquest entry point. Will mark user as having entered conquest if valid entry.
   * @param _from    Address who sent the token
   * @param _ids     An array containing ids of each Token being transferred
   * @param _amounts An array containing amounts of each Token being transferred
   */
  function onERC1155BatchReceived(
    address, // _operator
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory // _data
  )
    public override returns(bytes4)
  {
    require(msg.sender == address(skyweaverAssets), "Conquest#entry: INVALID_ENTRY_TOKEN_ADDRESS");
    require(_ids.length == 1, "Conquest#entry: INVALID_IDS_ARRAY_LENGTH");
    require(_amounts.length == 1, "Conquest#entry: INVALID_AMOUNTS_ARRAY_LENGTH");
    require(_ids[0] == conquestEntryID, "Conquest#entry: INVALID_ENTRY_TOKEN_ID");
    require(_amounts[0] == 10**ENTRIES_DECIMALS, "Conquest#entry: INVALID_ENTRY_TOKEN_AMOUNT");
    require(!isActiveConquest[_from], "Conquest#entry: PLAYER_ALREADY_IN_CONQUEST");
    require(nextConquestTime[_from] <= block.timestamp, "Conquest#entry: NEW_CONQUEST_TOO_EARLY");

    // Mark player as playing
    isActiveConquest[_from] = true;
    conquestsEntered[_from] = conquestsEntered[_from].add(1);
    nextConquestTime[_from] = block.timestamp.add(TIME_BETWEEN_CONQUESTS);

    // Burn tickets
    skyweaverAssets.burn(conquestEntryID, 10**ENTRIES_DECIMALS);

    // Emit event
    emit ConquestEntered(_from, conquestsEntered[_from]);

    // Return success
    return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
  }


  /***********************************|
  |         Minting Functions         |
  |__________________________________*/

  /**
   * @notice Will exit user from conquest and mint tokens to user 
   * @param _user      The address that exits conquest and receive the rewards
   * @param _silverIds Ids of silver cards to mint (duplicate ids if amount > 1)
   * @param _goldIds   Ids of gold cards to mint (duplicate ids if amount > 1)
   */
  function exitConquest(address _user, uint256[] calldata _silverIds, uint256[] calldata _goldIds)
    external onlyOwnerTier(1)
  { 
    require(isActiveConquest[_user], "Conquest#exitConquest: USER_IS_NOT_IN_CONQUEST");

    // Mark player as not playing anymore
    isActiveConquest[_user] = false;

    // 0 win - 1 loss ===> 0 rewards
    if (_silverIds.length == 0 && _goldIds.length == 0) {
      /*  Do nothing if user didn't win any matches  */

    // 1 win - 1 loss ===> 1 Silver card
    } else if (_silverIds.length == 1 && _goldIds.length == 0) { 
      silverCardFactory.batchMint(_user, _silverIds, array(1, 10**CARDS_DECIMALS), "");

    // 2 wins - 1 loss ===> 2 silver cards
    } else if (_silverIds.length == 2 && _goldIds.length == 0) { 
      silverCardFactory.batchMint(_user, _silverIds, array(2, 10**CARDS_DECIMALS), "");

    // 3 wins - 0 loss ===> 1 Silver card and 1 Gold card
    } else if (_silverIds.length == 1 && _goldIds.length == 1) { 
      silverCardFactory.batchMint(_user, _silverIds, array(1, 10**CARDS_DECIMALS), "");
      goldCardFactory.batchMint(_user, _goldIds, array(1, 10**CARDS_DECIMALS), "");

    // Revert for any other combination
    } else {
      revert("Conquest#exitConquest: INVALID_REWARDS");
    }
  }

  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /** 
   * @notice Will create an array of uint _value of length _length
   * @param _length Number of elements in array
   * @param _value  Value to put in array at each element
   */
  function array(uint256 _length, uint256 _value) internal pure returns (uint256[] memory) {
    uint256[] memory a = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      a[i] = _value;
    }
    return a;
  }

  /**
   * @notice Indicates whether a contract implements a given interface.
   * @param interfaceID The ERC-165 interface ID that is queried for support.
   * @return True if contract interface is supported.
   */
  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId || 
      interfaceID == type(IERC1155TokenReceiver).interfaceId;
  }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../utils/Ownable.sol";

import "@0xsequence/erc-1155/contracts/tokens/ERC1155PackedBalance/ERC1155MintBurnPackedBalance.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155Metadata.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC2981/ERC2981Global.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";


/**
 * ERC-1155 token contract for skyweaver assets.
 * This contract manages the various SW asset factories
 * and ensures that each factory has constraint access in
 * terms of the id space they are allowed to mint.
 * @dev Mint permissions use range because factory contracts
 *      could be minting large numbers of NFTs or be built
 *      with granular, but efficient permission checks.
 */
contract SkyweaverAssets is ERC1155MintBurnPackedBalance, ERC1155Metadata, ERC2981Global, Ownable {
  using SafeMath for uint256;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // Factory mapping variables
  mapping(address => bool) internal isFactoryActive;          // Whether an address can print tokens or not
  mapping(address => AssetRange[]) internal mintAccessRanges; // Contains the ID ranges factories are allowed to mint
  AssetRange[] internal lockedRanges;                         // Ranges of IDs that can't be granted permission to mint

  // Issuance mapping variables
  mapping (uint256 => uint256) internal currentIssuance; // Current Issuance of token for tokens that have max issuance ONLY
  mapping (uint256 => uint256) internal maxIssuance;     // Issuance is counted and capped to associated maxIssuance if it's non-zero

  // Struct for mint ID ranges permissions
  struct AssetRange {
    uint64 minID;     // Minimum value the ID need to be to fall in the range
    uint64 maxID;     // Maximum value the ID need to be to fall in the range
    uint64 startTime; // Timestamp when the range becomes valid
    uint64 endTime;   // Timestamp after which the range is no longer valid 
  }

  /***********************************|
  |               Events              |
  |__________________________________*/

  event FactoryActivation(address indexed factory);
  event FactoryShutdown(address indexed factory);
  event MaxIssuancesChanged(uint256[] ids, uint256[] newMaxIssuances);
  event MintPermissionAdded(address indexed factory, AssetRange new_range);
  event MintPermissionRemoved(address indexed factory, AssetRange deleted_range);
  event RangeLocked(AssetRange locked_range);


  /***********************************|
  |             Constuctor            |
  |__________________________________*/
  
  constructor (address _firstOwner) ERC1155Metadata("Skyweaver", "") Ownable(_firstOwner) public {}


  /***********************************|
  |     Factory Management Methods    |
  |__________________________________*/

  /**
   * @notice Will ALLOW factory to print some assets specified in `canPrint` mapping
   * @param _factory Address of the factory to activate
   */
  function activateFactory(address _factory) external onlyOwner() {
    isFactoryActive[_factory] = true;
    emit FactoryActivation(_factory);
  }

  /**
   * @notice Will DISALLOW factory to print any asset
   * @param _factory Address of the factory to shutdown
   */
  function shutdownFactory(address _factory) external onlyOwner() {
    isFactoryActive[_factory] = false;
    emit FactoryShutdown(_factory);
  }

  /**
   * @notice Will allow a factory to mint some token ids
   * @param _factory   Address of the factory to update permission
   * @param _minRange  Minimum ID (inclusive) in id range that factory will be able to mint
   * @param _maxRange  Maximum ID (inclusive) in id range that factory will be able to mint
   * @param _startTime Timestamp when the range becomes valid
   * @param _endTime   Timestamp after which the range is no longer valid 
   */
  function addMintPermission(address _factory, uint64 _minRange, uint64 _maxRange, uint64 _startTime, uint64 _endTime) external onlyOwner() {
    require(_maxRange > 0, "SkyweaverAssets#addMintPermission: NULL_RANGE");
    require(_minRange <= _maxRange, "SkyweaverAssets#addMintPermission: INVALID_RANGE");
    require(_startTime < _endTime, "SkyweaverAssets#addMintPermission: START_TIME_IS_NOT_LESSER_THEN_END_TIME");

    // Check if new range has an overlap with locked ranges.
    // lockedRanges is expected to be a small array
    for (uint256 i = 0; i < lockedRanges.length; i++) {
      AssetRange memory locked_range = lockedRanges[i];
      require(
        (_maxRange < locked_range.minID) || (locked_range.maxID < _minRange),
        "SkyweaverAssets#addMintPermission: OVERLAP_WITH_LOCKED_RANGE"
      );
    }

    // Create and store range struct for _factory
    AssetRange memory range = AssetRange(_minRange, _maxRange, _startTime, _endTime);
    mintAccessRanges[_factory].push(range);
    emit MintPermissionAdded(_factory, range);
  }

  /**
   * @notice Will remove the permission a factory has to mint some token ids
   * @param _factory    Address of the factory to update permission
   * @param _rangeIndex Array's index where the range to delete is located for _factory
   */
  function removeMintPermission(address _factory, uint256 _rangeIndex) external onlyOwner() {
    // Will take the last range and put it where the "hole" will be after
    // the AssetRange struct at _rangeIndex is deleted
    uint256 last_index = mintAccessRanges[_factory].length - 1; // won't underflow because of require() statement above
    AssetRange memory range_to_delete = mintAccessRanges[_factory][_rangeIndex]; // Stored for log

    if (_rangeIndex != last_index) {
      AssetRange memory last_range = mintAccessRanges[_factory][last_index]; // Retrieve the range that will be moved
      mintAccessRanges[_factory][_rangeIndex] = last_range;                  // Overwrite the "to-be-deleted" range
    }

    // Delete last element of the array
    mintAccessRanges[_factory].pop();
    emit MintPermissionRemoved(_factory, range_to_delete);
  }

  /**
   * @notice Will forever prevent new mint permissions for provided ids
   * @dev THIS ACTION IS IRREVERSIBLE, USE WITH CAUTION
   * @dev In order to forever restrict minting of certain ids to a set of factories,
   *      one first needs to call `addMintPermission()` for the corresponding factory
   *      and the corresponding ids, then call this method to prevent further mint
   *      permissions to be granted. One can also remove mint permissions after ids
   *      mint permissions where locked down.
   * @param _range AssetRange struct for range of asset that can't be granted
   *               new mint permission to
   */
  function lockRangeMintPermissions(AssetRange memory _range) public onlyOwner() {
    lockedRanges.push(_range);
    emit RangeLocked(_range);
  }

  /***********************************|
  |    Supplies Management Methods    |
  |__________________________________*/

  /**
   * @notice Set max issuance for some token IDs that can't ever be increased
   * @dev Can only decrease the max issuance if already set, but can't set it *back* to 0.
   * @param _ids Array of token IDs to set the max issuance
   * @param _newMaxIssuances Array of max issuances for each corresponding ID
   */
  function setMaxIssuances(uint256[] calldata _ids, uint256[] calldata _newMaxIssuances) external onlyOwner() {
    require(_ids.length == _newMaxIssuances.length, "SkyweaverAssets#setMaxIssuances: INVALID_ARRAYS_LENGTH");

    // Can only *decrease* a max issuance
    // Can't set max issuance back to 0
    for (uint256 i = 0; i < _ids.length; i++ ) {
      if (maxIssuance[_ids[i]] > 0) {
        require(
          0 < _newMaxIssuances[i] && _newMaxIssuances[i] < maxIssuance[_ids[i]],
          "SkyweaverAssets#setMaxIssuances: INVALID_NEW_MAX_ISSUANCE"
        );
      }
      maxIssuance[_ids[i]] = _newMaxIssuances[i];
    }

    emit MaxIssuancesChanged(_ids, _newMaxIssuances);
  }

  /***********************************|
  |    Royalty Management Methods     |
  |__________________________________*/

  /**
   * @notice Will set the basis point and royalty recipient that is applied to all Skyweaver assets
   * @param _receiver Fee recipient that will receive the royalty payments
   * @param _royaltyBasisPoints Basis points with 3 decimals representing the fee %
   *        e.g. a fee of 2% would be 20 (i.e. 20 / 1000 == 0.02, or 2%)
   */
  function setGlobalRoyaltyInfo(address _receiver, uint256 _royaltyBasisPoints) external onlyOwner() {
    _setGlobalRoyaltyInfo(_receiver, _royaltyBasisPoints);
  }

  /***********************************|
  |      Receiver Method Handler      |
  |__________________________________*/

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("UNSUPPORTED_METHOD");
  }

  /***********************************|
  |          Minting Function         |
  |__________________________________*/

  /**
   * @notice Mint tokens for each ids in _ids
   * @dev This methods assumes ids are sorted by how the ranges are sorted in
   *      the corresponding mintAccessRanges[msg.sender] array. Call might throw
   *      if they are not.
   * @param _to      The address to mint tokens to.
   * @param _ids     Array of ids to mint
   * @param _amounts Array of amount of tokens to mint per id
   * @param _data    Byte array of data to pass to recipient if it's a contract
   */
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data) public
  {
    // Validate assets to be minted
    _validateMints(_ids, _amounts);

    // If hasn't reverted yet, all IDs are allowed for factory
    _batchMint(_to, _ids, _amounts, _data);
  }

  /**
   * @notice Mint _amount of tokens of a given id, if allowed.
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function mint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external
  {
    // Put into array for validation
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ids[0] = _id;
    amounts[0] = _amount;

    // Validate and mint
    _validateMints(ids, amounts);
    _mint(_to, _id, _amount, _data);
  }

  /**
   * @notice Will validate the ids and amounts to mint
   * @dev This methods assumes ids are sorted by how the ranges are sorted in
   *      the corresponding mintAccessRanges[msg.sender] array. Call will revert
   *      if they are not.
   * @dev When the maxIssuance of an asset is set to a non-zero value, the
   *      supply manager contract will start keeping track of how many of that
   *      token are minted, until the maxIssuance hit.
   * @param _ids     Array of ids to mint
   * @param _amounts Array of amount of tokens to mint per id
   */
  function _validateMints(uint256[] memory _ids, uint256[] memory _amounts) internal {
    require(isFactoryActive[msg.sender], "SkyweaverAssets#_validateMints: FACTORY_NOT_ACTIVE");

    // Number of mint ranges
    uint256 n_ranges = mintAccessRanges[msg.sender].length;

    // Load factory's default range
    AssetRange memory range = mintAccessRanges[msg.sender][0];
    uint256 range_index = 0;

    // Will make sure that factory is allowed to print all ids
    // and that no max issuance is exceeded
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      uint256 amount = _amounts[i];
      uint256 max_issuance = maxIssuance[id];

      // If ID is out of current range, move to next range, else skip.
      // This function only moves forwards in the AssetRange array,
      // hence if _ids are not sorted correctly, the call will fail.
      while (block.timestamp < range.startTime || block.timestamp > range.endTime || id < range.minID || range.maxID < id) {
        range_index += 1;

        // Load next range. If none left, ID is assumed to be out of all ranges
        require(range_index < n_ranges, "SkyweaverAssets#_validateMints: ID_OUT_OF_RANGE");
        range = mintAccessRanges[msg.sender][range_index];
      }

      // If max supply is specified for id
      if (max_issuance > 0) {
        uint256 new_current_issuance = currentIssuance[id].add(amount);
        require(new_current_issuance <= max_issuance, "SkyweaverAssets#_validateMints: MAX_ISSUANCE_EXCEEDED");
        currentIssuance[id] = new_current_issuance;
      }
    }
  }

  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Get the max issuance of multiple asset IDs
   * @dev The max issuance of a token does not reflect the maximum supply, only
   *      how many tokens can be minted once the maxIssuance for a token is set.
   * @param _ids Array containing the assets IDs
   * @return The current max issuance of each asset ID in _ids
   */
  function getMaxIssuances(uint256[] calldata _ids) external view returns (uint256[] memory) {
    uint256 nIds = _ids.length;
    uint256[] memory max_issuances = new uint256[](nIds);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < nIds; i++) {
      max_issuances[i] = maxIssuance[_ids[i]];
    }

    return max_issuances;
  }

  /**
   * @notice Get the current issuanc of multiple asset ID
   * @dev The current issuance of a token does not reflect the current supply, only
   *      how many tokens since a max issuance was set for a given token id.
   * @param _ids Array containing the assets IDs
   * @return The current issuance of each asset ID in _ids
   */
  function getCurrentIssuances(uint256[] calldata _ids) external view returns (uint256[] memory) {
    uint256 nIds = _ids.length;
    uint256[] memory current_issuances = new uint256[](nIds);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < nIds; i++) {
      current_issuances[i] = currentIssuance[_ids[i]];
    }

    return current_issuances;
  }

  /**
   * @return Returns whether a factory is active or not
   */
  function getFactoryStatus(address _factory) external view returns (bool) {
    return isFactoryActive[_factory];
  }

  /**
   * @return Returns whether the sale has ended or not
   */
  function getFactoryAccessRanges(address _factory) external view returns (AssetRange[] memory) {
    return mintAccessRanges[_factory];
  }

  /**
   * @return Returns all the ranges that are locked
   */
  function getLockedRanges() external view returns (AssetRange[] memory) {
    return lockedRanges;
  }

  /***********************************|
  |          Burning Functions        |
  |__________________________________*/

  /**
   * @notice Burn _amount of tokens of a given id from msg.sender
   * @dev This will not change the current issuance tracked in _supplyManagerAddr.
   * @param _id     Asset id to burn
   * @param _amount The amount to be burn
   */
  function burn(
    uint256 _id,
    uint256 _amount)
    external
  {
    _burn(msg.sender, _id, _amount);
  }

  /**
   * @notice Burn _amounts of tokens of given ids from msg.sender
   * @dev This will not change the current issuance tracked in _supplyManagerAddr.
   * @param _ids     Asset id to burn
   * @param _amounts The amount to be burn
   */
  function batchBurn(
    uint256[] calldata _ids,
    uint256[] calldata _amounts)
    external
  {
    _batchBurn(msg.sender, _ids, _amounts);
  }

  /***********************************|
  |           URI Functions           |
  |__________________________________*/

  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function setBaseMetadataURI(string calldata _newBaseMetadataURI) external onlyOwner() {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }

  /**
   * @dev Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function logURIs(uint256[] calldata _tokenIDs) external onlyOwner() {
    _logURIs(_tokenIDs);
  }

  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC1155PackedBalance, ERC1155Metadata, ERC2981Global) virtual pure returns (bool) {
    return super.supportsInterface(_interfaceID);
  }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface ISkyweaverAssets {

  /***********************************|
  |               Events              |
  |__________________________________*/

  event FactoryActivation(address indexed factory);
  event FactoryShutdown(address indexed factory);
  event MintPermissionAdded(address indexed factory, AssetRange new_range);
  event MintPermissionRemoved(address indexed factory, AssetRange deleted_range);

  // Struct for mint ID ranges permissions
  struct AssetRange {
    uint256 minID;
    uint256 maxID;
  }

  /***********************************|
  |    Supplies Management Methods    |
  |__________________________________*/

  /**
   * @notice Set max issuance for some token IDs that can't ever be increased
   * @dev Can only decrease the max issuance if already set, but can't set it *back* to 0.
   * @param _ids Array of token IDs to set the max issuance
   * @param _newMaxIssuances Array of max issuances for each corresponding ID
   */
  function setMaxIssuances(uint256[] calldata _ids, uint256[] calldata _newMaxIssuances) external;

  /***********************************|
  |     Factory Management Methods    |
  |__________________________________*/

  /**
   * @notice Will allow a factory to mint some token ids
   * @param _factory   Address of the factory to update permission
   * @param _minRange  Minimum ID (inclusive) in id range that factory will be able to mint
   * @param _maxRange  Maximum ID (inclusive) in id range that factory will be able to mint
   * @param _startTime Timestamp when the range becomes valid
   * @param _endTime   Timestamp after which the range is no longer valid 
   */
  function addMintPermission(address _factory, uint64 _minRange, uint64 _maxRange, uint64 _startTime, uint64 _endTime) external;

  /**
   * @notice Will remove the permission a factory has to mint some token ids
   * @param _factory    Address of the factory to update permission
   * @param _rangeIndex Array's index where the range to delete is located for _factory
   */
  function removeMintPermission(address _factory, uint256 _rangeIndex) external;

  /**
   * @notice Will ALLOW factory to print some assets specified in `canPrint` mapping
   * @param _factory Address of the factory to activate
   */
  function activateFactory(address _factory) external;

  /**
   * @notice Will DISALLOW factory to print any asset
   * @param _factory Address of the factory to shutdown
   */
  function shutdownFactory(address _factory) external;

  /**
   * @notice Will forever prevent new mint permissions for provided ids
   * @param _range AssetRange struct for range of asset that can't be granted
   *               new mint permission to
   */
  function lockRangeMintPermissions(AssetRange calldata _range) external;


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @return Returns whether a factory is active or not
   */
  function getFactoryStatus(address _factory) external view returns (bool);

  /**
   * @return Returns whether the sale has ended or not
   */
  function getFactoryAccessRanges(address _factory) external view returns ( AssetRange[] memory);

  /**
   * @notice Get the max issuance of multiple asset IDs
   * @dev The max issuance of a token does not reflect the maximum supply, only
   *      how many tokens can be minted once the maxIssuance for a token is set.
   * @param _ids Array containing the assets IDs
   * @return The current max issuance of each asset ID in _ids
   */
  function getMaxIssuances(uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Get the current issuanc of multiple asset ID
   * @dev The current issuance of a token does not reflect the current supply, only
   *      how many tokens since a max issuance was set for a given token id.
   * @param _ids Array containing the assets IDs
   * @return The current issuance of each asset ID in _ids
   */
  function getCurrentIssuances(uint256[] calldata _ids)external view returns (uint256[] memory);

  /***************************************|
  |           Minting Functions           |
  |______________________________________*/

  /**
   * @dev Mint _amount of tokens of a given id if not frozen and if max supply not exceeded
   * @param _to     The address to mint tokens to.
   * @param _id     Token id to mint
   * @param _amount The amount to be minted
   * @param _data   Byte array of data to pass to recipient if it's a contract
   */
  function mint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
   * @dev Mint tokens for each ids in _ids
   * @param _to      The address to mint tokens to.
   * @param _ids     Array of ids to mint
   * @param _amounts Array of amount of tokens to mint per id
   * @param _data    Byte array of data to pass to recipient if it's a contract
   */
  function batchMint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;


  /***************************************|
  |           Burning Functions           |
  |______________________________________*/

  /**
   * @notice Burn sender's_amount of tokens of a given token id
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function burn(uint256 _id, uint256 _amount) external;

  /**
   * @notice Burn sender's tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function batchBurn(uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

pragma solidity 0.7.4;

/**
 * @notice The TieredOwnable can assign ownership tiers to addresses,
 * allowing inheriting contracts to choose which tier can call which function.
 */
contract TieredOwnable {
  uint256 constant internal HIGHEST_OWNER_TIER = 2**256-1; //Highest possible tier

  mapping(address => uint256) internal ownerTier;
  event OwnershipGranted(address indexed owner, uint256 indexed previousTier, uint256 indexed newTier);

  /**
   * @dev Sets the _firstOwner provided to highest owner tier
   * @dev _firstOwner First address to be a owner of this contract
   */
  constructor (address _firstOwner) {
    require(_firstOwner != address(0), "TieredOwnable#constructor: INVALID_FIRST_OWNER");
    ownerTier[_firstOwner] = HIGHEST_OWNER_TIER;
    emit OwnershipGranted(_firstOwner, 0, HIGHEST_OWNER_TIER);
  }

  /**
   * @dev Throws if called by an account that's in lower ownership tier than expected
   */
  modifier onlyOwnerTier(uint256 _minTier) {
    require(ownerTier[msg.sender] >= _minTier, "TieredOwnable#onlyOwnerTier: OWNER_TIER_IS_TOO_LOW");
    _;
  }

  /**
   * @notice Highest owners can change ownership tier of other owners
   * @dev Prevents changing sender's tier to ensure there is always at least one HIGHEST_OWNER_TIER owner.
   * @param _address Address of the owner
   * @param _tier    Ownership tier assigned to owner
   */
  function assignOwnership(address _address, uint256 _tier) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    require(_address != address(0), "TieredOwnable#assignOwnership: INVALID_ADDRESS");
    require(msg.sender != _address, "TieredOwnable#assignOwnership: UPDATING_SELF_TIER");
    emit OwnershipGranted(_address, ownerTier[_address], _tier);
    ownerTier[_address] = _tier;
  }

  /**
   * @notice Returns the ownership tier of provided owner
   * @param _owner Owner's address to query ownership tier
   */
  function getOwnerTier(address _owner) external view returns (uint256) {
    return ownerTier[_owner];
  }
}

pragma solidity 0.7.4;

/**
 * @notice This is a contract allowing contract owner to mint up to N
 *         assets per period of 6 hours.
 * @dev This contract should only be able to mint some assets types
 */
interface IRewardFactory {

  // Event
  event PeriodMintLimitChanged(uint256 oldMintingLimit, uint256 newMintingLimit);

  /***********************************|
  |         Management Methods        |
  |__________________________________*/

  /**
   * @notice Will update the daily mint limit
   * @dev This change will take effect immediatly once executed
   * @param _newPeriodMintLimit Amount of assets that can be minted within a period
   */
  function updatePeriodMintLimit(uint256 _newPeriodMintLimit) external;


  /***********************************|
  |         Minting Functions         |
  |__________________________________*/

  /**
   * @notice Will mint tokens to user
   * @dev Can only mint up to the periodMintLimit in a given 6hour period
   * @param _to      The address that receives the assets
   * @param _ids     Array of Tokens ID that are minted
   * @param _amounts Amount of Tokens id minted for each corresponding Token id in _tokenIds
   * @param _data    Byte array passed to recipient if recipient is a contract
   */
  function batchMint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Returns how many cards can currently be minted by this factory
   */
  function getAvailableSupply() external view returns (uint256);

  /**
   * @notice Calculate the current period
   */
  function livePeriod() external view returns (uint256);

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}

pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import './IERC165.sol';


interface IERC1155 is IERC165 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "../../utils/SafeMath.sol";
import "../../interfaces/IERC1155TokenReceiver.sol";
import "../../interfaces/IERC1155.sol";
import "../../utils/Address.sol";
import "../../utils/ERC165.sol";


/**
 * @dev Implementation of Multi-Token Standard contract. This implementation of the ERC-1155 standard
 *      utilizes the fact that balances of different token ids can be concatenated within individual
 *      uint256 storage slots. This allows the contract to batch transfer tokens more efficiently at
 *      the cost of limiting the maximum token balance each address can hold. This limit is
 *      2^IDS_BITS_SIZE, which can be adjusted below. In practice, using IDS_BITS_SIZE smaller than 16
 *      did not lead to major efficiency gains.
 */
contract ERC1155PackedBalance is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Constants regarding bin sizes for balance packing
  // IDS_BITS_SIZE **MUST** be a power of 2 (e.g. 2, 4, 8, 16, 32, 64, 128)
  uint256 internal constant IDS_BITS_SIZE   = 32;                  // Max balance amount in bits per token ID
  uint256 internal constant IDS_PER_UINT256 = 256 / IDS_BITS_SIZE; // Number of ids per uint256

  // Operations for _updateIDBalance
  enum Operations { Add, Sub }

  // Token IDs balances ; balances[address][id] => balance (using array instead of mapping for efficiency)
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operators
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155PackedBalance#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155PackedBalance#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances);  Not necessary since checked with _viewUpdateBinValue() checks

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155PackedBalance#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155PackedBalance#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    //Update balances
    _updateIDBalance(_from, _id, _amount, Operations.Sub); // Subtract amount from sender
    _updateIDBalance(_to,   _id, _amount, Operations.Add); // Add amount to recipient

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas:_gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155PackedBalance#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    uint256 nTransfer = _ids.length; // Number of transfer to execute
    require(nTransfer == _amounts.length, "ERC1155PackedBalance#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    if (_from != _to && nTransfer > 0) {
      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balFrom = _viewUpdateBinValue(balances[_from][bin], index, _amounts[0], Operations.Sub);
      uint256 balTo = _viewUpdateBinValue(balances[_to][bin], index, _amounts[0], Operations.Add);

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          balances[_from][lastBin] = balFrom;
          balances[_to][lastBin] = balTo;

          balFrom = balances[_from][bin];
          balTo = balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balFrom = _viewUpdateBinValue(balFrom, index, _amounts[i], Operations.Sub);
        balTo = _viewUpdateBinValue(balTo, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      balances[_from][bin] = balFrom;
      balances[_to][bin] = balTo;

    // If transfer to self, just make sure all amounts are valid
    } else {
      for (uint256 i = 0; i < nTransfer; i++) {
        require(balanceOf(_from, _ids[i]) >= _amounts[i], "ERC1155PackedBalance#_safeBatchTransferFrom: UNDERFLOW");
      }
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155PackedBalance#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |     Public Balance Functions      |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
  {
    uint256 bin;
    uint256 index;

    //Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);
    return getValueInBin(balances[_owner][bin], index);
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders (sorted owners will lead to less gas usage)
   * @param _ids    ID of the Tokens (sorted ids will lead to less gas usage
   * @return The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
    */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override view returns (uint256[] memory)
  {
    uint256 n_owners = _owners.length;
    require(n_owners == _ids.length, "ERC1155PackedBalance#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // First values
    (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);
    uint256 balance_bin = balances[_owners[0]][bin];
    uint256 last_bin = bin;

    // Initialization
    uint256[] memory batchBalances = new uint256[](n_owners);
    batchBalances[0] = getValueInBin(balance_bin, index);

    // Iterate over each owner and token ID
    for (uint256 i = 1; i < n_owners; i++) {
      (bin, index) = getIDBinIndex(_ids[i]);

      // SLOAD if bin changed for the same owner or if owner changed
      if (bin != last_bin || _owners[i-1] != _owners[i]) {
        balance_bin = balances[_owners[i]][bin];
        last_bin = bin;
      }

      batchBalances[i] = getValueInBin(balance_bin, index);
    }

    return batchBalances;
  }


  /***********************************|
  |      Packed Balance Functions     |
  |__________________________________*/

  /**
   * @notice Update the balance of a id for a given address
   * @param _address    Address to update id balance
   * @param _id         Id to update balance of
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to id balance
   *   Operations.Sub: Substract _amount from id balance
   */
  function _updateIDBalance(address _address, uint256 _id, uint256 _amount, Operations _operation)
    internal
  {
    uint256 bin;
    uint256 index;

    // Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);

    // Update balance
    balances[_address][bin] = _viewUpdateBinValue(balances[_address][bin], index, _amount, _operation);
  }

  /**
   * @notice Update a value in _binValues
   * @param _binValues  Uint256 containing values of size IDS_BITS_SIZE (the token balances)
   * @param _index      Index of the value in the provided bin
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to value in _binValues at _index
   *   Operations.Sub: Substract _amount from value in _binValues at _index
   */
  function _viewUpdateBinValue(uint256 _binValues, uint256 _index, uint256 _amount, Operations _operation)
    internal pure returns (uint256 newBinValues)
  {
    uint256 shift = IDS_BITS_SIZE * _index;
    uint256 mask = (uint256(1) << IDS_BITS_SIZE) - 1;

    if (_operation == Operations.Add) {
      newBinValues = _binValues + (_amount << shift);
      require(newBinValues >= _binValues, "ERC1155PackedBalance#_viewUpdateBinValue: OVERFLOW");
      require(
        ((_binValues >> shift) & mask) + _amount < 2**IDS_BITS_SIZE, // Checks that no other id changed
        "ERC1155PackedBalance#_viewUpdateBinValue: OVERFLOW"
      );

    } else if (_operation == Operations.Sub) {
      newBinValues = _binValues - (_amount << shift);
      require(newBinValues <= _binValues, "ERC1155PackedBalance#_viewUpdateBinValue: UNDERFLOW");
      require(
        ((_binValues >> shift) & mask) >= _amount, // Checks that no other id changed
        "ERC1155PackedBalance#_viewUpdateBinValue: UNDERFLOW"
      );

    } else {
      revert("ERC1155PackedBalance#_viewUpdateBinValue: INVALID_BIN_WRITE_OPERATION"); // Bad operation
    }

    return newBinValues;
  }

  /**
  * @notice Return the bin number and index within that bin where ID is
  * @param _id  Token id
  * @return bin index (Bin number, ID"s index within that bin)
  */
  function getIDBinIndex(uint256 _id)
    public pure returns (uint256 bin, uint256 index)
  {
    bin = _id / IDS_PER_UINT256;
    index = _id % IDS_PER_UINT256;
    return (bin, index);
  }

  /**
   * @notice Return amount in _binValues at position _index
   * @param _binValues  uint256 containing the balances of IDS_PER_UINT256 ids
   * @param _index      Index at which to retrieve amount
   * @return amount at given _index in _bin
   */
  function getValueInBin(uint256 _binValues, uint256 _index)
    public pure returns (uint256)
  {
    // require(_index < IDS_PER_UINT256) is not required since getIDBinIndex ensures `_index < IDS_PER_UINT256`

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << IDS_BITS_SIZE) - 1;

    // Shift amount
    uint256 rightShift = IDS_BITS_SIZE * _index;
    return (_binValues >> rightShift) & mask;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

pragma solidity 0.7.4;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

pragma solidity 0.7.4;
import "../interfaces/IERC165.sol";

abstract contract ERC165 is IERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual override public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "../../utils/ERC165.sol";
import "../../utils/SafeMath.sol";
import "../../interfaces/IERC2981.sol";

/**
 * @notice Contract return royalty information for tokens of this contract
 * @dev This contract sets a global fee information for all token ids.
 */
contract ERC2981Global is IERC2981, ERC165 {
  using SafeMath for uint256;

  struct FeeInfo {
    address receiver;
    uint256 feeBasisPoints;
  }

  // Royalty Fee information struct
  FeeInfo public globalRoyaltyInfo;

  /**
   * @notice Will set the basis point and royalty recipient that is applied to all assets
   * @param _receiver Fee recipient that will receive the royalty payments
   * @param _royaltyBasisPoints Basis points with 3 decimals representing the fee %
   *        e.g. a fee of 2% would be 20 (i.e. 20 / 1000 == 0.02, or 2%)
   */
  function _setGlobalRoyaltyInfo(address _receiver, uint256 _royaltyBasisPoints) internal {
    require(_receiver != address(0x0), "ERC2981Global#_setGlobalRoyalty: RECIPIENT_IS_0x0");
    require(_royaltyBasisPoints <= 1000, "ERC2981Global#_setGlobalRoyalty: FEE_IS_ABOVE_100_PERCENT");
    globalRoyaltyInfo.receiver = _receiver;
    globalRoyaltyInfo.feeBasisPoints = _royaltyBasisPoints;
  }


  /***********************************|
  |         ERC-2981 Functions        |
  |__________________________________*/

    /**  
    * @notice Called with the sale price to determine how much royalty is owed and to whom.
    * @param _saleCost - the sale cost of the NFT asset specified by _tokenId
    * @return receiver - address of who should be sent the royalty payment
    * @return royaltyAmount - the royalty payment amount for _salePrice
    */
  function royaltyInfo(
    uint256, 
    uint256 _saleCost
  ) external view override returns (address receiver, uint256 royaltyAmount) 
  {
    FeeInfo memory info = globalRoyaltyInfo;
    return (info.receiver, _saleCost.mul(info.feeBasisPoints).div(1000));
  }


  /***********************************|
  |         ERC-165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC2981).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import './IERC165.sol';

interface IERC2981 is IERC165 {
  /**  
    * @notice Called with the sale price to determine how much royalty is owed and to whom.
    * @param _tokenId - the NFT asset queried for royalty information
    * @param _saleCost - the sale cost of the NFT asset specified by _tokenId
    * @return receiver - address of who should be sent the royalty payment
    * @return royaltyAmount - the royalty payment amount for _salePrice
    */
  function royaltyInfo(uint256 _tokenId, uint256 _saleCost) external view returns (address receiver, uint256 royaltyAmount);
}

pragma solidity 0.7.4;

import "../utils/TieredOwnable.sol";
import "../interfaces/ISkyweaverAssets.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";

/**
 * @notice This is a contract allowing contract owner to mint up to N 
 *         assets per period of 6 hours.
 * @dev This contract should only be able to mint some asset types
 */
contract RewardFactory is TieredOwnable {
  using SafeMath for uint256;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // Token information
  ISkyweaverAssets immutable public skyweaverAssets; // ERC-1155 Skyweaver assets contract

  // Period variables
  uint256 internal period;                // Current period
  uint256 internal availableSupply;       // Amount of assets that can currently be minted
  uint256 public periodMintLimit;         // Amount that can be minted within 6h
  uint256 immutable public PERIOD_LENGTH; // Length of each mint periods in seconds

  // Whitelist
  bool internal immutable MINT_WHITELIST_ONLY;
  mapping(uint256 => bool) public mintWhitelist;

  // Event
  event PeriodMintLimitChanged(uint256 oldMintingLimit, uint256 newMintingLimit);
  event AssetsEnabled(uint256[] enabledIds);
  event AssetsDisabled(uint256[] disabledIds);
  
  /***********************************|
  |            Constructor            |
  |__________________________________*/

  /**
   * @notice Create factory, link skyweaver assets and store initial parameters
   * @param _firstOwner      Address of the first owner
   * @param _assetsAddr      The address of the ERC-1155 Assets Token contract
   * @param _periodLength    Number of seconds each period lasts
   * @param _periodMintLimit Can only mint N assets per period
   * @param _whitelistOnly   Whether this factory uses a mint whitelist or not
   */
  constructor(
    address _firstOwner,
    address _assetsAddr,
    uint256 _periodLength,
    uint256 _periodMintLimit,
    bool _whitelistOnly
  ) TieredOwnable(_firstOwner) public {
    require(
      _assetsAddr != address(0) &&
      _periodLength > 0 &&
      _periodMintLimit > 0,
      "RewardFactory#constructor: INVALID_INPUT"
    );

    // Assets
    skyweaverAssets = ISkyweaverAssets(_assetsAddr);

    // Set Period length
    PERIOD_LENGTH = _periodLength;

    // Set whether this factory uses a mint whitelist or not
    MINT_WHITELIST_ONLY = _whitelistOnly;

    // Set current period
    period = block.timestamp / _periodLength; // From livePeriod()
    availableSupply = _periodMintLimit;

    // Rewards parameters
    periodMintLimit = _periodMintLimit;
    emit PeriodMintLimitChanged(0, _periodMintLimit);
  }


  /***********************************|
  |         Management Methods        |
  |__________________________________*/

  /**
   * @notice Will update the daily mint limit
   * @dev This change will take effect immediatly once executed
   * @param _newPeriodMintLimit Amount of assets that can be minted within a period
   */
  function updatePeriodMintLimit(uint256 _newPeriodMintLimit) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    // Immediately update supply instead of waiting for next period
    if (availableSupply > _newPeriodMintLimit) {
      availableSupply = _newPeriodMintLimit;
    }

    emit PeriodMintLimitChanged(periodMintLimit, _newPeriodMintLimit);
    periodMintLimit = _newPeriodMintLimit;
  }

  /**
   * @notice Will enable these tokens to be minted by this factory
   * @param _enabledIds IDs this factory can mint
   */
  function enableMint(uint256[] calldata _enabledIds) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    for (uint256 i = 0; i < _enabledIds.length; i++) {
      mintWhitelist[_enabledIds[i]] = true;
    }
    emit AssetsEnabled(_enabledIds);
  }

  /**
   * @notice Will prevent these ids from being minted by this factory
   * @param _disabledIds IDs this factory can mint
   */
  function disableMint(uint256[] calldata _disabledIds) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    for (uint256 i = 0; i < _disabledIds.length; i++) {
      mintWhitelist[_disabledIds[i]] = false;
    }
    emit AssetsDisabled(_disabledIds);
  }


  /***********************************|
  |      Receiver Method Handler      |
  |__________________________________*/

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("RewardFactory#_: UNSUPPORTED_METHOD");
  }

  /***********************************|
  |         Minting Functions         |
  |__________________________________*/

  /**
   * @notice Will mint tokens to user
   * @dev Can only mint up to the periodMintLimit in a given 6hour period
   * @param _to      The address that receives the assets
   * @param _ids     Array of Tokens ID that are minted
   * @param _amounts Amount of Tokens id minted for each corresponding Token id in _ids
   * @param _data    Byte array passed to recipient if recipient is a contract
   */
  function batchMint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data)
    external onlyOwnerTier(1)
  {
    uint256 live_period = livePeriod();
    uint256 stored_period = period;
    uint256 available_supply;

    // Update period and refresh the available supply if period
    // is different, otherwise use current available supply.
    if (live_period == stored_period) {
      available_supply = availableSupply;
    } else {
      available_supply = periodMintLimit;
      period = live_period;
    }

    // If there is an insufficient available supply, this will revert
    for (uint256 i = 0; i < _ids.length; i++) {
      available_supply = available_supply.sub(_amounts[i]);
      if (MINT_WHITELIST_ONLY) {
        require(mintWhitelist[_ids[i]], "RewardFactory#batchMint: ID_IS_NOT_WHITELISTED");
      }
    }

    // Store available supply
    availableSupply = available_supply;
    
    // Mint assets
    skyweaverAssets.batchMint(_to, _ids, _amounts, _data);
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Returns how many cards can currently be minted by this factory
   */
  function getAvailableSupply() external view returns (uint256) {
    return livePeriod() == period ? availableSupply : periodMintLimit;
  }

  /**
   * @notice Calculate the current period
   */
  function livePeriod() public view returns (uint256) {
    return block.timestamp / PERIOD_LENGTH;
  }

  /**
   * @notice Indicates whether a contract implements a given interface.
   * @param interfaceID The ERC-165 interface ID that is queried for support.
   * @return True if contract interface is supported.
   */
  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId;
  }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";

/**
 * @dev This contract allows an owner to execute registered calls after an expiration
 *      delay has passed. This contract can then be the owner of another contract to
 *      enforce delayed function calls.
 * @dev Does not support passing ETH in calls for simplicity, but could be added in V2.
 */
contract DelayedOwner is Ownable {
  using SafeMath for uint256;

  // Time transactions must be registered before being executable
  uint256 immutable internal EXECUTION_DELAY;
  
  // Mapping between transaction id and transaction hashes
  mapping(uint256 => bytes32) public txHashes;

  // Events
  event TransactionRegistered(Transaction transaction);
  event TransactionCancelled(Transaction transaction);
  event TransactionExecuted(Transaction transaction);

  // Transaction structure
  struct Transaction {
    Status status;       // Transaction status
    uint256 triggerTime; // Timestamp after which the transaction can be executed
    address target;      // Address of the contract to call
    uint256 id;          // Transaction identifier (unique)
    bytes data;          // calldata to pass
  }

  enum Status {
    NotRegistered, // 0x0 - Transaction was not registered
    Pending,       // 0x1 - Transaction was registered but not executed
    Executed,      // 0x2 - Transaction was executed
    Cancelled      // 0x3 - Transaction was registered and cancelled
  }

  /**
   * @dev Registers the execution delay for this contract 
   * @param _firstOwner Address of the first owner
   * @param _delay Amount of time in seconds the delay will be
   */
  constructor (address _firstOwner, uint256 _delay) Ownable(_firstOwner) {
    EXECUTION_DELAY = _delay;
  }


  /***********************************|
  |           Core Functions          |
  |__________________________________*/

  /**
   * @notice Register a transaction to execute post delay
   * @param _tx Transaction to execute
   */
  function register(Transaction memory _tx) onlyOwner() public {
    require(txHashes[_tx.id] == 0x0, "DelayedOwner#register: TX_ALREADY_REGISTERED");

    // Set trigger time and mark transaction as pending
    _tx.triggerTime = block.timestamp.add(EXECUTION_DELAY);
    _tx.status = Status.Pending;

    // Store transaction
    txHashes[_tx.id] = keccak256(abi.encode(_tx));
    emit TransactionRegistered(_tx);
  }

  /**
   * @notice Cancels a transaction that was registered but not yet executed or cancelled
   * @param _tx Transaction to cancel
   */
  function cancel(Transaction memory _tx) onlyOwner() onlyValidWitnesses(_tx) public {
    require(_tx.status == Status.Pending, "DelayedOwner#cancel: TX_NOT_PENDING");

    // Set status to Cancelled
    _tx.status = Status.Cancelled;

    // Store transaction
    txHashes[_tx.id] = keccak256(abi.encode(_tx));
    emit TransactionCancelled(_tx);
  }

  /**
   * @notice Will execute transaction specified
   * @param _tx Transaction to execute
   */
  function execute(Transaction memory _tx) onlyValidWitnesses(_tx) public {
    require(_tx.status == Status.Pending, "DelayedOwner#execute: TX_NOT_PENDING");
    require(_tx.triggerTime <= block.timestamp, "DelayedOwne#execute: TX_NOT_YET_EXECUTABLE");

    // Mark transaction as executed, preventing re-entrancy and replay
    _tx.status = Status.Executed;

    // Store transaction
    txHashes[_tx.id] = keccak256(abi.encode(_tx));

    // Execute transaction
    (bool success,) = _tx.target.call(_tx.data);
    require(success, "DelayedOwner#execute: TX_FAILED");
    emit TransactionExecuted(_tx); 
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Verify if provided transaction object matches registered transaction
   * @param _tx Transaction to validate
   */
  function isValidWitness(Transaction memory _tx) public view returns (bool isValid) {
    return txHashes[_tx.id] == keccak256(abi.encode(_tx));
  }

  /**
   * @notice Will enforce that the provided transaction witness is valid
   * @param _tx Transaction to validate
   */
  modifier onlyValidWitnesses(Transaction memory _tx) {
    require(
      isValidWitness(_tx),
      "DelayedOwner#onlyValidWitnesses: INVALID_TX_WITNESS"
    );

    _;
  }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the specied address
   * @param _firstOwner Address of the first owner
   */
  constructor (address _firstOwner) {
    owner = _firstOwner;
    emit OwnershipTransferred(address(0), _firstOwner);
  }

  /**
   * @dev Throws if called by any account other than the master owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  /**
   * @notice Returns the address of the owner.
   */
  function getOwner() public view returns (address) {
    return owner;
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "./ERC1155PackedBalance.sol";


/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions.
 */
contract ERC1155MintBurnPackedBalance is ERC1155PackedBalance {

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    //Add _amount
    _updateIDBalance(_to,   _id, _amount, Operations.Add); // Add amount to recipient

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each (_ids[i], _amounts[i]) pair
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurnPackedBalance#_batchMint: INVALID_ARRAYS_LENGTH");

    if (_ids.length > 0) {
      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balTo = _viewUpdateBinValue(balances[_to][bin], index, _amounts[0], Operations.Add);

      // Number of transfer to execute
      uint256 nTransfer = _ids.length;

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          balances[_to][lastBin] = balTo;
          balTo = balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balTo = _viewUpdateBinValue(balTo, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      balances[_to][bin] = balTo;
    }

    // //Emit event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    // Substract _amount
    _updateIDBalance(_from, _id, _amount, Operations.Sub);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @dev This batchBurn method does not implement the most efficient way of updating
   *      balances to reduce the potential bug surface as this function is expected to
   *      be less common than transfers. EIP-2200 makes this method significantly
   *      more efficient already for packed balances.
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of burning to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurnPackedBalance#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all burning
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      _updateIDBalance(_from,   _ids[i], _amounts[i], Operations.Sub); // Add amount to recipient
    }

    // Emit batch burn event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "../../interfaces/IERC1155Metadata.sol";
import "../../utils/ERC165.sol";


/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata is IERC1155Metadata, ERC165 {
  // URI's default URI prefix
  string public baseURI;
  string public name;

  // set the initial name and base URI
  constructor(string memory _name, string memory _baseURI) {
    name = _name;
    baseURI = _baseURI;
  }

  /***********************************|
  |     Metadata Public Functions     |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   * @return URI string
   */
  function uri(uint256 _id) public override view returns (string memory) {
    return string(abi.encodePacked(baseURI, _uint2str(_id), ".json"));
  }


  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseURI = _newBaseMetadataURI;
  }

  /**
   * @notice Will update the name of the contract
   * @param _newName New contract name
   */
  function _setContractName(string memory _newName) internal {
    name = _newName;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155Metadata).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }


  /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

  /**
   * @notice Convert uint256 to string
   * @param _i Unsigned integer to convert to string
   */
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

    // Get number of bytes
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

    // Get each individual ASCII
    while (ii != 0) {
      bstr[k--] = byte(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


interface IERC1155Metadata {

  event URI(string _uri, uint256 indexed _id);

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../tokens/ERC1155/ERC1155MintBurn.sol";
import "../tokens/ERC1155/ERC1155Metadata.sol";


contract ERC1155MintBurnMock is ERC1155MintBurn, ERC1155Metadata {

  // set the initial name and base URI
  constructor(string memory _name, string memory _baseURI) ERC1155Metadata(_name, _baseURI) {}

  /**
   * @notice Query if a contract implements an interface
   * @dev Parent contract inheriting multiple contracts with supportsInterface()
   *      need to implement an overriding supportsInterface() function specifying
   *      all inheriting contracts that have a supportsInterface() function.
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(
    bytes4 _interfaceID
  ) public override(
    ERC1155,
    ERC1155Metadata
  ) pure virtual returns (bool) {
    return super.supportsInterface(_interfaceID);
  }

  /***********************************|
  |         Minting Functions         |
  |__________________________________*/

  /**
   * @dev Mint _value of tokens of a given id
   * @param _to The address to mint tokens to.
   * @param _id token id to mint
   * @param _value The amount to be minted
   * @param _data Data to be passed if receiver is contract
   */
  function mintMock(address _to, uint256 _id, uint256 _value, bytes memory _data)
    public
  {
    super._mint(_to, _id, _value, _data);
  }

  /**
   * @dev Mint tokens for each ids in _ids
   * @param _to The address to mint tokens to.
   * @param _ids Array of ids to mint
   * @param _values Array of amount of tokens to mint per id
   * @param _data Data to be passed if receiver is contract
   */
  function batchMintMock(address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data)
    public
  {
    super._batchMint(_to, _ids, _values, _data);
  }


  /***********************************|
  |         Burning Functions         |
  |__________________________________*/

  /**
   * @dev burn _value of tokens of a given token id
   * @param _from The address to burn tokens from.
   * @param _id token id to burn
   * @param _value The amount to be burned
   */
  function burnMock(address _from, uint256 _id, uint256 _value)
    public
  {
    super._burn(_from, _id, _value);
  }

  /**
   * @dev burn _value of tokens of a given token id
   * @param _from The address to burn tokens from.
   * @param _ids Array of token ids to burn
   * @param _values Array of the amount to be burned
   */
  function batchBurnMock(address _from, uint256[] memory _ids, uint256[] memory _values)
    public
  {
    super._batchBurn(_from, _ids, _values);
  }
  
  /***********************************|
  |       Unsupported Functions       |
  |__________________________________*/

  fallback () virtual external {
    revert("ERC1155MetaMintBurnMock: INVALID_METHOD");
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "./ERC1155.sol";


/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
  using SafeMath for uint256;

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "../../utils/SafeMath.sol";
import "../../interfaces/IERC1155TokenReceiver.sol";
import "../../interfaces/IERC1155.sol";
import "../../utils/Address.sol";
import "../../utils/ERC165.sol";


/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

pragma solidity 0.7.4;

import "../utils/TieredOwnable.sol";
import "../interfaces/ISkyweaverAssets.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC1155TokenReceiver.sol";

/**
 * @notice Allows players to convert their silver cards and Wrapped DAI (wDAI) to conquest entries.
 *
 * @dev Assumes both cards and entries have the same number of decimals, if not, need to change
 * the amount minted.
 * 
 * @dev This contract should only be able to mint conquest entries.
 */
contract ConquestEntriesFactory is IERC1155TokenReceiver, TieredOwnable {
  using SafeMath for uint256;
  
  /***********************************|
  |             Variables             |
  |__________________________________*/

  // Assets
  ISkyweaverAssets immutable public skyweaverAssets; // ERC-1155 Skyweaver assets contract
  IERC1155 immutable internal wDai;                  // ERC-1155 Wrapped DAI contract
  uint256 immutable public wDaiID;                   // ID of wDAI token in respective ERC-1155 contract
  uint256 immutable public silverRangeMin;           // Lower bound for the range of asset IDs that can be converted to entries
  uint256 immutable public silverRangeMax;           // Upper bound for the range of asset IDs that can be converted to entries

  // Conquest entry token id
  uint256 immutable public conquestEntryID; 

  // Parameters
  uint256 constant internal CARD_DECIMALS = 2;                     // Number of decimals cards have
  uint256 constant internal ENTRIES_DECIMALS = 2;                  // Number of decimals entries have
  uint256 constant internal wDAI_DECIMALS = 6;                    // Number of decimals wDAI have
  uint256 constant internal wDAI_REQUIRED = 15 * 10**(wDAI_DECIMALS-1); // 1.5 wDAI for 1 conquest entry (after decimals)


  /***********************************|
  |            Constructor            |
  |__________________________________*/

  /**
   * @notice Create factory, link skyweaver assets and store initial parameters
   * @param _firstOwner             Address of the first owner
   * @param _skyweaverAssetsAddress The address of the ERC-1155 Assets Token contract
   * @param _wDaiAddress            The address of the ERC-1155 Wrapped DAI
   * @param _wDaiID                 Wrapped DAI token id
   * @param _conquestEntryTokenId   Conquest entry token id
   * @param _silverRangeMin         Minimum id for silver cards
   * @param _silverRangeMax         Maximum id for silver cards
   */
  constructor(
    address _firstOwner,
    address _skyweaverAssetsAddress,
    address _wDaiAddress,
    uint256 _wDaiID,
    uint256 _conquestEntryTokenId,
    uint256 _silverRangeMin,
    uint256 _silverRangeMax
  ) TieredOwnable(_firstOwner) public 
  {
    require(
      _skyweaverAssetsAddress != address(0) && 
      _wDaiAddress != address(0) &&
      _silverRangeMin < _silverRangeMax,
      "ConquestEntriesFactory#constructor: INVALID_INPUT"
    );

    // Assets
    skyweaverAssets = ISkyweaverAssets(_skyweaverAssetsAddress);
    wDai = IERC1155(_wDaiAddress);
    wDaiID = _wDaiID;
    conquestEntryID = _conquestEntryTokenId;
    silverRangeMin = _silverRangeMin;
    silverRangeMax = _silverRangeMax;
  }

  
  /***********************************|
  |      Receiver Method Handler      |
  |__________________________________*/

  /**
   * @notice Prevents receiving Ether or calls to unsuported methods
   */
  fallback () external {
    revert("ConquestEntriesFactory#_: UNSUPPORTED_METHOD");
  }

  /**
   * @notice Players converting silver cards to conquest entries
   * @dev Payload is passed to and verified by onERC1155BatchReceived()
   */
  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id, 
    uint256 _amount, 
    bytes calldata _data
  )
    external override returns(bytes4)
  {
    // Convert payload to arrays to pass to onERC1155BatchReceived()
    uint256[] memory ids = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ids[0] = _id;
    amounts[0] = _amount;

    // Will revert call if doesn't pass
    onERC1155BatchReceived(_operator, _from, ids, amounts, _data);
    
    // Return success
    return IERC1155TokenReceiver.onERC1155Received.selector;
  }

  /**
   * @notice Players converting silver cards or wDAIs to conquest entries
   * @param _from    Address who sent the token
   * @param _ids     An array containing ids of each Token being transferred
   * @param _amounts An array containing amounts of each Token being transferred
   * @param _data    If data is provided, it should be address who will receive the entries
   */
  function onERC1155BatchReceived(
    address, // _operator
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  )
    public override returns(bytes4)
  { 
    // Number of entries to mint
    uint256 n_entries = 0; 

    // Burn cards or store wDAI
    if (msg.sender == address(skyweaverAssets)) {
      
      // Validate IDs and count number of entries to mint
      for (uint256 i = 0; i < _ids.length; i++) {
        require(
          silverRangeMin <= _ids[i] && _ids[i] <= silverRangeMax, 
          "ConquestEntriesFactory#onERC1155BatchReceived: ID_IS_OUT_OF_RANGE"
        );
        n_entries = n_entries.add(_amounts[i]);
      }
      // Account for cards decimals
      n_entries = n_entries.div(10**CARD_DECIMALS);

      // Burn silver cards received
      skyweaverAssets.batchBurn(_ids, _amounts);

    } else if (msg.sender == address(wDai)) {
      require(_ids.length == 1, "ConquestEntriesFactory#onERC1155BatchReceived: INVALID_ARRAY_LENGTH");
      require(_ids[0] == wDaiID, "ConquestEntriesFactory#onERC1155BatchReceived: INVALID_wDAI_ID");
      n_entries = _amounts[0] / wDAI_REQUIRED; 

      // Do nothing else. wDAIs are stored until withdrawn

    } else {
      revert("ConquestEntriesFactory#onERC1155BatchReceived: INVALID_TOKEN_ADDRESS");
    }

    // If an address is specified in _data, use it as receiver, otherwise use _from address
    address receiver = _data.length > 0 ? abi.decode(_data, (address)) : _from;

    // Mint conquest entries (with decimals)
    skyweaverAssets.mint(receiver, conquestEntryID, n_entries*10**ENTRIES_DECIMALS, "");

    // Return success
    return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
  }

  /**
   * @notice Send current wDAI balance of this contract to recipient
   * @param _recipient Address where the currency will be sent to
   * @param _data      Data to pass with transfer function
   */
  function withdraw(address _recipient, bytes calldata _data) external onlyOwnerTier(HIGHEST_OWNER_TIER) {
    require(_recipient != address(0x0), "ConquestEntriesFactory#withdraw: INVALID_RECIPIENT");
    uint256 this_balance = wDai.balanceOf(address(this), wDaiID);
    wDai.safeTransferFrom(address(this), _recipient, wDaiID, this_balance, _data);
  }


  /***********************************|
  |         Utility Functions         |
  |__________________________________*/

  /**
   * @notice Indicates whether a contract implements a given interface.
   * @param interfaceID The ERC-165 interface ID that is queried for support.
   * @return True if contract interface is supported.
   */
  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId || 
      interfaceID == type(IERC1155TokenReceiver).interfaceId;
  }
}

pragma solidity 0.7.4;
import "../interfaces/ISkyweaverAssets.sol";

contract FactoryMock {

  ISkyweaverAssets internal skyweaverAssets; //SkyWeaver Curencies Factory Manager Contract

  constructor(address _factoryManagerAddr) public {
    skyweaverAssets = ISkyweaverAssets(_factoryManagerAddr);
  }

  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data) public
  {
    skyweaverAssets.batchMint(_to, _ids, _amounts, _data);
  }

  function mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data) public
  {
    skyweaverAssets.mint(_to, _id, _amount, _data);
  }

}

pragma solidity 0.7.4;

import "../utils/TieredOwnable.sol";
import "../interfaces/ISkyweaverAssets.sol";
import "@0xsequence/erc-1155/contracts/interfaces/IERC165.sol";

/**
 * This is a contract allowing owner to mint any tokens within a given
 * range. This factory will be used to mint community related assets, special
 * event assets that are meant to be given away.
 */
contract FreemintFactory is TieredOwnable {

  // ERC-1155 Skyweaver assets contract
  ISkyweaverAssets internal skyweaverAssets;

  /***********************************|
  |            Constructor            |
  |__________________________________*/

  /**
   * @notice Create factory & link skyweaver assets
   * @param _firstOwner Address of the first owner
   * @param _assetsAddr The address of the ERC-1155 Assets Token contract
   */
  constructor(address _firstOwner, address _assetsAddr) TieredOwnable(_firstOwner) public {
    require(
      _assetsAddr != address(0),
      "FreemintFactory#constructor: INVALID_INPUT"
    );
    skyweaverAssets = ISkyweaverAssets(_assetsAddr);
  }


  /***********************************|
  |         Minting Function          |
  |__________________________________*/

  /**
   * @notice Will mint a bundle of tokens to users
   * @param _recipients Arrays of addresses to mint _amounts of _ids
   * @param _ids        Array of Tokens ID that are minted
   * @param _amounts    Amount of Tokens id minted for each corresponding Token id in _ids
   */
  function batchMint(address[] calldata _recipients, uint256[] calldata _ids, uint256[] calldata _amounts)
    external onlyOwnerTier(1)
  {
    for (uint256 i = 0 ; i < _recipients.length; i++) {
      skyweaverAssets.batchMint(_recipients[i], _ids, _amounts, "");
    }
  }


  /***********************************|
  |          Misc Functions           |
  |__________________________________*/

  /**
   * @notice Returns the address of the  skyweaver assets contract
   */
  function getSkyweaverAssets() external view returns (address) {
    return address(skyweaverAssets);
  }

  /**
   * @notice Prevents receiving Ether, ERC-1155 or calls to unsuported methods
   */
  fallback () external {
    revert("FreemintFactory#_: UNSUPPORTED_METHOD");
  }

  /**
   * @notice Indicates whether a contract implements a given interface.
   * @param interfaceID The ERC-165 interface ID that is queried for support.
   * @return True if contract interface is supported.
   */
  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId;
  }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;


import "../utils/TieredOwnable.sol";

contract TieredOwnableMock is TieredOwnable {

  constructor(address _firstOwner) TieredOwnable(_firstOwner) public {}

  function onlyMaxTier() external onlyOwnerTier(HIGHEST_OWNER_TIER) returns(bool) {
    return true;
  }

  function onlyTierFive() external onlyOwnerTier(5) returns(bool) {
    return true;
  }

  function onlyTierZero() external onlyOwnerTier(0) returns(bool) {
    return true;
  }

  function anyone() external returns(bool) {
    return true;
  }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;


import "@0xsequence/erc-1155/contracts/mocks/ERC1155MintBurnMock.sol";

contract ERC1155Mock is ERC1155MintBurnMock {

  constructor() ERC1155MintBurnMock('ERC1155Mock', "") {}

}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;


import "../utils/Ownable.sol";

contract OwnableMock is Ownable {

  constructor(address _firstOwner) Ownable(_firstOwner) public {}

  function call_onlyOwner() external onlyOwner() returns(bool) {
    return true;
  }
  function call_anyone() external returns(bool) {
    return true;
  }

  function call_throw() external returns(bool) {
    revert(":/");
    return true;
  }

  fallback() external {}
}