/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Bitmap {
    uint32 constant width = 10;
    uint32 constant height = 10;
    uint32 constant bit_count = 24;
    uint32 constant total_header_size = 54;
    uint32 constant bi_size = 40;
    uint32 constant width_in_bytes = 32; // ((width * bit_count + 31) / 32) * 4
    uint32 constant image_size = 320; // width_in_bytes * height
    uint32 constant file_size = 374; // total_header_size + image_size

    function createRandom(bytes memory seed)
        internal
        pure
        returns (uint16[] memory)
    {
        // 50 (unique bytes, not including mirror bytes) + (3 * 6) (3 colors, each requiring 6 random numbers)
        uint8 len = 68;
        uint16[] memory random = new uint16[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            seed = abi.encodePacked(keccak256(seed));
            uint16 rand = uint16(uint256(keccak256(seed)));
            random[idx] = rand - (rand / 100) * 100; // Between 0-100
        }
        return random;
    }

    function createImage(uint16[] memory random)
        internal
        pure
        returns (uint8[] memory)
    {
        uint32 half = width / 2;

        uint8 idx;
        uint8 randomIdx;
        uint8[] memory image = new uint8[](100);
        for (uint8 y = 0; y < height; y++) {
            for (uint8 x = 0; x < half; x++) {
                uint16 randomWord = random[randomIdx];
                uint8 pixelType = uint8((randomWord * 23) / 1000); // 43% foreground, 43% background, 14% spot
                image[idx] = pixelType;
                idx++;
                randomIdx++;
            }

            // Mirror
            for (uint8 x = 0; x < half; x++) {
                image[idx] = image[idx - ((2 * x) + 1)];
                idx++;
            }
        }
        return image;
    }

    function createColor(uint16[] memory random, uint8 idx)
        internal
        pure
        returns (uint8[3] memory)
    {
        uint8 offset = 0;
        uint16 hue = (uint16(random[idx + offset]) * 36) / 10; // Between 0-360
        offset++;
        uint16 saturation = ((uint16(random[idx + offset]) * 6) + 400) / 10; // Between 40-100
        offset++;

        // Between 0-100 but probabilities are a bell curve around 50%
        uint16 lightness =
            (uint16(
                (random[idx + offset] +
                    random[idx + offset + 1] +
                    random[idx + offset + 2] +
                    random[idx + offset + 3])
            ) * 25) / 100;
        (uint8 r, uint8 b, uint8 g) =
            Color.hslToRgb(hue, saturation, lightness);
        return [r, g, b];
    }

    function generate(bytes memory seed)
        public
        pure
        returns (bytes memory bitmap)
    {
        uint16[] memory random = createRandom(seed);
        uint8[] memory image = createImage(random);

        uint8[3] memory color0 = createColor(random, 50);
        uint8[3] memory color1 = createColor(random, 56);
        uint8[3] memory color2 = createColor(random, 62);

        assembly {
            let data := mload(0x40)
            mstore(data, file_size)
            mstore8(add(data, add(0x20, 0x0)), 0x42) // B
            mstore8(add(data, add(0x20, 0x1)), 0x4D) // M

            mstore8(add(data, add(0x20, 0x2)), file_size)
            mstore8(add(data, add(0x20, 0xa)), total_header_size)

            mstore8(add(data, add(0x20, 0xe)), bi_size)
            mstore8(add(data, add(0x20, 0x12)), width)
            mstore8(add(data, add(0x20, 0x16)), height)

            mstore8(add(data, add(0x20, 0x1a)), 1)
            mstore8(add(data, add(0x20, 0x1c)), bit_count)
            mstore8(add(data, add(0x20, 0x22)), image_size)

            let idx := 0
            for {
                let row := height
            } gt(row, 0) {
                row := sub(row, 1)
            } {
                for {
                    let col := 0
                } lt(col, height) {
                    col := add(col, 1)
                } {
                    let pos := add(
                        0x36,
                        add(mul(sub(row, 1), width_in_bytes), mul(col, 3))
                    )

                    let color := color0
                    switch mload(add(image, add(0x20, mul(idx, 0x20))))
                        case 0 {
                            color := color0
                        }
                        case 1 {
                            color := color1
                        }
                        case 2 {
                            color := color2
                        }

                    mstore8(
                        add(data, add(0x20, add(pos, 0))),
                        mload(add(color, mul(2, 0x20)))
                    )
                    mstore8(
                        add(data, add(0x20, add(pos, 1))),
                        mload(add(color, mul(1, 0x20)))
                    )
                    mstore8(
                        add(data, add(0x20, add(pos, 2))),
                        mload(add(color, mul(0, 0x20)))
                    )

                    idx := add(idx, 1)
                }
            }

            mstore(0x40, add(data, add(32, file_size)))
            bitmap := data
        }
    }

    function encoded(bytes memory seed) public pure returns (string memory) {
        return Base64.encode(generate(seed));
    }

    function uri(bytes memory seed) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/bmp;base64,",
                    Base64.encode(generate(seed))
                )
            );
    }
}

library Base64 {
    bytes private constant base64stdchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // bytes constant private base64urlchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function encode(bytes memory _bs) internal pure returns (string memory) {
        uint256 rem = _bs.length % 3;

        uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= _bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(_bs[i]),
                uint8(_bs[i + 1]),
                uint8(_bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(_bs[_bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(_bs[_bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, ) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64stdchars[c0];
        b1 = base64stdchars[c1];
        b2 = base64stdchars[c2];
        b3 = base64stdchars[c3];
    }
}

library Color {
    function hslToRgb(
        uint256 hue,
        uint256 sat,
        uint256 lum
    )
        public
        pure
        returns (
            uint8 r,
            uint8 g,
            uint8 b
        )
    {
        hue = (hue * 100 * 255) / 36000;
        sat = (sat * 255) / 100;
        lum = (lum * 255) / 100;
        uint256 v =
            (lum < 128)
                ? (lum * (256 + sat)) >> 8
                : (((lum + sat) << 8) - lum * sat) >> 8;
        if (v <= 0) {
            r = 0;
            g = 0;
            b = 0;
        } else {
            hue = hue * 6;
            uint256 m = lum * 2 - v;
            uint256 sextant = hue >> 8;
            uint256 fract = hue - (sextant << 8);
            uint256 vsf = ((v * fract * (v - m)) / v) >> 8;
            uint256 mid1 = m + vsf;
            uint256 mid2 = v - vsf;
            assembly {
                switch sextant
                    case 0 {
                        r := v
                        g := mid1
                        b := m
                    }
                    case 1 {
                        r := mid2
                        g := v
                        b := m
                    }
                    case 2 {
                        r := m
                        g := v
                        b := mid1
                    }
                    case 3 {
                        r := m
                        g := mid2
                        b := v
                    }
                    case 4 {
                        r := mid1
                        g := m
                        b := v
                    }
                    case 5 {
                        r := v
                        g := m
                        b := mid2
                    }
            }
        }
    }
}