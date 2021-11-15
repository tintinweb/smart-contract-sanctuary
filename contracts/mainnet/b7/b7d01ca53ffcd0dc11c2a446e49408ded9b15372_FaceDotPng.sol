// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./base64.sol";
import "./render.sol";


library Bitfield {
    function setBit(bytes32 self, uint8 bit) internal pure returns (bytes32) {
        return self | bytes32(1 << (255 - bit));
    }

    function getBit(bytes32 self, uint8 bit) internal pure returns (bool) {
        return uint256((self << bit) >> 255) == 1;
    }
}

contract Measurable {
    event Measurement(
        string name,
        uint256 gas
    );

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(1 != chainId);
    }

    modifier measured(string memory name) {
        uint256 before = gasleft();
        _;
        emit Measurement(name, before - gasleft());
    }
}

library TokenAttributes {
    /*
    +-------+----------+-------+-------+-------+
    | color | negative | left  | nose  | right |
    +-------+----------+-------+-------+-------+
    | uint7 | uint1    | uint8 | uint8 | uint8 |
    +-------+----------+-------+-------+-------+
    */

    function newFace(
        bool negative,
        uint8 color,
        uint8 leftEye,
        uint8 nose,
        uint8 rightEye
    ) internal pure returns (uint32) {
        uint32 face = (uint32(color) << 25)
            | (uint32(leftEye) << 16)
            | (uint32(nose) << 8)
            | uint32(rightEye);

        if (negative) {
            face |= 0x01000000;
        }

        return face;
    }

    function faceColor(uint32 self) internal pure returns (uint8) {
        return uint8(self >> 25);
    }

    function faceNegative(uint32 self) internal pure returns (bool) {
        return 0 != (self & 0x01000000);
    }

    function faceLeftEye(uint32 self) internal pure returns (uint8) {
        return uint8(self >> 16);
    }

    function faceRightEye(uint32 self) internal pure returns (uint8) {
        return uint8(self);
    }

    function faceNose(uint32 self) internal pure returns (uint8) {
        return uint8(self >> 8);
    }

    function faceBit(uint32 self) internal pure returns (uint8) {
        unchecked {
            return uint8(self >> 16) + (7 * uint8(self >> 8)) + (21 * uint8(self));
        }
    }
}

abstract contract Attributes {
    using TokenAttributes for uint32;
    using Bitfield for bytes32;

    uint8 constant internal COLORS = 7;
    uint8 constant internal EYES = 7;
    uint8 constant internal NOSES = 3;

    bytes32 internal unique;

    function takeFace(bytes32 input, uint32 face) private pure returns (bool success, bytes32 output) {
        uint8 bit = face.faceBit();

        if (input.getBit(bit)) {
            success = false;
            output = input;
        } else {
            success = true;
            output = input.setBit(bit);
        }
    }

    // (274 bytes)
    function pickEye(uint8 seed) private pure returns (uint8) {
        if (seed < 80) return 0;
        if (seed < 144) return 1;
        if (seed < 184) return 2;
        if (seed < 224) return 3;
        if (seed < 246) return 4;
        if (seed < 254) return 5;
        return 6;
    }

    // (98 bytes)
    function pickNose(uint8 seed) private pure returns (uint8) {
        if (seed < 156) return 0;
        if (seed < 244) return 1;
        return 2;
    }

    // (137 bytes)
    function pickColor(uint8 seed) private pure returns (uint8) {
        return seed % COLORS;
    }

    // (20 bytes)
    function pickNegative(uint8 seed) private pure returns (bool) {
        return seed >= 254;
    }

    function pickFace(bytes32 seed) private pure returns (uint32) {
        return TokenAttributes.newFace(
            pickNegative(uint8(seed[0])),
            pickColor(uint8(seed[1])),
            pickEye(uint8(seed[2])),
            pickNose(uint8(seed[3])),
            pickEye(uint8(seed[4]))
        );
    }

    function random(bytes32 uni) private view returns (bytes32) {
        // Oh look, random number generation on-chain. What could go wrong?

        unchecked {
            uint256 bitfield;


            for (uint ii = 1; ii < 257; ii++) {
                uint256 bits = uint256(blockhash(block.number - ii));
                bitfield |= bits & (1 << (ii - 1));
            }

            uint256 value = uint256(keccak256(abi.encodePacked(bytes32(bitfield))));
            value ^= uint256(keccak256(abi.encodePacked(uni)));

            return bytes32(value);
        }
    }

    function roll() internal returns (uint32) {
        bytes32 mem = unique;
        bytes32 seed = random(mem);

        bool success;
        uint32 face;

        while (true) {
            face = pickFace(seed);

            (success, mem) = takeFace(mem, face);

            if (success) {
                break;
            }

            seed = keccak256(abi.encodePacked(seed));
        }

        unique = mem;
        return face;
    }

    function steal(uint32 face) internal {
        bool success;
        (success, unique) = takeFace(unique, face);
        require(success, "nice try");
    }
}

contract FaceDotPng is Attributes, ERC721, Ownable {
    using TokenAttributes for uint32;

    bytes constant private COLOR_VALUES = hex"cc0000f15d2264cf00006fff2222ccad7fa834e2e2";

    Render immutable public RENDERER;

    uint256 public price = 130000000000000;

    constructor(Render renderer) ERC721("face.png", "PNG") {
        RENDERER = renderer;

        // My avatar.
        genesisSteal(msg.sender, 0xc020000);
    }

    // (357 bytes)
    function color(uint8 index, bool negative) private pure returns (bytes3) {
        index *= 3;
        uint24 result =
            (uint24(uint8(COLOR_VALUES[index])) << 16)
            | (uint24(uint8(COLOR_VALUES[index + 1])) << 8)
            | uint24(uint8(COLOR_VALUES[index + 2]));

        if (negative) {
            result = ~result;
        }

        return bytes3(result);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "PNG: nonexistent");

        uint32 face = uint32(tokenId);
        bool isNegative = face.faceNegative();

        bytes3 bg = bytes3(isNegative ? 0xFFFFFF : 0x000000);

        bytes memory png = RENDERER.png(
            bg,
            color(face.faceColor(), isNegative),
            face.faceLeftEye(),
            face.faceNose(),
            face.faceRightEye()
        );

        bytes memory svg = abi.encodePacked(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
            "<svg version=\"1.1\" viewBox=\"0 0 48 48\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">"
            "<image style=\"image-rendering:crisp-edges;image-rendering:pixelated\" xlink:href=\"data:image/png;base64,",
            Base64.encode(png),
            "\"/></svg>"
        );

        bytes memory name = abi.encodePacked(
            RENDERER.eyeName(face.faceLeftEye()),
            RENDERER.noseName(face.faceNose()),
            RENDERER.eyeName(face.faceRightEye()),
            ".png"
        );

        bytes memory json = abi.encodePacked(
            "{\"description\":\"\",\"name\":\"",
            name,
            "\",\"attributes\":[{\"trait_type\":\"Left Eye\",\"value\":\"",
            RENDERER.eyeName(face.faceLeftEye()),
            "\"},{\"trait_type\":\"Nose\",\"value\":\"",
            RENDERER.noseName(face.faceNose()),
            "\"},{\"trait_type\":\"Right Eye\",\"value\":\"",
            RENDERER.eyeName(face.faceRightEye()),
            "\"},{\"trait_type\":\"Base Color\",\"value\":\"",
            face.faceColor() + 48, // Convert to ASCII digit.
            "\"},{\"trait_type\":\"Negative\",\"value\":\"",
            face.faceNegative() ? "Yes" : "No",
            "\"}],\"image\":\"data:image/svg+xml;base64,",
            Base64.encode(svg),
            "\"}"
        );

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(json)
        ));
    }

    function genesisSteal(address to, uint32 face) private {
        steal(face);
        _mint(to, face);
    }

    function preMint() private returns (uint256) {
        require(msg.sender == tx.origin, "EOAs only"); // fuck 3074
        require(msg.value >= price, "not enough");
        price = (price * 1082) / 1000;
        return roll();
    }

    function mint(address to) external payable {
        _mint(to, preMint());
    }

    function safeMint(address to) external payable {
        _safeMint(to, preMint());
    }

    function withdraw(address payable to) external onlyOwner {
        (bool success,) = to.call{value:address(this).balance}("");
        require(success, "could not send");
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

