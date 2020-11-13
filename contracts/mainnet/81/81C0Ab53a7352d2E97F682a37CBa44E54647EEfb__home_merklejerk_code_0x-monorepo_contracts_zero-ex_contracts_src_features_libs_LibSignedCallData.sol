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

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";


/// @dev Library for working with signed calldata.
library LibSignedCallData {
    using LibBytesV06 for bytes;

    // bytes4(keccak256('SignedCallDataSignature(bytes)'))
    bytes4 constant private SIGNATURE_SELECTOR = 0xf86d1d92;

    /// @dev Try to parse potentially signed calldata into its hash and signature
    ///      components. Signed calldata has signature data appended to it.
    /// @param callData the raw call data.
    /// @return callDataHash If a signature is detected, this will be the hash of
    ///         the bytes preceding the signature data. Otherwise, this
    ///         will be the hash of the entire `callData`.
    /// @return signature The signature bytes, if present.
    function parseCallData(bytes memory callData)
        internal
        pure
        returns (bytes32 callDataHash, bytes memory signature)
    {
        // Signed calldata has a 70 byte signature appended as:
        // ```
        //   abi.encodePacked(
        //     callData,
        //     bytes4(keccak256('SignedCallDataSignature(bytes)')),
        //     signature // 66 bytes
        //   );
        // ```

        // Try to detect an appended signature. This isn't foolproof, but an
        // accidental false positive should highly unlikely. Additinally, the
        // signature would also have to pass verification, so the risk here is
        // low.
        if (
            // Signed callData has to be at least 70 bytes long.
            callData.length < 70 ||
            // The bytes4 at offset -70 should equal `SIGNATURE_SELECTOR`.
            SIGNATURE_SELECTOR != callData.readBytes4(callData.length - 70)
        ) {
            return (keccak256(callData), signature);
        }
        // Consider everything before the signature selector as the original
        // calldata and everything after as the signature.
        assembly {
            callDataHash := keccak256(add(callData, 32), sub(mload(callData), 70))
        }
        signature = callData.slice(callData.length - 66, callData.length);
    }
}
