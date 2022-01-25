// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs15 is IHardwareSVGs, ICategories {
    function hardware_57() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Three Chalices',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient id="h57-a" x2="1" y1="0" y2="0"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h57-b" x2="1" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><radialGradient cx=".5" cy=".25" id="h57-c" r="1.5"><stop offset="0" stop-color="gray"/><stop offset="0.47" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><linearGradient id="h57-f" x1="0" x2="1" y1="0" y2="0"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><radialGradient cx="18.2" cy="-4" gradientUnits="userSpaceOnUse" id="h57-g" r="30"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><linearGradient id="h57-h" x1="0" x2="0" y1="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h57-i" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#696969"/><stop offset="1" stop-color="#fff"/></linearGradient><filter id="h57-k" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h57-m" viewBox="0 0 12.69 5.16"><path d="M11.7,0H.54c1.87.84,2.4,2.41.23,3.37H11.93C9.75,2.47,9.89.87,11.7,0Z" fill="url(#h57-h)"/><path d="M9.43,3.37A2.26,2.26,0,0,1,9.43,0H3A2.27,2.27,0,0,1,3,3.37Z" fill="url(#h57-i)"/><path d="M11.93,3.31H.77A.81.81,0,0,0,0,4.23a.81.81,0,0,0,.77.93H11.93s.76,0,.76-.93S11.93,3.31,11.93,3.31Z" fill="url(#h57-f)"/></symbol><symbol id="h57-o" viewBox="0 0 33.33 2.08"><path d="M32.58,0H.75L0,1l16.56.52L33.33,1Z" fill="url(#h57-a)"/><path d="M0,1l.75,1H32.58l.75-1Z" fill="url(#h57-b)"/></symbol><symbol id="h57-l" viewBox="0 0 36.42 40.13"><path d="M.82,1.56C5.94,7.12,5,11.22,11.73,16.85h13c6.69-5.63,5.79-9.73,10.91-15.29Z" fill="url(#h57-g)"/><use height="5.16" transform="translate(11.87 19.08) scale(1 1.04)" width="12.69" xlink:href="#h57-m"/><use height="5.16" transform="translate(11.87 29.4)" width="12.69" xlink:href="#h57-m"/><use height="2.08" transform="scale(1.09 1)" width="33.33" xlink:href="#h57-o"/><path d="M21.31,32.57H15.12c-2.95,2.44-2.52,5.14-2.69,6.52H24C23.83,37.71,24.25,35,21.31,32.57Z" fill="url(#h57-c)"/><path d="M23.18,39.09h7.58c-.07-3.14-3.93-6.52-7-6.52H20.87C23.4,35,23,37.71,23.18,39.09Z" fill="url(#h57-c)"/><path d="M13.25,39.09H5.67c.07-3.14,3.93-6.52,7-6.52h2.92C13,35,13.39,37.71,13.25,39.09Z" fill="url(#h57-c)"/><path d="M11.73,16.66h13v2.63h-13Z" fill="url(#h57-f)"/><use height="2.08" transform="translate(4.33 38.05) scale(0.83 1)" width="33.33" xlink:href="#h57-o"/><use height="5.16" transform="translate(11.87 24.24) scale(1 1.04)" width="12.69" xlink:href="#h57-m"/></symbol></defs><g filter="url(#h57-k)"><use height="40.13" transform="translate(66.79 82.71)" width="36.42" xlink:href="#h57-l"/><use height="40.13" transform="translate(116.79 82.71)" width="36.42" xlink:href="#h57-l"/><use height="40.13" transform="translate(91.79 142.71)" width="36.42" xlink:href="#h57-l"/></g>'
                    )
                )
            );
    }

    function hardware_58() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Three Brushes',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16386.69)" gradientUnits="userSpaceOnUse" id="h58-a" x2="27.33" y1="16385.01" y2="16385.01"><stop offset="0" stop-color="#818181"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="#818181"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16386.69)" gradientUnits="userSpaceOnUse" id="h58-f" x2="27.33" y1="16386.02" y2="16386.02"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#818181"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h58-c" x1="3.67" x2="3.67" y1="11.01"><stop offset="0" stop-color="#818181"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h58-d" x1="6.86" x2="1.22" y1="62.11" y2="62.11"><stop offset="0" stop-color="#818181"/><stop offset=".24" stop-color="#4c4c4c"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4c4c4c"/></linearGradient><linearGradient id="h58-e" x1="1.54" x2="5.8" xlink:href="#h58-a" y1="14.48" y2="14.48"/><linearGradient gradientUnits="userSpaceOnUse" id="h58-b" x1="110" x2="110" y1="130.04" y2="185.41"><stop offset="0" stop-color="#4c4b4c"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h58-i" x1="110" x2="110" xlink:href="#h58-b" y1="130.04" y2="185.41"/><linearGradient id="h58-j" x1="110" x2="110" xlink:href="#h58-b" y1="186.25" y2="129.54"/><linearGradient id="h58-k" x1="110" x2="110" xlink:href="#h58-c" y1="119.9" y2="86.8"/><linearGradient id="h58-l" x1="110" x2="110" xlink:href="#h58-b" y1="119.98" y2="86.3"/><linearGradient id="h58-m" x1="110" x2="110" xlink:href="#h58-c" y1="118.41" y2="131.41"/><linearGradient id="h58-n" x1="97.68" x2="122.33" xlink:href="#h58-a" y1="124.86" y2="124.86"/><symbol id="h58-h" viewBox="0 0 7.34 111.46"><path d="M1.67 11.01 5.69 11 7.34 0H0l1.67 11.01z" fill="url(#h58-c)"/><path d="m1.57 18.18 2.11-5.43L5.8 18.2c0 8.55 1.13 10.02 1.13 21.63s-1.47 71.65-3.22 71.64S.4 51.46.42 39.83s1.19-13.07 1.15-21.65Z" fill="url(#h58-d)"/><path d="M1.55 10.78H5.8v7.41H1.55z" fill="url(#h58-e)"/></symbol><symbol id="h58-o" viewBox="0 0 27.33 2.69"><path d="M27.33 1.34 25.98 2.7H1.34L0 1.34 13.66.67Z" fill="url(#h58-a)"/><path d="M0 1.34 1.34 0h24.64l1.35 1.34Z" fill="url(#h58-f)"/></symbol><filter id="h58-g"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h58-g)"><use height="111.46" transform="rotate(39.81 -48.64 240.53)" width="7.34" xlink:href="#h58-h"/><use height="111.46" transform="scale(-1 1) rotate(39.81 -158.64 -63.3)" width="7.34" xlink:href="#h58-h"/><path d="M121.35 130.82s-1.03-.78-11.35-.78-11.35.78-11.35.78c8.32 5.5 8.42 8.92 8.42 19.37s-7.13 21.74 2.93 35.22c10.06-13.48 2.93-24.78 2.93-35.22s.1-13.91 8.42-19.37Z" fill="url(#h58-i)" stroke="url(#h58-j)"/><path d="M126.45 86.8H93.56l5.05 33.1h22.78l5.06-33.1z" fill="url(#h58-k)"/><path d="m98.61 119.9-5.05-33.1h32.89l-5.06 33.1" fill="none" stroke="url(#h58-l)"/><path d="M97.68 118.42h24.65v12.4l-12.32.59-12.33-.59v-12.4z" fill="url(#h58-m)"/><path d="M121.33 132H98.68l-1-1.18h24.65Zm1-14.28H97.68v1.18h24.65Z" fill="url(#h58-n)"/><use height="2.69" transform="matrix(1 0 0 .744 96.34 127.48)" width="27.33" xlink:href="#h58-o"/></g>'
                    )
                )
            );
    }

    function hardware_59() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Three Writing Pens',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h59-a" x1="6.11" x2="6.11" y1="85.97" y2="104.23"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h59-b" x1="0.11" x2="10.73" y1="44.25" y2="44.25"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(-1, 0, 0, 1, 16387.58, 0)" gradientUnits="userSpaceOnUse" id="h59-c" x1="16376.35" x2="16386.58" y1="27.51" y2="27.51"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h59-d" x1="3.75" x2="8.47" xlink:href="#h59-c" y1="87.98" y2="87.98"/><linearGradient gradientTransform="translate(16420.35 16383.51) rotate(180)" id="h59-e" x1="16410.99" x2="16417.49" xlink:href="#h59-c" y1="16382.99" y2="16382.99"/><linearGradient gradientUnits="userSpaceOnUse" id="h59-f" x2="12.22" y1="27.51" y2="27.51"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><filter id="h59-g" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h59-h" viewBox="0 0 12.22 104.23"><path d="M6.9,90.12c0-.48.45-.65.86-.89v-3A5.23,5.23,0,0,0,6.11,86a5.28,5.28,0,0,0-1.65.3v3c.41.24.87.41.86.89,0,1.24-2.51,2-2.51,4.39,0,2.69,1.7,4.95,2.52,9.72H6.9c.81-4.77,2.52-7,2.52-9.72C9.42,92.09,6.9,91.36,6.9,90.12Zm-.79,7.13a1,1,0,1,1,1-1A1,1,0,0,1,6.11,97.25Z" fill="url(#h59-a)"/><path d="M12,32.62C10.49,67.11,8.47,87.46,8.47,87.46H3.75S1.74,67.11.27,32.62ZM9.36,1H2.86A109.18,109.18,0,0,0,0,22.4H12.22A108.3,108.3,0,0,0,9.36,1Z" fill="url(#h59-b)"/><path d="M11,31.62c-5.05-1.43-3.81-6.9.26-8.22H1c4.07,1.32,5.31,6.79.27,8.22Z" fill="url(#h59-c)"/><polygon fill="url(#h59-d)" points="7.76 88.5 4.46 88.5 3.75 87.46 8.47 87.46 7.76 88.5"/><polygon fill="url(#h59-e)" points="3.84 0 8.39 0 9.36 1.04 2.86 1.04 3.84 0"/><path d="M12.22,22.4l-1,1H1l-1-1ZM12,32.62l-1-1H1.27l-1,1Z" fill="url(#h59-f)"/></symbol></defs><g filter="url(#h59-g)"><use height="104.23" transform="translate(83.69 173.1) rotate(-140.19)" width="12.22" xlink:href="#h59-h"/><use height="104.23" transform="matrix(0.77, -0.64, -0.64, -0.77, 136.31, 173.1)" width="12.22" xlink:href="#h59-h"/><use height="104.23" transform="translate(103.89 80.45)" width="12.22" xlink:href="#h59-h"/></g>'
                    )
                )
            );
    }

    function hardware_60() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Lead Holder and Twin Blades',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16468.62)" gradientUnits="userSpaceOnUse" id="h60-a" x1="11.25" x2="11.25" y1="16463.22" y2="16457.82"><stop offset="0" stop-color="#404040"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h60-b" xlink:href="#h60-a" y1="16384" y2="16468.62"/><linearGradient id="h60-c" xlink:href="#h60-a" y1="16384" y2="16434.37"/><filter id="h60-d" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h60-e" x1="99.5" x2="120.5" y1="160" y2="160"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h60-f" x1="99.69" x2="117.93" y1="87" y2="87"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h60-g" x1="104.75" x2="115.25" xlink:href="#h60-e" y1="136.5" y2="136.5"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h60-h" x1="104.75" x2="115.25" xlink:href="#h60-e" y1="144.58" y2="144.58"/><linearGradient id="h60-i" x1="99.69" x2="117.93" xlink:href="#h60-f" y1="124.54" y2="124.54"/><linearGradient id="h60-j" x1="107.54" x2="111.89" xlink:href="#h60-f" y1="154.68" y2="154.68"/><linearGradient gradientUnits="userSpaceOnUse" id="h60-k" x1="120.5" x2="99.5" y1="101.5" y2="101.5"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="h60-l" viewBox="0 0 22.5 84.61"><path d="M11.25,5.4A3.6,3.6,0,0,1,14.85,9v1.8a3.6,3.6,0,1,0-7.2,0V9A3.6,3.6,0,0,1,11.25,5.4Z" fill="url(#h60-a)"/><path d="M0,84.62,22.5,41.45v-9a8,8,0,0,1-2.25-5.55V0h-18V25.32A9.81,9.81,0,0,1,.05,31.5ZM7.65,9a3.6,3.6,0,0,1,7.2,0v9a3.6,3.6,0,0,1-7.2,0Z" fill="url(#h60-b)"/><path d="M22.5,34.25,0,77.41v7.21L22.5,41.45Z" fill="url(#h60-c)"/></symbol></defs><g filter="url(#h60-d)"><path d="M126,94.2h18V93H126Z" fill="#fff"/><path d="M120.5,105h-21v-2h21Z" fill="url(#h60-e)"/><path d="M120.5,72h-21v30h21Z" fill="url(#h60-f)"/><use height="84.62" transform="translate(123.75 93)" width="22.5" xlink:href="#h60-l"/><use height="84.62" transform="matrix(-1, 0, 0, 1, 96.25, 93)" width="22.5" xlink:href="#h60-l"/><polygon fill="url(#h60-g)" points="114.25 137 105.75 137 104.75 136 115.25 136 114.25 137"/><polygon fill="url(#h60-h)" points="114.25 145.08 105.75 145.08 104.75 144.08 115.25 144.08 114.25 145.08"/><path d="M115.25,136h-10.5L99.5,105h21Zm-5.75,1v7.08h-4.75l1-7.08Zm1,0v7.08h4.75l-1-7.08Z" fill="url(#h60-i)"/><path d="M107.5,145.08V150l2,13.92a.48.48,0,0,0,.92,0l2-13.92v-4.92Z" fill="url(#h60-j)"/><polygon points="110.5 145.08 110.5 137 109.5 137 109.5 145.08 107.5 145.08 107.5 146.08 112.5 146.08 112.5 145.08 110.5 145.08"/><path d="M119.5,103h-19v-1h19Z"/><path d="M99.5,101.5h21" fill="none" stroke="url(#h60-k)"/></g>'
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