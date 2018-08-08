pragma solidity ^0.4.23;

// converting to bech32/base32 w/ no checksum
library Base32Lib {
    // see https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki#bech32 for alphabet
    bytes constant ALPHABET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

    // modified toBase58 impl from https://github.com/MrChico/verifyIPFS/blob/b4bfb3df52e7e012a4ef668c6b3dbc038f881fd9/contracts/verifyIPFS.sol
    // MIT Licensed - https://github.com/MrChico/verifyIPFS/blob/b4bfb3df52e7e012a4ef668c6b3dbc038f881fd9/LICENSE
    function toBase32(bytes source) internal pure returns (bytes) {
        if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](40); //TODO: figure out exactly how much is needed
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint8 i = 0; i < source.length; ++i) {
            uint carry = uint8(source[i]);
            for (uint8 j = 0; j < digitlength; ++j) {
                carry += uint(digits[j]) * 256;
                digits[j] = uint8(carry % 32);
                carry = carry / 32;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 32);
                digitlength++;
                carry = carry / 32;
            }
        }
        //return digits;
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function truncate(uint8[] array, uint8 length) pure internal returns (uint8[]) {
        uint8[] memory output = new uint8[](length);
        for (uint8 i = 0; i<length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] input) pure internal returns (uint8[]) {
        uint8[] memory output = new uint8[](input.length);
        for (uint8 i = 0; i<input.length; i++) {
            output[i] = input[input.length-1-i];
        }
        return output;
    }

    function toAlphabet(uint8[] indices) pure internal returns (bytes) {
        bytes memory output = new bytes(indices.length);
        for (uint8 i = 0; i<indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }
}