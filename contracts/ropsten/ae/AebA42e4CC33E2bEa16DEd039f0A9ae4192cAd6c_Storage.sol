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
        return msg.data;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Storage is Ownable {
  /// @dev Bytes storage.
  mapping(bytes32 => bytes) private _bytes;

  /// @dev Bool storage.
  mapping(bytes32 => bool) private _bool;

  /// @dev Uint storage.
  mapping(bytes32 => uint256) private _uint;

  /// @dev Int storage.
  mapping(bytes32 => int256) private _int;

  /// @dev Address storage.
  mapping(bytes32 => address) private _address;

  /// @dev String storage.
  mapping(bytes32 => string) private _string;

  event Updated(bytes32 indexed key);

  /**
   * @param key The key for the record
   */
  function getBytes(bytes32 key) external view returns (bytes memory) {
    return _bytes[key];
  }

  /**
   * @param key The key for the record
   */
  function getBool(bytes32 key) external view returns (bool) {
    return _bool[key];
  }

  /**
   * @param key The key for the record
   */
  function getUint(bytes32 key) external view returns (uint256) {
    return _uint[key];
  }

  /**
   * @param key The key for the record
   */
  function getInt(bytes32 key) external view returns (int256) {
    return _int[key];
  }

  /**
   * @param key The key for the record
   */
  function getAddress(bytes32 key) external view returns (address) {
    return _address[key];
  }

  /**
   * @param key The key for the record
   */
  function getString(bytes32 key) external view returns (string memory) {
    return _string[key];
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setBytes(bytes32 key, bytes calldata value) external onlyOwner {
    _bytes[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setBool(bytes32 key, bool value) external onlyOwner {
    _bool[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setUint(bytes32 key, uint256 value) external onlyOwner {
    _uint[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setInt(bytes32 key, int256 value) external onlyOwner {
    _int[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setAddress(bytes32 key, address value) external onlyOwner {
    _address[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setString(bytes32 key, string calldata value) external onlyOwner {
    _string[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteBytes(bytes32 key) external onlyOwner {
    delete _bytes[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteBool(bytes32 key) external onlyOwner {
    delete _bool[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteUint(bytes32 key) external onlyOwner {
    delete _uint[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteInt(bytes32 key) external onlyOwner {
    delete _int[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteAddress(bytes32 key) external onlyOwner {
    delete _address[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteString(bytes32 key) external onlyOwner {
    delete _string[key];
    emit Updated(key);
  }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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