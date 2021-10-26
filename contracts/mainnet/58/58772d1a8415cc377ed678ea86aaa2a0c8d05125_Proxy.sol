/*
  Copyright 2019-2021 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "ProxyGovernance.sol";
import "ProxyStorage.sol";
import "StorageSlots.sol";
import "Common.sol";

/**
  The Proxy contract implements delegation of calls to other contracts (`implementations`), with
  proper forwarding of return values and revert reasons. This pattern allows retaining the contract
  storage while replacing implementation code.

  The following operations are supported by the proxy contract:

  - :sol:func:`addImplementation`: Defines a new implementation, the data with which it should be initialized and whether this will be the last version of implementation.
  - :sol:func:`upgradeTo`: Once an implementation is added, the governor may upgrade to that implementation only after a safety time period has passed (time lock), the current implementation is not the last version and the implementation is not frozen (see :sol:mod:`FullWithdrawals`).
  - :sol:func:`removeImplementation`: Any announced implementation may be removed. Removing an implementation is especially important once it has been used for an upgrade in order to avoid an additional unwanted revert to an older version.

  The only entity allowed to perform the above operations is the proxy governor
  (see :sol:mod:`ProxyGovernance`).

  Every implementation is required to have an `initialize` function that replaces the constructor
  of a normal contract. Furthermore, the only parameter of this function is an array of bytes
  (`data`) which may be decoded arbitrarily by the `initialize` function. It is up to the
  implementation to ensure that this function cannot be run more than once if so desired.

  When an implementation is added (:sol:func:`addImplementation`) the initialization `data` is also
  announced, allowing users of the contract to analyze the full effect of an upgrade to the new
  implementation. During an :sol:func:`upgradeTo`, the `data` is provided again and only if it is
  identical to the announced `data` is the upgrade performed by pointing the proxy to the new
  implementation and calling its `initialize` function with this `data`.

  It is the responsibility of the implementation not to overwrite any storage belonging to the
  proxy (`ProxyStorage`). In addition, upon upgrade, the new implementation is assumed to be
  backward compatible with previous implementations with respect to the storage used until that
  point.
*/
contract Proxy is ProxyStorage, ProxyGovernance, StorageSlots {
    // Emitted when the active implementation is replaced.
    event ImplementationUpgraded(address indexed implementation, bytes initializer);

    // Emitted when an implementation is submitted as an upgrade candidate and a time lock
    // is activated.
    event ImplementationAdded(address indexed implementation, bytes initializer, bool finalize);

    // Emitted when an implementation is removed from the list of upgrade candidates.
    event ImplementationRemoved(address indexed implementation, bytes initializer, bool finalize);

    // Emitted when the implementation is finalized.
    event FinalizedImplementation(address indexed implementation);

    using Addresses for address;

    string public constant PROXY_VERSION = "3.0.0";

    constructor(uint256 upgradeActivationDelay) public {
        initGovernance();
        setUpgradeActivationDelay(upgradeActivationDelay);
    }

    function setUpgradeActivationDelay(uint256 delayInSeconds) private {
        bytes32 slot = UPGRADE_DELAY_SLOT;
        assembly {
            sstore(slot, delayInSeconds)
        }
    }

    function getUpgradeActivationDelay() public view returns (uint256 delay) {
        bytes32 slot = UPGRADE_DELAY_SLOT;
        assembly {
            delay := sload(slot)
        }
        return delay;
    }

    /*
      Returns the address of the current implementation.
    */
    // NOLINTNEXTLINE external-function.
    function implementation() public view returns (address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

    /*
      Returns true if the implementation is frozen.
      If the implementation was not assigned yet, returns false.
    */
    function implementationIsFrozen() private returns (bool) {
        address _implementation = implementation();

        // We can't call low level implementation before it's assigned. (i.e. ZERO).
        if (_implementation == address(0x0)) {
            return false;
        }

        // NOLINTNEXTLINE: low-level-calls.
        (bool success, bytes memory returndata) = _implementation.delegatecall(
            abi.encodeWithSignature("isFrozen()")
        );
        require(success, string(returndata));
        return abi.decode(returndata, (bool));
    }

    /*
      This method blocks delegation to initialize().
      Only upgradeTo should be able to delegate call to initialize().
    */
    function initialize(
        bytes calldata /*data*/
    ) external pure {
        revert("CANNOT_CALL_INITIALIZE");
    }

    modifier notFinalized() {
        require(isNotFinalized(), "IMPLEMENTATION_FINALIZED");
        _;
    }

    /*
      Forbids calling the function if the implementation is frozen.
      This modifier relies on the lower level (logical contract) implementation of isFrozen().
    */
    modifier notFrozen() {
        require(!implementationIsFrozen(), "STATE_IS_FROZEN");
        _;
    }

    /*
      This entry point serves only transactions with empty calldata. (i.e. pure value transfer tx).
      We don't expect to receive such, thus block them.
    */
    receive() external payable {
        revert("CONTRACT_NOT_EXPECTED_TO_RECEIVE");
    }

    /*
      Contract's default function. Delegates execution to the implementation contract.
      It returns back to the external caller whatever the implementation delegated code returns.
    */
    fallback() external payable {
        address _implementation = implementation();
        require(_implementation != address(0x0), "MISSING_IMPLEMENTATION");

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 for now, as we don't know the out size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /*
      Sets the implementation address of the proxy.
    */
    function setImplementation(address newImplementation) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    /*
      Returns true if the contract is not in the finalized state.
    */
    function isNotFinalized() public view returns (bool notFinal) {
        bytes32 slot = FINALIZED_STATE_SLOT;
        uint256 slotValue;
        assembly {
            slotValue := sload(slot)
        }
        notFinal = (slotValue == 0);
    }

    /*
      Marks the current implementation as finalized.
    */
    function setFinalizedFlag() private {
        bytes32 slot = FINALIZED_STATE_SLOT;
        assembly {
            sstore(slot, 0x1)
        }
    }

    /*
      Introduce an implementation and its initialization vector,
      and start the time-lock before it can be upgraded to.
      addImplementation is not blocked when frozen or finalized.
      (upgradeTo API is blocked when finalized or frozen).
    */
    function addImplementation(
        address newImplementation,
        bytes calldata data,
        bool finalize
    ) external onlyGovernance {
        require(newImplementation.isContract(), "ADDRESS_NOT_CONTRACT");

        bytes32 implVectorHash = keccak256(abi.encode(newImplementation, data, finalize));

        uint256 activationTime = block.timestamp + getUpgradeActivationDelay();

        // First implementation should not have time-lock.
        if (implementation() == address(0x0)) {
            activationTime = block.timestamp;
        }

        enabledTime[implVectorHash] = activationTime;
        emit ImplementationAdded(newImplementation, data, finalize);
    }

    /*
      Removes a candidate implementation.
      Note that it is possible to remove the current implementation. Doing so doesn't affect the
      current implementation, but rather revokes it as a future candidate.
    */
    function removeImplementation(
        address removedImplementation,
        bytes calldata data,
        bool finalize
    ) external onlyGovernance {
        bytes32 implVectorHash = keccak256(abi.encode(removedImplementation, data, finalize));

        // If we have initializer, we set the hash of it.
        uint256 activationTime = enabledTime[implVectorHash];
        require(activationTime > 0, "UNKNOWN_UPGRADE_INFORMATION");
        delete enabledTime[implVectorHash];
        emit ImplementationRemoved(removedImplementation, data, finalize);
    }

    /*
      Upgrades the proxy to a new implementation, with its initialization.
      to upgrade successfully, implementation must have been added time-lock agreeably
      before, and the init vector must be identical ot the one submitted before.

      Upon assignment of new implementation address,
      its initialize will be called with the initializing vector (even if empty).
      Therefore, the implementation MUST must have such a method.

      Note - Initialization data is committed to in advance, therefore it must remain valid
      until the actual contract upgrade takes place.

      Care should be taken regarding initialization data and flow when planning the contract upgrade.

      When planning contract upgrade, special care is also needed with regard to governance
      (See comments in Governance.sol).
    */
    // NOLINTNEXTLINE: reentrancy-events timestamp.
    function upgradeTo(
        address newImplementation,
        bytes calldata data,
        bool finalize
    ) external payable onlyGovernance notFinalized notFrozen {
        bytes32 implVectorHash = keccak256(abi.encode(newImplementation, data, finalize));
        uint256 activationTime = enabledTime[implVectorHash];
        require(activationTime > 0, "UNKNOWN_UPGRADE_INFORMATION");
        require(newImplementation.isContract(), "ADDRESS_NOT_CONTRACT");
        // NOLINTNEXTLINE: timestamp.
        require(activationTime <= block.timestamp, "UPGRADE_NOT_ENABLED_YET");

        setImplementation(newImplementation);

        // NOLINTNEXTLINE: low-level-calls controlled-delegatecall.
        (bool success, bytes memory returndata) = newImplementation.delegatecall(
            abi.encodeWithSelector(this.initialize.selector, data)
        );
        require(success, string(returndata));

        // Verify that the new implementation is not frozen post initialization.
        // NOLINTNEXTLINE: low-level-calls controlled-delegatecall.
        (success, returndata) = newImplementation.delegatecall(
            abi.encodeWithSignature("isFrozen()")
        );
        require(success, "CALL_TO_ISFROZEN_REVERTED");
        require(!abi.decode(returndata, (bool)), "NEW_IMPLEMENTATION_FROZEN");

        if (finalize) {
            setFinalizedFlag();
            emit FinalizedImplementation(newImplementation);
        }

        emit ImplementationUpgraded(newImplementation, data);
    }
}