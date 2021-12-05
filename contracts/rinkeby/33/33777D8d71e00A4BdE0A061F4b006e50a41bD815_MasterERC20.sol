//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/Dictionary.sol";
import "./interfaces/IMasterERC20.sol";
import "./ListAddressContract.sol";
import "../../access/GroupOwner.sol";

contract MasterERC20 is GroupOwnable {
  Dictionary private config;
  IMasterERC20 private iMasterERC20;
  ListAddressContract private caddress;

  constructor(address configFee, address _caddress) {
    config = Dictionary(configFee);
    caddress = ListAddressContract(_caddress);
  }

  function createTokenERC20(
    string[] memory _keyTypes,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 _cap
  ) external payable {
    require(
      keccak256(abi.encodePacked((name))) != keccak256(abi.encodePacked((""))),
      "require name"
    );
    require(
      keccak256(abi.encodePacked((symbol))) !=
        keccak256(abi.encodePacked((""))),
      "require symbol"
    );

    require(
      msg.value == config.getFees(_keyTypes),
      "ERC20:feeContract must be compare payableAmount"
    );

    bytes32[] memory _types = new bytes32[](_keyTypes.length);
    for (uint256 index = 0; index < _keyTypes.length; index++) {
      _types[index] = keccak256(abi.encodePacked(_keyTypes[index]));
    }
    bytes32 check = keccak256(abi.encodePacked(_types));

    address s = caddress.getValue(check);

    iMasterERC20 = IMasterERC20(s);
    iMasterERC20.createERC20(name, symbol, decimal, initialSupply, _cap);
  }

  function withdraw(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../access/GroupOwner.sol';
import './interfaces/IDictionary.sol';


contract Dictionary is IDictionary, GroupOwnable {
    mapping(bytes32 => uint256) private fees;

    function getFee(string memory key) override public view returns (uint256) {
        bytes32 encodedKey = keccak256(abi.encodePacked(key));
        return fees[encodedKey];
    }

    function getFees(string[] memory keys) override public view returns (uint256) {
        uint256 fee;
        for (uint256 index = 0; index < keys.length; index++) {
            bytes32 encodedKey = keccak256(abi.encodePacked(keys[index]));
            fee += fees[encodedKey];
        }
        return fee;
    }

    function setFee(string memory key, uint256 value ) override public groupOwner {
        bytes32 encodedKey = keccak256(abi.encodePacked(key));
        fees[encodedKey] = value;
    }

    function getEncodedKey(string memory key) override public pure returns (bytes32) {
        return keccak256(abi.encodePacked(key));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterERC20 {

  function createERC20(
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 cap
  ) external;

  event ChildCreatedERC20 (
    address childAddress,
    string name,
    string symbol
  );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ListAddressContract {
  mapping(bytes32 => address) public mapMasterERC20;

  bytes32 _standard = keccak256(abi.encodePacked("20standard"));
  bytes32 _mint = keccak256(abi.encodePacked("20mint"));
  bytes32 _burn = keccak256(abi.encodePacked("20burn"));
  bytes32 _pause = keccak256(abi.encodePacked("20pause"));
  bytes32 _gover = keccak256(abi.encodePacked("20governance"));

  //
  bytes32 standard = keccak256(abi.encodePacked([_standard]));
  bytes32 mint = keccak256(abi.encodePacked([_standard, _mint]));
  bytes32 burn = keccak256(abi.encodePacked([_standard, _burn]));
  bytes32 pause = keccak256(abi.encodePacked([_standard, _pause]));
  bytes32 gover = keccak256(abi.encodePacked([_standard, _gover]));
  bytes32 mintBurn = keccak256(abi.encodePacked([_standard, _mint, _burn]));
  bytes32 mintPause = keccak256(abi.encodePacked([_standard, _mint, _pause]));
  bytes32 mintGover = keccak256(abi.encodePacked([_standard, _mint, _gover]));
  bytes32 burnPause = keccak256(abi.encodePacked([_standard, _burn, _pause]));
  bytes32 burnGover = keccak256(abi.encodePacked([_standard, _burn, _gover]));
  bytes32 pauseGover = keccak256(abi.encodePacked([_standard, _pause, _gover]));
  bytes32 mintBurnPause =
    keccak256(abi.encodePacked([_standard, _mint, _burn, _pause]));
  bytes32 mintBurnGover =
    keccak256(abi.encodePacked([_standard, _mint, _burn, _gover]));
  bytes32 mintPauseGover =
    keccak256(abi.encodePacked([_standard, _mint, _pause, _gover]));
  bytes32 burnPauseGover =
    keccak256(abi.encodePacked([_standard, _burn, _pause, _gover]));
  bytes32 mintBurnPauseGover =
    keccak256(abi.encodePacked([_standard, _mint, _burn, _pause, _gover]));

  // bytes
  constructor() {
    mapMasterERC20[standard] = 0xBeD06b507981042aD436833bF5e707287190431e;
    mapMasterERC20[mint] = 0xE8b9292AEa87220aE58A0B5343b0755C6d2E9f50;
    mapMasterERC20[burn] = 0xD56e182f16A09aC61E4f49EbdC85CE82F9DAd625;
    mapMasterERC20[pause] = 0x0650a4253B0Be6921A49ABDEfCE1857F640bb5a5;
    mapMasterERC20[gover] = 0xE9a4ADf4d78bf21e3E064c60073F0e423B2b424f;
    mapMasterERC20[mintBurn] = 0x7995454C2a05405e45d3185A68312a3AC6e34D49;
    mapMasterERC20[mintPause] = 0x3012EA13718a306688685770560A6B8CD1789034;
    mapMasterERC20[mintGover] = 0x35a585D43EbEf6628BB610c180649aCC0a1D2388;
    mapMasterERC20[burnPause] = 0xD3e0d4c229B6eAaB4D7809cF4713cE864B29543a;
    mapMasterERC20[burnGover] = 0x6897bad7e6A09a79AF7bf8dEcD62114BCaaB6A3F;
    mapMasterERC20[pauseGover] = 0xA46B8897c2b657ffedbAb2A013F33ba6BF9c1F0F;
    mapMasterERC20[mintBurnPause] = 0x1e59279E29dACBfcA75EA5d7bC3142AAd61BF728;
    mapMasterERC20[mintBurnGover] = 0x52AD02C3f0c753D355e6F31eDf262d132eEB08B1;
    mapMasterERC20[mintPauseGover] = 0xCf73cB3181123383E63b3524b354Acb8179bCB5c;
    mapMasterERC20[burnPauseGover] = 0xCf395A2CB61500ded98337678787feAb404eD497;
    mapMasterERC20[mintBurnPauseGover] = 0xf5143E7b2F09C5507dE512A94281625BE0fb7F2A;
  }

  function getValue(bytes32 check) public view returns (address) {
    return mapMasterERC20[check];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../libraries/Context.sol";
import "./Owner.sol";

abstract contract GroupOwnable is Context, Ownable {
  address private addressContract;
  address[] public owners;
  mapping(address => bool) public ownerByAddress;

  event SetOwners(address[] owners);
  event RemoveOwners(address[] owners);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    ownerByAddress[_msgSender()] == true;
  }

  /**
   * @dev groupOwner.
   */
  modifier groupOwner() {
    require(
      checkOwner(_msgSender()) || owner() == _msgSender(),
      "GroupOwner: caller is not the owner"
    );
    _;
  }

  /**
   * @dev Function to set owners addresses
   */
  function setGroupOwners(address[] memory _owners) public virtual groupOwner {
    _setOwners(_owners);
  }

  function _setOwners(address[] memory _owners) private {
    for (uint256 index = 0; index < _owners.length; index++) {
      if (!ownerByAddress[_owners[index]]) {
        ownerByAddress[_owners[index]] = true;
        owners.push(_owners[index]);
      }
    }
    emit SetOwners(owners);
  }

  /**
   * @dev Function to remove owners addresses
   */
  function removeOwner(address _oldowner) public virtual groupOwner {
    _removeOwner(_oldowner);
  }

  function _removeOwner(address _oldowner) private {
    ownerByAddress[_oldowner] = true;

    emit RemoveOwners(owners);
  }

  function checkOwner(address newOwner) public view virtual returns (bool) {
    return ownerByAddress[newOwner];
  }

  function getOwners() public view virtual returns (address[] memory) {
    return owners;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../access/Owner.sol';

interface IDictionary {
    function getFee(string memory key) external view returns (uint256);
    function setFee(string memory key, uint256 value) external;
    function getEncodedKey(string memory key) external pure returns (bytes32);
    function getFees(string[] memory keys) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../libraries/Context.sol";

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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