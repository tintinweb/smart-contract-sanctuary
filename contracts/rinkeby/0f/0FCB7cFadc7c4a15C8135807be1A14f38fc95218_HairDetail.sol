// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";
import "./constants/Colors.sol";

/// @title Hair SVG generator
library HairDetail {
    /// @dev Hair N°1 => Classic Brown
    function item_1() public pure returns (string memory) {
        return base(classicHairs(Colors.BROWN));
    }

    /// @dev Hair N°2 => Classic Black
    function item_2() public pure returns (string memory) {
        return base(classicHairs(Colors.BLACK));
    }

    /// @dev Hair N°3 => Classic Gray
    function item_3() public pure returns (string memory) {
        return base(classicHairs(Colors.GRAY));
    }

    /// @dev Hair N°4 => Classic White
    function item_4() public pure returns (string memory) {
        return base(classicHairs(Colors.WHITE));
    }

    /// @dev Hair N°5 => Classic Blue
    function item_5() public pure returns (string memory) {
        return base(classicHairs(Colors.BLUE));
    }

    /// @dev Hair N°6 => Classic Yellow
    function item_6() public pure returns (string memory) {
        return base(classicHairs(Colors.YELLOW));
    }

    /// @dev Hair N°7 => Classic Pink
    function item_7() public pure returns (string memory) {
        return base(classicHairs(Colors.PINK));
    }

    /// @dev Hair N°8 => Classic Red
    function item_8() public pure returns (string memory) {
        return base(classicHairs(Colors.RED));
    }

    /// @dev Hair N°9 => Classic Purple
    function item_9() public pure returns (string memory) {
        return base(classicHairs(Colors.PURPLE));
    }

    /// @dev Hair N°10 => Classic Green
    function item_10() public pure returns (string memory) {
        return base(classicHairs(Colors.GREEN));
    }

    /// @dev Hair N°11 => Classic Saiki
    function item_11() public pure returns (string memory) {
        return base(classicHairs(Colors.SAIKI));
    }

    /// @dev Hair N°12 => Classic 2 Brown
    function item_12() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.BROWN));
    }

    /// @dev Hair N°13 => Classic 2 Black
    function item_13() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.BLACK));
    }

    /// @dev Hair N°14 => Classic 2 Gray
    function item_14() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.GRAY));
    }

    /// @dev Hair N°15 => Classic 2 White
    function item_15() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.WHITE));
    }

    /// @dev Hair N°16 => Classic 2 Blue
    function item_16() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.BLUE));
    }

    /// @dev Hair N°17 => Classic 2 Yellow
    function item_17() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.YELLOW));
    }

    /// @dev Hair N°18 => Classic 2 Pink
    function item_18() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.PINK));
    }

    /// @dev Hair N°19 => Classic 2 Red
    function item_19() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.RED));
    }

    /// @dev Hair N°20 => Classic 2 Purple
    function item_20() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.PURPLE));
    }

    /// @dev Hair N°21 => Classic 2 Green
    function item_21() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.GREEN));
    }

    /// @dev Hair N°22 => Classic 2 Saiki
    function item_22() public pure returns (string memory) {
        return base(classicTwoHairs(Colors.SAIKI));
    }

    /// @dev Hair N°23 => Short Black
    function item_23() public pure returns (string memory) {
        return base(shortHairs(Colors.BLACK));
    }

    /// @dev Hair N°24 => Short Blue
    function item_24() public pure returns (string memory) {
        return base(shortHairs(Colors.BLUE));
    }

    /// @dev Hair N°25 => Short Pink
    function item_25() public pure returns (string memory) {
        return base(shortHairs(Colors.PINK));
    }

    /// @dev Hair N°26 => Short White
    function item_26() public pure returns (string memory) {
        return base(shortHairs(Colors.WHITE));
    }

    /// @dev Hair N°27 => Spike Black
    function item_27() public pure returns (string memory) {
        return base(spike(Colors.BLACK));
    }

    /// @dev Hair N°28 => Spike Blue
    function item_28() public pure returns (string memory) {
        return base(spike(Colors.BLUE));
    }

    /// @dev Hair N°29 => Spike Pink
    function item_29() public pure returns (string memory) {
        return base(spike(Colors.PINK));
    }

    /// @dev Hair N°30 => Spike White
    function item_30() public pure returns (string memory) {
        return base(spike(Colors.WHITE));
    }

    /// @dev Hair N°31 => Monk
    function item_31() public pure returns (string memory) {
        return base(monk());
    }

    /// @dev Hair N°32 => Nihon
    function item_32() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        monk(),
                        '<path opacity="0.36" fill="#6E5454" stroke="#8A8A8A" stroke-width="0.5" stroke-miterlimit="10" d=" M287.5,206.8c0,0,0.1-17.4-2.9-20.3c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6 c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3 S111,72.1,216.8,70.4c108.4-1.7,87.1,121.7,85.1,122.4C295.4,190.1,293.9,197.7,287.5,206.8z"/>',
                        '<g opacity="0.33">',
                        '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.367 227.089)" fill="#FFFFFF" cx="274.3" cy="113.1" rx="1.4" ry="5.3"/>',
                        '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.4151 255.0608)" fill="#FFFFFF" cx="254.1" cy="97.3" rx="4.2" ry="16.3"/>',
                        "</g>",
                        '<path fill="#FFFFFF" stroke="#2B232B" stroke-miterlimit="10" d="M136.2,125.1c0,0,72,9.9,162.2,0c0,0,4.4,14.9,4.8,26.6 c0,0-125.4,20.9-172.6-0.3C129.5,151.3,132.9,130.3,136.2,125.1z"/>',
                        '<polygon fill="#FFFFFF" stroke="#2B232B" stroke-miterlimit="10" points="306.2,138 324.2,168.1 330,160"/>',
                        '<path fill="#FFFFFF" stroke="#2B232B" stroke-miterlimit="10" d="M298.4,125.1l34.2,54.6l-18,15.5l-10.7-43.5 C302.3,142.2,299.9,128.8,298.4,125.1z"/>',
                        '<ellipse opacity="0.87" fill="#FF0039" cx="198.2" cy="144.1" rx="9.9" ry="10.8"/>'
                    )
                )
            );
    }

    /// @dev Hair N°33 => Bald
    function item_33() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.1733 226.5807)" fill="#FFFFFF" cx="273.6" cy="113.1" rx="1.4" ry="5.3"/>',
                        '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.1174 254.4671)" fill="#FFFFFF" cx="253.4" cy="97.3" rx="4.2" ry="16.3"/>'
                    )
                )
            );
    }

    /// @dev Generate classic hairs with the given color
    function classicHairs(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    hairsColor,
                    "' stroke='#000000'  stroke-width='0.5' stroke-miterlimit='10' d='M252.4,71.8c0,0-15.1-13.6-42.6-12.3l15.6,8.8c0,0-12.9-0.9-28.4-1.3c-6.1-0.2-21.8,3.3-38.3-1.4c0,0,7.3,7.2,9.4,7.7c0,0-30.6,13.8-47.3,34.2c0,0,10.7-8.9,16.7-10.9c0,0-26,25.2-31.5,70c0,0,9.2-28.6,15.5-34.2c0,0-10.7,27.4-5.3,48.2c0,0,2.4-14.5,4.9-19.2c-1,14.1,2.4,33.9,13.8,47.8c0,0-3.3-15.8-2.2-21.9l8.8-17.9c0.1,4.1,1.3,8.1,3.1,12.3c0,0,13-36.1,19.7-43.9c0,0-2.9,15.4-1.1,29.6c0,0,6.8-23.5,16.9-36.8c0,0-4.6,15.6-2.7,31.9c0,0,9.4-26.2,10.4-28.2l-2.7,9.2c0,0,4.1,21.6,3.8,25.3c0,0,8.4-10.3,21.2-52l-2.9,12c0,0,9.8,20.3,10.3,22.2s-1.3-13.9-1.3-13.9s12.4,21.7,13.5,26c0,0,5.5-20.8,3.4-35.7l1.1,9.6c0,0,15,20.3,16.4,30.1s-0.1-23.4-0.1-23.4s13.8,30.6,17,39.4c0,0,1.9-17,1.4-19.4s8.5,34.6,4.4,46c0,0,11.7-16.4,11.5-21.4c1.4,0.8-1.3,22.6-4,26.3c0,0,3.2-0.3,8.4-9.3c0,0,11.1-13.4,11.8-11.7c0.7,1.7,1.8-2.9,5.5,10.2l2.6-7.6c0,0-0.4,15.4-3.3,21.4c0,0,14.3-32.5,10.4-58.7c0,0,3.7,9.3,4.4,16.9s3.1-32.8-7.7-51.4c0,0,6.9,3.9,10.8,4.8c0,0-12.6-12.5-13.6-15.9c0,0-14.1-25.7-39.1-34.6c0,0,9.3-3.2,15.6,0.2C286.5,78.8,271.5,66.7,252.4,71.8z'/>",
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M286,210c0,0,8.5-10.8,8.6-18.7"/>',
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" d="M132.5,190.4c0,0-1.3-11.3,0.3-16.9"/>',
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" d="M141.5,170c0,0-1-6.5,1.6-20.4"/>',
                    '<path opacity="0.2" d="M267.7,151.7l-0.3,30.9c0,0,1.9-18.8,1.8-19.3s8.6,43.5,3.9,47.2c0,0,11.9-18.8,12.1-21.5s0,22-3.9,25c0,0,6-4.4,8.6-10.1c0,0,6.1-7,9.9-10.7c0,0,3.9-1,6.8,8.2l2.8-6.9c0,0,0.1,13.4-1.3,16.1c0,0,10.5-28.2,7.9-52.9c0,0,4.7,8.3,4.9,17.1c0.1,8.8,1.7-8.6,0.2-17.8c0,0-6.5-13.9-8.2-15.4c0,0,2.2,14.9,1.3,18.4c0,0-8.2-15.1-11.4-17.3c0,0,1.2,41-1.6,46.1c0,0-6.8-22.7-11.4-26.5c0,0,0.7,17.4-3.6,23.2C284.5,183.3,280.8,169.9,267.7,151.7z"/>',
                    '<path opacity="0.2" d="M234.3,137.1c0,0,17.1,23.2,16.7,30.2s-0.2-13.3-0.2-13.3s-11.7-22-17.6-26.2L234.3,137.1z"/>',
                    '<polygon opacity="0.2" points="250.7,143.3 267.5,162.9 267.3,181.9"/>',
                    '<path opacity="0.2" d="M207.4,129.2l9.7,20.7l-1-13.7c0,0,11.6,21,13.5,25.4l1.4-5l-17.6-27.4l1,7.5l-6-12.6L207.4,129.2z"/>',
                    '<path opacity="0.2" d="M209.2,118c0,0-13.7,36.6-18.5,40.9c-1.7-7.2-1.9-7.9-4.2-20.3c0,0-0.1,2.7-1.4,5.3c0.7,8.2,4.1,24.4,4,24.5S206.4,136.6,209.2,118z"/>',
                    '<path opacity="0.2" d="M187.6,134.7c0,0-9.6,25.5-10,26.9l-0.4-3.6C177.1,158.1,186.8,135.8,187.6,134.7z"/>',
                    '<path opacity="0.2" fill-rule="evenodd" clip-rule="evenodd" d="M180.7,129.6c0,0-16.7,22.3-17.7,24.2s0,12.4,0.3,12.8S165.9,153,180.7,129.6z"/>',
                    '<path opacity="0.2" fill-rule="evenodd" clip-rule="evenodd" d="M180.4,130.6c0,0-0.2,20.5-0.6,21.5c-0.4,0.9-2.6,5.8-2.6,5.8S176.1,147.1,180.4,130.6z"/>',
                    abi.encodePacked(
                        '<path opacity="0.2" d="M163.9,138c0,0-16.3,25.3-17.9,26.3c0,0-3.8-12.8-3-14.7s-9.6,10.3-9.9,17c0,0-8.4-0.6-11-7.4c-1-2.5,1.4-9.1,2.1-12.2c0,0-6.5,7.9-9.4,22.5c0,0,0.6,8.8,1.1,10c0,0,3.5-14.8,4.9-17.7c0,0-0.3,33.3,13.6,46.7c0,0-3.7-18.6-2.6-21l9.4-18.6c0,0,2.1,10.5,3.1,12.3l13.9-33.1L163.9,138z"/>',
                        '<path fill="#FFFFFF" d="M204,82.3c0,0-10.3,24.4-11.5,30.4c0,0,11.1-20.6,12.6-20.8c0,0,11.4,20.4,12,22.2C217.2,114.1,208.2,88.2,204,82.3z"/>',
                        '<path fill="#FFFFFF" d="M185.6,83.5c0,0-1,29.2,0,39.2c0,0-4-21.4-3.6-25.5c0.4-4-13.5,19.6-16,23.9c0,0,7.5-20.6,10.5-25.8c0,0-14.4,9.4-22,21.3C154.6,116.7,170.1,93.4,185.6,83.5z"/>',
                        '<path fill="#FFFFFF" d="M158.6,96.2c0,0-12,15.3-14.7,23.2"/>',
                        '<path fill="#FFFFFF" d="M125.8,125.9c0,0,9.5-20.6,23.5-27.7"/>',
                        '<path fill="#FFFFFF" d="M296.5,121.6c0,0-9.5-20.6-23.5-27.7"/>',
                        '<path fill="#FFFFFF" d="M216.1,88.5c0,0,10.9,19.9,11.6,23.6s3.7-5.5-10.6-23.6"/>',
                        '<path fill="#FFFFFF" d="M227,92c0,0,21.1,25.4,22,27.4s-4.9-23.8-12.9-29.5c0,0,9.5,20.7,9.9,21.9C246.3,113,233.1,94.1,227,92z"/>',
                        '<path fill="#FFFFFF" d="M263.1,119.5c0,0-9.5-26.8-10.6-28.3s15.5,14.1,16.2,22.5c0,0-11.1-16.1-11.8-16.9C256.1,96,264.3,114.1,263.1,119.5z"/>'
                    )
                )
            );
    }

    /// @dev Generate classic 2 hairs with the given color
    function classicTwoHairs(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<polygon fill='#",
                    hairsColor,
                    "' points='188.2,124.6 198.3,128.1 211.2,124.3 197.8,113.2'/>",
                    '<polygon opacity="0.5" points="188.4,124.7 198.3,128.1 211.7,124.2 197.7,113.6"/>',
                    "<path fill='#",
                    hairsColor,
                    "' stroke='#000000' stroke-width='0.5' stroke-miterlimit='10' d='M274,209.6c1,0.9,10.1-12.8,10.5-18.3 c1.1,3.2-0.2,16.8-2.9,20.5c0,0,3.7-0.7,8.3-6.5c0,0,11.1-13.4,11.8-11.7c0.7,1.7,1.8-2.9,5.5,10.2l2.6-7.6 c0,0-0.4,15.4-3.3,21.4c0,0,14.3-32.5,10.4-58.7c0,0,3.7,9.3,4.4,16.9s3.1-32.8-7.7-51.4c0,0,6.9,3.9,10.8,4.8 c0,0-12.6-12.5-13.6-15.9c0,0-14.1-25.7-39.1-34.6c0,0,9.3-3.2,15.6,0.2c-0.1-0.1-15.1-12.2-34.2-7.1c0,0-15.1-13.6-42.6-12.3 l15.6,8.8c0,0-12.9-0.9-28.4-1.3c-6.1-0.2-21.8,3.3-38.3-1.4c0,0,7.3,7.2,9.4,7.7c0,0-30.6,13.8-47.3,34.2 c0,0,10.7-8.9,16.7-10.9c0,0-26,25.2-31.5,70c0,0,9.2-28.6,15.5-34.2c0,0-10.7,27.4-5.3,48.2c0,0,2.4-14.5,4.9-19.2 c-1,14.1,2.4,33.9,13.8,47.8c0,0-3.3-15.8-2.2-21.9l8.8-17.9c0.1,4.1,1.3,8.1,3.1,12.3c0,0,13-36.1,19.7-43.9 c0,0-2.9,15.4-1.1,29.6c0,0,7.2-26.8,17.3-40.1c0,0,0.8,0.1,17.6-7.6c6.3,3.1,8,1.4,17.9,7.7c4.1,5.3,13.8,31.9,15.6,41.5 c3.4-7.3,5.6-19,5.2-29.5c2.7,3.7,8.9,19.9,9.6,34.3c0,0,7.9-15.9,5.9-29c0-0.2,0.2,14.5,0.3,14.3c0,0,12.1,19.9,14.9,19.7 c0-0.8-1.7-12.9-1.7-12.8c1.3,5.8,2.8,23.3,3.1,27.1l5-9.5C276.2,184,276.8,204.9,274,209.6z'/>",
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M286.7,210c0,0,8.5-10.8,8.6-18.7"/>',
                    '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" d="M133.2,190.4 c0,0-1.3-11.3,0.3-16.9"/>',
                    abi.encodePacked(
                        '<path fill="none" stroke="#000000" stroke-width="0.5" stroke-linecap="round" stroke-miterlimit="10" d="M142.2,170 c0,0-1-6.5,1.6-20.4"/>',
                        '<path opacity="0.2" fill-rule="evenodd" clip-rule="evenodd" d="M180.6,128.2 c0,0-15.9,23.7-16.9,25.6s0,12.4,0.3,12.8S165.8,151.6,180.6,128.2z"/>',
                        '<path opacity="0.2" d="M164.6,138c0,0-16.3,25.3-17.9,26.3c0,0-3.8-12.8-3-14.7s-9.6,10.3-9.9,17 c0,0-8.4-0.6-11-7.4c-1-2.5,1.4-9.1,2.1-12.2c0,0-6.5,7.9-9.4,22.5c0,0,0.6,8.8,1.1,10c0,0,3.5-14.8,4.9-17.7 c0,0-0.3,33.3,13.6,46.7c0,0-3.7-18.6-2.6-21l9.4-18.6c0,0,2.1,10.5,3.1,12.3l13.9-33.1L164.6,138z"/>',
                        '<path opacity="0.16" d="M253.3,155.9c0.8,4.4,8.1,12.1,13.1,11.7l1.6,11c0,0-5.2-3.9-14.7-19.9 V155.9z"/>',
                        '<path opacity="0.16" d="M237.6,139.4c0,0,4.4,3,13.9,21.7c0,0-4.3,12-4.6,12.4 C246.6,173.9,248.5,162.8,237.6,139.4z"/>',
                        '<path opacity="0.17" d="M221,136.7c0,0,5.2,4,14.4,23c0,0-1.2,4.6-3.1,8.9 C227.7,152.4,227.1,149.9,221,136.7z"/>',
                        '<path opacity="0.2" d="M272.1,152.6c-2.4,8.1-3.6,13.8-4.9,17.9c0,0,1.3,12.8,2.1,22.2 c4.7-8.4,5.4-8.8,5.4-9c-0.1-0.5,3.6,11.2-0.7,25.9c1.6,1,13.3-16.9,11.9-20.6c-1-2.5-0.4,19.8-4.3,22.8c0,0,6.4-2.2,9-7.9 c0,0,6.1-7,9.9-10.7c0,0,3.9-1,6.8,8.2l2.8-6.9c0,0,0.1,13.4-1.3,16.1c0,0,10.5-28.2,7.9-52.9c0,0,4.7,8.3,4.9,17.1 c0.1,8.8,1.7-8.6,0.2-17.8c0,0-6.5-13.9-8.2-15.4c0,0,2.2,14.9,1.3,18.4c0,0-8.2-15.1-11.4-17.3c0,0,1.2,41-1.6,46.1 c0,0-6.8-22.7-11.4-26.5c0,0-1.8,15.7-5,22.9C283.7,183,280.5,166.7,272.1,152.6z"/>'
                    ),
                    abi.encodePacked(
                        '<path opacity="0.14" d="M198.2,115.2c-0.9-3.9,3.2-35.1,34.7-36C227.6,78.5,198.9,99.8,198.2,115.2z"/>',
                        '<g opacity="0.76">',
                        '<path fill="#FFFFFF" d="M153,105.9c0,0-12,15.3-14.7,23.2"/>',
                        '<path fill="#FFFFFF" d="M126.5,125.9c0,0,9.5-20.6,23.5-27.7"/>',
                        '<path fill="#FFFFFF" d="M297.2,121.6c0,0-9.5-20.6-23.5-27.7"/>',
                        '<path fill="#FFFFFF" d="M241.9,109.4c0,0,10.9,19.9,11.6,23.6s3.7-5.5-10.6-23.6"/>',
                        '<path fill="#FFFFFF" d="M155.1,117.3c0,0-10.9,19.9-11.6,23.6s-3.7-5.5,10.6-23.6"/>',
                        '<path fill="#FFFFFF" d="M256.1,101.5c0,0,21.1,25.4,22,27.4c0.9,2-4.9-23.8-12.9-29.5c0,0,9.5,20.7,9.9,21.9 C275.4,122.5,262.2,103.6,256.1,101.5z"/>',
                        '<path fill="#FFFFFF" d="M230,138.5c0,0-12.9-24.9-14.1-26.4c-1.2-1.4,18.2,11.9,19.3,20.2c0,0-11.9-13-12.7-13.7 C221.8,117.9,230.9,133,230,138.5z"/>',
                        '<path fill="#FFFFFF" d="M167,136.6c0,0,15.5-24.5,17-25.8c1.5-1.2-19.1,10.6-21.6,18.8c0,0,15-13.5,15.8-14.2 C179.2,114.8,166.8,130.9,167,136.6z"/>',
                        "</g>"
                    )
                )
            );
    }

    /// @dev Generate mohawk with the given color
    function spike(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    hairsColor,
                    "' d='M287.3,207.1c0,0-0.4-17.7-3.4-20.6c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3c0.9-0.2-19.1-126.3,86.7-126.8c108.4-0.3,87.1,121.7,85.1,122.4C294.5,191.6,293.7,198,287.3,207.1z'/>",
                    '<path fill-rule="evenodd" clip-rule="evenodd" fill="#212121" stroke="#000000" stroke-miterlimit="10" d="M196,124.6c0,0-30.3-37.5-20.6-77.7c0,0,0.7,18,12,25.1c0,0-8.6-13.4-0.3-33.4c0,0,2.7,15.8,10.7,23.4c0,0-2.7-18.4,2.2-29.6c0,0,9.7,23.2,13.9,26.3c0,0-6.5-17.2,5.4-27.7c0,0-0.8,18.6,9.8,25.4c0,0-2.7-11,4-18.9c0,0,1.2,25.1,6.6,29.4c0,0-2.7-12,2.1-20c0,0,6,24,8.6,28.5c-9.1-2.6-17.9-3.2-26.6-3C223.7,72.3,198,80.8,196,124.6z"/>',
                    crop()
                )
            );
    }

    function shortHairs(string memory hairsColor) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path fill='#",
                    hairsColor,
                    "' d='M287.3,207.1c0,0-0.4-17.7-3.4-20.6c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3c0.9-0.2-19.1-126.3,86.7-126.8c108.4-0.3,87.1,121.7,85.1,122.4C294.5,191.6,293.7,198,287.3,207.1z'/>",
                    '<path fill="#212121" stroke="#000000" stroke-miterlimit="10" d="M134.9,129.3c1-8.7,2.8-19.9,2.6-24.1 c1.1,2,4.4,6.1,4.7,6.9c2-15.1,3.9-18.6,6.6-28.2c0.1,5.2,0.4,6.1,4.6,11.9c0.1-7,4.5-17.6,8.8-24.3c0.6,3,4,8.2,5.8,10.7 c2.4-7,8.6-13.4,14.5-17.9c-0.3,3.4-0.1,6.8,0.7,10.1c4.9-5.1,7.1-8.7,15.6-15.4c-0.2,4.5,1.8,9,5.1,12c4.1-3.7,7.7-8,10.6-12.7 c0.6,3.7,1.4,7.3,2.5,10.8c2.6-4.6,7.9-8.4,12.4-11.3c1.5,3.5,1.3,11,5.9,11.7c7.1,1.1,10-3.3,11.4-10.1 c2.2,6.6,4.8,12.5,9.4,17.7c4.2,0.5,5.7-5.6,4.2-9c4.2,5.8,8.4,11.6,12.5,17.4c0.7-2.9,0.9-5.9,0.6-8.8 c3.4,7.6,9.1,16.7,13.6,23.6c0-1.9,1.8-8.5,1.8-10.4c2.6,7.3,7.7,17.9,10.3,36.6c0.2,1.1-23.8,7.5-28.8,10.1 c-1.2-2.3-2.2-4.3-6.2-8c-12.1-5.7-35.6-7.9-54.5-2.2c-16.3,4.8-21.5-2.3-31.3-3.1c-11.8-1.8-31.1-1.7-36.2,10.7 C139.6,133.6,137.9,132.2,134.9,129.3z"/>',
                    '<polygon fill="#212121" points="270.7,138.4 300.2,129 300.7,131.1 271.3,139.9"/>',
                    '<polygon fill="#212121" points="141.1,137 134,131.7 133.8,132.9 140.8,137.7 "/>',
                    crop()
                )
            );
    }

    /// @dev Generate crop SVG
    function crop() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g id="Light" opacity="0.14">',
                    '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.1603 226.5965)" fill="#FFFFFF" cx="273.6" cy="113.1" rx="1.4" ry="5.3"/>',
                    '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.0969 254.4865)" fill="#FFFFFF" cx="253.4" cy="97.3" rx="4.2" ry="16.3"/>',
                    "</g>",
                    '<path opacity="0.05" fill-rule="evenodd" clip-rule="evenodd" d="M276.4,163.7c0,0,0.2-1.9,0.2,14.1c0,0,6.5,7.5,8.5,11s2.6,17.8,2.6,17.8l7-11.2c0,0,1.8-3.2,6.6-2.6c0,0,5.6-13.1,2.2-42.2C303.5,150.6,294.2,162.1,276.4,163.7z"/>',
                    '<path opacity="0.1" fill-rule="evenodd" clip-rule="evenodd" d="M129.2,194.4c0,0-0.7-8.9,6.8-20.3c0,0-0.2-21.2,1.3-22.9c-3.7,0-6.7-0.5-7.7-2.4C129.6,148.8,125.8,181.5,129.2,194.4z"/>'
                )
            );
    }

    /// @dev Generate monk SVG
    function monk() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path opacity="0.36" fill="#6E5454" stroke="#8A8A8A" stroke-width="0.5" stroke-miterlimit="10" d="M286.8,206.8c0,0,0.1-17.4-2.9-20.3c-3.1-2.9-7.3-8.7-7.3-8.7s0.6-24.8-2.9-31.8c-3.6-7-3.9-24.3-35-23.6c-30.3,0.7-42.5,5.4-42.5,5.4s-14.2-8.2-43-3.8c-19.3,4.9-17.2,50.1-17.2,50.1s-5.6,9.5-6.2,14.8c-0.6,5.3-0.3,8.3-0.3,8.3S110.3,72.1,216.1,70.4c108.4-1.7,87.1,121.7,85.1,122.4C294.7,190.1,293.2,197.7,286.8,206.8z"/>',
                    '<g id="Bald" opacity="0.33">',
                    '<ellipse transform="matrix(0.7071 -0.7071 0.7071 0.7071 0.1603 226.5965)" fill="#FFFFFF" cx="273.6" cy="113.1" rx="1.4" ry="5.3"/>',
                    '<ellipse transform="matrix(0.5535 -0.8328 0.8328 0.5535 32.0969 254.4865)" fill="#FFFFFF" cx="253.4" cy="97.3" rx="4.2" ry="16.3"/>',
                    "</g>"
                )
            );
    }

    /// @notice Return the hair cut name of the given id
    /// @param id The hair Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic Brown";
        } else if (id == 2) {
            name = "Classic Black";
        } else if (id == 3) {
            name = "Classic Gray";
        } else if (id == 4) {
            name = "Classic White";
        } else if (id == 5) {
            name = "Classic Blue";
        } else if (id == 6) {
            name = "Classic Yellow";
        } else if (id == 7) {
            name = "Classic Pink";
        } else if (id == 8) {
            name = "Classic Red";
        } else if (id == 9) {
            name = "Classic Purple";
        } else if (id == 10) {
            name = "Classic Green";
        } else if (id == 11) {
            name = "Classic Saiki";
        } else if (id == 12) {
            name = "Classic Brown";
        } else if (id == 13) {
            name = "Classic 2 Black";
        } else if (id == 14) {
            name = "Classic 2 Gray";
        } else if (id == 15) {
            name = "Classic 2 White";
        } else if (id == 16) {
            name = "Classic 2 Blue";
        } else if (id == 17) {
            name = "Classic 2 Yellow";
        } else if (id == 18) {
            name = "Classic 2 Pink";
        } else if (id == 19) {
            name = "Classic 2 Red";
        } else if (id == 20) {
            name = "Classic 2 Purple";
        } else if (id == 21) {
            name = "Classic 2 Green";
        } else if (id == 22) {
            name = "Classic 2 Saiki";
        } else if (id == 23) {
            name = "Short Black";
        } else if (id == 24) {
            name = "Short Blue";
        } else if (id == 25) {
            name = "Short Pink";
        } else if (id == 26) {
            name = "Short White";
        } else if (id == 27) {
            name = "Spike Black";
        } else if (id == 28) {
            name = "Spike Blue";
        } else if (id == 29) {
            name = "Spike Pink";
        } else if (id == 30) {
            name = "Spike White";
        } else if (id == 31) {
            name = "Monk";
        } else if (id == 32) {
            name = "Nihon";
        } else if (id == 33) {
            name = "Bald";
        }
    }

    /// @dev The base SVG for the hair
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Hair">', children, "</g>"));
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
pragma solidity ^0.8.0;

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

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
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