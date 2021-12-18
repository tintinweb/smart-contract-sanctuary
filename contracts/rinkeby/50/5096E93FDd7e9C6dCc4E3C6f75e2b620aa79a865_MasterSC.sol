//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Dictionary.sol";
import "../proxy/Initializable.sol";
import "../access/OwnerUpgradeable.sol";

contract MasterSC is Initializable, OwnableUpgradeable {
  Dictionary private config;
  mapping(address => uint256) private balances;
  address private addrRecipient;

  event ChildCreatedERC(
    string[] key,
    address sender,
    string name,
    string symbol,
    uint256 decimal,
    uint256 initialSupply,
    uint256 cap,
    uint256 amount,
    string metadata
  );
  event Transfer(address indexed from, address indexed to, uint256 value);

  function initialize(address _config) public virtual initializer {
    __MasterERC721_init(_config);
  }

  function __MasterERC721_init(address _config) internal initializer {
    __Ownable_init_unchained();
    __MasterERC721_init_unchained(_config);
  }

  function __MasterERC721_init_unchained(address _config) internal initializer {
    addrRecipient = owner();
    config = Dictionary(_config);
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  function createTokenERC20(
    string[] memory _keyTypes,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 _cap
  ) external payable {
    require(!isContract(owner()));
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

    emit ChildCreatedERC(
      _keyTypes,
      msg.sender,
      name,
      symbol,
      decimal,
      initialSupply,
      _cap,
      0,
      ""
    );

    balances[getRecipient()] += msg.value;
    _transfer(getRecipient(), balances[getRecipient()]);
  }

  function createTokenERC777(
    string[] memory _keyTypes,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 _cap
  ) external payable {
    require(!isContract(owner()));
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

    emit ChildCreatedERC(
      _keyTypes,
      msg.sender,
      name,
      symbol,
      decimal,
      initialSupply,
      _cap,
      0,
      ""
    );

    balances[getRecipient()] += msg.value;
    _transfer(getRecipient(), balances[getRecipient()]);
  }

  function createTokenERC721(
    string[] memory _keyTypes,
    string memory name,
    string memory symbol,
    string memory metadata
  ) external payable {
    require(!isContract(owner()));
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

    emit ChildCreatedERC(
      _keyTypes,
      msg.sender,
      name,
      symbol,
      0,
      0,
      0,
      0,
      metadata
    );

    balances[getRecipient()] += msg.value;
    _transfer(getRecipient(), balances[getRecipient()]);
  }

  function createTokenERC1155(
    string[] memory _keyTypes,
    string memory name,
    string memory symbol,
    uint256 amount,
    string memory metadata
  ) external payable {
    require(!isContract(owner()));
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

    emit ChildCreatedERC(
      _keyTypes,
      msg.sender,
      name,
      symbol,
      0,
      0,
      0,
      amount,
      metadata
    );

    balances[getRecipient()] += msg.value;
    _transfer(getRecipient(), balances[getRecipient()]);
  }

  function getRecipient() public view virtual returns (address) {
    return addrRecipient;
  }

  function setRecipient(address newAddr) public virtual onlyOwner {
    addrRecipient = newAddr;
  }

  function _transfer(address recipient, uint256 value) internal virtual {
    require(recipient != address(0), "Transfer to the zero address");
    balances[recipient] = 0;
    (bool success, ) = recipient.call{value: value}("");
    require(success, "Failed to send Ether");

    emit Transfer(owner(), recipient, value);
  }

  function transfer(address recipient, uint256 value) public virtual {
    _transfer(recipient, value);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../access/GroupOwner.sol";
import "./interfaces/IDictionary.sol";

contract Dictionary is IDictionary, GroupOwnable {
  mapping(bytes32 => uint256) private fees;
  mapping(bytes32 => address) public mapMasterERC20;

  function getFee(string memory key) public view override returns (uint256) {
    bytes32 encodedKey = keccak256(abi.encodePacked(key));
    return fees[encodedKey];
  }

  function getFees(string[] memory keys)
    public
    view
    override
    returns (uint256)
  {
    uint256 fee;
    for (uint256 index = 0; index < keys.length; index++) {
      bytes32 encodedKey = keccak256(abi.encodePacked(keys[index]));
      fee += fees[encodedKey];
    }
    return fee;
  }

  function setFee(string memory key, uint256 value) public override groupOwner {
    bytes32 encodedKey = keccak256(abi.encodePacked(key));
    fees[encodedKey] = value;
  }

  function setFees(string[] memory key, uint256[] memory value)
    public
    override
    groupOwner
  {
    bytes32 encodedKey;
    for (uint256 index = 0; index < key.length; index++) {
      encodedKey = keccak256(abi.encodePacked(key[index]));
      fees[encodedKey] = value[index];
    }
  }

  function getEncodedKey(string memory key)
    public
    pure
    override
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(key));
  }

  function setContractAddress(string[] memory key, address addressContract)
    public
    override
    virtual
    groupOwner
  {
    bytes32[] memory _types = new bytes32[](key.length);
    for (uint256 index = 0; index < key.length; index++) {
      _types[index] = keccak256(abi.encodePacked(key[index]));
    }
    bytes32 _key = keccak256(abi.encodePacked(_types));
    mapMasterERC20[_key] = addressContract;
  }

  function setContractsAddress(
    string[][] memory key,
    address[] memory addressContract
  ) public override virtual groupOwner {
    for (uint256 index1 = 0; index1 < key.length; index1++) {
      bytes32[] memory _types = new bytes32[](key[index1].length);
      for (uint256 index2 = 0; index2 < key[index1].length; index2++) {
        _types[index2] = keccak256(abi.encodePacked(key[index1][index2]));
      }
      bytes32 _key = keccak256(abi.encodePacked(_types));
      mapMasterERC20[_key] = addressContract[index1];
    }
  }

  function getContractAddress(string[] memory key)
    public
    override
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
import "../proxy/Initializable.sol";

abstract contract OwnableUpgradeable is Initializable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function __Ownable_init() internal initializer {
    __Ownable_init_unchained();
  }

  function __Ownable_init_unchained() internal initializer {
    _setOwner(msg.sender);
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
    require(owner() == msg.sender, "Ownable: caller is not the owner");
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

import "../../access/Owner.sol";

interface IDictionary {
  function getFee(string memory key) external view returns (uint256);

  function setFee(string memory key, uint256 value) external;

  function setFees(string[] memory key, uint256[] memory value) external;

  function getEncodedKey(string memory key) external pure returns (bytes32);

  function getFees(string[] memory keys) external view returns (uint256);

  function setContractAddress(string[] memory key, address addressContract)
    external;

  function setContractsAddress(
    string[][] memory key,
    address[] memory addressContract
  ) external;

  function getContractAddress(string[] memory key)
    external
    view
    returns (address);
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