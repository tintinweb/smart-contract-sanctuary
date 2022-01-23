// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./EllipticCurve.sol";
import "./UtilStrings.sol";

/// @dev This contract is compiled from a template file.
/// You can see the full template at https://github.com/noway/nzcp-sol/blob/main/templates/NZCP.sol
/// 
/// @title NZCP.sol
/// @author noway421.eth
/// @notice New Zealand COVID Pass verifier implementation in Solidity
///
/// Features:
/// - Verifies NZCP pass and returns the credential subject (givenName, familyName, dob)
/// - Reverts transaction if pass is invalid.
/// - To save gas, the full pass URI is not passed into the contract, but merely the ToBeSigned value.
///    * ToBeSigned value is enough to cryptographically prove that the pass is valid.
///    * The definition of ToBeSigned can be found here: https://datatracker.ietf.org/doc/html/rfc8152#section-4.4 
///
/// Assumptions:
/// - NZ Ministry of Health never going to sign any malformed CBOR
///    * This assumption relies on internal implementation of https://mycovidrecord.nz
/// - NZ Ministry of Health never going to sign any pass that is not active
///    * This assumption relies on internal implementation of https://mycovidrecord.nz
/// - NZ Ministry of Health never going to change the private-public key pair used to sign the pass
///    * This assumption relies on trusting NZ Ministry of Health not to leak their private key









































































/// @dev Start of the NZCP contract
contract NZCP is EllipticCurve, UtilStrings {


    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------


    error InvalidSignature();
    error PassExpired();
    // error UnexpectedCBORType();
    // error UnsupportedCBORUint();


    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------


    /// @dev A combination of buffer and position in that buffer
    /// So that we can easily seek it and find the right items
    struct Stream {
        bytes buffer;
        uint pos;
    }


    /// -----------------------------------------------------------------------
    /// Private CBOR functions
    /// -----------------------------------------------------------------------


    /// @dev Decode an unsigned integer from the stream
    /// @param stream The stream to decode from
    /// @param v The v value
    /// @return The decoded unsigned integer
    function decodeUint(Stream memory stream, uint v) private pure returns (uint) {
        uint x = v & 31;
        if (x <= 23) {
            return x;
        }
        else if (x == 24) {
            return uint8(stream.buffer[stream.pos++]);
        }
        // Commented out to save gas
        // else if (x == 25) { // 16-bit
        //     uint16 value;
        //     value = uint16(uint8(buffer[pos++])) << 8;
        //     value |= uint16(uint8(buffer[pos++]));
        //     return (pos, value);
        // }
        else if (x == 26) { // 32-bit
            uint32 value;
            value = uint32(uint8(stream.buffer[stream.pos++])) << 24;
            value |= uint32(uint8(stream.buffer[stream.pos++])) << 16;
            value |= uint32(uint8(stream.buffer[stream.pos++])) << 8;
            value |= uint32(uint8(stream.buffer[stream.pos++]));
            return value;
        }
        else {
            // this revert is not necessary // revert UnsupportedCBORUint();
        }
    }

    /// @dev Decode a string from the stream given stream and string length
    /// @param stream The stream to decode from
    /// @param len The length of the string
    /// @return The decoded string
    function decodeString(Stream memory stream, uint len) private pure returns (string memory) {
        string memory str = new string(len);

        uint strptr;
        // 32 is the length of the string header
        assembly { strptr := add(str, 32) }
        
        uint bufferptr;
        uint pos = stream.pos;
        bytes memory buffer = stream.buffer;
        // 32 is the length of the string header
        assembly { bufferptr := add(add(buffer, 32), pos) }

        memcpy(strptr, bufferptr, len);

        stream.pos += len;

        return str;
    }

    /// @dev Skip a CBOR value from the stream
    /// @param stream The stream to decode from
    function skipValue(Stream memory stream) private pure {
        (uint cbortype, uint v) = readType(stream);

        uint value;
        if (cbortype == 0) {
            value = decodeUint(stream, v);
        }
        // Commented out to save gas
        // else if (cbortype == 1) {
        //     value = decodeUint(stream, v);
        // }
        // Commented out to save gas
        // else if (cbortype == 2) {
        //     value = decodeUint(stream, v);
        //     pos += value;
        // }
        else if (cbortype == 3) {
            value = decodeUint(stream, v);
            stream.pos += value;
        }
        else if (cbortype == 4) {
            value = decodeUint(stream, v);
            for (uint i = 0; i++ < value;) {
                skipValue(stream);
            }
        }
        // Commented out to save gas
        // else if (cbortype == 5) {
        //     value = decodeUint(stream, v);
        //     for (uint i = 0; i++ < value;) {
        //         skipValue(stream);
        //         skipValue(stream);
        //     }
        // }
        else {
            // this revert is not necessary // revert UnexpectedCBORType();
        }
    }

    /// @dev Read the CBOR type from the stream
    /// @param stream The stream to decode from
    /// @return The CBOR type and the v value
    function readType(Stream memory stream) private pure returns (uint, uint) {
        uint v = uint8(stream.buffer[stream.pos++]);
        return (v >> 5, v);
    }

    /// @dev Read a CBOR string from the stream
    /// @param stream The stream to decode from
    /// @return The decoded string
    function readStringValue(Stream memory stream) private pure returns (string memory) {
        (uint value, uint v) = readType(stream);
        // this revert is not necessary // if (value != 3) revert  UnexpectedCBORType();
        value = decodeUint(stream, v);
        string memory str = decodeString(stream, value);
        return str;
    }

    /// @dev Read a CBOR map length from the stream
    /// @param stream The stream to decode from
    /// @return The decoded map length
    function readMapLength(Stream memory stream) private pure returns (uint) {
        (uint value, uint v) = readType(stream);
        // this revert is not necessary // if (value != 5) revert  UnexpectedCBORType();
        value = decodeUint(stream, v);
        return value;
    }


    /// -----------------------------------------------------------------------
    /// Private CWT functions
    /// -----------------------------------------------------------------------


    /// @dev Recursively search the position of credential subject in the CWT claims
    /// @param stream The stream to decode from
    /// @param pathindex The index of the credential subject path in the CWT claims tree
    /// @notice Side effects: reverts transaction if pass is expired.
    function findCredSubj(Stream memory stream, uint pathindex) private view {
        uint maplen = readMapLength(stream);

        for (uint i = 0; i++ < maplen;) {
            (uint cbortype, uint v) = readType(stream);

            uint value = decodeUint(stream, v);
            if (cbortype == 0) {
                if (value == 4) {
                    (cbortype, v) = readType(stream);
                    // this revert is not necessary // if (cbortype != 0) revert  UnexpectedCBORType();

                    // check if pass expired
                    if (block.timestamp >= decodeUint(stream, v)) revert  PassExpired();
                }
                // We do not check for whether pass is active, since we assume
                // That the NZ Ministry of Health only issues active passes
                else {
                    skipValue(stream);
                }
            }
            else if (cbortype == 3) {
                if (keccak256(abi.encodePacked(decodeString(stream, value))) == [bytes32(0x6ec613b793842434591077d5267660b73eca3bb163edb2574938d0a1b9fed380), bytes32(0xf888b25396a7b641f052b4f483e19960c8cb98c3e8f094f00faf41fffd863fda)][pathindex]) {
                    if (pathindex >= 1) {
                        return;
                    }
                    else {
                        return findCredSubj(stream, pathindex + 1);
                    }
                }
                else {
                    skipValue(stream);
                }
            }
            else {
                // this revert is not necessary // revert UnexpectedCBORType();
            }
        }
    }

    /// @dev Decode credential subject from the stream
    /// @param stream The stream to decode from
    /// @return The decoded credential subject (givenName, familyName, dob)
    function decodeCredSubj(Stream memory stream) private pure returns (string memory, string memory, string memory) {
        uint maplen = readMapLength(stream);

        string memory givenName;
        string memory familyName;
        string memory dob;

        string memory key;
        for (uint i = 0; i++ < maplen;) {
            key = readStringValue(stream);

            if (keccak256(abi.encodePacked(key)) == 0xa3f2ad40900c663841a16aacd4bc622b021d6b2548767389f506dbe65673c3b9) {
                givenName = readStringValue(stream);
            }
            else if (keccak256(abi.encodePacked(key)) == 0xd7aa1fd5ef0cc1f1e7ce8b149fdb61f373714ea1cc3ad47c597f4d3e554d10a4) {
                familyName = readStringValue(stream);
            }
            else if (keccak256(abi.encodePacked(key)) == 0x635ec02f32ae461b745f21d9409955a9b5a660b486d30e7b5d4bfda4a75dec80) {
                dob = readStringValue(stream);
            }
            else {
                skipValue(stream);
            }
        }
        return (givenName, familyName, dob);
    }

    
    /// -----------------------------------------------------------------------
    /// Public contract functions for example passes
    /// -----------------------------------------------------------------------


    /// @dev Verify the signature of the message hash of the ToBeSigned value of an example NZCP pass
    /// @param messageHash The message hash of ToBeSigned value
    /// @param rs The r and s values of the signature
    /// @return True if the signature is valid, reverts transaction otherwise
    function verifySignExample(bytes32 messageHash, uint256[2] memory rs) public pure returns (bool) {
        if (!validateSignature(messageHash, rs, [0xCD147E5C6B02A75D95BDB82E8B80C3E8EE9CAA685F3EE5CC862D4EC4F97CEFAD, 0x22FE5253A16E5BE4D1621E7F18EAC995C57F82917F1A9150842383F0B4A4DD3D])) revert  InvalidSignature();
        return true;
    }

    /// @dev Verifies the signature, parses the ToBeSigned value and returns the credential subject of an example NZCP pass
    /// @param ToBeSigned The ToBeSigned value as per https://datatracker.ietf.org/doc/html/rfc8152#section-4.4
    /// @param rs The r and s values of the signature
    /// @return credential subject (givenName, familyName, dob) if pass is valid, reverts transaction otherwise
    function readCredSubjExample(bytes memory ToBeSigned, uint256[2] memory rs) public view 
        returns (string memory, string memory, string memory) {

        verifySignExample(sha256(ToBeSigned), rs);

        Stream memory stream = Stream(ToBeSigned, 27); 

        findCredSubj(stream, 0);
        return decodeCredSubj(stream);
    }
    

    
}