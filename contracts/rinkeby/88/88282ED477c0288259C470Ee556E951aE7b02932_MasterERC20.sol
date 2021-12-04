//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/Dictionary.sol";
// import "./interfaces/IMasterERC20.sol";
import "./AddressContract.sol";

contract MasterERC20 is Ownable, AddressContract {
  Dictionary private config;
  // IMasterERC20 private caddress;

  constructor(address configFee) {
    config = Dictionary(configFee);
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

    bytes32[] memory _types = new bytes32[](10);
    for(uint256 index = 0; index < _keyTypes.length; index++) {
      _types[index] = keccak256(abi.encodePacked(_keyTypes[index]));
    }
    
    bytes32 check = keccak256(abi.encodePacked(_types));
    require(mapMasterERC20[check] == 0x35c2D5F8C9c7091a8F5569E4053008A3D233CE6E, "ERC20: ERROR");

    // caddress = IMasterERC20(mapMasterERC20[check]);
    // caddress.createERC20(name, symbol, decimal, initialSupply, _cap);
  
    // (bool success, ) = mapMasterERC20[check].delegatecall(abi.encodePacked(bytes4(keccak256("createERC20(string, string, uint256, uint256, uint256)")), name, symbol, decimal, initialSupply, _cap));
    // require(success, "Delegatecall failed");
  }

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


contract AddressContract {

    mapping(bytes32 => address) public mapMasterERC20;
    
    bytes32 _standard = keccak256(abi.encodePacked("20standard"));
    bytes32 _mint = keccak256(abi.encodePacked("20mint"));
    bytes32 _burn = keccak256(abi.encodePacked("20burn"));
    bytes32 _pause = keccak256(abi.encodePacked("20pause"));
    bytes32 _gover = keccak256(abi.encodePacked("20governance"));

    //
    bytes32 standard = keccak256(abi.encodePacked([_standard]));
    bytes32 mint = keccak256(abi.encodePacked([_standard,_mint]));
    bytes32 burn = keccak256(abi.encodePacked([_standard,_burn]));
    bytes32 pause = keccak256(abi.encodePacked([_standard,_pause]));
    bytes32 gover = keccak256(abi.encodePacked([_standard,_gover]));
    bytes32 mintBurn = keccak256(abi.encodePacked([_standard,_mint,_burn]));
    bytes32 mintPause = keccak256(abi.encodePacked([_standard,_mint,_pause]));
    bytes32 mintGover = keccak256(abi.encodePacked([_standard,_mint,_gover]));
    bytes32 burnPause = keccak256(abi.encodePacked([_standard,_burn,_pause]));
    bytes32 burnGover = keccak256(abi.encodePacked([_standard,_burn,_gover]));
    bytes32 pauseGover = keccak256(abi.encodePacked([_standard,_pause,_gover]));
    bytes32 mintBurnPause = keccak256(abi.encodePacked([_standard,_mint,_burn,_pause]));
    bytes32 mintBurnGover = keccak256(abi.encodePacked([_standard,_mint,_burn,_gover]));
    bytes32 mintPauseGover = keccak256(abi.encodePacked([_standard,_mint,_pause,_gover]));
    bytes32 burnPauseGover = keccak256(abi.encodePacked([_standard,_burn,_pause,_gover]));
    bytes32 mintBurnPauseGover = keccak256(abi.encodePacked([_standard,_mint,_burn,_pause,_gover]));


    // bytes
    constructor() {
         mapMasterERC20[standard] = 0x35c2D5F8C9c7091a8F5569E4053008A3D233CE6E;
         mapMasterERC20[mint] = 0x0ac2e6D3C208817e2ff01D3EA62936Bab68cf814;
         mapMasterERC20[burn] = 0x8967223E884Be0b5af128a061693de6bDdc17BA1;
         mapMasterERC20[pause] = 0xa17f572f043096994671f3ecAE00552fb99Dde1b;
         mapMasterERC20[gover] = 0x0Bc93B99f024dc14F4C716c257630002875a1547;
         mapMasterERC20[mintBurn] = 0x3111E6D192C6C095Ad6dd73b8aa14A072e800B7A;
         mapMasterERC20[mintPause] = 0x5f4dE9D080361Fb64B311c27a5bC2ef67b05cb94;
         mapMasterERC20[mintGover] = 0x0DbC7BCfAa0a3a3702A9942773FbbeE28e33Fd5B;
         mapMasterERC20[burnPause] = 0x95a5136AEE00f1C359e1B6AA403115e9c94c75aA;
         mapMasterERC20[burnGover] = 0x846287B8237611EAbBa3bA012f0B6e638Cb45AbD;
         mapMasterERC20[pauseGover] = 0xb61d5F6A7cB25B1cd836729222e9e3A9aEE0Eb63;
         mapMasterERC20[mintBurnPause] = 0x695C5e4DCC28fe6fdbF5900d38cfd66e3826349C;
         mapMasterERC20[mintBurnGover] = 0x8b95cC540eb70c07F9C2389abb74C3900F1c07Ae;
         mapMasterERC20[mintPauseGover] = 0xe530bc82A093b42A35c230715fbb79B7F3d8148c;
         mapMasterERC20[burnPauseGover] = 0x1A4377f3E090A75Ac8175AadfeF8f6337bE965ac;
         mapMasterERC20[mintBurnPauseGover] = 0x1F0701FF44eFe85929a9c3ed32385162C4696916;

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
      addressContract == _msgSender(),
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
    _setContractOwner(_addressContract);
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