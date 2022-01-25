// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

import "./IRenderer.sol";

contract RleRendererV3 is IRenderer {
    mapping(bytes1 => string) hexParts;
    mapping(uint256 => string) gridOffsets;

    constructor () public {

        // Populate hex parts needed for hex color lookup. Seems more gas
        // friendly than storing in array.
        hexParts[0x00] = '00';
        hexParts[0x01] = '01';
        hexParts[0x02] = '02';
        hexParts[0x03] = '03';
        hexParts[0x04] = '04';
        hexParts[0x05] = '05';
        hexParts[0x06] = '06';
        hexParts[0x07] = '07';
        hexParts[0x08] = '08';
        hexParts[0x09] = '09';
        hexParts[0x0A] = '0A';
        hexParts[0x0B] = '0B';
        hexParts[0x0C] = '0C';
        hexParts[0x0D] = '0D';
        hexParts[0x0E] = '0E';
        hexParts[0x0F] = '0F';
        hexParts[0x10] = '10';
        hexParts[0x11] = '11';
        hexParts[0x12] = '12';
        hexParts[0x13] = '13';
        hexParts[0x14] = '14';
        hexParts[0x15] = '15';
        hexParts[0x16] = '16';
        hexParts[0x17] = '17';
        hexParts[0x18] = '18';
        hexParts[0x19] = '19';
        hexParts[0x1A] = '1A';
        hexParts[0x1B] = '1B';
        hexParts[0x1C] = '1C';
        hexParts[0x1D] = '1D';
        hexParts[0x1E] = '1E';
        hexParts[0x1F] = '1F';
        hexParts[0x20] = '20';
        hexParts[0x21] = '21';
        hexParts[0x22] = '22';
        hexParts[0x23] = '23';
        hexParts[0x24] = '24';
        hexParts[0x25] = '25';
        hexParts[0x26] = '26';
        hexParts[0x27] = '27';
        hexParts[0x28] = '28';
        hexParts[0x29] = '29';
        hexParts[0x2A] = '2A';
        hexParts[0x2B] = '2B';
        hexParts[0x2C] = '2C';
        hexParts[0x2D] = '2D';
        hexParts[0x2E] = '2E';
        hexParts[0x2F] = '2F';
        hexParts[0x30] = '30';
        hexParts[0x31] = '31';
        hexParts[0x32] = '32';
        hexParts[0x33] = '33';
        hexParts[0x34] = '34';
        hexParts[0x35] = '35';
        hexParts[0x36] = '36';
        hexParts[0x37] = '37';
        hexParts[0x38] = '38';
        hexParts[0x39] = '39';
        hexParts[0x3A] = '3A';
        hexParts[0x3B] = '3B';
        hexParts[0x3C] = '3C';
        hexParts[0x3D] = '3D';
        hexParts[0x3E] = '3E';
        hexParts[0x3F] = '3F';
        hexParts[0x40] = '40';
        hexParts[0x41] = '41';
        hexParts[0x42] = '42';
        hexParts[0x43] = '43';
        hexParts[0x44] = '44';
        hexParts[0x45] = '45';
        hexParts[0x46] = '46';
        hexParts[0x47] = '47';
        hexParts[0x48] = '48';
        hexParts[0x49] = '49';
        hexParts[0x4A] = '4A';
        hexParts[0x4B] = '4B';
        hexParts[0x4C] = '4C';
        hexParts[0x4D] = '4D';
        hexParts[0x4E] = '4E';
        hexParts[0x4F] = '4F';
        hexParts[0x50] = '50';
        hexParts[0x51] = '51';
        hexParts[0x52] = '52';
        hexParts[0x53] = '53';
        hexParts[0x54] = '54';
        hexParts[0x55] = '55';
        hexParts[0x56] = '56';
        hexParts[0x57] = '57';
        hexParts[0x58] = '58';
        hexParts[0x59] = '59';
        hexParts[0x5A] = '5A';
        hexParts[0x5B] = '5B';
        hexParts[0x5C] = '5C';
        hexParts[0x5D] = '5D';
        hexParts[0x5E] = '5E';
        hexParts[0x5F] = '5F';
        hexParts[0x60] = '60';
        hexParts[0x61] = '61';
        hexParts[0x62] = '62';
        hexParts[0x63] = '63';
        hexParts[0x64] = '64';
        hexParts[0x65] = '65';
        hexParts[0x66] = '66';
        hexParts[0x67] = '67';
        hexParts[0x68] = '68';
        hexParts[0x69] = '69';
        hexParts[0x6A] = '6A';
        hexParts[0x6B] = '6B';
        hexParts[0x6C] = '6C';
        hexParts[0x6D] = '6D';
        hexParts[0x6E] = '6E';
        hexParts[0x6F] = '6F';
        hexParts[0x70] = '70';
        hexParts[0x71] = '71';
        hexParts[0x72] = '72';
        hexParts[0x73] = '73';
        hexParts[0x74] = '74';
        hexParts[0x75] = '75';
        hexParts[0x76] = '76';
        hexParts[0x77] = '77';
        hexParts[0x78] = '78';
        hexParts[0x79] = '79';
        hexParts[0x7A] = '7A';
        hexParts[0x7B] = '7B';
        hexParts[0x7C] = '7C';
        hexParts[0x7D] = '7D';
        hexParts[0x7E] = '7E';
        hexParts[0x7F] = '7F';
        hexParts[0x80] = '80';
        hexParts[0x81] = '81';
        hexParts[0x82] = '82';
        hexParts[0x83] = '83';
        hexParts[0x84] = '84';
        hexParts[0x85] = '85';
        hexParts[0x86] = '86';
        hexParts[0x87] = '87';
        hexParts[0x88] = '88';
        hexParts[0x89] = '89';
        hexParts[0x8A] = '8A';
        hexParts[0x8B] = '8B';
        hexParts[0x8C] = '8C';
        hexParts[0x8D] = '8D';
        hexParts[0x8E] = '8E';
        hexParts[0x8F] = '8F';
        hexParts[0x90] = '90';
        hexParts[0x91] = '91';
        hexParts[0x92] = '92';
        hexParts[0x93] = '93';
        hexParts[0x94] = '94';
        hexParts[0x95] = '95';
        hexParts[0x96] = '96';
        hexParts[0x97] = '97';
        hexParts[0x98] = '98';
        hexParts[0x99] = '99';
        hexParts[0x9A] = '9A';
        hexParts[0x9B] = '9B';
        hexParts[0x9C] = '9C';
        hexParts[0x9D] = '9D';
        hexParts[0x9E] = '9E';
        hexParts[0x9F] = '9F';
        hexParts[0xA0] = 'A0';
        hexParts[0xA1] = 'A1';
        hexParts[0xA2] = 'A2';
        hexParts[0xA3] = 'A3';
        hexParts[0xA4] = 'A4';
        hexParts[0xA5] = 'A5';
        hexParts[0xA6] = 'A6';
        hexParts[0xA7] = 'A7';
        hexParts[0xA8] = 'A8';
        hexParts[0xA9] = 'A9';
        hexParts[0xAA] = 'AA';
        hexParts[0xAB] = 'AB';
        hexParts[0xAC] = 'AC';
        hexParts[0xAD] = 'AD';
        hexParts[0xAE] = 'AE';
        hexParts[0xAF] = 'AF';
        hexParts[0xB0] = 'B0';
        hexParts[0xB1] = 'B1';
        hexParts[0xB2] = 'B2';
        hexParts[0xB3] = 'B3';
        hexParts[0xB4] = 'B4';
        hexParts[0xB5] = 'B5';
        hexParts[0xB6] = 'B6';
        hexParts[0xB7] = 'B7';
        hexParts[0xB8] = 'B8';
        hexParts[0xB9] = 'B9';
        hexParts[0xBA] = 'BA';
        hexParts[0xBB] = 'BB';
        hexParts[0xBC] = 'BC';
        hexParts[0xBD] = 'BD';
        hexParts[0xBE] = 'BE';
        hexParts[0xBF] = 'BF';
        hexParts[0xC0] = 'C0';
        hexParts[0xC1] = 'C1';
        hexParts[0xC2] = 'C2';
        hexParts[0xC3] = 'C3';
        hexParts[0xC4] = 'C4';
        hexParts[0xC5] = 'C5';
        hexParts[0xC6] = 'C6';
        hexParts[0xC7] = 'C7';
        hexParts[0xC8] = 'C8';
        hexParts[0xC9] = 'C9';
        hexParts[0xCA] = 'CA';
        hexParts[0xCB] = 'CB';
        hexParts[0xCC] = 'CC';
        hexParts[0xCD] = 'CD';
        hexParts[0xCE] = 'CE';
        hexParts[0xCF] = 'CF';
        hexParts[0xD0] = 'D0';
        hexParts[0xD1] = 'D1';
        hexParts[0xD2] = 'D2';
        hexParts[0xD3] = 'D3';
        hexParts[0xD4] = 'D4';
        hexParts[0xD5] = 'D5';
        hexParts[0xD6] = 'D6';
        hexParts[0xD7] = 'D7';
        hexParts[0xD8] = 'D8';
        hexParts[0xD9] = 'D9';
        hexParts[0xDA] = 'DA';
        hexParts[0xDB] = 'DB';
        hexParts[0xDC] = 'DC';
        hexParts[0xDD] = 'DD';
        hexParts[0xDE] = 'DE';
        hexParts[0xDF] = 'DF';
        hexParts[0xE0] = 'E0';
        hexParts[0xE1] = 'E1';
        hexParts[0xE2] = 'E2';
        hexParts[0xE3] = 'E3';
        hexParts[0xE4] = 'E4';
        hexParts[0xE5] = 'E5';
        hexParts[0xE6] = 'E6';
        hexParts[0xE7] = 'E7';
        hexParts[0xE8] = 'E8';
        hexParts[0xE9] = 'E9';
        hexParts[0xEA] = 'EA';
        hexParts[0xEB] = 'EB';
        hexParts[0xEC] = 'EC';
        hexParts[0xED] = 'ED';
        hexParts[0xEE] = 'EE';
        hexParts[0xEF] = 'EF';
        hexParts[0xF0] = 'F0';
        hexParts[0xF1] = 'F1';
        hexParts[0xF2] = 'F2';
        hexParts[0xF3] = 'F3';
        hexParts[0xF4] = 'F4';
        hexParts[0xF5] = 'F5';
        hexParts[0xF6] = 'F6';
        hexParts[0xF7] = 'F7';
        hexParts[0xF8] = 'F8';
        hexParts[0xF9] = 'F9';
        hexParts[0xFA] = 'FA';
        hexParts[0xFB] = 'FB';
        hexParts[0xFC] = 'FC';
        hexParts[0xFD] = 'FD';
        hexParts[0xFE] = 'FE';
        hexParts[0xFF] = 'FF';

        // Populate offsets needed for SVG formatting
        gridOffsets[0] = '0';
        gridOffsets[1] = '10';
        gridOffsets[2] = '20';
        gridOffsets[3] = '30';
        gridOffsets[4] = '40';
        gridOffsets[5] = '50';
        gridOffsets[6] = '60';
        gridOffsets[7] = '70';
        gridOffsets[8] = '80';
        gridOffsets[9] = '90';
        gridOffsets[10] = '100';
        gridOffsets[11] = '110';
        gridOffsets[12] = '120';
        gridOffsets[13] = '130';
        gridOffsets[14] = '140';
        gridOffsets[15] = '150';
        gridOffsets[16] = '160';
        gridOffsets[17] = '170';
        gridOffsets[18] = '180';
        gridOffsets[19] = '190';
        gridOffsets[20] = '200';
        gridOffsets[21] = '210';
        gridOffsets[22] = '220';
        gridOffsets[23] = '230';
        gridOffsets[24] = '240';
        gridOffsets[25] = '250';
        gridOffsets[26] = '260';
        gridOffsets[27] = '270';
        gridOffsets[28] = '280';
        gridOffsets[29] = '290';

    }


    function render(bytes memory encodedData)
        external
        view
        returns (string memory)
    {
        bytes memory colorCodes;
        bytes memory colorNums;
        bytes memory colorCounts;

        (colorCodes, colorNums, colorCounts) = abi.decode(
            encodedData, (
                bytes,
                bytes,
                bytes
            )
        );
        return _renderImage(colorCodes, _decodeImage(colorNums, colorCounts));

    }

    function _renderImage(
        bytes memory colorCodes,
        uint16[720] memory decodedImage
    )
        private
        view
        returns(string memory)
    {

        string memory fullPicture;
        for (uint256 i = 0; i < 720; i += 180) {

            string memory partialPicture;
            for (uint256 j = 0; j < 180; j += 36) {

                string memory smallPicture;
                for (uint256 k = 0; k < 36; k += 6) {
                    smallPicture =
                    string(
                        abi.encodePacked(
                            smallPicture,
                            _fillColor(
                                colorCodes,
                                decodedImage[i + j + k],
                                i + j + k
                            ),
                            _fillColor(
                                colorCodes,
                                decodedImage[i + j + k + 1],
                                i + j + k + 1
                            ),
                            _fillColor(
                                colorCodes,
                                decodedImage[i + j + k  + 2],
                                i + j + k + 2
                            ),
                            _fillColor(
                                colorCodes,
                                decodedImage[i + j + k  + 3],
                                i + j + k + 3
                            ),
                            _fillColor(
                                colorCodes,
                                decodedImage[i + j + k  + 4],
                                i + j + k + 4
                            ),
                            _fillColor(
                                colorCodes,
                                decodedImage[i + j + k  + 5],
                                i + j + k + 5
                            )
                        )
                   );
                }
                partialPicture = string(
                    abi.encodePacked(
                        partialPicture,
                        smallPicture
                    )
                );
            }
            fullPicture = string(
                abi.encodePacked(
                    fullPicture,
                    partialPicture
                )
            );
        }
        return fullPicture;
    }

    function _decodeImage(
        bytes memory colorNums,
        bytes memory colorCounts
    )
        private
        pure
        returns (uint16[720] memory)
    {
        uint16[720] memory arr;
        uint16 index = 0;
        for (uint256 ind = 0; ind < colorCounts.length; ind += 2) {
            // The logic directly below extracts a 2-byte uint value from an
            // array of bytes which represent counts (or frequencies of color
            // codes). The first byte extracted is a high byte (follows
            // Big Endian high --> low hency why the shift (<<) of 8 bits.
            // The second byte represents a lower byte which does not have to
            // be shifted.
            uint256 count = (
                uint256(
                    uint8(
                        colorCounts[ind]
                    )
                ) << 8
            ) | uint256(
                uint8(
                    colorCounts[ind + 1]
                )
            );

            // Color Nums, or indices into the color code array are are single
            // byte so they do not need to be shifted, just cast accordingly
            uint16 num = (
                uint16(
                  uint8(
                    colorNums[ind]
                  )
                ) << 8
              ) | uint16(
                uint8(
                  colorNums[ind + 1]
                )
              );
            for (uint256 j = 0; j < count; j++) {
                arr[index++] = num;
            }
        }

        return arr;
    }


    function _fillColor(
        bytes memory colorCodes,
        uint256 colorIndex,
        uint256 offset
    )
        private
        view
        returns (string memory)
    {

        return string(
            abi.encodePacked(
                "<rect height='10' width='10' fill='#",

                 // This way of encoding hex strings through mappings seems to
                 // be more efficient than bitwise shifting conversions such as
                 // https://stackoverflow.com/questions/69312285/how-to-convert-bytes3-to-hex-string-in-solidity
                 // Unfortunately open zeppelin's toString() is too slow maybe because of type conversions
                 // happening behind the scenes. We multiply by 3 to navigate to
                 // start of a hex code which is composed of 3 bytes.
                 hexParts[colorCodes[colorIndex * 3]],
                 hexParts[colorCodes[colorIndex * 3 + 1]],
                 hexParts[colorCodes[colorIndex * 3 + 2]],
                "' x='",
                gridOffsets[offset % 24],
                "' y='",
                gridOffsets[offset / 24],
                "'/>"
            )
        );
    }



}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.11;

interface IRenderer {
    function render(bytes memory encodedData)
        external
        view
        returns (string memory lol);
}