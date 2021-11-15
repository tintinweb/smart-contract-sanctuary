// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';

// This contract is a base for different modules,
// that can be passed on to new Octobay versions.
contract OctobayStorage is Ownable {

  address octobay;

  modifier onlyOctobay() {
    require(msg.sender == octobay, 'Only the current octobay version can use this function.');
    _;
  }

  function setOctobay(address _octobay) onlyOwner public {
    octobay = _octobay;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './OctobayStorage.sol';

// This contract acts as Octobay's user storage.
contract UserAddressStorage is OctobayStorage {
  // GitHub user's eth addresses
  // A user can have multiple (named) addresses.
  // GitHub GraphQL ID => (name => address)
  mapping(string => mapping(bytes32 => address)) public addresses;
  mapping(address => string) public userIdsByAddress;

  event UserAddressAddedEvent(string userId, bytes32 addressName, address ethAddress);
  event UserAddressRemovedEvent(string userId, bytes32 addressName, address ethAddress);

  function addUserAddress(
    string calldata _userId,
    bytes32 _addressName,
    address _address
  ) public onlyOctobay {
    require(addresses[_userId][_addressName] == address(0), 'An address with this name already exsits for this GitHub user.');
    addresses[_userId][_addressName] = _address;
    userIdsByAddress[_address] = _userId;

    emit UserAddressAddedEvent(
      _userId,
      _addressName,
      _address
    );
  }

  function deleteUserAddress(
    string calldata _userId,
    bytes32 _addressName
  ) public onlyOctobay {
    emit UserAddressRemovedEvent(
      _userId,
      _addressName,
      addresses[_userId][_addressName]
    );

    delete userIdsByAddress[addresses[_userId][_addressName]];
    delete addresses[_userId][_addressName];
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

