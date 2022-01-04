//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Dictionary.sol";
import "../proxy/Initializable.sol";
import "../access/OwnerUpgradeable.sol";

contract TransferFeeToDeployer is Initializable, OwnableUpgradeable {
  Dictionary private config;
  mapping(address => uint256) private balances;
  address private addrRecipient;

  event EventCreated(
    uint256 request_id,
    string[] key,
    address sender,
    string[] optionsKey,
    string[] optionsValue
  );
  event TransferFee(address indexed from, address indexed to, uint256 value);

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

  function transferFee(string memory keyType) public payable virtual {
    keyType = 'aaa';
    balances[owner()] += msg.value;
    _transfer(getRecipient(), balances[owner()]);
  }

  function getRecipient() public view virtual returns (address) {
    return addrRecipient;
  }

  function setRecipient(address newAddr) public virtual onlyOwner {
    addrRecipient = newAddr;
  }

  function _transfer(address recipient, uint256 value) internal virtual {
    require(recipient != address(0), "Transfer to the zero address");
    uint256 senderBalance = balances[owner()];
    require(senderBalance >= value, "Transfer amount exceeds balance");
    unchecked {
      balances[owner()] = senderBalance - value;
    }
    (bool success, ) = recipient.call{value: value}("");
    require(success, "Failed to send Ether");

    emit TransferFee(owner(), recipient, value);
  }

  function transfer(address recipient, uint256 value) public virtual onlyOwner {
    _transfer(recipient, value);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../access/GroupOwner.sol";
import "./interfaces/IDictionary.sol";

contract Dictionary is IDictionary, GroupOwnable {
  mapping(bytes32 => uint256) private fees;

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

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Initializable {
  
  bool private _initialized;

  bool private _initializing;

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

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _setOwner(address(0));
  }

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

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GroupOwnable is Ownable {
  address private addressContract;
  address[] public owners;
  mapping(address => bool) public ownerByAddress;

  event SetOwners(address[] owners);
  event RemoveOwners(address[] owners);

  constructor() {
    ownerByAddress[_msgSender()] == true;
  }

  modifier groupOwner() {
    require(
      checkOwner(_msgSender()) || owner() == _msgSender(),
      "GroupOwner: caller is not the owner"
    );
    _;
  }

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

interface IDictionary {
  function getFee(string memory key) external view returns (uint256);

  function setFee(string memory key, uint256 value) external;

  function setFees(string[] memory key, uint256[] memory value) external;

  function getEncodedKey(string memory key) external pure returns (bytes32);

  function getFees(string[] memory keys) external view returns (uint256);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}