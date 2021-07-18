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

import "Escapes.sol";
import "StarkExForcedActionState.sol";
import "UpdateState.sol";
import "Freezable.sol";
import "MainGovernance.sol";
import "Operator.sol";
import "AcceptModifications.sol";
import "StateRoot.sol";
import "TokenQuantization.sol";
import "SubContractor.sol";

contract StarkExState is
    MainGovernance,
    SubContractor,
    Operator,
    Freezable,
    AcceptModifications,
    TokenQuantization,
    StarkExForcedActionState,
    StateRoot,
    Escapes,
    UpdateState
{
    uint256 constant INITIALIZER_SIZE = 9 * 32; // 2 * address + 6 * uint256 + 1 * bool = 288 bytes.

    struct InitializationArgStruct {
        address escapeVerifierAddress;
        uint256 sequenceNumber;
        uint256 vaultRoot;
        uint256 orderRoot;
        uint256 vaultTreeHeight;
        uint256 orderTreeHeight;
        uint256 onchainDataVersionValue;
        bool strictVaultBalancePolicy;
        address orderRegistryAddress;
    }

    /*
      Initialization flow:
      1. Extract initialization parameters from data.
      2. Call internalInitializer with those parameters.
    */
    function initialize(bytes calldata data) external virtual override {
        // This initializer sets roots etc. It must not be applied twice.
        // I.e. it can run only when the state is still empty.
        require(vaultRoot == 0, "STATE_ALREADY_INITIALIZED");
        require(vaultTreeHeight == 0, "STATE_ALREADY_INITIALIZED");
        require(orderRoot == 0, "STATE_ALREADY_INITIALIZED");
        require(orderTreeHeight == 0, "STATE_ALREADY_INITIALIZED");

        require(data.length == INITIALIZER_SIZE, "INCORRECT_INIT_DATA_SIZE_256");

        // Copies initializer values into initValues.
        InitializationArgStruct memory initValues;
        bytes memory _data = data;
        assembly {initValues := add(32, _data)}

        initGovernance();
        Operator.initialize();
        StateRoot.initialize(
            initValues.sequenceNumber,
            initValues.vaultRoot,
            initValues.orderRoot,
            initValues.vaultTreeHeight,
            initValues.orderTreeHeight
        );
        Escapes.initialize(initValues.escapeVerifierAddress);
        onchainDataVersion = initValues.onchainDataVersionValue;
        strictVaultBalancePolicy = initValues.strictVaultBalancePolicy;
        orderRegistryAddress = initValues.orderRegistryAddress;
    }

    /*
      The call to initializerSize is done from MainDispatcherBase using delegatecall,
      thus the existing state is already accessible.
    */
    function initializerSize() external view virtual override returns (uint256) {
        return INITIALIZER_SIZE;
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_StarkExState_2021_1";
    }
}