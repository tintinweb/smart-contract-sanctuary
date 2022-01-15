// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

import './interfaces/ISvgGenerator.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract SvgGenerator is ISvgGenerator {
    uint256 immutable MAX_HUE = 360;

    /// @inheritdoc ISvgGenerator
    function generateSvg(bool redeemed, string calldata category)
        external
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _getInitialPart(),
                    redeemed
                        ? ' '
                        : '.rotation-newt { animation: clockwise-rotation 15s linear infinite; transform-box: fill-box; transform-origin: center; } ',
                    _getMiddlePart(),
                    Strings.toString(_stringToIntInInterval(category, 0, MAX_HUE)),
                    _getLastPart()
                )
            );
    }

    /// @dev Generates the first part of the SVG.
    /// @return A string representing the first part of the SVG.
    function _getInitialPart() internal pure returns (string memory) {
        return
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 414.68 414.68"> <defs> <style> @keyframes clockwise-rotation { from { transform: rotate(0deg); } to { transform: rotate(360deg); } } @keyframes counter-clockwise-rotation { from { transform: rotate(360deg); } to { transform: rotate(0deg); } }';
    }

    /// @dev Generates the middle part of the SVG.
    /// @return A string representing the middle part of the SVG.
    function _getMiddlePart() internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '.rotation-2 { animation: counter-clockwise-rotation 5s linear infinite; transform-box: fill-box; transform-origin: center; } ',
                '.rotation-3 { animation: clockwise-rotation 13s linear infinite; transform-box: fill-box; transform-origin: center; } ',
                '.rotation-4 { animation: counter-clockwise-rotation 7s linear infinite; transform-box: fill-box; transform-origin: center; } ',
                '.rotation-5 { animation: clockwise-rotation 3s linear infinite; transform-box: fill-box; transform-origin: center; } ',
                '.rotation-6 { animation: counter-clockwise-rotation 5s linear infinite; transform-box: fill-box; transform-origin: center; } ',
                '.cls-1, .cls-15, .cls-20, .cls-3, .cls-5 { fill: none; } .cls-17, .cls-2 { fill: hsla('
            );
    }

    /// @dev Generates the last part of the SVG.
    /// @return A string representing the last part of the SVG.
    function _getLastPart() internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                ', 100%, 93%, 1); } .cls-15, .cls-2, .cls-3, .cls-5 { stroke: hsla(262, 67%, 76%, 1); } .cls-16, .cls-17, .cls-18, .cls-19, .cls-2, .cls-3 { stroke-miterlimit: 10; } .cls-2, .cls-3 { stroke-width: 4px; } .cls-4 { clip-path: url(#clip-path); } .cls-15, .cls-20, .cls-5 { stroke-linecap: round; stroke-linejoin: round; } .cls-5 { stroke-width: 3px; } .cls-6 { clip-path: url(#clip-path-2); } .cls-7 { clip-path: url(#clip-path-3); } .cls-8 { clip-path: url(#clip-path-4); } .cls-9 { clip-path: url(#clip-path-5); } .cls-10 { clip-path: url(#clip-path-6); } .cls-11 { clip-path: url(#clip-path-7); } .cls-12 { clip-path: url(#clip-path-8); } .cls-13 { clip-path: url(#clip-path-9); } .cls-14 { clip-path: url(#clip-path-10); } .cls-15 { stroke-width: 3px; } .cls-16, .cls-18 { fill: #9a7ac6; } .cls-16, .cls-17 { stroke: #8c6bb4; } .cls-18, .cls-19, .cls-20 { stroke: #9a7ac6; } .cls-19 { fill: #fffeff; } </style>',
                '<clipPath id="clip-path" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="387.39" y="151.38" width="18.18" height="30"/> </clipPath> <clipPath id="clip-path-2" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="255.95" y="151.38" width="18.18" height="30"/> </clipPath> <clipPath id="clip-path-3" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="385.78" y="470.94" width="18.18" height="30"/> </clipPath> <clipPath id="clip-path-4" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="254.34" y="470.94" width="18.18" height="30"/> </clipPath> <clipPath id="clip-path-5" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="153.65" y="383.1" width="30" height="18.18"/> </clipPath> <clipPath id="clip-path-6" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="153.65" y="251.66" width="30" height="18.18"/> </clipPath> <clipPath id="clip-path-7" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="472.19" y="379.79" width="30" height="18.18"/> </clipPath> <clipPath id="clip-path-8" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="472.19" y="248.35" width="30" height="18.18"/> </clipPath> <clipPath id="clip-path-9" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="391.89" y="293.49" width="34.18" height="65.04"/> </clipPath> <clipPath id="clip-path-10" transform="translate(-120.62 -118.82)"> <rect class="cls-1" x="228.75" y="293.49" width="34.18" height="65.04"/> </clipPath> </defs>',
                '<g id="Base"> <circle class="cls-2" cx="207.34" cy="207.34" r="205.34"/> </g> ',
                '<g id="Circle1"> <circle class="cls-3" cx="207.34" cy="207.34" r="192.47"/> </g> ',
                '<g id="Circle2" class="rotation-2"> <g> <g class="cls-4"> <polygon class="cls-5" points="272.77 55.6 271.1 45.49 283.46 34.06 282.5 50.17 272.77 55.6"/> <polyline class="cls-5" points="268.27 51.18 270.35 61.06 279.61 56.37"/> </g> <g class="cls-6"> <polygon class="cls-5" points="147.52 55.6 149.19 45.49 136.83 34.06 137.79 50.17 147.52 55.6"/> <polyline class="cls-5" points="152.02 51.18 149.94 61.06 140.68 56.37"/> </g> </g> <g> <g class="cls-7"> <polygon class="cls-5" points="271.16 359.08 269.48 369.2 281.84 380.62 280.88 364.51 271.16 359.08"/> <polyline class="cls-5" points="266.66 363.5 268.73 353.62 278 358.31"/> </g> <g class="cls-8"> <polygon class="cls-5" points="145.91 359.08 147.58 369.2 135.22 380.62 136.18 364.51 145.91 359.08"/> <polyline class="cls-5" points="150.41 363.5 148.33 353.62 139.06 358.31"/> </g> </g> <g> <g class="cls-9"> <polygon class="cls-5" points="56.06 270.28 45.95 268.6 34.53 280.96 50.64 280 56.06 270.28"/> <polyline class="cls-5" points="51.65 265.78 61.52 267.85 56.84 277.12"/> </g> <g class="cls-10"> <polygon class="cls-5" points="56.06 145.03 45.95 146.7 34.53 134.34 50.64 135.3 56.06 145.03"/> <polyline class="cls-5" points="51.65 149.53 61.52 147.45 56.84 138.18"/> </g> </g> <g> <g class="cls-11"> <polygon class="cls-5" points="358.54 266.97 368.65 265.3 380.07 277.66 363.96 276.7 358.54 266.97"/> <polyline class="cls-5" points="362.95 262.47 353.07 264.55 357.76 273.81"/> </g> <g class="cls-12"> <polygon class="cls-5" points="358.54 141.72 368.65 143.4 380.07 131.03 363.96 131.99 358.54 141.72"/> <polyline class="cls-5" points="362.95 146.22 353.07 144.15 357.76 134.88"/> </g> </g> <path class="cls-5" d="M328.91,169.53s51.13-31.73,78.54-18.7c27.65,13.13,30.74,64.79,30.74,64.79S496,231,503.66,247.48c8.57,18.36-19.64,78.65-19.64,78.65s30,51.91,23.66,69C500.94,413.49,440.47,435,440.47,435s-15.3,58.36-31.9,66.29c-18.63,8.9-80.43-18.89-80.43-18.89s-54.87,25.92-72.4,19c-18.65-7.32-38.63-65.86-38.63-65.86s-58.1-16.47-65.7-33.23c-8-17.67,19.25-75.15,19.25-75.15s-26.55-59-19.82-76.48c6.93-17.94,64.39-35.3,64.39-35.3s26.7-60.9,45.24-67.69C281.18,140.15,328.91,169.53,328.91,169.53Z" transform="translate(-120.62 -118.82)"/> <circle class="cls-3" cx="207.34" cy="207.34" r="155.53"/> </g> ',
                '<g id="Circle3" class="rotation-3"> <g> <g> <polygon class="cls-5" points="203.05 316.67 194.64 340.67 192.12 315.87 203.05 316.67"/> <polygon class="cls-5" points="182.72 347.84 182.22 326.78 168.85 344.57 182.72 347.84"/> <path class="cls-5" d="M322.23,437.65" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="169.33 310 153.92 330.22 159.18 305.86 169.33 310"/> <polygon class="cls-5" points="140.36 333.36 146.39 313.17 128.18 325.96 140.36 333.36"/> <path class="cls-5" d="M287.91,430.43" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="139.32 293.23 118.42 307.7 130.95 286.16 139.32 293.23"/> <polygon class="cls-5" points="104.56 306.49 116.53 289.16 95.25 295.7 104.56 306.49"/> <path class="cls-5" d="M257.51,413" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="115.97 268.01 91.61 275.31 110.19 258.7 115.97 268.01"/> <polygon class="cls-5" points="78.8 269.88 95.55 257.1 73.29 256.74 78.8 269.88"/> <path class="cls-5" d="M234,386.94" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="101.55 236.81 76.13 236.22 98.93 226.17 101.55 236.81"/> <polygon class="cls-5" points="65.63 227.1 85.5 220.12 64.44 212.9 65.63 227.1"/> <path class="cls-5" d="M219.66,354.93" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="97.48 202.68 73.48 194.27 98.28 191.75 97.48 202.68"/> <polygon class="cls-5" points="66.31 182.35 87.37 181.84 69.58 168.48 66.31 182.35"/> <path class="cls-5" d="M215.93,320.06" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="104.15 168.96 83.93 153.54 108.29 158.81 104.15 168.96"/> <polygon class="cls-5" points="80.79 139.99 100.98 146.02 88.19 127.81 80.79 139.99"/> <path class="cls-5" d="M223.16,285.74" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="120.92 138.95 106.45 118.05 127.99 130.58 120.92 138.95"/> <polygon class="cls-5" points="107.65 104.19 124.99 116.16 118.45 94.88 107.65 104.19"/> <path class="cls-5" d="M240.63,255.34" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="146.14 115.6 138.84 91.24 155.45 109.82 146.14 115.6"/> <polygon class="cls-5" points="144.27 78.43 157.05 95.17 157.41 72.92 144.27 78.43"/> <path class="cls-5" d="M266.65,231.82" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="177.34 101.18 177.92 75.76 187.98 98.56 177.34 101.18"/> <polygon class="cls-5" points="187.04 65.25 194.03 85.13 201.25 64.07 187.04 65.25"/> <path class="cls-5" d="M298.66,217.49" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="211.47 97.11 219.88 73.11 222.4 97.91 211.47 97.11"/> <polygon class="cls-5" points="231.8 65.94 232.3 87 245.67 69.21 231.8 65.94"/> <path class="cls-5" d="M333.53,213.76" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="245.19 103.78 260.6 83.56 255.34 107.92 245.19 103.78"/> <polygon class="cls-5" points="274.16 80.42 268.13 100.61 286.34 87.81 274.16 80.42"/> <path class="cls-5" d="M367.85,221" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="275.19 120.55 296.1 106.08 283.57 127.62 275.19 120.55"/> <polygon class="cls-5" points="309.96 107.28 297.99 124.61 319.26 118.08 309.96 107.28"/> <path class="cls-5" d="M398.25,238.46" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="298.55 145.77 322.91 138.47 304.33 155.08 298.55 145.77"/> <polygon class="cls-5" points="335.72 143.9 318.97 156.68 341.23 157.04 335.72 143.9"/> <path class="cls-5" d="M421.77,264.48" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="312.97 176.97 338.39 177.55 315.59 187.61 312.97 176.97"/> <polygon class="cls-5" points="348.89 186.67 329.02 193.66 350.07 200.88 348.89 186.67"/> <path class="cls-5" d="M436.09,296.49" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="317.04 211.1 341.04 219.51 316.24 222.03 317.04 211.1"/> <polygon class="cls-5" points="348.21 231.43 327.15 231.93 344.94 245.3 348.21 231.43"/> <path class="cls-5" d="M439.83,331.36" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="310.37 244.82 330.59 260.23 306.23 254.97 310.37 244.82"/> <polygon class="cls-5" points="333.73 273.79 313.54 267.76 326.33 285.97 333.73 273.79"/> <path class="cls-5" d="M432.6,365.67" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="293.6 274.82 308.07 295.73 286.53 283.2 293.6 274.82"/> <polygon class="cls-5" points="306.87 309.59 289.53 297.62 296.07 318.89 306.87 309.59"/> <path class="cls-5" d="M415.12,396.08" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="268.38 298.18 275.68 322.54 259.07 303.96 268.38 298.18"/> <polygon class="cls-5" points="270.25 335.34 257.47 318.6 257.11 340.86 270.25 335.34"/> <path class="cls-5" d="M389.11,419.6" transform="translate(-120.62 -118.82)"/> </g> <g> <polygon class="cls-5" points="237.18 312.6 236.6 338.02 226.54 315.21 237.18 312.6"/> <polygon class="cls-5" points="227.47 348.52 220.49 328.65 213.27 349.7 227.47 348.52"/> <path class="cls-5" d="M357.1,433.92" transform="translate(-120.62 -118.82)"/> </g> </g> <circle class="cls-3" cx="207.34" cy="207.34" r="144.22"/> </g> ',
                '<g id="Circle4" class="rotation-4"> <polygon class="cls-5" points="208.52 107.67 252.6 107.67 277.54 137.53 309.96 169.24 306.83 207.06 309.3 245.7 277.61 277.23 252.08 307.24 208.06 307.37 167.72 309.85 137.58 276.92 107.13 252.81 107.9 207.99 102.95 171.36 136.34 137.51 162 106.9 208.52 107.67"/> <circle class="cls-3" cx="207.34" cy="207.34" r="109.43"/> </g> ',
                '<g id="Circle5" class="rotation-5"> <g> <g> <polyline class="cls-5" points="167.51 134.16 159.08 154.9 135.51 152.66"/> <polyline class="cls-5" points="178.04 142.05 170.66 125.28 127.51 150.59 141.81 177.35 144.96 171.84 134.19 152.01 167.64 132.84 172.92 144.64 161.65 151.61"/> <path class="cls-5" d="M326.54,227.16s-1.14,6.5-4,9-9.62,7-10,9-1.71,8,.15,11" transform="translate(-120.62 -118.82)"/> </g> <g> <polyline class="cls-5" points="168.67 280.53 160.24 259.79 136.66 262.03"/> <polyline class="cls-5" points="179.2 272.64 171.82 289.42 128.66 264.1 142.97 237.34 146.12 242.85 135.35 262.69 168.8 281.85 174.08 270.05 162.81 263.08"/> <path class="cls-5" d="M327.7,425.17s-1.14-6.5-4-9-9.62-7-10-9-1.72-8,.14-11" transform="translate(-120.62 -118.82)"/> </g> <g> <polyline class="cls-5" points="168.67 135 160.24 155.74 136.66 153.5"/> <polyline class="cls-5" points="179.2 142.89 171.82 126.12 128.66 151.43 142.97 178.19 146.12 172.68 135.35 152.84 168.8 133.68 174.08 145.48 162.81 152.45"/> <path class="cls-5" d="M327.7,228s-1.14,6.5-4,9-9.62,7-10,9-1.72,8,.14,11" transform="translate(-120.62 -118.82)"/> </g> <g> <polyline class="cls-5" points="247.15 280.53 255.57 259.79 279.15 262.03"/> <polyline class="cls-5" points="236.62 272.64 243.99 289.42 287.15 264.1 272.85 237.34 269.7 242.85 280.47 262.69 247.01 281.85 241.74 270.05 253.01 263.08"/> <path class="cls-5" d="M329.35,425.17s1.14-6.5,4-9,9.63-7,10-9,1.71-8-.15-11" transform="translate(-120.62 -118.82)"/> </g> <g> <polyline class="cls-5" points="247.15 135 255.57 155.74 279.15 153.5"/> <polyline class="cls-5" points="236.62 142.89 243.99 126.12 287.15 151.43 272.85 178.19 269.7 172.68 280.47 152.84 247.01 133.68 241.74 145.48 253.01 152.45"/> <path class="cls-5" d="M329.35,228s1.14,6.5,4,9,9.63,7,10,9,1.71,8-.15,11" transform="translate(-120.62 -118.82)"/> </g> <g> <g class="cls-13"> <path class="cls-5" d="M393.39,298s13.7-5.45,15.88-1.55c3.76,6.74-11,16.38-11,16.38s28.23,2.6,26.23,14.36-26.78,12.59-26.78,12.59,16.52,7.15,13.91,14.93c-1.88,5.56-17.94-.38-17.94-.38" transform="translate(-120.62 -118.82)"/> <path class="cls-5" d="M395.37,301.17s6.85-3.25,8.23-1c1.64,2.73-5.9,8.52-5.9,8.52" transform="translate(-120.62 -118.82)"/> <path class="cls-5" d="M398.34,318.08s20.82,2.36,21.27,8.08c.46,6-20.88,8.92-20.88,8.92" transform="translate(-120.62 -118.82)"/> <path class="cls-5" d="M397,343.41s10.5,4.91,9.09,8.1c-1.3,2.95-11.31-.56-11.31-.56" transform="translate(-120.62 -118.82)"/> </g> <g class="cls-14"> <path class="cls-5" d="M261.43,298s-13.7-5.45-15.88-1.55c-3.76,6.74,11,16.38,11,16.38s-28.23,2.6-26.23,14.36,26.78,12.59,26.78,12.59-16.52,7.15-13.9,14.93c1.87,5.56,17.94-.38,17.94-.38" transform="translate(-120.62 -118.82)"/> <path class="cls-5" d="M259.45,301.17s-6.85-3.25-8.23-1c-1.64,2.73,5.91,8.52,5.91,8.52" transform="translate(-120.62 -118.82)"/> <path class="cls-5" d="M256.48,318.08s-20.82,2.36-21.26,8.08c-.47,6,20.87,8.92,20.87,8.92" transform="translate(-120.62 -118.82)"/> <path class="cls-5" d="M257.79,343.41s-10.5,4.91-9.1,8.1C250,354.46,260,351,260,351" transform="translate(-120.62 -118.82)"/> </g> </g> </g> <circle class="cls-3" cx="207.34" cy="207.34" r="99"/> </g> ',
                '<g id="Circle6" class="rotation-6"> <g id="Layer_8" data-name="Layer 8"> <g> <circle class="cls-15" cx="206.59" cy="272.52" r="5.13"/> <circle class="cls-15" cx="192.65" cy="271" r="5.13"/> <circle class="cls-15" cx="179.37" cy="266.53" r="5.13"/> <circle class="cls-15" cx="167.35" cy="259.3" r="5.13"/> <circle class="cls-15" cx="157.17" cy="249.65" r="5.13"/> <circle class="cls-15" cx="149.3" cy="238.05" r="5.13"/> <circle class="cls-15" cx="144.11" cy="225.03" r="5.13"/> <circle class="cls-15" cx="141.85" cy="211.19" r="5.13"/> <circle class="cls-15" cx="142.61" cy="197.19" r="5.13"/> <circle class="cls-15" cx="146.36" cy="183.68" r="5.13"/> <circle class="cls-15" cx="152.92" cy="171.29" r="5.13"/> <circle class="cls-15" cx="162" cy="160.61" r="5.13"/> <circle class="cls-15" cx="173.16" cy="152.12" r="5.13"/> <circle class="cls-15" cx="185.89" cy="146.23" r="5.13"/> <circle class="cls-15" cx="199.58" cy="143.22" r="5.13"/> <circle class="cls-15" cx="213.6" cy="143.22" r="5.13"/> <circle class="cls-15" cx="227.3" cy="146.23" r="5.13"/> <circle class="cls-15" cx="240.02" cy="152.12" r="5.13"/> <circle class="cls-15" cx="251.18" cy="160.6" r="5.13"/> <circle class="cls-15" cx="260.26" cy="171.29" r="5.13"/> <circle class="cls-15" cx="266.83" cy="183.68" r="5.13"/> <circle class="cls-15" cx="270.58" cy="197.19" r="5.13"/> <circle class="cls-15" cx="271.34" cy="211.19" r="5.13"/> <circle class="cls-15" cx="269.07" cy="225.03" r="5.13"/> <circle class="cls-15" cx="263.88" cy="238.05" r="5.13"/> <circle class="cls-15" cx="256.01" cy="249.65" r="5.13"/> <circle class="cls-15" cx="245.83" cy="259.3" r="5.13"/> <circle class="cls-15" cx="233.82" cy="266.53" r="5.13"/> <circle class="cls-15" cx="220.53" cy="271" r="5.13"/> </g> </g> <circle class="cls-3" cx="207.34" cy="207.34" r="58.43"/> <circle class="cls-3" cx="207.34" cy="207.34" r="70.77"/> </g> ',
                '<g id="newt" class="rotation-newt"> <g> <path class="cls-16" d="M283.35,312.87a14.34,14.34,0,0,1,2.06-7.23,20.42,20.42,0,0,1,6.52-6.45,33.55,33.55,0,0,1,11.47-3.45,23.58,23.58,0,0,1,7.56.52" transform="translate(-120.62 -118.82)"/> <path class="cls-17" d="M276.29,317.51c7.7-5.8,20.23-15.58,32.8-21.25a37.61,37.61,0,0,1,9.44-2.68,68.8,68.8,0,0,1,7.71-.7c8.71,0,23.29.8,34.35,6.2,2.51,1.22,7.57,7.21,12.68,12.5a50.15,50.15,0,0,1,6.59,8.37c1.55,2.54,2.19,4.24,2.15,5.8-.09,3-1.88,7.56-4.53,10.91s-6.53,5.13-10.86,7.66c-12,7-28.8,10-39,8.93-7.38-.74-20.69-2-30.38-6.3-6.39-2.85-12.58-5.36-16.5-8.39-4.32-3.34-5.62-4.73-6-7.05-.24-1.36.29-3.69.66-5.49s-1.12-3.76-1-5.49A3.91,3.91,0,0,1,276.29,317.51Z" transform="translate(-120.62 -118.82)"/> <ellipse class="cls-18" cx="231.49" cy="190.72" rx="14.07" ry="12.03"/> <path class="cls-19" d="M276.34,318.16c1.91-.33,3.65,1.17,6.16,2.61,4.19,2.4,9.33,5.61,12.23,7.07,5.15,2.58,16.82,3.8,22.54,4a115.39,115.39,0,0,0,19.69-1c13.28-1.91,21-5.28,27.73-7.73,2.5-.9,7.74-2.9,10.34-2.35,1.58.33,3.37,4.37,3.47,6,.17,2.82-2.22,7.76-4.35,9.53-4.24,3.5-8.93,5.86-19.88,9a92.83,92.83,0,0,1-29,3.59c-7.23-.3-16.61-1.64-28.6-4.81s-24-8.63-22.9-13.24c.33-1.38,1.93-4.1,1.63-5.48s-1.13-3-1.06-4.84A2.48,2.48,0,0,1,276.34,318.16Z" transform="translate(-120.62 -118.82)"/> <path class="cls-20" d="M367.91,328.72a60.28,60.28,0,0,1-16.12,6.56c-10.8,2.61-24.59,3.17-31.07,2.93a114.56,114.56,0,0,1-27.05-4.6,90.52,90.52,0,0,1-17.78-8.05" transform="translate(-120.62 -118.82)"/> </g> <g id="Layer_17" data-name="Layer 17"> <path class="cls-19" d="M344.49,300.84c1.05.61-1.52,4-1.23,4.84.34,1,2.39,2.3,2.58,3.36s-1.4,2.58-1.55,3.67,2,4.33,1.12,5c-1.77,1.22-4.36-5.4-5-7.51a8.06,8.06,0,0,1,0-3.72S343,300,344.49,300.84Z" transform="translate(-120.62 -118.82)"/> <path class="cls-19" d="M357.31,304c-.62,0-2.1.61-1.89,1.68s1.34,2.06,2.25,1.8c.42-.13,1.44-1.1,1.28-1.87A2.18,2.18,0,0,0,357.31,304Z" transform="translate(-120.62 -118.82)"/> <path class="cls-19" d="M285.42,308.89c.59.24,1.31-1.37,1.6-1.94s1.23-2.25.77-2.71c-.22-.22-.93.24-1.13.47a5.87,5.87,0,0,0-1.06,1.57S284.85,308.65,285.42,308.89Z" transform="translate(-120.62 -118.82)"/> <path class="cls-19" d="M295.3,300.09c.21,0,.71.11.8.31a1.21,1.21,0,0,1-.2.93c-.15.17-.57.49-.79.43a1.08,1.08,0,0,1-.57-.68,1.14,1.14,0,0,1,.2-.65A1,1,0,0,1,295.3,300.09Z" transform="translate(-120.62 -118.82)"/> </g> </g> </svg>'
            );
    }

    /// @dev Converts a string into an integer inside the given closed interval.
    /// @param str The string to covert.
    /// @param start The first integer inside the output interval.
    /// @param end The last integer inside the output interval.
    /// @return An integer inside the given interval derived from the given string.
    function _stringToIntInInterval(
        string calldata str,
        uint256 start,
        uint256 end
    ) internal pure returns (uint256) {
        uint256 intervalLength = end - start + 1;
        return (uint256(keccak256(bytes(str))) % intervalLength) + start;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.4;

interface ISvgGenerator {
    /// @dev Generates an SVG from the given data.
    /// @param redeemed A boolean representing if the token is already redeemed or not.
    /// @param category Type or category label that represents the activity for what the time was tokenized.
    /// @return A string representing the generated SVG.
    function generateSvg(bool redeemed, string calldata category)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}