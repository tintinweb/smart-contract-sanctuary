// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HeadImageData {
    function getLabel(uint256 slot) public pure returns (string memory) {
        string[13] memory names = [
            "Light Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Light Nougat",
            "Nougat",
            "Brick Yellow",
            "Light Brown",
            "Dark Brown",
            "Light Yellow",
            "Yellow",
            "Bright Yellow",
            "Bright Orange"
        ];
        return names[slot % names.length];
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        string[13] memory colors = [
            "A0A19F",
            "42423E",
            "F4F4F4",
            "F6ADCD",
            "FCC39E",
            "DE8B5F",
            "DDC48E",
            "AF7446",
            "692E14",
            "FFF579",
            "FEE716",
            "FFCD03",
            "F57D20"
        ];
        return
            abi.encodePacked(
                '<path d="M10 5H15V6H10V5ZM18 8V7H7V8H6V17H7V18H18V17H19V8H18ZM16 19H9V20H16V19Z" fill="#',
                colors[slot % colors.length],
                '"/>'
                '<path d="M18 6V7H7V6H9V4H16V6H18ZM6 8V7H7V8H6ZM6 17H5V8H6V17ZM7 18H6V17H7V18ZM18 18V19H17V20H16V19H9V20H8V19H7V18H18ZM19 17H18V18H19V17ZM19 8H18V7H19V8ZM19 8V17H20V8H19ZM15 5H10V6H15V5Z" fill="black"/>'
            );
    }
}