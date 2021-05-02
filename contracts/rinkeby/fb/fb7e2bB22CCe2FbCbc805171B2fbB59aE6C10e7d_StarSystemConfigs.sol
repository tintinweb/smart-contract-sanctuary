// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

library PlanetCounter {
    function planetCount(bytes32 _sysMap) internal pure returns (uint _count) {
        uint prevPosition;
        while(_sysMap > 0) {
            require(uint(_sysMap) & 255 == 5, "Invalid planet {type}{color}{hp}");
            uint position = (uint(_sysMap) >> 8) & 255;
            require(_count == 0 || position < prevPosition, "Invalid planet position");
            prevPosition = position;
            _count++;
            _sysMap >>= 16;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystemData is Ownable {

    struct SysData {
        bytes32 map;
        address owner;
    }

    uint public numSystems;
    mapping(uint => SysData) public sysData; // [sysId]
    mapping(address => bool) public dataEditors;

    event StarSystemMapSet(uint indexed _sysId, bytes32 _newMap);
    event StarSystemOwnerSet(uint indexed _sysId, address indexed _owner);
    event StarSystemDataCleared(uint indexed _sysId);

    modifier onlyDataEditor {
        require(dataEditors[msg.sender], "Unauthorised to change system data");
        _;
    }

    function ownerOf(uint _sysId) public view returns (address) { return sysData[_sysId].owner; }
    function mapOf(uint _sysId) external view returns (bytes32) { return sysData[_sysId].map; }

    function setDataEditor(address _editor, bool _added) external onlyOwner { 
        dataEditors[_editor] = _added; 
    }

    function setOwner(uint _sysId, address _owner) public onlyDataEditor {
        require(_owner != address(0), "_owner cannot be null");
        if(ownerOf(_sysId) == address(0)) {
            numSystems++;
        }
        sysData[_sysId].owner = _owner;
        emit StarSystemOwnerSet(_sysId, _owner);
    }

    function setMap(uint _sysId, bytes32 _sysMap) public onlyDataEditor {
        require(_sysMap > 0 && uint(_sysMap) < 2**253, "Invalid system map"); // _sysMap must be smaller than snark scalar field (=> have first 3 bits empty)
        sysData[_sysId].map = _sysMap;
        emit StarSystemMapSet(_sysId, _sysMap);
    }

    function setSystemData(uint _sysId, address _owner, bytes32 _sysMap) external onlyDataEditor {
        setOwner(_sysId, _owner);
        setMap(_sysId, _sysMap);
    }

    function clearSystemData(uint _sysId) external onlyDataEditor {
        require(ownerOf(_sysId) != address(0), "system data not set");
        numSystems--;
        delete sysData[_sysId];
        emit StarSystemDataCleared(_sysId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "./StarSystemMapEditor.sol";

contract StarSystemConfigs is StarSystemMapEditor {
    struct PlayerConfig {
        uint8 minPlayers; // >= 2, <= 255
        uint8 maxPlayers; // >= 2, <= 255
    }

    struct ItemConfig {
        uint256 itemPrices;
        uint256 itemMaxQuantities;
    }

    struct TimeConfig {
        uint64 joinPeriod;
        uint64 playPeriod;
        uint64 exitPeriod;
        uint64 ransomPeriod;
        uint64 gracePeriod;
    }

    struct StakeConfig {
        address stakeToken;
        uint256 stakeInWei; // amount of tokens (in wei) staked by each player
    }

    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(uint => bytes32) public configIds; // [sysId] => [configId]
    mapping(bytes32 => TimeConfig) public timeConfigs; // [configId]
    mapping(bytes32 => uint16) public feesPer10000; // [configId]
    mapping(bytes32 => StakeConfig) public stakeConfigs; // [configId]
    mapping(bytes32 => ItemConfig) public itemConfigs; // [configId]
    mapping(bytes32 => PlayerConfig) public playerConfigs; // [configId]

    event ConfigCreated(address _creator, bytes32 _configId);
    event ConfigSelected(uint indexed _sysId, bytes32 _configId);

    constructor(StarSystemData _starSystemData) StarSystemMapEditor(_starSystemData) {}

    function createConfig(
        uint256 _sysId,
        bytes32 _sysMap,
        PlayerConfig memory _players,
        TimeConfig memory _times,
        ItemConfig memory _items,
        StakeConfig memory _stake,
        uint16 _feePer10000
    )
        public
    {
        bytes32 configId = keccak256(abi.encodePacked(
            _stake.stakeToken, _stake.stakeInWei, 
            _times.joinPeriod, _times.playPeriod, _times.exitPeriod, _times.ransomPeriod, _times.gracePeriod,
            _items.itemPrices, _items.itemMaxQuantities,
            _players.minPlayers, _players.maxPlayers,
            _feePer10000
        ));

        if(playerConfigs[configId].minPlayers == 0) {
            require(_players.minPlayers >= 2 && _players.maxPlayers <= 255 && _players.minPlayers <= _players.maxPlayers, "bad player limit");
            require(_feePer10000 <= 10000, "fee too big");
            require(_times.playPeriod > _times.ransomPeriod, "playPeriod too small");
            require(_items.itemPrices <= 2**253 && _items.itemMaxQuantities <= 2**253, "item param too big"); // need to be < than snark field

            stakeConfigs[configId].stakeToken = _stake.stakeToken;
            stakeConfigs[configId].stakeInWei = _stake.stakeInWei;

            timeConfigs[configId].joinPeriod = _times.joinPeriod;
            timeConfigs[configId].playPeriod = _times.playPeriod;
            timeConfigs[configId].exitPeriod = _times.exitPeriod;
            timeConfigs[configId].ransomPeriod = _times.ransomPeriod;
            timeConfigs[configId].gracePeriod = _times.gracePeriod;

            itemConfigs[configId].itemPrices = _items.itemPrices;
            itemConfigs[configId].itemMaxQuantities = _items.itemMaxQuantities;

            playerConfigs[configId].minPlayers = _players.minPlayers;
            playerConfigs[configId].maxPlayers = _players.maxPlayers;

            feesPer10000[configId] = _feePer10000;

            emit ConfigCreated(msg.sender, configId);
        }

        if(_sysId > 0) {
            changeConfigId(_sysId, configId);
            if(_sysMap > 0) {
                changeMap(_sysId, _sysMap);
            }
        }
    }

    function changeConfigId(uint _sysId, bytes32 _configId) public {
        require(starSystemData.ownerOf(_sysId) == msg.sender, "Should be system owner");
        require(playerConfigs[_configId].minPlayers > 0, "Invalid config");
        configIds[_sysId] = _configId;
        emit ConfigSelected(_sysId, _configId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "../StarSystemData.sol";
import "../../common/PlanetCounter.sol";

abstract contract StarSystemMapEditor {
    using PlanetCounter for bytes32;

    StarSystemData public immutable starSystemData;

    constructor(StarSystemData _starSystemData) { 
        starSystemData = _starSystemData;
    }

    function changeMap(uint _sysId, bytes32 _sysMap) public {
        require(msg.sender == starSystemData.ownerOf(_sysId), "sender should be system owner");
        require(_sysMap.planetCount() == starSystemData.mapOf(_sysId).planetCount(), "Map should keep same planet count");
        starSystemData.setMap(_sysId, _sysMap);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}