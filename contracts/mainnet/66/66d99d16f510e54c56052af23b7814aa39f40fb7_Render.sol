/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

library Crc32 {
    bytes constant private TABLE = hex"0000000077073096ee0e612c990951ba076dc419706af48fe963a5359e6495a30edb883279dcb8a4e0d5e91e97d2d98809b64c2b7eb17cbde7b82d0790bf1d911db710646ab020f2f3b9714884be41de1adad47d6ddde4ebf4d4b55183d385c7136c9856646ba8c0fd62f97a8a65c9ec14015c4f63066cd9fa0f3d638d080df53b6e20c84c69105ed56041e4a26771723c03e4d14b04d447d20d85fda50ab56b35b5a8fa42b2986cdbbbc9d6acbcf94032d86ce345df5c75dcd60dcfabd13d5926d930ac51de003ac8d75180bfd0611621b4f4b556b3c423cfba9599b8bda50f2802b89e5f058808c60cd9b2b10be9242f6f7c8758684c11c1611dabb6662d3d76dc419001db710698d220bcefd5102a71b1858906b6b51f9fbfe4a5e8b8d4337807c9a20f00f9349609a88ee10e98187f6a0dbb086d3d2d91646c97e6635c016b6b51f41c6c6162856530d8f262004e6c0695ed1b01a57b8208f4c1f50fc45765b0d9c612b7e9508bbeb8eafcb9887c62dd1ddf15da2d498cd37cf3fbd44c654db261583ab551cea3bc0074d4bb30e24adfa5413dd895d7a4d1c46dd3d6f4fb4369e96a346ed9fcad678846da60b8d044042d7333031de5aa0a4c5fdd0d7cc95005713c270241aabe0b1010c90c20865768b525206f85b3b966d409ce61e49f5edef90e29d9c998b0d09822c7d7a8b459b33d172eb40d81b7bd5c3bc0ba6cadedb883209abfb3b603b6e20c74b1d29aead547399dd277af04db261573dc1683e3630b1294643b840d6d6a3e7a6a5aa8e40ecf0b9309ff9d0a00ae277d079eb1f00f93448708a3d21e01f2686906c2fef762575d806567cb196c36716e6b06e7fed41b7689d32be010da7a5a67dd4accf9b9df6f8ebeeff917b7be4360b08ed5d6d6a3e8a1d1937e38d8c2c44fdff252d1bb67f1a6bc57673fb506dd48b2364bd80d2bdaaf0a1b4c36034af641047a60df60efc3a867df55316e8eef4669be79cb61b38cbc66831a256fd2a05268e236cc0c7795bb0b4703220216b95505262fc5ba3bbeb2bd0b282bb45a925cb36a04c2d7ffa7b5d0cf312cd99e8b5bdeae1d9b64c2b0ec63f226756aa39c026d930a9c0906a9eb0e363f720767850500571395bf4a82e2b87a147bb12bae0cb61b3892d28e9be5d5be0d7cdcefb70bdbdf2186d3d2d4f1d4e24268ddb3f81fda836e81be16cdf6b9265b6fb077e118b7477788085ae6ff0f6a7066063bca11010b5c8f659efff862ae69616bffd3166ccf45a00ae278d70dd2ee4e0483543903b3c2a7672661d06016f74969474d3e6e77dbaed16a4ad9d65adc40df0b6637d83bf0a9bcae53debb9ec547b2cf7f30b5ffe9bdbdf21ccabac28a53b3933024b4a3a6bad03605cdd7069354de572923d967bfb3667a2ec4614ab85d681b022a6f2b94b40bbe37c30c8ea15a05df1b2d02ef8d";

    function table(uint index) private pure returns (uint32) {
        unchecked {
            index *= 4;

            uint32 result =
                uint32(uint8(TABLE[index    ])) << 24;
            result |= uint32(uint8(TABLE[index + 1])) << 16;
            result |= uint32(uint8(TABLE[index + 2])) << 8;
            result |= uint32(uint8(TABLE[index + 3]));
            return result;
        }
    }

    function crc32(bytes memory self, uint offset, uint end) internal pure {
        unchecked {
            uint32 crc = ~uint32(0);

            for (uint ii = offset; ii < end; ii++) {
                crc = (crc >> 8) ^ table((crc & 0xff) ^ uint8(self[ii]));
            }

            crc = ~crc;

            self[end    ] = bytes1(uint8(crc >> 24));
            self[end + 1] = bytes1(uint8(crc >> 16));
            self[end + 2] = bytes1(uint8(crc >> 8));
            self[end + 3] = bytes1(uint8(crc));
        }
    }
}

library Adler32 {
    uint32 constant private MOD = 65521;

    function adler32(bytes memory self, uint offset, uint end) internal pure {
        unchecked {
            uint32 a = 1;
            uint32 b = 0;

            // Process each byte of the data in order
            for (uint ii = offset; ii < end; ii++) {
                    a = (a + uint32(uint8(self[ii]))) % MOD;
                    b = (b + a) % MOD;
            }

            uint32 adler = (b << 16) | a;

            self[end    ] = bytes1(uint8(adler >> 24));
            self[end + 1] = bytes1(uint8(adler >> 16));
            self[end + 2] = bytes1(uint8(adler >> 8));
            self[end + 3] = bytes1(uint8(adler));
        }
    }
}

contract Render {
    using Crc32 for bytes;
    using Adler32 for bytes;

    uint constant private WIDTH_BYTES = 6;

    uint constant private WIDTH_PIXELS = WIDTH_BYTES * 8;
    uint constant private LINES = WIDTH_PIXELS;

    uint constant private SPRITES_PER_IMAGE = 3;
    uint constant private SPRITE_LINE_BYTES = WIDTH_BYTES / SPRITES_PER_IMAGE;
    uint constant private SPRITE_BYTES = LINES * SPRITE_LINE_BYTES;
    uint constant private SPRITE_LINE_MASK = 0xFFFF;

    uint8 constant public EYES = 7;

    bytes constant private EYES_X =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"700e"
        hex"381c"
        hex"1818"
        hex"0c30"
        hex"0e70"
        hex"07e0"
        hex"03c0"
        hex"03c0"
        hex"0660"
        hex"0e70"
        hex"1c30"
        hex"1818"
        hex"381c"
        hex"700e"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";

    bytes constant private EYES_CARET =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0180"
        hex"03c0"
        hex"07e0"
        hex"0e70"
        hex"1c38"
        hex"381c"
        hex"700e"
        hex"6006"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";


    bytes constant private EYES_O =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"07e0"
        hex"0ff0"
        hex"1c38"
        hex"1818"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"1818"
        hex"1c38"
        hex"0ff0"
        hex"07e0"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";


    bytes constant private EYES_0 =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"03c0"
        hex"0ff0"
        hex"1c38"
        hex"1818"
        hex"1818"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"300c"
        hex"1818"
        hex"1818"
        hex"1c38"
        hex"0ff0"
        hex"03c0"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";


    bytes constant private EYES_GT =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"3800"
        hex"3f00"
        hex"07c0"
        hex"01f8"
        hex"003c"
        hex"01f8"
        hex"07c0"
        hex"3f00"
        hex"3800"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";


    bytes constant private EYES_LT =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"001c"
        hex"00fc"
        hex"03e0"
        hex"1f80"
        hex"3c00"
        hex"1f80"
        hex"03e0"
        hex"00fc"
        hex"001c"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";


    bytes constant private EYES_CRY =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0004"
        hex"0004"
        hex"0002"
        hex"0002"
        hex"0002"
        hex"0006"
        hex"3ffe"
        hex"7ffc"
        hex"0630"
        hex"1818"
        hex"108c"
        hex"31c6"
        hex"21c6"
        hex"6086"
        hex"6006"
        hex"6006"
        hex"310e"
        hex"3ffc"
        hex"1e78"
        hex"0000"
        hex"0100"
        hex"0180"
        hex"0380"
        hex"0380"
        hex"0100"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";


    uint8 constant public NOSES = 3;

    bytes constant private NOSES_UNDERSCORE =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"7ffe"
        hex"7ffe"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";

    bytes constant private NOSES_PERIOD =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0180"
        hex"03c0"
        hex"0180"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";


    bytes constant private NOSES_CAT =
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"1818"
        hex"1818"
        hex"3818"
        hex"300c"
        hex"300c"
        hex"318c"
        hex"318c"
        hex"318c"
        hex"318c"
        hex"318c"
        hex"318c"
        hex"3bd8"
        hex"1e78"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000"
        hex"0000";


    bytes constant private HEADER =
        hex"89504e470d0a1a0a"                                       // PNG Signature
        hex"0000000d49484452000000300000003001030000006dcc6bc4"     // IHDR Chunk
        hex"00000006504c5445";                                      // PLTE Chunk (Partial)

    bytes constant private IDAT_PREFIX =
        hex"0000015b"                                               // Chunk Length
        hex"49444154"                                               // "IDAT"
        hex"7801015001affe";                                        // zlib header

    bytes constant private TRAILER = hex"0000000049454e44ae426082"; // IEND Chunk

    function eye(uint8 index) private pure returns (bytes memory) {
        require(index < EYES, "eye out of range");

        if (0 == index) {
            return EYES_0;
        } else if (1 == index) {
            return EYES_CARET;
        } else if (2 == index) {
            return EYES_O;
        } else if (3 == index) {
            return EYES_X;
        } else if (4 == index) {
            return EYES_GT;
        } else if (5 == index) {
            return EYES_LT;
        } else if (6 == index) {
            return EYES_CRY;
        } else {
            assert(true);
            return new bytes(0); // Unreachable?
        }
    }

    function eyeName(uint8 index) public pure returns (string memory) {
        require(index < EYES, "eye out of range");

        if (0 == index) {
            return "0";
        } else if (1 == index) {
            return "^";
        } else if (2 == index) {
            return "o";
        } else if (3 == index) {
            return "x";
        } else if (4 == index) {
            return ">";
        } else if (5 == index) {
            return "<";
        } else if (6 == index) {
            return "\u0ca5";
        } else {
            assert(true);
            return new string(0); // Unreachable?
        }
    }

    function nose(uint8 index) private pure returns (bytes memory) {
        require(index < NOSES, "nose out of range");

        if (0 == index) {
            return NOSES_UNDERSCORE;
        } else if (1 == index) {
            return NOSES_PERIOD;
        } else if (2 == index) {
            return NOSES_CAT;
        } else {
            assert(true);
            return new bytes(0); // Unreachable?
        }
    }

    function noseName(uint8 index) public pure returns (string memory) {
        require(index < NOSES, "nose out of range");

        if (0 == index) {
            return "_";
        } else if (1 == index) {
            return ".";
        } else if (2 == index) {
            return "\u03c9";
        } else {
            assert(true);
            return new string(0); // Unreachable?
        }
    }

    function render(bytes memory output, uint offset, uint8 leftEyeIndex, uint8 noseIndex, uint8 rightEyeIndex) private pure {
        unchecked {
            bytes memory sprite;

            sprite = eye(leftEyeIndex);

            for (uint line = 0; line < LINES; line++) {
                uint inOffset = line * SPRITE_LINE_BYTES;
                uint outOffset = 1 + (line * (WIDTH_BYTES + 1));

                for (uint column = 0; column < SPRITE_LINE_BYTES; column++) {
                    output[offset + outOffset + column] = sprite[inOffset + column];
                }
            }

            sprite = nose(noseIndex);

            for (uint line = 0; line < LINES; line++) {
                uint inOffset = line * SPRITE_LINE_BYTES;
                uint outOffset = 1 + SPRITE_LINE_BYTES + (line * (WIDTH_BYTES + 1));

                for (uint column = 0; column < SPRITE_LINE_BYTES; column++) {
                    output[offset + outOffset + column] = sprite[inOffset + column];
                }
            }

            sprite = eye(rightEyeIndex);

            for (uint line = 0; line < LINES; line++) {
                uint inOffset = line * SPRITE_LINE_BYTES;
                uint outOffset = 1 + (2 * SPRITE_LINE_BYTES) + (line * (WIDTH_BYTES + 1));

                for (uint column = 0; column < SPRITE_LINE_BYTES; column++) {
                    output[offset + outOffset + column] = sprite[inOffset + column];
                }
            }
        }
    }

    function png(bytes3 bg, bytes3 fg, uint8 leftEyeIndex, uint8 noseIndex, uint8 rightEyeIndex) external pure returns (bytes memory) {
        unchecked {
            uint length = HEADER.length
                + bg.length
                + fg.length
                + 4                         // PLTE CRC32
                + IDAT_PREFIX.length
                + LINES * (WIDTH_BYTES + 1) // Image Data
                + 4                         // zlib adler32
                + 4                         // IDAT CRC32
                + TRAILER.length;

            bytes memory output = new bytes(length);

            uint offset = 0;

            // Copy the static portion of the header.
            for (uint ii = 0; ii < HEADER.length; ii++) {
                output[offset++] = HEADER[ii];
            }

            // Copy the background color.
            for (uint ii = 0; ii < bg.length; ii++) {
                output[offset++] = bg[ii];
            }

            // Copy the foreground color.
            for (uint ii = 0; ii < fg.length; ii++) {
                output[offset++] = fg[ii];
            }

            // Compute the palette's checksum.
            output.crc32(HEADER.length - 4, offset);
            offset += 4;

            uint idat_data_offset = offset + 4;

            // Copy the IDAT prefix.
            for (uint ii = 0; ii < IDAT_PREFIX.length; ii++) {
                output[offset++] = IDAT_PREFIX[ii];
            }

            uint image_data_offset = offset;

            render(output, offset, leftEyeIndex, noseIndex, rightEyeIndex);

            offset += LINES * (WIDTH_BYTES + 1);

            output.adler32(image_data_offset, offset);
            offset += 4;

            output.crc32(idat_data_offset, offset);
            offset += 4;

            // Copy the trailer.
            for (uint ii = 0; ii < TRAILER.length; ii++) {
                output[offset++] = TRAILER[ii];
            }

            return output;
        }
    }
}