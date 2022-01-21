// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../zone/Interface.sol";

contract BaseRegistrar {
  event AuthorizedOperator(address indexed operator, address indexed zone);
  event RevokedOperator(address indexed operator, address indexed zone);

  mapping (address => mapping (address => bool)) private _operators;

  constructor() {}

  function isOperatorFor(
    address operator,
    address zone
  ) public view virtual returns (bool) {
    return _operators[zone][operator];
  }

  function authorizeOperator(
    address zone,
    address operator
  ) public virtual {
    require(msg.sender == Ownable(zone).owner(), "unauthorized");
    _operators[zone][operator] = true;
    emit AuthorizedOperator(operator, zone);
  }

  function revokeOperator(
    address zone,
    address operator
  ) public virtual {
    require(msg.sender == Ownable(zone).owner(), "unauthorized");
    delete _operators[zone][operator];
    emit RevokedOperator(operator, zone);
  }

  function register(
    address to,
    address zone,
    string memory label
  ) public virtual {
    require(isOperatorFor(msg.sender, zone), "unauthorized");
    bytes32 origin = ZoneInterface(zone).getOrigin();
    ZoneInterface(zone).register(to, origin, label);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ZoneInterface {
  event ZoneCreated(bytes32 indexed origin, string name, string symbol);
  event ResourceRegistered(bytes32 indexed parent, string label);

  event RecordSet(
    bytes32 indexed resource,
    string indexed label,
    uint16 rrt,
    uint32 ttl,
    bytes32 data
  );

  event RecordLocked(
    bytes32 indexed resource,
    string indexed label,
    uint256 unlocks
  );

  function getOrigin() external view returns (bytes32);

  function owner() external view returns (address);
  function exists(bytes32 namehash) external view returns (bool);

  function register(
    address to,
    bytes32 parent,
    string memory label
  ) external returns (bytes32 namehash);

  function setRecord(
    bytes32 resource,
    string calldata label,
    uint16 rrt,
    uint32 ttl,
    bytes32 data
  ) external returns (bytes32 key);

  function getRecord(bytes32 resource, string calldata label) external view returns (
    uint16 rrt,
    uint32 ttl,
    bytes32 data
  );

  function setLock(
    bytes32 resource,
    string calldata label,
    uint32 time
  ) external returns (uint256 unlocks);

  function getLock(bytes32 resource, string calldata label) external view returns (uint256 unlocks);
}