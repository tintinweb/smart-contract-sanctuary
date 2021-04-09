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
pragma solidity ^0.5.2;

import "ERC721Receiver.sol";
import "Freezable.sol";
import "KeyGetters.sol";
import "Operator.sol";
import "Tokens.sol";
import "Users.sol";
import "MainGovernance.sol";
import "AcceptModifications.sol";
import "Deposits.sol";
import "FullWithdrawals.sol";
import "Withdrawals.sol";
import "SubContractor.sol";

contract TokensAndRamping is
    ERC721Receiver,
    SubContractor,
    Operator,
    Freezable,
    MainGovernance,
    AcceptModifications,
    Tokens,
    KeyGetters,
    Users,
    Deposits,
    Withdrawals,
    FullWithdrawals
{
    // TODO(Remo,01/01/2022): When the initialize embodied, place stateful upgrade prevention.
    function initialize(bytes calldata /* data */)
        external {
        revert("NOT_IMPLEMENTED");
    }

    function initializerSize()
        external view
        returns(uint256){
        return 0;
    }

    function identify()
        external pure
        returns(string memory){
        return "StarkWare_TokensAndRamping_2020_1";
    }
}