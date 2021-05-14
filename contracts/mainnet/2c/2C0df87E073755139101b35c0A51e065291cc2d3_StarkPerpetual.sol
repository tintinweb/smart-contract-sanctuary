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

import "MainDispatcher.sol";
import "PerpetualStorage.sol";

contract StarkPerpetual is MainDispatcher, PerpetualStorage {
    string public constant VERSION = "1.0.0";

    // Salt for a 8 bit unique spread of all relevant selectors. Pre-caclulated.
    // ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
    uint256 constant MAGIC_SALT = 24748;
    uint256 constant IDX_MAP_0 = 0x3000100000203000002010004002012003003200010000001222000021002010;
    uint256 constant IDX_MAP_1 = 0x4300000140200010000000001000030000300100000222303302;
    uint256 constant IDX_MAP_2 = 0x10001300000020200020000220001002020000320000020031100030020012;
    uint256 constant IDX_MAP_3 = 0x120300002000000000000100000000202001002000040101130302000000;
    // ---------- End of auto-generated code. ----------

    function getNumSubcontracts() internal pure override returns (uint256) {
        return 4;
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
        if (index == 1){
            id = "StarkWare_AllVerifiers_2020_1";
        } else if (index == 2){
            id = "StarkWare_PerpetualTokensAndRamping_2020_1";
        } else if (index == 3){
            id = "StarkWare_PerpetualState_2020_1";
        } else if (index == 4){
            id = "StarkWare_PerpetualForcedActions_2020_1";
        } else {
            revert("UNEXPECTED_INDEX");
        }
    }

    function initializationSentinel() internal view override {
        string memory REVERT_MSG = "INITIALIZATION_BLOCKED";
        // This initializer sets state etc. It must not be applied twice.
        // I.e. it can run only when the state is still empty.
        require(int(sharedStateHash) == 0, REVERT_MSG);
        require(int(globalConfigurationHash) == 0, REVERT_MSG);
        require(systemAssetType == 0, REVERT_MSG);
    }
}