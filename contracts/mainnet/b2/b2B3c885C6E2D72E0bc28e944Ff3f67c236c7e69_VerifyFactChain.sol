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

import "MainStorage.sol";
import "IFactRegistry.sol";
import "Common.sol";

contract VerifyFactChain is MainStorage {

    function verifyFact(
        StarkExTypes.ApprovalChainData storage chain, bytes32 fact, string memory noVerifiersErrorMessage,
        string memory invalidFactErrorMessage)
        internal view
    {
        address[] storage list = chain.list;
        uint256 n_entries = list.length;
        require(n_entries > 0, noVerifiersErrorMessage);
        for (uint256 i = 0; i < n_entries; i++) {
            // NOLINTNEXTLINE: calls-loop.
            require(IFactRegistry(list[i]).isValid(fact), invalidFactErrorMessage);
        }
    }
}
