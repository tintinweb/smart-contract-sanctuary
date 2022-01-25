// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs4 is IHardwareSVGs, ICategories {
    function hardware_15() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Mallet with Chisels in Saltire',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient id="h15-d" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h15-a" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h15-e" x1="1" x2="0" xlink:href="#h15-a" y1="0" y2="0"/><linearGradient id="h15-f" x1="0" x2="1" xlink:href="#h15-a" y1="0" y2="0"/><linearGradient id="h15-g" x1="0" x2="1" xlink:href="#h15-a" y1="0" y2="0"/><linearGradient id="h15-b" x1="1" x2="0" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset=".2" stop-color="#4b4b4b"/><stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h15-c" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h15-i" x1="0" x2="1" xlink:href="#h15-b" y1="0" y2="0"/><linearGradient id="h15-j" x1="0" x2="1" xlink:href="#h15-c" y1="0" y2="0"/><linearGradient id="h15-k" x1="0" x2="1" xlink:href="#h15-b" y1="0" y2="0"/><symbol id="h15-l" viewBox="0 0 91.6 8.01"><path d="m87.6 6 2 2 2-2V2l-2-2-2 2v4z" fill="url(#h15-d)"/><path d="M89.6 8H19.3l8.18-3.73L87.6 6a2 2 0 0 1 2 2Zm0-8H19.3l6.64 3.11L87.6 2a2 2 0 0 0 2-2Z" fill="url(#h15-a)"/><path d="M89.6 4a2 2 0 0 1-2 2H27.25V2H87.6a2 2 0 0 1 2 2Z" fill="url(#h15-e)"/><path d="M30.6 2v4L19.3 8.01 0 6.01v-4l19.3-2L30.6 2z" fill="url(#h15-f)"/><path d="M4.43 6.46 0 6.01v-4l4.43-.46v4.91z" fill="url(#h15-g)"/></symbol><filter id="h15-h"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h15-h)"><path d="m116.55 169.17-6.55-1.4-6.55 1.4v2l6.55.5 6.55-.5v-2z" fill="url(#h15-b)"/><path d="M104.45 172.17h11.1l1-1h-13.1l1 1z" fill="url(#h15-c)"/><path d="M104.48 143c0 8.09 1.78 21.15-1 26.2h13.1c-2.81-5-1-18.11-1-26.2 0-12.57.51-24.18.51-24.18H104s.48 11.58.48 24.18Z" fill="url(#h15-i)"/><path d="M99.76 112.28c1.64.85 3.67 3.73 4.12 6.51h12.24a10 10 0 0 1 4.33-6.51 83.25 83.25 0 0 0-20.69 0Z" fill="url(#h15-b)"/><path d="M119.95 90.09h-19.69l-1.39 1v20.19l.88 1h20.7l.89-1V91.09l-1.39-1z" fill="url(#h15-j)"/><path d="M121.29 91.09H98.87v20.19h22.47l-.05-20.19z" fill="url(#h15-k)"/><path d="m104 134.05.5 9.55a15.93 15.93 0 0 1 5.52-5.75 15.93 15.93 0 0 1 5.52 5.75l.5-9.55Z"/><use height="8.01" transform="rotate(27.6 -181.80659088 196.0494639)" width="91.6" xlink:href="#h15-l"/><path d="m120.01 132.61-2.46.99-4.26 2.29-1.21 1.73-4.21-1.12 10.47-4.79 1.67.9z"/><use height="8.01" transform="matrix(-.89 .46 .46 .89 149.86 106.54)" width="91.6" xlink:href="#h15-l"/></g>'
                    )
                )
            );
    }

    function hardware_16() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Hammer and Compass',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -.0323 0 184.17)" gradientUnits="userSpaceOnUse" id="h16-a" x1="104.92" x2="115.16" y1="177.91" y2="177.91"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h16-e" x1="104.92" x2="115.16" y1="147.28" y2="147.28"><stop offset="0" stop-color="gray"/><stop offset=".2" stop-color="#4b4b4b"/><stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h16-c" x1="110" x2="110" y1="111.15" y2="129.23"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h16-f" x1="110" x2="110" xlink:href="#h16-a" y1="134.73" y2="154.49"/><linearGradient gradientUnits="userSpaceOnUse" id="h16-b" x1="110" x2="110" y1="100.65" y2="100.66"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h16-g" xlink:href="#h16-b" y1="100.66" y2="160.67"/><linearGradient id="h16-h" x1="110.17" x2="110.17" xlink:href="#h16-b" y1="92.7" y2="109.37"/><linearGradient id="h16-i" x1="110.08" x2="110.08" xlink:href="#h16-b" y1="108.06" y2="93.88"/><linearGradient id="h16-j" xlink:href="#h16-b" y1="160.67" y2="110.68"/><linearGradient id="h16-k" xlink:href="#h16-b" y1="145.17" y2="103.79"/><linearGradient id="h16-l" x1="110" x2="110" xlink:href="#h16-c" y1="147.04" y2="159.2"/><linearGradient id="h16-m" x1="102.3" x2="117.7" xlink:href="#h16-c" y1="110.68" y2="110.68"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h16-n" xlink:href="#h16-b" y1="150.48" y2="156.16"/><filter id="h16-d"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h16-d)"><path d="m115.16 178.41-5.16-1.97-5.08 1.97 2 2h6.24l2-2z" fill="url(#h16-a)"/><path d="M104.92 116.16h10.24v62.25h-10.24z" fill="url(#h16-e)"/><path d="m104.78 148.96.14 7.59a43.43 43.43 0 0 0 10.24-.02l.13-7.59Z"/><path d="M110 153.99a43.34 43.34 0 0 1-32.08-14.23l4.88-4.33a36.75 36.75 0 0 0 54.4 0l4.88 4.33A43.34 43.34 0 0 1 110 153.99Z" fill="url(#h16-c)" stroke="url(#h16-f)" stroke-miterlimit="10"/><path d="M104.82 117.72h10.43l-.1 10.05-5.15-6.5-5.08 6.62Zm23.69 23.48-1.32 1.4 1.07.58 3.37 4.43.39.92 1.58-.78Zm-42.11 6.55 1.58.78.39-.92 3.37-4.43 1.07-.58-1.32-1.4Z"/><path d="M110 100.65v.01l.01-.01H110z" fill="url(#h16-b)"/><path d="m110 100.66-32.8 60.01 32.8-42.06h.01l32.79 42.06-32.8-60.01z" fill="url(#h16-g)"/><path d="M88.24 93.88v14.18l21.76 1.31 22.11-2.84V95.57L112.3 92.7l-24.06 1.18z" fill="url(#h16-h)"/><path d="m89.37 97.1-.04 7.62 6.3 2.55 14.37.79 20.84-2.58-.02-9.16-18.69-2.44-16.5.71-6.26 2.51z" fill="url(#h16-i)"/><path d="m142.8 160.67-10.18-15.5L110 110.68l-22.62 34.49-10.18 15.5 32.81-42.08v.02l32.79 42.06z" fill="url(#h16-j)"/><path d="m110 103.79-22.62 41.38L110 116.16l22.62 29.01L110 103.79z" fill="url(#h16-k)"/><path d="M110 117.25a6.57 6.57 0 1 0-6.58-6.57 6.57 6.57 0 0 0 6.58 6.57Z" fill="url(#h16-l)" stroke="url(#h16-m)" stroke-miterlimit="10" stroke-width="2.25"/><path d="M110 114.52a2.84 2.84 0 1 0-2.84-2.84 2.84 2.84 0 0 0 2.84 2.84Z"/><path d="M110 113.52a2.84 2.84 0 1 0-2.84-2.84 2.84 2.84 0 0 0 2.84 2.84Z" fill="url(#h16-n)"/></g>'
                    )
                )
            );
    }

    function hardware_17() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Spring Caliper',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><radialGradient cx=".5" cy=".7" id="h17-a" r="1"><stop offset="0" stop-color="gray"/><stop offset="0.55" stop-color="#fff"/><stop offset="0.64" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></radialGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16459.63)" gradientUnits="userSpaceOnUse" id="h17-b" x1="12.74" x2="12.74" y1="16381.48" y2="16448.38"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><filter id="h17-c" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h17-d" x1="126" x2="126" y1="132" y2="134"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h17-e" x1="119.68" x2="119.68" y1="135.68" y2="130.32"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h17-f" x1="119.93" x2="119.93" xlink:href="#h17-d" y1="133.68" y2="128.32"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h17-g" x1="110" x2="110" y1="170.5" y2="155.5"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h17-h" x1="110" x2="110" y1="169.5" y2="156.5"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h17-i" x1="110" x2="110" xlink:href="#h17-b" y1="168.5" y2="157.5"/><linearGradient id="h17-j" x1="110" x2="110" xlink:href="#h17-h" y1="160.38" y2="153.63"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h17-k" x1="110" x2="110" xlink:href="#h17-b" y1="159.38" y2="154.63"/><symbol id="h17-l" viewBox="0 0 25.8 75.63"><path d="M25.8,3.12l-2,19.4c-.05.55-.79,7-4.27,11.78-4,5.49-16.14,14.08-16.63,22.22C2.72,59.23,3,72.17,18.76,74.58l-.12,1C3.07,73.83-.16,62.29,0,56.39c.26-9.47,12.7-18.72,16.42-24.24a20.45,20.45,0,0,0,3.25-9.95L21,0Z" fill="url(#h17-a)"/><path d="M18.69,75.11C4.37,73.46.83,62.58,1,56.41S7.25,43.73,12.13,38.6a52.3,52.3,0,0,0,5.13-5.89,21.31,21.31,0,0,0,3.42-10.46L21.87,1l2.62,1.87-1.7,19.61c0,.06-.62,6.49-4.08,11.28a54.78,54.78,0,0,1-5.38,5.79c-5.2,5.14-11.08,11-11.44,17-.1,1.62-.46,16,16.78,18.62Z" fill="url(#h17-b)"/></symbol></defs><g filter="url(#h17-c)"><path d="M145,132H106v-2h39a1,1,0,0,1,0,2Z" fill="url(#h17-d)"/><path d="M118.2,129.25v3.5a2.68,2.68,0,0,1,3,.93v-5.36A2.67,2.67,0,0,1,118.2,129.25Z" fill="url(#h17-e)"/><path d="M118.2,129.25v3.5l-1.48-3.5Zm3,4.43h2v-5.36h-2Z" fill="url(#h17-f)"/><use height="75.63" transform="translate(83.58 103.85)" width="25.8" xlink:href="#h17-l"/><use height="75.63" transform="matrix(-1, 0, 0, 1, 136.42, 103.85)" width="25.8" xlink:href="#h17-l"/><path d="M110,107a6,6,0,1,0-6-6A6,6,0,0,0,110,107Z" fill="none" stroke="url(#h17-g)" stroke-width="3"/><path d="M110,107a6,6,0,1,0-6-6A6,6,0,0,0,110,107Z" fill="none" stroke="url(#h17-h)"/><path d="M110,106a5,5,0,1,0-5-5A5,5,0,0,0,110,106Z" fill="none" stroke="url(#h17-i)"/><path d="M110,110.38a3.38,3.38,0,1,0-3.38-3.38A3.39,3.39,0,0,0,110,110.38Z" fill="url(#h17-j)"/><path d="M110,109.38a2.38,2.38,0,1,0-2.37-2.38A2.39,2.39,0,0,0,110,109.38Z" fill="url(#h17-k)"/></g>'
                    )
                )
            );
    }

    function hardware_18() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Book',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16419.13)" gradientUnits="userSpaceOnUse" id="h18-a" x2="57.11" y1="16399.9" y2="16399.9"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16419.13)" gradientUnits="userSpaceOnUse" id="h18-b" x1="28.55" x2="28.55" y1="16365.17" y2="16416.3"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h18-c" x1="0.25" x2="56.86" y1="18.51" y2="18.51"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h18-d" x1="28.56" x2="28.56" y1="21.35" y2="32.47"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h18-e" x1="28.56" x2="28.56" xlink:href="#h18-d" y1="22.9" y2="3.98"/><linearGradient gradientUnits="userSpaceOnUse" id="h18-f" x1="7.96" x2="49.15" y1="14.96" y2="14.96"><stop offset="0" stop-color="gray"/><stop offset="0.35" stop-color="#fff"/><stop offset="0.5" stop-color="#4b4b4b"/><stop offset="0.65" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h18-g" x1="28.55" x2="28.55" xlink:href="#h18-b" y1="30.32" y2="0"/><filter id="h18-h" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h18-i" viewBox="0 0 57.11 35.13"><path d="M22.94,35.13l-.1-1.39.37-1.17H3.06V28.65H2.47a2.47,2.47,0,1,1,0-4.94h.59V12.89H2.47A2.47,2.47,0,0,1,2.47,8h.59V4.16l.77-.84H53.28l.77.84V8h.59a2.47,2.47,0,0,1,0,4.94h-.59V23.71h.59a2.47,2.47,0,0,1,0,4.94h-.59v3.92H33.9l.37,1.17-.1,1.39Z" fill="url(#h18-a)"/><path d="M54.64,23.28H53.06V11.46h1.58a2,2,0,0,0,0-3.94H53.06v-4h-49v4H2.47a2,2,0,0,0,0,3.94H4.05V23.28H2.47a2,2,0,1,0,0,3.94H4.05v3.94H23.83l-.48,2.39H33.76l-.48-2.39H53.06V27.22h1.58a2,2,0,0,0,0-3.94Z" fill="url(#h18-b)" stroke="url(#h18-c)" stroke-width="0.5"/><path d="M31.71,29.94l.48,2.39H24.91l.49-2.39H5.27l2.85-4.15,41,.16,2.69,4Z" fill="url(#h18-d)"/><path d="M8,.25,5.27,3.57V29.94l5.38-8ZM46.46,22l5.38,8V3.57L49.15.25Z" fill="url(#h18-e)"/><path d="M22.41,26H8V.25H22.41c3.48,0,5.51,1,6.15,3.17C29.23,1.27,31.25.25,34.7.25H49.15V26H34.7a6.28,6.28,0,0,0-6.14,3.72A7,7,0,0,0,22.41,26Z" fill="url(#h18-f)" stroke="url(#h18-g)" stroke-width="0.5"/></symbol></defs><g filter="url(#h18-h)"><use height="35.13" transform="translate(68.81 106.66) scale(1.44)" width="57.11" xlink:href="#h18-i"/></g>'
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