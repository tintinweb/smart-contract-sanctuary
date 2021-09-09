// SPDX-License-Identifier: UNLICENSED
/// @title NumbersOnTapRender
/// @notice Render Numbers on Tap (NFT Faucet)
/// @author CyberPnk <[email protected]>

pragma solidity ^0.8.0;

import "./IStringUtilsV1.sol";

contract NumbersOnTapRender {
    IStringUtilsV1 stringUtils;

    struct Traits {
        bool div2;
        bool div3;
        bool div5;
        bool div7;
        bool div10;
        bool div11;
        bool div42;
        bool div69;
        bool div100;
        bool div360;
        bool div1000;
        bool pow2;
        bool sqr;
        bool gt99;
        bool gt999;
        bool gt9999;
    }

    constructor(address stringUtilsContract) {
        stringUtils = IStringUtilsV1(stringUtilsContract);
    }

    function sqrt(uint x) pure private returns (uint) {
        uint z = (x + 1) / 2;
        uint y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function getTraits(uint256 itemId) internal pure returns(Traits memory) {
        uint maybeSqrt = sqrt(itemId);

        return Traits(
            itemId % 2 == 0,
            itemId % 3 == 0,
            itemId % 5 == 0,
            itemId % 7 == 0,
            itemId % 10 == 0,
            itemId % 11 == 0,
            itemId % 42 == 0,
            itemId % 69 == 0,
            itemId % 100 == 0,
            itemId % 360 == 0,
            itemId % 1000 == 0,
            itemId != 0 && (itemId & (itemId - 1) == 0),
            itemId == maybeSqrt * maybeSqrt,
            itemId > 99,
            itemId > 999,
            itemId > 9999            
        );
    }

    function getImage(uint256 itemId) public view returns(bytes memory) {
        Traits memory traits = getTraits(itemId);
        string memory classname = string(abi.encodePacked(string(abi.encodePacked(
            traits.div2 ? "d2 " : "",
            traits.div3 ? "d3 " : "",
            traits.div5 ? "d5 " : "",
            traits.div7 ? "d7 " : "",
            traits.div10 ? "d10 " : "",
            traits.div11 ? "d11 " : "",
            traits.div42 ? "d42 " : "")),string(abi.encodePacked(
            traits.div69 ? "d69 " : "",
            traits.div100 ? "d100 " : "",
            traits.div360 ? "d360 " : "",
            traits.div1000 ? "d1000 " : "",
            traits.pow2 ? "p2 " : "",
            traits.sqr ? "sqr " : "",
            traits.gt99 ? "gt99 " : "",
            traits.gt999 ? "gt999 " : "",
            traits.gt9999 ? "gt9999 " : ""
        ))));

        string memory strId = stringUtils.numberToString(itemId);

        return abi.encodePacked(
            "<svg viewBox='0 0 640 640' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' class='", classname, "'>"
                  "<style>"
                    "svg{background-color:white;}"
                    "text{",
                        "font-weight:bold;"
                        "font-size:25em;"
                        "fill:rgba(128, 128, 128, 1);"
                        "font-family:sans-serif;",
                        "font-style:italic;"
                        "paint-order:stroke;"
                        "stroke:rgba(0, 0, 0, 1);"
                        "stroke-width:0.2em;"
                        "stroke-linecap:butt;",
                        "stroke-linejoin:round;"
                        "stroke-opacity:1;"
                        "filter:drop-shadow(4px 4px 0px rgba(0, 0, 0, 0.7));"
                    "}",
                    ".d2{background-color:#F2D0A4;}"
                    ".d3>text{fill:#F18F01;}"
                    ".d5>text{stroke-linejoin:miter;}"
                    ".d7>text{stroke:#2E86AB;fill:white;}",
                    ".d10>text{filter:drop-shadow(4px 4px 0px rgba(162,59,114,1));}"
                    ".d11>text{fill:#C73E1D;}"
                    ".d42{background-color:black;}"
                    ".d42>text{fill:gold;stroke:white;}",
                    ".d69>text{letter-spacing:-0.1em;}"
                    ".d100>text{filter:drop-shadow(8px 8px 4px rgba(162, 59, 114, 1));}"
                    ".d360{animation:spin 120s;}",
                    ".d1000>text{filter:drop-shadow(32px 32px 16px rgba(162,59,114,1));}"
                    ".gt99>text{font-size:20em;}"
                    ".gt999>text{font-size:15em;}"
                    ".gt9999>text{font-size:10em;}",
                    ".p2{"
                        "background-image:linear-gradient(45deg,rgba(59,31,43,0.5) 25%, transparent 25%),"
                                        "linear-gradient(-45deg,rgba(59,31,43,0.5) 25%, transparent 25%),"
                                        "linear-gradient(45deg,transparent 75%, rgba(59,31,43,0.5) 75%),",
                                        "linear-gradient(-45deg,transparent 75%, rgba(59,31,43,0.5) 75%);"
                        "background-size:1em 1em;"
                        "background-position:0 0,0 0.5em,0.5em -0.5em,-0.5em 0px;"
                    "}",
                    "@keyframes spin {0%{transform:rotate(0deg);}25%{transform:rotate(0deg);}100%{transform:rotate(360deg);}}"
                    ".sqr{box-shadow:inset 0 0 0 0.7em rgba(162,59,114,0.5);}"
                    ".sqr>text{font-style:normal;}"
                "</style>",
                "<text x='", traits.sqr ? "50": "48", "%' y='55%' dominant-baseline='middle' text-anchor='middle'>",
                    strId,
                "</text>"
            "</svg>"
        );
    }

    function tokenURI(uint256 itemId) public view returns (string memory) {
        string memory strId = stringUtils.numberToString(itemId);

        bytes memory imageBytes = getImage(itemId);

        string memory image = string(abi.encodePacked("data:image/svg+xml;utf8,", imageBytes));

        Traits memory traits = getTraits(itemId);

        bytes memory json = abi.encodePacked(string(abi.encodePacked(
            '{'
                '"name": "Number ', strId, '",'
                '"description": "Numbers",'
                '"image": "', image, '",'
                '"traits": [ ',
                    traits.div2 ? '{"trait_type":"Divisible By 2","value":"Divisible By 2"},' : '',
                    traits.div3 ? '{"trait_type":"Divisible By 3","value":"Divisible By 3"},' : '',
                    traits.div5 ? '{"trait_type":"Divisible By 5","value":"Divisible By 5"},' : '',
                    traits.div7 ? '{"trait_type":"Divisible By 7","value":"Divisible By 7"},' : '',
                    traits.div10 ? '{"trait_type":"Divisible By 10","value":"Divisible By 10"},' : '',
                    traits.div11 ? '{"trait_type":"Divisible By 11","value":"Divisible By 11"},' : '')),string(abi.encodePacked(
                    traits.div42 ? '{"trait_type":"Divisible By 42","value":"Divisible By 42"},' : '',
                    traits.div69 ? '{"trait_type":"Divisible By 69","value":"Divisible By 69"},' : '',
                    traits.div100 ? '{"trait_type":"Divisible By 100","value":"Divisible By 100"},' : '',
                    traits.div360 ? '{"trait_type":"Divisible By 360","value":"Divisible By 360"},' : '',
                    traits.div1000 ? '{"trait_type":"Divisible By 1000","value":"Divisible By 1000"},' : '',
                    traits.pow2 ? '{"trait_type":"Power Of 2","value":"Power Of 2"},' : '',
                    traits.sqr ? '{"trait_type":"Square","value":"Square"},' : '',
                    '{"trait_type":"Integer","value":"Integer"}'
                ']'
            '}'
        )));

        return stringUtils.base64EncodeJson(json);
    }

}

// SPDX-License-Identifier: MIT
/// [MIT License]
/// @title StringUtilsV1

pragma solidity ^0.8.0;

interface IStringUtilsV1 {
    function base64Encode(bytes memory data) external pure returns (string memory);

    function base64EncodeJson(bytes memory data) external pure returns (string memory);

    function base64EncodeSvg(bytes memory data) external pure returns (string memory);

    function numberToString(uint256 value) external pure returns (string memory);

    function addressToString(address account) external pure returns(string memory);

    function split(string calldata str, string calldata delim) external pure returns(string[] memory);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}