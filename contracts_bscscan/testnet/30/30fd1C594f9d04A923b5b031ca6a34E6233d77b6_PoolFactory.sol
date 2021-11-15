// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ========== External Inheritance ========== */
import "@openzeppelin/contracts/access/Ownable.sol";

/* ========== External Interfaces ========== */
import "../interfaces/IDelegateCallProxyManager.sol";

/* ========== External Libraries ========== */
import "../proxies/SaltyLib.sol";

/* ========== Internal Interfaces ========== */
import "../interfaces/IPoolFactory.sol";


/**
 * @title PoolFactory
 * @author d1ll0n
 */
contract PoolFactory is Ownable, IPoolFactory {
/* ==========  Constants  ========== */

  // Address of the proxy manager contract.
  IDelegateCallProxyManager public override immutable proxyManager;

/* ==========  Events  ========== */

  /** @dev Emitted when a pool is deployed. */
  event NewPool(address pool, address controller, bytes32 implementationID);

/* ==========  Storage  ========== */

  mapping(address => bool) public override isApprovedController;
  mapping(address => bytes32) public override getPoolImplementationID;

/* ==========  Modifiers  ========== */

  modifier onlyApproved {
    require(isApprovedController[msg.sender], "ERR_NOT_APPROVED");
    _;
  }

/* ==========  Constructor  ========== */

  constructor(IDelegateCallProxyManager proxyManager_) public Ownable() {
    proxyManager = proxyManager_;
  }

/* ==========  Controller Approval  ========== */

  /** @dev Approves `controller` to deploy pools. */
  function approvePoolController(address controller) external override onlyOwner {
    isApprovedController[controller] = true;
  }

  /** @dev Removes the ability of `controller` to deploy pools. */
  function disapprovePoolController(address controller) external override onlyOwner {
    isApprovedController[controller] = false;
  }

/* ==========  Pool Deployment  ========== */

  /**
   * @dev Deploys a pool using an implementation ID provided by the controller.
   *
   * Note: To support future interfaces, this does not initialize or
   * configure the pool, this must be executed by the controller.
   *
   * Note: Must be called by an approved controller.
   *
   * @param implementationID Implementation ID for the pool
   * @param controllerSalt Create2 salt provided by the deployer
   */
  function deployPool(bytes32 implementationID, bytes32 controllerSalt)
    external
    override
    onlyApproved
    returns (address poolAddress)
  {
    bytes32 suppliedSalt = keccak256(abi.encodePacked(msg.sender, controllerSalt));
    poolAddress = proxyManager.deployProxyManyToOne(implementationID, suppliedSalt);
    getPoolImplementationID[poolAddress] = implementationID;
    emit NewPool(poolAddress, msg.sender, implementationID);
  }

/* ==========  Queries  ========== */

  /**
   * @dev Checks if an address is a pool that was deployed by the factory.
   */
  function isRecognizedPool(address pool) external view override returns (bool) {
    return getPoolImplementationID[pool] != bytes32(0);
  }

  /**
   * @dev Compute the create2 address for a pool deployed by an approved controller.
   */
  function computePoolAddress(bytes32 implementationID, address controller, bytes32 controllerSalt)
    external
    view
    override
    returns (address)
  {
    bytes32 suppliedSalt = keccak256(abi.encodePacked(controller, controllerSalt));
    return SaltyLib.computeProxyAddressManyToOne(
      address(proxyManager),
      address(this),
      implementationID,
      suppliedSalt
    );
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


/**
 * @dev Contract that manages deployment and upgrades of delegatecall proxies.
 *
 * An implementation identifier can be created on the proxy manager which is
 * used to specify the logic address for a particular contract type, and to
 * upgrade the implementation as needed.
 *
 * A one-to-one proxy is a single proxy contract with an upgradeable implementation
 * address.
 *
 * A many-to-one proxy is a single upgradeable implementation address that may be
 * used by many proxy contracts.
 */
interface IDelegateCallProxyManager {
/* ==========  Events  ========== */

  event DeploymentApprovalGranted(address deployer);
  event DeploymentApprovalRevoked(address deployer);

  event ManyToOne_ImplementationCreated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ImplementationUpdated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ProxyDeployed(
    bytes32 implementationID,
    address proxyAddress
  );

  event OneToOne_ProxyDeployed(
    address proxyAddress,
    address implementationAddress
  );

  event OneToOne_ImplementationUpdated(
    address proxyAddress,
    address implementationAddress
  );

/* ==========  Controls  ========== */

  /**
   * @dev Allows `deployer` to deploy many-to-one proxies.
   */
  function approveDeployer(address deployer) external;

  /**
   * @dev Prevents `deployer` from deploying many-to-one proxies.
   */
  function revokeDeployerApproval(address deployer) external;

/* ==========  Implementation Management  ========== */

  /**
   * @dev Creates a many-to-one proxy relationship.
   *
   * Deploys an implementation holder contract which stores the
   * implementation address for many proxies. The implementation
   * address can be updated on the holder to change the runtime
   * code used by all its proxies.
   *
   * @param implementationID ID for the implementation, used to identify the
   * proxies that use it. Also used as the salt in the create2 call when
   * deploying the implementation holder contract.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external;

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationManyToOne(bytes32 implementationID) external;

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationOneToOne(address proxyAddress) external;

  /**
   * @dev Updates the implementation address for a many-to-one
   * proxy relationship.
   *
   * @param implementationID Identifier for the implementation.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external;

  /**
   * @dev Updates the implementation address for a one-to-one proxy.
   *
   * Note: This could work for many-to-one as well if the caller
   * provides the implementation holder address in place of the
   * proxy address, as they use the same access control and update
   * mechanism.
   *
   * @param proxyAddress Address of the deployed proxy
   * @param implementation Address with the runtime code for
   * the proxy to use.
   */
  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external;

/* ==========  Proxy Deployment  ========== */

  /**
   * @dev Deploy a proxy contract with a one-to-one relationship
   * with its implementation.
   *
   * The proxy will have its own implementation address which can
   * be updated by the proxy manager.
   *
   * @param suppliedSalt Salt provided by the account requesting deployment.
   * @param implementation Address of the contract with the runtime
   * code that the proxy should use.
   */
  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  ) external returns(address proxyAddress);

  /**
   * @dev Deploy a proxy with a many-to-one relationship with its implemenation.
   *
   * The proxy will call the implementation holder for every transaction to
   * determine the address to use in calls.
   *
   * @param implementationID Identifier for the proxy's implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external returns(address proxyAddress);

/* ==========  Queries  ========== */

  /**
   * @dev Returns a boolean stating whether `implementationID` is locked.
   */
  function isImplementationLocked(bytes32 implementationID) external view returns (bool);

  /**
   * @dev Returns a boolean stating whether `proxyAddress` is locked.
   */
  function isImplementationLocked(address proxyAddress) external view returns (bool);

  /**
   * @dev Returns a boolean stating whether `deployer` is allowed to deploy many-to-one
   * proxies.
   */
  function isApprovedDeployer(address deployer) external view returns (bool);

  /**
   * @dev Queries the temporary storage value `_implementationHolder`.
   * This is used in the constructor of the many-to-one proxy contract
   * so that the create2 address is static (adding constructor arguments
   * would change the codehash) and the implementation holder can be
   * stored as a constant.
   */
  function getImplementationHolder() external view returns (address);

  /**
   * @dev Returns the address of the implementation holder contract
   * for `implementationID`.
   */
  function getImplementationHolder(bytes32 implementationID) external view returns (address);

  /**
   * @dev Computes the create2 address for a one-to-one proxy requested
   * by `originator` using `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address originator,
    bytes32 suppliedSalt
  ) external view returns (address);

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` requested by `originator` using
   * `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external view returns (address);

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(bytes32 implementationID) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "./IDelegateCallProxyManager.sol";


interface IPoolFactory {
/* ========== Events ========== */

  event NewPool(address pool, address controller, bytes32 implementationID);

/* ========== Mutative ========== */

  function approvePoolController(address controller) external;

  function disapprovePoolController(address controller) external;

  function deployPool(bytes32 implementationID, bytes32 controllerSalt) external returns (address);

/* ========== Views ========== */

  function proxyManager() external view returns (IDelegateCallProxyManager);

  function isApprovedController(address) external view returns (bool);

  function getPoolImplementationID(address) external view returns (bytes32);

  function isRecognizedPool(address pool) external view returns (bool);

  function computePoolAddress(
    bytes32 implementationID,
    address controller,
    bytes32 controllerSalt
  ) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
import "./ManyToOneImplementationHolder.sol";
import { DelegateCallProxyManyToOne } from "./DelegateCallProxyManyToOne.sol";
import { DelegateCallProxyOneToOne } from "./DelegateCallProxyOneToOne.sol";


/**
 * @dev Because we use the code hashes of the proxy contracts for proxy address
 * derivation, it is important that other packages have access to the correct
 * values when they import the salt library.
 */
library CodeHashes {
  bytes32 internal constant ONE_TO_ONE_CODEHASH = keccak256(type(DelegateCallProxyOneToOne).creationCode);
  bytes32 internal constant MANY_TO_ONE_CODEHASH = keccak256(type(DelegateCallProxyManyToOne).creationCode);
  bytes32 internal constant IMPLEMENTATION_HOLDER_CODEHASH = keccak256(type(ManyToOneImplementationHolder).creationCode);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @dev Proxy contract which uses an implementation address shared with many
 * other proxies.
 *
 * An implementation holder contract stores the upgradeable implementation address.
 * When the proxy is called, it queries the implementation address from the holder
 * contract and delegatecalls the returned address, forwarding the received calldata
 * and ether.
 *
 * Note: This contract does not verify that the implementation
 * address is a valid delegation target. The manager must perform
 * this safety check before updating the implementation on the holder.
 */
contract DelegateCallProxyManyToOne is Proxy {
/* ==========  Constants  ========== */

  // Address that stores the implementation address.
  address internal immutable _implementationHolder;

/* ==========  Constructor  ========== */

  constructor() public {
    // Calls the sender rather than receiving the address in the constructor
    // arguments so that the address is computable using create2.
    _implementationHolder = ProxyDeployer(msg.sender).getImplementationHolder();
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Queries the implementation address from the implementation holder.
   */
  function _implementation() internal override view returns (address) {
    // Queries the implementation address from the implementation holder.
    (bool success, bytes memory data) = _implementationHolder.staticcall("");
    require(success, string(data));
    address implementation = abi.decode((data), (address));
    require(implementation != address(0), "ERR_NULL_IMPLEMENTATION");
    return implementation;
  }
}

interface ProxyDeployer {
  function getImplementationHolder() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @dev Upgradeable delegatecall proxy for a single contract.
 *
 * This proxy stores an implementation address which can be upgraded by the proxy manager.
 *
 * To upgrade the implementation, the manager calls the proxy with the abi encoded implementation address.
 *
 * If any other account calls the proxy, it will delegatecall the implementation address with the received
 * calldata and ether. If the call succeeds, it will return with the received returndata.
 * If it reverts, it will revert with the received revert data.
 *
 * Note: The storage slot for the implementation address is:
 * `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`
 * This slot must not be used by the implementation contract.
 *
 * Note: This contract does not verify that the implementation address is a valid delegation target.
 * The manager must perform this safety check.
 */
contract DelegateCallProxyOneToOne is Proxy {
/* ==========  Constants  ========== */
  address internal immutable _manager;

/* ==========  Constructor  ========== */
  constructor() public {
    _manager = msg.sender ;
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Reads the implementation address from storage.
   */
  function _implementation() internal override view returns (address) {
    address implementation;
    assembly {
      implementation := sload(
        // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
        0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a
      )
    }
    return implementation;
  }

  /**
    * @dev Hook that is called before falling back to the implementation.
    *
    * Checks if the call is from the owner.
    * If it is, reads the abi-encoded implementation address from calldata and stores
    * it at the slot `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`,
    * then returns with no data.
    * If it is not, continues execution with the fallback function.
    */
  function _beforeFallback() internal override {
    if (msg.sender != _manager) {
      super._beforeFallback();
    } else {
      assembly {
        sstore(
          // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
          0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a,
          calldataload(0)
        )
        return(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


/**
 * @dev The ManyToOneImplementationHolder stores an upgradeable implementation address
 * in storage, which many-to-one proxies query at execution time to determine which
 * contract to delegate to.
 *
 * The manager can upgrade the implementation address by calling the holder with the
 * abi-encoded address as calldata. If any other account calls the implementation holder,
 * it will return the implementation address.
 *
 * This pattern was inspired by the DharmaUpgradeBeacon from 0age
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/upgradeability/smart-wallet/DharmaUpgradeBeacon.sol
 */
contract ManyToOneImplementationHolder {
/* ---  Storage  --- */
  address internal immutable _manager;
  address internal _implementation;

/* ---  Constructor  --- */
  constructor() public {
    _manager = msg.sender;
  }

  /**
   * @dev Fallback function for the contract.
   *
   * Used by proxies to read the implementation address and used
   * by the proxy manager to set the implementation address.
   *
   * If called by the owner, reads the implementation address from
   * calldata (must be abi-encoded) and stores it to the first slot.
   *
   * Otherwise, returns the stored implementation address.
   */
  fallback() external payable {
    if (msg.sender != _manager) {
      assembly {
        mstore(0, sload(0))
        return(0, 32)
      }
    }
    assembly { sstore(0, calldataload(0)) }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ---  External Libraries  --- */
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

/* ---  Proxy Contracts  --- */
import { CodeHashes } from "./CodeHashes.sol";


/**
 * @dev Library for computing create2 salts and addresses for proxies
 * deployed by `DelegateCallProxyManager`.
 *
 * Because the proxy factory is meant to be used by multiple contracts,
 * we use a salt derivation pattern that includes the address of the
 * contract that requested the proxy deployment, a salt provided by that
 * contract and the implementation ID used (for many-to-one proxies only).
 */
library SaltyLib {
/* ---  Salt Derivation  --- */

  /**
   * @dev Derives the create2 salt for a many-to-one proxy.
   *
   * Many different contracts in the Bishares framework may use the
   * same implementation contract, and they all use the same init
   * code, so we derive the actual create2 salt from a combination
   * of the implementation ID, the address of the account requesting
   * deployment and the user-supplied salt.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deriveManyToOneSalt(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        originator,
        implementationID,
        suppliedSalt
      )
    );
  }

  /**
   * @dev Derives the create2 salt for a one-to-one proxy.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deriveOneToOneSalt(
    address originator,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(originator, suppliedSalt));
  }

/* ---  Address Derivation  --- */

  /**
   * @dev Computes the create2 address for a one-to-one proxy deployed
   * by `deployer` (the factory) when requested by `originator` using
   * `suppliedSalt`.
   *
   * @param deployer Address of the proxy factory.
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address deployer,
    address originator,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (address)
  {
    bytes32 salt = deriveOneToOneSalt(originator, suppliedSalt);
    return Create2.computeAddress(salt, CodeHashes.ONE_TO_ONE_CODEHASH, deployer);
  }

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` deployed by `deployer` (the factory)
   * when requested by `originator` using `suppliedSalt`.
   *
   * @param deployer Address of the proxy factory.
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address deployer,
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (address)
  {
    bytes32 salt = deriveManyToOneSalt(
      originator,
      implementationID,
      suppliedSalt
    );
    return Create2.computeAddress(salt, CodeHashes.MANY_TO_ONE_CODEHASH, deployer);
  }

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param deployer Address of the proxy factory.
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(
    address deployer,
    bytes32 implementationID
  )
    internal
    pure
    returns (address)
  {
    return Create2.computeAddress(
      implementationID,
      CodeHashes.IMPLEMENTATION_HOLDER_CODEHASH,
      deployer
    );
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
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

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

