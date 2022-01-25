// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs5 is IHardwareSVGs, ICategories {
    function hardware_19() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Calipers',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h19-a" x1="18.89" x2="18.89" y2="84.77"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h19-h" x1="7.44" x2="37.77" y1="42.38" y2="42.38"><stop offset="0" stop-color="#696969"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h19-i" x1="41.51" x2="1.83" xlink:href="#h19-h" y1="71.87" y2="11.1"/><linearGradient id="h19-j" x1="10.62" x2="10.62" xlink:href="#h19-a" y1="7.36" y2="81.72"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16468.77)" id="h19-k" x1="21.61" x2="21.61" xlink:href="#h19-h" y1="16453.16" y2="16426.16"/><linearGradient id="h19-l" x1="5.46" x2="16.79" xlink:href="#h19-a" y1="63.19" y2="63.19"/><linearGradient id="h19-m" x1="18.89" x2="18.89" xlink:href="#h19-a" y1="41.61" y2="15.61"/><linearGradient id="h19-n" x1="-0.61" x2="8.31" xlink:href="#h19-h" y1="13.55" y2="13.55"/><filter id="h19-o" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h19-p" viewBox="0 0 37.77 84.77"><polygon fill="url(#h19-a)" points="24.36 0 7.44 0 7.44 0 7.44 84.77 14.8 84.77 14.8 4.51 37.77 5.61 37.77 2.8 24.36 0"/><polygon fill="url(#h19-a)" points="24.05 1 8.44 1 7.44 0 7.44 5.61 0 5.61 0 9.23 6.44 11.35 8.44 11.36 8.44 83.77 13.8 83.77 13.8 5.61 37.77 5.61 37.77 3.61 24.05 1"/><path d="M12.81,9.61H8.44m2.37-2H8.44m4.37,6H8.44m2.37-2H8.44m0,27.86h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37" fill="url(#h19-a)"/><path d="M16.79,42.61V21.5H24.2l13.57-3.09v-2.8L6.46,17.76V20.5l-1,1V42.61Z" fill="url(#h19-a)"/><path d="M13.81,83.77l1,1H7.44l1-1ZM6.46,41.61l-1,1H16.79l-1-1Z" fill="url(#h19-a)"/><polygon fill="url(#h19-a)" points="6.46 15.61 0 17.98 0 21.5 6.46 20.5 6.46 41.61 15.79 41.61 15.79 20.5 23.79 20.5 37.77 17.41 37.77 15.61 6.46 15.61"/><path d="M6.46,20.5H1l-1,1H5.46ZM0,9.23l1-.82,5.44,2.94-2.51,0ZM8.44,6.61l-1-1H0l1,1ZM1,18.77l5.46-3.16H3.93L0,18Z" fill="url(#h19-a)"/><polygon fill="url(#h19-h)" points="24.36 0 7.44 0 7.44 0 7.44 84.77 14.8 84.77 14.8 4.51 37.77 5.61 37.77 2.8 24.36 0"/><polygon fill="url(#h19-i)" points="24.05 1 8.44 1 7.44 0 7.44 5.61 0 5.61 0 9.23 6.44 11.35 8.44 11.36 8.44 83.77 13.8 83.77 13.8 5.61 37.77 5.61 37.77 3.61 24.05 1"/><path d="M12.81,9.61H8.44m2.37-2H8.44m4.37,6H8.44m2.37-2H8.44m0,27.86h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37m-2.37,2h4.37m-4.37,2h2.37" fill="none" stroke="url(#h19-j)" stroke-width="0.5"/><path d="M16.79,42.61V21.5H24.2l13.57-3.09v-2.8L6.46,17.76V20.5l-1,1V42.61Z" fill="url(#h19-k)"/><path d="M13.81,83.77l1,1H7.44l1-1ZM6.46,41.61l-1,1H16.79l-1-1Z" fill="url(#h19-l)"/><polygon fill="url(#h19-m)" points="6.46 15.61 0 17.98 0 21.5 6.46 20.5 6.46 41.61 15.79 41.61 15.79 20.5 23.79 20.5 37.77 17.41 37.77 15.61 6.46 15.61"/><path d="M6.46,20.5H1l-1,1H5.46ZM0,9.23l1-.82,5.44,2.94-2.51,0ZM8.44,6.61l-1-1H0l1,1ZM1,18.77l5.46-3.16H3.93L0,18Z" fill="url(#h19-n)"/></symbol></defs><g filter="url(#h19-o)"><use height="84.77" transform="translate(113.03 96.39)" width="37.77" xlink:href="#h19-p"/><use height="84.77" transform="matrix(-1, 0, 0, 1, 106.97, 96.39)" width="37.77" xlink:href="#h19-p"/></g>'
                    )
                )
            );
    }

    function hardware_20() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Three Nails',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16482)" gradientUnits="userSpaceOnUse" id="h20-a" x1="9.33" x2="4" y1="16437.84" y2="16437.84"><stop offset="0" stop-color="gray"/><stop offset=".2" stop-color="#4b4b4b"/><stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h20-c" x1="0" x2="13.33" xlink:href="#h20-a" y1="16480.58" y2="16480.58"/><linearGradient gradientUnits="userSpaceOnUse" id="h20-d" x2="13.33" y1="2.83" y2="2.83"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16482)" gradientUnits="userSpaceOnUse" id="h20-b" x1="5.33" x2="5.33" y1="16396.98" y2="16383"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h20-e" x1="8" x2="8" xlink:href="#h20-b" y1="16383" y2="16396.98"/><linearGradient id="h20-f" x1="4" x2="9.33" xlink:href="#h20-b" y1="16461.67" y2="16461.67"/><symbol id="h20-h" viewBox="0 0 13.33 99"><path d="M9.33 2.64H4v83.03h5.33Z" fill="url(#h20-a)"/><path d="M13.33 0H0v2l6.67.83L13.33 2Z" fill="url(#h20-c)"/><path d="M13.33 2H0l4 1.67h5.33Z" fill="url(#h20-d)"/><path d="M4 85.67c1.21-1.46 2.67 0 2.67 0V99Z" fill="url(#h20-b)"/><path d="M9.33 85.67c-1.2-1.46-2.66 0-2.66 0V99Z" fill="url(#h20-e)"/><path d="M9.33 28.33a4.24 4.24 0 0 1-5.33 0 4.24 4.24 0 0 1 5.33 0Zm0-16a4.24 4.24 0 0 0-5.33 0 4.24 4.24 0 0 0 5.33 0ZM4 23a4.24 4.24 0 0 0 5.33 0A4.24 4.24 0 0 0 4 23Zm0 2.67a4.24 4.24 0 0 0 5.33 0 4.24 4.24 0 0 0-5.33 0ZM4 15a4.24 4.24 0 0 0 5.33 0A4.24 4.24 0 0 0 4 15Zm0 2.67a4.24 4.24 0 0 0 5.33 0 4.24 4.24 0 0 0-5.33 0Zm0 2.66a4.24 4.24 0 0 0 5.33 0 4.24 4.24 0 0 0-5.33 0Z" fill="url(#h20-f)"/></symbol><filter id="h20-g"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h20-g)"><use height="99" transform="rotate(39.81 -58.19 232.54)" width="13.33" xlink:href="#h20-h"/><use height="99" transform="scale(-1 1) rotate(39.81 -168.18 -71.28)" width="13.33" xlink:href="#h20-h"/><use height="99" transform="translate(103.33 87.5)" width="13.33" xlink:href="#h20-h"/></g>'
                    )
                )
            );
    }

    function hardware_21() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Awl',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h21-c" x1="97.93" x2="121.14" y1="111.67" y2="111.67"><stop offset="0" stop-color="gray"/><stop offset=".2" stop-color="#4b4b4b"/><stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h21-d" x1="110" x2="110" y1="170.13" y2="153.4"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h21-a" x1="108.53" x2="111.13" y1="104.61" y2="104.61"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h21-e" x1="103.36" x2="116.64" y1="139.66" y2="139.66"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h21-f" x1="105.36" x2="114.64" y1="144" y2="144"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h21-g" x1="104.46" x2="114.26" xlink:href="#h21-a" y1="124.84" y2="124.84"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h21-h" x1="108.53" x2="111.13" y1="92.39" y2="92.39"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".32" stop-color="#fff"/><stop offset=".76" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h21-b"><feDropShadow dx="0" dy="4" stdDeviation="0"/></filter></defs><g filter="url(#h21-b)"><path d="M125.35 102.23c0-5.18-6.87-10.89-15.35-10.89s-15.35 5.7-15.35 10.9c0 7.4 5.92 11.32 7.49 15.42s1.22 14.34 1.22 14.34h13.28s-.34-10.24 1.22-14.34 7.5-8.02 7.5-15.43Z" fill="url(#h21-c)"/><path d="M110 110.6c5.96 0 10.79-3.74 10.79-8.36s-4.83-8.37-10.79-8.37-10.79 3.74-10.79 8.37 4.83 8.36 10.79 8.36Z" fill="url(#h21-d)"/><path d="M110 142.15h-1.5v16.02c0 11.9 1.5 18.45 1.5 18.45s1.5-6.54 1.5-18.45v-16.02Z" fill="url(#h21-a)"/><path d="m116.64 132-6.64 6.64-6.64-6.64Zm-2 14.32-4.64-1-4.64 1 1 1h7.28Z" fill="url(#h21-e)"/><path d="m114.64 146.32-4.64-4.64-4.64 4.64h9.28z" fill="url(#h21-f)"/><path d="M113.64 145.32h-7.28l-2-12.32h11.28Z" fill="url(#h21-g)"/><path d="M111.5 158.16a69.16 69.16 0 0 1-1.5 13.91 69.16 69.16 0 0 1-1.5-13.9c0 11.9.35 13.37 1.5 26.88 1.15-13.5 1.5-14.97 1.5-26.89Z" fill="url(#h21-h)"/></g>'
                    )
                )
            );
    }

    function hardware_22() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'French Key Wrench',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient id="h22-c" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h22-a" x1="1" x2="0" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h22-i" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h22-b" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h22-j" x1="0" x2="0" xlink:href="#h22-a" y1="0" y2="1"/><linearGradient id="h22-k" x1="105.92" x2="114.08" xlink:href="#h22-b" y1="173.15" y2="173.15"/><linearGradient id="h22-l" x1="0" x2="1" xlink:href="#h22-c" y1="0" y2="0"/><linearGradient id="h22-m" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><symbol id="h22-g" viewBox="0 0 2 24.35"><path d="M0 24.35h2V0H0v24.35z" fill="url(#h22-c)"/></symbol><symbol id="h22-d" viewBox="0 0 7 1.73"><path d="m7 .86-6 .87-1-.87L6 0l1 .86z" fill="url(#h22-a)"/></symbol><symbol id="h22-e" viewBox="0 0 7 2.73"><use height="1.73" transform="translate(0 1)" width="7" xlink:href="#h22-d"/><use height="1.73" transform="rotate(180 3.5 .865)" width="7" xlink:href="#h22-d"/></symbol><symbol id="h22-h" viewBox="0 0 7 14.73"><use height="2.73" transform="translate(0 10)" width="7" xlink:href="#h22-e"/><use height="2.73" transform="translate(0 12)" width="7" xlink:href="#h22-e"/><use height="2.73" transform="translate(0 8)" width="7" xlink:href="#h22-e"/><use height="2.73" transform="translate(0 6)" width="7" xlink:href="#h22-e"/><use height="2.73" transform="translate(0 4)" width="7" xlink:href="#h22-e"/><use height="2.73" transform="translate(0 2)" width="7" xlink:href="#h22-e"/><use height="2.73" width="7" xlink:href="#h22-e"/></symbol><filter id="h22-f"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h22-f)"><use height="24.35" transform="translate(102 102)" width="2" xlink:href="#h22-g"/><use height="14.73" transform="translate(106.5 119.13)" width="7" xlink:href="#h22-h"/><use height="14.73" transform="translate(106.5 99.13)" width="7" xlink:href="#h22-h"/><use height="14.73" transform="translate(106.5 87.13)" width="7" xlink:href="#h22-h"/><use height="24.35" transform="translate(116 102)" width="2" xlink:href="#h22-g"/><path d="M130 99v2.5H90V99a11.76 11.76 0 0 0 10-5h20a11.76 11.76 0 0 0 10 5Zm-30 21h20a11.76 11.76 0 0 1 10-5v-2.5H90v2.5a11.76 11.76 0 0 1 10 5Z" fill="url(#h22-i)"/><path d="M113.06 147.6c0-4.86 4-8.84 1-12.15h-8.16c-2.93 3.31 1 7.29 1 12.15s-3.41 6.75-3.41 14.89 4.19 10.92 6.47 10.92 6.47-2.78 6.47-10.92-3.37-10.02-3.37-14.89Z" fill="url(#h22-b)"/><path d="M111.26 147.6c0-4.86 1.63-8.84.42-12.15h-3.36c-1.21 3.31.42 7.29.42 12.15s-1.41 6.75-1.41 14.89 1.73 10.92 2.67 10.92 2.67-2.78 2.67-10.92-1.41-10.02-1.41-14.89Z" fill="url(#h22-j)"/><path d="M113.06 174.04h-6.12l-1.02-1.01 4.08-.76 4.08.76-1.02 1.01z" fill="url(#h22-k)"/><path d="M114.08 135.45h-8.16V132h8.16Zm0 35.56h-8.16v2h8.16Z" fill="url(#h22-l)"/><path d="M130 102H90v-1h40Zm0 10H90v1h40Z" fill="url(#h22-m)"/></g>'
                    )
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}