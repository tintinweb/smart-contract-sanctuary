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

contract CpuPublicInputOffsets {
    // The following constants are offsets of data expected in the public input.
    uint256 internal constant OFFSET_LOG_N_STEPS = 0;
    uint256 internal constant OFFSET_RC_MIN = 1;
    uint256 internal constant OFFSET_RC_MAX = 2;
    uint256 internal constant OFFSET_LAYOUT_CODE = 3;
    uint256 internal constant OFFSET_PROGRAM_BEGIN_ADDR = 4;
    uint256 internal constant OFFSET_PROGRAM_STOP_PTR = 5;
    uint256 internal constant OFFSET_EXECUTION_BEGIN_ADDR = 6;
    uint256 internal constant OFFSET_EXECUTION_STOP_PTR = 7;
    uint256 internal constant OFFSET_OUTPUT_BEGIN_ADDR = 8;
    uint256 internal constant OFFSET_OUTPUT_STOP_PTR = 9;
    uint256 internal constant OFFSET_PEDERSEN_BEGIN_ADDR = 10;
    uint256 internal constant OFFSET_PEDERSEN_STOP_PTR = 11;
    uint256 internal constant OFFSET_RANGE_CHECK_BEGIN_ADDR = 12;
    uint256 internal constant OFFSET_RANGE_CHECK_STOP_PTR = 13;
    uint256 internal constant OFFSET_ECDSA_BEGIN_ADDR = 14;
    uint256 internal constant OFFSET_ECDSA_STOP_PTR = 15;
    uint256 internal constant OFFSET_CHECKPOINTS_BEGIN_PTR = 16;
    uint256 internal constant OFFSET_CHECKPOINTS_STOP_PTR = 17;
    uint256 internal constant OFFSET_N_PUBLIC_MEMORY_PAGES = 18;
    uint256 internal constant OFFSET_PUBLIC_MEMORY = 19;

    uint256 internal constant N_WORDS_PER_PUBLIC_MEMORY_ENTRY = 2;

    // The format of the public input, starting at OFFSET_PUBLIC_MEMORY is as follows:
    //   * For each page:
    //     * First address in the page (this field is not included for the first page).
    //     * Page size.
    //     * Page hash.
    //   * Padding cell address.
    //   * Padding cell value.
    //   # All data above this line, appears in the initial seed of the proof.
    //   * For each page:
    //     * Cumulative product.

    function getOffsetPageSize(uint256 pageId) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + 3 * pageId;
    }

    function getOffsetPageHash(uint256 pageId) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + 3 * pageId + 1;
    }

    function getOffsetPageAddr(uint256 pageId) internal pure returns (uint256) {
        require(pageId >= 1, "Address of page 0 is not part of the public input.");
        return OFFSET_PUBLIC_MEMORY + 3 * pageId - 1;
    }

    /*
      Returns the offset of the address of the padding cell. The offset of the padding cell value
      can be obtained by adding 1 to the result.
    */
    function getOffsetPaddingCell(uint256 nPages) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + 3 * nPages - 1;
    }

    function getOffsetPageProd(uint256 pageId, uint256 nPages) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + 3 * nPages + 1 + pageId;
    }

    function getPublicInputLength(uint256 nPages) internal pure returns (uint256) {
        return OFFSET_PUBLIC_MEMORY + 4 * nPages + 1;
    }

}
