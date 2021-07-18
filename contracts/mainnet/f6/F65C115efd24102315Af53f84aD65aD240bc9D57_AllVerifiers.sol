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

import "ApprovalChain.sol";
import "AvailabilityVerifiers.sol";
import "Freezable.sol";
import "MainGovernance.sol";
import "Verifiers.sol";
import "SubContractor.sol";

contract AllVerifiers is
    SubContractor,
    MainGovernance,
    Freezable,
    ApprovalChain,
    AvailabilityVerifiers,
    Verifiers
{
    function initialize(bytes calldata /* data */)
        external override {
        revert("NOT_IMPLEMENTED");
    }

    function initializerSize()
        external view override
        returns(uint256){
        return 0;
    }

    function identify()
        external pure override
        returns(string memory){
        return "StarkWare_AllVerifiers_2020_1";
    }
}