// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";

/**************                                                                                             
                                                                                                                                                                                                                                     
                                                                
                                ████████████████                                
                                ██            ██                                
                           ▐████████████████████████▌                           
                         ▐██                        ▐██                         
                       ██                              ██                       
                       ██                              ██                       
                       ██                              ██                       
                       ██       ████▌                  ██                       
                       ██       ████▌       ████▌      ██                       
                       ██                              ██                       
                       ██                              ██                       
                       ██          ██       ██         ██                       
                       ██            ███████           ██
                       ██                              ██                       
                         ▐██                        ▐██            
                            ▐███████████████████████▌                         
                                ██            ██
                  █████  ▐████████████████████████████▌  █████                
                ██     ██                              ██     ██  
              ██       ██                              ██       ██             
              ██       ██                              ██       ██            
           ▐██       ██                                  ██▌      ██▌           
                                                                                
     ▄▄▄▄▄   ▄▄▄  ▄▄▄▄    ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄  ▄▄▄▄▄▄   ▄▄▄▄ ▄▄▄▄▄▄    ▄▄▄▄     
    █     █ █   █▀    █▄█▀   ▐█  █   █   █  ▀▄█▌     ██▀    █       ██▀    ▐█   
   █▌ ▀▀  ██  ▄█▌ ██▌  █   ████    ▄██      ▐██   ▀▀██   █  █  ▐██   ██  ▀▀█▄   
   █  ▀▀  █▌  ▀▀▌      ██     █▌     █   ██  █   ▀▀▀█▌  ▄▄  ██      █▌  ▀   █▌  
   ▀█▄▄▄▄█▀█▄▄▄█▀█▄▄▄██▀▀██▄▄█▀█▄██▄███▄█▀█▄▀▀█▄▄▄▄▄█▀██▀█▄███▄▄▄▄▄███▄▄▄▄██▀   
                                                                                
******************/

contract HeadwearImageData {
    function random(bytes memory input) private pure returns (uint256) {
        return uint256(keccak256(input));
    }

    struct PathData {
        // d is the path for the svg path element, or empty meaning dont output a path
        string d;
        // fill is either a hex string or empty for black
        string fill;
    }

    function pathDataToSVG(string memory d, string memory fill)
        private
        pure
        returns (bytes memory)
    {
        if (bytes(d).length == 0) return bytes("");

        return
            abi.encodePacked(
                '<path fill-rule="evenodd" clip-rule="evenodd" d="',
                d,
                '" fill="',
                bytes(fill).length > 0 ? fill : "black",
                '" />'
            );
    }

    /** HAIR */

    function hairColorIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("haircolor", slot));
        return rand % 17;
    }

    function hairTypeIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("hairtype", slot));
        return rand % 5;
    }

    function getHairLabel(uint256 slot) private pure returns (string memory) {
        string[17] memory hairColors = [
            "Light Blue",
            "Bright Blue",
            "Light Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Yellow Green",
            "Bright Green",
            "Light Nougat",
            "Nougat",
            "Light Brown",
            "Dark Brown",
            "Light Yellow",
            "Yellow",
            "Bright Yellow",
            "Bright Orange",
            "Bright Red"
        ];

        string[5] memory hairTypes = [
            "Short Hair",
            "Long Hair",
            "Wavy Hair",
            "Bowl Cut",
            "Puffy Hair"
        ];

        return
            string(
                abi.encodePacked(
                    hairColors[hairColorIndex(slot)],
                    " ",
                    hairTypes[hairTypeIndex(slot)]
                )
            );
    }

    function getHairSVG(uint256 slot) private pure returns (bytes memory) {
        string[5] memory outlinePaths = [
            /* Short Hair */
            "M17 2H8V3H6V4H5V6H4V8H3V13H4V14H5V13H6V10H7V9H16V8H18V10H19V13H20V14H21V13H22V8H21V6H20V4H19V3H17V2ZM17 3V4H19V6H20V8H21V13H20V10H19V8H18V7H16V8H7V9H6V10H5V13H4V8H5V6H6V4H8V3H17Z",
            /* Long hair */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM5 7V5H6V7H5ZM4 15V7H5V15H4ZM3 16V15H4V16H3ZM3 17H2V16H3V17ZM5 17V18H3V17H5ZM6 16V17H5V16H6ZM7 11V16H6V11H7ZM8 10V11H7V10H8ZM10 9V10H8V9H10ZM11 8V9H10V8H11ZM14 8H11V7H14V8ZM15 9H14V8H15V9ZM17 10H15V9H17V10ZM18 11H17V10H18V11ZM19 16H18V11H19V16ZM20 17V16H19V17H20ZM22 17V18H20V17H22ZM22 16H23V17H22V16ZM21 15H22V16H21V15ZM20 7H21V15H20V7ZM19 5H20V7H19V5ZM18 4H19V5H18V4ZM18 4V3H16V4H18Z",
            /* Wavy Hair */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM5 7V5H6V7H5ZM4 14V7H5V14H4ZM3 16H4V14H3V16ZM3 20V16H2V20H3ZM5 21H3V20H5V21ZM6 21V22H5V21H6ZM8 20V21H6V20H8ZM8 19H9V20H8V19ZM7 18H8V19H7V18ZM7 11V18H6V11H7ZM8 10V11H7V10H8ZM9 9V10H8V9H9ZM11 8V9H9V8H11ZM14 8H11V7H14V8ZM16 9H14V8H16V9ZM17 10H16V9H17V10ZM18 11H17V10H18V11ZM18 18V11H19V18H18ZM17 19V18H18V19H17ZM17 20H16V19H17V20ZM19 21H17V20H19V21ZM20 21V22H19V21H20ZM22 20V21H20V20H22ZM22 16H23V20H22V16ZM21 14H22V16H21V14ZM20 7H21V14H20V7ZM19 5H20V7H19V5ZM18 4H19V5H18V4ZM18 4V3H16V4H18Z",
            /* Bowl Cut */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM5 7H6V5H5V7ZM5 13V7H4V13H5ZM6 13V14H5V13H6ZM7 10V13H6V10H7ZM18 10H7V9H18V10ZM19 13H18V10H19V13ZM20 13V14H19V13H20ZM20 7H21V13H20V7ZM19 5H20V7H19V5ZM18 4H19V5H18V4ZM18 4V3H16V4H18Z",
            /* Puffy Hair */
            "M18 2H7V3H5V4H4V5H3V7H2V11H3V13H4V14H5V13H6V10H7V9H16V8H18V10H19V13H20V14H21V13H22V11H23V7H22V5H21V4H20V3H18V2ZM18 3V4H20V5H21V7H22V11H21V13H20V10H19V8H18V7H16V8H7V9H6V10H5V13H4V11H3V7H4V5H5V4H7V3H18Z"
        ];

        string[5] memory fillPaths = [
            /* Short Hair */
            "M20 8V6H19V4H17V3H8V4H6V6H5V8H4V13H5V10H6V9H7V8H16V7H18V8H19V10H20V13H21V8H20Z",
            /* Long hair */
            "M21 16V15H20V7H19V5H18V4H16V3H9V4H7V5H6V7H5V15H4V16H3V17H5V16H6V15V11H7V10H8V9H10V8H11V7H14V8H15V9H17V10H18V11H19V15V16H20V17H22V16H21Z",
            /* Wavy Hair */
            "M6 11V18H7V19H8V20H6V21H5V20H3V16H4V14H5V7H6V5H7V4H9V3H16V4H18V5H19V7H20V14H21V16H22V20H20V21H19V20H17V19H18V18H19V11H18V10H17V9H16V8H14V7H11V8H9V9H8V10H7V11H6Z",
            /* Bowl Cut */
            "M20 7V13H19V10H18V9H7V10H6V13H5V7H6V5H7V4H9V3H16V4H18V5H19V7H20Z",
            /* Puffy Hair */
            "M22 7V11H21V13H20V10H19V8H18V7H16V8H7V9H6V10H5V13H4V11H3V7H4V5H5V4H7V3H18V4H20V5H21V7H22Z"
        ];

        string[17] memory hairColors = [
            "#78BFEA",
            "#00A3DA",
            "#A0A19F",
            "#42423E",
            "#F4F4F4",
            "#F6ADCD",
            "#9ACA3C",
            "#00AF4D",
            "#FCC39E",
            "#DE8B5F",
            "#AF7446",
            "#692E14",
            "#FFF579",
            "#FEE716",
            "#FFCD03",
            "#F57D20",
            "#DD1A21"
        ];

        uint256 hairIndex = hairTypeIndex(slot);
        return
            abi.encodePacked(
                pathDataToSVG(outlinePaths[hairIndex], "black"),
                pathDataToSVG(
                    fillPaths[hairIndex],
                    hairColors[hairColorIndex(slot)]
                )
            );
    }

    /** HAT */
    function hatColorIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("hatcolor", slot));
        return rand;
    }

    function hatTypeIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("hattype", slot));
        return rand;
    }

    function getHatLabel(uint256 slot) private pure returns (string memory) {
        string[7] memory hatTypes = [
            "Cap",
            "Peaked Cap",
            "Hard Hat",
            "Bucket Hat",
            "Helmet",
            "Hoodie",
            "Beanie"
        ];
        string[12] memory hatColors = [
            "Bright Blue",
            "Dark Blue",
            "Light Grey",
            "Medium Grey",
            "Dark Grey",
            "White",
            "Light Pink",
            "Deep Blush",
            "Bright Green",
            "Bright Yellow",
            "Bright Orange",
            "Bright Red"
        ];

        return
            string(
                abi.encodePacked(
                    hatColors[hatColorIndex(slot) % hatColors.length],
                    " ",
                    hatTypes[hatTypeIndex(slot) % hatTypes.length]
                )
            );
    }

    function getHatSVG(uint256 slot) private pure returns (bytes memory) {
        string[7] memory outlinePaths = [
            /* Cap */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM5 7H6V5H5V7ZM5 9V7H4V9H5ZM23 9V10H5V9H23ZM23 8H24V9H23V8ZM20 7H23V8H20V7ZM19 5H20V7H19V5ZM18 4H19V5H18V4ZM18 4V3H16V4H18Z",
            /* Peaked Cap */
            "M3 2H22V3H3V2ZM3 5V3H2V5H3ZM5 6H3V5H5V6ZM20 6H5V7H4V9H5V10H20V9H21V7H20V6ZM22 5V6H20V5H22ZM22 5H23V3H22V5ZM20 7H5V9H20V7Z",
            /* Hard Hat */
            "M16 2H9V3H7V4H6V5H5V7H4V8H3V9H4V10H21V9H22V8H21V7H20V5H19V4H18V3H16V2ZM16 3V4H18V5H19V7H20V8H21V9H4V8H5V7H6V5H7V4H9V3H16Z",
            /* Bucket Hat */
            "M8 2H17V3H8V2ZM7 4V3H8V4H7ZM6 7V4H7V7H6ZM5 8V7H6V8H5ZM3 9H5V8H3V9ZM3 10V9H2V10H3ZM6 10V11H3V10H6ZM19 10H6V9H19V10ZM22 10V11H19V10H22ZM22 9H23V10H22V9ZM20 8H22V9H20V8ZM19 7H20V8H19V7ZM18 4H19V7H18V4ZM18 4V3H17V4H18Z",
            /* Helmet */
            "M8 3H17V4H8V3ZM7 5V4H8V5H7ZM6 6V5H7V6H6ZM5 8H6V6H5V8ZM5 19V8H4V19H5ZM6 20H5V19H6V20ZM19 20V21H6V20H19ZM20 19V20H19V19H20ZM20 8H21V19H20V8ZM19 6H20V8H19V6ZM18 5H19V6H18V5ZM18 5V4H17V5H18ZM18 10H19V17H18V10ZM7 10V9H18V10H7ZM7 17H6V10H7V17ZM7 17V18H18V17H7Z",
            /* Hoodie */
            "M10 2H15V3H10V2ZM8 4V3H10V4H8ZM6 5H8V4H6V5ZM5 6V5H6V6H5ZM4 8V6H5V8H4ZM3 11V8H4V11H3ZM3 17H2V11H3V17ZM4 19H3V18V17H4V18V19ZM5 21H4V19H5V21ZM6 21V22H5V21H6ZM6 12V17H7V18H8V20H7V21H6V18H5V12H6ZM7 10V12H6V10H7ZM8 9V10H7V9H8ZM10 8V9H8V8H10ZM15 8H10V7H15V8ZM17 9H15V8H17V9ZM18 10H17V9H18V10ZM19 12H18V10H19V12ZM19 21H18V20H17V18H18V17H19V12H20V18H19V20V21ZM20 21V22H19V21H20ZM21 19V21H20V19H21ZM22 17V19H21V17H22ZM22 11H23V17H22V11ZM21 8H22V11H21V8ZM20 6H21V8H20V6ZM19 5H20V6H19V5ZM17 4H19V5H17V4ZM17 4V3H15V4H17Z",
            /* Beanie */
            "M9 2H16V3H9V2ZM7 4V3H9V4H7ZM6 5V4H7V5H6ZM19 5V6H6V5H5V7H4V9H5V10H20V9H21V7H20V5H19ZM18 4H16V3H18V4ZM18 4V5H19V4H18ZM20 7V9H5V7H20Z"
        ];

        string[7] memory fillPaths = [
            /* Cap */
            "M23 8V9H5V7H6V5H7V4H9V3H16V4H18V5H19V7H20V8H23Z",
            /* Peaked Cap */
            "M3 5V3H22V5H20V6H5V5H3ZM5 7H20V9H5V7Z",
            /* Hard Hat */
            "M21 8V9H4V8H5V7H6V5H7V4H9V3H16V4H18V5H19V7H20V8H21Z",
            /* Bucket Hat */
            "M22 9V10H19V9H6V10H3V9H5V8H6V7H7V4H8V3H17V4H18V7H19V8H20V9H22Z",
            /* Helmet */
            "M18 18V17H19V10H18V9H7V10H6V17H7V18H18ZM20 8V19H19V20H6V19H5V8H6V6H7V5H8V4H17V5H18V6H19V8H20Z",
            /* Hoodie */
            "M21 11V8H20V6H19V5H17V4H15V3H10V4H8V5H6V6H5V8H4V11H3V17H4V19H5V21H6V18H5V12H6V10H7V9H8V8H10V7H15V8H17V9H18V10H19V12H20V18H19V21H20V19H21V17H22V11H21Z",
            /* Beanie */
            "M19 5V6H6V5H7V4H9V3H16V4H18V5H19ZM5 7H20V9H5V7Z"
        ];

        string[12] memory hatColors = [
            "#00A3DA",
            "#006CB7",
            "#A0A19F",
            "#646765",
            "#42423E",
            "#F4F4F4",
            "#F6ADCD",
            "#E95DA2",
            "#00AF4D",
            "#FFCD03",
            "#F57D20",
            "#DD1A21"
        ];

        uint256 hatIndex = hatTypeIndex(slot) % fillPaths.length;
        return
            abi.encodePacked(
                pathDataToSVG(outlinePaths[hatIndex], "black"),
                pathDataToSVG(
                    fillPaths[hatIndex],
                    hatColors[hatColorIndex(slot) % hatColors.length]
                )
            );
    }

    /** HELMET */

    function helmetStyleIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("helmet", slot));
        return rand % 17;
    }

    function getHelmetLabel(uint256 slot) private pure returns (string memory) {
        string[17] memory helmetLabels = [
            // Blue Visor
            "Bright Blue",
            "Light Grey ",
            "Dark Grey",
            "Bright Blue",
            "Light Pink",
            "Deep Blush",
            "White",
            "Bright Yellow",
            "Bright Red",
            "Bright Green",
            // Red Visor
            "White",
            "Bright Yellow",
            "Bright Blue",
            // Dark Visor
            "Bright Blue",
            "White",
            "Bright Red",
            "Bright Green"
        ];
        uint256 styleIndex = helmetStyleIndex(slot);
        string memory visorColor = "Blue";
        if (styleIndex > 12) {
            visorColor = "Dark";
        } else if (styleIndex > 9) {
            visorColor = "Red";
        }
        return
            string(
                abi.encodePacked(
                    helmetLabels[styleIndex],
                    " Helmet with ",
                    visorColor,
                    " Visor"
                )
            );
    }

    function getHelmetSVG(uint256 slot) private pure returns (bytes memory) {
        string
            memory outlinePath = "M17 3H8V4H7V5H6V6H5V8H4V9V10H3V18H4V19H5V20H6V21H19V20H20V19H21V18H22V10H21V9V8H20V6H19V5H18V4H17V3ZM17 4V5H18V6H19V8H20V9H5V8H6V6H7V5H8V4H17ZM20 15V14H21V10H19V15H20ZM18 16H20V15H21V18H20V19H19V20H6V19H5V18H4V15H5V16H7V17H9V18H16V17H18V16ZM18 16H16V17H9V16H7V10H18V16ZM5 15H6V10H4V14H5V15Z";
        string
            memory fill = "M19 8H20V9H5V8H6V6H7V5H8V4H17V5H18V6H19V8ZM4 14V10H6V15H5V14H4ZM20 15V16H18V17H16V18H9V17H7V16H5V15H4V18H5V19H6V20H19V19H20V18H21V15H20ZM20 15H19V10H21V14H20V15Z";
        string
            memory visor = "M21 10V14H20V15H18V16H16V17H9V16H7V15H5V14H4V10H21Z";
        string[17] memory colors = [
            "#00A3DA",
            "#A0A19F",
            "#42423E",
            "#F6ADCD",
            "#E95DA2",
            "#F4F4F4",
            "#FFCD03",
            "#DD1A21",
            "#00AF4D",
            "#F4F4F4",
            "#FFCD03",
            "#00A3DA",
            "#00A3DA",
            "#42423E",
            "#F4F4F4",
            "#DD1A21",
            "#00AF4D"
        ];

        uint256 styleIndex = helmetStyleIndex(slot);
        string memory visorColor = "#00A3DA7F"; // Transparent blue
        if (styleIndex > 12) {
            visorColor = "#42423E";
        } else if (styleIndex > 9) {
            visorColor = "#DD1A217F";
        }

        return
            abi.encodePacked(
                pathDataToSVG(outlinePath, "black"),
                pathDataToSVG(fill, colors[styleIndex]),
                pathDataToSVG(visor, visorColor)
            );
    }

    /** EXTRAS */

    function extrasStyleIndex(uint256 slot) private pure returns (uint256) {
        uint256 rand = random(abi.encodePacked("extras", slot));
        return rand;
    }

    function getExtrasSVG(uint256 slot) public pure returns (bytes memory) {
        string[8] memory extraSVGs = [
            // VR Helmet
            '<path d="M7 9H6V10H7V9Z" fill="#DD1A21"/>'
            '<path d="M7 6H18V4H16V3H9V4H7V6ZM20 7H5V8H4V14H5V15H20V14H21V8H20V7ZM7 10V11H6V10H5V9H6V8H7V9H8V10H7Z" fill="#42423E"/>'
            '<path d="M16 2H9V3H7V4H6V6H5V7H4V8H3V14H4V15H5V16H20V15H21V14H22V8H21V7H20V6H19V4H18V3H16V2ZM16 3V4H18V6H7V4H9V3H16ZM20 7V8H21V14H20V15H5V14H4V8H5V7H20ZM8 9H7V8H6V9H5V10H6V11H7V10H8V9ZM7 10H6V9H7V10Z" fill="black"/>',
            // Ghost
            '<path d="M11 10V13H10V14H8V12H9V11H10V10H11ZM16 12H17V14H15V13H14V10H15V11H16V12ZM16 15V16H15V15H16ZM10 16H15V17H14V18H11V17H10V16ZM10 16V15H9V16H10ZM5 25H20V24H21V25H24V24H23V22H22V21H20V11H19V8H18V6H17V4H15V3H10V4H8V6H7V8H6V11H5V21H3V22H2V24H1V25H4V24H5V25ZM5 24H6V21H5V24ZM20 21H19V24H20V21Z" fill="#F4F4F4"/>'
            '<path d="M15 2H10V3H8V4H7V6H6V8H5V11H4V20H3V21H2V22H1V24H0V25H1V24H2V22H3V21H5V24H4V25H5V24H6V21H5V11H6V8H7V6H8V4H10V3H15V4H17V6H18V8H19V11H20V21H19V24H20V25H21V24H20V21H22V22H23V24H24V25H25V24H24V22H23V21H22V20H21V11H20V8H19V6H18V4H17V3H15V2ZM16 15H15V16H10V15H9V16H10V17H11V18H14V17H15V16H16V15ZM15 11H16V12H17V14H15V13H14V10H15V11ZM10 13H11V10H10V11H9V12H8V14H10V13Z" fill="black"/>',
            // Pumpkin
            '<path d="M19 11H18V10H17V9H16V10H15V11H14V12H16V13H17V12H19V11ZM18 7V8H19V9H20V8H19V7H18V6H17V7H18ZM18 18V17H19V16H20V14H19V16H18V17H17V18H18ZM13 10V7H12V10H13ZM14 13H13V12H12V13H11V14H14V13ZM7 10V11H6V12H8V13H9V12H11V11H10V10H9V9H8V10H7ZM7 6V7H6V8H5V9H6V8H7V7H8V6H7ZM8 18V17H7V16H6V14H5V16H6V17H7V18H8ZM8 15V16H9V17H10V18H11V17H12V18H13V17H14V18H15V17H16V16H17V15H15V16H14V15H11V16H10V15H8ZM4 15H3V9H4V7H5V6H6V5H8V4H11V5H12V6H13V5H14V4H17V5H19V6H20V7H21V9H22V15H21V17H20V18H19V19H18V20H7V19H6V18H5V17H4V15Z" fill="#F57D20"/>'
            '<path d="M12 1H13V2H12V1ZM12 5V2H11V3H8V4H6V5H5V6H4V7H3V9H2V15H3V17H4V18H5V19H6V20H7V21H18V20H19V19H20V18H21V17H22V15H23V9H22V7H21V6H20V5H19V4H17V3H14V2H13V5H12ZM12 5V6H13V5H14V4H17V5H19V6H20V7H21V9H22V15H21V17H20V18H19V19H18V20H7V19H6V18H5V17H4V15H3V9H4V7H5V6H6V5H8V4H11V5H12ZM20 8H19V7H18V6H17V7H18V8H19V9H20V8ZM19 14H20V16H19V14ZM18 17V16H19V17H18ZM18 17V18H17V17H18ZM17 13H16V12H14V11H15V10H16V9H17V10H18V11H19V12H17V13ZM13 7H12V10H13V7ZM11 14H14V13H13V12H12V13H11V14ZM15 16V15H17V16H16V17H15V18H14V17H13V18H12V17H11V18H10V17H9V16H8V15H10V16H11V15H14V16H15ZM8 6H7V7H6V8H5V9H6V8H7V7H8V6ZM8 10H7V11H6V12H8V13H9V12H11V11H10V10H9V9H8V10ZM7 17H8V18H7V17ZM6 16H7V17H6V16ZM6 16V14H5V16H6Z" fill="black"/>'
            '<path d="M13 2H12V5H13V2Z" fill="#692E14"/>',
            // Fishbowl
            '<path d="M6 3H19V4H6V3ZM14 10V9H15V10H14ZM14 7V8H13V7H14ZM15 7V6H16V7H15ZM12 16V17H11V16H10H9V15H8V16H7V15H6V14H7V13H6V12H7V11H8V12H9V11H10V10H11V9H12V10H13V11H14V12H15V13V14H14V15H13V16H12ZM4 15V17H5V18H6V19H7V20H18V19H19V18H20V17H21V15H22V9H21V7H20V6H19V5H6V6H5V7H4V9H3V15H4Z" fill="#78BFEA"/>'
            '<path d="M13 12V13H12V12H13ZM8 14H9V15H10H11V16H12V15H13V14H14V13V12H13V11H12V10H11V11H10V12H9V13H8V12H7V13H8V14ZM8 14V15H7V14H8Z" fill="#F57D20"/>'
            '<path d="M6 2H19V3H6V2ZM6 4H5V3H6V4ZM19 4H6V5H5V6H4V7H3V9H2V15H3V17H4V18H5V19H6V20H7V21H18V20H19V19H20V18H21V17H22V15H23V9H22V7H21V6H20V5H19V4ZM19 4H20V3H19V4ZM19 5V6H20V7H21V9H22V15H21V17H20V18H19V19H18V20H7V19H6V18H5V17H4V15H3V9H4V7H5V6H6V5H19ZM16 6H15V7H16V6ZM14 9H15V10H14V9ZM14 13V14H13V15H12V16H11V15H10H9V14H8V13H9V12H10V11H11V10H12V11H13V12H12V13H13V12H14V13ZM14 12V11H13V10H12V9H11V10H10V11H9V12H8V11H7V12H6V13H7V14H6V15H7V16H8V15H9V16H10H11V17H12V16H13V15H14V14H15V13V12H14ZM8 15H7V14H8V15ZM7 13V12H8V13H7ZM14 7H13V8H14V7Z" fill="black"/>',
            // Chef Hat
            '<path d="M22 5V7H20V9H5V7H3V5H4V4H6V3H9V2H16V3H19V4H21V5H22Z" fill="#F4F4F4"/>'
            '<path d="M16 1H9V2H6V3H4V4H3V5H2V7H3V8H4V9H5V10H20V9H21V8H22V7H23V5H22V4H21V3H19V2H16V1ZM16 2V3H19V4H21V5H22V7H20V9H5V7H3V5H4V4H6V3H9V2H16Z" fill="black"/>',
            // Snorkel
            '<path d="M20 15V16H15V17H14V18H11V17H10V14H15V15H19V14H20V4H21V15H20Z" fill="#C1E4DA"/>'
            '<path d="M17 10V14H15V13H10V14H8V10H17Z" fill="#78BFEA"/>'
            '<path d="M20 4V3H22V15H21V4H20ZM19 14V4H20V14H19ZM15 14V15H19V14H18V10H17V9H8V10H7V14H8V15H9V17H10V18H11V19H14V18H15V17H20V16H21V15H20V16H15V17H14V18H11V17H10V14H15ZM15 14V13H10V14H8V10H17V14H15Z" fill="black"/>',
            // Bright Red Beret
            '<path d="M20 5V4H5V5H3V6H4V7H5V9H20V7H21V6H22V5H20Z" fill="#DD1A21"/>'
            '<path d="M11 1H12V2H11V1ZM20 4V3H13V2H12V3H5V4H3V5H2V6H3V7H4V9H5V10H20V9H21V7H22V6H23V5H22V4H20ZM20 4V5H22V6H21V7H20V9H5V7H4V6H3V5H5V4H20Z" fill="black"/>',
            // Cowboy hat
            '<path d="M17 4H18V7H7V4H8V3H9V2H16V3H17V4ZM21 7V6H22V8H21V9H4V8H3V6H4V7H5V8H20V7H21Z" fill="#AF7446"/>'
            '<path d="M16 1H9V2H8V3H7V4H6V7H5V6H4V5H3V6H2V8H3V9H4V10H21V9H22V8H23V6H22V5H21V6H20V7H19V4H18V3H17V2H16V1ZM16 2V3H17V4H18V7H7V4H8V3H9V2H16ZM20 7H21V6H22V8H21V9H4V8H3V6H4V7H5V8H20V7Z" fill="black"/>'
        ];
        return bytes(extraSVGs[extrasStyleIndex(slot) % extraSVGs.length]);
    }

    function getExtrasLabel(uint256 slot) private pure returns (string memory) {
        string[8] memory labels = [
            "VR Helmet",
            "Ghost",
            "Pumpkin",
            "Fish Bowl",
            "Chef Hat",
            "Snorkel",
            "Beret",
            "Cowboy Hat"
        ];
        return labels[extrasStyleIndex(slot) % labels.length];
    }

    /** MOTOCROSS */

    function getMotocrossColorIndex(uint256 slot)
        private
        pure
        returns (uint256)
    {
        return random(abi.encodePacked("motocross", slot)) % 6;
    }

    function getMotocrossSVG(uint256 slot) private pure returns (bytes memory) {
        string
            memory helmetFill = "M19 8V6H18V4H16V3H9V4H7V6H6V8H5V16H6V18H7V19H8V20H9V21H16V20H17V19H18V18H19V16H20V8H19ZM12 19H11V18H12V19ZM12 17H11V16H12V17ZM14 19H13V18H14V19ZM14 17H13V16H14V17ZM19 14H18V15H17V16H15V15H14V14H11V15H10V16H8V15H7V14H6V11H7V10H8V9H17V10H18V11H19V14Z";
        string
            memory visorFill = "M8 10H17V11H18V14H17V15H15V14H14V13H11V14H10V15H8V14H7V11H8V10Z";
        string
            memory outline = "M16 2H9V3H7V4H6V6H5V8H4V16H5V18H6V19H7V20H8V21H9V22H16V21H17V20H18V19H19V18H20V16H21V8H20V6H19V4H18V3H16V2ZM16 3V4H18V6H19V8H20V11V16H19V18H18V19H17V20H16V21H9V20H8V19H7V18H6V16H5V8H6V6H7V4H9V3H16ZM19 11H18V10H17V9H8V10H7V11H6V14H7V15H8V16H10V15H11V14H14V15H15V16H17V15H18V14H19V11ZM18 14H17V15H15V14H14V13H11V14H10V15H8V14H7V11H8V10H17V11H18V14ZM14 18H13V19H14V18ZM13 16H14V17H13V16ZM11 18H12V19H11V18ZM12 16H11V17H12V16Z";

        string[6] memory colors = [
            "#00A3DA", // "Bright Blue",
            "#A0A19F", // "Light Grey",
            "#F4F4F4", // "White",
            "#00AF4D", // "Bright Green",
            "#FFCD03", // "Bright Yellow",
            "#DD1A21" // "Bright Red"
        ];
        return
            abi.encodePacked(
                pathDataToSVG(helmetFill, colors[getMotocrossColorIndex(slot)]),
                pathDataToSVG(visorFill, "#78BFEA"),
                pathDataToSVG(outline, "black")
            );
    }

    function getMotocrossLabel(uint256 slot)
        private
        pure
        returns (string memory)
    {
        string[6] memory labels = [
            "Bright Blue",
            "Light Grey",
            "White",
            "Bright Green",
            "Bright Yellow",
            "Bright Red"
        ];
        return
            string(
                abi.encodePacked(
                    labels[getMotocrossColorIndex(slot)],
                    " Motocross Helmet"
                )
            );
    }

    /** FACE SHIELD */

    function getFaceShieldColorIndex(uint256 slot)
        private
        pure
        returns (uint256)
    {
        return random(abi.encodePacked("faceshield", slot)) % 6;
    }

    function getFaceShieldSVG(uint256 slot)
        private
        pure
        returns (bytes memory)
    {
        string
            memory helmetFill = "M16 8V7H9V8H16ZM16 4H18V5H19V7H20V12H19V10H18V9H7V10H6V12H5V7H6V5H7V4H9V3H16V4Z";
        string memory visorFill = "M19 12V17H18V18H7V17H6V12H7V10H18V12H19Z";
        string
            memory outline = "M16 2H9V3H7V4H6V5H5V7H4V12H5V17H6V18H7V19H18V18H19V17H20V12H21V7H20V5H19V4H18V3H16V2ZM16 3V4H18V5H19V7H20V12H19V10H18V9H7V10H6V12H5V7H6V5H7V4H9V3H16ZM6 12H7V10H18V12H19V17H18V18H7V17H6V12ZM9 7H16V8H9V7Z";

        string[6] memory colors = [
            "#42423E",
            "#F4F4F4",
            "#FFCD03",
            "#DD1A21",
            "#006CB7",
            "#00AF4D"
        ];
        return
            abi.encodePacked(
                pathDataToSVG(
                    helmetFill,
                    colors[getFaceShieldColorIndex(slot)]
                ),
                pathDataToSVG(visorFill, "#00A3DA7F"),
                pathDataToSVG(outline, "black")
            );
    }

    function getFaceShieldLabel(uint256 slot)
        private
        pure
        returns (string memory)
    {
        string[6] memory labels = [
            "Dark Grey",
            "White",
            "Bright Yellow",
            "Bright Red",
            "Dark Blue",
            "Bright Green"
        ];
        return
            string(
                abi.encodePacked(
                    labels[getFaceShieldColorIndex(slot)],
                    " Helmet with Face Shield"
                )
            );
    }

    string constant RAND_SEED = "hwlabel";

    // In order to choose between which type of headwear we want to use
    // lets choose a random number between 0-99 and pick a section based off that.
    function typeOffset(uint256 slot) public pure returns (uint256) {
        return random(abi.encodePacked(RAND_SEED, slot)) % 100;
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        uint256 section = typeOffset(slot);
        if (section < 1) {
            return getExtrasSVG(slot);
        } else if (section < 5) {
            return getMotocrossSVG(slot);
        } else if (section < 30) {
            return getHairSVG(slot);
        } else if (section < 80) {
            return getHatSVG(slot);
        } else if (section < 90) {
            return getHelmetSVG(slot);
        } else {
            return bytes("");
        }
    }

    function getLabel(uint256 slot) public pure returns (string memory) {
        uint256 section = typeOffset(slot);
        if (section < 1) {
            // 1% get extras
            return getExtrasLabel(slot);
        } else if (section < 5) {
            // 4% get motocross
            return getMotocrossLabel(slot);
        } else if (section < 30) {
            // 25% get hair
            return getHairLabel(slot);
        } else if (section < 80) {
            // 50% get hats
            return getHatLabel(slot);
        } else if (section < 90) {
            // 10% get helmets
            return getHelmetLabel(slot);
        } else {
            // 10% get none
            return "None";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}