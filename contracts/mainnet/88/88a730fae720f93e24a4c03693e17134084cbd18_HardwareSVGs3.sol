// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs3 is IHardwareSVGs, ICategories {
    function hardware_10() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Magnifying Glass',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h10-e" x1="85.41" x2="134.59" y1="147" y2="147"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h10-b" x1="107.5" x2="112.5" y1="120.68" y2="120.68"><stop offset="0" stop-color="gray"/><stop offset=".2" stop-color="#4b4b4b"/><stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h10-a" x1="110" x2="110" y1="117.74" y2="79.91"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h10-c" x1="110" x2="110" y1="79.91" y2="117.67"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h10-f" x1="106.67" x2="113.33" xlink:href="#h10-a" y1="80.29" y2="80.29"/><linearGradient id="h10-g" x1="106.67" x2="113.33" xlink:href="#h10-b" y1="164.1" y2="164.1"/><linearGradient id="h10-h" xlink:href="#h10-c" y1="142" y2="92"/><linearGradient gradientUnits="userSpaceOnUse" id="h10-j" x1="110" x2="110" y1="139" y2="95"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><radialGradient cx=".5" cy=".35" id="h10-i" r=".95"><stop offset="0" stop-color="#8c8c8c" stop-opacity="0"/><stop offset=".55" stop-color="#fff" stop-opacity=".8"/><stop offset=".65" stop-color="#8c8c8c" stop-opacity="0"/><stop offset=".75" stop-color="#fff"/></radialGradient><filter id="h10-d"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h10-d)"><path d="M110 141.59A24.59 24.59 0 1 1 134.59 117 24.62 24.62 0 0 1 110 141.59ZM131.34 117A21.34 21.34 0 1 0 110 138.34 21.36 21.36 0 0 0 131.34 117Z" fill="url(#h10-e)"/><path d="M112.5 141.5h-5v3.65h5Z" fill="url(#h10-b)"/><path d="M112.5 158.53c0-4.82 3-9 .68-12.27h-6.36c-2.28 3.28.68 7.45.68 12.27s-2.79 6.68-2.79 14.74 3.43 10.82 5.29 10.82 5.29-2.76 5.29-10.82-2.79-9.92-2.79-14.74Z" fill="url(#h10-a)"/><path d="M111 158.53c0-4.82 1.33-8.92.34-12.2h-2.74c-1 3.28.34 7.38.34 12.2s-1.15 6.68-1.15 14.74 1.41 10.82 2.18 10.82 2.18-2.76 2.18-10.82-1.15-9.92-1.15-14.74Z" fill="url(#h10-c)"/><path d="M112.5 184.71h-5l-.83-1 3.33-1 3.33 1Z" fill="url(#h10-f)"/><path d="M113.33 146.5h-6.66v-2h6.66Zm0 35.21h-6.66v2h6.66Z" fill="url(#h10-g)"/><circle cx="110" cy="117" fill="none" r="24.5" stroke="url(#h10-h)"/></g><path d="M110 138.37A21.37 21.37 0 1 0 88.63 117 21.37 21.37 0 0 0 110 138.37Z" fill="url(#h10-i)"/><circle cx="110" cy="117" fill="none" r="21.5" stroke="url(#h10-j)"/>'
                    )
                )
            );
    }

    function hardware_11() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Shears',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(-1 0 0 1 220 0)" gradientUnits="userSpaceOnUse" id="h11-b" x1="110" x2="110" y1="125.67" y2="181.89"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h11-c" x1="110.01" x2="110.01" y1="127.08" y2="84.42"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h11-d" x1="110.01" x2="110.01" y1="182.89" y2="89.84"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h11-e" x1="110" x2="110" y1="127.08" y2="84.42"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h11-a"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h11-a)"><path d="m119.78 125.9-4.41 29.1a15.17 15.17 0 0 0 2.49 11 8.93 8.93 0 0 1 1.52 5.3 9.39 9.39 0 0 1-18.77-.26 8.93 8.93 0 0 1 1.54-5.05 15.14 15.14 0 0 0 2.48-11l-4.41-29.09" fill="none" stroke="url(#h11-b)" stroke-miterlimit="10" stroke-width="3"/><path d="m104.62 84.42 5.38 42.66H98Zm10.77 0L110 127.08h12Z" fill="url(#h11-c)"/><path d="m116.14 90 4.92 28.32a42 42 0 0 1-.21 13.47l-4 23.62a11.94 11.94 0 0 0 2.1 8.79c4.89 7.08.85 17.67-8.92 17.67s-13.81-10.59-8.92-17.67a11.94 11.94 0 0 0 2.1-8.79l-4-23.62a44.09 44.09 0 0 1-.21-13.47L103.86 90" fill="none" stroke="url(#h11-d)" stroke-miterlimit="10" stroke-width="2"/><path d="M104.62 84.42 110 127v.07h-3.07l-4-37.23Zm10.76 0L110 127v.07h3.07l4-37.23Z" fill="url(#h11-e)"/></g>'
                    )
                )
            );
    }

    function hardware_12() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'End Cutting Pliers',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h12-a" x1="25" x2="25" y1="79.55" y2="36.44"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(-1, 0, 0, 1, 16432, 0)" id="h12-b" x1="16412.42" x2="16412.42" xlink:href="#h12-a" y1="68.54" y2="22.76"/><linearGradient gradientTransform="matrix(-1, 0, 0, 1, 16432, 0)" id="h12-c" x1="16401.77" x2="16401.77" xlink:href="#h12-a" y1="22.76" y2="82.78"/><linearGradient gradientTransform="translate(16432 16500.18) rotate(180)" id="h12-d" x1="16396.76" x2="16396.76" xlink:href="#h12-a" y1="16488.95" y2="16477.42"/><linearGradient gradientTransform="translate(16432 16500.18) rotate(180)" id="h12-e" x1="16394.5" x2="16394.5" xlink:href="#h12-a" y1="16477.42" y2="16500.18"/><linearGradient gradientTransform="translate(16432 16500.18) rotate(180)" id="h12-f" x1="16393.71" x2="16393.71" xlink:href="#h12-a" y1="16495.92" y2="16479.42"/><linearGradient gradientTransform="translate(16432 16500.18) rotate(180)" id="h12-g" x1="16394.13" x2="16382.01" xlink:href="#h12-a" y1="16478.42" y2="16478.42"/><linearGradient gradientTransform="translate(16432 16500.18) rotate(180)" id="h12-h" x1="16403.4" x2="16403.4" xlink:href="#h12-a" y1="16500.18" y2="16486.63"/><linearGradient gradientTransform="translate(16432 16500.18) rotate(180)" id="h12-i" x1="16431.5" x2="16431.5" xlink:href="#h12-a" y1="16420.62" y2="16432.58"/><linearGradient gradientTransform="translate(16399.39 16417.42) rotate(180)" gradientUnits="userSpaceOnUse" id="h12-j" x1="16384" x2="16399.39" y1="16400.71" y2="16400.71"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="translate(16399.39 16417.42) rotate(180)" id="h12-k" x1="16391.74" x2="16391.74" xlink:href="#h12-a" y1="16384.56" y2="16415.42"/><filter id="h12-l" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient id="h12-m" x1="" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h12-n" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="h12-o" viewBox="0 0 50 82.78"><path d="M6.93,63c5.31-5,6.22-10.27,7.72-13.92,2-4.86,5.38-7.61,10.35-9.62,0,0,12.87-6.06,12.87-16.66,0-6.79-8-9.21-8-9.21L25,0h0c.14,0,25,4.05,25,22.76,0,7.87-4.88,15-8.26,21.14-4.54,7.15-5.2,10.69-7,13.86a22.84,22.84,0,0,1-9.79,10s-9.75,4.39-11.65,7.35-1.91,7.65-1.91,7.65H0v-15A23.91,23.91,0,0,0,6.93,63Z" fill="url(#h12-a)"/><path d="M38.37,22.76c0,10.79-12.62,16.86-13.16,17.12C11.79,45,16.88,54.26,7.27,63.32A24.68,24.68,0,0,1,.5,68.09" fill="none" stroke="url(#h12-b)"/><path d="M11,82.76c.06-1.31.36-5.41,2-7.92,2-3.09,11.77-7.49,11.86-7.53a22.14,22.14,0,0,0,9.56-9.79c2.45-4.89,2.83-7.4,7-13.88,3.54-6.4,8.14-13.15,8.18-20.88" fill="none" stroke="url(#h12-c)"/><path d="M29.85,13.55l2.35-2.32,8.13,2.32.3,7.21-2.76,2C37.87,16,29.85,13.55,29.85,13.55Z" fill="url(#h12-d)"/><path d="M29.71,4.26,25,0c.18,0,25,4.07,25,22.76l-3.12-2Z" fill="url(#h12-e)"/><path d="M46.88,20.76c-.56-4.26-3.51-12.24-17.17-16.5l2.49,7c6,2.55,7.88,6.94,8.43,9.53Z" fill="url(#h12-f)"/><path d="M37.87,22.76l2.76-2h6.25l3.12,2Z" fill="url(#h12-g)"/><path d="M29.71,4.26,25,0l4.85,13.55,2.35-2.32Z" fill="url(#h12-h)"/><path d="M0,67.76l1,.64V82.76H0Z" fill="url(#h12-i)"/></symbol><symbol id="h12-q" viewBox="0 0 15.39 33.42"><path d="M1.74,0H13.66a1.73,1.73,0,0,1,1.73,1.78l-.92,31.64A49.82,49.82,0,0,1,.05,27.12L0,1.73A1.73,1.73,0,0,1,1.74,0Z" fill="url(#h12-j)"/><path d="M5.09,2h5.12a3.06,3.06,0,0,1,3.08,3.16l-.81,27.7A50.22,50.22,0,0,1,2.05,28.34L2,5.09A3.08,3.08,0,0,1,5.09,2Z" fill="url(#h12-k)"/></symbol></defs><polygon points="110 79.24 107.2 84.24 110 83.24 112.8 84.24 110 79.24"/><g filter="url(#h12-l)"><use height="82.78" transform="translate(85 79.24)" width="50" xlink:href="#h12-o"/><use height="82.78" transform="matrix(-1, 0, 0, 1, 135, 79.24)" width="50" xlink:href="#h12-o"/><path d="M110,138.1a6.1,6.1,0,1,0-6.1-6.1A6.1,6.1,0,0,0,110,138.1Z" fill="url(#h12-m)" stroke="url(#h12-n)" stroke-width="2"/><path d="M112.4,131.41h-4.79v1.18h4.79Z"/><path d="M109.41,129.61v4.78h1.18v-4.78Z"/></g><use height="33.42" transform="translate(83.01 162)" width="15.39" xlink:href="#h12-q"/><use height="33.42" transform="matrix(-1, 0, 0, 1, 137, 162)" width="15.39" xlink:href="#h12-q"/>'
                    )
                )
            );
    }

    function hardware_13() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Wheel',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h13-a" x2="4.217" y1="11.286" y2="11.286"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h13-b" x1="0.137" x2="3.896" y1="5.733" y2="5.733"><stop offset="0" stop-color="gray"/><stop offset="0.239" stop-color="#4b4b4b"/><stop offset="0.681" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h13-c" x1="0.038" x2="3.701" y1="12.483" y2="12.483"><stop offset="0" stop-color="gray"/><stop offset="0.239" stop-color="#4b4b4b"/><stop offset="0.681" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h13-d" x1="1.758" x2="1.758" y1="3.517"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h13-e" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="translate(18.633 -18.633)" gradientUnits="userSpaceOnUse" id="h13-f" x1="86.051" x2="96.683" y1="155.949" y2="145.318"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h13-g" x1="64.862" x2="117.971" xlink:href="#h13-f" y1="177.14" y2="124.029"/><linearGradient gradientTransform="translate(18.633 -18.633)" id="h13-h" x1="91.367" x2="91.367" xlink:href="#h13-d" y1="142.138" y2="159.128"/><linearGradient gradientTransform="translate(18.633 -18.633)" id="h13-i" x1="91.367" x2="91.367" xlink:href="#h13-d" y1="112.654" y2="188.612"/><linearGradient id="h13-j" x1="91.367" x2="91.367" xlink:href="#h13-f" y1="145.62" y2="155.646"/><linearGradient id="h13-k" x1="91.367" x2="91.367" xlink:href="#h13-f" y1="145.631" y2="155.635"/><linearGradient id="h13-l" x1="91.367" x2="91.367" xlink:href="#h13-f" y1="119.228" y2="182.038"/><symbol id="h13-n" viewBox="0 0 4.217 13.017"><path d="M.473,11.466,0,11.95l2.109.356,2.108-.356-.473-.484v-.485l-.607-.714H1.08l-.607.712v.487Z" fill="url(#h13-a)"/><path d="M3.744,11.466H.473v-.485H3.744ZM3.944,0,3.331,10.5H.886L.272,0Z" fill="url(#h13-b)"/><rect fill="url(#h13-c)" height="1.067" width="4.217" y="11.95"/></symbol><symbol id="h13-m" viewBox="0 0 4.217 30.763"><use height="13.017" transform="translate(0 17.747)" width="4.217" xlink:href="#h13-n"/><use height="13.017" transform="matrix(1, 0, 0, -1, 0, 13.017)" width="4.217" xlink:href="#h13-n"/></symbol><symbol id="h13-y" viewBox="0 0 3.517 3.517"><circle cx="1.758" cy="1.758" r="1.508" stroke="url(#h13-d)" stroke-width="0.5"/></symbol></defs><g filter="url(#h13-e)"><use height="30.763" transform="translate(105.703 101.551) scale(2.038 1.98)" width="4.217" xlink:href="#h13-m"/><use height="30.763" transform="matrix(1.441, -1.441, 1.4, 1.4, 85.431, 113.508)" width="4.217" xlink:href="#h13-m"/><use height="30.763" transform="matrix(0, -2.038, 1.98, 0, 79.551, 136.297)" width="4.217" xlink:href="#h13-m"/><use height="30.763" transform="matrix(-1.441, -1.441, 1.4, -1.4, 91.508, 156.569)" width="4.217" xlink:href="#h13-m"/><path d="M110,138.086A6.086,6.086,0,1,1,116.086,132,6.091,6.091,0,0,1,110,138.086Z" fill="none" stroke="url(#h13-f)" stroke-width="2.9"/><path d="M110,165.935A33.935,33.935,0,1,1,143.935,132,33.975,33.975,0,0,1,110,165.935Z" fill="none" stroke="url(#h13-g)" stroke-width="7"/><path d="M110,139.986A7.986,7.986,0,1,1,117.986,132,7.994,7.994,0,0,1,110,139.986Z" fill="none" stroke="url(#h13-h)"/><path d="M110,169.469A37.469,37.469,0,1,1,147.469,132,37.513,37.513,0,0,1,110,169.469Z" fill="none" stroke="url(#h13-i)"/><circle cx="110" cy="132" fill="none" r="4.492" stroke="url(#h13-j)"/><circle cx="110" cy="132" fill="none" r="4.492" stroke="url(#h13-k)"/><circle cx="110" cy="132" fill="none" r="30.896" stroke="url(#h13-l)"/><use height="3.517" transform="translate(108.103 96.164)" width="3.517" xlink:href="#h13-y"/><use height="3.517" transform="translate(108.38 164.319)" width="3.517" xlink:href="#h13-y"/><use height="3.517" transform="translate(84.047 106.243)" width="3.517" xlink:href="#h13-y"/><use height="3.517" transform="translate(74.164 130.38)" width="3.517" xlink:href="#h13-y"/><use height="3.517" transform="translate(84.243 154.436)" width="3.517" xlink:href="#h13-y"/><use height="3.517" transform="matrix(-1, 0, 0, 1, 135.953, 106.243)" width="3.517" xlink:href="#h13-y"/><use height="3.517" transform="matrix(-1, 0, 0, 1, 145.836, 130.38)" width="3.517" xlink:href="#h13-y"/><use height="3.517" transform="matrix(-1, 0, 0, 1, 135.757, 154.436)" width="3.517" xlink:href="#h13-y"/></g>'
                    )
                )
            );
    }

    function hardware_14() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Tuning Fork',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><filter id="h14-a" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientUnits="userSpaceOnUse" id="h14-b" x1="109.99" x2="109.99" y1="152.29" y2="87.5"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h14-c" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h14-d" x1="112.99" x2="106.99" y1="96.5" y2="96.5"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h14-e" x1="106.99" x2="112.99" y1="113.32" y2="113.32"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h14-f" x1="106.99" x2="112.99" y1="78.5" y2="78.5"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h14-g" x1="110" x2="110" xlink:href="#h14-b" y1="152.41" y2="141.6"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h14-h" x1="116.99" x2="116.99" y1="122.12" y2="115.22"><stop offset="0" stop-color="#696969"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="translate(219.99 264) rotate(180)" id="h14-i" x1="116.99" x2="116.99" xlink:href="#h14-h" y1="122.12" y2="115.22"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h14-j" x1="99" x2="120.99" xlink:href="#h14-e" y1="87.5" y2="87.5"/></defs><g filter="url(#h14-a)"><path d="M120.49,87.5h-5V132a5.5,5.5,0,0,1-11,0V87.5h-5v54.3L110,152.29l10.49-10.49Z" fill="url(#h14-b)" stroke="url(#h14-c)"/><path d="M113,150h-6v35h6Z" fill="url(#h14-d)"/><path d="M107,148.59v4.18h6v-4.18s-.7,1.23-3,1.23S107,148.59,107,148.59Z" fill="url(#h14-e)"/><path d="M107,185l1,1h4l1-1Z" fill="url(#h14-f)"/><path d="M110.52,140.15h-1l-2.16,5.64h1l.52-1.49h2.26l.53,1.49h1Zm-1.4,3.4.87-2.46.86,2.46Z" fill="url(#h14-g)"/><path d="M120,141.59l1,.41-8,8v-1.41Z" fill="url(#h14-h)"/><path d="M100,141.59,99,142l8,8v-1.41Z" fill="url(#h14-i)"/><path d="M104,88h-4l-1-1h6Zm12,0h4l1-1h-6Z" fill="url(#h14-j)"/></g>'
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