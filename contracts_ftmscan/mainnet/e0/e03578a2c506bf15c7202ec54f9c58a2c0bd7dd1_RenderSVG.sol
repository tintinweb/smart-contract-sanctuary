// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library HexStrings {
    bytes16 internal constant ALPHABET = "0123456789abcdef";

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

pragma solidity ^0.8.10;
import "base64-sol/base64.sol";
import "./HexStrings.sol";

contract RenderSVG {
    using HexStrings for uint160;

    constructor() {}

    function renderToken(
        string memory c1,
        string memory c2,
        string memory c3,
        string memory c4,
        string memory c5
    ) public pure returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                c1,
                '" points="255.9231,212.32 127.9611,0 125.1661,9.5 125.1661,285.168 127.9611,287.958 " /><polygon fill="#',
                c2,
                '" points="0,212.32 127.962,287.959 127.962,154.158 127.962,0 " /><polygon fill="#',
                c3,
                '" points="255.9991,236.5866 127.9611,312.1866 126.3861,314.1066 126.3861,412.3056 127.9611,416.9066 " /> <polygon fill="#',
                c2,
                '" points="127.962,416.9052 127.962,312.1852 0,236.5852 " /><polygon fill="#',
                c4,
                '" points="127.9611,287.9577 255.9211,212.3207 127.9611,154.1587 " /><polygon fill="#',
                c5
            )
        );

        return render;
    }

    function generateSVGofTokenById(
        string memory preEvent1,
        string memory rsca,
        string memory id,
        string memory telegram
    ) public pure returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg width="606" height="334" xmlns="http://www.w3.org/2000/svg"><rect style="fill:#fff;stroke:black;stroke-width:3;" width="602" height="331" x="1.5" y="1.5" ry="10" /><g transform="matrix(0.72064248,0,0,0.72064248,17.906491,14.009434)"><polygon fill="#',
                rsca,
                '" points="0.0009,212.3208 127.9609,287.9578 127.9609,154.1588 " /></g><text style="font-size:40px;line-height:1.25;fill:#000000;" x="241" y="143.01178" >Conference</text> <text style="font-size:20px;line-height:1.25;fill:#000000;" x="241" y="182">',
                preEvent1,
                '</text><text style="font-size:40px;line-height:1.25;fill:#000000;" x="241" y="87">#',
                id,
                ' on Fantom</text> <text style="font-size:40px;line-height:1.25;fill:#000000;" x="241" y="290">@',
                telegram,
                '</text> <text style="font-size:40px;line-height:1.25;fill:#000000;" x="241" y="39">ETHDubai Ticket</text></svg>'
            )
        );

        return svg;
    }

    function metadata(
        string memory id,
        string memory image,
        string memory ticketOption,
        uint160 owner
    ) public pure returns (string memory) {
        string memory name = string(
            abi.encodePacked("ETHDubai Ticket #", id, " on Fantom")
        );
        string memory dsc = string(
            abi.encodePacked("ETHDubai 2022 conference ticket.")
        );
        string memory ownerHex = owner.toHexString(20);
        string memory imageB64 = Base64.encode(bytes(image));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                dsc,
                                '", "external_url":"https://www.ethdubaiconf.org/token/',
                                id,
                                "metis",
                                '", "attributes": [{"trait_type": "options", "value": "',
                                ticketOption,
                                '"}], "owner":"',
                                ownerHex,
                                '", "image": "data:image/svg+xml;base64,',
                                imageB64,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}