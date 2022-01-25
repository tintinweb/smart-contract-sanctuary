// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs17 is IHardwareSVGs, ICategories {
    function hardware_64() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Pickaxes',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16475.32)" gradientUnits="userSpaceOnUse" id="h64-c" x1=".1" x2="9.93" y1="16429.89" y2="16429.89"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h64-b" x1="17.14" x2="25.21" y1="27.81" y2="27.81"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16439.62)" gradientUnits="userSpaceOnUse" id="h64-a" x2="30.49" y1="16430.78" y2="16430.78"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h64-e" x1="30.49" x2="0" xlink:href="#h64-a" y1="16432.65" y2="16432.65"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 16439.62)" gradientUnits="userSpaceOnUse" id="h64-f" x1="34.38" x2="8.16" y1="16430.78" y2="16430.78"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#696969"/></linearGradient><linearGradient id="h64-g" x1="29.64" x2="29.64" xlink:href="#h64-a" y1="16426.63" y2="16434.94"/><linearGradient id="h64-i" x1="104.34" x2="115.66" xlink:href="#h64-b" y1="135.1" y2="135.1"/><linearGradient gradientUnits="userSpaceOnUse" id="h64-j" x1="85" x2="135" y1="101.86" y2="101.86"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h64-k" x1="85.45" x2="128.89" xlink:href="#h64-c" y1="101.71" y2="101.71"/><linearGradient id="h64-l" x1="110" x2="110" xlink:href="#h64-b" y1="108.61" y2="95.11"/><symbol id="h64-d" viewBox="0 0 11.31 90.85"><path d="M1.3 50V0H10v50c.38 16.93.45 23.8 1.3 40.85H0A796.05 796.05 0 0 0 1.3 50Z" fill="url(#h64-c)"/></symbol><symbol id="h64-m" viewBox="0 0 30.49 55.62"><path d="M18.52 55.62h5.3l1.39-1-4.04-1.34-4.03 1.33ZM24.27 1 20.9 2.06 18.07 1l1-1h4.4Z" fill="url(#h64-b)"/><use height="90.85" transform="matrix(.713 0 0 .59 17.14 1)" width="11.31" xlink:href="#h64-d"/><path d="M30.5 4.68v8.31l-13.82-.19A48.3 48.3 0 0 1 0 9.24a52.66 52.66 0 0 1 16.93-4.37Z" fill="url(#h64-a)"/><path d="m30.5 4.68-13.58.19A52.66 52.66 0 0 0 0 9.24l27.03-.14Z" fill="url(#h64-e)"/><path d="M28.8 6.1v5.46l-10.9-.12A44.77 44.77 0 0 1 4.72 9.1a48.4 48.4 0 0 1 13.36-2.87Z" fill="url(#h64-f)"/><path d="M28.8 11.56 30.5 13V4.68L28.8 6.1Z" fill="url(#h64-g)"/></symbol><filter id="h64-h"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h64-h)"><path d="m115.66 180.53-5.66-1.05-5.66 1.05 1.5 1h8.32Zm-1.3-90.86L110 90.7l-4.35-1.03 1.5-1h5.7Z" fill="url(#h64-i)"/><use height="90.85" transform="translate(104.34 89.67)" width="11.31" xlink:href="#h64-d"/><path d="M116.98 96.16c-1.2-.05-1.56-1.05-2.75-1.05h-8.46c-1.2 0-1.56 1-2.75 1.05a162.86 162.86 0 0 1-18.02-.6v12.3c3.26-.63 8.16-1.1 17.86-.6 1.32.06 1.57 1.35 2.88 1.35h8.51c1.32 0 1.57-1.3 2.88-1.36 9.71-.5 14.6-.02 17.87.6V95.56a162.85 162.85 0 0 1-18.02.6Z" fill="url(#h64-j)"/><path d="M116.15 97.02c-1.05-.04-1.37-.88-2.42-.88h-7.46c-1.05 0-1.37.84-2.42.88-6.3.25-18.85-1.46-18.85-1.46v12.3a97.36 97.36 0 0 1 18.71-1.42c1.16.05 1.38 1.15 2.54 1.15h7.5c1.16 0 1.38-1.1 2.54-1.15a97.36 97.36 0 0 1 18.71 1.41V95.56s-12.55 1.7-18.85 1.46Z" fill="url(#h64-k)"/><path d="m135 107.85 3.35.76V95.1l-3.35.45ZM85 95.56l-3.35-.45v13.5l3.35-.76Z" fill="url(#h64-l)"/><use height="55.62" transform="translate(66.75 116.57)" width="30.49" xlink:href="#h64-m"/><use height="55.62" transform="matrix(-1 0 0 1 153.25 116.57)" width="30.49" xlink:href="#h64-m"/></g><path d="M114.88 109.6h-9.76v-1h9.76Zm-17.64 19.96-14.32-.17v1l14.32.17Zm25.52 1 14.32-.17v-1l-14.32.17Z"/>'
                    )
                )
            );
    }

    function hardware_65() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Three Bells in Chief',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16407.3)" gradientUnits="userSpaceOnUse" id="h65-a" x1="6.75" x2="11.75" y1="16406.05" y2="16406.05"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h65-c" x1=".17" x2="16.24" y1="10.44" y2="10.44"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h65-d" x1="0" x2="18.5" xlink:href="#h65-a" y1="11.2" y2="11.2"/><radialGradient cx="5712.38" cy="10694.26" gradientTransform="matrix(3.4542 0 0 -3.4542 -19722.21 36959.4)" gradientUnits="userSpaceOnUse" id="h65-b" r="1"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset=".6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><symbol id="h65-e" viewBox="0 0 18.5 23.34"><path d="M6.75 2.5h1a1.5 1.5 0 1 1 3 0h1a2.5 2.5 0 0 0-5 0Z" fill="url(#h65-a)"/><path d="m18.44 19.63-1.93-3.39H2l-1.94 3.4.24.78h7.5a1.8 1.8 0 0 0-.37 1.1v.02a1.82 1.82 0 0 0 3.64 0v-.02a1.8 1.8 0 0 0-.37-1.1h7.5Z"/><path d="M9.25 19.33a6.25 6.25 0 0 0-1.81.25 1.82 1.82 0 0 0 3.63 0 6.26 6.26 0 0 0-1.82-.25Z" fill="url(#h65-b)"/><path d="M18.5 17.42a10.53 10.53 0 0 0-2-3.18l-1.07-1.37a5.41 5.41 0 0 1-.57-1.51l-1.3-6.01-.29-1.38-.13-.6a1.15 1.15 0 0 0-1.13-.91H6.5a1.16 1.16 0 0 0-1.13.91l-.13.6-.3 1.38-1.29 6.01a5.38 5.38 0 0 1-.57 1.5L2 14.25a10.53 10.53 0 0 0-2 3.18l9.25 1Z" fill="url(#h65-c)"/><path d="M18.2 18.42H.3l-.3-1h18.5Zm-2.77-5.55H3.07L2 14.24h14.5ZM4.93 5.35h8.64l-.3-1.38H5.23Z" fill="url(#h65-d)"/></symbol></defs><use height="23.34" transform="translate(125.75 76.66)" width="18.5" xlink:href="#h65-e"/><use height="23.34" transform="translate(100.75 76.66)" width="18.5" xlink:href="#h65-e"/><use height="23.34" transform="translate(75.75 76.9)" width="18.5" xlink:href="#h65-e"/>'
                    )
                )
            );
    }

    function hardware_66() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Three Suns in Chief',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16392.83)" gradientUnits="userSpaceOnUse" id="h66-a" x1="1.47" x2="5.86" y1="16384.25" y2="16389.17"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h66-b" x1="0.82" x2="0.82" xlink:href="#h66-a" y1="0.47" y2="8"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16408)" id="h66-c" x1="12" x2="12" xlink:href="#h66-a" y1="16406.33" y2="16383.11"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16408)" id="h66-d" x1="12" x2="12" xlink:href="#h66-a" y1="16399.1" y2="16387.64"/><filter id="h66-e" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h66-g" viewBox="0 0 7.27 10.68"><path d="M2.88,5.92,1,9.55,4.73,6l2.54-4.4Z" fill="url(#h66-a)"/><path d="M1.42,4.42C2.31,6.6,0,10.68,0,10.68L0,6.25a1.48,1.48,0,0,0,.51-.94C.51,4.27.16,4.23.16,3S2,1.68,1.27,0h0C2.53,1.43,0,2,1.42,4.42Z" fill="url(#h66-b)"/></symbol><symbol id="h66-f" viewBox="0 0 24 24"><path d="M6.39,10.22a1.51,1.51,0,0,0-.56-.91c-.9-.52-1.11-.24-2.19-.86S3.42,6.23,1.61,6h0c1.66-.54,1.84.65,2.56,1.06s1.75-.44,2.9.18a2.86,2.86,0,0,1,.47.33L6,1.61H6l4.73,4.64a1.46,1.46,0,0,0,.51-.93c0-1.05-.35-1.09-.35-2.34S12.71,1.68,12,0h0c1.3,1.17.36,1.92.36,2.75s1.26,1.3,1.3,2.6a3.77,3.77,0,0,1-.05.57L18,1.61,16.34,8a1.53,1.53,0,0,0,1.07,0c.91-.52.76-.84,1.85-1.47s2,.93,3.13-.53h0C22,7.71,20.91,7.27,20.2,7.69s-.5,1.73-1.61,2.42a2.25,2.25,0,0,1-.52.24L24,12l-6.39,1.78a1.55,1.55,0,0,0,.56.91c.9.52,1.11.24,2.19.86s.22,2.22,2,2.45h0c-1.66.54-1.84-.65-2.56-1.06s-1.75.44-2.9-.18a2.86,2.86,0,0,1-.47-.33l1.54,6h0l-4.73-4.64a1.48,1.48,0,0,0-.51.94c0,1,.35,1.08.35,2.33s-1.82,1.3-1.11,3h0c-1.3-1.17-.36-1.92-.36-2.75s-1.26-1.3-1.3-2.6a3.88,3.88,0,0,1,.05-.57L6,22.39H6L7.66,16a1.53,1.53,0,0,0-1.07,0c-.91.52-.76.84-1.84,1.47s-2-.93-3.14.53h0c.36-1.71,1.48-1.27,2.2-1.69s.49-1.73,1.6-2.42a2.25,2.25,0,0,1,.52-.24L0,12Z" fill="url(#h66-c)"/><use height="10.68" transform="translate(10.73)" width="7.27" xlink:href="#h66-g"/><use height="10.68" transform="matrix(0.5, -0.87, 0.87, 0.5, 0.97, 7.1)" width="7.27" xlink:href="#h66-g"/><use height="10.68" transform="translate(2.24 19.1) rotate(-120)" width="7.27" xlink:href="#h66-g"/><use height="10.68" transform="translate(13.27 24) rotate(180)" width="7.27" xlink:href="#h66-g"/><use height="10.68" transform="matrix(-0.5, 0.87, -0.87, -0.5, 23.03, 16.9)" width="7.27" xlink:href="#h66-g"/><use height="10.68" transform="matrix(0.5, 0.87, -0.87, 0.5, 21.76, 4.9)" width="7.27" xlink:href="#h66-g"/><path d="M10.75,7.68,7.87,4.84l1.42,5.52A4.77,4.77,0,0,0,5.52,8.08a3.56,3.56,0,0,1,2.11,2.84L3.74,12l5.49,1.53h0a4.8,4.8,0,0,0-3.87,2.12,3.61,3.61,0,0,1,3.52-.41h0l-1,3.92,4.06-4h0a4.77,4.77,0,0,0-.09,4.42,3.55,3.55,0,0,1,1.4-3.25h0l2.88,2.84-1.42-5.52h0a4.78,4.78,0,0,0,3.77,2.28,3.58,3.58,0,0,1-2.11-2.84h0L20.26,12l-5.51-1.53h0a4.78,4.78,0,0,0,3.87-2.12,3.6,3.6,0,0,1-3.52.41h0l1-3.92-4.06,4h0a4.83,4.83,0,0,0,.09-4.42,3.61,3.61,0,0,1-1.41,3.26Z" fill="url(#h66-d)"/></symbol></defs><g filter="url(#h66-e)"><use height="24" transform="translate(123 75.44)" width="24" xlink:href="#h66-f"/><use height="24" transform="translate(98 75.44)" width="24" xlink:href="#h66-f"/><use height="24" transform="translate(73 75.44)" width="24" xlink:href="#h66-f"/></g>'
                    )
                )
            );
    }

    function hardware_67() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Quatrefoil Tracery in Chief',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1, 0, 0, -1, -8146, 24463.66)" gradientUnits="userSpaceOnUse" id="h67-a" x1="8158.87" x2="8147.64" y1="24459.62" y2="24459.62"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h67-b" x1="8146" x2="8160.51" xlink:href="#h67-a" y1="24457.8" y2="24457.8"/><linearGradient gradientTransform="translate(-8156.44 24458.41) rotate(-90)" id="h67-c" x1="24456.77" x2="24445.54" xlink:href="#h67-a" y1="8161.72" y2="8161.72"/><linearGradient gradientTransform="translate(-8156.44 24458.41) rotate(-90)" id="h67-d" x1="24443.9" x2="24458.41" xlink:href="#h67-a" y1="8159.9" y2="8159.9"/><filter id="h67-e" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 148)" gradientUnits="userSpaceOnUse" id="h67-f" x1="60" x2="160" y1="74.5" y2="74.5"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h67-g" xlink:href="#h67-f" y1="48.5" y2="48.5"/><linearGradient gradientTransform="translate(220 148) rotate(180)" gradientUnits="userSpaceOnUse" id="h67-h" x1="60" x2="160" y1="73" y2="73"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h67-i" x1="60" x2="160" xlink:href="#h67-h" y1="47" y2="47"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h67-j" x1="110" x2="110" xlink:href="#h67-a" y1="100.5" y2="73.5"/><symbol id="h67-l" viewBox="0 0 9.31 14.51"><path d="M1.24,7.26c0,6.24,5.66,5.59,5.66,5.59l1.57-.59.84-1.82a3.48,3.48,0,0,1-1.67.46,3.65,3.65,0,0,1,0-7.29,3.48,3.48,0,0,1,1.67.46L8.23,2.13,6.9,1.66S1.24,1,1.24,7.26Z" fill="url(#h67-c)"/><path d="M6.9,12.85a5.64,5.64,0,0,1,0-11.19h0L6.59.45,5.24,0a7.64,7.64,0,0,0,0,14.51h0l1.48-.57.18-1.09Z" fill="url(#h67-d)"/></symbol><symbol id="h67-n" viewBox="0 0 14.51 9.31"><path d="M7.26,8.07c-6.25,0-5.6-5.66-5.6-5.66L4.07,0a3.54,3.54,0,0,0-.46,1.67,3.65,3.65,0,0,0,7.29,0A3.54,3.54,0,0,0,10.44,0l2.41,2.41S13.5,8.07,7.26,8.07Z" fill="url(#h67-a)"/><path d="M1.66,2.41a5.64,5.64,0,0,0,11.19,0h0l1.66,1.66A7.64,7.64,0,0,1,0,4.07H0L1.66,2.41Z" fill="url(#h67-b)"/></symbol><symbol id="h67-k" viewBox="0 0 25.04 25"><use height="14.51" transform="translate(0 5.24)" width="9.31" xlink:href="#h67-l"/><use height="14.51" transform="translate(25.03 19.76) rotate(180)" width="9.31" xlink:href="#h67-l"/><use height="9.31" transform="translate(19.79 9.31) rotate(180)" width="14.51" xlink:href="#h67-n"/><use height="9.31" transform="translate(5.24 15.69)" width="14.51" xlink:href="#h67-n"/></symbol></defs><g filter="url(#h67-e)"><line fill="none" stroke="url(#h67-f)" stroke-miterlimit="10" stroke-width="3" x1="160" x2="60" y1="73.5" y2="73.5"/><line fill="none" stroke="url(#h67-g)" stroke-miterlimit="10" stroke-width="3" x1="160" x2="60" y1="99.5" y2="99.5"/><line fill="none" stroke="url(#h67-h)" stroke-miterlimit="10" stroke-width="2" x1="160" x2="60" y1="75" y2="75"/><line fill="none" stroke="url(#h67-i)" stroke-miterlimit="10" stroke-width="2" x1="60" x2="160" y1="101" y2="101"/><use height="25" transform="translate(60 74.5)" width="25.03" xlink:href="#h67-k"/><use height="25" transform="translate(85 74.5)" width="25.03" xlink:href="#h67-k"/><use height="25" transform="translate(110 74.5)" width="25.03" xlink:href="#h67-k"/><use height="25" transform="translate(135 74.5)" width="25.03" xlink:href="#h67-k"/><path d="M78.1,92.6h0a5.65,5.65,0,0,1-11.2,0h0a5.65,5.65,0,0,1,0-11.2,5.65,5.65,0,0,1,11.2,0h0a5.65,5.65,0,0,1,0,11.2ZM108,87a5.66,5.66,0,0,0-4.9-5.6h0a5.65,5.65,0,0,0-11.2,0,5.65,5.65,0,0,0,0,11.2h0a5.65,5.65,0,0,0,11.2,0h0A5.66,5.66,0,0,0,108,87Zm25,0a5.66,5.66,0,0,0-4.9-5.6h0a5.65,5.65,0,0,0-11.2,0,5.65,5.65,0,0,0,0,11.2h0a5.65,5.65,0,0,0,11.2,0h0A5.66,5.66,0,0,0,133,87Zm25,0a5.66,5.66,0,0,0-4.9-5.6h0a5.65,5.65,0,0,0-11.2,0,5.65,5.65,0,0,0,0,11.2h0a5.65,5.65,0,0,0,11.2,0h0A5.66,5.66,0,0,0,158,87ZM60,74H160M60,100H160" fill="none" stroke="url(#h67-j)" stroke-miterlimit="10"/></g>'
                    )
                )
            );
    }

    function hardware_68() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Two Suns',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16394.73)" gradientUnits="userSpaceOnUse" id="h68-a" x1="10.73" x2="10.73" y1="16383.81" y2="16388.96"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16394.73)" gradientUnits="userSpaceOnUse" id="h68-b" x1="4.62" x2="20.09" y1="16391.86" y2="16385.5"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.49" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16394.73)" gradientUnits="userSpaceOnUse" id="h68-c" x1="4.04" x2="20.28" y1="16394.14" y2="16386.35"><stop offset="0" stop-color="#fff"/><stop offset="0.49" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h68-d" x1="17.71" x2="17.71" xlink:href="#h68-a" y1="9.13" y2="20.57"/><linearGradient gradientUnits="userSpaceOnUse" id="h68-e" x1="21.98" x2="30.49" y1="16.67" y2="16.67"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h68-f" x1="17.71" x2="17.71" xlink:href="#h68-e" y1="33.06" y2="2.37"/><filter id="h68-g" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h68-i" viewBox="0 0 21.47 10.73"><path d="M21.47,10.73A36.77,36.77,0,0,0,10.61,7.79h0L0,10.73H21.47Z" fill="url(#h68-a)"/><path d="M21.47,10.73c-3.26-5.8-8.51-5.36-13.71-9C6.08.77,4.29,2.58,2.88,0c.65,3.06,2.64,2.28,3.93,3S7.7,6.13,9.68,7.35a4.68,4.68,0,0,0,.93.44Z" fill="url(#h68-b)"/><path d="M8,2.28c1.49.87.91,2.14,3.2,3.46s6.91-.84,10.28,5c-1.84-3.17-3.77-5.85-7.77-7.1a2.67,2.67,0,0,1-1.91,0C10.17,2.65,10.42,2.07,8.49,1S4.85,2.61,2.88,0C3.86,3,6.31,1.32,8,2.28Z" fill="url(#h68-c)"/></symbol><symbol id="h68-h" viewBox="0 0 35.43 35.43"><path d="M9.43,20.34,0,17.72a109.07,109.07,0,0,1,17.71,0C11.7,17.72,9.43,20.34,9.43,20.34Zm17.24-.19,8.76-2.43H17.71Z" fill="url(#h68-d)"/><path d="M26,15.09l9.43,2.63a74,74,0,0,1-17.72,0C23.73,17.72,26,15.09,26,15.09Z" fill="url(#h68-e)"/><path d="M11.3,11.85,8.86,2.37a72.76,72.76,0,0,1,8.85,15.35C14.71,12.5,11.3,11.85,11.3,11.85Zm8.29-2.62,7-6.86a83,83,0,0,1-8.86,15.35C20.72,12.5,19.59,9.23,19.59,9.23Zm4.54,14.35,2.44,9.48a59.19,59.19,0,0,1-8.86-15.34C20.72,22.93,24.13,23.58,24.13,23.58ZM15.84,26.2l-7,6.86a92.44,92.44,0,0,1,8.85-15.34C14.71,22.93,15.84,26.2,15.84,26.2Z" fill="url(#h68-f)"/><use height="10.73" transform="translate(0 8.86) scale(0.83)" width="21.47" xlink:href="#h68-i"/><use height="10.73" transform="translate(16.53 -2.06) rotate(60) scale(0.83)" width="21.47" xlink:href="#h68-i"/><use height="10.73" transform="translate(34.24 6.8) rotate(120) scale(0.83)" width="21.47" xlink:href="#h68-i"/><use height="10.73" transform="translate(35.43 26.57) rotate(180) scale(0.83)" width="21.47" xlink:href="#h68-i"/><use height="10.73" transform="translate(18.9 37.49) rotate(-120) scale(0.83)" width="21.47" xlink:href="#h68-i"/><use height="10.73" transform="matrix(0.41, -0.71, 0.71, 0.41, 1.19, 28.63)" width="21.47" xlink:href="#h68-i"/></symbol></defs><g filter="url(#h68-g)"><use height="35.43" transform="translate(92.28 144.28)" width="35.43" xlink:href="#h68-h"/><use height="35.43" transform="translate(92.28 84.28)" width="35.43" xlink:href="#h68-h"/></g>'
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