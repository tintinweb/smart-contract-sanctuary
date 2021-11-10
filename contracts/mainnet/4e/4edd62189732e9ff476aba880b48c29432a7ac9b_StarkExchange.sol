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

import "MainDispatcher.sol";

contract StarkExchange is MainDispatcher {
    string public constant VERSION = "4.0.1";

    // Salt for a 8 bit unique spread of all relevant selectors. Pre-caclulated.
    // ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
    uint256 constant MAGIC_SALT = 46110;
    uint256 constant IDX_MAP_0 = 0x30006100050005012000102002000001200000010001100500200000000020;
    uint256 constant IDX_MAP_1 = 0x120000105000000501200000120502000000200452005000202002030500003;
    uint256 constant IDX_MAP_2 = 0x1020000000003020000502203000300000200000000001000100330010220001;
    uint256 constant IDX_MAP_3 = 0x200230200020300001401200000000100020011200000002020000010000301;

    // ---------- End of auto-generated code. ----------

    function getNumSubcontracts() internal pure override returns (uint256) {
        return 6;
    }

    function magicSalt() internal pure override returns (uint256) {
        return MAGIC_SALT;
    }

    function handlerMapSection(uint256 section) internal view override returns (uint256) {
        if (section == 0) {
            return IDX_MAP_0;
        } else if (section == 1) {
            return IDX_MAP_1;
        } else if (section == 2) {
            return IDX_MAP_2;
        } else if (section == 3) {
            return IDX_MAP_3;
        }
        revert("BAD_IDX_MAP_SECTION");
    }

    function expectedIdByIndex(uint256 index) internal pure override returns (string memory id) {
        if (index == 1) {
            id = "StarkWare_AllVerifiers_2020_1";
        } else if (index == 2) {
            id = "StarkWare_TokensAndRamping_2020_1";
        } else if (index == 3) {
            id = "StarkWare_StarkExState_2021_1";
        } else if (index == 4) {
            id = "StarkWare_ForcedActions_2020_1";
        } else if (index == 5) {
            id = "StarkWare_OnchainVaults_2021_1";
        } else if (index == 6) {
            id = "StarkWare_ProxyUtils_2021_1";
        } else {
            revert("UNEXPECTED_INDEX");
        }
    }

    function initializationSentinel() internal view override {
        string memory REVERT_MSG = "INITIALIZATION_BLOCKED";
        // This initializer sets roots etc. It must not be applied twice.
        // I.e. it can run only when the state is still empty.
        require(vaultRoot == 0, REVERT_MSG);
        require(vaultTreeHeight == 0, REVERT_MSG);
        require(orderRoot == 0, REVERT_MSG);
        require(orderTreeHeight == 0, REVERT_MSG);
    }
}