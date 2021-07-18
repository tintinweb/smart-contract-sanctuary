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
    string public constant VERSION = "3.0.3";

    // Salt for a 8 bit unique spread of all relevant selectors. Pre-caclulated.
    // ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
    uint256 constant MAGIC_SALT = 20188;
    uint256 constant IDX_MAP_0 = 0x110200000021000030000005000020015200500020500200002020220000;
    uint256 constant IDX_MAP_1 = 0x200200032001330010000101000203000003120201405000200010000;
    uint256 constant IDX_MAP_2 = 0x100230002000000020032200261550025010000100102002003020010000030;
    uint256 constant IDX_MAP_3 = 0x2001022000000001031050500102200001020200300004010100002002;
    // ---------- End of auto-generated code. ----------

    function getNumSubcontracts() internal pure override returns (uint256) {
        return 6;
    }

    function magicSalt() internal pure override returns(uint256) {
        return MAGIC_SALT;
    }

    function handlerMapSection(uint256 section) internal view override returns(uint256) {
        if(section == 0) {
            return IDX_MAP_0;
        }
        else if(section == 1) {
            return IDX_MAP_1;
        }
        else if(section == 2) {
            return IDX_MAP_2;
        }
        else if(section == 3) {
            return IDX_MAP_3;
        }
        revert("BAD_IDX_MAP_SECTION");
    }

    function expectedIdByIndex(uint256 index)
        internal pure override returns (string memory id) {
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