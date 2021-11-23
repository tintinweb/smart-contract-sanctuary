// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDelegateCallProxyManager.sol";
import "../interfaces/IPoolFactory.sol";
import "../proxies/SaltyLib.sol";


contract PoolFactory is Ownable, IPoolFactory {
  IDelegateCallProxyManager public override immutable proxyManager;
  mapping(address => bool) public override isApprovedController;
  mapping(address => bytes32) public override getPoolImplementationID;

  function isRecognizedPool(address pool) external view override returns (bool) {
    return getPoolImplementationID[pool] != bytes32(0);
  }

  function computePoolAddress(
    bytes32 implementationID,
    address controller,
    bytes32 controllerSalt
  ) external view override returns (address) {
    bytes32 suppliedSalt = keccak256(abi.encodePacked(controller, controllerSalt));
    return SaltyLib.computeProxyAddressManyToOne(
      address(proxyManager),
      address(this),
      implementationID,
      suppliedSalt
    );
  }

  event NewPool(address pool, address controller, bytes32 implementationID);

  constructor(IDelegateCallProxyManager proxyManager_) Ownable() {
    require(address(proxyManager_) != address(0), "BiShares: Proxy manager is zero address");
    proxyManager = proxyManager_;
  }

  function approvePoolController(address controller) external override onlyOwner returns (bool) {
    isApprovedController[controller] = true;
    return true;
  }

  function disapprovePoolController(address controller) external override onlyOwner returns (bool) {
    isApprovedController[controller] = false;
    return true;
  }

  function deployPool(
    bytes32 implementationID,
    bytes32 controllerSalt
  ) external override onlyApproved returns (address poolAddress) {
    address caller = msg.sender;
    bytes32 suppliedSalt = keccak256(abi.encodePacked(caller, controllerSalt));
    poolAddress = proxyManager.deployProxyManyToOne(implementationID, suppliedSalt);
    getPoolImplementationID[poolAddress] = implementationID;
    emit NewPool(poolAddress, caller, implementationID);
  }

  modifier onlyApproved {
    require(isApprovedController[msg.sender], "ERR_NOT_APPROVED");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./CodeHashes.sol";


library SaltyLib {

  function deriveManyToOneSalt(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) internal pure returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        originator,
        implementationID,
        suppliedSalt
      )
    );
  }

  function deriveOneToOneSalt(
    address originator,
    bytes32 suppliedSalt
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(originator, suppliedSalt));
  }

  function computeProxyAddressOneToOne(
    address deployer,
    address originator,
    bytes32 suppliedSalt
  ) internal pure returns (address) {
    bytes32 salt = deriveOneToOneSalt(originator, suppliedSalt);
    return Create2.computeAddress(salt, CodeHashes.ONE_TO_ONE_CODEHASH, deployer);
  }

  function computeProxyAddressManyToOne(
    address deployer,
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) internal pure returns (address) {
    bytes32 salt = deriveManyToOneSalt(
      originator,
      implementationID,
      suppliedSalt
    );
    return Create2.computeAddress(salt, CodeHashes.MANY_TO_ONE_CODEHASH, deployer);
  }

  function computeHolderAddressManyToOne(
    address deployer,
    bytes32 implementationID
  ) internal pure returns (address) {
    return Create2.computeAddress(
      implementationID,
      CodeHashes.IMPLEMENTATION_HOLDER_CODEHASH,
      deployer
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


contract ManyToOneImplementationHolder {
  address internal immutable _manager;
  address internal _implementation;

  constructor() {
    _manager = msg.sender;
  }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/proxy/Proxy.sol";


contract DelegateCallProxyOneToOne is Proxy {
  address internal immutable _manager;

  constructor() {
    _manager = msg.sender ;
  }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/proxy/Proxy.sol";


interface ProxyDeployer {
  function getImplementationHolder() external view returns (address);
}


contract DelegateCallProxyManyToOne is Proxy {
  address internal immutable _implementationHolder;

  constructor() {
    _implementationHolder = ProxyDeployer(msg.sender).getImplementationHolder();
  }

  function _implementation() internal override view returns (address) {
    (bool success, bytes memory data) = _implementationHolder.staticcall("");
    require(success, string(data));
    address implementation = abi.decode((data), (address));
    require(implementation != address(0), "ERR_NULL_IMPLEMENTATION");
    return implementation;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./ManyToOneImplementationHolder.sol";
import "./DelegateCallProxyManyToOne.sol";
import "./DelegateCallProxyOneToOne.sol";


library CodeHashes {
  bytes32 internal constant ONE_TO_ONE_CODEHASH = keccak256(
    type(DelegateCallProxyOneToOne).creationCode
  );
  bytes32 internal constant MANY_TO_ONE_CODEHASH = keccak256(
    type(DelegateCallProxyManyToOne).creationCode
  );
  bytes32 internal constant IMPLEMENTATION_HOLDER_CODEHASH = keccak256(
    type(ManyToOneImplementationHolder).creationCode
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./IDelegateCallProxyManager.sol";


interface IPoolFactory {
  function approvePoolController(address controller) external returns (bool);
  function disapprovePoolController(address controller) external returns (bool);
  function deployPool(bytes32 implementationID, bytes32 controllerSalt) external returns (address);

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