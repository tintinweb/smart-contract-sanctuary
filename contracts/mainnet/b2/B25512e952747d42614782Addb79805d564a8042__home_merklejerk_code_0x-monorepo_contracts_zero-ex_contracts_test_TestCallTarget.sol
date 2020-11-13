/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;


contract TestCallTarget {

    event CallTargetCalled(
        address context,
        address sender,
        bytes data,
        uint256 value
    );

    bytes4 private constant MAGIC_BYTES = 0x12345678;
    bytes private constant REVERTING_DATA = hex"1337";

    fallback() external payable {
        if (keccak256(msg.data) == keccak256(REVERTING_DATA)) {
            revert("TestCallTarget/REVERT");
        }
        emit CallTargetCalled(
            address(this),
            msg.sender,
            msg.data,
            msg.value
        );
        bytes4 rval = MAGIC_BYTES;
        assembly {
            mstore(0, rval)
            return(0, 32)
        }
    }
}
