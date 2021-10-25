// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

/* solhint-disable quotes */

contract MeloBleepsTokenURI {
    string internal constant TABLE_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    bytes internal constant FREQUENCIES =
        hex"00198d001b12001cae001e6200203100221b00242200264800288f002af8002d8600303b00331900362300395b003cc4004061004435004844004c9000511d0055f0005b0c006076006633006c460072b60079890080c300886b00908700992000a23a00abe000b61800c0ec00cc6500d88d00e56d00f3110101850110d601210f01323f0144750157c0016c310181d90198ca01b11901cada01e62302030b0221ab02421e02647e0288ea02af8002d8620303b10331940362320395b403cc4604061604435704843c04c8fc0511d4055f0005b0c306076306632906c464072b6707988b080c2c0886ad0908770991f90a23a80abe000b61860c0ec5";

    // settings for sound quality
    uint256 internal constant SAMPLE_RATE = 11000;
    uint256 internal constant BYTES_PER_SAMPLE = 1;

    // constants for ensuring enough precision when computing values
    int256 internal constant ONE = 1000000;
    int256 internal constant TWO = 2000000; // 2 * ONE;
    int256 internal constant HALF = 500000; // ONE/ 2;
    int256 internal constant ZERO7 = 700000; // (ONE * 7) / 10;
    int256 internal constant ZERO3 = 300000; // (ONE * 3) / 10;
    int256 internal constant ZERO1 = 100000; //(ONE * 1) / 10;
    int256 internal constant ZERO3125 = 312500; //( ONE * 3125) / 10000;
    int256 internal constant ZERO8750 = 875000; // (ONE * 8750) / 10000;
    int256 internal constant MINUS_ONE = -1000000; //; -ONE;
    int256 internal constant MIN_VALUE = MINUS_ONE + 1;
    int256 internal constant MAX_VALUE = ONE - 1;

    // allow to switch sign in assembly via mul(MINUS, x)
    int256 internal constant MINUS = -1;

    // sample rate: 22050 , bitsPerSample: 16bit
    // bytes internal constant metadataStart =
    //     'data:application/json,{"name":"__________________________________","description":"A_sound_fully_generated_onchain","external_url":"?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????","image":"data:image/svg+xml,<svg viewBox=\'0 0 32 16\' ><text x=\'50%\' y=\'50%\' dominant-baseline=\'middle\' text-anchor=\'middle\' style=\'fill: rgb(219, 39, 119); font-size: 12px;\'>__________________________________</text></svg>","animation_url":"data:audio/wav;base64,UklGRgAAAABXQVZFZm10IBAAAAABAAEAIlYAAESsAAACABAAZGF0YQAA'; // missing 2 zero bytes

    // sample rate: 11000 , bitsPerSample: 16bit
    // bytes internal constant metadataStart =
    // 'data:application/json,{"name":"__________________________________","description":"A_sound_fully_generated_onchain","external_url":"?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????","image":"data:image/svg+xml,<svg viewBox=\'0 0 32 16\' ><text x=\'50%\' y=\'50%\' dominant-baseline=\'middle\' text-anchor=\'middle\' style=\'fill: rgb(219, 39, 119); font-size: 12px;\'>__________________________________</text></svg>","animation_url":"data:audio/wav;base64,UklGRgAAAABXQVZFZm10IBAAAAABAAEA+CoAAPBVAAACABAAZGF0YQAA'; // missing 2 zero bytes

    // sample rate: 11000 , bitsPerSample: 8bit
    // bytes internal constant metadataStart =
    //     'data:application/json,{"name":"__________________________________","description":"A_sound_fully_generated_onchain","external_url":"?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????","image":"data:image/svg+xml,<svg viewBox=\'0 0 32 16\' ><text x=\'50%\' y=\'50%\' dominant-baseline=\'middle\' text-anchor=\'middle\' style=\'fill: rgb(219, 39, 119); font-size: 12px;\'>__________________________________</text></svg>","animation_url":"data:audio/wav;base64,UklGRgAAAABXQVZFZm10IBAAAAABAAEA+CoAAPBVAAABAAgAZGF0YQAA'; // missing 2 zero bytes

    function wav(bytes32 d1, bytes32 d2) external view returns (string memory) {
        return _generateWav(d1, d2);
    }

    function _prepareBuffer(bytes memory buffer) internal pure returns (uint256 l) {
        bytes memory start = bytes.concat(
            'data:application/json,{"name":"',
            "hello",
            '","description":"A_sound_fully_generated_onchain","external_url":"',
            "https://hello",
            "\",\"image\":\"data:image/svg+xml,<svg viewBox='0 0 32 16' ><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' style='fill: rgb(219, 39, 119); font-size: 12px;'>",
            "hello",
            '</text></svg>","animation_url":"data:audio/wav;base64,UklGRgAAAABXQVZFZm10IBAAAAABAAEA+CoAAPBVAAABAAgAZGF0YQAA'
        ); // missing 2 zero bytes
        uint256 len = start.length;
        uint256 src;
        uint256 dest;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            src := add(start, 0x20)
            dest := add(buffer, 0x20)
        }
        for (; len >= 32; len -= 32) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        // TODO remove that step by ensuring the length is a multiple of 32 bytes
        uint256 mask = 256**(32 - len) - 1;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return start.length;
    }

    function _finishBuffer(
        bytes memory buffer,
        uint256 resultPtr,
        uint256 tablePtr,
        uint256 numSamplesPlusOne,
        uint256 startLength
    ) internal pure {
        // write ends + size in buffer
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore8(resultPtr, 0x22) // "
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, 0x7D) // }
            resultPtr := add(resultPtr, 1)
            mstore(buffer, sub(sub(resultPtr, buffer), 32))
        }

        // compute chnksize (TODO hardcode)
        uint256 filesizeMinus8 = ((numSamplesPlusOne - 1) * 2 + 44) - 8;
        uint256 chunkSize = filesizeMinus8 + 8 - 44;

        // filesize // 46 00 00
        resultPtr = startLength + 32 - 52;
        assembly {
            resultPtr := add(buffer, resultPtr)
            let v := shl(40, 0x46)
            v := add(v, shl(32, and(filesizeMinus8, 255)))
            v := add(v, shl(24, and(shr(8, filesizeMinus8), 255)))
            v := add(v, shl(16, and(shr(16, filesizeMinus8), 255)))
            v := add(v, shl(8, and(shr(24, filesizeMinus8), 255)))
            v := add(v, 0x57)
            // write 8 characters
            mstore8(resultPtr, mload(add(tablePtr, and(shr(42, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(36, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(30, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(24, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(18, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(12, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(6, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(v, 0x3F))))
        }

        // // // chunksize // 61 00 00
        resultPtr = startLength + 32 - 4;
        assembly {
            resultPtr := add(buffer, resultPtr)
            let v := shl(40, 0x61)
            v := add(v, shl(32, and(chunkSize, 255)))
            v := add(v, shl(24, and(shr(8, chunkSize), 255)))
            v := add(v, shl(16, and(shr(16, chunkSize), 255)))
            v := add(v, shl(8, and(shr(24, chunkSize), 255)))
            v := add(v, 0x57)
            // write 8 characters
            mstore8(resultPtr, mload(add(tablePtr, and(shr(42, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(36, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(30, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(24, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(18, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(12, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(shr(6, v), 0x3F))))
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, mload(add(tablePtr, and(v, 0x3F))))
        }
    }

    function _generateWav(bytes32 d1, bytes32 d2) internal view returns (string memory) {
        bytes memory buffer = new bytes(500000);
        uint256 startLength = _prepareBuffer(buffer);

        string memory table = TABLE_ENCODE;
        uint256 tablePtr;
        uint256 resultPtr = startLength + 32;
        assembly {
            // prepare the lookup table
            tablePtr := add(table, 1)

            // set write pointer
            resultPtr := add(buffer, resultPtr)
        }

        bytes memory freqTable = FREQUENCIES;

        uint256 numSamplesPlusOne = (3 * (((32 * (61 * 16 * SAMPLE_RATE)) / (7350)) + 1)) / 3; //3 * 3 * ((22050 + 3) / 3); // 8 = speed

        uint256[] memory noise_handler = new uint256[](4);

        // console.log("numSamplesPlusOne %i", numSamplesPlusOne);
        int256 pos = 0;

        for (uint256 i = 0; i < numSamplesPlusOne; i += 3) {
            assembly {
                function abs(a) -> b {
                    b := a
                    if lt(b, 0) {
                        b := mul(b, MINUS)
                    }
                }

                let meloIndex := div(i, div(numSamplesPlusOne, 32)) // TODO numSamples
                let data := d1
                if gt(meloIndex, 15) {
                    data := d2
                    meloIndex := sub(meloIndex, 16)
                    if gt(meloIndex, 15) {
                        meloIndex := 15
                    }
                }
                data := and(shr(add(16, mul(sub(15, meloIndex), 15)), data), 0x3FFF) // sub(15) is to divide the data in 2
                let note := and(data, 0x3F)
                let instr := and(shr(6, data), 0x07)
                let vol := and(shr(9, data), 0x07)

                let posStep := div(
                    mul(and(shr(232, mload(add(freqTable, add(32, mul(note, 3))))), 0xFFFFFF), 10000),
                    SAMPLE_RATE
                )

                let v := 0
                for {
                    let c := 0
                } lt(c, 3) {
                    c := add(c, 1)
                } {
                    let intValue := 0
                    // skip first value as it pertain to the double bytes for chunksize
                    if gt(pos, 0) {
                        // tri
                        if eq(instr, 0) {
                            intValue := sub(mul(smod(pos, ONE), 2), ONE)
                            if slt(intValue, 0) {
                                intValue := sub(0, intValue)
                            }
                            intValue := sub(mul(intValue, 2), ONE)
                            intValue := sdiv(mul(intValue, HALF), ONE)
                        }
                        if eq(instr, 1) {
                            // uneven_tri
                            let tmp := smod(pos, ONE)
                            if slt(tmp, ZERO8750) {
                                intValue := sdiv(mul(tmp, 16), 7)
                            }
                            if sgt(tmp, ZERO8750) {
                                intValue := mul(sub(ONE, tmp), 16)
                            }
                            if eq(tmp, ZERO8750) {
                                intValue := mul(sub(ONE, tmp), 16)
                            }
                            intValue := sdiv(mul(sub(intValue, ONE), HALF), ONE)
                        }
                        if eq(instr, 2) {
                            // saw
                            intValue := sdiv(mul(sub(smod(pos, ONE), HALF), ZERO7), ONE)
                        }
                        if eq(instr, 3) {
                            // square
                            let tmp := smod(pos, ONE)
                            intValue := MINUS_ONE
                            if lt(tmp, HALF) {
                                intValue := ONE
                            }
                            intValue := sdiv(intValue, 4)
                        }
                        if eq(instr, 4) {
                            // pulse
                            let tmp := smod(pos, ONE)
                            intValue := MINUS_ONE
                            if lt(tmp, ZERO3125) {
                                intValue := ONE
                            }
                            intValue := sdiv(intValue, 4)
                        }
                        if eq(instr, 5) {
                            // tri2
                            intValue := mul(pos, 4)
                            intValue := sdiv(
                                mul(
                                    sub(
                                        sub(
                                            add(
                                                abs(sub(smod(intValue, TWO), ONE)),
                                                sdiv(
                                                    sub(abs(sub(smod(sdiv(mul(intValue, HALF), ONE), TWO), ONE)), HALF),
                                                    2
                                                )
                                            ),
                                            HALF
                                        ),
                                        ZERO1
                                    ),
                                    ZERO1
                                ),
                                ONE
                            )
                        }
                        if eq(instr, 6) {
                            let rand := mload(add(noise_handler, 32))
                            let lastx := mload(add(noise_handler, 64))
                            let sample := mload(add(noise_handler, 96))
                            let lsample := mload(add(noise_handler, 128))

                            rand := mod(add(mul(1103515245, rand), 12345), 0x80000000)
                            let scale := div(mul(sub(pos, lastx), ONE), 160000) // 2489  = note_to_hz(63)  => 2489 * 10000000 / 11000 (sample rate) => 2262727 (160000 is from js)
                            lsample := sample
                            sample := sdiv(
                                mul(add(lsample, scale), sub(div(mul(rand, TWO), 0x8000000), ONE)),
                                add(ONE, scale)
                            )
                            lastx := pos
                            intValue := sdiv(mul(sdiv(mul(add(lsample, sample), 4), 3), sub(2, scale)), ONE) // 2 => 1.75
                            if slt(intValue, MINUS_ONE) {
                                intValue := MINUS_ONE
                            }
                            if sgt(intValue, ONE) {
                                intValue := ONE
                            }
                            intValue := sdiv(mul(intValue, 5), 10)
                            // noise_handler := or(rand, or(shl(64, lastx), add(shl(128, sample), shl(196, lsample))))
                            mstore(add(noise_handler, 32), rand)
                            mstore(add(noise_handler, 64), lastx)
                            mstore(add(noise_handler, 96), sample)
                            mstore(add(noise_handler, 128), lsample)
                        }
                        if eq(instr, 7) {
                            // detuned_tri
                            intValue := mul(pos, 2)
                            intValue := add(
                                sub(abs(sub(smod(intValue, TWO), ONE)), HALF),
                                sub(
                                    sdiv(sub(abs(sub(smod(sdiv(mul(intValue, 127), 128), TWO), ONE)), HALF), 2),
                                    sdiv(ONE, 4)
                                )
                            )
                        }
                        intValue := sdiv(mul(intValue, vol), 7) // getValue(pos, instr)
                        intValue := add(sdiv(mul(intValue, 256), TWO), 128) // TODO never go negative
                    }
                    v := add(v, shl(sub(16, mul(c, 8)), intValue))
                    pos := add(pos, posStep)
                }

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, v), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, v), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, v), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(v, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
        }

        _finishBuffer(buffer, resultPtr, tablePtr, numSamplesPlusOne, startLength);

        return string(buffer);
    }
}