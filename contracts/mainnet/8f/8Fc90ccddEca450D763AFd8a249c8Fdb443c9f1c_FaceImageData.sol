// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract FaceImageData {
    function getLabel(uint256 slot) public pure returns (string memory) {
        string[30] memory names = [
            "Red Lipstick",
            "Light Blue Goggles",
            "Black Goggles",
            "Fashion Glasses",
            "Light Blue Wrap Around Shades",
            "Black Wrap Around Shades",
            "Disguise",
            "3D Glasses",
            "Smile",
            "Serious",
            "Smile with Beard",
            "Serious with Beard",
            "Wink",
            "Wink with Beard",
            "Eyebrows",
            "Eyebrows with Beard",
            "Mustache",
            "Mustache",
            "Skeleton",
            "Monocle",
            "Monocle with Beard",
            "Eyepatch",
            "Eyepatch with Beard",
            "Smoking",
            "Black Aviator Glasses",
            "Black Aviator Glasses with Beard",
            "Round Glasses",
            "Round Glasses with Beard",
            "Black Round Glasses",
            "Black Round Glasses with Beard"
        ];
        return names[slot % names.length];
    }

    struct PathData {
        string d;
        string fill;
    }

    struct SVGComposition {
        PathData[3] paths;
    }

    function pathDataToSVG(PathData memory pathData)
        private
        pure
        returns (bytes memory)
    {
        if (bytes(pathData.d).length == 0) return bytes("");
        
        return
            abi.encodePacked(
                '<path fill-rule="evenodd" clip-rule="evenodd" d="',
                pathData.d,
                '" fill="',
                bytes(pathData.fill).length > 0 ? pathData.fill : "black",
                '" />'
            );
    }

    function getData(uint256 slot) public pure returns (bytes memory) {
        SVGComposition[30] memory svgData = [
            SVGComposition(
                [
                    PathData("M10 15H11V16H14V15H15V14H10V15Z", "#DD1A21"),
                    PathData("M9 11H11V13H9V11ZM14 11H16V13H14V11Z", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M17 11V13H13V12H12V13H8V11H17Z", "#78BFEA"),
                    PathData(
                        "M8 10H17V11H8V10ZM8 13V11H6V12H7V13H8ZM12 13V14H8V13H12ZM13 13H12V12H13V13ZM17 13V14H13V13H17ZM17 13H18V12H19V11H17V13ZM14 15H11V16H14V15Z",
                        ""
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M17 10V11H19V12H18V13H17V14H13V13H12V14H8V13H7V12H6V11H8V10H17ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M18 10V11H19V12H18V13H17V14H14V13H13V12H12V13H11V14H8V13H7V12H6V11H7V10H8V9H11V10H12V11H13V10H14V9H17V10H18ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M19 10V11H18V12H17V13H14V12H11V13H8V12H7V11H6V10H19Z",
                        "#78BFEA"
                    ),
                    PathData(
                        "M19 9H6V10H5V11H6V12H7V13H8V14H11V13H14V14H17V13H18V12H19V11H20V10H19V9ZM19 10V11H18V12H17V13H14V12H11V13H8V12H7V11H6V10H19ZM14 15H11V16H14V15Z",
                        ""
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M19 10V9H6V10H5V11H6V12H7V13H8V14H11V13H14V14H17V13H18V12H19V11H20V10H19Z",
                        ""
                    ),
                    PathData("M14 15H11V16H14V15Z", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 8H11V9H9V8ZM9 10H8V9H9V10ZM11 11V10H9V11H8V13H9V14H11V15H10V16H15V15H14V14H16V13H17V11H16V10H17V9H16V8H14V9H16V10H14V11H11ZM11 13V14H14V13H16V11H14V13H13V12H12V13H11ZM11 13H9V11H11V13Z",
                        ""
                    ),
                    PathData("M9 11H11V13H9V11ZM14 11H16V13H14V11Z", "#F4F4F4"),
                    PathData("M13 13V12H12V13H11V14H14V13H13Z", "#FCC39E")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M7 14V10H18V14H13V12H12V14H7ZM8 13H11V11H8V13ZM14 13H17V11H14V13ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("M11 11H8V13H11V11Z", "#00A3DA"),
                    PathData("M17 11H14V13H17V11Z", "#DD1A21")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 11H14V13H16V11ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 11H14V13H16V11ZM10 15H15V16H10V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 11H14V13H16V11ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 11H14V13H16V11ZM10 15H15V16H10V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 12H14V13H16V12ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 11H9V13H11V11ZM16 12H14V13H16V12ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 9H9V10H8V11H9V13H11V11H9V10H11V9ZM16 11H14V13H16V11ZM16 10H17V11H16V10ZM16 10H14V9H16V10ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M11 9H9V10H8V11H9V13H11V11H9V10H11V9ZM16 11H14V13H16V11ZM16 10H17V11H16V10ZM16 10H14V9H16V10ZM11 15H14V16H11V15ZM11 15H10V14H11V15ZM14 15H15V14H14V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 11H11V13H9V11ZM14 11H16V13H14V11ZM10 15H9V16H12V14H10V15ZM16 16H13V14H15V15H16V16Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 11H11V13H9V11ZM14 11H16V13H14V11ZM10 15H9V16H12V14H10V15ZM16 16H13V14H15V15H16V16Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 11H11V13H9V11ZM14 11H16V13H14V11ZM13 13H12V15H13V13ZM8 15V14H10V16H9V15H8ZM10 16H11V17H10V16ZM15 16H16V15H17V14H15V16ZM15 16V17H14V16H15ZM13 16H12V17H13V16Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M16 11H14V13H16V11Z", "#78BFEA"),
                    PathData(
                        "M16 10H14V11H13V13H14V14H16V13H17V11H16V10ZM16 11V13H14V11H16ZM11 11H9V13H11V11ZM14 15H11V14H10V15H11V16H14V15Z",
                        ""
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M16 11H14V13H16V11Z", "#78BFEA"),
                    PathData(
                        "M16 10H14V11H13V13H14V14H16V13H17V11H16V10ZM16 11V13H14V11H16ZM11 11H9V13H11V11ZM14 15H11V14H10V15H11V16H14V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    )
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 7H10V8H9V7ZM11 9H10V8H11V9ZM12 10H11V9H12V10ZM18 10H12V11H13V13H17V11H18V10ZM18 10H19V9H18V10ZM9 11V13H11V11H9ZM15 14H14V15H11V14H10V15H11V16H14V15H15V14Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 7H10V8H9V7ZM11 9H10V8H11V9ZM12 10H11V9H12V10ZM18 10H12V11H13V13H17V11H18V10ZM18 10H19V9H18V10ZM9 11V13H11V11H9ZM15 14H14V15H11V14H10V15H11V16H14V15H15V14Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M9 11H11V13H9V11ZM14 11H16V13H14V11ZM14 14H10V15H14V16H15V15H14V14Z",
                        ""
                    ),
                    PathData("M16 16H15V17H16V16Z", "#DD1A21"),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M17 10V11H18V12H17V13H14V12H13V11H12V12H11V13H8V12H7V11H8V10H17ZM10 14H11V15H10V14ZM14 15V16H11V15H14ZM14 15V14H15V15H14Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M17 10V11H18V12H17V13H14V12H13V11H12V12H11V13H8V12H7V11H8V10H17ZM10 14H11V15H10V14ZM14 15V16H11V15H14ZM14 15V14H15V15H14Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M9 11H11V13H9V11ZM14 11H16V13H14V11Z", "#78BFEA"),
                    PathData(
                        "M9 10H11V11H9V10ZM9 13H8V12H7V11H9V13ZM11 13V14H9V13H11ZM14 13H13V12H12V13H11V11H14V13ZM16 13H14V14H16V13ZM16 11H18V12H17V13H16V11ZM16 11H14V10H16V11ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData("M9 11H11V13H9V11ZM14 11H16V13H14V11Z", "#78BFEA"),
                    PathData(
                        "M9 10H11V11H9V10ZM9 13H8V12H7V11H9V13ZM11 13V14H9V13H11ZM14 13H13V12H12V13H11V11H14V13ZM16 13H14V14H16V13ZM16 11H18V12H17V13H16V11ZM16 11H14V10H16V11ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    )
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M16 10V11H18V12H17V13H16V14H14V13H13V12H12V13H11V14H9V13H8V12H7V11H9V10H11V11H14V10H16ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData("", ""),
                    PathData("", "")
                ]
            ),
            SVGComposition(
                [
                    PathData(
                        "M16 10V11H18V12H17V13H16V14H14V13H13V12H12V13H11V14H9V13H8V12H7V11H9V10H11V11H14V10H16ZM11 15H14V16H11V15Z",
                        ""
                    ),
                    PathData(
                        "M7 15H6V16H7V17H8V18H9V17H10V18H11V17H10V16H9V15H8V16H7V15ZM8 16V17H9V16H8ZM12 17H13V18H12V17ZM15 17H14V18H15V17ZM16 16H15V17H16V18H17V17H18V16H19V15H18V16H17V15H16V16ZM16 16V17H17V16H16Z",
                        "#491702"
                    ),
                    PathData("", "")
                ]
            )
        ];
        SVGComposition memory comp = svgData[slot % svgData.length];
        bytes memory svg = "";
        svg = abi.encodePacked(svg, pathDataToSVG(comp.paths[0]));
        svg = abi.encodePacked(svg, pathDataToSVG(comp.paths[1]));
        svg = abi.encodePacked(svg, pathDataToSVG(comp.paths[2]));
        return svg;
    }
}