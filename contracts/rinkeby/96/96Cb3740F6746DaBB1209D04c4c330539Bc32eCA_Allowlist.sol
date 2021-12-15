// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title Allowlist
 * @dev The Allowlist contract has a allowlist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Allowlist is Ownable {
  mapping(address => bool) public allowlist;
  uint256 public maxLength = 1000;
  uint256 public memberCount = 0;
  event AllowlistedAddressAdded(address addr);
  event AllowlistedAddressRemoved(address addr);

  // ------------------
  // modifiers
  // ------------------

  modifier whenAllowlistNotFull() {
    require(memberCount < maxLength, "RetroPhonesAllowlist: Allowlist full");
    _;
  }

  modifier whenAllowlistNotEmpty() {
    require(memberCount != 0, "RetroPhonesAllowlist: Allowlist is empty");
    _;
  }

  // ------------------
  // Functions for the owner
  // ------------------

  function setMaxLength(uint256 _maxLength) external onlyOwner {
      maxLength = _maxLength;
  }

  // ------------------
  // Public write functions
  // ------------------

  function addAddressToAllowlist(address _addr) public whenAllowlistNotFull returns(bool success) {
    if (!allowlist[_addr]) {
      memberCount = memberCount + 1;
      allowlist[_addr] = true;
      AllowlistedAddressAdded(_addr);
      success = true; 
    }
  }

  function addAddressesToAllowlist(address[] calldata _addrs) public returns(bool success) {
    for (uint256 i = 0; i < _addrs.length; i++) {
      if (addAddressToAllowlist(_addrs[i])) {
        success = true;
      }
    }
  }

  function removeAddressFromWhitelist(address _addr) public whenAllowlistNotEmpty returns(bool success) {
    if (allowlist[_addr]) {
      memberCount = memberCount - 1;
      allowlist[_addr] = false;
      AllowlistedAddressRemoved(_addr);
      success = true;
    }
  }

  function removeAddressesFromWhitelist(address[] calldata _addrs) public returns(bool success) {
    for (uint256 i = 0; i < _addrs.length; i++) {
      if (removeAddressFromWhitelist(_addrs[i])) {
        success = true;
      }
    }
  }

  // ------------------
  // Public read functions
  // ------------------

  function isOnAllowlist(address _addr) public view returns(bool) {
    bool isAddressOnAllowlist = allowlist[_addr];
    return isAddressOnAllowlist;
  } 
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