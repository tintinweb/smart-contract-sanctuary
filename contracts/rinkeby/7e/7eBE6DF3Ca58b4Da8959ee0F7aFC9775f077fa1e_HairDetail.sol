// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Hair SVG generator
library HairDetail {
    /// @dev Hair N°1 => Hair Blood
    function item_1() public pure returns (string memory) {
        return base(longHair("E31466"), "Hair Blood");
    }

    /// @dev Hair N°2 => Tattoo Blood
    function item_2() public pure returns (string memory) {
        return base(tattoo("B50D5E"), "Tattoo Blood");
    }

    /// @dev Hair N°3 => Tattoo Moon
    function item_3() public pure returns (string memory) {
        return base(tattoo("000000"), "Tattoo Moon");
    }

    /// @dev Hair N°4 => Tattoo Pure
    function item_4() public pure returns (string memory) {
        return base(tattoo("FFEDED"), "Tattoo Pure");
    }

    /// @dev Hair N°5 => Monk Blood
    function item_5() public pure returns (string memory) {
        return base(shortHair("B50D5E"), "Monk Blood");
    }

    /// @dev Hair N°6 => Monk Moon
    function item_6() public pure returns (string memory) {
        return base(shortHair("001015"), "Monk Moon");
    }

    /// @dev Hair N°7 => Monk Pure
    function item_7() public pure returns (string memory) {
        return base(shortHair("FFEDED"), "Monk Pure");
    }

    /// @dev Hair N°8 => Flame Blood
    function item_8() public pure returns (string memory) {
        return base(flame("E31466"), "Flame Blood");
    }

    /// @dev Hair N°9 => Flame Moon
    function item_9() public pure returns (string memory) {
        return base(flame("2A2C38"), "Flame Moon");
    }

    /// @dev Hair N°10 => Flame Pure
    function item_10() public pure returns (string memory) {
        return base(flame("FFDAEA"), "Flame Pure");
    }

    /// @dev Hair N°11 => Top eyes
    function item_11() public pure returns (string memory) {
        return
            base(
                '<path d="M212.26,68.64S205.37,71,201.72,84c-1.28,4.6-.79,11.21,1.45,18a30.33,30.33,0,0,0,9.55-16.12C213.83,81.08,213.79,75.34,212.26,68.64Z" transform="translate(0 0.5)" /> <path d="M215.93,75.57a28.82,28.82,0,0,1,.15,6.15A36.91,36.91,0,0,1,215,87.81a24.33,24.33,0,0,1-2.36,5.75,23.15,23.15,0,0,1-3.74,4.93c.28-.37.58-.83.88-1.29l.43-.6.35-.63.8-1.31.72-1.34a35.55,35.55,0,0,0,2.16-5.71,36.25,36.25,0,0,0,1.24-6,18.25,18.25,0,0,0,.26-3C215.83,77.61,215.83,76.62,215.93,75.57Z" transform="translate(0 0.5)"/> <path d="M199,85.3c0,1.23-.07,2.45,0,3.69s0,2.39.17,3.64a16.5,16.5,0,0,0,.61,3.63,20,20,0,0,0,1.07,3.53,14.31,14.31,0,0,1-1.45-3.33c-.32-1.2-.48-2.37-.7-3.64,0-1.24-.12-2.4-.07-3.71A32.65,32.65,0,0,1,199,85.3Z" transform="translate(0 0.5)"/> <ellipse cx="211.04" cy="79.75" rx="2.78" ry="0.69" transform="matrix(0.09, -1, 1, 0.09, 111.76, 282.83)" fill="#fff"/>',
                "Top Eyes"
            );
    }

    /// @dev Hair N°12 => Middle eyes
    function item_12() public pure returns (string memory) {
        return
            base(
                '<path d="M213,104.52s-10.09,8.91-23.55-.09C189.55,104.37,200.24,95.64,213,104.52Z" transform="translate(0 0.5)" /> <path d="M211.51,101.33a16.75,16.75,0,0,0-3.14-1.5A23.51,23.51,0,0,0,205,98.9a16.16,16.16,0,0,0-3.53-.27,14.89,14.89,0,0,0-3.43.56c.26,0,.57-.07.88-.1l.41,0,.41,0,.87-.06h.85a21.36,21.36,0,0,1,3.46.35,23,23,0,0,1,3.37.82,12.29,12.29,0,0,1,1.6.58C210.44,100.9,210.94,101.13,211.51,101.33Z" transform="translate(0 0.5)"/> <path d="M199.85,109.75c-.83-.13-1.65-.25-2.48-.43s-1.59-.31-2.42-.55a11,11,0,0,1-2.35-.84,13.15,13.15,0,0,1-2.24-1.14,9.12,9.12,0,0,0,2.06,1.37c.76.36,1.53.6,2.35.91s1.6.36,2.48.48A20.38,20.38,0,0,0,199.85,109.75Z" transform="translate(0 0.5)"/> <ellipse cx="205.62" cy="102.76" rx="0.47" ry="1.89" transform="translate(68.77 287.95) rotate(-80.02)" fill="#fff"/>',
                "Middle Eyes"
            );
    }

    /// @dev Hair N°13 => Side eyes
    function item_13() public pure returns (string memory) {
        return
            base(
                '<g id="Eye"> <path d="M289,147.2s-10.34-8.61-3.5-23.28C285.51,124,295.77,133.19,289,147.2Z" transform="translate(0 0.5)" /> <path d="M281.77,135c0-.83,0-1.67.05-2.51s.06-1.62.17-2.47a10.81,10.81,0,0,1,.47-2.46,13.76,13.76,0,0,1,.78-2.38,9.71,9.71,0,0,0-1,2.24c-.24.81-.36,1.6-.53,2.46s-.12,1.63-.1,2.53A20.5,20.5,0,0,0,281.77,135Z" transform="translate(0 0.5)"/> <ellipse cx="287.94" cy="130.66" rx="0.47" ry="1.89" transform="translate(-26.21 95.24) rotate(-17.88)" fill="#fff"/> </g> <g id="Eye-2" > <path d="M137,147.2s7.8-8.61,2.65-23.28C139.6,124,131.86,133.19,137,147.2Z" transform="translate(0 0.5)" /> <path d="M142.42,135c0-.83,0-1.67,0-2.51s0-1.62-.13-2.47a14.29,14.29,0,0,0-.35-2.46,16.86,16.86,0,0,0-.59-2.38,11,11,0,0,1,.78,2.24c.18.81.28,1.6.4,2.46s.09,1.63.08,2.53A25.66,25.66,0,0,1,142.42,135Z" transform="translate(0 0.5)"/> <ellipse cx="137.95" cy="129.7" rx="1.89" ry="0.36" transform="translate(-25.79 225.29) rotate(-73.38)" fill="#fff"/></g>',
                "Side Eyes"
            );
    }

    /// @dev Hair N°14 => Akuma
    function item_14() public pure returns (string memory) {
        return base("", "Akuma");
    }

    /// @dev Hair N°15 => Hair Moon
    function item_15() public pure returns (string memory) {
        return base(longHair("2A2C38"), "Hair Moon");
    }

    /// @dev Hair N°16 => Hair Pure
    function item_16() public pure returns (string memory) {
        return base(longHair("FFDAEA"), "Hair Pure");
    }

    /// @dev Hair N°17 => Tattoo kin
    function item_17() public pure returns (string memory) {
        return
            base(
                '<g id="Tattoo_kin" display="inline" ><linearGradient id="SVGID_00000011722690206770933430000008680616382255612556_" gradientUnits="userSpaceOnUse" x1="210.6601" y1="-54.3" x2="210.6601" y2="11.1777" gradientTransform="matrix(1 0 0 -1 0 76)"><stop offset="0" style="stop-color:#FFB451" /><stop offset="0.4231" style="stop-color:#F7E394" /><stop offset="1" style="stop-color:#FF9B43" /></linearGradient><path  fill="url(#SVGID_00000011722690206770933430000008680616382255612556_)" d="M192.1,67.4c-6.5,21.1,2,49.3,5.5,62.9c0,0,6.9-39.2,34-63.9C220.8,63.6,198.1,64.9,192.1,67.4z" /></g>',
                "Tattoo kin"
            );
    }

    function flame(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline" fill="#',
                    color,
                    '" d="M292.2,168.8c-2.7,2.1-7.7,6-10.4,8.1c3.5-8,7-18.9,7.2-24c-2.4,1.6-6.8,4.7-9.3,4.1 c3.9-12.3,4.2-11.6,4.6-24.2c-2.5,2-8.9,9.3-11.5,11.2c0.5-5.9,0.8-14.3,1.4-20.1c-3.3,3.4-7.6,2.6-12.5,4c-0.5-5,1.3-7,3.5-11.6 c-9.8,4-24.7,6-34.9,8.6c-0.1-2.4-0.6-6.3,0.7-8.1c-10.4,5-26.7,9.3-31.8,12.4c-4.1-2.8-16.9-9.3-19.7-12.9 c-0.1,1.6,0.7,8,0.6,9.6c-5.4-3.8-6.2-3-12-6.8c0.5,2.6,0.3,3.6,0.8,6.2c-7.2-2.8-14.4-5.7-21.6-8.5c1.8,4,3.5,8,5.3,12 c-3.6,0.6-9.9-1.8-12-4.9c-3,7.8-0.1,12.2,0,20.5c-2-2-3.9-6.4-5.4-8.6c0.5,9.6,1,19.1,1.6,28.7c-1.6-0.6-2.7-2-3.1-3.5 c-0.1,5.8,2.6,20.6,4,26.4c-0.8-0.8-5.5-10.9-5.7-12.1c4.3,7.9,4.1,10.5,5.4,26.3c0.9-0.9-5.5-17-8-19.4 c-1.7-15.4-5.3-33.7-9.1-48.8c2,3.6,3.9,7.3,5.8,11c-0.7-13.8-0.7-27.6-0.1-41.4c-0.2,5.9,0.7,11.9,2.6,17.4 c0.5-11.3,2.2-22.4,5.2-33.3c-0.1,4.1,0.4,8.1,1.6,12c2.8-10,6.3-19.8,10.3-29.3c0.8,4.7,1.7,9.4,2.4,14.1 c3.6-9.9,7.9-15.5,14.6-23.7c0.2,4,0.4,7.8,0.7,11.8c6.9-8.9,15-16.8,24.1-23.2c-0.5,4.4-1,8.8-1.6,13.1 c6.1-5.7,11.7-9.7,17.8-15.4c0.3,4.4,1.3,7,1.6,11.5c4-5.4,8.1-9.6,12.1-15c1.4,6.1,2,11.3,2.2,17.6c4.8-4.7,8.1-10,8.4-16.7 c4.2,7.4,7.9,10.6,9.8,18.9c2.5-8.4,4.8-11,4.7-19.8c4.4,10.1,6.8,14.3,9.6,24c0.9-4.6,4.1-11.5,5-16c6.3,6.7,9.1,14.6,12.4,23 c0.7-7.6,5.7-10.6,3.5-17.9c6.5,10.7,4.6,15.2,8.6,27.7c2.9-5.3,4.4-13.3,5.5-19.4c2.7,8,7.7,23.1,9.4,31.5 c0.7-2.7,3.1-3.3,3.5-9.9c2.8,7.7,3.3,8.4,3.5,23.4c1.1-7.4,4.3-3.3,4.5-10.8c3.8,9.6,1.4,14.8,0.4,22.6c-0.1,0.9,4.2-0.4,5.1-1.5 c1-1.3-2.1,12.4-2.8,14.3c-0.5,1.4-1.9,2.7-1.4,8.4c2.2-3.1,2.5-3,4.3-6.4c1.3,11.3-2.3,6-4.7,25.5c1.9-2.5,3.9-1.1,5.6-3.5 c-2.8,7.8-0.4,9.8-6.9,14c-3.3,2.1-11.2,10.3-14.2,13.5c1.6-3.3-2.9,9.8-8.2,18.8C284.5,199.5,289.7,170.7,292.2,168.8z"/>'
                )
            );
    }

    function tattoo(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M193.2,67.36c-6.5,21.1,3,50.54,6.48,64.14,0,0,5.91-44.63,33.11-64.86C222,63.84,201.2,64.36,193.2,67.36Z" fill="#',
                    color,
                    '" transform="translate(-0.1)"/>'
                )
            );
    }

    function longHair(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g ><polygon fill="#',
                    color,
                    '" points="188.1,115.5 198.2,119 211.1,115.2 197.7,104.1 "/><polygon opacity="0.5" enable-background="new    " points="188.3,115.6 198.2,119 211.6,115.1 197.6,104.5 "/><path fill="#',
                    color,
                    '" stroke="#000000" stroke-width="2" stroke-miterlimit="10" d="M273.7,200.6c4.2-5.9,10.1-12.8,10.5-18.3c1.1,3.2,2,11.7,1.5,15.8c0,0,5.7-10.8,10.6-15.6c6.4-6.3,13.9-10.2,17.2-14.4c2.3,6.4,1.4,15.3-4.7,28.1c0,0,0.4,9.2-0.7,15.3c3.3-5.9,12.8-36.2,8.5-61.6c0,0,3.7,9.3,4.4,16.9s3.1-32.8-7.7-51.4c0,0,6.9,3.9,10.8,4.8c0,0-12.6-12.5-13.6-15.9c0,0-14.1-25.7-39.1-34.6c0,0,9.3-3.2,15.6,0.2c-0.1-0.1-15.1-12.2-34.2-7.1c0,0-15.1-13.6-42.6-12.3l15.6,8.8c0,0-12.9-0.9-28.4-1.3c-6.1-0.2-21.8,3.3-38.3-1.4c0,0,7.3,7.2,9.4,7.7c0,0-30.6,13.8-47.3,34.2c0,0,10.7-8.9,16.7-10.9c0,0-26,25.2-31.5,70c0,0,9.2-28.6,15.5-34.2c0,0-10.7,27.4-5.3,48.2c0,0,2.4-14.5,4.9-19.2c-1,14.1,2.4,33.9,13.8,47.8c0,0-3.3-15.8-2.2-21.9l8.8-17.9c0.1,4.1,1.3,8.1,3.1,12.3c0,0,13-36.1,19.7-43.9c0,0-2.9,15.4-1.1,29.6c0,0,7.2-26.8,17.3-40.1c0,0,0.8,0.1,17.6-7.6c6.3,3.1,8,1.4,17.9,7.7c4.1,5.3,13.8,31.9,15.6,41.5c3.4-7.3,5.6-19,5.2-29.5c2.7,3.7,8.9,19.9,9.6,34.3c4.3-6,6.4-27.8,5.9-29c0,1.2,0.2,14.8,0.3,14.3c0,0,12.1,19.9,14.9,19.7c0-0.8-1.7-12.9-1.7-12.8c1.3,5.8,2.8,23.3,3.1,27.1l5-9.5C274.6,176.2,275.4,194.5,273.7,200.6z"/><g><path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M295.2,182.2"/><path fill="none" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M286.6,200.9"/><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" d="M133.1,181.3c0,0-1.3-11.3,0.3-16.9"/><path fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-miterlimit="10" d="M142.1,160.9c0,0-1-6.5,1.6-20.4"/></g></g><g  id="Shadow"><path opacity="0.2"  enable-background="new    " d="M180.5,119.1c0,0-15.9,23.7-16.9,25.6s0,12.4,0.3,12.8S165.7,142.5,180.5,119.1z"/><path opacity="0.2" enable-background="new    " d="M164.5,128.9c0,0-16.3,25.3-17.9,26.3c0,0-3.8-12.8-3-14.7s-9.6,10.3-9.9,17c0,0-8.4-0.6-11-7.4c-1-2.5,1.4-9.1,2.1-12.2c0,0-6.5,7.9-9.4,22.5c0,0,0.6,8.8,1.1,10c0,0,3.5-14.8,4.9-17.7c0,0-0.3,33.3,13.6,46.7c0,0-3.7-18.6-2.6-21l9.4-18.6c0,0,2.1,10.5,3.1,12.3l13.9-33.1L164.5,128.9z"/><path opacity="0.16" enable-background="new    " d="M253.2,146.8c0.8,4.4,8.1,12.1,13.1,11.7l1.6,11c0,0-5.2-3.9-14.7-19.9V146.8z"/><path opacity="0.16" enable-background="new    " d="M237.5,130.3c0,0,4.4,3,13.9,21.7c0,0-4.3,12-4.6,12.4C246.5,164.8,248.4,153.7,237.5,130.3z"/><path opacity="0.17" enable-background="new    " d="M220.9,127.6c0,0,5.2,4,14.4,23c0,0-1.2,4.6-3.1,8.9C227.6,143.3,227,140.8,220.9,127.6z"/><path opacity="0.2" enable-background="new    " d="M272,143.7c-2.4,8.1-3.6,13.8-4.9,17.9c0,0,1.3,12.8,2.1,22.2c4.7-8.4,4.7-8.4,5.4-9c0.2,0.6,3.1,11.9-1.2,26.6c5.1-6.7,10.4-14.9,11-21.3c1.1,3.7,1.7,15,1.2,19.1c0,0,7.1-7.4,12.3-11.3c0,0,8.7-3.5,12.5-7.2c0,0,2.2,1.4-1.2,11.6l3.7-8c0,0-2.7,19.9-3.4,22.5c0,0,9.8-33.3,7.2-58c0,0,4.7,8.3,4.9,17.1c0.1,8.8,1.7-8.6,0.2-17.8c0,0-6.5-13.9-8.2-15.4c0,0,1.3,10.1,0.4,13.6c0,0-7.3-10.3-10.5-12.5c0,0,1.1,30.2-1.7,35.3c0,0-6.1-17-10.7-20.8c0,0-2.4,20.9-5.6,28.1C283.6,174.1,280.4,157.8,272,143.7z"/><path opacity="0.14" enable-background="new    " d="M198.1,106.1c-0.9-3.9,3.2-35.1,34.7-36C227.5,69.4,198.8,90.7,198.1,106.1z"/></g><g id="Light" opacity="0.64"> <path d="M128,115.68s9.5-20.6,23.5-27.7A231.28,231.28,0,0,0,128,115.68Z" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M302.32,118.62s-12.77-26.38-29.75-35A151.52,151.52,0,0,1,302.32,118.62Z" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M251.35,127.49s-9.25-18.73-11.63-21.13,5,1.76,12.17,20.33" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M168.21,103.68s-10.66,10.79-16,23.94C157.36,118,168.21,103.68,168.21,103.68Z" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M170,126.1s7.5-21.3,8.4-22.5-12.6,11.4-13.1,18c0,0,9-12.8,9.5-13.5S168.8,121.8,170,126.1Z" transform="translate(-0.48 0.37)" fill="#fff"/> <path d="M233.09,127.55s-7.5-21.3-8.4-22.5,12.6,11.4,13.1,18c0,0-9-12.8-9.5-13.5S234.29,123.25,233.09,127.55Z" transform="translate(-0.48 0.37)" fill="#fff"/> </g>'
                )
            );
    }

    function spike(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path  display="inline"  fill="#',
                    color,
                    '" stroke="#',
                    color,
                    '" stroke-miterlimit="10" d="M197.7,120.1c0,0-26.4-38.7-18-80.2c0,0,0.6,18.5,10.4,25.8c0,0-7.5-13.9-0.3-34.5c0,0,2.3,16.4,9.3,24.1c0,0-2.3-19.1,1.9-30.5c0,0,8.4,23.9,12.1,27.1c0,0-2.8-16.2,4.8-28.6c0,0,2.2,17.1,8.5,26.2c0,0-2.3-11.5,3.4-19.6c0,0,1,25.8,5.7,30.3c0,0-2.3-12.4,1.8-20.7c0,0,3.6,24.4,5.9,29c-7.9-2.6-14.6-2.1-22.2-1.9C221.3,67,199.4,74.8,197.7,120.1z"/>'
                )
            );
    }

    function shortHair(string memory color) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path display="inline" fill="#',
                    color,
                    '" d="M288.2,192.7c0,0,0.1-18.3-2.9-21.5c-3.1-3-7.4-9.2-7.4-9.2s0.3-22.2-3.2-29.6c-3.6-7.4-4.6-19.5-36.1-18.7c-30.7,0.7-41.1,5.8-41.1,5.8s-13.1-7.7-41.9-4c-19.6,5.2-20.3,42.6-20.3,42.6s-1.3,9.2-1.9,14.7c-0.6,5.6-0.3,8.5-0.3,8.5c-0.9,11.8-27.4-116.1,81.3-119.6c110.4,6.8,89.8,101.8,86.7,115.3C295.8,180.8,294.7,183.1,288.2,192.7z"  />',
                    '<g id="Shadow" display="inline" > <path opacity="7.000000e-02"  enable-background="new    " d="M277,141.5c0,0,0.9,3.6,0.9,20.6c0,0,6.6,7.9,8.6,11.7c2,3.6,2.6,18.8,2.6,18.8l5.4-9.2c0,0,1.5-1.8,5.7-4c0,0,7-15.6,3.4-46.3C303.7,133.1,295.1,139.9,277,141.5z" /> <path opacity="7.000000e-02"  enable-background="new    " d="M132.9,182.7c0,0,0.4-11.3,2.3-24.4c0,0,1.9-15.1,3.4-21.9c-1.9,0-6.9,0-8.5-1.1C130,135.3,128.7,177.5,132.9,182.7z" /> </g>'
                )
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Hair Blood";
        } else if (id == 2) {
            name = "Tattoo Blood";
        } else if (id == 3) {
            name = "Tattoo Moon";
        } else if (id == 4) {
            name = "Tattoo Pure";
        } else if (id == 5) {
            name = "Monk Blood";
        } else if (id == 6) {
            name = "Monk Moon";
        } else if (id == 7) {
            name = "Monk Pure";
        } else if (id == 8) {
            name = "Flame Blood";
        } else if (id == 9) {
            name = "Flame Moon";
        } else if (id == 10) {
            name = "Flame Pure";
        } else if (id == 11) {
            name = "Top eyes";
        } else if (id == 12) {
            name = "Middle eyes";
        } else if (id == 13) {
            name = "Side eyes";
        } else if (id == 14) {
            name = "Akuma";
        } else if (id == 15) {
            name = "Hair Moon";
        } else if (id == 16) {
            name = "Hair Pure";
        } else if (id == 17) {
            name = "Tatoo Kin";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="hair"><g id="', name, '">', children, "</g></g>"));
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