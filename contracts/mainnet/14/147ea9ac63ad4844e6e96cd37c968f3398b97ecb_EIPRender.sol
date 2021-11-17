// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base64.sol";
import "./Strings.sol";

/*
 *
 *  ______ _____ _____    _   _ ______ _______
 * |  ____|_   _|  __ \  | \ | |  ____|__   __|
 * | |__    | | | |__) | |  \| | |__     | |
 * |  __|   | | |  ___/  | . ` |  __|    | |
 * | |____ _| |_| |      | |\  | |       | |
 * |______|_____|_|      |_| \_|_|       |_|
 * created by @aka_labs_, 2021
 *
 */

library EIPRender {
    using Strings for uint160;

    function generateMetadata(
        string memory name,
        string memory collectionInfo,
        address currentOwner,
        string memory dateCreated,
        string memory eipDescription
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description": "',
                                eipDescription,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                generateImage(name, collectionInfo, currentOwner, dateCreated),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _getBorderFade(address currentOwner) internal pure returns (string memory) {
        string memory bottomRight = "#81A7F8";
        string memory topLeft = "#CBAEFD";
        string memory xTop = "88";
        string memory xBottom = "202";
        if (uint160(currentOwner) % 2 == 0) {
            (bottomRight, topLeft) = (topLeft, bottomRight);
            (xTop, xBottom) = (xBottom, xTop);
        }
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg"><circle cx="',
                        xBottom,
                        '" cy="434" r="150px" fill="',
                        bottomRight,
                        '"/><circle cx="',
                        xTop,
                        '" cy="66" r="150px" fill="',
                        topLeft,
                        '"/></svg>'
                    )
                )
            );
    }

    function _getPolygon(address currentOwner) internal pure returns (string memory) {
        string memory fourthAndSixth = "#81A7F8";
        string memory thirdAndFifth = "#CBAEFD";
        string memory second = "#CEC0F9";
        string memory first = "#A6FBF7";
        if (uint160(currentOwner) % 2 == 0) {
            (first, second) = (second, first);
            (thirdAndFifth, fourthAndSixth) = (fourthAndSixth, thirdAndFifth);
        }
        return
            string(
                abi.encodePacked(
                    '<polygon points="392.07,0 383.5,29.11 383.5,873.74 392.07,882.29 784.13,650.54" fill="',
                    first,
                    '" stroke="rgb(0,0,0)" stroke-width="6"/><polygon points="392.07,0 0,650.54 392.07,882.29 392.07,472.33" fill="',
                    second,
                    '" stroke="rgb(0,0,0)" stroke-width="6"/><polygon points="392.07,956.52 387.24,962.41 387.24,1263.3 392.07,1277.4 784.37,724.89" fill="',
                    thirdAndFifth,
                    '" stroke="rgb(0,0,0)" stroke-width="6"/><polygon points="392.07,1277.4 392.07,956.52 0,724.89" fill="',
                    fourthAndSixth,
                    '" stroke="rgb(0,0,0)" stroke-width="6"/><polygon points="392.07,882.29 784.13,650.54 392.07,472.33" fill="',
                    thirdAndFifth,
                    '" stroke="rgb(0,0,0)" stroke-width="6"/><polygon points="0,650.54 392.07,882.29 392.07,472.33" fill="',
                    fourthAndSixth,
                    '" stroke="rgb(0,0,0)" stroke-width="6"/>'
                )
            );
    }

    function generateImage(
        string memory name,
        string memory collectionInfo,
        address currentOwner,
        string memory dateCreated
    ) public pure returns (string memory) {
        string
            memory description = "Ethereum Improvement Proposals (EIPs) describe standards for the Ethereum platform, including core protocol specifications, client APIs, and contract standards.";
        return
            Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                            '<defs><filter id="f1"><feImage result="p3" xlink:href="data:image/svg+xml;base64,',
                            _getBorderFade(currentOwner),
                            '"/>'
                            '<feGaussianBlur stdDeviation="42"/></filter><clipPath id="corners"><rect width="290" height="500" rx="42" ry="42"/></clipPath><path id="dpath" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z"/></defs>'
                            '<g clip-path="url(#corners)"><rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px"/></g>'
                            '<text text-rendering="optimizeSpeed"><textPath startOffset="-100%" font-family="Courier New" font-size="10px" xlink:href="#dpath">',
                            description,
                            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath><textPath startOffset="0%" fill="#000" font-family="Courier New" font-size="10px" xlink:href="#dpath">',
                            description,
                            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>'
                            '<rect x="20" y="25" width="250" height="450" rx="26" ry="26" fill="#f2f2f9" stroke="#000"/>',
                            '<text y="65px" x="50%" font-family="Courier New" font-weight="200" font-size="36px" dominant-baseline="middle" text-anchor="middle">',
                            name,
                            "</text>"
                            '<g transform="matrix(0.13 0 0 0.13 94.015951 143)">',
                            _getPolygon(currentOwner),
                            "</g>",
                            '<g style="transform:translate(65px, 95px)">',
                            '<rect width="160px" height="26px" rx="8px" ry="8px" fill="#fff" stroke="#000"/>',
                            '<text x="12px" y="17px" font-family="Courier New" font-size="12px">Created: ',
                            dateCreated,
                            "</text></g>",
                            '<g style="transform:translate(65px, 335px)">',
                            '<rect width="160px" height="50px" rx="8px" ry="8px" fill="#fff" stroke="#000"/><text x="30px" y="18px" font-family="Courier New" font-size="12px">Edition: ',
                            collectionInfo,
                            "</text>",
                            '<text x="30px" y="38px" font-family="Courier New" font-size="12px">Status: FINAL</text></g><g style="transform:translate(29px, 395px)"><rect width="232px" height="55px" rx="8px" ry="8px" fill="#fff" stroke="#000"/>',
                            '<text x="90px" y="22px" font-family="Courier New" font-size="12px">Minted:</text><text x="12px" y="36px" font-family="Courier New" font-size="8.3px">',
                            uint160(currentOwner).toHexString(20),
                            "</text></g></svg>"
                        )
                    )
                )
            );
    }
}