// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs12 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_199(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Ehrenstein',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><symbol id="fi199-a" viewBox="0 0 40 108.04"><path d="M25,86H40V84H25Zm0-30H40V54H25Zm0-30H40V24H25Zm-6-6h2V0H19ZM0,56H15V54H0Zm19-6h2V30H19Zm0,30h2V60H19Zm-4,6V84H2.24L3,86ZM0,26H15V24H0ZM21,90H19v16.7L21,108Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol></defs><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110,132h0Zm0,0h0Zm0,0h0Zm0,0h0Zm0,0v0h0Zm0,0,0,0h0Zm0,0,0,0h0Zm0,0h0l0,0Zm1-35h-2V77h2Zm-2,60h2V137h-2Zm2-50h-2v20h2Zm0,85V167h-2v25Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" transform="translate(0 0)"/><use height="108.04" transform="translate(65 77)" width="40" xlink:href="#fi199-a"/><use height="108.04" transform="matrix(-1, 0, 0, 1, 155, 77)" width="40" xlink:href="#fi199-a"/>'
                    )
                )
            );
    }

    function field_200(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Semy of Alternating Roundels',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M102.5 117a5 5 0 1 1-10 0 5 5 0 0 1 10 0Zm20-5a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm5-25a5 5 0 1 0-10 0 5 5 0 0 0 10 0Zm15 30a5 5 0 1 0 10 0 5 5 0 0 0-10 0Zm5 35a5 5 0 1 0 0-10 5 5 0 0 0 0 10Zm-5-65a5 5 0 1 0 10 0 5 5 0 0 0-10 0Zm-45 5a5 5 0 1 0 0-10 5 5 0 0 0 0 10Zm-25 20a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm5 35a5 5 0 1 0-10 0 5 5 0 0 0 10 0Zm-5-65a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm25 60a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm25 0a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm-20 35a5 5 0 1 0-10 0 5 5 0 0 0 10 0Zm25 0a5 5 0 1 0-10 0 5 5 0 0 0 10 0ZM85 93a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm25 0a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm-25 30a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm25 0a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm-25 30a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm41-51a9 9 0 1 0 18 0 9 9 0 0 0-18 0Zm0 30a9 9 0 1 0 18 0 9 9 0 0 0-18 0Zm0 30a9 9 0 1 0 18 0 9 9 0 0 0-18 0Zm-16-9a9 9 0 1 0 0 18 9 9 0 0 0 0-18Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_201(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quasar Semy',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M97.5 72h25c-6.9 0-12.5 6.716-12.5 15 0-8.284-5.6-15-12.5-15Zm0 30c6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15-6.9 0-12.5-6.716-12.5-15 0 8.284-5.6 15-12.5 15Zm0 30c6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15-6.9 0-12.5-6.716-12.5-15 0 8.284-5.6 15-12.5 15Zm58.67 34.209a49.854 49.854 0 0 0 3.83-19.177C159.984 155.3 154.4 162 147.5 162a11.471 11.471 0 0 1 8.67 4.209Zm3.83-19.222v-29.974c-.007 8.278-5.6 14.987-12.5 14.987 6.9 0 12.493 6.709 12.5 14.987Zm0-30V87.013c-.007 8.278-5.6 14.987-12.5 14.987 6.9 0 12.493 6.709 12.5 14.987Zm0-30V72h-12.5c6.9 0 12.493 6.709 12.5 14.987ZM97.5 102C90.6 102 85 95.284 85 87c0 8.284-5.6 15-12.5 15 6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15Zm0 30c-6.9 0-12.5-6.716-12.5-15 0 8.284-5.6 15-12.5 15 6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15Zm0 30c6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15-6.9 0-12.5-6.716-12.5-15 0 8.284-5.6 15-12.5 15Zm25-30c6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15-6.9 0-12.5-6.716-12.5-15 0 8.284-5.6 15-12.5 15Zm0 30c6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15-6.9 0-12.5-6.716-12.5-15 0 8.284-5.6 15-12.5 15Zm0 30c1.979.012 3.916.567 5.6 1.606a49.885 49.885 0 0 0 10.752-5.786A16.502 16.502 0 0 1 135 177c0 8.284-5.6 15-12.5 15ZM110 177c0 8.284-5.6 15-12.5 15a11.638 11.638 0 0 1 9.208 4.88c1.089.071 2.185.12 3.292.12 1.107 0 2.2-.049 3.292-.12A11.634 11.634 0 0 1 122.5 192c-6.9 0-12.5-6.716-12.5-15Zm-25 0a16.5 16.5 0 0 1-3.857 10.82 49.897 49.897 0 0 0 10.757 5.786A10.789 10.789 0 0 1 97.5 192c-6.9 0-12.5-6.716-12.5-15Zm37.5-75c6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15-6.9 0-12.5-6.716-12.5-15 0 8.284-5.6 15-12.5 15ZM85 87c0-8.284 5.6-15 12.5-15h-25C79.4 72 85 78.716 85 87Zm50 0c0-8.284 5.6-15 12.5-15h-25c6.9 0 12.5 6.716 12.5 15ZM72.5 72H60v15c0-8.284 5.6-15 12.5-15Zm0 30C65.6 102 60 95.284 60 87v30c0-8.284 5.6-15 12.5-15Zm25 60c-6.9 0-12.5-6.716-12.5-15 0 8.284-5.6 15-12.5 15 6.9 0 12.5 6.716 12.5 15 0-8.284 5.6-15 12.5-15ZM60 147v.015a49.844 49.844 0 0 0 3.829 19.2A11.471 11.471 0 0 1 72.5 162c-6.9 0-12.5-6.716-12.5-15Zm12.5-15c-6.9 0-12.5-6.716-12.5-15v30c0-8.284 5.6-15 12.5-15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_202(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tiles V',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi202-a" viewBox="-17.9 -30 35.8 60"><path d="m7.1 21.48-5.11 2.39-2 6.13L-2 23.87l-5.1-2.39 5.11-2.4L0 12.95l2 6.14zm10.8-30L6.08-5.5l6.45 11.93-.06.09-9.95-7.75L0 12.95-2.53-1.22l-9.94 7.74-.06-.09L-6.09-5.5-17.9-8.52l11.82-3.03-6.58-12.16 10.14 7.89L0-30l2.52 14.18 9.95-7.75.06.1-6.44 11.92z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi202-d" viewBox="-17.9 -90 35.8 180"><use height="60" overflow="visible" transform="translate(0 -60)" width="35.8" x="-17.9" xlink:href="#fi202-a" y="-30"/><use height="60" overflow="visible" width="35.8" x="-17.9" xlink:href="#fi202-a" y="-30"/><use height="60" overflow="visible" transform="translate(0 60)" width="35.8" x="-17.9" xlink:href="#fi202-a" y="-30"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi202-b"/></defs><clipPath id="fi202-c"><use overflow="visible" xlink:href="#fi202-b"/></clipPath><g clip-path="url(#fi202-c)"><use height="180" overflow="visible" transform="matrix(1 0 0 -1 110 123.479)" width="35.8" x="-17.9" xlink:href="#fi202-d" y="-90"/><use height="180" overflow="visible" transform="translate(60 80.479)" width="35.8" x="-17.9" xlink:href="#fi202-d" y="-90"/><use height="180" overflow="visible" transform="matrix(1 0 0 -1 85 153.479)" width="35.8" x="-17.9" xlink:href="#fi202-d" y="-90"/><use height="180" overflow="visible" transform="matrix(-1 0 0 1 160 80.479)" width="35.8" x="-17.9" xlink:href="#fi202-d" y="-90"/><use height="180" overflow="visible" transform="rotate(180 67.5 76.74)" width="35.8" x="-17.9" xlink:href="#fi202-d" y="-90"/></g>'
                    )
                )
            );
    }

    function field_203(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'QuiltX I',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi203-b" viewBox="-8.3 -10 16.7 20"><path d="M2-1.4a1.75 1.75 0 0 0 0 2.8l3.3 2.3 3 6.3-5.2-3.7-1.9-4C1 1.9.5 1.6 0 1.6s-1 .3-1.1.8l-1.9 4-5.3 3.6 3.1-6.3L-2 1.4c.4-.4.7-.9.7-1.4 0-.5-.2-1-.7-1.4l-3.3-2.3-3-6.3L-3-6.3l1.9 4c.1.4.6.7 1.1.7.5 0 1-.3 1.1-.8l1.9-4L8.3-10l-3 6.3L2-1.4z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi203-a" viewBox="-11.4 -13.7 22.8 27.3"><path d="m-3-13.7 3 6.6 3.1-6.6L3-6.1 8.3-10 5.1-3.5l6.3-.2L5.9 0l5.5 3.7-6.3-.2L8.3 10 2.9 6.1l.1 7.6-3-6.6-3 6.6.1-7.6-5.4 3.9 3.2-6.5-6.3.2L-5.9 0l-5.5-3.7 6.3.2-3.2-6.5 5.4 3.9z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi203-c" viewBox="-18.2 -21.8 22.8 83.7"><use height="27.3" overflow="visible" transform="translate(-6.8 -8.17)" width="22.8" x="-11.4" xlink:href="#fi203-a" y="-13.7"/><use height="20" overflow="visible" transform="translate(-6.8 11.83)" width="16.7" x="-8.3" xlink:href="#fi203-b" y="-10"/><use height="27.3" overflow="visible" transform="translate(-6.8 31.83)" width="22.8" x="-11.4" xlink:href="#fi203-a" y="-13.7"/><use height="20" overflow="visible" transform="translate(-6.8 51.83)" width="16.7" x="-8.3" xlink:href="#fi203-b" y="-10"/></symbol><symbol id="fi203-d" viewBox="-11.4 -81.8 22.8 163.7"><use height="83.7" overflow="visible" transform="translate(6.8 -60)" width="22.8" x="-18.2" xlink:href="#fi203-c" y="-21.8"/><use height="83.7" overflow="visible" transform="translate(6.8 20)" width="22.8" x="-18.2" xlink:href="#fi203-c" y="-21.8"/></symbol><symbol id="fi203-g" viewBox="-19.7 -91.8 39.4 183.7"><use height="163.7" overflow="visible" transform="translate(8.33 -10)" width="22.8" x="-11.4" xlink:href="#fi203-d" y="-81.8"/><use height="163.7" overflow="visible" transform="translate(-8.33 10)" width="22.8" x="-11.4" xlink:href="#fi203-d" y="-81.8"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" id="fi203-e"/></defs><clipPath id="fi203-f"><use overflow="visible" xlink:href="#fi203-e"/></clipPath><g clip-path="url(#fi203-f)"><use height="183.7" overflow="visible" transform="matrix(1 0 0 -1 101.67 133.83)" width="39.4" x="-19.7" xlink:href="#fi203-g" y="-91.8"/><use height="183.7" overflow="visible" transform="matrix(1 0 0 -1 135 133.83)" width="39.4" x="-19.7" xlink:href="#fi203-g" y="-91.8"/><use height="183.7" overflow="visible" transform="matrix(1 0 0 -1 168.33 133.83)" width="39.4" x="-19.7" xlink:href="#fi203-g" y="-91.8"/><use height="183.7" overflow="visible" transform="matrix(1 0 0 -1 68.33 133.83)" width="39.4" x="-19.7" xlink:href="#fi203-g" y="-91.8"/></g>'
                    )
                )
            );
    }

    function field_204(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bloomy',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><symbol id="fi204-a" viewBox="0 0 35.7 30.96"><path d="m33.46 12.51-2.2-4.77-3.05-4.3a4.57 4.57 0 0 1 .52 3.17 6.16 6.16 0 0 1-3.26 4.28c-2.3 1.2-4.61 2.28-4.97 1.93-.42-.42 1.23-3.75 2.66-6.42a6.03 6.03 0 0 1 .68-1.02c1.1-1.31 3.17-3.4 4.37-1.95L26.77.03l-3.69.45L17.85 0 12.6.48a4.57 4.57 0 0 1 3.02 1.14 6.16 6.16 0 0 1 2.06 4.96c-.1 2.6-.32 5.14-.8 5.27-.58.16-2.64-2.94-4.24-5.52a5.98 5.98 0 0 1-.53-1.07c-.6-1.6-1.37-4.46.49-4.78L8.92.02 7.47 3.44l-3.03 4.3-2.2 4.79a4.57 4.57 0 0 1 2.5-2.04 6.16 6.16 0 0 1 5.32.69c2.2 1.38 4.3 2.85 4.16 3.33-.15.58-3.85.81-6.9.9a6.06 6.06 0 0 1-1.21-.08c-1.68-.29-4.52-1.04-3.88-2.8L0 15.48l2.24 2.96 2.2 4.78 3.04 4.3a4.57 4.57 0 0 1-.51-3.18 6.16 6.16 0 0 1 3.26-4.27c2.3-1.2 4.61-2.29 4.96-1.94.43.43-1.22 3.75-2.66 6.43a6 6 0 0 1-.68 1.01c-1.1 1.32-3.17 3.4-4.37 1.95l1.44 3.41 3.69-.45 5.24.48 5.25-.48a4.57 4.57 0 0 1-3.02-1.15 6.17 6.17 0 0 1-2.06-4.96c.1-2.59.32-5.14.8-5.27.58-.15 2.63 2.94 4.23 5.53a5.98 5.98 0 0 1 .53 1.07c.6 1.6 1.37 4.46-.49 4.78l3.68.45 1.44-3.42 3.04-4.3 2.2-4.78a4.57 4.57 0 0 1-2.5 2.04 6.16 6.16 0 0 1-5.32-.7c-2.2-1.38-4.29-2.84-4.16-3.32.16-.58 3.86-.82 6.9-.91a6.07 6.07 0 0 1 1.21.08c1.69.3 4.53 1.05 3.88 2.81l2.24-2.95Zm-23.4 7.27a6.16 6.16 0 0 1-5.33.7 4.57 4.57 0 0 1-2.5-2.03c-.67-1.84 2.46-2.58 4.09-2.84a6 6 0 0 1 1.12-.06c3.01.1 6.62.33 6.77.9.14.48-1.96 1.95-4.15 3.33Zm5.13-6.96c-.35.36-2.67-.73-4.96-1.93a6.16 6.16 0 0 1-3.26-4.27 4.57 4.57 0 0 1 .5-3.17c1.26-1.5 3.46.83 4.5 2.12a5.98 5.98 0 0 1 .62.94c1.42 2.65 3.02 5.89 2.6 6.31Zm-2.57 17.66c-1.93-.34-1.01-3.42-.42-4.96a5.97 5.97 0 0 1 .5-1c1.6-2.56 3.6-5.56 4.17-5.41.48.13.7 2.67.8 5.27a6.16 6.16 0 0 1-2.06 4.95 4.58 4.58 0 0 1-3 1.15Zm6.2-18.63c-.49-.13-.7-2.67-.8-5.27a6.16 6.16 0 0 1 2.06-4.95 4.58 4.58 0 0 1 3-1.15c1.93.34 1 3.41.41 4.95a5.86 5.86 0 0 1-.5 1C21.4 9 19.39 12 18.82 11.85Zm6.64 8.22a6.16 6.16 0 0 1 3.26 4.26 4.58 4.58 0 0 1-.5 3.18c-1.26 1.5-3.46-.84-4.5-2.12a5.96 5.96 0 0 1-.62-.94c-1.42-2.66-3.02-5.9-2.6-6.32.36-.35 2.67.73 4.96 1.94Zm3.9-4.72a6.01 6.01 0 0 1-1.12.06c-3.01-.1-6.62-.33-6.77-.9-.13-.48 1.96-1.95 4.16-3.33a6.16 6.16 0 0 1 5.32-.7 4.57 4.57 0 0 1 2.5 2.03c.68 1.84-2.45 2.58-4.08 2.84Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi204-c" viewBox="0 0 35.7 150.96"><use height="30.96" transform="translate(0 60)" width="35.7" xlink:href="#fi204-a"/><use height="30.96" transform="translate(0 90)" width="35.7" xlink:href="#fi204-a"/><use height="30.96" transform="translate(0 120)" width="35.7" xlink:href="#fi204-a"/><use height="30.96" transform="translate(0 30)" width="35.7" xlink:href="#fi204-a"/><use height="30.96" width="35.7" xlink:href="#fi204-a"/></symbol><clipPath id="fi204-b"><path d="M60.05 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="none"/></clipPath></defs><path d="M60.05 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi204-b)"><use height="150.96" transform="matrix(.962 0 0 1 92.84 56.52)" width="35.7" xlink:href="#fi204-c"/><use height="150.96" transform="matrix(.962 0 0 1 42.84 56.52)" width="35.7" xlink:href="#fi204-c"/><use height="150.96" transform="matrix(.962 0 0 1 67.84 41.52)" width="35.7" xlink:href="#fi204-c"/><use height="150.96" transform="matrix(-.962 0 0 1 177.16 56.52)" width="35.7" xlink:href="#fi204-c"/><use height="150.96" transform="matrix(-.962 0 0 1 152.16 41.52)" width="35.7" xlink:href="#fi204-c"/><path d="M58 118.13h52V132H58z" fill="none"/></g><path d="M0 0h220v264H0z" fill="none"/>'
                    )
                )
            );
    }

    function field_205(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Talon Matrix I',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi205-a" viewBox="-2.47 -15 4.93 30"><path d="M2.47 0 0 15-2.47 0 0-15z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi205-c" viewBox="-30.02 -45 50 60"><use height="30" overflow="visible" transform="translate(-5.016)" width="4.93" x="-2.47" xlink:href="#fi205-a" y="-15"/><use height="30" overflow="visible" transform="matrix(0 -1 .8318 0 7.507 -15)" width="4.93" x="-2.47" xlink:href="#fi205-a" y="-15"/><use height="30" overflow="visible" transform="matrix(.7682 -.6402 .4166 .4999 1.233 -7.5)" width="4.93" x="-2.47" xlink:href="#fi205-a" y="-15"/><use height="30" overflow="visible" transform="matrix(0 -1 -.8318 0 -17.54 -15)" width="4.93" x="-2.47" xlink:href="#fi205-a" y="-15"/><use height="30" overflow="visible" transform="matrix(-.7682 -.6402 -.4166 .4999 -11.266 -7.5)" width="4.93" x="-2.47" xlink:href="#fi205-a" y="-15"/><use height="30" overflow="visible" transform="matrix(1 0 0 -1 -5.016 -30)" width="4.93" x="-2.47" xlink:href="#fi205-a" y="-15"/><use height="30" overflow="visible" transform="matrix(.7682 .6402 .4166 -.4999 1.233 -22.5)" width="4.93" x="-2.47" xlink:href="#fi205-a" y="-15"/><use height="30" overflow="visible" transform="matrix(-.7682 .6402 -.4166 -.4999 -11.266 -22.5)" width="4.93" x="-2.47" xlink:href="#fi205-a" y="-15"/></symbol><symbol id="fi205-b" viewBox="-26.23 -62.5 52.47 125"><path d="m-21.3-42.5-2.47-15-2.47 15 2.47 15 2.47-15zm47.53 105-7.92-5.49-4.58-9.51 7.92 5.49 4.58 9.51zm-49.95-125c.78 0 1.55.02 2.33.06l-2.38 4.94-.3-4.99c.12 0 .23-.01.35-.01zm24.95 65L13.73.03l12.5 2.47-12.5 2.47L1.23 2.5zm12.5 15 4.58-9.51 7.92-5.49-4.58 9.51-7.92 5.49zm0-30 7.92 5.49 4.58 9.51-7.92-5.49-4.58-9.51zm-37.5-45 7.92 5.49 4.58 9.51-7.92-5.49-4.58-9.51zm0 90 2.47 15-2.47 15-.95-15 .95-15zm0 30 4.58-9.51 7.92-5.49-4.58 9.51-7.92 5.49z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><use height="125" overflow="visible" transform="matrix(1 0 0 -1 133.767 134.5)" width="52.47" x="-26.23" xlink:href="#fi205-b" y="-62.5"/><use height="125" overflow="visible" transform="rotate(180 43.14 67.25)" width="52.47" x="-26.23" xlink:href="#fi205-b" y="-62.5"/><use height="60" overflow="visible" transform="matrix(1 0 0 -1 115.016 117)" width="50" x="-30.02" xlink:href="#fi205-c" y="-45"/><defs><path d="M60.05 72v75c0 27.61 22.38 50 50 50 27.61 0 50-22.38 50-49.99V72h-100z" id="fi205-d"/></defs><clipPath id="fi205-e"><use overflow="visible" xlink:href="#fi205-d"/></clipPath><g clip-path="url(#fi205-e)"><use height="60" overflow="visible" transform="matrix(1 0 0 -1 90.016 87)" width="50" x="-30.02" xlink:href="#fi205-c" y="-45"/><use height="60" overflow="visible" transform="matrix(1 0 0 -1 140.016 87)" width="50" x="-30.02" xlink:href="#fi205-c" y="-45"/><use height="60" overflow="visible" transform="matrix(1 0 0 -1 90.016 147)" width="50" x="-30.02" xlink:href="#fi205-c" y="-45"/><use height="60" overflow="visible" transform="matrix(1 0 0 -1 140.016 147)" width="50" x="-30.02" xlink:href="#fi205-c" y="-45"/></g>'
                    )
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IFieldSVGs {
    struct FieldData {
        string title;
        ICategories.FieldCategories fieldType;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}