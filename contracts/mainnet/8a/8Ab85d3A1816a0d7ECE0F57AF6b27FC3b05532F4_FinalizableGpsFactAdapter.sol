/*
  Copyright 2019,2020 StarkWare Industries Ltd.

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

import "Finalizable.sol";
import "GpsFactRegistryAdapter.sol";
import "IQueryableFactRegistry.sol";

/**
  A finalizable version of GpsFactRegistryAdapter.
  It allows resetting the gps program hash, until finalized.
*/
contract FinalizableGpsFactAdapter is GpsFactRegistryAdapter , Finalizable {

    constructor(IQueryableFactRegistry gpsStatementContract, uint256 programHash_)
        public
        GpsFactRegistryAdapter(gpsStatementContract, programHash_)
    {
    }

    function setProgramHash(uint256 newProgramHash)
        external
        notFinalized
        onlyAdmin
    {
        programHash = newProgramHash;
    }

    function identify() external override pure returns (string memory) {
        return "StarkWare_FinalizableGpsFactAdapterForTesting_2021_1";
    }
}