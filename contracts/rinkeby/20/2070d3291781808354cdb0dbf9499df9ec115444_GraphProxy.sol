// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/utils/Address.sol";

import "./GraphProxyStorage.sol";

/**
 * @title Graph Proxy
 * @dev Graph Proxy contract used to delegate call implementation contracts and support upgrades.
 * This contract should NOT define storage as it is managed by GraphProxyStorage.
 * This contract implements a proxy that is upgradeable by an admin.
 * https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#transparent-proxies-and-function-clashes
 */
contract GraphProxy is GraphProxyStorage {
    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless
     * the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless
     * the sender is the admin or pending implementation.
     */
    modifier ifAdminOrPendingImpl() {
        if (msg.sender == _admin() || msg.sender == _pendingImplementation()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Contract constructor.
     * @param _impl Address of the initial implementation
     * @param _admin Address of the proxy admin
     */
    constructor(address _impl, address _admin) {
        assert(ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        assert(
            IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        assert(
            PENDING_IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.pendingImplementation")) - 1)
        );

        _setAdmin(_admin);
        _setPendingImplementation(_impl);
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin and implementation can call this function.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdminOrPendingImpl returns (address) {
        return _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdminOrPendingImpl returns (address) {
        return _implementation();
    }

    /**
     * @dev Returns the current pending implementation.
     *
     * NOTE: Only the admin can call this function.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x9e5eddc59e0b171f57125ab86bee043d9128098c3a6b9adb4f2e86333c2f6f8c`
     */
    function pendingImplementation() external ifAdminOrPendingImpl returns (address) {
        return _pendingImplementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * NOTE: Only the admin can call this function.
     */
    function setAdmin(address _newAdmin) external ifAdmin {
        require(_newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
        _setAdmin(_newAdmin);
    }

    /**
     * @dev Upgrades to a new implementation contract.
     * @param _newImplementation Address of implementation contract
     *
     * NOTE: Only the admin can call this function.
     */
    function upgradeTo(address _newImplementation) external ifAdmin {
        _setPendingImplementation(_newImplementation);
    }

    /**
     * @dev Admin function for new implementation to accept its role as implementation.
     */
    function acceptUpgrade() external ifAdminOrPendingImpl {
        _acceptUpgrade();
    }

    /**
     * @dev Admin function for new implementation to accept its role as implementation.
     */
    function acceptUpgradeAndCall(bytes calldata data) external ifAdminOrPendingImpl {
        _acceptUpgrade();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _implementation().delegatecall(data);
        require(success);
    }

    /**
     * @dev Admin function for new implementation to accept its role as implementation.
     */
    function _acceptUpgrade() internal {
        address _pendingImplementation = _pendingImplementation();
        require(Address.isContract(_pendingImplementation), "Implementation must be a contract");
        require(
            _pendingImplementation != address(0) && msg.sender == _pendingImplementation,
            "Caller must be the pending implementation"
        );

        _setImplementation(_pendingImplementation);
        _setPendingImplementation(address(0));
    }

    /**
     * @dev Delegates the current call to implementation.
     * This function does not return to its internal call site, it will return directly to the
     * external caller.
     */
    function _fallback() internal {
        require(msg.sender != _admin(), "Cannot fallback to proxy target");

        assembly {
            // (a) get free memory pointer
            let ptr := mload(0x40)

            // (b) get address of the implementation
            let impl := and(sload(IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)

            // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())

            // (2) forward call to logic contract
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()

            // (3) retrieve return data
            returndatacopy(ptr, 0, size)

            // (4) forward return data back to caller
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    /**
     * @dev Fallback function that delegates calls to implementation. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to implementation. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
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

pragma solidity ^0.7.3;

/**
 * @title Graph Proxy Storage
 * @dev Contract functions related to getting and setting proxy storage.
 * This contract does not actually define state variables managed by the compiler
 * but uses fixed slot locations.
 */
contract GraphProxyStorage {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32
        internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the address of the pending implementation.
     * This is the keccak-256 hash of "eip1967.proxy.pendingImplementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32
        internal constant PENDING_IMPLEMENTATION_SLOT = 0x9e5eddc59e0b171f57125ab86bee043d9128098c3a6b9adb4f2e86333c2f6f8c;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32
        internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when pendingImplementation is changed.
     */
    event PendingImplementationUpdated(
        address indexed oldPendingImplementation,
        address indexed newPendingImplementation
    );

    /**
     * @dev Emitted when pendingImplementation is accepted,
     * which means contract implementation is updated.
     */
    event ImplementationUpdated(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);

    /**
     * @dev Modifier to check whether the `msg.sender` is the admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin(), "Caller must be admin");
        _;
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
     * @param _newAdmin Address of the new proxy admin
     */
    function _setAdmin(address _newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, _newAdmin)
        }

        emit AdminUpdated(_admin(), _newAdmin);
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Returns the current pending implementation.
     * @return impl Address of the current pending implementation
     */
    function _pendingImplementation() internal view returns (address impl) {
        bytes32 slot = PENDING_IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param _newImplementation Address of the new implementation
     */
    function _setImplementation(address _newImplementation) internal {
        address oldImplementation = _implementation();

        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _newImplementation)
        }

        emit ImplementationUpdated(oldImplementation, _newImplementation);
    }

    /**
     * @dev Sets the pending implementation address of the proxy.
     * @param _newImplementation Address of the new pending implementation
     */
    function _setPendingImplementation(address _newImplementation) internal {
        address oldPendingImplementation = _pendingImplementation();

        bytes32 slot = PENDING_IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _newImplementation)
        }

        emit PendingImplementationUpdated(oldPendingImplementation, _newImplementation);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}