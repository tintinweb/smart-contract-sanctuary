// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs34 is IHardwareSVGs, ICategories {
    function hardware_107() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Chain Maille',
                HardwareCategories.SPECIAL,
                string(
                    abi.encodePacked(
                        '<defs><clipPath id="h107-b"><path d="M-15 15a10.578 10.578 0 0 0-6.16-3.02c1.89 5.74 7.3 9.91 13.66 9.91s11.78-4.16 13.66-9.91c-2.39.3-4.54 1.4-6.16 3.02 0 0-3.04 3.11-7.5 3.11-4.44 0-7.5-3.11-7.5-3.11Zm0-15a10.573 10.573 0 0 0-3.11 7.5c0 .45.04.9.09 1.34-1.22-.4-2.5-.63-3.84-.69-.01-.22-.03-.43-.03-.64 0-6.37 4.16-11.78 9.91-13.66-.117 2.597-1.4 4.53-3.02 6.15ZM6.86 8.14c-1.34.06-2.63.3-3.84.7.05-.44.09-.89.09-1.34C3.11 1.65-1.65-3.11-7.5-3.11c-.45 0-.9.04-1.34.09.4-1.22.63-2.5.69-3.84.22-.01.43-.03.64-.03C.43-6.89 6.89-.43 6.89 7.5c0 .22-.02.43-.03.64Z" fill="red" overflow="visible"/></clipPath></defs><filter id="h107-i"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h107-j" viewBox="-82.25 -22 164.5 44"><use height="44" overflow="visible" transform="translate(-82.25 -22)" width="44.5" xlink:href="#h107-a"/><use height="44" overflow="visible" transform="translate(-52.25 -22)" width="44.5" xlink:href="#h107-a"/><use height="44" overflow="visible" transform="translate(-22.25 -22)" width="44.5" xlink:href="#h107-a"/><use height="44" overflow="visible" transform="translate(7.75 -22)" width="44.5" xlink:href="#h107-a"/><use height="44" overflow="visible" transform="translate(37.75 -22)" width="44.5" xlink:href="#h107-a"/></symbol><symbol id="h107-a" viewBox="-22.5 -22 44.5 44"><g clip-path="url(#h107-b)"><use height="29" overflow="visible" transform="translate(-22 -7)" width="29" xlink:href="#h107-c"/><path d="M7.13 7.67S5 7.21 2.86 8.23l-.13 1.38L7.5 8.48l-.37-.81z"/><path d="M-22.13 7.67s2.13-.46 4.27.56l.13 1.38-4.77-1.13.37-.81z"/><path d="M-14.654-.113c2.21-2.21 1.334-7.067 1.334-7.067l3.54 1.33-4.874 5.737Z"/><path d="M-5.039-7.18c2.21 2.21 1.334 7.067 1.334 7.067l3.54-1.33-4.874-5.737Z" transform="rotate(180 -2.602 -3.647)"/></g><clipPath id="h107-d"><path d="M7.5 6.89c-.33 0-.64-.03-.64-.03-.06-1.34-.3-2.62-.7-3.84 0 0 .69.09 1.35.09 5.85 0 10.61-4.76 10.61-10.61S13.35-18.11 7.5-18.11-3.11-13.35-3.11-7.5c0 3.08 1.33 5.85 3.43 7.79 0 0 2.45 2.52 2.7 5.87C-2.73 4.27-6.89-1.13-6.89-7.5c0-7.93 6.45-14.39 14.39-14.39S21.89-15.43 21.89-7.5 15.43 6.89 7.5 6.89z" overflow="visible"/></clipPath><g clip-path="url(#h107-d)"><use height="29" overflow="visible" transform="translate(-7 -22)" width="29" xlink:href="#h107-c"/></g><path clip-path="url(#h107-d)" d="M15-15c2.47 2.47 6.34 1.24 6.34 1.24l.43 4.37C17.69-11.26 15.43-13.13 15-15z"/><path clip-path="url(#h107-d)" d="M0-15c-2.47 2.47-6.34 1.24-6.34 1.24l-.43 4.37C-2.69-11.26-.43-13.13 0-15z"/></symbol><symbol id="h107-c" viewBox="-14.5 -14.5 29 29"><linearGradient gradientUnits="userSpaceOnUse" id="h107-e" x1="0" x2="0" y1="-12.5" y2="12.5"><stop offset="0" stop-color="#aaa"/><stop offset=".3" stop-color="#fff"/><stop offset=".75" stop-color="#4b4b4b"/><stop offset="1" stop-color="#aaa"/></linearGradient><circle fill="none" r="11.5" stroke="url(#h107-e)" stroke-width="2"/><linearGradient gradientUnits="userSpaceOnUse" id="h107-f" x1="0" x2="0" y1="14.5" y2="-14.5"><stop offset="0" stop-color="#aaa"/><stop offset=".3" stop-color="#fff"/><stop offset=".75" stop-color="#4b4b4b"/><stop offset="1" stop-color="#aaa"/></linearGradient><circle fill="none" r="13.5" stroke="url(#h107-f)" stroke-width="2"/><linearGradient gradientUnits="userSpaceOnUse" id="h107-g" x1="-13.25" x2="13.25" y1="0" y2="0"><stop offset="0" stop-color="#aaa"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="#aaa"/></linearGradient><circle fill="none" r="12.5" stroke="url(#h107-g)" stroke-width="1.5"/></symbol><clipPath id="h107-h"><path d="M160 72v75c0 27.61-22.39 50-50 50s-50-22.39-50-50V72h100z" overflow="visible"/></clipPath><g clip-path="url(#h107-h)" filter="url(#h107-i)"><use height="44" overflow="visible" transform="matrix(1 0 0 -1 35 101.5)" width="164.5" xlink:href="#h107-j"/><use height="44" overflow="visible" transform="matrix(1 0 0 -1 35 131.5)" width="164.5" xlink:href="#h107-j"/><use height="44" overflow="visible" transform="matrix(1 0 0 -1 35 161.5)" width="164.5" xlink:href="#h107-j"/><use height="44" overflow="visible" transform="matrix(1 0 0 -1 35 191.5)" width="164.5" xlink:href="#h107-j"/><use height="44" overflow="visible" transform="matrix(1 0 0 -1 35 221.5)" width="164.5" xlink:href="#h107-j"/></g>'
                    )
                )
            );
    }

    function hardware_108() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Trypto Plate',
                HardwareCategories.SPECIAL,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 266)" gradientUnits="userSpaceOnUse" id="h108-c" x1="110" x2="110" y1="202.64" y2="28.76"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#696969"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h108-d" x1="110" x2="110" y1="76.31" y2="191.31"><stop offset="0" stop-color="gray"/><stop offset=".29" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h108-e" x1="64" x2="156" y1="77.31" y2="77.31"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#696969"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h108-a" x1="110" x2="110" y1="92.31" y2="80.31"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h108-f" x1="110" x2="110" xlink:href="#h108-a" y1="122.31" y2="110.31"/><linearGradient id="h108-g" x1="110" x2="110" xlink:href="#h108-a" y1="152.31" y2="140.31"/><linearGradient id="h108-h" x1="110" x2="110" xlink:href="#h108-a" y1="182.31" y2="170.31"/><linearGradient id="h108-i" x1="110" x2="110" xlink:href="#h108-a" y1="171.31" y2="151.31"/><linearGradient id="h108-j" x1="110" x2="110" xlink:href="#h108-a" y1="141.31" y2="121.31"/><linearGradient id="h108-k" x1="110" x2="110" xlink:href="#h108-a" y1="111.31" y2="91.31"/><filter id="h108-b"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h108-b)"><path d="m65.12 77.7-.14 67.89c0 35.41 37.35 56.29 68.02 38.58 14.23-8.22 21.88-22.43 21.88-38.86l-.14-67.74-89.62.14ZM135 92.32a9 9 0 1 1 0 18 9 9 0 0 1 0-18Zm-41 39a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-1.5-15a5 5 0 1 1 10 0 5 5 0 0 1-10 0Zm5 25a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm3.5-10a9 9 0 1 1 18 0 9 9 0 0 1-18 0Zm16.5-15a5 5 0 1 1 10 0 5 5 0 0 1-10 0Zm5 25a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm3.5-10a9 9 0 1 1 18 0 9 9 0 0 1-18 0Zm-3.5-50a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm-12.5 11a9 9 0 1 1 0 18 9 9 0 0 1 0-18Zm-12.5-11a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm-12.5 11a9 9 0 1 1 0 18 9 9 0 0 1 0-18Zm-12.5-11a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm0 30a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm-5 35a5 5 0 1 1 10 0 5 5 0 0 1-10 0Zm17.5 24a9 9 0 1 1 0-18 9 9 0 0 1 0 18Zm12.5 11a5 5 0 1 1 0-10 5 5 0 0 1 0 10Zm12.5-11a9 9 0 1 1 0-18 9 9 0 0 1 0 18Zm12.5 11a5 5 0 1 1 0-10 5 5 0 0 1 0 10Zm12.5-11a9 9 0 1 1 0-18 9 9 0 0 1 0 18Zm12.5-19a5 5 0 1 1 0-10 5 5 0 0 1 0 10Zm0-30a5 5 0 1 1 0-10 5 5 0 0 1 0 10Zm0-30a5 5 0 1 1 0-10 5 5 0 0 1 0 10Z" fill="url(#h108-c)"/><path d="M155 76.31v69a45 45 0 0 1-90 0v-69" fill="none" stroke="url(#h108-d)" stroke-width="2"/><path d="m156 76.31-2 2H66l-2-2Z" fill="url(#h108-e)"/><path d="M147.5 91.31a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Z" fill="none" stroke="url(#h108-a)"/><path d="M147.5 121.31a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Z" fill="none" stroke="url(#h108-f)"/><path d="M147.5 151.31a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Z" fill="none" stroke="url(#h108-g)"/><path d="M122.5 181.31a5 5 0 1 1 5-5 5 5 0 0 1-5 5Zm-25 0a5 5 0 1 1 5-5 5 5 0 0 1-5 5Z" fill="none" stroke="url(#h108-h)"/><path d="M135 170.31a9 9 0 1 1 9-9 9 9 0 0 1-9 9Zm-25 0a9 9 0 1 1 9-9 9 9 0 0 1-9 9Zm-25 0a9 9 0 1 1 9-9 9 9 0 0 1-9 9Z" fill="none" stroke="url(#h108-i)"/><path d="M135 140.31a9 9 0 1 1 9-9 9 9 0 0 1-9 9Zm-25 0a9 9 0 1 1 9-9 9 9 0 0 1-9 9Zm-25 0a9 9 0 1 1 9-9 9 9 0 0 1-9 9Z" fill="none" stroke="url(#h108-j)"/><path d="M135 110.31a9 9 0 1 1 9-9 9 9 0 0 1-9 9Zm-25 0a9 9 0 1 1 9-9 9 9 0 0 1-9 9Zm-25 0a9 9 0 1 1 9-9 9 9 0 0 1-9 9Z" fill="none" stroke="url(#h108-k)"/></g>'
                    )
                )
            );
    }

    function hardware_109() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Bordure Plate',
                HardwareCategories.SPECIAL,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 266)" gradientUnits="userSpaceOnUse" id="h109-b" x1="110" x2="110" y1="75.58" y2="207.19"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h109-c" x1="110" x2="110" y1="185.47" y2="85.97"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 266)" gradientUnits="userSpaceOnUse" id="h109-d" x1="75.26" x2="156.98" y1="179.53" y2="179.53"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".49" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h109-e" x1="110" x2="110" y1="198" y2="71"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".54" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 266)" gradientUnits="userSpaceOnUse" id="h109-f" x1="59" x2="161" y1="194.03" y2="194.03"><stop offset="0" stop-color="#fff"/><stop offset=".49" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><clipPath id="h109-a"><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="none"/></clipPath></defs><g clip-path="url(#h109-a)"><path d="M67.87 82.64 72 87.97h76l4.13-5.33H67.87z"/><path d="M110 196.47A49.57 49.57 0 0 1 60.5 147V72.47h99V147a49.57 49.57 0 0 1-49.5 49.5ZM72 147a38 38 0 1 0 76 0V86.47H72Z" fill="url(#h109-b)"/><path d="M72 86v61a38 38 0 1 0 76 0V86" fill="none" stroke="url(#h109-c)" stroke-miterlimit="10"/><path d="M72.5 87h75l1-1h-77Z" fill="url(#h109-d)"/><path d="M60 71v76a50 50 0 0 0 100 0V71" fill="none" stroke="url(#h109-e)" stroke-miterlimit="10" stroke-width="2"/><path d="m59 71 2 2h98l2-2Z" fill="url(#h109-f)"/></g>'
                    )
                )
            );
    }

    function hardware_110() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Inverted Pall Plate',
                HardwareCategories.SPECIAL,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h110-a" x1="110" x2="110" y1="72.75" y2="211.64"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#696969"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h110-b" x1="110" x2="110" y1="145.46" y2="185.42"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h110-c" x1="84.16" x2="84.16" xlink:href="#h110-b" y1="129.71" y2="172.25"/><linearGradient id="h110-d" x1="135.84" x2="135.84" xlink:href="#h110-b" y1="129.71" y2="172.25"/><linearGradient id="h110-e" x1="101.42" x2="101.42" xlink:href="#h110-b" y1="72" y2="130.07"/><linearGradient gradientUnits="userSpaceOnUse" id="h110-f" x1="100.92" x2="118.92" y1="72.5" y2="72.5"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h110-g" x1="118.42" x2="118.42" xlink:href="#h110-b" y1="72" y2="130.07"/><linearGradient gradientUnits="userSpaceOnUse" id="h110-h" x1="66.32" x2="153.68" y1="178.4" y2="178.4"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient></defs><path d="M110,132.89l-42.37,40.5a50.83,50.83,0,0,0,11.49,12.92L110,149.24l30.88,37.06a50.85,50.85,0,0,0,11.48-12.89Z"/><path d="M118.42,129.89V72.56h-17v57.33L66.93,171.36a49.77,49.77,0,0,0,11,13.33l32-38.45,32,38.45a50,50,0,0,0,11-13.32Z" fill="url(#h110-a)"/><path d="M110,145.46l-32.76,39.3.76.66L110,147l32,38.4.76-.66Z" fill="url(#h110-b)"/><path d="M66.85,172.25,102,130.07l-1-.36L66.32,171.33C66.49,171.64,66.67,171.94,66.85,172.25Z" fill="url(#h110-c)"/><path d="M153.68,171.32,119,129.71l-1,.36,35.14,42.18C153.33,171.94,153.51,171.63,153.68,171.32Z" fill="url(#h110-d)"/><polygon fill="url(#h110-e)" points="100.92 129.71 101.92 130.07 101.92 73 100.92 72 100.92 129.71"/><polygon fill="url(#h110-f)" points="118.92 72 100.92 72 101.92 73 117.92 73 118.92 72"/><polygon fill="url(#h110-g)" points="117.92 130.07 118.92 129.71 118.92 72 117.92 73 117.92 130.07"/><path d="M153.68,171.32A49.45,49.45,0,0,1,142,185.47l.09-1.53a49.07,49.07,0,0,0,10.36-12.56Zm-86.1.06a49.07,49.07,0,0,0,10.36,12.56l.09,1.53a49.45,49.45,0,0,1-11.71-14.15Z" fill="url(#h110-h)"/>'
                    )
                )
            );
    }

    function hardware_111() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Escarbuncle',
                HardwareCategories.SPECIAL,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient id="h111-a" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h111-d" x1="1" x2="0" xlink:href="#h111-a" y1="0" y2="0"/><linearGradient id="h111-c" x1="0" x2="0" xlink:href="#h111-a" y1="1" y2="0"/><linearGradient id="h111-f" x1="0" x2="1" xlink:href="#h111-a" y1="0" y2="0"/><linearGradient gradientUnits="userSpaceOnUse" id="h111-b" x1="0" x2="0" y1="132" y2="0"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h111-g" x1="100" x2="5" xlink:href="#h111-b" y1="0" y2="0"/><symbol id="h111-h" viewBox="0 0 46.08 99.06"><path d="M29.67 65.57a3.64 3.64 0 0 1 2.64 6.34l-6.75-.78L6.93 47.04h20.4c2.46 0 5.14 1.73 5.14 4.46 0 3.29-4.19 1.18-5.08-.94 2.14 8.8 13.96 4.58 8.36-2.63C39.77 49.8 43 44.2 46.08 42.8l-10.33-1.14c5.6-7.22-6.87-12.03-8.36-6.63.9-2.12 5.07-.22 5.08 3.06 0 2.74-2.68 4.46-5.13 4.46H6.6l19.67-23.6c1.57-1.89 4.61-2.84 6.71-1.09 2.52 2.1-.24 3.25-2.44 2.58 8.1 3.98 10.94-7.02 1.84-7.38 3.96-1.94 2.87-8.85 4.17-11.95L27.52 9c-1.88-8.4-11-6.1-9.2.36-.67-4.89 9.78.38 4.51 6.71L3.2 39.7l.86-30.42c0-2.46 1.73-5.13 4.46-5.13 3.29 0 3.18 2.18 1.06 3.08 7.14-2.5-.55-10.95-7.76-5.35L0 42.8l1.82 56.26c1.4-3.09 5-6.31 3.13-10.33 7.22 5.6 13.42-8.22 4.63-10.36 2.73.66 2.55 6.47-.73 6.48a4.63 4.63 0 0 1-4.79-4.54l-.65-29.4L22.14 72.8c2.07 2.5 2.3 6.31.28 8.16-2.43 2.21-5.17-2.94-4.21-5.03-4.26 7.5 6.43 12.85 9.37 5.71 1.88 3.5 5.85 1.52 8.97 2.84l-3.78-8.21c10.23-1.36 4.8-15.05-3.1-10.7Z"/></symbol><symbol id="h111-e" viewBox="0 0 7.27 14.24"><path d="M7.27 7.84c0 3.16-2.02 4.19-3.12 6.4L3.56 1.22 3.63 0c1 2.63 3.64 4.47 3.64 7.84Z" fill="url(#h111-a)"/><path d="M0 7.84c0 3.16 2.02 4.19 3.12 6.4l.51-11.39V0C2.64 2.63 0 4.47 0 7.84Z" fill="url(#h111-c)"/></symbol><symbol id="h111-i" viewBox="0 0 24.13 54.83"><path d="M12.07 18.55c0-3.1-2.37-7.66-7.01-7.66-3.79 0-5.59 5.9-1.29 8.06-1.52-1.24-1.45-4.77 1.6-4.77 2.73 0 4.45 2.68 4.45 5.14v30.82l2.25 4.7Z" fill="url(#h111-a)"/><path d="M5.06 11.89c4.64 0 7 4.6 7 7.68v-3.32c0-3.68-3.52-6.75-7.1-6.75-6.5 0-6.5 8.9-.66 9.76a1.93 1.93 0 0 1-.53-.31c-3.39-2.22-2.5-7.06 1.29-7.06Z" fill="url(#h111-d)"/><path d="M12.07 18.35a7.1 7.1 0 0 1 7-7.15c3.8 0 5.44 5.77 1.29 7.75 1.53-1.24 1.45-4.77-1.59-4.77-2.73 0-4.46 2.68-4.46 5.13v30.83l-2.24 4.7Z" fill="url(#h111-c)"/><path d="M19.08 11.89c-4.65 0-7.01 4.6-7.01 7.68v-3.32c0-3.68 3.52-6.75 7.1-6.75 6.5 0 6.5 8.9.66 9.76a1.93 1.93 0 0 0 .53-.31c3.39-2.22 2.5-7.06-1.28-7.06Z" fill="url(#h111-d)"/><path d="M12.07 3.03v51.8" fill="none" stroke="url(#h111-b)"/><use height="14.24" transform="matrix(-1 0 0 1.0764 15.7 0)" width="7.27" xlink:href="#h111-e"/></symbol><symbol id="h111-j" viewBox="0 0 44.29 24.13"><path d="M19.03 12.07c-3.09 0-8.68 2.36-8.68 7 0 4.7 5.85 4.68 8.06 1.29-1.24 1.53-4.77 1.45-4.77-1.59 0-2.73 2.68-4.46 5.13-4.46H41.6l2.7-2.24Z" fill="url(#h111-f)"/><path d="M19.03 12.07c-3.09 0-8.68-2.37-8.68-7.01 0-3.79 6.09-5.06 8.06-1.29-1.24-1.52-4.77-1.45-4.77 1.6 0 2.73 2.68 4.45 5.13 4.45H41.6l2.7 2.25Z" fill="url(#h111-d)"/><path d="M11.35 5.06c0 4.64 4.6 7 7.68 7h-3.32c-3.68 0-6.75-3.52-6.75-7.1 0-6.5 8.9-6.5 9.76-.66a1.93 1.93 0 0 0-.31-.53c-2.22-3.39-7.06-2.5-7.06 1.29Z" fill="url(#h111-d)"/><path d="M11.35 19.08c0-4.65 4.6-7.01 7.68-7.01h-3.32c-3.68 0-6.75 3.52-6.75 7.1 0 6.5 8.9 6.5 9.76.66a1.93 1.93 0 0 1-.31.53c-2.22 3.39-7.06 2.5-7.06-1.28Z" fill="url(#h111-a)"/><path d="M1.98 12.07h42.31" fill="none" stroke="url(#h111-g)"/><use height="14.24" transform="rotate(-90 7.85 7.85)" width="7.27" xlink:href="#h111-e"/></symbol></defs><path d="M126.8 99.7a6.44 6.44 0 0 1-.29-1.13 5.54 5.54 0 0 0 .3 1.13Z"/><use height="99.06" transform="translate(108.18 89.2)" width="46.08" xlink:href="#h111-h"/><path d="M93.2 99.7a6.44 6.44 0 0 0 .29-1.13 5.54 5.54 0 0 1-.3 1.13Z"/><use height="99.06" transform="matrix(-1 0 0 1 111.82 89.2)" width="46.08" xlink:href="#h111-h"/><use height="54.83" transform="translate(97.93 77.17)" width="24.13" xlink:href="#h111-i"/><use height="24.13" transform="translate(65.7 119.93)" width="44.29" xlink:href="#h111-j"/><use height="24.13" transform="matrix(-1 0 0 1 154.3 119.93)" width="44.29" xlink:href="#h111-j"/><use height="54.83" transform="rotate(-39.81 167.6 -41.83)" width="24.13" xlink:href="#h111-i"/><use height="54.83" transform="scale(-1 1) rotate(-39.81 57.6 261.99)" width="24.13" xlink:href="#h111-i"/><use height="54.83" transform="scale(1 -1) rotate(39.81 319.04 96.65)" width="24.13" xlink:href="#h111-i"/><use height="54.83" transform="rotate(-140.19 75 75.69)" width="24.13" xlink:href="#h111-i"/><use height="54.83" transform="matrix(1 0 0 -1 97.93 186.83)" width="24.13" xlink:href="#h111-i"/>'
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