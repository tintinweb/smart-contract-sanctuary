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


/// @dev Feature for validating signatures.
interface ISignatureValidatorFeature {

   /// @dev Allowed signature types.
    enum SignatureType {
        Illegal,                     // 0x00, default value
        Invalid,                     // 0x01
        EIP712,                      // 0x02
        EthSign,                     // 0x03
        NSignatureTypes              // 0x04, number of signature types. Always leave at end.
    }

    /// @dev Validate that `hash` was signed by `signer` given `signature`.
    ///      Reverts otherwise.
    /// @param hash The hash that was signed.
    /// @param signer The signer of the hash.
    /// @param signature The signature. The last byte of this signature should
    ///        be a member of the `SignatureType` enum.
    function validateHashSignature(
        bytes32 hash,
        address signer,
        bytes calldata signature
    )
        external
        view;

    /// @dev Check that `hash` was signed by `signer` given `signature`.
    /// @param hash The hash that was signed.
    /// @param signer The signer of the hash.
    /// @param signature The signature. The last byte of this signature should
    ///        be a member of the `SignatureType` enum.
    /// @return isValid `true` on success.
    function isValidHashSignature(
        bytes32 hash,
        address signer,
        bytes calldata signature
    )
        external
        view
        returns (bool isValid);
}
