// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IProxyManagerAccessControl.sol";
import "../interfaces/IDelegateCallProxyManager.sol";


contract ProxyManagerAccessControl is IProxyManagerAccessControl, Ownable {
  mapping (address => bool) public override hasAdminAccess;
  address public immutable override proxyManager;

  constructor(address proxyManager_) Ownable() {
    proxyManager = proxyManager_;
  }

  function approveDeployer(address deployer) external override onlyAdminOrOwner returns (bool) {
    return IDelegateCallProxyManager(proxyManager).approveDeployer(deployer);
  }

  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external override onlyAdminOrOwner returns (bool) {
    return IDelegateCallProxyManager(proxyManager).createManyToOneProxyRelationship(
      implementationID,
      implementation
    );
  }

  function grantAdminAccess(address admin) external override onlyOwner returns (bool) {
    hasAdminAccess[admin] = true;
    emit AdminAccessGranted(admin);
    return true;
  }

  function revokeAdminAccess(address admin) external override onlyOwner returns (bool) {
    hasAdminAccess[admin] = false;
    emit AdminAccessRevoked(admin);
    return true;
  }

  function revokeDeployerApproval(address deployer) external override onlyOwner returns (bool) {
    return IDelegateCallProxyManager(proxyManager).revokeDeployerApproval(deployer);
  }

  function lockImplementationManyToOne(
    bytes32 implementationID
  ) external override onlyOwner returns (bool) {
    return IDelegateCallProxyManager(proxyManager).lockImplementationManyToOne(implementationID);
  }

  function lockImplementationOneToOne(
    address proxyAddress
  ) external override onlyOwner returns (bool) {
    return IDelegateCallProxyManager(proxyManager).lockImplementationOneToOne(proxyAddress);
  }

  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external override onlyOwner returns (bool) {
    return IDelegateCallProxyManager(proxyManager).setImplementationAddressManyToOne(
      implementationID,
      implementation
    );
  }

  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external override onlyOwner returns (bool) {
    return IDelegateCallProxyManager(proxyManager).setImplementationAddressOneToOne(
      proxyAddress,
      implementation
    );
  }

  function transferManagerOwnership(address newOwner) external override onlyOwner returns (bool) {
    Ownable(proxyManager).transferOwnership(newOwner);
    return true;
  }

  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  ) external override onlyAdminOrOwner returns(address) {
    return IDelegateCallProxyManager(proxyManager).deployProxyOneToOne(
      suppliedSalt,
      implementation
    );
  }

  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external override onlyAdminOrOwner returns(address) {
    return IDelegateCallProxyManager(proxyManager).deployProxyManyToOne(
      implementationID,
      suppliedSalt
    );
  }

  modifier onlyAdminOrOwner {
    address caller = msg.sender;
    require(
      hasAdminAccess[caller] || caller == owner(),
      "BiShares: Caller is not admin or owner"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IProxyManagerAccessControl {
  function hasAdminAccess(address account) external view returns (bool);
  function proxyManager() external view returns (address);

  event AdminAccessGranted(address newAdmin);
  event AdminAccessRevoked(address newAdmin);

  function approveDeployer(address deployer) external returns (bool);
  function revokeDeployerApproval(address deployer) external returns (bool);
  function grantAdminAccess(address admin) external returns (bool);
  function revokeAdminAccess(address admin) external returns (bool);
  function transferManagerOwnership(address newOwner) external returns (bool);
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external returns (bool);
  function lockImplementationManyToOne(bytes32 implementationID) external returns (bool);
  function lockImplementationOneToOne(address proxyAddress) external returns (bool);
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external returns (bool);
  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external returns (bool);
  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  ) external returns(address proxyAddress);
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external returns(address proxyAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IDelegateCallProxyManager {
  function isImplementationLocked(bytes32 implementationID) external view returns (bool);
  function isImplementationLocked(address proxyAddress) external view returns (bool);
  function isApprovedDeployer(address deployer) external view returns (bool);
  function getImplementationHolder() external view returns (address);
  function getImplementationHolder(bytes32 implementationID) external view returns (address);
  function computeProxyAddressOneToOne(address originator, bytes32 suppliedSalt) external view returns (address);
  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external view returns (address);
  function computeHolderAddressManyToOne(bytes32 implementationID) external view returns (address);

  function approveDeployer(address deployer) external returns (bool);
  function revokeDeployerApproval(address deployer) external returns (bool);
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external returns (bool);
  function lockImplementationManyToOne(bytes32 implementationID) external returns (bool);
  function lockImplementationOneToOne(address proxyAddress) external returns (bool);
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external returns (bool);
  function setImplementationAddressOneToOne(address proxyAddress, address implementation) external returns (bool);
  function deployProxyOneToOne(bytes32 suppliedSalt, address implementation) external returns(address proxyAddress);
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external returns(address proxyAddress);
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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