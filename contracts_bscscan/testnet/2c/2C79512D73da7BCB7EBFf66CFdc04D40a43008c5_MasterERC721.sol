//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/Dictionary.sol";
import "./interfaces/IMasterERC721.sol";
import "../ERC20/ListAddressContract.sol";
import "../../proxy/Initializable.sol";

contract MasterERC721 is Initializable {
  Dictionary private config;
  IMasterERC721 private iMasterERC721;
  ListAddressContract private cAddress;
  address payable public owner_;
  mapping(address => uint256) private balances;

  function initialize(address configFee, address _cAddress)
    public
    virtual
    initializer
  {
    __MasterERC721_init(configFee, _cAddress);
  }

  function __MasterERC721_init(address configFee, address _cAddress)
    internal
    initializer
  {
    __MasterERC721_init_unchained(configFee, _cAddress);
  }

  function __MasterERC721_init_unchained(address configFee, address _cAddress)
    internal
    initializer
  {
    owner_ = payable(msg.sender);
    config = Dictionary(configFee);
    cAddress = ListAddressContract(_cAddress);
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  function createTokenERC721(
    string[] memory _keyTypes,
    string memory name,
    string memory symbol,
    string memory metadata
  ) external payable {
    require(!isContract(owner_));
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
      "ERC721:feeContract must be compare payableAmount"
    );

    address s = cAddress.getContractAddress(_keyTypes);

    iMasterERC721 = IMasterERC721(s);
    iMasterERC721.createERC721(name, symbol, metadata);

    balances[owner_] += msg.value;
    withdraw();
  }

  function withdraw() private {
    uint256 amount = balances[owner_];
    balances[owner_] = 0;
    (bool success, ) = owner_.call{value: amount}("");
    require(success, "Failed to send Ether");
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

interface IMasterERC721 {
  function createERC721(
    string memory name,
    string memory symbol,
    string memory metadata
  ) external;

  event ChildCreatedERC721(address childAddress, string name, string symbol);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ListAddressContract {
  mapping(bytes32 => address) public mapMasterERC20;

  function setContractAddress(string[] memory key, address addressContract)
    public
    virtual
  {
    bytes32[] memory _types = new bytes32[](key.length);
    for (uint256 index = 0; index < key.length; index++) {
      _types[index] = keccak256(abi.encodePacked(key[index]));
    }
    bytes32 _key = keccak256(abi.encodePacked(_types));
    mapMasterERC20[_key] = addressContract;
  }

  function getContractAddress(string[] memory key)
    public
    view
    returns (address)
  {
    bytes32[] memory _types = new bytes32[](key.length);
    for (uint256 index = 0; index < key.length; index++) {
      _types[index] = keccak256(abi.encodePacked(key[index]));
    }
    bytes32 _key = keccak256(abi.encodePacked(_types));
    return mapMasterERC20[_key];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(
      _initializing || !_initialized,
      "Initializable: contract is already initialized"
    );

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Owner.sol";

abstract contract GroupOwnable is Ownable {
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