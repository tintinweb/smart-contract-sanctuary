// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import './EternalModel.sol';

/**
 * @title ElasticDAO ecosystem
 * @author ElasticDAO - https://ElasticDAO.org
 * @notice This contract is used for storing core dao data
 * @dev ElasticDAO network contracts can read/write from this contract
 * @dev Serialize - Translation of data from the concerned struct to key-value pairs
 * @dev Deserialize - Translation of data from the key-value pairs to a struct
 */
contract Ecosystem is EternalModel, ReentrancyGuard {
  struct Instance {
    address daoAddress;
    // Models
    address daoModelAddress;
    address ecosystemModelAddress;
    address tokenHolderModelAddress;
    address tokenModelAddress;
    // Tokens
    address governanceTokenAddress;
  }

  event Serialized(address indexed _daoAddress);

  /**
   * @dev deserializes Instance struct
   * @param _daoAddress - address of the unique user ID
   * @return record Instance
   */
  function deserialize(address _daoAddress) external view returns (Instance memory record) {
    if (_exists(_daoAddress)) {
      record.daoAddress = _daoAddress;
      record.daoModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'daoModelAddress'))
      );
      record.ecosystemModelAddress = address(this);
      record.governanceTokenAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'governanceTokenAddress'))
      );
      record.tokenHolderModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'tokenHolderModelAddress'))
      );
      record.tokenModelAddress = getAddress(
        keccak256(abi.encode(record.daoAddress, 'tokenModelAddress'))
      );
    }

    return record;
  }

  /**
   * @dev checks if @param _daoAddress
   * @param _daoAddress - address of the unique user ID
   * @return recordExists bool
   */
  function exists(address _daoAddress) external view returns (bool recordExists) {
    return _exists(_daoAddress);
  }

  /**
   * @dev serializes Instance struct
   * @param _record Instance
   */
  function serialize(Instance memory _record) external nonReentrant {
    bool recordExists = _exists(_record.daoAddress);

    require(
      msg.sender == _record.daoAddress || (_record.daoAddress == address(0) && !recordExists),
      'ElasticDAO: Unauthorized'
    );

    setAddress(
      keccak256(abi.encode(_record.daoAddress, 'daoModelAddress')),
      _record.daoModelAddress
    );
    setAddress(
      keccak256(abi.encode(_record.daoAddress, 'governanceTokenAddress')),
      _record.governanceTokenAddress
    );
    setAddress(
      keccak256(abi.encode(_record.daoAddress, 'tokenHolderModelAddress')),
      _record.tokenHolderModelAddress
    );
    setAddress(
      keccak256(abi.encode(_record.daoAddress, 'tokenModelAddress')),
      _record.tokenModelAddress
    );

    setBool(keccak256(abi.encode(_record.daoAddress, 'exists')), true);

    emit Serialized(_record.daoAddress);
  }

  function _exists(address _daoAddress) internal view returns (bool recordExists) {
    return getBool(keccak256(abi.encode(_daoAddress, 'exists')));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

/**
 * @title Implementation of Eternal Storage for ElasticDAO -
 * - (https://fravoll.github.io/solidity-patterns/eternal_storage.html)
 * @author ElasticDAO - https://ElasticDAO.org
 * @notice This contract is used for storing contract network data
 * @dev ElasticDAO network contracts can read/write from this contract
 */
contract EternalModel {
  struct Storage {
    mapping(bytes32 => address) addressStorage;
    mapping(bytes32 => bool) boolStorage;
    mapping(bytes32 => bytes) bytesStorage;
    mapping(bytes32 => int256) intStorage;
    mapping(bytes32 => string) stringStorage;
    mapping(bytes32 => uint256) uIntStorage;
  }

  Storage internal s;

  /**
   * @notice Getter Functions
   */

  /**
   * @notice Gets stored contract data in unit256 format
   * @param _key bytes32 location should be keccak256 and abi.encodePacked
   * @return uint256 _value from storage _key location
   */
  function getUint(bytes32 _key) internal view returns (uint256) {
    return s.uIntStorage[_key];
  }

  /**
   * @notice Get stored contract data in string format
   * @param _key bytes32 location should be keccak256 and abi.encodePacked
   * @return string _value from storage _key location
   */
  function getString(bytes32 _key) internal view returns (string memory) {
    return s.stringStorage[_key];
  }

  /**
   * @notice Get stored contract data in address format
   * @param _key bytes32 location should be keccak256 and abi.encodePacked
   * @return address _value from storage _key location
   */
  function getAddress(bytes32 _key) internal view returns (address) {
    return s.addressStorage[_key];
  }

  /**
   * @notice Get stored contract data in bool format
   * @param _key bytes32 location should be keccak256 and abi.encodePacked
   * @return bool _value from storage _key location
   */
  function getBool(bytes32 _key) internal view returns (bool) {
    return s.boolStorage[_key];
  }

  /**
   * @notice Setters Functions
   */

  /**
   * @notice Store contract data in uint256 format
   * @dev restricted to latest ElasticDAO Networks contracts
   * @param _key bytes32 location should be keccak256 and abi.encodePacked
   * @param _value uint256 value
   */
  function setUint(bytes32 _key, uint256 _value) internal {
    s.uIntStorage[_key] = _value;
  }

  /**
   * @notice Store contract data in string format
   * @dev restricted to latest ElasticDAO Networks contracts
   * @param _key bytes32 location should be keccak256 and abi.encodePacked
   * @param _value string value
   */
  function setString(bytes32 _key, string memory _value) internal {
    s.stringStorage[_key] = _value;
  }

  /**
   * @notice Store contract data in address format
   * @dev restricted to latest ElasticDAO Networks contracts
   * @param _key bytes32 location should be keccak256 and abi.encodePacked
   * @param _value address value
   */
  function setAddress(bytes32 _key, address _value) internal {
    s.addressStorage[_key] = _value;
  }

  /**
   * @notice Store contract data in bool format
   * @dev restricted to latest ElasticDAO Networks contracts
   * @param _key bytes32 location should be keccak256 and abi.encodePacked
   * @param _value bool value
   */
  function setBool(bytes32 _key, bool _value) internal {
    s.boolStorage[_key] = _value;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}