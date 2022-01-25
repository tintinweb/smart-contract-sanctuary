// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IHardwareSVGs.sol';
import '../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs1 is IHardwareSVGs, ICategories {
    function hardware_0() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Bushing Hammer',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h0-a" x1="23.65" x2="4.03" y1="10" y2="10"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h0-b" x1="11.25" x2="11.25" y1="0.98" y2="22.2"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h0-c" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h0-d" x1="101.34" x2="116.66" y1="127.98" y2="127.98"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h0-e" x1="110" x2="110" xlink:href="#h0-b" y1="82.1" y2="130.35"/><linearGradient id="h0-f" x1="110" x2="110" xlink:href="#h0-b" y1="94.39" y2="115.71"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h0-g" x1="100" x2="120" y1="171.5" y2="171.5"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h0-h" x1="114.95" x2="105.64" xlink:href="#h0-b" y1="174.69" y2="174.69"/><symbol id="h0-i" viewBox="0 0 22.51 20"><path d="M1,20l20-2.61V2.62L1,0Z" fill="url(#h0-a)"/><path d="M22.51,5.93,21,6.31V4.46l1.51.38Zm0,.75L21,6.31V8.15l1.51-.37Zm0,3.7L21,10v1.85l1.51-.38Zm0-1.85L21,8.15V10l1.51-.38Zm0,3.69L21,11.85v1.84l1.51-.37Zm0,3.69L21,15.54v1.11L.63,19,1,20l20-2.61L22.51,17Zm0-1.84L21,13.69v1.85l1.51-.38ZM21,2.62,1,0H0L1,1,21,3.62v.84l1.51-.37V3Z" fill="url(#h0-b)"/></symbol></defs><g filter="url(#h0-c)"><path d="M118.82,172.21c0-5.62-3.15-5.27-3.15-14.41s1.1-17.06,1.1-25-2.22-9.09-2.22-42.89h-9.09c0,33.8-2.23,35-2.23,42.89s1.1,15.82,1.1,25-3.15,8.79-3.15,14.41,2.27,9.88,8.82,9.88S118.82,177.84,118.82,172.21Z" fill="url(#h0-d)"/><path d="M114.45,170.7c0-4.12-1.59-3.86-1.59-10.55s.55-12.47.55-18.26-6.82-5.78-6.82,0,.55,11.58.55,18.26-1.58,6.43-1.58,10.55,1.14,7.23,4.44,7.23S114.45,174.81,114.45,170.7Z" fill="url(#h0-e)"/><path d="M120,92H100v20h20Z" fill="url(#h0-f)"/><use height="20" transform="translate(119 92)" width="22.51" xlink:href="#h0-i"/><use height="20" transform="matrix(-1, 0, 0, 1, 101, 92)" width="22.51" xlink:href="#h0-i"/><path d="M100,93l1-1h18l1,1Z" fill="url(#h0-g)"/><path d="M113.55,88.68h-7.09l-1,1.27h9.09Z" fill="url(#h0-h)"/></g>'
                    )
                )
            );
    }

    function hardware_1() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Shovel',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<filter id="h1-a"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><g filter="url(#h1-a)"><linearGradient gradientUnits="userSpaceOnUse" id="h1-b" x1="110" x2="110" y1="148" y2="177"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h1-c" x1="110" x2="110" y1="177.5" y2="147.5"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><path d="M100 148h20v29h-20z" fill="url(#h1-b)" stroke="url(#h1-c)"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h1-d" x1="110" x2="110" y1="116.16" y2="180.92"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h1-e" x1="110" x2="110" y1="89.3" y2="151.32"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><path d="M110 150.82c-.57 0-1.36-1.16-1.36-3.75v-41.2c0-1.1-.58-2.13-1.53-2.7l-.98-.59a6.34 6.34 0 0 1-3.06-5.41V89.8h13.85v7.37c0 2.2-1.17 4.27-3.06 5.41l-.97.59a3.18 3.18 0 0 0-1.53 2.7v41.2c0 2.59-.8 3.75-1.36 3.75zm-5.17-54.13a5.18 5.18 0 0 0 10.34 0v-4.72h-10.34v4.72z" fill="url(#h1-d)" stroke="url(#h1-e)"/><linearGradient gradientUnits="userSpaceOnUse" id="h1-f" x1="110" x2="110" y1="91.47" y2="102.36"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><path d="M104.83 96.69a5.18 5.18 0 0 0 10.34 0v-4.72h-10.34v4.72z" fill="none" stroke="url(#h1-f)"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h1-g" x1="110" x2="110" y1="171.07" y2="174.4"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><path d="M117.26 89.14h-14.51v3.83h14.51v-3.83z" fill="url(#h1-g)"/><linearGradient gradientUnits="userSpaceOnUse" id="h1-h" x1="110" x2="110" y1="89.32" y2="93.39"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><path d="m102.08 89.8.67-.67v3.83l-.67-.67V89.8zm15.84 0-.67-.67v3.83l.67-.67V89.8z" fill="url(#h1-h)"/><linearGradient gradientUnits="userSpaceOnUse" id="h1-i" x1="99.69" x2="117.93" y1="149.24" y2="149.24"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><path d="M99.5 147v4.48c1.07-1.65 3.4-2.65 5.37-2.65h10.26c1.97 0 3.8 1 5.37 2.65V147h-21z" fill="url(#h1-i)"/><linearGradient gradientUnits="userSpaceOnUse" id="h1-j" x1="108.17" x2="111.41" y1="155.22" y2="155.22"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><path d="M111.86 142.31h-3.72V147s.27 10.6 1.86 21.12v.01-.01a195.07 195.07 0 0 0 1.86-21.12v-4.69z" fill="url(#h1-j)"/></g>'
                    )
                )
            );
    }

    function hardware_2() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Screw',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16390.62)" gradientUnits="userSpaceOnUse" id="h2-b" x2="20.62" y1="16387.31" y2="16387.31"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h2-a" x1="128.58" x2="91.42" y1="169.89" y2="169.89"><stop offset="0" stop-color="gray"/><stop offset=".2" stop-color="#4b4b4b"/><stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h2-e" x1="91.42" x2="128.58" xlink:href="#h2-a" y1="164.55" y2="164.55"/><linearGradient id="h2-f" x1="117.09" x2="102.92" xlink:href="#h2-a" y1="131.65" y2="131.65"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h2-g" x1="102.92" x2="117.08" y1="99.08" y2="99.08"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="h2-c" viewBox="0 0 20.62 6.62"><path d="M0 1.87c3.23 1.87 17.39 2.88 20.62 4.75l-3.23-1.87L3.23 0Z" fill="url(#h2-b)"/></symbol><symbol id="h2-h" viewBox="0 0 20.62 8.49"><use height="6.62" width="20.62" xlink:href="#h2-c"/><use height="6.62" transform="rotate(180 10.3 4.25)" width="20.62" xlink:href="#h2-c"/></symbol><filter id="h2-d"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h2-d)"><path d="M127.58 91.33H92.42l-1 1.8L110 96.9l18.58-3.76Z" fill="url(#h2-a)"/><path d="m91.42 93.13 12.64 12.64h11.88l12.64-12.64Z" fill="url(#h2-e)"/><path d="M102.92 104.63h14.17v55.45l-14.17-4.85Z" fill="url(#h2-f)"/><path d="m102.92 155.43 7.08 18.99 7.08-14.24" fill="url(#h2-g)"/><use height="8.49" transform="translate(99.7 108.22)" width="20.62" xlink:href="#h2-h"/><use height="8.49" transform="translate(99.7 116.91)" width="20.62" xlink:href="#h2-h"/><use height="8.49" transform="translate(99.7 125.6)" width="20.62" xlink:href="#h2-h"/><use height="8.49" transform="translate(99.7 134.3)" width="20.62" xlink:href="#h2-h"/><use height="8.49" transform="translate(99.7 143)" width="20.62" xlink:href="#h2-h"/><use height="8.49" transform="translate(99.7 151.69)" width="20.62" xlink:href="#h2-h"/></g>'
                    )
                )
            );
    }

    function hardware_3() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Flathead Screwdriver',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><filter id="h3-a" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientUnits="userSpaceOnUse" id="h3-b" x1="108.49" x2="111.44" y1="157.35" y2="157.35"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h3-c" x1="102.64" x2="117.36" y1="149.93" y2="149.93"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h3-d" x1="110" x2="110" y1="137.32" y2="117.55"><stop offset="0" stop-color="#696969"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h3-e" x1="110" x2="110" xlink:href="#h3-c" y1="87" y2="141.14"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h3-f" x1="110" x2="110" y1="137.4" y2="126.6"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h3-g" x1="110" x2="110" xlink:href="#h3-f" y1="81.53" y2="94.87"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h3-h" x1="110" x2="110" xlink:href="#h3-f" y1="179.13" y2="184.28"/><linearGradient gradientUnits="userSpaceOnUse" id="h3-i" x1="102.64" x2="117.36" y1="114.17" y2="114.17"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h3-j" x1="105.98" x2="114.02" xlink:href="#h3-c" y1="114.17" y2="114.17"/></defs><g filter="url(#h3-a)"><path d="M108.2,165.58a7.4,7.4,0,0,1-1.65,4.3l1.3,12.59h4.3l1.3-12.59a7.4,7.4,0,0,1-1.65-4.3V132.23h-3.6v33.35Z" fill="url(#h3-b)"/><path d="M102.64,126.6s2.75,2.42,2.75,5.4-2.75,5.4-2.75,5.4v3.74h14.72V137.4s-2.75-2.42-2.75-5.4,2.75-5.4,2.75-5.4V87H102.64v39.6Z" fill="url(#h3-c)"/><path d="M114.61,132c0-3,2.75-5.4,2.75-5.4H102.64s2.75,2.42,2.75,5.4-2.75,5.4-2.75,5.4h14.72S114.61,135,114.61,132Z" fill="url(#h3-d)"/><path d="M114,126.6h-8V87h8Zm0,10.8h-8v3.74h8Z" fill="url(#h3-e)"/><path d="M114,126.6h-8a10.47,10.47,0,0,1,0,10.8h8a10.47,10.47,0,0,1,0-10.8Z" fill="url(#h3-f)"/><path d="M110,169.13a4.52,4.52,0,0,0-3.36,1.62l1.21,11.72h4.3l1.21-11.72A4.52,4.52,0,0,0,110,169.13Z" fill="url(#h3-g)"/><path d="M107.52,179.28l.33,3.19h4.3l.33-3.19Z" fill="url(#h3-h)"/><path d="M117.36,87.2H102.64l1-1h12.72Zm0,53.94H102.64l1,1h12.72Z" fill="url(#h3-i)"/><path d="M114,87.2h-8l1-1h6Zm0,53.94h-8l1,1h6Z" fill="url(#h3-j)"/><path d="M111.8,142.14h-3.6v1.32h3.6Z"/></g>'
                    )
                )
            );
    }

    function hardware_4() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Pen Nib',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16439.1)" gradientUnits="userSpaceOnUse" id="h4-a" x1="1.77" x2="1.77" y1="16418.62" y2="16439.05"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h4-b" x1="2.52" x2="2.52" xlink:href="#h4-a" y1="16412.32" y2="16418.72"/><linearGradient id="h4-c" x1="1.19" x2="1.19" xlink:href="#h4-a" y1="16388.24" y2="16411.21"/><linearGradient gradientTransform="matrix(-1 0 0 1 220 0)" gradientUnits="userSpaceOnUse" id="h4-e" x1="92.43" x2="127.58" y1="132.75" y2="132.75"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="rotate(180 110 132)" gradientUnits="userSpaceOnUse" id="h4-f" x1="93.43" x2="126.58" y1="133" y2="133"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="h4-g" viewBox="0 0 4.41 55.09"><path d="M.2 1c1.66 0 2.57 1.36 2.29 3.26L.62 20.67l1.02-.25L3.48 4.4a4.08 4.08 0 0 0-.79-3.33A3.23 3.23 0 0 0 .2 0a.73.73 0 0 0 0 1Z" fill="url(#h4-a)"/><path d="m1.67 20.13-1.05.54c1.63.87 2.83 2.2 2.79 3.68A3.03 3.03 0 0 1 .7 26.99l.83.97a3.7 3.7 0 0 0 2.88-3.58 5.1 5.1 0 0 0-2.74-4.25Z" fill="url(#h4-b)"/><path d="m1.7 49.56-1 5.53V27l1 .92Z" fill="url(#h4-c)"/></symbol><filter id="h4-d"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><path d="M0 0h220v264H0z" fill="none"/><path d="M108.5 152.33h3v32.05h-3z"/><g filter="url(#h4-d)"><path d="M118.28 87.05V103c-2.17 1.32-3.36 2.54-3.32 4.41 0 4.43 12.6 10.2 12.62 22.07 0 15.98-11.78 21.7-16.34 50.95h-.74l.93-27.18 2.44-3.57-2.4-4.22c.7-7.75 1.18-18.46 1.18-18.46l-2.65-1.25-2.65 1.25s.48 10.7 1.17 18.46l-2.39 4.22 2.45 3.57.92 27.18h-.74c-4.56-29.25-16.33-34.97-16.33-50.95 0-11.87 12.62-17.64 12.62-22.07.03-1.87-1.16-3.09-3.33-4.41V87.05a18.37 18.37 0 0 1 16.57 0Z" fill="url(#h4-e)"/><path d="M110 125.75c-1.8 0-3.26 1.28-2.9 3.99.57 4.33.97 8 1.6 15.72a5.2 5.2 0 0 0-2.43 4.26c.06 1.82 2.61 3.53 2.61 3.53l-.3 22.1c-4.1-23.92-15.15-32.4-15.15-45.87 0-12.16 12.62-15.84 12.62-22.05.05-2.37-2.27-3.27-4.33-4.43V88.14a23.65 23.65 0 0 1 16.57 0V103c-2.06 1.17-4.37 2.06-4.33 4.43 0 6.22 12.62 9.89 12.62 22.05 0 13.47-11.04 21.96-15.15 45.87l-.3-22.1s2.56-1.71 2.61-3.53a5.2 5.2 0 0 0-2.42-4.25c.62-7.73 1.03-11.4 1.6-15.73.34-2.71-1.12-4-2.92-4Z" fill="url(#h4-f)"/><use height="55.09" transform="translate(109.8 125.33)" width="4.41" xlink:href="#h4-g"/><use height="55.09" transform="matrix(-1 0 0 1 110.2 125.33)" width="4.41" xlink:href="#h4-g"/></g>'
                    )
                )
            );
    }

    function hardware_5() public pure returns (HardwareData memory) {
        return
            HardwareData(
                'Scissors',
                HardwareCategories.STANDARD,
                string(
                    abi.encodePacked(
                        '<defs><linearGradient gradientUnits="userSpaceOnUse" id="h5-a" x1="14.82" x2="3.01" y1="38.81" y2="38.81"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h5-b" x1="6.92" x2="6.92" xlink:href="#h5-a" y1="0" y2="74.68"/><linearGradient id="h5-c" x1="2.52" x2="2.52" xlink:href="#h5-a" y1="2.58" y2="31.15"/><linearGradient id="h5-d" x1="4.67" x2="25.89" xlink:href="#h5-a" y1="77.06" y2="77.06"/><linearGradient gradientUnits="userSpaceOnUse" id="h5-e" x1="15.28" x2="15.28" y1="95.66" y2="58"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h5-f" x1="15.29" x2="15.29" xlink:href="#h5-a" y1="75.78" y2="93.31"/><radialGradient cx="109.21" cy="119.42" gradientUnits="userSpaceOnUse" id="h5-i" r="3.38"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="#4b4b4b"/></radialGradient><symbol id="h5-h" viewBox="0 0 26.39 95.66"><path d="M3.5 2.58c0 .03 3.33 36.98 5.35 46.44l5.48 25.96" fill="none" stroke="url(#h5-a)"/><path d="M3.16 0h.7l3.33 40.52a68.31 68.31 0 0 0 1.24 8.5l5.4 25.57-1.69.1-7-26.73a8.13 8.13 0 0 0-1.63-3.14l-2.2-2.65A5.65 5.65 0 0 1 0 38.1Z" fill="url(#h5-b)"/><path d="M4.73 29.37 2.95 2.58.3 31.15h2.76a1.66 1.66 0 0 0 1.66-1.78Z" fill="url(#h5-c)"/><path d="M19.2 69.05s-6.22.4-6.22-6.61l-3.4-3.49-1.45 4.66c3 1.9 2.52 11.05-3.32 12.7l-.14 8.81c0 6.2 5.5 10.04 10.61 10.04h.03a10.7 10.7 0 0 0 10.58-11.2c-.01-5.47-5.06-8.7-6.69-14.91ZM15.3 92.8a8.26 8.26 0 1 1 8.26-8.26 8.27 8.27 0 0 1-8.27 8.26Z" fill="url(#h5-d)" stroke="url(#h5-e)"/><path d="M15.3 92.81a8.26 8.26 0 1 1 8.25-8.26 8.27 8.27 0 0 1-8.26 8.26Z" fill="none" stroke="url(#h5-f)"/></symbol><filter id="h5-g"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h5-g)" transform="matrix(1, 0, 0, 1, 0.990002, 0)"><use height="95.66" transform="matrix(-1, 0, 0, 1, 112.5199966430664, 83.7300033569336)" width="26.39" xlink:href="#h5-h"/><path d="M105.38 123.55a3.88 3.88 0 0 0 .66 2.5l2.32 3.4 1.02-1.23-3.85-6.47Z"/><use height="95.66" transform="matrix(1, 0, 0, 1, 105.5, 83.7300033569336)" width="26.39" xlink:href="#h5-h"/><circle cx="109.01" cy="120.88" fill="#fff" r="2.05"/><circle cx="109.01" cy="119.88" r="2.05"/><circle cx="109.01" cy="120.45" fill="url(#h5-i)" r="1.79"/></g>'
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