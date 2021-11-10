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

import "StarkExForcedActionState.sol";
import "ERC721Receiver.sol";
import "Freezable.sol";
import "KeyGetters.sol";
import "TokenRegister.sol";
import "TokenTransfers.sol";
import "Users.sol";
import "MainGovernance.sol";
import "AcceptModifications.sol";
import "CompositeActions.sol";
import "Deposits.sol";
import "TokenAssetData.sol";
import "TokenQuantization.sol";
import "Withdrawals.sol";
import "SubContractor.sol";

contract TokensAndRamping is
    ERC721Receiver,
    SubContractor,
    Freezable,
    MainGovernance,
    AcceptModifications,
    StarkExForcedActionState,
    TokenAssetData,
    TokenQuantization,
    TokenRegister,
    TokenTransfers,
    KeyGetters,
    Users,
    Deposits,
    CompositeActions,
    Withdrawals
{
    function initialize(
        bytes calldata /* data */
    ) external override {
        revert("NOT_IMPLEMENTED");
    }

    function initializerSize() external view override returns (uint256) {
        return 0;
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_TokensAndRamping_2020_1";
    }
}