// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


interface IPoolFactoryAccessControl {
/* ==========  Events  ========== */

  event AdminAccessGranted(address newAdmin);
  event AdminAccessRevoked(address newAdmin);

/* ==========  Queries  ========== */

  function poolFactory() external view returns (address);

  function hasAdminAccess(address) external view returns (bool);

/* ==========  Owner Controls  ========== */

  function grantAdminAccess(address admin) external;

  function revokeAdminAccess(address admin) external;

  function transferPoolFactoryOwnership(address) external;

  function disapprovePoolController(address) external;

/* ==========  Admin Controls  ========== */

  function approvePoolController(address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ========== External Inheritance ========== */
import "@openzeppelin/contracts/access/Ownable.sol";

/* ========== Internal Interfaces ========== */
import "./interfaces/IPoolFactoryAccessControl.sol";


contract PoolFactoryAccessControl is IPoolFactoryAccessControl, Ownable {
/* ==========  Constants  ========== */

  address public immutable override poolFactory;

/* ==========  Storage  ========== */

  mapping(address => bool) public override hasAdminAccess;

/* ==========  Modifiers  ========== */

  modifier onlyAdminOrOwner {
    require(
      hasAdminAccess[msg.sender] || msg.sender == owner(),
      "ERR_NOT_ADMIN_OR_OWNER"
    );
    _;
  }

/* ==========  Constructor  ========== */

  constructor(address poolFactory_) public Ownable() {
    poolFactory = poolFactory_;
  }

/* ==========  Owner Controls  ========== */

  /**
   * @dev Transfer ownership of the pool factory to another account.
   */
  function transferPoolFactoryOwnership(address newOwner) external override onlyOwner {
    Ownable(poolFactory).transferOwnership(newOwner);
  }

  /**
   * @dev Grants admin access to `admin`.
   */
  function grantAdminAccess(address admin) external override onlyOwner {
    hasAdminAccess[admin] = true;
    emit AdminAccessGranted(admin);
  }

  /**
   * @dev Revokes admin access from `admin`.
   */
  function revokeAdminAccess(address admin) external override onlyOwner {
    hasAdminAccess[admin] = false;
    emit AdminAccessRevoked(admin);
  }

  /** @dev Removes the ability of `controller` to deploy pools. */
  function disapprovePoolController(address controller) external override onlyOwner {
    IPoolFactory(poolFactory).disapprovePoolController(controller);
  }

/* ==========  Admin Controls  ========== */

  /** @dev Approves `controller` to deploy pools. */
  function approvePoolController(address controller) external override onlyAdminOrOwner {
    IPoolFactory(poolFactory).approvePoolController(controller);
  }
}


interface IPoolFactory {
  function approvePoolController(address controller) external;

  function disapprovePoolController(address controller) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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