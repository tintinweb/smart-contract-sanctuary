pragma solidity ^0.8.0;

contract nft8008 {
    // Clock8008 will be the base contract with ownership data

    // Note: The process of "approving", "transfering" etc should all be done on the base contract
    address internal constant base = 0xf2470e641a551D7Dbdf4B8D064Cf208edfB06586;

    fallback(bytes calldata) external payable returns (bytes memory) {
        (, bytes memory m) = base.call{value: msg.value}(msg.data);
        return m;
    }

    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        string[3] memory parts;
        parts[
            0
        ] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="420x" height="420px" viewBox="0 0 100 100"><style type="text/css">@font-face{font-family:"Share Tech Mono";font-style:normal;font-weight:400;src:url(https://fonts.gstatic.com/s/sharetechmono/v10/J7aHnp1uDWRBEqV98dVQztYldFcLowEF.woff2) format("woff2");unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}text{filter:url(#filter);fill:#fff;font-family:"Share Tech Mono",sans-serif;font-size:20px;-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}body{background:#000}.info{color:#fff;font:1em/1 sans-serif;text-align:center}.info a{color:#fff}svg{width:420px;height:420px;display:block;position:relative;overflow:hidden;background:#000}</style> <defs> <filter id="filter"> <feFlood flood-color="black" result="black"/> <feFlood flood-color="red" result="flood1"/> <feFlood flood-color="limegreen" result="flood2"/> <feOffset in="SourceGraphic" dx="3" dy="0" result="off1a"/> <feOffset in="SourceGraphic" dx="2" dy="0" result="off1b"/> <feOffset in="SourceGraphic" dx="-3" dy="0" result="off2a"/> <feOffset in="SourceGraphic" dx="-2" dy="0" result="off2b"/> <feComposite in="flood1" in2="off1a" operator="in" result="comp1"/> <feComposite in="flood2" in2="off2a" operator="in" result="comp2"/> <feMerge x="0" width="100%" result="merge1"> <feMergeNode in="black"/> <feMergeNode in="comp1"/> <feMergeNode in="off1b"/> <animate attributeName="y" id="y" dur="4s" values="104px; 104px; 30px; 105px; 30px; 2px; 2px; 50px; 40px; 105px; 105px; 20px; 60px; 40px; 104px; 40px; 70px; 10px; 30px; 104px; 102px" keyTimes="0; 0.362; 0.368; 0.421; 0.440; 0.477; 0.518; 0.564; 0.593; 0.613; 0.644; 0.693; 0.721; 0.736; 0.772; 0.818; 0.844; 0.894; 0.925; 0.939; 1" repeatCount="indefinite"/> <animate attributeName="height" id="h" dur="4s" values="10px; 0px; 10px; 30px; 50px; 0px; 10px; 0px; 0px; 0px; 10px; 50px; 40px; 0px; 0px; 0px; 40px; 30px; 10px; 0px; 50px" keyTimes="0; 0.362; 0.368; 0.421; 0.440; 0.477; 0.518; 0.564; 0.593; 0.613; 0.644; 0.693; 0.721; 0.736; 0.772; 0.818; 0.844; 0.894; 0.925; 0.939; 1" repeatCount="indefinite"/> </feMerge> <feMerge x="0" width="100%" y="60px" height="65px" result="merge2"> <feMergeNode in="black"/> <feMergeNode in="comp2"/> <feMergeNode in="off2b"/> <animate attributeName="y" id="y" dur="4s" values="103px; 104px; 69px; 53px; 42px; 104px; 78px; 89px; 96px; 100px; 67px; 50px; 96px; 66px; 88px; 42px; 13px; 100px; 100px; 104px;" keyTimes="0; 0.055; 0.100; 0.125; 0.159; 0.182; 0.202; 0.236; 0.268; 0.326; 0.357; 0.400; 0.408; 0.461; 0.493; 0.513; 0.548; 0.577; 0.613; 1" repeatCount="indefinite"/> <animate attributeName="height" id="h" dur="4s" values="0px; 0px; 0px; 16px; 16px; 12px; 12px; 0px; 0px; 5px; 10px; 22px; 33px; 11px; 0px; 0px; 10px" keyTimes="0; 0.055; 0.100; 0.125; 0.159; 0.182; 0.202; 0.236; 0.268; 0.326; 0.357; 0.400; 0.408; 0.461; 0.493; 0.513; 1" repeatCount="indefinite"/> </feMerge> <feMerge> <feMergeNode in="SourceGraphic"/> <feMergeNode in="merge1"/> <feMergeNode in="merge2"/> </feMerge> </filter> </defs> <g> <text x="50%" y="20" dominant-baseline="middle" text-anchor="middle"> NFT8008 </text> <text style="font-size:32px" x="50%" y="50" dominant-baseline="middle" text-anchor="middle"> #';
        parts[1] = Utils.toString(tokenId);
        parts[2] = "</text></g></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "NFT8008 Passport #',
                        Utils.toString(tokenId),
                        '", "description": "NFT8008 is your passport to the 8008 digital collectible world. It is the all-in-one pass for the ever expanding 8008 meta-universe. Buy once, valid forever!", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
}

library Utils {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}