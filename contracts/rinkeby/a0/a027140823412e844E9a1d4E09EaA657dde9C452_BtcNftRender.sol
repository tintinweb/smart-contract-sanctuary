// SPDX-License-Identifier: UNLICENSED
/// @title BtcNftRender
/// @notice Render BTC NFT
/// @author CyberPnk <[email protected]>

pragma solidity ^0.8.0;

import "@cyberpnk/solidity-library/contracts/IStringUtilsV1.sol";
// import "hardhat/console.sol";

contract BtcNftRender {
    IStringUtilsV1 stringUtils;

    struct Traits {
        bool gt0001;
        bool gt001;
        bool gt01;
        bool gt1;
        bool gt10;
        bool gt100;
        bool gt1000;
        bool petRock;
    }

    constructor(address stringUtilsContract) {
        stringUtils = IStringUtilsV1(stringUtilsContract);
    }

    function getTraits(uint256 itemId) internal pure returns(Traits memory) {
        uint satoshis = itemId % (10**16);

        return Traits(
            satoshis >= 100000 && satoshis < 1000000,
            satoshis >= 1000000 && satoshis < 10000000,
            satoshis >= 10000000 && satoshis < 100000000,
            satoshis >= 100000000 && satoshis < 1000000000,
            satoshis >= 1000000000 && satoshis < 10000000000,
            satoshis >= 10000000000 && satoshis < 100000000000,
            satoshis >= 100000000000 && satoshis < 1000000000000,
            itemId / (10**40) > 0
        );        
    }

    function getImage(uint256 itemId) public view returns(bytes memory) {
        Traits memory traits = getTraits(itemId);
        string memory strSats = stringUtils.numberToString(itemId % 10**16);
        string memory strBtcs = getStrBtc(itemId);
        string memory classname = string(abi.encodePacked(string(abi.encodePacked(
            traits.gt0001 ? "gt0001 " : "",
            traits.gt001 ? "gt001 " : "",
            traits.gt01 ? "gt01 " : "",
            traits.gt1 ? "gt1 " : "")),string(abi.encodePacked(
            traits.gt10 ? "gt10 " : "",
            traits.gt100 ? "gt100 " : "",
            traits.gt1000 ? "gt1000 " : "",
            traits.petRock ? "pr " : ""
        ))));

        uint16 size = 1024;
        if (traits.gt001) {
            size = 512;
        } else if (traits.gt01) {
            size = 256;
        } else if (traits.gt1) {
            size = 128;
        } else if (traits.gt10) {
            size = 64;
        } else if (traits.gt100) {
            size = 32;
        } else if (traits.gt1000) {
            size = 16;
        }
        uint16 offset = 512 - size/2;

        string memory strSize = stringUtils.numberToString(size);
        string memory strOffset = stringUtils.numberToString(offset);

        bytes memory strPetRockSvg = abi.encodePacked(
"<g transform='translate(340, 340)'>"
    "<path d='m159 246c0.383-8.67-4.79-13.7-4.79-13.7l6.9 5.81-3.07-6.61 7 8.32-1.82-8.67 5.46 10.6-1.05-9.81 3.55 7.52 0.479-7.52 1.92 6.5 2.68-5.93 0.383 8.78 6.04-6.73s-4.98 10.6-3.93 11.4c1.05 0.798-19.7 0-19.7 0z' style='fill:#005600;stroke-width:.614;stroke:#000'/>"
    "<path d='m145 260s5.37 6.61 21.2 7.98 22.4 0.342 25.1-7.18-5.56-15.6-12.7-17.1c-7.09-1.48-24.3-0.342-28.7 5.81-4.31 6.16-5.56 7.3-4.98 10.5z' style='fill:#ececec;stroke-width:.614;stroke:#000'/>"
    "<ellipse cx='158' cy='252' rx='4.27' ry='3.88' style='fill:#fff;stroke-width:.614;stroke:#000'/>",
    "<ellipse cx='176' cy='251' rx='4.07' ry='4.16' style='fill:#fff;stroke-width:.614;stroke:#000'/>"
    "<ellipse cx='156' cy='253' rx='1.53' ry='1.94' style='stroke-width:.0812;stroke:#000'/>"
    "<ellipse cx='178' cy='250' rx='1.68' ry='1.71' style='stroke-width:.0812;stroke:#000'/>",
"</g>");

        return abi.encodePacked(abi.encodePacked(
"<svg width='1024' height='1024' version='1.1' viewBox='0 0 640 640' xmlns='http://www.w3.org/2000/svg' class='",classname,"'>"
  "<style>text {font-family: monospace; fill: black; font-weight: bold;}</style>",
  "<svg viewBox='",strOffset,' ',strOffset,' ',strSize,' ',strSize,"'>"
    "<g transform='translate(480, 480)'>"),abi.encodePacked(
      "<path fill='#f7931a' d='m63.033,39.744c-4.274,17.143-21.637,27.576-38.782,23.301-17.138-4.274-27.571-21.638-23.295-38.78,4.272-17.145,21.635-27.579,38.775-23.305,17.144,4.274,27.576,21.64,23.302,38.784z'/>"
      "<path fill='#FFF' d='m46.103,27.444c0.637-4.258-2.605-6.547-7.038-8.074l1.438-5.768-3.511-0.875-1.4,5.616c-0.923-0.23-1.871-0.447-2.813-0.662l1.41-5.653-3.509-0.875-1.439,5.766c-0.764-0.174-1.514-0.346-2.242-0.527l0.004-0.018-4.842-1.209-0.934,3.75s2.605,0.597,2.55,0.634c1.422,0.355,1.679,1.296,1.636,2.042l-1.638,6.571c0.098,0.025,0.225,0.061,0.365,0.117-0.117-0.029-0.242-0.061-0.371-0.092l-2.296,9.205c-0.174,0.432-0.615,1.08-1.609,0.834,0.035,0.051-2.552-0.637-2.552-0.637l-1.743,4.019,4.569,1.139c0.85,0.213,1.683,0.436,2.503,0.646l-1.453,5.834,3.507,0.875,1.439-5.772c0.958,0.26,1.888,0.5,2.798,0.726l-1.434,5.745,3.511,0.875,1.453-5.823c5.987,1.133,10.489,0.676,12.384-4.739,1.527-4.36-0.076-6.875-3.226-8.515,2.294-0.529,4.022-2.038,4.483-5.155zm-8.022,11.249c-1.085,4.36-8.426,2.003-10.806,1.412l1.928-7.729c2.38,0.594,10.012,1.77,8.878,6.317zm1.086-11.312c-0.99,3.966-7.1,1.951-9.082,1.457l1.748-7.01c1.982,0.494,8.365,1.416,7.334,5.553z'/>"
    "</g>",
    traits.petRock? string(strPetRockSvg) : '',
  "</svg>"
  "<text x='10' y='580'>Satoshis: ", strSats, "</text>"
  "<text x='10' y='600'>BTC: ", strBtcs, "</text>"
"</svg>"));
    }

    function getStrBtc(uint256 itemId) internal view returns (string memory) {
        uint sats = itemId % 10**16;
        uint afterDot = sats % 10**8;
        uint beforeDot = sats / 10**8;

        string memory strBeforeDot = stringUtils.numberToString(beforeDot);
        string memory strAfterDot = stringUtils.numberToString(afterDot);

        uint8 i;
        for (i = 0; i <= 8; i++) {
            if ((afterDot % (10 ** (8 - i))) == 0) {
                break;
            }
        }

        string memory strBtcs;
        if (i == 0) {
            strBtcs = strBeforeDot;
        } else {
            bytes memory bytesAfterDot = new bytes(i);
            uint leadingZeroes = 8 - bytes(strAfterDot).length;
            for (uint k = 0; k < leadingZeroes; k++) {
                bytesAfterDot[k] = bytes("0")[0];
            }
            for (uint j = 0; j < i - leadingZeroes; j++) {
                bytesAfterDot[leadingZeroes + j] = bytes(strAfterDot)[j];
            }
            strBtcs = string(abi.encodePacked(strBeforeDot, ".", bytesAfterDot));
        }

        return strBtcs;
    }

    function getTokenURI(uint256 itemId) public view returns (string memory) {
        string memory strSats = stringUtils.numberToString(itemId % 10**16);
        string memory strBtcs = getStrBtc(itemId);

        bytes memory imageBytes = getImage(itemId);

        string memory image = string(abi.encodePacked("data:image/svg+xml;utf8,", imageBytes));

        Traits memory traits = getTraits(itemId);

        bytes memory json = abi.encodePacked(string(abi.encodePacked(
            '{'
                '"name": "', strBtcs, ' BTC NFT",'
                '"image": "', image, '",'
                '"traits": [ ')),string(abi.encodePacked(
                    traits.gt0001 ? '{"trait_type":"milli","value":"milli"},' : '',
                    traits.gt001 ? '{"trait_type":"centi","value":"centi"},' : '',
                    traits.gt01 ? '{"trait_type":"deci","value":"deci"},' : '',
                    traits.gt1 ? '{"trait_type":"Unit","value":"Unit"},' : '',
                    traits.gt10 ? '{"trait_type":"deka","value":"deka"},' : '',
                    traits.gt100 ? '{"trait_type":"hecto","value":"hecto"},' : '',
                    traits.gt1000 ? '{"trait_type":"kilo","value":"kilo"},' : '')),string(abi.encodePacked(
                    traits.petRock ? '{"trait_type":"Pet","value":"Rock"},' : '',
                    '{"trait_type":"Redeemable for WBTC","value":"',traits.petRock ? 'No':'Yes','"},',
                    '{"trait_type":"Satoshis","value":', strSats, '},'
                    '{"trait_type":"BTC","value":', strBtcs, '}'
                '],'
                '"description": "BitCoin as the NFT it always wanted to be.  ',strSats,' sats or ',strBtcs,' BTC"'
            '}'
        )));

        return stringUtils.base64EncodeJson(json);
    }

    function getContractURI(address recipient) public view returns(string memory) {
        return stringUtils.base64EncodeJson(abi.encodePacked(
        '{'
            '"name": "BTC NFT",'
            '"description": "BTC wants to be an NFT.  You can mint a normal token by locking some wBTC, which you can unlock burning the NFT.  Or you can mint a rare token by burning some wBTC forever.",'
            '"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABC0lEQVR4nO3XSw6DMBBEwZwg978Pq5yKbCPlIxMGyjY9kpdI%2FWrH7ZY779bHfW15emfZtQZPBVIVPRzG0eHdQpwd3g2EDqcQOpYi6EiKoOMogo6iCDqGIugIiqDHUwQ9miPowRRAj%2BUIeigF0CM5gh5IAfQ4jqCHBUAC6FEcQQ8KQAAggB7DEfSQAAQgAAEIQAACEAAGcEWE%2FAsEIADvp0fR%2BAAE4BoIP%2BMD0CnCsixNryS%2BB4DW4K0ozQACoTL609sUfybA0eG7IGaL7wpBxXeDoAEogg7%2FC6ASQYf%2FDVCFoMN3AVQg6PDdADMg7Iqvghg%2BvgJiivgRIA4Pr8KYIvzbtSK8fjN08Aj3BLXDqLJyjKs4AAAAAElFTkSuQmCC",'
            '"external_link": "https://cyberpnk.win",'
            '"seller_fee_basis_points": 500,'
            '"fee_recipient": "', stringUtils.addressToString(recipient), '"'
        '}'));
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