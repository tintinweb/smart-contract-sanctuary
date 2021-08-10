/**
 *Submitted for verification at polygonscan.com on 2021-08-10
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Root file: contracts/infrastructure/Registry.sol

pragma solidity >=0.8.4 <0.9.0;

// import '/home/chiro/gits/infrastructure/node_modules/@openzeppelin/contracts/access/Ownable.sol';

/**
 * DKDAO domain name system
 * Name: Registry
 * Domain: DKDAO Infrastructure
 */
contract Registry is Ownable {
  // Mapping bytes32 -> address
  mapping(bytes32 => mapping(bytes32 => address)) private registered;

  // Mapping address -> bytes32 name
  mapping(address => bytes32) private revertedName;

  // Mapping address -> bytes32 domain
  mapping(address => bytes32) private revertedDomain;

  // Event when new address registered
  event RecordSet(bytes32 domain, bytes32 indexed name, address indexed addr);

  // Set a record
  function set(
    bytes32 domain,
    bytes32 name,
    address addr
  ) external onlyOwner returns (bool) {
    return _set(domain, name, addr);
  }

  // Set many records at once
  function batchSet(
    bytes32[] calldata domains,
    bytes32[] calldata names,
    address[] calldata addrs
  ) external onlyOwner returns (bool) {
    require(
      domains.length == names.length && names.length == addrs.length,
      'Registry: Number of records and addreses must be matched'
    );
    for (uint256 i = 0; i < names.length; i += 1) {
      require(_set(domains[i], names[i], addrs[i]), 'Registry: Unable to set records');
    }
    return true;
  }

  // Check is record existed
  function isExistRecord(bytes32 domain, bytes32 name) external view returns (bool) {
    return registered[domain][name] != address(0);
  }

  // Get address by name
  function getAddress(bytes32 domain, bytes32 name) external view returns (address) {
    return registered[domain][name];
  }

  // Get name by address
  function getDomainAndName(address addr) external view returns (bytes32, bytes32) {
    return (revertedDomain[addr], revertedName[addr]);
  }

  // Set record internally
  function _set(
    bytes32 domain,
    bytes32 name,
    address addr
  ) internal returns (bool) {
    require(addr != address(0), "Registry: We don't allow zero address");
    registered[domain][name] = addr;
    revertedName[addr] = name;
    revertedDomain[addr] = domain;
    emit RecordSet(domain, name, addr);
    return true;
  }
}