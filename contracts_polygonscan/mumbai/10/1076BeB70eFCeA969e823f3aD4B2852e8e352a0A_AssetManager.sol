/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

// File contracts/access/Owned.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Owned {

    address public owner;
    address public nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerNominated(address indexed newOwner);

    constructor(address _owner) {
        require(_owner != address(0),
            "Address cannot be 0");

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function nominateNewOwner(address _owner)
    external
    onlyOwner {
        nominatedOwner = _owner;

        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
    external {
        require(msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership");

        emit OwnershipTransferred(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
            "Only the contract owner may perform this action");
        _;
    }

}


// File contracts/access/AccessController.sol



pragma solidity 0.8.7;

contract AccessController is Owned {

  mapping(bytes32 => mapping(address => bool)) public roles;

  constructor(
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations,
    address _owner
  ) Owned(_owner) {
    require(_roles.length == _authAddresses.length && _roles.length == _authorizations.length,
      "Input lenghts not matched");

    for(uint i = 0; i < _roles.length; i++) {
      _setAuthorizations(_roles[i], _authAddresses[i], _authorizations[i]);
    }
  }

  function setAuthorizations(
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations
  ) external
  onlyOwner {
    require(_roles.length == _authAddresses.length && _roles.length == _authorizations.length,
      "Input lenghts not matched");

    for(uint i = 0; i < _roles.length; i++) {
      _setAuthorizations(_roles[i], _authAddresses[i], _authorizations[i]);
    }
  }

  function _setAuthorizations(
    bytes32 _role,
    address _address,
    bool _authorization
  ) internal {
    roles[_role][_address] = _authorization;
  }

  modifier onlyRole(bytes32 _role, address _address) {
    require(roles[_role][_address],
      string(abi.encodePacked("Caller is not ", _role)));
    _;
  }

}


// File contracts/AssetManager.sol



pragma solidity ^0.8.7;

contract AssetManager is AccessController {

  mapping(uint => address) public versionToStorage; // version => storage_address

  mapping(address => uint) public storageToVersion; // storage_address => version

  bytes32 constant public GENERATOR_ROLE = "GENERATOR_ROLE";

  bytes32[] public assets;

  constructor(
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations,
    address _owner
  ) AccessController(
    _roles,
    _authAddresses,
    _authorizations,
    _owner
  ) {}

  function addStorage(uint _version, address _storage)
  external
  onlyOwner {
    require(versionToStorage[_version] == address(0),
      string(abi.encodePacked("storage is already assigned in the version ", _version)));

    versionToStorage[_version] = _storage;
    storageToVersion[_storage] = _version;
  }

  function addAsset(bytes32 _assetKey)
  external
  onlyRole(GENERATOR_ROLE, msg.sender) {
    assets.push(_assetKey);
  }

  function assetsLength()
  external view
  returns(uint) {
    return assets.length;
  }

}