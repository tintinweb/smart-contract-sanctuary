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
pragma solidity ^0.6.11;

import "SubContractor.sol";
import "ProxyGovernance.sol";
import "ProxyStorage.sol";
import "StorageSlots.sol";

contract ProxyUtils is
    SubContractor,
    StorageSlots,
    ProxyGovernance,
    ProxyStorage
{
    event ImplementationActivationRescheduled(
        address indexed implementation, uint256 updatedActivationTime);

    function initialize(bytes calldata /* data */) external override {
        revert("NOT_IMPLEMENTED");
    }

    function initializerSize() external override view returns (uint256) {
        return 0;
    }

    function identify() external override pure returns (string memory) {
        return "StarkWare_ProxyUtils_2021_1";
    }

    function storedActivationDelay() internal view returns(uint256 delay) {
        bytes32 slot = UPGRADE_DELAY_SLOT;
        assembly {
            delay := sload(slot)
        }
        return delay;
    }

    function updateImplementationActivationTime(
            address implementation, bytes calldata data, bool finalize) external onlyGovernance {

        uint256 updatedActivationTime = block.timestamp + storedActivationDelay();

        // We assume the Proxy is of the old format.
        bytes32 oldFormatInitHash = keccak256(abi.encode(data, finalize));
        require(
            initializationHash_DEPRECATED[implementation] == oldFormatInitHash,
            "IMPLEMENTATION_NOT_PENDING");

        // Converting address to bytes32 to match the mapping key type.
        bytes32 implementationKey;
        assembly {implementationKey := implementation}
        uint256 pendingActivationTime = enabledTime[implementationKey];

        require(pendingActivationTime > 0, "IMPLEMENTATION_NOT_PENDING");

        // Current value is checked to be within a reasonable delay. If it's over 6 months from now,
        // it's assumed that the activation time is configured under a different set of rules.
        require(
            pendingActivationTime < block.timestamp + 180 days,
            "INVALID_PENDING_ACTIVATION_TIME");

        if (updatedActivationTime < pendingActivationTime) {
            enabledTime[implementationKey] = updatedActivationTime;
            emit ImplementationActivationRescheduled(implementation, updatedActivationTime);
        }
    }
}