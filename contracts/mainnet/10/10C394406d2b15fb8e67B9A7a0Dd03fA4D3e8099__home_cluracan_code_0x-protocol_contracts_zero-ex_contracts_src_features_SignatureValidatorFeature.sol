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

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "../errors/LibSignatureRichErrors.sol";
import "../fixins/FixinCommon.sol";
import "../migrations/LibMigrate.sol";
import "./ISignatureValidatorFeature.sol";
import "./IFeature.sol";


/// @dev Feature for validating signatures.
contract SignatureValidatorFeature is
    IFeature,
    ISignatureValidatorFeature,
    FixinCommon
{
    using LibBytesV06 for bytes;
    using LibRichErrorsV06 for bytes;

    /// @dev Exclusive upper limit on ECDSA signatures 'R' values.
    ///      The valid range is given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
    /// @dev Exclusive upper limit on ECDSA signatures 'S' values.
    ///      The valid range is given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "SignatureValidator";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate()
        external
        returns (bytes4 success)
    {
        _registerFeatureFunction(this.validateHashSignature.selector);
        _registerFeatureFunction(this.isValidHashSignature.selector);
        return LibMigrate.MIGRATE_SUCCESS;
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
        bytes memory signature
    )
        public
        override
        view
    {
        SignatureType signatureType = _readValidSignatureType(
            hash,
            signer,
            signature
        );

        // TODO: When we support non-hash signature types, assert that
        // `signatureType` is only `EIP712` or `EthSign` here.

        _validateHashSignatureTypes(
            signatureType,
            hash,
            signer,
            signature
        );
    }

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
        override
        returns (bool isValid)
    {
        // HACK: `validateHashSignature()` is stateless so we can just perform
        // a staticcall against the implementation contract. This avoids the
        // overhead of going through the proxy. If `validateHashSignature()` ever
        // becomes stateful this would need to change.
        (isValid, ) = _implementation.staticcall(
            abi.encodeWithSelector(
                this.validateHashSignature.selector,
                hash,
                signer,
                signature
            )
        );
    }

    /// @dev Validates a hash-only signature type. Low-level, hidden variant.
    /// @param signatureType The type of signature to check.
    /// @param hash The hash that was signed.
    /// @param signer The signer of the hash.
    /// @param signature The signature. The last byte of this signature should
    ///        be a member of the `SignatureType` enum.
    function _validateHashSignatureTypes(
        SignatureType signatureType,
        bytes32 hash,
        address signer,
        bytes memory signature
    )
        private
        pure
    {
        address recovered = address(0);
        if (signatureType == SignatureType.Invalid) {
            // Always invalid signature.
            // Like Illegal, this is always implicitly available and therefore
            // offered explicitly. It can be implicitly created by providing
            // a correctly formatted but incorrect signature.
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.ALWAYS_INVALID,
                hash,
                signer,
                signature
            ).rrevert();
        } else if (signatureType == SignatureType.EIP712) {
            // Signature using EIP712
            if (signature.length != 66) {
                LibSignatureRichErrors.SignatureValidationError(
                    LibSignatureRichErrors.SignatureValidationErrorCodes.INVALID_LENGTH,
                    hash,
                    signer,
                    signature
                ).rrevert();
            }
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            if (uint256(r) < ECDSA_SIGNATURE_R_LIMIT && uint256(s) < ECDSA_SIGNATURE_S_LIMIT) {
                recovered = ecrecover(
                    hash,
                    v,
                    r,
                    s
                );
            }
        } else if (signatureType == SignatureType.EthSign) {
            // Signed using `eth_sign`
            if (signature.length != 66) {
                LibSignatureRichErrors.SignatureValidationError(
                    LibSignatureRichErrors.SignatureValidationErrorCodes.INVALID_LENGTH,
                    hash,
                    signer,
                    signature
                ).rrevert();
            }
            uint8 v = uint8(signature[0]);
            bytes32 r = signature.readBytes32(1);
            bytes32 s = signature.readBytes32(33);
            if (uint256(r) < ECDSA_SIGNATURE_R_LIMIT && uint256(s) < ECDSA_SIGNATURE_S_LIMIT) {
                recovered = ecrecover(
                    keccak256(abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        hash
                    )),
                    v,
                    r,
                    s
                );
            }
        } else {
            // This should never happen.
            revert('SignatureValidator/ILLEGAL_CODE_PATH');
        }
        if (recovered == address(0) || signer != recovered) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.WRONG_SIGNER,
                hash,
                signer,
                signature
            ).rrevert();
        }
    }

    /// @dev Reads the `SignatureType` from the end of a signature and validates it.
    function _readValidSignatureType(
        bytes32 hash,
        address signer,
        bytes memory signature
    )
        private
        pure
        returns (SignatureType signatureType)
    {
        // Read the signatureType from the signature
        signatureType = _readSignatureType(
            hash,
            signer,
            signature
        );

        // Ensure signature is supported
        if (uint8(signatureType) >= uint8(SignatureType.NSignatureTypes)) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.UNSUPPORTED,
                hash,
                signer,
                signature
            ).rrevert();
        }

        // Always illegal signature.
        // This is always an implicit option since a signer can create a
        // signature array with invalid type or length. We may as well make
        // it an explicit option. This aids testing and analysis. It is
        // also the initialization value for the enum type.
        if (signatureType == SignatureType.Illegal) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.ILLEGAL,
                hash,
                signer,
                signature
            ).rrevert();
        }
    }

    /// @dev Reads the `SignatureType` from the end of a signature.
    function _readSignatureType(
        bytes32 hash,
        address signer,
        bytes memory signature
    )
        private
        pure
        returns (SignatureType sigType)
    {
        if (signature.length == 0) {
            LibSignatureRichErrors.SignatureValidationError(
                LibSignatureRichErrors.SignatureValidationErrorCodes.INVALID_LENGTH,
                hash,
                signer,
                signature
            ).rrevert();
        }
        return SignatureType(uint8(signature[signature.length - 1]));
    }
}
