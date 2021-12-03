// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ERC998, ItemTypeIO} from "../libraries/LibERC998.sol";
import {LibAppStorage, InstallationType, QueueItem, Modifiers} from "../libraries/AppStorage.sol";
import {LibStrings} from "../libraries/LibStrings.sol";
import {LibMeta} from "../libraries/LibMeta.sol";
import {LibERC1155} from "../libraries/LibERC1155.sol";
import {ERC998} from "../libraries/LibERC998.sol";
import {LibERC20} from "../libraries/LibERC20.sol";
import {IERC721} from "../interfaces/IERC721.sol";

contract InstallationFacet is Modifiers {
  event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);

  event AddedToQueue(uint256 indexed _queueId, uint256 indexed _installationType, uint256 _readyBlock, address _sender);

  event QueueClaimed(uint256 indexed _queueId);
  event CraftTimeReduced(uint256 indexed _queueId, uint256 _blocks);

  /***********************************|
   |             Read Functions         |
   |__________________________________*/

  struct InstallationIdIO {
    uint256 installationId;
    uint256 balance;
  }

  ///@notice Returns balance for each installation that exists for an account
  ///@param _account Address of the account to query
  ///@return bals_ An array of structs,each struct containing details about each installation owned
  function installationsBalances(address _account) external view returns (InstallationIdIO[] memory bals_) {
    uint256 count = s.ownerInstallations[_account].length;
    bals_ = new InstallationIdIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 installationId = s.ownerInstallations[_account][i];
      bals_[i].balance = s.ownerInstallationBalances[_account][installationId];
      bals_[i].installationId = installationId;
    }
  }

  ///@notice Returns balance for each installation(and their types) that exists for an account
  ///@param _owner Address of the account to query
  ///@return output_ An array of structs containing details about each installation owned(including the installation types)
  function installationsBalancesWithTypes(address _owner) external view returns (ItemTypeIO[] memory output_) {
    uint256 count = s.ownerInstallations[_owner].length;
    output_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 installationId = s.ownerInstallations[_owner][i];
      output_[i].balance = s.ownerInstallationBalances[_owner][installationId];
      output_[i].itemId = installationId;
      output_[i].installationType = s.installationTypes[installationId];
    }
  }

  /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return bal_    The _owner's balance of the token type requested
     */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_) {
    bal_ = s.ownerInstallationBalances[_owner][_id];
  }

  /// @notice Get the balance of a non-fungible parent token
  /// @param _tokenContract The contract tracking the parent token
  /// @param _tokenId The ID of the parent token
  /// @param _id     ID of the token
  /// @return value The balance of the token
  function balanceOfToken(
    address _tokenContract,
    uint256 _tokenId,
    uint256 _id
  ) external view returns (uint256 value) {
    value = s.nftInstallationBalances[_tokenContract][_tokenId][_id];
  }

  ///@notice Returns the balances for all ERC1155 items for a ERC721 token
  ///@param _tokenContract Contract address for the token to query
  ///@param _tokenId Identifier of the token to query
  ///@return bals_ An array of structs containing details about each item owned
  function installationBalancesOfToken(address _tokenContract, uint256 _tokenId) external view returns (InstallationIdIO[] memory bals_) {
    uint256 count = s.nftInstallations[_tokenContract][_tokenId].length;
    bals_ = new InstallationIdIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 installationId = s.nftInstallations[_tokenContract][_tokenId][i];
      bals_[i].installationId = installationId;
      bals_[i].balance = s.nftInstallationBalances[_tokenContract][_tokenId][installationId];
    }
  }

  ///@notice Returns the balances for all ERC1155 items for a ERC721 token
  ///@param _tokenContract Contract address for the token to query
  ///@param _tokenId Identifier of the token to query
  ///@return installationBalancesOfTokenWithTypes_ An array of structs containing details about each installation owned(including installation types)
  function installationBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    external
    view
    returns (ItemTypeIO[] memory installationBalancesOfTokenWithTypes_)
  {
    installationBalancesOfTokenWithTypes_ = ERC998.itemBalancesOfTokenWithTypes(_tokenContract, _tokenId);
  }

  /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return bals   The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory bals) {
    require(_owners.length == _ids.length, "InstallationFacet: _owners length not same as _ids length");
    bals = new uint256[](_owners.length);
    for (uint256 i; i < _owners.length; i++) {
      uint256 id = _ids[i];
      address owner = _owners[i];
      bals[i] = s.ownerInstallationBalances[owner][id];
    }
  }

  ///@notice Query the item type of a particular installation
  ///@param _installationTypeId Item to query
  ///@return installationType A struct containing details about the item type of an item with identifier `_itemId`
  function getInstallationType(uint256 _installationTypeId) external view returns (InstallationType memory installationType) {
    require(_installationTypeId < s.installationTypes.length, "InstallationFacet: Item type doesn't exist");
    installationType = s.installationTypes[_installationTypeId];
  }

  ///@notice Query the item type of multiple installation types
  ///@param _installationTypeIds An array containing the identifiers of items to query
  ///@return installationTypes_ An array of structs,each struct containing details about the item type of the corresponding item
  function getInstallationTypes(uint256[] calldata _installationTypeIds) external view returns (InstallationType[] memory installationTypes_) {
    if (_installationTypeIds.length == 0) {
      installationTypes_ = s.installationTypes;
    } else {
      installationTypes_ = new InstallationType[](_installationTypeIds.length);
      for (uint256 i; i < _installationTypeIds.length; i++) {
        installationTypes_[i] = s.installationTypes[_installationTypeIds[i]];
      }
    }
  }

  /**
        @notice Get the URI for a voucher type
        @return URI for token type
    */
  function uri(uint256 _id) external view returns (string memory) {
    require(_id < s.installationTypes.length, "InstallationFacet: Item _id not found");
    return LibStrings.strWithUint(s.baseUri, _id);
  }

  function getAlchemicaAddresses() external view returns (address[] memory) {
    return s.alchemicaAddresses;
  }

  /***********************************|
   |             Write Functions        |
   |__________________________________*/

  function craftInstallations(uint256[] calldata _installationTypes) external {
    for (uint8 i = 0; i < _installationTypes.length; i++) {
      //level check
      require(s.installationTypes[_installationTypes[i]].level == 1, "InstallationFacet: can only craft level 1");
      //take the required alchemica
      InstallationType memory installationType = s.installationTypes[_installationTypes[i]];
      for (uint8 j = 0; j < installationType.alchemicaCost.length; j++) {
        LibERC20.transferFrom(s.alchemicaAddresses[j], msg.sender, address(this), s.installationTypes[_installationTypes[i]].alchemicaCost[j]);
      }

      uint256 readyBlock = block.number + installationType.craftTime;

      //put the installation into a queue
      //each wearable needs a unique queue id
      s.craftQueue.push(QueueItem(s.nextCraftId, readyBlock, _installationTypes[i], false, msg.sender));

      emit AddedToQueue(s.nextCraftId, _installationTypes[i], readyBlock, msg.sender);
      s.nextCraftId++;
    }
    //after queue is over, user can claim installation
  }

  function reduceCraftTime(uint256[] calldata _queueIds, uint256[] calldata _amounts) external {
    require(_queueIds.length == _amounts.length, "InstallationFacet: Mismatched arrays");
    for (uint8 i; i < _queueIds.length; i++) {
      uint256 queueId = _queueIds[i];
      QueueItem storage queueItem = s.craftQueue[queueId];
      require(msg.sender == queueItem.owner, "InstallationFacet: not owner");

      require(block.number <= queueItem.readyBlock, "InstallationFacet: installation already done");

      //todo: check user has enough GLMR
      //todo: burn GLMR tokens

      queueItem.readyBlock -= _amounts[i];
      emit CraftTimeReduced(queueId, _amounts[i]);
    }
  }

  function claimInstallations(uint256[] calldata _queueIds) external {
    for (uint8 i; i < _queueIds.length; i++) {
      uint256 queueId = _queueIds[i];
      QueueItem memory queueItem = s.craftQueue[queueId];
      require(msg.sender == queueItem.owner, "InstallationFacet: not owner");
      require(!queueItem.claimed, "InstallationFacet: already claimed");

      require(block.number >= queueItem.readyBlock, "InstallationFacet: installation not ready");

      // mint installation
      LibERC1155._safeMint(msg.sender, queueItem.installationType, queueItem.id);
      emit QueueClaimed(queueId);
    }
  }

  function equipInstallation(
    address _owner,
    uint256 _realmId,
    uint256 _installationType
  ) external onlyRealmDiamond {
    ERC998.removeFromOwner(_owner, _installationType, 1);
    ERC998.addToParent(s.realmDiamond, _realmId, _installationType, 1);
    emit TransferToParent(s.realmDiamond, _realmId, _installationType, 1);
  }

  function unequipInstallation(
    address _owner,
    uint256 _realmId,
    uint256 _installationType
  ) external onlyRealmDiamond {
    ERC998.removeFromParent(s.realmDiamond, _realmId, _installationType, 1);
    LibERC1155._burn(_owner, _installationType, 1);
  }

  // TODO function upgradeInstallations()

  /***********************************|
   |             Owner Functions        |
   |__________________________________*/

  /**
        @notice Set the base url for all voucher types
        @param _value The new base url        
    */
  function setBaseURI(string memory _value) external onlyOwner {
    s.baseUri = _value;
    for (uint256 i; i < s.installationTypes.length; i++) {
      emit LibERC1155.URI(LibStrings.strWithUint(_value, i), i);
    }
  }

  function setAlchemicaAddresses(address[] memory _addresses) external onlyOwner {
    s.alchemicaAddresses = _addresses;
  }

  function setDiamondsAddresses(address _aavegotchiDiamond, address _realmDiamond) external onlyOwner {
    s.aavegotchiDiamond = _aavegotchiDiamond;
    s.realmDiamond = _realmDiamond;
  }

  function addInstallationTypes(InstallationType[] calldata _installationTypes) external onlyOwner {
    for (uint16 i = 0; i < _installationTypes.length; i++) {
      s.installationTypes.push(
        InstallationType(
          _installationTypes[i].installationType,
          _installationTypes[i].level,
          _installationTypes[i].width,
          _installationTypes[i].height,
          _installationTypes[i].alchemicaType,
          _installationTypes[i].alchemicaCost,
          _installationTypes[i].harvestRate,
          _installationTypes[i].capacity,
          _installationTypes[i].spillRadius,
          _installationTypes[i].spillPercentage,
          _installationTypes[i].craftTime
        )
      );
    }
  }

  // TODO function updateInstallationType(Installation memory _updatedInstallation) external onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorage, AppStorage, InstallationType} from "./AppStorage.sol";
import {LibERC1155} from "./LibERC1155.sol";

struct ItemTypeIO {
  uint256 balance;
  uint256 itemId;
  InstallationType installationType;
}

library ERC998 {
  function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    internal
    view
    returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_)
  {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 count = s.nftInstallations[_tokenContract][_tokenId].length;
    itemBalancesOfTokenWithTypes_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 itemId = s.nftInstallations[_tokenContract][_tokenId][i];
      uint256 bal = s.nftInstallationBalances[_tokenContract][_tokenId][itemId];
      itemBalancesOfTokenWithTypes_[i].itemId = itemId;
      itemBalancesOfTokenWithTypes_[i].balance = bal;
      itemBalancesOfTokenWithTypes_[i].installationType = s.installationTypes[itemId];
    }
  }

  function addToParent(
    address _toContract,
    uint256 _toTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.nftInstallationBalances[_toContract][_toTokenId][_id] += _value;
    if (s.nftInstallationIndexes[_toContract][_toTokenId][_id] == 0) {
      s.nftInstallations[_toContract][_toTokenId].push(uint16(_id));
      s.nftInstallationIndexes[_toContract][_toTokenId][_id] = s.nftInstallations[_toContract][_toTokenId].length;
    }
  }

  function addToOwner(
    address _to,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.ownerInstallationBalances[_to][_id] += _value;
    if (s.ownerInstallationIndexes[_to][_id] == 0) {
      s.ownerInstallations[_to].push(uint16(_id));
      s.ownerInstallationIndexes[_to][_id] = s.ownerInstallations[_to].length;
    }
  }

  function removeFromOwner(
    address _from,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 bal = s.ownerInstallationBalances[_from][_id];
    require(_value <= bal, "LibItems: Doesn't have that many to transfer");
    bal -= _value;
    s.ownerInstallationBalances[_from][_id] = bal;
    if (bal == 0) {
      uint256 index = s.ownerInstallationIndexes[_from][_id] - 1;
      uint256 lastIndex = s.ownerInstallations[_from].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.ownerInstallations[_from][lastIndex];
        s.ownerInstallations[_from][index] = uint16(lastId);
        s.ownerInstallationIndexes[_from][lastId] = index + 1;
      }
      s.ownerInstallations[_from].pop();
      delete s.ownerInstallationIndexes[_from][_id];
    }
  }

  function removeFromParent(
    address _fromContract,
    uint256 _fromTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 bal = s.nftInstallationBalances[_fromContract][_fromTokenId][_id];
    require(_value <= bal, "Items: Doesn't have that many to transfer");
    bal -= _value;
    s.nftInstallationBalances[_fromContract][_fromTokenId][_id] = bal;
    if (bal == 0) {
      uint256 index = s.nftInstallationIndexes[_fromContract][_fromTokenId][_id] - 1;
      uint256 lastIndex = s.nftInstallations[_fromContract][_fromTokenId].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.nftInstallations[_fromContract][_fromTokenId][lastIndex];
        s.nftInstallations[_fromContract][_fromTokenId][index] = uint16(lastId);
        s.nftInstallationIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
      }
      s.nftInstallations[_fromContract][_fromTokenId].pop();
      delete s.nftInstallationIndexes[_fromContract][_fromTokenId][_id];
      if (_fromContract == address(this)) {
        // checkWearableIsEquipped(_fromTokenId, _id);
      }
    }

    /*
    if (_fromContract == address(this) && bal == 1) {
      Aavegotchi storage aavegotchi = s.aavegotchis[_fromTokenId];
      if (
        aavegotchi.equippedWearables[LibItems.WEARABLE_SLOT_HAND_LEFT] == _id &&
        aavegotchi.equippedWearables[LibItems.WEARABLE_SLOT_HAND_RIGHT] == _id
      ) {
        revert("LibItems: Can't hold 1 item in both hands");
      }
      */
    // }
  }

  /*
  function checkWearableIsEquipped(uint256 _fromTokenId, uint256 _id) internal view {
    AppStorage storage s = LibAppStorage.diamondStorage();
    for (uint256 i; i < EQUIPPED_WEARABLE_SLOTS; i++) {
      require(s.aavegotchis[_fromTokenId].equippedWearables[i] != _id, "Items: Cannot transfer wearable that is equipped");
    }
  }
  */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import {LibDiamond} from "./LibDiamond.sol";

struct InstallationType {
  uint16 installationType; //0 = harvester, 1 = reservoir, 2 = altar, 3 = gotchi lodge
  uint16 level;
  uint256 width;
  uint256 height;
  uint16 alchemicaType; //0 = none 1 = fud, 2 = fomo, 3 = alpha, 4 = kek
  uint256[] alchemicaCost; // [fud, fomo, alpha, kek]
  uint256 harvestRate;
  uint256 capacity;
  uint256 spillRadius;
  uint256 spillPercentage;
  uint256 craftTime; // in blocks
  // glam token to reduce craftTime
}

struct QueueItem {
  uint256 id;
  uint256 readyBlock;
  uint256 installationType;
  bool claimed;
  address owner;
}

struct AppStorage {
  address realmDiamond;
  address aavegotchiDiamond;
  address[] alchemicaAddresses;
  string baseUri;
  InstallationType[] installationTypes;
  QueueItem[] craftQueue;
  uint256 nextCraftId;
  //ERC1155 vars
  mapping(address => mapping(address => bool)) operators;
  //ERC998 vars
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftInstallationBalances;
  mapping(address => mapping(uint256 => uint256[])) nftInstallations;
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftInstallationIndexes;
  mapping(address => mapping(uint256 => uint256)) ownerInstallationBalances;
  mapping(address => uint256[]) ownerInstallations;
  mapping(address => mapping(uint256 => uint256)) ownerInstallationIndexes;
}

library LibAppStorage {
  function diamondStorage() internal pure returns (AppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  AppStorage internal s;

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyRealmDiamond() {
    require(msg.sender == s.realmDiamond, "LibDiamond: Must be realm diamond");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function strWithUint(string memory _str, uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bytes memory buffer;
        unchecked {
            if (value == 0) {
                return string(abi.encodePacked(_str, "0"));
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            buffer = new bytes(digits);
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + (temp % 10)));
                temp /= 10;
            }
        }
        return string(abi.encodePacked(_str, buffer));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorage, AppStorage} from "./AppStorage.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";

library LibERC1155 {
  bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
  bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

  /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
  event URI(string _value, uint256 indexed _tokenId);

  event MintInstallation(address indexed _owner, uint256 indexed _installationType, uint256 _installationId);

  function _safeMint(
    address _to,
    uint256 _installationType,
    uint256 _queueId
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    require(!s.craftQueue[_queueId].claimed, "LibERC1155: tokenId already minted");
    require(s.craftQueue[_queueId].owner == _to, "LibERC1155: wrong owner");
    s.craftQueue[_queueId].claimed = true;
    addToOwner(_to, _installationType, 1);
    emit MintInstallation(_to, _installationType, _queueId);
    emit LibERC1155.TransferSingle(address(this), address(0), _to, _installationType, 1);
  }

  function addToOwner(
    address _to,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.ownerInstallationBalances[_to][_id] += _value;
    if (s.ownerInstallationIndexes[_to][_id] == 0) {
      s.ownerInstallations[_to].push(uint16(_id));
      s.ownerInstallationIndexes[_to][_id] = s.ownerInstallations[_to].length;
    }
  }

  function removeFromOwner(
    address _from,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 bal = s.ownerInstallationBalances[_from][_id];
    require(_value <= bal, "LibERC1155: Doesn't have that many to transfer");
    bal -= _value;
    s.ownerInstallationBalances[_from][_id] = bal;
    if (bal == 0) {
      uint256 index = s.ownerInstallationIndexes[_from][_id] - 1;
      uint256 lastIndex = s.ownerInstallations[_from].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.ownerInstallations[_from][lastIndex];
        s.ownerInstallations[_from][index] = uint16(lastId);
        s.ownerInstallationIndexes[_from][lastId] = index + 1;
      }
      s.ownerInstallations[_from].pop();
      delete s.ownerInstallationIndexes[_from][_id];
    }
  }

  function _burn(
    address _from,
    uint256 _installationType,
    uint256 _amount
  ) internal {
    removeFromOwner(_from, _installationType, _amount);
    emit LibERC1155.TransferSingle(address(this), _from, address(0), _installationType, _amount);
  }

  function onERC1155Received(
    address _operator,
    address _from,
    address _to,
    uint256 _id,
    uint256 _value,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data),
        "Wearables: Transfer rejected/failed by _to"
      );
    }
  }

  function onERC1155BatchReceived(
    address _operator,
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data),
        "Wearables: Transfer rejected/failed by _to"
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import "../interfaces/IERC20.sol";

library LibERC20 {
  function transferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _value
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_token)
    }
    require(size > 0, "LibERC20: Address has no code");
    (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
    handleReturn(success, result);
  }

  function transfer(
    address _token,
    address _to,
    uint256 _value
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_token)
    }
    require(size > 0, "LibERC20: Address has no code");
    (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
    handleReturn(success, result);
  }

  function handleReturn(bool _success, bytes memory _result) internal pure {
    if (_success) {
      if (_result.length > 0) {
        require(abi.decode(_result, (bool)), "LibERC20: contract call returned false");
      }
    } else {
      if (_result.length > 0) {
        // bubble up any reason for revert
        revert(string(_result));
      } else {
        revert("LibERC20: contract call reverted");
      }
    }
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
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
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount & 7 > 0) {
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];

                bytes32 oldFacet = ds.facets[selector];

                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}