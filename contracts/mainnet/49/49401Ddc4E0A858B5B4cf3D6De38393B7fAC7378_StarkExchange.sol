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
import "MainDispatcher.sol";

contract StarkExchange is MainStorage, MainDispatcher {
    string public constant VERSION = "2.5.0";

    uint256 constant SUBCONTRACT_BITS = 4;

    // Salt for a 7 bit unique spread of all relevant selectors. Pre-calculated.
    // ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------
    uint256 constant MAGIC_SALT = 45733;
    uint256 constant IDX_MAP_0 = 0x201220230201001000221220210222000000020303010211122120200003002;
    uint256 constant IDX_MAP_1 = 0x2100003002200010003000000300100220220203000020000101022100011100;
    // ---------- End of auto-generated code. ----------

    function validateSubContractIndex(uint256 index, address subContract) internal pure{
        string memory id = SubContractor(subContract).identify();
        bytes32 hashed_expected_id = keccak256(abi.encodePacked(expectedIdByIndex(index)));
        require(
            hashed_expected_id == keccak256(abi.encodePacked(id)),
            "MISPLACED_INDEX_OR_BAD_CONTRACT_ID");
    }

    function expectedIdByIndex(uint256 index)
        private pure returns (string memory id) {
        if (index == 1){
            id = "StarkWare_AllVerifiers_2020_1";
        } else if (index == 2){
            id = "StarkWare_TokensAndRamping_2020_1";
        } else if (index == 3){
            id = "StarkWare_StarkExState_2020_1";
        } else {
            revert("UNEXPECTED_INDEX");
        }
    }

    function getNumSubcontracts() internal pure returns (uint256) {
        return 3;
    }

    function getSubContract(bytes4 selector)
        internal view returns (address) {
        uint256 location = 0x7F & uint256(keccak256(abi.encodePacked(selector, MAGIC_SALT)));
        uint256 subContractIdx;
        uint256 offset = SUBCONTRACT_BITS * location % 256;
        if (location < 64) {
            subContractIdx = (IDX_MAP_0 >> offset) & 0xF;
        } else {
            subContractIdx = (IDX_MAP_1 >> offset) & 0xF;
        }
        return subContracts[subContractIdx];
    }

    function setSubContractAddress(uint256 index, address subContractAddress) internal {
        subContracts[index] = subContractAddress;
    }

    function initializationSentinel()
        internal view {
        string memory REVERT_MSG = "INITIALIZATION_BLOCKED";
        // This initializer sets roots etc. It must not be applied twice.
        // I.e. it can run only when the state is still empty.
        require(vaultRoot == 0, REVERT_MSG);
        require(vaultTreeHeight == 0, REVERT_MSG);
        require(orderRoot == 0, REVERT_MSG);
        require(orderTreeHeight == 0, REVERT_MSG);
    }
}