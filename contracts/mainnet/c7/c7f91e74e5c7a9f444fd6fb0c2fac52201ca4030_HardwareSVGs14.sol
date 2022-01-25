// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs14 is IHardwareSVGs, ICategories {
    function hardware_52() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Anchor',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h52-a" x1="8.13" x2="8.13" y2="16.27"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h52-b" x1="13.76" x2="13.76" xlink:href="#h52-a" y1="19.99" y2="0.63"/><linearGradient id="h52-c" x1="8.52" x2="8.52" xlink:href="#h52-a" y1="7.54" y2="18.97"/><linearGradient id="h52-d" x1="23.91" x2="23.91" xlink:href="#h52-a" y1="66.7" y2="4.85"/><linearGradient id="h52-e" x1="24.98" x2="24.98" xlink:href="#h52-a" y1="4.85" y2="54.63"/><linearGradient id="h52-f" x1="7" x2="7" xlink:href="#h52-a" y1="14" y2="0"/><linearGradient id="h52-g" x1="7" x2="7" xlink:href="#h52-a" y1="1.25" y2="12.75"/><linearGradient id="h52-h" x1="31.55" x2="0" xlink:href="#h52-a" y1="6.91" y2="6.91"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16333.21)" id="h52-i" x1="0" x2="31.55" xlink:href="#h52-a" y1="16330.91" y2="16330.91"/><filter id="h52-j" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient id="h52-k" x1="110" x2="110" xlink:href="#h52-a" y1="103.71" y2="100.29"/><linearGradient id="h52-l" x1="105.63" x2="110" xlink:href="#h52-a" y1="92.39" y2="92.39"/><linearGradient gradientTransform="matrix(-1, 0, 0, 1, 220, 0)" id="h52-m" x1="110" x2="105.63" xlink:href="#h52-a" y1="92.39" y2="92.39"/><linearGradient id="h52-n" x1="107.82" x2="107.82" xlink:href="#h52-a" y1="102" y2="96"/><linearGradient gradientTransform="matrix(-1, 0, 0, 1, 220, 0)" id="h52-o" x1="107.82" x2="107.82" xlink:href="#h52-a" y1="96" y2="102"/><linearGradient id="h52-p" x1="107.82" x2="107.82" xlink:href="#h52-a" y1="166.88" y2="102"/><linearGradient gradientTransform="matrix(-1, 0, 0, 1, 220, 0)" id="h52-q" x1="107.82" x2="107.82" xlink:href="#h52-a" y1="102" y2="166.88"/><linearGradient gradientUnits="userSpaceOnUse" id="h52-r" x1="110" x2="110" y1="179.76" y2="96"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><symbol id="h52-s" viewBox="0 0 31.55 9.21"><polygon fill="url(#h52-h)" points="31.55 4.6 1 4.6 0 6.32 27.18 9.21 31.55 4.6"/><polygon fill="url(#h52-i)" points="31.55 4.6 1 4.6 0 2.89 27.18 0 31.55 4.6"/></symbol><symbol id="h52-t" viewBox="0 0 14 14"><circle cx="7" cy="7" fill="none" r="6" stroke="url(#h52-f)" stroke-width="2"/><circle cx="7" cy="7" fill="none" r="5" stroke="url(#h52-g)" stroke-width="1.5"/></symbol><symbol id="h52-u" viewBox="0 0 42.45 66.7"><path d="M0,16.27a57.92,57.92,0,0,1,10.49-5.61L16.25,0A55.3,55.3,0,0,0,0,16.27Z" fill="url(#h52-a)"/><path d="M10.49,10.66S13.76,13,17,20V.63C14.93,1.35,10.63,9.59,10.49,10.66Z" fill="url(#h52-b)"/><path d="M17,20C15.25,10.3,12.21,6.81,12.21,6.81S6.11,9.28,0,16.27a57.93,57.93,0,0,1,10.49-5.61A31.68,31.68,0,0,1,17,20Z" fill="url(#h52-c)"/><path d="M13.6,4.85c-5.32,5.8-8.23,12.4-8.23,23.76s6.74,17,14,20.94S40.5,56.29,40.5,58.83v5.61l1,2.26H42l.42-12.07s-3.54-5.19-23.84-13.49C-1.4,33,13.6,4.85,13.6,4.85Z" fill="url(#h52-d)"/><path d="M37.66,45C16.45,42.94,3.23,27.88,13.6,4.85c-10.21,13.25-6.89,31.78,5,38.38s20.3,6.9,23.84,11.4C41.63,49.34,37.66,45,37.66,45Z" fill="url(#h52-e)"/></symbol></defs><g filter="url(#h52-j)"><polygon fill="url(#h52-k)" points="141.55 100.29 78.45 100.29 77.96 100.78 77.96 103.22 78.45 103.71 141.55 103.71 142.04 103.22 142.04 100.78 141.55 100.29"/><use height="9.21" transform="matrix(-1, 0, 0, 1, 141.55, 97.4)" width="31.55" xlink:href="#h52-s"/><use height="14" transform="translate(103 171.25)" width="14" xlink:href="#h52-t"/><use height="66.7" transform="translate(67.97 113.05)" width="42.45" xlink:href="#h52-u"/><use height="66.7" transform="matrix(-1, 0, 0, 1, 152.03, 113.05)" width="42.45" xlink:href="#h52-u"/><use height="9.21" transform="translate(78.45 97.4)" width="31.55" xlink:href="#h52-s"/><use height="14" transform="translate(103 78.75)" width="14" xlink:href="#h52-t"/><path d="M109,89.78v4.6a.62.62,0,0,1-.62.62h-1.75l-1,1H110V88.78Z" fill="url(#h52-l)"/><path d="M111,89.78v4.6a.62.62,0,0,0,.62.62h1.75l1,1H110V88.78Z" fill="url(#h52-m)"/><polygon fill="url(#h52-n)" points="110 96 105.63 96 105.63 97.4 110 102 110 96"/><polygon fill="url(#h52-o)" points="110 96 114.37 96 114.37 97.4 110 102 110 96"/><polygon fill="url(#h52-p)" points="105.63 106.6 105.63 158.08 110 166.88 110 102 105.63 106.6"/><polygon fill="url(#h52-q)" points="114.37 106.6 114.37 158.08 110 166.88 110 102 114.37 106.6"/><path d="M140.84,102H79.16m5.45,11.37c-14.18,17.32-9.93,36.32,2,42.92s19.89,6.09,23.42,10.59c3.53-4.5,11.53-4,23.42-10.59s16.15-25.6,2-42.92M110,96v6m0,0v77.76" fill="none" stroke="url(#h52-r)"/></g>'
                    )
                )
            );
    }

    function hardware_53() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Bells',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><radialGradient cx="9.25" cy="21.9" gradientUnits="userSpaceOnUse" id="h53-a" r="3.52"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><linearGradient gradientUnits="userSpaceOnUse" id="h53-b" x1="0.17" x2="16.24" y1="11.48" y2="11.48"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h53-c" x2="18.5" y1="12.32" y2="12.32"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16409.54)" id="h53-d" x1="6.75" x2="11.75" xlink:href="#h53-c" y1="16407.21" y2="16407.21"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16409.54)" gradientUnits="userSpaceOnUse" id="h53-e" x1="9.25" x2="9.25" y1="16409.39" y2="16406.47"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#696969"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16386.57)" gradientUnits="userSpaceOnUse" id="h53-f" x1="1.04" x2="1.04" y1="16384.62" y2="16386.89"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h53-g" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h53-h" x1="110" x2="110" y1="176.1" y2="151.54"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h53-i" x1="110" x2="110" xlink:href="#h53-h" y1="152.54" y2="175.1"/><linearGradient id="h53-j" x1="110" x2="110" xlink:href="#h53-h" y1="151.54" y2="156.77"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h53-k" x1="110" x2="110" xlink:href="#h53-e" y1="168.34" y2="150.38"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h53-l" x1="110" x2="110" xlink:href="#h53-e" y1="120.67" y2="85.86"/><radialGradient cx="0" cy="264.22" gradientTransform="matrix(-9.97, 0, 0, 9.97, 110, -2469.94)" id="h53-m" r="0.97" xlink:href="#h53-a"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h53-n" x1="82.74" x2="130.97" xlink:href="#h53-b" y1="124.94" y2="124.94"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h53-o" x1="110" x2="110" xlink:href="#h53-h" y1="112.46" y2="102"/><radialGradient cx="110.04" cy="101.08" id="h53-p" r="23.2" xlink:href="#h53-a"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h53-q" x1="148.4" x2="86.05" xlink:href="#h53-e" y1="108.25" y2="99.01"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h53-r" x1="98.31" x2="121.69" y1="141.28" y2="141.28"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h53-s" x1="90.17" x2="129.83" xlink:href="#h53-r" y1="114.6" y2="114.6"/><linearGradient id="h53-t" x1="91.45" x2="128.55" xlink:href="#h53-c" y1="134.5" y2="134.5"/><linearGradient gradientUnits="userSpaceOnUse" id="h53-u" x1="88.23" x2="131.77" y1="137.63" y2="137.63"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h53-v" x1="92.94" x2="127.06" xlink:href="#h53-c" y1="92.28" y2="92.28"/><symbol id="h53-w" viewBox="0 0 18.5 22.46"><path d="M11.07,20.65c0-1-1.82-1-1.82-1s-1.81,0-1.81,1a1.82,1.82,0,0,0,3.63,0Z" fill="url(#h53-a)"/><path d="M11.07,20.7a6.61,6.61,0,0,0-1.82-.25,6.48,6.48,0,0,0-1.81.25,1.71,1.71,0,0,1,1.81-1.87A1.72,1.72,0,0,1,11.07,20.7Z"/><path d="M18.5,18.54a10.59,10.59,0,0,0-2-3.18L15.43,14a5.73,5.73,0,0,1-.57-1.51l-1.29-6-.3-1.38-.13-.6A1.15,1.15,0,0,0,12,3.58H6.49a1.15,1.15,0,0,0-1.13.91l-.13.6-.3,1.38-1.29,6A5.41,5.41,0,0,1,3.07,14L2,15.36a10.47,10.47,0,0,0-2,3.18l9.25.85Z" fill="url(#h53-b)"/><path d="M18.2,19.54H.3l-.3-1H18.5ZM15.43,14H3.07L2,15.36H16.51ZM4.93,6.47h8.64l-.3-1.38h-8Z" fill="url(#h53-c)"/><path d="M6.75,3.58h1a1.5,1.5,0,0,1,3,0h1a2.5,2.5,0,0,0-5,0Z" fill="url(#h53-d)"/><path d="M8.75,0V2.17a.5.5,0,0,0,1,0V0Z" fill="url(#h53-e)"/></symbol><symbol id="h53-y" viewBox="0 0 2.07 2.57"><path d="M1,2.57a1,1,0,1,0-1-1A1,1,0,0,0,1,2.57Z"/><path d="M1,2.07a1,1,0,0,0,1-1,1,1,0,1,0-1,1Z" fill="url(#h53-f)"/></symbol></defs><g filter="url(#h53-g)"><path d="M135,102c-8.2,0-15-14.1-25-14.1S93.2,102,85,102H78.33v10.46H97.09s3.26-4.23,12.91-4.23,12.91,4.23,12.91,4.23h18.76V102Z" fill="url(#h53-h)"/><path d="M117,109.22l-2.12,2.3A2.93,2.93,0,0,0,113,110,3.15,3.15,0,0,1,117,109.22Zm-14.06,0,2.12,2.3A2.93,2.93,0,0,1,107,110,3.15,3.15,0,0,0,103,109.22Z"/><path d="M123.35,111.46c-1.11-1.12-4.95-4.23-13.35-4.23s-12.24,3.11-13.35,4.23H79.33V103H85c4.28,0,8-3.29,11.91-6.78S105.14,88.9,110,88.9s9,3.72,13.09,7.32S130.72,103,135,103h5.67v8.46Z" fill="url(#h53-i)"/><path d="M96.65,111.46l.44,1s3.26-4.23,12.91-4.23,12.91,4.23,12.91,4.23l.44-1c-1.11-1.12-4.95-4.23-13.35-4.23S97.76,110.34,96.65,111.46Z" fill="url(#h53-j)"/><path d="M127.06,97.34l-3.54-3.27-10.34,11.21h0V87.16h-6.28v18.11h0L96.48,94.07l-3.54,3.27L105.49,111a6.65,6.65,0,0,1,.61.79,4.8,4.8,0,0,0,7.8,0,6.65,6.65,0,0,1,.61-.79Z" fill="url(#h53-k)"/><path d="M110,112.74c-1.52,0-2.35-.87-3.66-2.35l-12-13,2.07-1.92,9.48,10.28c.88.95,2,.62,2-.46V88.16H110m0,24.58c1.52,0,2.35-.87,3.66-2.35l12-13-2.07-1.92-9.48,10.28c-.88.95-1.95.62-1.95-.46V88.16H110" fill="url(#h53-l)"/><path d="M107,110s-.29,2.51,3,2.51,3-2.51,3-2.51l3.32-1s-2.3,4.8-6.36,4.8-6.36-4.8-6.36-4.8"/><path d="M110,170.57a5.46,5.46,0,0,0,5.46-5.47s-2.44-3.6-5.46-3.6-5.46,3.6-5.46,3.6A5.46,5.46,0,0,0,110,170.57Z" fill="url(#h53-m)"/><path d="M110,164.28a16.09,16.09,0,0,1,5.46.88v-.06c0-3-1.71-5.46-5.46-5.46s-5.46,2.44-5.46,5.46v.06A16.09,16.09,0,0,1,110,164.28Z"/><path d="M137.7,160.77a31,31,0,0,0-5.93-9.3l-1.94-1-1.51-2.13.23-1a16.18,16.18,0,0,1-1.72-4.52l-3.88-18-1.26-1-.37-2.14.74-1-.39-1.8a3.46,3.46,0,0,0-3.38-2.74H101.71a3.46,3.46,0,0,0-3.38,2.74l-.39,1.8.74,1-.37,2.14-1.26,1-3.88,18a16.18,16.18,0,0,1-1.72,4.52l.23,1-1.51,2.13-1.94,1a31,31,0,0,0-5.93,9.3.91.91,0,0,0,.85,1.23h53.7A.91.91,0,0,0,137.7,160.77Z" fill="url(#h53-n)"/><path d="M141.67,112.46l-1-1V103l1-1Zm-63.34,0,1-1V103l-1-1Z" fill="url(#h53-o)"/><path d="M102.35,116.11a4.91,4.91,0,0,1-1.29-3.08c0-4.43,4.24-5.22,5.9-3.08-2.15.56-3.15,3.52-1.17,6.16Zm15.3,0a4.91,4.91,0,0,0,1.29-3.08c0-4.43-4.24-5.22-5.9-3.08,2.15.56,3.15,3.52,1.17,6.16ZM110,108.23c-3,0-2.09,6.56-1.76,7.88h3.52C112.09,114.79,113,108.23,110,108.23Z" fill="url(#h53-p)"/><path d="M137.75,161H82.25a.9.9,0,0,0,.9,1h53.7A.9.9,0,0,0,137.75,161Z" fill="url(#h53-q)"/><path d="M98.31,123.79h23.38l-.37-2.14H98.68Z" fill="url(#h53-r)"/><path d="M128.32,148.34H91.68l-1.51,2.13h39.66Z" fill="url(#h53-s)"/><path d="M128.55,147.34l-.23,1H91.68l-.23-1ZM97.94,120.65l.74,1h22.64l.74-1Z" fill="url(#h53-t)"/><path d="M129.83,150.47l1.94,1H88.23l1.94-1ZM98.31,123.79l-1.26,1H123l-1.26-1Z" fill="url(#h53-u)"/><use height="22.46" transform="translate(75.75 112.46)" width="18.5" xlink:href="#h53-w"/><use height="22.46" transform="translate(125.75 112.46)" width="18.5" xlink:href="#h53-w"/><use height="2.57" transform="translate(101.31 102.45)" width="2.07" xlink:href="#h53-y"/><use height="2.57" transform="translate(108.96 102.45)" width="2.07" xlink:href="#h53-y"/><use height="2.57" transform="translate(108.96 96.45)" width="2.07" xlink:href="#h53-y"/><use height="2.57" transform="translate(120.63 98.45)" width="2.07" xlink:href="#h53-y"/><use height="2.57" transform="matrix(-1, 0, 0, 1, 99.37, 98.45)" width="2.07" xlink:href="#h53-y"/><use height="2.57" transform="translate(108.96 90.45)" width="2.07" xlink:href="#h53-y"/><use height="2.57" transform="translate(116.62 102.45)" width="2.07" xlink:href="#h53-y"/><path d="M127.06,97.34l-1.41.06-2.07-1.92,0-1.14v-.27Zm-34.12,0,1.41.06,2.07-1.92,0-1.14v-.27m10.38-6.91,1,1h4.28l1-1Z" fill="url(#h53-v)"/></g>'
                    )
                )
            );
    }

    function hardware_54() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Stack',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h54-a" x1="1.45" x2="27.61" y1="11.15" y2="11.15"><stop offset="0.01" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h54-b" x1="28.18" x2="1.6" y1="7.61" y2="7.61"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16417.96)" gradientUnits="userSpaceOnUse" id="h54-c" x1="27.31" x2="27.31" y1="16397.39" y2="16417.96"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><symbol id="h54-e" viewBox="0 0 28.31 22.3"><path d="M0,8.12,1,22.3c17.49,0,27.31-4.58,27.31-11.06V0C28.31,6.48,7.87,8.12,0,8.12Z" fill="url(#h54-a)"/></symbol><symbol id="h54-g" viewBox="0 0 28.32 15.23"><path d="M26.45,0H0L1,15.23c17.49,0,27.31-4.58,27.31-11.06A6,6,0,0,0,26.45,0Z" fill="url(#h54-b)"/></symbol><symbol id="h54-d" viewBox="0 0 54.63 35.84"><path d="M27.31,35.84c14.6,0,26.43-4.68,26.43-10.45S41.91,14.94,27.31,14.94.89,19.62.89,25.39,12.72,35.84,27.31,35.84Z"/><use height="22.3" transform="translate(26.31 11.66)" width="28.31" xlink:href="#h54-e"/><use height="22.3" transform="matrix(-1, 0, 0, 1, 28.31, 11.66)" width="28.31" xlink:href="#h54-e"/><use height="15.23" transform="translate(26.31 7.49)" width="28.31" xlink:href="#h54-g"/><use height="15.23" transform="matrix(-1, 0, 0, 1, 28.31, 7.49)" width="28.31" xlink:href="#h54-g"/><path d="M27.31,20.57c14.61,0,26.45-4.6,26.45-10.28S41.92,0,27.31,0,.87,4.6.87,10.29,12.71,20.57,27.31,20.57Z" fill="url(#h54-c)"/></symbol></defs><path d="M136.43,156.33c0,7.39-11.85,13.38-26.45,13.38s-26.45-6-26.45-13.38S136.43,148.94,136.43,156.33Z"/><use height="35.84" transform="translate(82.67 130.21)" width="54.63" xlink:href="#h54-d"/><use height="35.84" transform="translate(82.67 112.74)" width="54.63" xlink:href="#h54-d"/><use height="35.84" transform="translate(82.67 95.27)" width="54.63" xlink:href="#h54-d"/>'
                    )
                )
            );
    }

    function hardware_55() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Orb',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><filter id="h55-a" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><radialGradient cx=".5" cy=".1" id="h55-b" r="1.1"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.55" stop-color="#4b4b4b"/><stop offset="0.9" stop-color="#fff"/></radialGradient><linearGradient id="h55-c" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="#fff"/><stop offset="0.21" stop-color="#4b4b4b"/><stop offset="0.85" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient></defs><g filter="url(#h55-a)"><circle cx="110" cy="145" fill="url(#h55-b)" r="36.55" stroke="url(#h55-c)"/></g>'
                    )
                )
            );
    }

    function hardware_56() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Command in Canton',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><filter id="h56-a" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientUnits="userSpaceOnUse" id="h56-b" x1="85" x2="85" y1="100" y2="86"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h56-c" xlink:href="#h56-b" y1="118" y2="104"/><linearGradient id="h56-d" xlink:href="#h56-b" y1="89" y2="97"/><linearGradient id="h56-e" xlink:href="#h56-b" y1="108" y2="96"/><linearGradient id="h56-f" xlink:href="#h56-b" y1="107" y2="115"/><linearGradient id="h56-g" xlink:href="#h56-b" y1="99" y2="105"/><linearGradient id="h56-h" xlink:href="#h56-b" y1="117.05" y2="86.95"/></defs><g filter="url(#h56-a)"><path d="M82.5,93v6.5H76A6.5,6.5,0,1,1,82.5,93Zm18,0a6.5,6.5,0,0,0-13,0v6.5H94A6.51,6.51,0,0,0,100.5,93Z" fill="none" stroke="url(#h56-b)" stroke-miterlimit="10"/><path d="M76,104.5h6.5V111a6.5,6.5,0,1,1-6.5-6.5Zm18,0H87.5V111a6.5,6.5,0,1,0,6.5-6.5Z" fill="none" stroke="url(#h56-c)" stroke-miterlimit="10"/><path d="M79.5,93v3.5H76A3.5,3.5,0,1,1,79.5,93Zm18,0a3.5,3.5,0,0,0-7,0v3.5H94A3.5,3.5,0,0,0,97.5,93Z" fill="none" stroke="url(#h56-d)" stroke-miterlimit="10"/><path d="M89,96.5H81m-1.5,11h11" fill="none" stroke="url(#h56-e)" stroke-miterlimit="10"/><path d="M76,107.5h3.5V111a3.5,3.5,0,1,1-3.5-3.5Zm18,0H90.5V111a3.5,3.5,0,1,0,3.5-3.5Z" fill="none" stroke="url(#h56-f)" stroke-miterlimit="10"/><path d="M87.5,99.5v5h-5v-5Zm3,5.5V99m-11,0v6" fill="none" stroke="url(#h56-g)" stroke-miterlimit="10"/><path d="M94,106a5,5,0,1,1-5,5V93a5,5,0,1,1,5,5H76a5,5,0,1,1,5-5v18a5,5,0,1,1-5-5Z" fill="none" stroke="url(#h56-h)" stroke-miterlimit="10" stroke-width="2.1"/></g>'
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