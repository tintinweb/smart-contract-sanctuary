// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Accessory SVG generator
library AccessoryDetail {
    /// @dev Accessory N°1 => Classic
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Accessory N°2 => Glasses
    function item_2() public pure returns (string memory) {
        return base(glasses("D1F5FF", "000000", "0.31"));
    }

    /// @dev Accessory N°3 => Bow Tie
    // tslint:disable-next-line:max-line-length
    function item_3() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="7" stroke-miterlimit="10" d="M176.2,312.5 c3.8,0.3,26.6,7.2,81.4-0.4"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#DF0849" stroke="#000000" stroke-miterlimit="10" d="M211.3,322.1 c-2.5-0.3-5-0.5-7.4,0c-1.1,0-1.9-1.4-1.9-3.1v-4.5c0-1.7,0.9-3.1,1.9-3.1c2.3,0.6,4.8,0.5,7.4,0c1.1,0,1.9,1.4,1.9,3.1v4.5 C213.2,320.6,212.3,322.1,211.3,322.1z"/>',
                        '<path fill="#DF0849" stroke="#000000" stroke-miterlimit="10" d="M202.4,321.5c0,0-14,5.6-17.7,5.3c-1.1-0.1-2.5-4.6-1.2-10.5 c0,0-1-2.2-0.3-9.5c0.4-3.4,19.2,5.1,19.2,5.1S201,316.9,202.4,321.5z"/>',
                        '<path fill="#DF0849" stroke="#000000" stroke-miterlimit="10" d="M212.6,321.5c0,0,14,5.6,17.7,5.3c1.1-0.1,2.5-4.6,1.2-10.5 c0,0,1-2.2,0.3-9.5c-0.4-3.4-19.2,5.1-19.2,5.1S213.9,316.9,212.6,321.5z"/>',
                        '<path opacity="0.41" d="M213.6,315.9l6.4-1.1l-3.6,1.9l4.1,1.1l-7-0.6L213.6,315.9z M201.4,316.2l-6.4-1.1l3.6,1.9l-4.1,1.1l7-0.6L201.4,316.2z"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°4 => Monk Beads Classic
    function item_4() public pure returns (string memory) {
        return base(monkBeads("63205A"));
    }

    /// @dev Accessory N°5 => Monk Beads Silver
    function item_5() public pure returns (string memory) {
        return base(monkBeads("C7D2D4"));
    }

    /// @dev Accessory N°6 => Power Pole
// tslint:disable-next-line:max-line-length
    function item_6() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FF6F4F" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M272.3,331.9l55.2-74.4c0,0,3,4.3,8.7,7.5l-54,72.3"/>',
                        '<polygon fill="#BA513A" points="335.9,265.3 334.2,264.1 279.9,336.1 281.8,337.1"/>',
                        '<ellipse transform="matrix(0.6516 -0.7586 0.7586 0.6516 -82.3719 342.7996)" fill="#B54E36" stroke="#000000" stroke-width="0.25" stroke-miterlimit="10" cx="332" cy="261.1" rx="1.2" ry="6.1"/>',
                        '<path fill="none" stroke="#B09E00" stroke-miterlimit="10" d="M276.9,335.3c-52.7,31.1-119.3,49.4-120.7,49"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°7 => Vintage Glasses
    function item_7() public pure returns (string memory) {
        return base(glasses("FC55FF", "DFA500", "0.31"));
    }

    /// @dev Accessory N°8 => Monk Beads Gold
    function item_8() public pure returns (string memory) {
        return base(monkBeads("FFDD00"));
    }

    /// @dev Accessory N°9 => Eye Patch
    // tslint:disable-next-line:max-line-length
    function item_9() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#FCFEFF" stroke="#4A6362" stroke-miterlimit="10" d="M253.6,222.7H219c-4.7,0-8.5-3.8-8.5-8.5v-20.8 c0-4.7,3.8-8.5,8.5-8.5h34.6c4.7,0,8.5,3.8,8.5,8.5v20.8C262.1,218.9,258.3,222.7,253.6,222.7z"/>',
                        '<path fill="none" stroke="#4A6362" stroke-width="0.75" stroke-miterlimit="10" d="M250.1,218.9h-27.6c-3.8,0-6.8-3.1-6.8-6.8 v-16.3c0-3.8,3.1-6.8,6.8-6.8h27.6c3.8,0,6.8,3.1,6.8,6.8V212C257,215.8,253.9,218.9,250.1,218.9z"/>',
                        '<line fill="none" stroke="#3C4F4E" stroke-linecap="round" stroke-miterlimit="10" x1="211.9" y1="188.4" x2="131.8" y2="183.1"/>',
                        '<line fill="none" stroke="#3C4F4E" stroke-linecap="round" stroke-miterlimit="10" x1="259.9" y1="188.1" x2="293.4" y2="196.7"/>',
                        '<line fill="none" stroke="#3C4F4E" stroke-linecap="round" stroke-miterlimit="10" x1="259.2" y1="220.6" x2="277.5" y2="251.6"/>',
                        '<line fill="none" stroke="#3C4F4E" stroke-linecap="round" stroke-miterlimit="10" x1="211.4" y1="219.1" x2="140.5" y2="242"/>',
                        '<g fill-rule="evenodd" clip-rule="evenodd" fill="#636363" stroke="#4A6362" stroke-width="0.25" stroke-miterlimit="10"><ellipse cx="250.9" cy="215" rx="0.8" ry="1.1"/><ellipse cx="236.9" cy="215" rx="0.8" ry="1.1"/><ellipse cx="250.9" cy="203.9" rx="0.8" ry="1.1"/><ellipse cx="250.9" cy="193.8" rx="0.8" ry="1.1"/><ellipse cx="236.9" cy="193.8" rx="0.8" ry="1.1"/><ellipse cx="221.3" cy="215" rx="0.8" ry="1.1"/><ellipse cx="221.3" cy="203.9" rx="0.8" ry="1.1"/><ellipse cx="221.3" cy="193.8" rx="0.8" ry="1.1"/></g>'
                    )
                )
            );
    }

    /// @dev Accessory N°10 => Sun Glasses
    function item_10() public pure returns (string memory) {
        return base(glasses(Colors.BLACK, Colors.BLACK_DEEP, "1"));
    }

    /// @dev Accessory N°11 => Monk Beads Diamond
    function item_11() public pure returns (string memory) {
        return base(monkBeads("AAFFFD"));
    }

    /// @dev Accessory N°12 => Horns
// tslint:disable-next-line:max-line-length
    function item_12() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-linejoin="round" stroke-miterlimit="10" d="M257.7,96.3c0,0,35-18.3,46.3-42.9c0,0-0.9,37.6-23.2,67.6C269.8,115.6,261.8,107.3,257.7,96.3z"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-linejoin="round" stroke-miterlimit="10" d="M162,96.7c0,0-33-17.3-43.7-40.5c0,0,0.9,35.5,21.8,63.8C150.6,114.9,158.1,107.1,162,96.7z"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°13 => Halo
    function item_13() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#F6FF99" stroke="#000000" stroke-miterlimit="10" d="M136,67.3c0,14.6,34.5,26.4,77,26.4s77-11.8,77-26.4s-34.5-26.4-77-26.4S136,52.7,136,67.3L136,67.3z M213,79.7c-31.4,0-56.9-6.4-56.9-14.2s25.5-14.2,56.9-14.2s56.9,6.4,56.9,14.2S244.4,79.7,213,79.7z"/>'
                    )
                )
            );
    }

    /// @dev Accessory N°14 => Saiki Power
    // tslint:disable-next-line:max-line-length
    function item_14() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<line fill="none" stroke="#000000" stroke-width="5" stroke-miterlimit="10" x1="270.5" y1="105.7" x2="281.7" y2="91.7"/>',
                        '<circle fill="#EB7FFF" stroke="#000000" stroke-miterlimit="10" cx="285.7" cy="85.2" r="9.2"/>',
                        '<line fill="none" stroke="#000000" stroke-width="5" stroke-miterlimit="10" x1="155.8" y1="105.7" x2="144.5" y2="91.7"/>',
                        '<circle fill="#EB7FFF" stroke="#000000" stroke-miterlimit="10" cx="138.7" cy="85.2" r="9.2"/>',
                        '<path opacity="0.17" d="M287.3,76.6c0,0,10.2,8.2,0,17.1c0,0,7.8-0.7,7.4-9.5 C293,75.9,287.3,76.6,287.3,76.6z"/>',
                        '<path opacity="0.17" d="M137,76.4c0,0-10.2,8.2,0,17.1c0,0-7.8-0.7-7.4-9.5 C131.4,75.8,137,76.4,137,76.4z"/>',
                        '<ellipse transform="matrix(0.4588 -0.8885 0.8885 0.4588 80.0823 294.4391)" fill="#FFFFFF" cx="281.8" cy="81.5" rx="2.1" ry="1.5"/>',
                        '<ellipse transform="matrix(0.8885 -0.4588 0.4588 0.8885 -21.756 74.6221)" fill="#FFFFFF" cx="142.7" cy="82.1" rx="1.5" ry="2.1"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M159.6,101.4c0,0-1.1,4.4-7.4,7.2"/>',
                        '<path fill="none" stroke="#000000" stroke-miterlimit="10" d="M267.2,101.4c0,0,1.1,4.4,7.4,7.2"/>',
                        abi.encodePacked(
                            '<polygon opacity="0.68" fill="#7FFF35" points="126,189.5 185.7,191.8 188.6,199.6 184.6,207.4 157.3,217.9 128.6,203.7"/>',
                            '<polygon opacity="0.68" fill="#7FFF35" points="265.7,189.5 206.7,191.8 203.8,199.6 207.7,207.4 234.8,217.9 263.2,203.7"/>',
                            '<polyline fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="196.5,195.7 191.8,195.4 187,190.9 184.8,192.3 188.5,198.9 183,206.8 187.6,208.3 193.1,201.2 196.5,201.2"/>',
                            '<polyline fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="196.4,195.7 201.1,195.4 205.9,190.9 208.1,192.3 204.4,198.9 209.9,206.8 205.3,208.3 199.8,201.2 196.4,201.2"/>',
                            '<polygon fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="123.8,189.5 126.3,203 129.2,204.4 127.5,189.5"/>',
                            '<polygon fill="#FFFFFF" stroke="#424242" stroke-width="0.5" stroke-miterlimit="10" points="265.8,189.4 263.3,203.7 284.3,200.6 285.3,189.4"/>'
                        )
                    )
                )
            );
    }

    /// @dev Accessory N°15 => No Face
// tslint:disable-next-line:max-line-length
    function item_15() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#F5F4F3" stroke="#000000" stroke-miterlimit="10" d="M285.5,177.9c0,68.3-19.6,127.3-77.9,128.2 c-58.4,0.9-74.4-57.1-74.4-125.4s14.4-103.5,72.7-103.5C266.7,77.2,285.5,109.6,285.5,177.9z"/>',
                        '<path opacity="0.08" d="M285.4,176.9c0,68.3-19.4,127.6-78,129.3 c27.2-17.6,28.3-49.1,28.3-117.3s23.8-86-30-111.6C266.4,77.3,285.4,108.7,285.4,176.9z"/>',
                        '<ellipse cx="243.2" cy="180.7" rx="16.9" ry="6.1"/>',
                        '<path d="M231.4,273.6c0.3-7.2-12.1-6.1-27.2-6.1s-27.4-1.4-27.2,6.1c0.1,3.4,12.1,6.1,27.2,6.1S231.3,277,231.4,273.6z"/>',
                        '<ellipse cx="162" cy="180.5" rx="16.3" ry="6"/>',
                        '<path fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M149.7,191.4c0,0,6.7,5.8,20.5,0.6"/>',
                        '<path fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M232.9,191.3c0,0,6.6,5.7,20.4,0.6"/>',
                        '<path fill="#F2EDED" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M192.7,285.1c0,0,9.2,3.5,21.6,0"/>',
                        '<path fill="#996DAD" d="M150.8,200.5c1.5-3.6,17.2-3.4,18.8-0.4c1.8,3.2-4.8,45.7-6.6,46C159.8,246.8,148.1,211.1,150.8,200.5z"/>',
                        '<path fill="#996DAD" d="M233.9,199.8c1.5-3.6,18-2.7,19.7,0.3c3.7,6.4-6.5,45.5-9.3,45.4C241,245.2,231.1,210.4,233.9,199.8z"/>',
                        '<path fill="#996DAD" d="M231.3,160.6c1.3,2.3,14.7,2.1,16.1,0.2c1.6-2-4.1-27.7-7.2-28.2C236.9,132.2,229,154.1,231.3,160.6z"/>',
                        '<path fill="#996DAD" d="M152.9,163.2c1.3,2.3,14.7,2.1,16.1,0.2c1.6-2-4.1-27.7-7.2-28.2C158.6,134.8,150.6,156.6,152.9,163.2z"/>'
                    )
                )
            );
    }

    /// @dev Generate glasses with the given color and opacity
    // tslint:disable-next-line:max-line-length
    function glasses(
        string memory color,
        string memory stroke,
        string memory opacity
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<circle fill="none" stroke="#',
                    stroke,
                    '" stroke-miterlimit="10" cx="161.5" cy="201.7" r="23.9"/>',
                    '<circle fill="none" stroke="#',
                    stroke,
                    '" stroke-miterlimit="10" cx="232.9" cy="201.7" r="23.9"/>',
                    '<circle opacity="',
                    opacity,
                    '" fill="#',
                    color,
                    '" cx="161.5" cy="201.7" r="23.9"/>',
                    abi.encodePacked(
                        '<circle opacity="',
                        opacity,
                        '" fill="#',
                        color,
                        '" cx="232.9" cy="201.7" r="23.9"/>',
                        '<path fill="none" stroke="#',
                        stroke,
                        '" stroke-miterlimit="10" d="M256.8,201.7l35.8-3.2 M185.5,201.7 c0,0,14.7-3.1,23.5,0 M137.6,201.7l-8.4-3.2"/>'
                    )
                )
            );
    }

    /// @dev Generate Monk Beads SVG with the given color
// tslint:disable-next-line:max-line-length
    function monkBeads(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g fill="#',
                    color,
                    '" stroke="#2B232B" stroke-miterlimit="10" stroke-width="0.75">',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.3439 3.0256)" cx="176.4" cy="317.8" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.458 3.2596)" cx="190.2" cy="324.6" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.5085 3.5351)" cx="206.4" cy="327.8" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.4607 4.0856)" cx="239.1" cy="325.2" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.693338e-02 1.693338e-02 0.9999 -5.386 4.3606)" cx="254.8" cy="320.2" rx="7.9" ry="8"/>',
                    '<ellipse transform="matrix(0.9999 -1.689662e-02 1.689662e-02 0.9999 -5.5015 3.8124)" cx="222.9" cy="327.5" rx="7.9" ry="8"/>',
                    "</g>",
                    '<path opacity="0.14" d="M182,318.4 c0.7,1.3-0.4,3.4-2.5,4.6c-2.1,1.2-4.5,1-5.2-0.3c-0.7-1.3,0.4-3.4,2.5-4.6C178.9,316.9,181.3,317,182,318.4z M190.5,325.7 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3s3.2-3.2,2.5-4.6C195,324.6,192.7,324.5,190.5,325.7z M206.7,328.6 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3c2.1-1.2,3.2-3.2,2.5-4.6C211.1,327.6,208.8,327.5,206.7,328.6z M223.2,328.4 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3c2.1-1.2,3.2-3.2,2.5-4.6S225.3,327.3,223.2,328.4z M239.8,325.7 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3c2.1-1.2,3.2-3.2,2.5-4.6C244.3,324.7,242,324.5,239.8,325.7z M255.7,320.9 c-2.1,1.2-3.2,3.2-2.5,4.6c0.7,1.3,3.1,1.5,5.2,0.3c2.1-1.2,3.2-3.2,2.5-4.6C260.1,319.9,257.8,319.7,255.7,320.9z"/>',
                    abi.encodePacked(
                        '<g fill="#FFFFFF" stroke="#FFFFFF" stroke-miterlimit="10">',
                        '<path d="M250.4,318.9c0.6,0.6,0.5-0.9,1.3-2c0.8-1,2.4-1.2,1.8-1.8 c-0.6-0.6-1.9-0.2-2.8,0.9C250,317,249.8,318.3,250.4,318.9z"/>',
                        '<path d="M234.4,323.6c0.7,0.6,0.5-0.9,1.4-1.9c1-1,2.5-1.1,1.9-1.7 c-0.7-0.6-1.9-0.3-2.8,0.7C234.1,321.7,233.8,323,234.4,323.6z"/>',
                        '<path d="M218.2,325.8c0.6,0.6,0.6-0.9,1.4-1.8c1-1,2.5-1,1.9-1.6 c-0.6-0.6-1.9-0.4-2.8,0.6C217.8,323.9,217.6,325.2,218.2,325.8z"/>',
                        '<path d="M202.1,325.5c0.6,0.6,0.6-0.9,1.7-1.7s2.6-0.8,2-1.5 c-0.6-0.6-1.8-0.5-2.9,0.4C202,323.5,201.5,324.8,202.1,325.5z"/>',
                        '<path d="M186.2,322c0.6,0.6,0.6-0.9,1.7-1.7c1-0.8,2.6-0.8,2-1.5 c-0.6-0.6-1.8-0.5-2.9,0.3C186,320.1,185.7,321.4,186.2,322z"/>',
                        '<path d="M171.7,315.4c0.6,0.6,0.6-0.9,1.5-1.8s2.5-0.9,1.9-1.6 s-1.9-0.4-2.8,0.5C171.5,313.5,171.1,314.9,171.7,315.4z"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @notice Return the accessory name of the given id
    /// @param id The accessory Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Glasses";
        } else if (id == 3) {
            name = "Bow Tie";
        } else if (id == 4) {
            name = "Monk Beads Classic";
        } else if (id == 5) {
            name = "Monk Beads Silver";
        } else if (id == 6) {
            name = "Power Pole";
        } else if (id == 7) {
            name = "Vintage Glasses";
        } else if (id == 8) {
            name = "Monk Beads Gold";
        } else if (id == 9) {
            name = "Eye Patch";
        } else if (id == 10) {
            name = "Sun Glasses";
        } else if (id == 11) {
            name = "Monk Beads Diamond";
        } else if (id == 12) {
            name = "Horns";
        } else if (id == 13) {
            name = "Halo";
        } else if (id == 14) {
            name = "Saiki Power";
        } else if (id == 15) {
            name = "No Face";
        }
    }

    /// @dev The base SVG for the accessory
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Accessory">', children, "</g>"));
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma abicoder v2;

/// @title Color constants
library Colors {
    string internal constant BLACK = "33333D";
    string internal constant BLACK_DEEP = "000000";
    string internal constant BLUE = "7FBCFF";
    string internal constant BROWN = "735742";
    string internal constant GRAY = "7F8B8C";
    string internal constant GREEN = "2FC47A";
    string internal constant PINK = "FF78A9";
    string internal constant PURPLE = "A839A4";
    string internal constant RED = "D9005E";
    string internal constant SAIKI = "F02AB6";
    string internal constant WHITE = "F7F7F7";
    string internal constant YELLOW = "EFED8F";
}