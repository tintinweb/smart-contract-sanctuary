// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICrewGenerator.sol";


/**
 * @dev Contract which generates crew features based on the set they're part of
 */
contract CrewFeatures is Ownable {

  // Mapping of collectionIds to contract addresses of generators
  mapping (uint => ICrewGenerator) private _generators;

  // Mapping of tokenIds to collection membership
  mapping (uint => uint) private _crewCollection;

  // Mapping of tokenIds to modifiers
  mapping (uint => uint) private _crewModifiers;

  // Mapping indicating allowed managers
  mapping (address => bool) private _managers;

  event CollectionCreated(uint indexed id);
  event CollectionSeeded(uint indexed id);

  // Modifier to check if calling contract has the correct minting role
  modifier onlyManagers {
    require(isManager(_msgSender()), "CrewFeatures: Only managers can call this function");
    _;
  }

  /**
   * @dev Defines a collection and points to the relevant contract
   * @param _collId Id for the collection
   * @param _generator Address of the contract adhering to the appropriate interface
   */
  function setGenerator(uint _collId, ICrewGenerator _generator) external onlyOwner {
    _generators[_collId] = _generator;
    emit CollectionCreated(_collId);
  }

  /**
   * @dev Sets the seed for a given collection
   * @param _collId Id for the collection
   * @param _seed The seed to bootstrap the generator with
   */
  function setGeneratorSeed(uint _collId, bytes32 _seed) external onlyManagers {
    require(address(_generators[_collId]) != address(0), "CrewFeatures: collection must be defined");
    ICrewGenerator generator = _generators[_collId];
    generator.setSeed(_seed);
    emit CollectionSeeded(_collId);
  }

  /**
   * @dev Set a token with a specific crew collection
   * @param _crewId The ERC721 tokenID for the crew member
   * @param _collId The set ID to assign the crew member to
   * @param _mod An optional modifier ranging from 0 (default) to 10,000
   */
  function setToken(uint _crewId, uint _collId, uint _mod) external onlyManagers {
    require(address(_generators[_collId]) != address(0), "CrewFeatures: collection must be defined");
    _crewCollection[_crewId] = _collId;

    if (_mod > 0) {
      _crewModifiers[_crewId] = _mod;
    }
  }

  /**
   * @dev Returns the generated features for a crew member as a bitpacked uint
   * @param _crewId The ERC721 tokenID for the crew member
   */
  function getFeatures(uint _crewId) public view returns (uint) {
    uint generatorId = _crewCollection[_crewId];
    ICrewGenerator generator = _generators[generatorId];
    uint features = generator.getFeatures(_crewId, _crewModifiers[_crewId]);
    features |= generatorId << 0;
    return features;
  }

  /**
   * @dev Add a new account / contract that can mint / burn crew members
   * @param _manager Address of the new manager
   */
  function addManager(address _manager) external onlyOwner {
    _managers[_manager] = true;
  }

  /**
   * @dev Remove a current manager
   * @param _manager Address of the manager to be removed
   */
  function removeManager(address _manager) external onlyOwner {
    _managers[_manager] = false;
  }

  /**
   * @dev Checks if an address is a manager
   * @param _manager Address of contract / account to check
   */
  function isManager(address _manager) public view returns (bool) {
    return _managers[_manager];
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


interface ICrewGenerator {

  function setSeed(bytes32 _seed) external;

  function getFeatures(uint _crewId, uint _mod) external view returns (uint);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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