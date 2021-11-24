// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ManyToOneImplementationHolder.sol";
import "./DelegateCallProxyManyToOne.sol";
import "./DelegateCallProxyOneToOne.sol";
import "./SaltyLib.sol";
import "./CodeHashes.sol";
import "../interfaces/IDelegateCallProxyManager.sol";


contract DelegateCallProxyManager is Ownable, IDelegateCallProxyManager {
  mapping(address => bool) internal _approvedDeployers;
  mapping(bytes32 => address) internal _implementationHolders;
  mapping(address => bool) internal _lockedImplementations;
  address internal _implementationHolder;

  function isImplementationLocked(bytes32 implementationID) external override view returns (bool) {
    address implementationHolder = _implementationHolders[implementationID];
    require(implementationHolder != address(0), "BiShares: Invalid implementation id");
    return _lockedImplementations[implementationHolder];
  }

  function isImplementationLocked(address proxyAddress) external override view returns (bool) {
    return _lockedImplementations[proxyAddress];
  }

  function isApprovedDeployer(address deployer) external override view returns (bool) {
    return _approvedDeployers[deployer];
  }

  function getImplementationHolder() external override view returns (address) {
    return _implementationHolder;
  }

  function getImplementationHolder(bytes32 implementationID) external override view returns (address) {
    return _implementationHolders[implementationID];
  }

  function computeProxyAddressOneToOne(
    address originator,
    bytes32 suppliedSalt
  ) external override view returns (address) {
    bytes32 salt = SaltyLib.deriveOneToOneSalt(originator, suppliedSalt);
    return Create2.computeAddress(salt, CodeHashes.ONE_TO_ONE_CODEHASH);
  }

  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external override view returns (address) {
    bytes32 salt = SaltyLib.deriveManyToOneSalt(
      originator,
      implementationID,
      suppliedSalt
    );
    return Create2.computeAddress(salt, CodeHashes.MANY_TO_ONE_CODEHASH);
  }

  function computeHolderAddressManyToOne(
    bytes32 implementationID
  ) public override view returns (address) {
    return Create2.computeAddress(
      implementationID,
      CodeHashes.IMPLEMENTATION_HOLDER_CODEHASH
    );
  }

  event DeploymentApprovalGranted(address deployer);
  event DeploymentApprovalRevoked(address deployer);
  event ManyToOne_ImplementationCreated(bytes32 implementationID, address implementationAddress);
  event ManyToOne_ImplementationUpdated(bytes32 implementationID, address implementationAddress);
  event ManyToOne_ImplementationLocked(bytes32 implementationID);
  event ManyToOne_ProxyDeployed(bytes32 implementationID, address proxyAddress);
  event OneToOne_ProxyDeployed(address proxyAddress, address implementationAddress);
  event OneToOne_ImplementationUpdated(address proxyAddress, address implementationAddress);
  event OneToOne_ImplementationLocked(address proxyAddress);

  constructor() Ownable() {}

  function approveDeployer(address deployer) external override onlyOwner returns (bool) {
    _approvedDeployers[deployer] = true;
    emit DeploymentApprovalGranted(deployer);
    return true;
  }

  function revokeDeployerApproval(address deployer) external override onlyOwner returns (bool) {
    _approvedDeployers[deployer] = false;
    emit DeploymentApprovalRevoked(deployer);
    return true;
  }

  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external override onlyOwner returns (bool) {
    address implementationHolder = Create2.deploy(
      0,
      implementationID,
      type(ManyToOneImplementationHolder).creationCode
    );
    _implementationHolders[implementationID] = implementationHolder;
    _setImplementation(implementationHolder, implementation);
    emit ManyToOne_ImplementationCreated(
      implementationID,
      implementation
    );
    return true;
  }

  function lockImplementationManyToOne(bytes32 implementationID) external override onlyOwner returns (bool) {
    address implementationHolder = _implementationHolders[implementationID];
    require(implementationHolder != address(0), "BiShares: Invalid implementation id");
    _lockedImplementations[implementationHolder] = true;
    emit ManyToOne_ImplementationLocked(implementationID);
    return true;
  }

  function lockImplementationOneToOne(address proxyAddress) external override onlyOwner returns (bool) {
    _lockedImplementations[proxyAddress] = true;
    emit OneToOne_ImplementationLocked(proxyAddress);
    return true;
  }

  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external override onlyOwner returns (bool) {
    address implementationHolder = _implementationHolders[implementationID];
    require(implementationHolder != address(0), "BiShares: Invalid implementation id");
    require(!_lockedImplementations[implementationHolder], "BiShares: Implementation is locked");
    _setImplementation(implementationHolder, implementation);
    emit ManyToOne_ImplementationUpdated(
      implementationID,
      implementation
    );
    return true;
  }

  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external override onlyOwner returns (bool) {
    require(!_lockedImplementations[proxyAddress], "BiShares: Implementation is locked");
    _setImplementation(proxyAddress, implementation);
    emit OneToOne_ImplementationUpdated(proxyAddress, implementation);
    return true;
  }

  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  ) external override onlyOwner returns(address proxyAddress) {
    bytes32 salt = SaltyLib.deriveOneToOneSalt(_msgSender(), suppliedSalt);
    proxyAddress = Create2.deploy(
      0,
      salt,
      type(DelegateCallProxyOneToOne).creationCode
    );
    _setImplementation(proxyAddress, implementation);
    emit OneToOne_ProxyDeployed(proxyAddress, implementation);
  }

  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external override onlyApprovedDeployer returns(address proxyAddress) {
    address zero = address(0);
    address implementationHolder = _implementationHolders[implementationID];
    require(implementationHolder != zero, "BiShares: Invalid implementation id");
    bytes32 salt = SaltyLib.deriveManyToOneSalt(
      _msgSender(),
      implementationID,
      suppliedSalt
    );
    _implementationHolder = implementationHolder;
    proxyAddress = Create2.deploy(
      0,
      salt,
      type(DelegateCallProxyManyToOne).creationCode
    );
    _implementationHolder = zero;
    emit ManyToOne_ProxyDeployed(
      implementationID,
      proxyAddress
    );
  }

  function _setImplementation(
    address proxyOrHolder,
    address implementation
  ) internal {
    require(Address.isContract(implementation), "BiShares: Implementation is not contract");
    // solium-disable-next-line security/no-low-level-calls
    (bool success,) = proxyOrHolder.call(abi.encode(implementation));
    require(success, "BiShares: Address setting fail");
  }

  modifier onlyApprovedDeployer {
    address sender = _msgSender();
    require(_approvedDeployers[sender] || sender == owner(), "BiShares: Deployer no approved");
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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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