// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BodyImageData {
    function getLabel(uint256 slot) public pure returns (string memory) {
        string[24] memory names = [
            "Aqua",
            "Light Blue",
            "Bright Blue",
            "Dark Blue",
            "Light Grey",
            "Medium Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Deep Blush",
            "Yellow Green",
            "Bright Green",
            "Dark Green",
            "Olive Green",
            "Light Nougat",
            "Nougat",
            "Brick Yellow",
            "Light Brown",
            "Dark Brown",
            "Light Yellow",
            "Yellow",
            "Bright Yellow",
            "Bright Orange",
            "Bright Red"
        ];
        return names[slot % names.length];
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        string[24] memory colors = [
            "C1E4DA",
            "78BFEA",
            "00A3DA",
            "006CB7",
            "A0A19F",
            "646765",
            "42423E",
            "F4F4F4",
            "F6ADCD",
            "E95DA2",
            "9ACA3C",
            "00AF4D",
            "009247",
            "828353",
            "FCC39E",
            "DE8B5F",
            "DDC48E",
            "AF7446",
            "692E14",
            "FFF579",
            "FEE716",
            "FFCD03",
            "F57D20",
            "DD1A21"
        ];
        return
            abi.encodePacked(
                '<path d="M15 15V20H19V21H6V20H10V15H15ZM5 24V21H6V24H5ZM5 24V25H4V24H5ZM20 24V21H19V24H20ZM20 24V25H21V24H20ZM11 20H14V16H11V20Z" fill="black"/>'
                '<path d="M11 16H14V20H11V16ZM19 21V24H20V25H5V24H6V21H19Z" fill="#',
                colors[slot % colors.length],
                '"/>'
            );
    }
}