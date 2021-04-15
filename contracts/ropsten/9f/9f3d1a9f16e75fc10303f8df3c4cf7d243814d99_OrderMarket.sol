/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Create2.sol



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
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address payable) {
        address payable addr;
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
        return address(uint256(_data));
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



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

// File: @openzeppelin/contracts/proxy/Initializable.sol



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/proxy/Proxy.sol



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
    function _delegate(address implementation) internal {
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
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable {
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

// File: contracts/proxy/BaseUpgradeabilityProxy.sol

//  
pragma solidity ^0.7.3;



/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 * 
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract BaseUpgradeabilityProxy is Proxy {

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal override view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * 
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) internal {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// File: contracts/proxy/BaseAdminUpgradeabilityProxy.sol

//  
pragma solidity ^0.7.3;


/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }
}

// File: contracts/proxy/InitializableAdminUpgradeabilityProxy.sol

//  
pragma solidity ^0.7.3;


/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));

    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }

    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

// File: contracts/src/ZoomString.sol

//  

pragma solidity ^0.7.3;

/**
 * @title ZoomString
 */
library ZoomString {
    
  // string helper
  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  // string helper
  function uintToString(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (_i != 0) {
      bstr[k--] = byte(uint8(48 + _i % 10));
      _i /= 10;
    }
    return string(bstr);
  }
}

// File: contracts/interfaces/IERC20.sol

//  
pragma solidity ^0.7.3;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// File: contracts/src/SafeERC20.sol

//  

pragma solidity ^0.7.3;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interfaces/IOwnable.sol

//  
pragma solidity ^0.7.3;


/**
 * @title Interface of Ownable
 */
interface IOwnable {
    function owner() external view returns (address);
}

// File: contracts/src/Ownable.sol

//  
pragma solidity ^0.7.3;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author bit-zoom
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;
    address private _newOwner;

    event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferCompleted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev ZOOM: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferCompleted(address(0), _owner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferInitiated(_owner, newOwner);
        _newOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function claimOwnership() public virtual {
        require(_newOwner == msg.sender, "Ownable: caller is not the owner");
        emit OwnershipTransferCompleted(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// File: contracts/interfaces/IZoom.sol

//  
pragma solidity ^0.7.3;


/**
 * @dev IZoom contract interface. See {IZoom}.
 * @author bit-zoom
 */
interface IZoom {

  //the params about the fee for zoom option
  function baseFeeNumerator() external view returns (uint256 _baseFeeNumerator);
  function optionFeeNumerator() external view returns (uint256 _optionFeeNumerator);
  function optionFeeDenominator() external view returns (uint256 _optionFeeDenominator);
  function orderFinishDelay() external view returns (uint256 _orderFinishDelay );

  //contract implementation
  function zoomERC20Implementation() external view returns (address _zoomERC20Implementation);
  function optionImplementation() external view returns (address _optionImplementation);

  function rewardPool() external view returns (address _rewardPool);
  function optionFactory() external view returns (address _optionFactory);
  function governance() external view returns (address _governance);
  function orderMarket() external view returns (address _orderMarket);

  //check the address is in the whitelist, it works when the enableWhiteListFn sets with true
  function isInWhiteList( address _user ) external view returns (bool);

  //return contract address, the contract may not be deployed yet
  function getOptionAddress(bytes32 _optionName, uint256 _expirationTimestamp, address _targetToken, uint256 _optionNonce) external view returns (address);
  //return contract address, the contract may not be deployed yet
  function getZoomTokenAddress(bytes32 _optionName, uint256 _expirationTimestamp, address _targetToken, uint256 _optionNonce, bool _isOptionToken) external view returns (address);
  
  //access restriction - owner (dev)
  //start zoom 
  function startZoom() external;
  //update this will only affect contracts deployed after
  function updateOptionImplementation(address _newImplementation) external returns (bool);
  //update this will only affect contracts deployed after
  function updateZoomERC20Implementation(address _newImplementation) external returns (bool);
 
  //access restriction - governance
  function updateRewardPool(address _address) external returns (bool);
  function updateOptionFactory(address _address) external returns (bool);
  function updateOrderMarket(address _address) external returns (bool);

  function updateFees(uint256 _baseFeeNumerator,uint256 _optionFeeNumerator, uint256 _optionFeeDenominator) external returns (bool);
  function updateOrderFinishDelay( uint256 _delaySeconds ) external returns (bool);
  function updateGovernance(address _address) external returns (bool);
  function setWhiteList( address _user, bool _openTag ) external;
  function enableWhiteListFn( bool _enable ) external;
}

// File: contracts/interfaces/IOption.sol

//  
pragma solidity ^0.7.3;

pragma experimental ABIEncoderV2;

/**
 * @dev Option contract interface. See {Option}.
 * @author bit-zoom
 */
interface IOption {

  struct OptionDetails {
        string name;
        address baseToken;
        address targetToken;
        address optionToken;
        address proofToken;
        uint256 baseAmount;
        uint256 targetAmout;
        uint256 totalSupply;
        uint64 expirationTimestamp;
        uint64 expirationDelay;    
        uint64 optionNonce;
    }

  function getOptionDetails()
    external view returns (
        string memory _name,
        address _baseToken,
        address _targetToken,
        address _optionToken,
        address _proofToken,
        uint256 _baseAmount,   
        uint256 _targetAmout,  
        uint256 _totalSupply,
        uint64 _expirationTimestamp,
        uint64 _expirationDelay,
        uint64 _optionNonce
    );

  function getOptionDetailsEx()
    external view 
    returns (IOption.OptionDetails memory _option);

  function subscribeOption( uint256 _amount ) external;
  function unsubscribeOption( uint256 _amount ) external;
  function subscribeOptionByContract(uint256 _amount ) external returns ( uint256 _mintAmount );
  function unsubscribeOptionByContract(uint256 _amount ) external returns ( uint256 _burnAmount );
  function excuteOption( uint256 _amount ) external;
  function collectOption( uint256 _amount ) external;
 
  //valid the status
  function validStatus() external view;

}

// File: contracts/interfaces/IZoomERC20.sol

//  
pragma solidity ^0.7.3;


/**
 * @title ZoomERC20 contract interface, implements {IERC20}. See {ZoomERC20}.
 * @author bit-zoom
 */
interface IZoomERC20 is IERC20 {
    function burn(uint256 _amount) external returns (bool);

    /// @notice access restriction - owner (Zoom)
    function mint(address _account, uint256 _amount) external returns (bool);
    function setSymbol(string calldata _symbol) external returns (bool);
    function burnByZoom(address _account, uint256 _amount) external returns (bool);
}

// File: contracts/interfaces/IOrderMarket.sol

//  
pragma solidity ^0.7.3;


// pragma experimental ABIEncoderV2;

/**
 * @dev IOrderMarket contract interface. See {OrderMarket}.
 * @author bit-zoom
 */
interface IOrderMarket {


  struct OrderDetails {
        string name;
        address optionAddress;
        uint256 orderId;
        address marketMaker;
        uint256 price;
        uint256 amount;
        uint256 acceptableUserNonce;
        uint256 finishTimeStamp;
        uint256 userNonce;
        uint256 commitAmount;
    }

  struct UserDetails {
        uint256 orderId;
        address user;
        uint256 index;
        uint256 price;
        uint256 amount;
        uint256 commitTimeStamp;
        uint256 acceptTimeStamp;
        uint256 commitAmount;
    }

  
  function orderNonce() external view  returns (uint256 _orderNonce) ;
  function zoom() external view  returns (address _zoom) ;

  function getOrderDetails(uint256 _orderId)
    external view returns (
        string memory _name,
        address _optionAddress,
        address _marketMaker,
        uint256 _price,
        uint256 _amount,
        uint256 _acceptableUserNonce,
        uint256 _finishTimeStamp,
        uint256 _userNonce,
        uint256 _commitAmount
    );

  function getOrderDetailsEx(uint256 _orderId)
    external view 
    returns (IOrderMarket.OrderDetails memory _order);


  function getUserDetails( uint256 _orderId, uint256 _userNonce )
    external view returns (
        address _user,
        uint256 _index,
        uint256 _price,
        uint256 _amount,
        uint256 _commitTimeStamp,
        uint256 _acceptTimeStamp,
        uint256 _commitAmount
    );

  function getUserDetailsEx(uint256 _orderId, uint256 _userNonce )
    external view 
    returns (IOrderMarket.UserDetails memory _order);


  //for market maker
  function createOrder(address _optionAddress,uint256 _price, uint256 _amount ) external;
  function addOrder( uint256 _orderId, uint256 _amount ) external;
  function finishOrder( uint256 _orderId, uint256 _acceptableUserNonce ) external;
 
  //for user
  function subscribeOrder(uint256 _orderId, uint256 _amount ) external;
  function acceptOrder(uint256 _orderId, uint256 _userNonce )  external;
  function unsubscribeOrder( uint256 _orderId, uint256 _userNonce ) external;
 
  //valid the status
  function validStatus(uint256 _orderId) external view;

  function getMarketMakerOrders( address _marketMaker ) external view  returns (uint256[] memory) ;
  function getUserOrders( address _user ) external view  returns (uint256[] memory ) ;
  function getUserOrderIndexs( address _user, uint256 _orderId ) external view  returns (uint256[] memory ) ;
  
  //access restriction - dev
  //when start the zoom or update the option factory by calling hookZoom to make the factory contract work normal 
  function hookZoom(address _zoom) external  returns (bool);
  
}

// File: contracts/src/OrderMarket.sol

//  
pragma solidity ^0.7.3;

// pragma experimental ABIEncoderV2;















/**
 * @title OrderMarket contract
 * @author bit-zoom
 */
contract OrderMarket is IOrderMarket, Initializable, ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  mapping(uint256 => IOrderMarket.OrderDetails) public orderDetails;
  mapping(uint256 => mapping(uint256 => IOrderMarket.UserDetails)) public orderIndexDetails; //
  
  mapping(address => uint256[]) public marketMakerAddressToOrders;
  mapping(address => mapping(uint256 => uint256[])) public userAddressToOrderIndexs;
  mapping(address => uint256[]) public userAddressToOrders;

  uint256 public override orderNonce;
  address public override zoom;

 
  event CreateOrder(address sender, address _optionAddress, uint256 _price, uint256 _amount, uint256 _orderId);
  event AddOrder(address sender,  uint256 _orderId, uint256 _amount, uint256 _oldAmount );
  event FinishOrder(address sender,  uint256 _orderId, uint256 _acceptableUserNonce, uint256 _commitAmount,  uint256 _acceptAmount);
  event SubscribeOrder(address sender, uint256 _orderId, uint256 _index, uint256 _oldAmount, uint256 _mintAmount, uint256 _commitAmount );
  event UnsubscribeOrder(address sender,  uint256 _orderId, uint256 _index, uint256 _oldAmount, uint256 _burnAmount, uint256 _commitAmount );
  event AcceptOrder(address sender, uint256 _orderId, uint256 _index, uint256 _reward );

  modifier onlyGovernance() {
    require(msg.sender == IZoom(zoom).governance(), "ZOOM: caller not governance");
    _;
  }

  modifier onlyOrderCreator() {
    require( IZoom(zoom).isInWhiteList(msg.sender) || msg.sender == IZoom(zoom).governance(), "ZOOM: caller not creator");
    _;
  }

  constructor() {
    initializeOwner();
   }

  /**
   * @notice create order for market maker
   */
  function createOrder(
    address _optionAddress,
    uint256 _price,
    uint256 _amount
  ) external override onlyOrderCreator nonReentrant
  {

    IOption option = IOption(_optionAddress);
    option.validStatus();

    IOption.OptionDetails memory optionDetails = option.getOptionDetailsEx();

    require(_price > 0, "ZOOM: _price <= 0");
    require(_amount > 0, "ZOOM: _amount <= 0");
    
    uint256 totalAmount =  _price.mul(_amount);
    // Validate sender targetToken balance is > amount
    IERC20 targetToken = IERC20(optionDetails.targetToken);
    require(targetToken.balanceOf(msg.sender) >= totalAmount, "ZOOM: amount > targetToken balance");

    // move targetToken to the option contract and mint ZoomTokens to sender
    uint256 zoomBalanceBefore = targetToken.balanceOf(address(this));
    targetToken.transferFrom(msg.sender, address(this), totalAmount);
    uint256 zoomBalanceAfter = targetToken.balanceOf(address(this));
    require(zoomBalanceAfter > zoomBalanceBefore, "ZOOM: targetToken transfer failed");

    orderNonce = orderNonce.add(1);
    uint256 orderId = orderNonce;
    string memory orderName = _generateOrderName(optionDetails.name,orderId);

    orderDetails[orderId].name = orderName;
    orderDetails[orderId].optionAddress = _optionAddress;
    orderDetails[orderId].marketMaker= msg.sender;
    orderDetails[orderId].orderId = orderId;
    orderDetails[orderId].price=_price;
    orderDetails[orderId].amount =_amount;
    orderDetails[orderId].acceptableUserNonce = 0;
    orderDetails[orderId].finishTimeStamp = 0;
    orderDetails[orderId].userNonce = 0;
    orderDetails[orderId].commitAmount = 0;
    
    marketMakerAddressToOrders[msg.sender].push(orderId);

    emit CreateOrder(msg.sender, _optionAddress, _price, _amount, orderId);

  }


  /**
   * @notice add order amount for sender
   */
  function addOrder( uint256 _orderId,uint256 _amount )
    external override nonReentrant
  {
    this.validStatus(_orderId);
    require( msg.sender == orderDetails[_orderId].marketMaker, "ZOOM: invalid market maker!");

    uint256 totalAmount=orderDetails[_orderId].price.mul(_amount);
    require(totalAmount > 0, "ZOOM: invalid amount");

    address optionAddress = orderDetails[_orderId].optionAddress;
    IOption option = IOption(optionAddress);

    IOption.OptionDetails memory optionDetails = option.getOptionDetailsEx();

    // validate sender targetToken balance is > amount
    IERC20 targetToken = IERC20(optionDetails.targetToken);
    require(targetToken.balanceOf(msg.sender) >= totalAmount, "ZOOM: amount > targetToken balance");

    // move targetToken to the option contract and mint ZoomTokens to sender
    uint256 zoomBalanceBefore = targetToken.balanceOf(address(this));
    targetToken.transferFrom(msg.sender, address(this), totalAmount);
    uint256 zoomBalanceAfter = targetToken.balanceOf(address(this));
    require(zoomBalanceAfter > zoomBalanceBefore, "ZOOM: targetToken transfer failed");

    emit AddOrder(msg.sender, _orderId, _amount, orderDetails[_orderId].amount );

    orderDetails[_orderId].amount = orderDetails[_orderId].amount.add(_amount);

  }


   /**
   * @notice finish order for sender , only when option not expired
   */
  function finishOrder(uint256 _orderId,uint256 _acceptableUserNonce)
    external override nonReentrant
  {
    this.validStatus(_orderId);
    require( msg.sender == orderDetails[_orderId].marketMaker, "ZOOM: invalid market maker!");

    IOption option = IOption(orderDetails[_orderId].optionAddress);
    option.validStatus();

    IOption.OptionDetails memory optionDetails = option.getOptionDetailsEx();
    IZoomERC20 optionToken = IZoomERC20(optionDetails.optionToken);

    uint256 totalAmount = 0;
    
    if(_acceptableUserNonce == 0 || _acceptableUserNonce >= orderDetails[_orderId].userNonce){
      //if _acceptableUserNonce is zero or userNonce, it will collect all option token
      _acceptableUserNonce = orderDetails[_orderId].userNonce;
    }
    
    if(orderDetails[_orderId].userNonce>0){
      //if finishing time is over then the _acceptableUserNonce user's last commit timestamp, it will be revert
      uint256 commitTimeStamp = orderIndexDetails[_orderId][_acceptableUserNonce].commitTimeStamp;
      require(block.timestamp.sub(commitTimeStamp)<=IZoom(zoom).orderFinishDelay(),"ZOOM: finishOrder time is too late!");

      totalAmount = orderIndexDetails[_orderId][_acceptableUserNonce].commitAmount;
      require(totalAmount<=orderDetails[_orderId].commitAmount,"ZOOM: invalid user commitAmount!");
    }

    //get left targetToken
    uint256 leftAmount = orderDetails[_orderId].amount.sub(totalAmount);
    if(leftAmount>0){
      IERC20 targetToken = IERC20(optionDetails.targetToken);
      targetToken.transfer(msg.sender, leftAmount.mul(orderDetails[_orderId].price));
    }

    //get total option 
    if(totalAmount>0){
      optionToken.transfer(msg.sender, totalAmount);
    }

    emit FinishOrder(msg.sender, _orderId, _acceptableUserNonce, orderDetails[_orderId].commitAmount, totalAmount);

    //close
    orderDetails[_orderId].acceptableUserNonce = _acceptableUserNonce;
    orderDetails[_orderId].finishTimeStamp = block.timestamp;
    orderDetails[_orderId].commitAmount = 0;

  }


  /**
   * @notice subscribe order for sender , only when option not expired
   */
  function subscribeOrder(uint256 _orderId, uint256 _amount )
    external override nonReentrant
  {
    this.validStatus(_orderId);

    IOption option = IOption(orderDetails[_orderId].optionAddress);
    uint256 mintAmount = option.subscribeOptionByContract(_amount);

    uint256 leftAmount = orderDetails[_orderId].amount.sub(orderDetails[_orderId].commitAmount);
    require(leftAmount>=mintAmount,"ZOOM: order amount is exceed!");

    uint256 userNonce = orderDetails[_orderId].userNonce;
    userNonce = userNonce.add(1);
    orderDetails[_orderId].userNonce = userNonce;

    if(userAddressToOrderIndexs[msg.sender][_orderId].length==0){
      userAddressToOrders[msg.sender].push(_orderId);
    }
    userAddressToOrderIndexs[msg.sender][_orderId].push(userNonce);
    
    orderIndexDetails[_orderId][userNonce].orderId = orderDetails[_orderId].orderId;
    orderIndexDetails[_orderId][userNonce].user = msg.sender;
    orderIndexDetails[_orderId][userNonce].index = userNonce;
    orderIndexDetails[_orderId][userNonce].price = orderDetails[_orderId].price;
    orderIndexDetails[_orderId][userNonce].amount = mintAmount;
    orderIndexDetails[_orderId][userNonce].commitTimeStamp = block.timestamp;

    uint256 oldAmount = orderDetails[_orderId].commitAmount;
    orderDetails[_orderId].commitAmount = oldAmount.add(mintAmount);
    orderIndexDetails[_orderId][userNonce].commitAmount = orderDetails[_orderId].commitAmount;

    emit SubscribeOrder(msg.sender, _orderId, userNonce, oldAmount, mintAmount, orderDetails[_orderId].commitAmount );

  }


/**
   * @notice unsubscribe order for sender , only when option not expired
   */
  function unsubscribeOrder( uint256 _orderId, uint256 _userNonce )
    external override nonReentrant
  {

    require(_orderId>0 && _orderId<=orderNonce,"ZOOM: orderid is invalid!");

    uint256 userNonce = orderDetails[_orderId].userNonce;
    require(_userNonce<=userNonce,"ZOOM: userNonce is invalid!");

    IOrderMarket.UserDetails storage indexDetails = orderIndexDetails[_orderId][_userNonce];
    require(indexDetails.user == msg.sender && indexDetails.index == _userNonce, "ZOOM: invalid user");
    require(indexDetails.amount>0,"ZOOM: invalid commit amount!");

    require(orderDetails[_orderId].finishTimeStamp>0,"ZOOM: order had not be finished!");
    require(orderDetails[_orderId].acceptableUserNonce<indexDetails.index,"ZOOM: the user nonce has been accepted!");
    
    IOption option = IOption(orderDetails[_orderId].optionAddress);
    uint256 burnAmount = option.unsubscribeOptionByContract(indexDetails.amount);
    require(burnAmount <= indexDetails.amount, "ZOOM: invalid burnAmount");

    emit UnsubscribeOrder(msg.sender, _orderId, indexDetails.index, indexDetails.amount,  burnAmount, orderDetails[_orderId].commitAmount );

    //amount update
    indexDetails.amount = 0;

    
  }

  /**
   * @notice accept order for sender
   */
  function acceptOrder(uint256 _orderId, uint256 _userNonce )
    external override nonReentrant
  { 
    require(_orderId>0 && _orderId <= orderNonce,"ZOOM: orderid is invalid!");
   
    IOrderMarket.UserDetails storage indexDetails = orderIndexDetails[_orderId][_userNonce];
    require(indexDetails.user == msg.sender && indexDetails.index == _userNonce, "ZOOM: invalid user");
    require(indexDetails.amount>0,"ZOOM: invalid commit amount!");
    require(indexDetails.acceptTimeStamp==0,"ZOOM: order has been accept!");

    if(orderDetails[_orderId].finishTimeStamp>0){
      require(orderDetails[_orderId].acceptableUserNonce>=indexDetails.index,"ZOOM: the user has been refused!");
    }
    else{
      uint256 commitTimeStamp = indexDetails.commitTimeStamp;
      require(block.timestamp.sub(commitTimeStamp)>IZoom(zoom).orderFinishDelay(),"ZOOM: order still pending");
    }

    address optionAddress = orderDetails[_orderId].optionAddress;
    IOption option = IOption(optionAddress);
    IOption.OptionDetails memory optionDetails = option.getOptionDetailsEx();

    //get reward
    uint256 amount = indexDetails.amount;
    uint256 reward = amount.mul(indexDetails.price);
    
    IERC20 targetToken = IERC20(optionDetails.targetToken);
    targetToken.transfer(msg.sender, reward);

    emit AcceptOrder(msg.sender, _orderId, indexDetails.index, reward );

    //close
    indexDetails.acceptTimeStamp = block.timestamp;
    indexDetails.amount = 0;

  }

  function getOrderDetails(uint256 _orderId)
    external view override returns (
        string memory _name,
        address _optionAddress,
        address _marketMaker,
        uint256 _price,
        uint256 _amount,
        uint256 _acceptableUserNonce,
        uint256 _finishTimeStamp,
        uint256 _userNonce,
        uint256 _commitAmount
    )
  {
    _name = orderDetails[_orderId].name;
    _optionAddress = orderDetails[_orderId].optionAddress;
    _marketMaker=orderDetails[_orderId].marketMaker;
    _price = orderDetails[_orderId].price;
    _amount = orderDetails[_orderId].amount;
    _acceptableUserNonce = orderDetails[_orderId].acceptableUserNonce;
    _finishTimeStamp = orderDetails[_orderId].finishTimeStamp;
    _userNonce = orderDetails[_orderId].userNonce;
    _commitAmount = orderDetails[_orderId].commitAmount;
  }

  function getOrderDetailsEx(uint256 _orderId)
    external view override
    returns (IOrderMarket.OrderDetails memory _order)
    {
        _order.name = orderDetails[_orderId].name;
        _order.optionAddress = orderDetails[_orderId].optionAddress;
        _order.marketMaker = orderDetails[_orderId].marketMaker;
        _order.orderId = orderDetails[_orderId].orderId;
        _order.price = orderDetails[_orderId].price;
        _order.amount = orderDetails[_orderId].amount;
        _order.acceptableUserNonce = orderDetails[_orderId].acceptableUserNonce;
        _order.finishTimeStamp = orderDetails[_orderId].finishTimeStamp;
        _order.userNonce = orderDetails[_orderId].userNonce;
        _order.commitAmount = orderDetails[_orderId].commitAmount;

    }


  function getUserDetails(uint256 _orderId, uint256 _userNonce )
    external view override returns (
        address _user,
        uint256 _index,
        uint256 _price,
        uint256 _amount,
        uint256 _commitTimeStamp,
        uint256 _acceptTimeStamp,
        uint256 _commitAmount 
    )
  {

    IOrderMarket.UserDetails memory details = orderIndexDetails[_orderId][_userNonce];
    require(details.index != 0,"ZOOM: invalid user!");

    return (
        details.user,
        details.index,
        details.price,
        details.amount,
        details.commitTimeStamp,
        details.acceptTimeStamp,
        details.commitAmount
    );
  }

  function getUserDetailsEx(uint256 _orderId, uint256 _userNonce )
    external view override
    returns (IOrderMarket.UserDetails memory _order)
    {
      IOrderMarket.UserDetails memory details = orderIndexDetails[_orderId][_userNonce];
      require(details.index != 0,"ZOOM: invalid user!");

      _order.orderId = details.orderId;
      _order.user = details.user;
      _order.index = details.index;
      _order.price = details.price;
      _order.amount = details.amount;
      _order.commitTimeStamp = details.commitTimeStamp;
      _order.acceptTimeStamp = details.acceptTimeStamp;
      _order.commitAmount = details.commitAmount;
    }

  //valid the status
  function validStatus( uint256 _orderId ) external view override
  {
    require(_orderId>0 && _orderId<=orderNonce,"ZOOM: orderid is invalid!");
    require(orderDetails[_orderId].finishTimeStamp<=0,"ZOOM: order has finished!");
  }

  function hookZoom(address _zoom) external  override  returns (bool) 
  {
    require(IOwnable(_zoom).owner() == owner(), "ZOOM: invalid owner!");
    zoom = _zoom;
    return true;
  }

  function getMarketMakerOrders( address _marketMaker ) external view  override returns (uint256[] memory){
    return marketMakerAddressToOrders[_marketMaker];
  }

  function getUserOrders(address _user) external view  override returns (uint256[] memory){
    return userAddressToOrders[_user];
  }
  
  function getUserOrderIndexs( address _user, uint256 _orderId ) external view override returns (uint256[] memory ){
    return userAddressToOrderIndexs[_user][_orderId];
  }

  /// @dev generate the option name. Example: OFFER_ZOOM_CURVE_1609167930_DAI_0_0
  function _generateOrderName(string memory _optionName, uint256 _orderId)
   internal pure returns (string memory) 
  {
    return string(abi.encodePacked(
      "ORDER",
      "_",
      _optionName,
      "_",
      ZoomString.uintToString(_orderId)
    ));
  }

}