//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/Dictionary.sol";
import "./interfaces/IMasterERC20.sol";
import "./ListAddressContract.sol";

contract MasterERC20 is Ownable {
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

  function test() public returns (bool) {}

  function withdraw(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../access/Owner.sol';
import './interfaces/IDictionary.sol';


contract Dictionary is IDictionary, Ownable {
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
    mapMasterERC20[standard] = 0xcbDd6e29b3cf751b49eF09f0fc73e81107ae06A1;
    mapMasterERC20[mint] = 0x7b7046AA86C8C8A30aB74b8d673B9f1446dbD27B;
    mapMasterERC20[burn] = 0x17589D783f0959D46D922d25350e0084F0Ed6090;
    mapMasterERC20[pause] = 0x2eb92B0559F775C850F21082E6A3F05528C79251;
    mapMasterERC20[gover] = 0x7E0Df58a08aa40af34b6547EF0Ee20299ECFFE35;
    mapMasterERC20[mintBurn] = 0xE06D3B044d21176BB04b813DdDC33b69578BaE60;
    mapMasterERC20[mintPause] = 0x4950969d102c36a09f41DF7f44BF45f97A693195;
    mapMasterERC20[mintGover] = 0xd8fD91A3D844Da4890f3249442Ab04B4a553Cb40;
    mapMasterERC20[burnPause] = 0x3677320c53bd1262C26a6564a0b54D3547464470;
    mapMasterERC20[burnGover] = 0xF83369511897eD1d9C315C137f798aCeCFc84E9c;
    mapMasterERC20[pauseGover] = 0x33722b6CAf3B4fC586166A4a8F5BDAA3Ca963228;
    mapMasterERC20[mintBurnPause] = 0x5bB793cdEAdD5c3B428458dc3E4C1BA82768b34e;
    mapMasterERC20[mintBurnGover] = 0x958e6E3f3d4c6673CB214B7dDEa486bC88BC7D49;
    mapMasterERC20[mintPauseGover] = 0x113842B543922456549C061994148Aa1516638Bb;
    mapMasterERC20[burnPauseGover] = 0x5A3972C88612F4a220e85d040C911aE5e4bf99Ae;
    mapMasterERC20[mintBurnPauseGover] = 0x52AaCBE05014D534f7B09A461F20e51bbF4064B6;
  }

  function getValue(bytes32 check) public view returns (address) {
    return mapMasterERC20[check];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../libraries/Context.sol";

abstract contract Ownable is Context {
  address private _owner;
  address private addressContract;
  address[] public owners;
  mapping(address => bool) public ownerByAddress;

  event SetOwners(address[] owners);
  event RemoveOwners(address[] owners);
  event SetContractOwner(address addressContract);

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _setOwner(_msgSender());
    ownerByAddress[_msgSender()] == true;
    setContractOwner(_msgSender());
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
   * @dev contractOwner.
   */
  modifier contractOwner() {
    require(
      addressContract == msg.sender,
      "ContractOwner: caller is not the contract owner"
    );
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

  /**
   * @dev Function to set owner contract
   */
  function setContractOwner(address _addressContract) public virtual onlyOwner {
    _setContractOwner(msg.sender);
  }

  function _setContractOwner(address _addressContract) private {
    addressContract = _addressContract;
    emit SetContractOwner(addressContract);
  }

  function getContractOwner() public view virtual returns (address) {
    return addressContract;
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