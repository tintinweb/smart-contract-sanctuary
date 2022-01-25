// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs17 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_228(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Warp',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi228-c" viewBox="-25 -32.79 50 62.79"><path d="m-13.36-22.7-1.83.58-.42-.8 1.67-.69zm1.97-3.41-1.58.82-.73-.94 1.39-.88zm5.4 21.67 8.33 6.38 6.23 9.79L-3.17.97zm-11.79-13.64 2.39.31.4.95-2.57-.57zm-.76-2.39 1.86-.41.29.71-1.97.26zm.36 1.14 2.11-.09.32.79-2.24-.1zm2.57-6.9-1.23.94-.43-.82 1.09-1zm6.2 2.28-2.04.65-.78-1.02 1.8-.74zm32.69 35.68L7.92 1.94l-4.9-6.38L13.43.97zM2.95-15.35l6.55.86 5.69 4.37-8.62-1.91zm-10.02-6.04-2.65.35-.9-1.18 2.32-.51zm28.06 4.36-9.03-.39-4.74-3.02 6.65-.29zm-23.79 5 6.06 1.91 4.13 4.51-7.72-3.2zm-1.94-13.39-2.45.77-1.33-1.21 2.08-.86zm13.37 1.96-5.1.67-2.99-1.9 4.01-.89zm-3.32 5.75-5.18-.23-2.29-2.09 4.2-.18zm-19.82-6.78-1.51.78-.41-.78 1.37-.87zm-2.45 2.93-1.75.55-.17-.55 1.64-.68zm-.36 4.95 2.77.87.52 1.25-3.02-1.25zm-.21-6.31-1.53.8-.18-.58 1.43-.91zm6.9 4.51-2.69-.11-.51-1 2.43-.11zM19.93 30h-7.3l-2.13-2.76L1.43 9.82zm-34.69-51.3 2.01-.45.64 1.02-2.2.29zm10.69-.48-1.66-1.52 2.9-.65 2.22 1.7zm-14.04-2.54-1.32 1.02-.2-.65 1.22-1.11zm-1.99-1.1 1-1.3.36.86-1.11 1.22zm4.22 13.39 4.2 3.22 1.33 3.2-4.93-4.51zm7.16-3.4-3.37-.74-.65-1.25 3 .39zm-4.54 11.7-1.2-3.79 6.03 6.58 3.17 7.64zm-3.47-11 3.31 1.73.76 1.83-3.69-2.35zm8.81 6.58-1.42-2.73 5.24 2.73 2.62 4.1zm1.9-3.02L-10.44-13l-.9-1.73 3.82 1.21zm1.95-6.94-3.52-.15-1.13-1.48 3.04-.13zm4.29 4.67-4.94-1.1-1.56-2.03 4.13.55zm-20.31-5.38-2-.09-.04-.25 1.95-.08zm4.97-9.27 1.04-.95.88.95-1.21.93zm-3.08.19.83-1.08.61.95-.96 1.05zm1.62-2.1.74-.97.89.97-.89.97zm3.55 0 1.06-.97 1.26.97-1.26.97zm2.15 1.98 1.5-.96 1.41 1.09-1.77.91zM-21.54-30l.47-1.48.61 1.48-.61 1.49zm2.25 0 .57-1.09.7 1.09-.7 1.1zm-1.4 2.69.75-1.44.44 1.07-.88 1.39zM1.47-30l3.59-1.48L9.78-30l-4.72 1.49zM11.49-7.52l12.03 3.79L25-2.6v4.28L18.68-.94zm4.44 19.9L25 19.34v4.86zM25-12.45v3.34l-6.61-4.21zM9.49-26.68l6.35-1.4 8.23 2.59-8.89 1.17zm-13.63-.99 2.6-1.08 2.77 1.45-3.2 1.01zM-7.79-30l1.74-1.1 2.12 1.1-2.12 1.1zM.97 21.73 4.4 30H.53l-7.99-15.35-3.85-12.19zm-23.58-44.52-.08-.67 1.1-2.12.2.88zm3.71 9.35-2.81-2.58-.08-.55 2.65 2.03zm-.99-4.46-2.13-.48-.04-.27 2.07.27zm.25 1.08-2.3-.95-.05-.31 2.22.69zm1.48 6.7-3.35-4.37-.12-.86 3.04 3.32zm-1.18-5.31-2.51-1.6-.05-.39 2.4 1.25zM-15.66 30l-2.23-16.96L-14.13 30zm-.87-32.76-4.61-8.85-.22-1.71 3.82 6zM-9.27 30h-.27l-10.5-33.31-.73-5.5 6.23 15.03zm-11.18-50.46-1.77.56-.04-.26 1.72-.71zm-.63-2.84-1.39 1.51-.06-.45 1.31-1.71zM-25 30v-49.03L-22.86 30zm1.44-60 .37-2.79.62 2.79-.62 2.8zm.6 4.51.82-2.6.31 1.41-.98 2.36zm2.12 3.27-1.54 1.17-.04-.34 1.46-1.35zm.57 2.57-1.89.25-.03-.25 1.83-.41zm-.37-1.65-1.65.86-.04-.29 1.59-1.01z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><path d="M60 72v75a50 50 0 1 0 100 0V72H60z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '" id="fi228-a"/><clipPath id="fi228-b"><use overflow="visible" xlink:href="#fi228-a"/></clipPath><g clip-path="url(#fi228-b)"><path d="M109 67h51v65.99h-51z" fill="none"/><use height="62.79" overflow="visible" transform="matrix(1 0 0 -1.0832 135 99.5)" width="50" x="-25" xlink:href="#fi228-c" y="-32.79"/><path d="M60 67h50v64.99H60z" fill="none"/><use height="62.79" overflow="visible" transform="matrix(-1 0 0 -1.0832 85 99.5)" width="50" x="-25" xlink:href="#fi228-c" y="-32.79"/><path d="M60 132h50v64.99H60z" fill="none"/><use height="62.79" overflow="visible" transform="matrix(-1 0 0 1.0832 85 164.5)" width="50" x="-25" xlink:href="#fi228-c" y="-32.79"/><path d="M110 132h50v64.99h-50z" fill="none"/><use height="62.79" overflow="visible" transform="matrix(1 0 0 1.0832 135 164.5)" width="50" x="-25" xlink:href="#fi228-c" y="-32.79"/></g>'
                    )
                )
            );
    }

    function field_229(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Mach',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi229-c" viewBox="-32.7 -31 66.5 83.1"><path d="m28.8-16.8-.9 1.3.1 5.4 1.2-2.4.7 7.1.9-2.8-.9-5.8-.7 1.4-.4-4.2zm-10.3 46L23-.2l2-4-1.9 19.5-4.6 13.9zm8.2-24.8L26.4 17l-5.7 23.1 2.4-24.9 3.6-10.8zM13.4-24.4l6.4.3-1.3 1.2 4.1-.2-1.2 1.6-5.5 1 2.6-2.5-8.2.4 3.1-1.8zm-.5-2.8-7.6-1.4 4.9-1.4 5.4 1.6-2.7 1.2zm0 0 3.8.7-3.3 2.1-5.9-.3 5.4-2.5zm17.9 19 1.2-3.6.7 3-1.3 5.1-.6-4.5zM28.2-.3l-1.5 4.7.3-12.5 1-2 .2 9.8zm-2.4-12.3 1.3-1.9-.1 6.4-2 3.9.8-8.4zm2.6 21.3.5 21-3.4 22.5.9-35.2 2-8.3-.2-9 1.7-5.1.6 5.9-2.1 8.2zm4.3 15.2-1.4 14.3-2.1 3.9-.3-12.5L31.6 12 30.5.5l1-4.2 1.3 8.2-1.1 7.6 1 11.8zM18.2-1.6 7.7 30H-2.7l3.1-6.2L18.2-1.6zm-4-10.3L-2.3 10.2-20.9 28l.4-13.4L-6.4 1l20.6-12.9zm-43.1 4.4.6-4.6L-13-15l-15.9 7.5zM-6.4 1-21 10.1l-.4-8.1L6.1-11-6.4 1zm-15-3.6 1.1-5.6 14.4-4.2-15.5 9.8zm28.9-22L2.1-22l8.3-.4L3.2-18l12.7-2.4-2.6 2.5-19.2 5.5L3.2-18-13-15l15-7.1-34.8 1.6 3.5 1.9 23-6.7 13.8.7zm-2.2-4-11.5 3.3-23-1.1 1.3 1.1L-2.4-30l7.7 1.4zm19.3 17.8L23-.2l-5.6 11 4.4-17.6 2.8-4zm-9-17.7zM3 5l-5.3 5.1-15 19.9H-4l4.4-6.2L6.8 11 19.6-6l-1.4 4.4 3.6-5.2.9-3.5 2.1-5.5-1 1 .2-.9.9-.3-.1.2.3-.3.3-.1-.8 5.4 1.2-1.7.4-3.9 1-.3-.1 2.3.7-1v-1.3l.9-.2v.2l.1-.2.5-.1.5 3.1 1-2 1 4.2.7-2.3-1.1-3.2h2.1V-31h-9.9v1.8l-1.3-.8-1.5.9 2.7 1.3v.1l-1.3 1.2 1.1.3-.1.9-2-.4-1.6 1.5 3.4.2v.2l-.4.8h.4l-.3 1.4-1.3.2-1.1 1.5 2.2-.6-.5 1.4-.4.9-4 1.9-3.4 4.5 1.1-.7L3 5zm27.7-22.2h.9L31-16l-.3-1.2zM16.2-7.6l3.6-6.1 2.8-1.5-.7 2.1-5.7 5.5zm-5.4 45.2-9.2 4.6 15.8-31.3-6.6 26.7zm10.1-66.7-2.3 1.5 3.8 1.1-.9.9-4.7-.9 1.8-1.1-2.9-.9L19-30l1.9.9zm-.7 9.2-2.6 3.5L6.1-11l7.2-6.9 6.9-2z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '" id="fi229-a"/><clipPath id="fi229-b"><use overflow="visible" xlink:href="#fi229-a"/></clipPath><g clip-path="url(#fi229-b)"><use height="83.1" overflow="visible" transform="matrix(1 0 0 -1 77.25 102)" width="66.5" x="-32.7" xlink:href="#fi229-c" y="-31"/><use height="83.1" overflow="visible" transform="rotate(180 71.37 51)" width="66.5" x="-32.7" xlink:href="#fi229-c" y="-31"/><use height="83.1" overflow="visible" transform="translate(77.25 162)" width="66.5" x="-32.7" xlink:href="#fi229-c" y="-31"/><use height="83.1" overflow="visible" transform="matrix(-1 0 0 1 142.75 162)" width="66.5" x="-32.7" xlink:href="#fi229-c" y="-31"/></g>'
                    )
                )
            );
    }

    function field_230(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Kaleidoscope',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi230-a" viewBox="-25 -37.5 50 75"><path d="M25 31.15a88.142 88.142 0 0 1-7.69 6.35H1.72c1.2-.62 2.38-1.26 3.54-1.94A81.146 81.146 0 0 0 25 27.39v3.76zM-20.24-26c2.27.72 4.7.82 7.02.29-.66 2.75-1.98 5.29-3.83 7.42-2.82-.2-5.55-1.07-7.95-2.54 2.02-1.27 3.67-3.05 4.76-5.17z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M25 17.69v1.57c-5.63 6.49-12.3 12-19.74 16.3-3.25.85-6.55 1.5-9.89 1.94H-25a72.026 72.026 0 0 0 27.08-9.63A72.145 72.145 0 0 0 25 17.69zM-25-37.5c.96 1 1.51 2.33 1.54 3.72A5.567 5.567 0 0 1-25-37.5z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M-25-29.17a7.011 7.011 0 0 0 1.54-4.62c1.14 1.22 2.69 2 4.35 2.18.18 1.94-.21 3.89-1.13 5.61A9.963 9.963 0 0 1-25-29.17zm0 41.67A46.723 46.723 0 0 0-7.48 4.79a46.812 46.812 0 0 0 17.84-6.94A51.496 51.496 0 0 1-4.3 12.49a51.536 51.536 0 0 1-20.7.01zm0 16.67a63.55 63.55 0 0 0 23.89-8.99C6.99 18.33 17.4 12.7 25 7.5A93.003 93.003 0 0 1 2.08 27.87 68.657 68.657 0 0 1-25 29.17zm0-25C-19.78 2.85-14.9.44-10.67-2.9c5.35-.63 10.5-2.38 15.13-5.14A43.014 43.014 0 0 1-7.48 4.79c-5.82 1-11.79.79-17.52-.62z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M-25 20.83c7.4-1.34 14.44-4.19 20.7-8.35a55.144 55.144 0 0 0 20.54-8.73A60 60 0 0 1-1.11 20.18a59.889 59.889 0 0 1-23.89.65zm0-33.33c3.07-1.28 5.79-3.27 7.95-5.79 3.32.25 6.65-.27 9.72-1.53a25.91 25.91 0 0 1-6.53 9.23c-3.81.19-7.61-.46-11.14-1.91z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M-25-4.17c4.14-1.31 7.94-3.5 11.14-6.43 4.34-.19 8.58-1.33 12.43-3.33A34.494 34.494 0 0 1-10.67-2.9c-4.81.59-9.7.16-14.33-1.27z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi230-b" viewBox="-50.01 -37.5 100.01 75"><use height="75" overflow="visible" transform="translate(25.006)" width="50" x="-25" xlink:href="#fi230-a" y="-37.5"/><use height="75" overflow="visible" transform="matrix(-1 0 0 1 -25.006 0)" width="50" x="-25" xlink:href="#fi230-a" y="-37.5"/></symbol><symbol id="fi230-e" viewBox="-50.01 -75 100.01 150"><use height="75" overflow="visible" transform="translate(0 37.5)" width="100.01" x="-50.01" xlink:href="#fi230-b" y="-37.5"/><use height="75" overflow="visible" transform="matrix(1 0 0 -1 0 -37.5)" width="100.01" x="-50.01" xlink:href="#fi230-b" y="-37.5"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi230-c"/></defs><clipPath id="fi230-d"><use overflow="visible" xlink:href="#fi230-c"/></clipPath><g clip-path="url(#fi230-d)"><use height="150" overflow="visible" transform="matrix(1 0 0 -1 109.994 147)" width="100.01" x="-50.01" xlink:href="#fi230-e" y="-75"/><use height="150" overflow="visible" transform="matrix(0 -1 -1 0 109.994 147)" width="100.01" x="-50.01" xlink:href="#fi230-e" y="-75"/></g>'
                    )
                )
            );
    }

    function field_231(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'AxoPile',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi231-c" viewBox="-34.49 -63.69 67.98 127.37"><path d="m-25.87-18.53-.01-.01zm-1.51-3.33 1.5 3.32-4.28-5.49zm9.76 21.52-2.28-5.02-.13-5.69 3.29 4.22zm.31 12.54v.01l-1.23-5.76.92-6.78 2.3 5.09zm-1.89 13.65.24 10.46-4.84 9.13 1.55-11.5zm1.58-26.19z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m-19.77.68-2.31-10.84 2.18 4.8zm-2.31-10.84-3.8-8.37 2.77 3.55z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m-21.36 27.34 1.88-13.94-.29-12.72 1.23 5.76-.94 6.96.15 6.36zm12.97-48.47-1.41 5.25-5.4-2.44.56-4.1zm-4.69 30.81-2.23-4.93 1.94-7.26 3.29 4.22 2.94-7.77L.4-.17l-4.84 9.12-5.64-7.23zm-6.25 10.08 2.02-7.56 1.18 5.53 3.04-8.05 3.81 8.39-4.84 9.12-2.01-9.44-3.06 8.1zm-13.35-47.02 2.11-1.64.37.83-2.3 1.05.35.45 2.41-.5.34.76h-2.54l.31.4 2.65.54.48 1.05-2.91-1.32 1.25 1.61-3.74-2.56.42-1.7zm5.97-4.65v.01zm5.35 59.25-.89 6.6-3 7.96zm-10.11-58.22 3.91-5.01.84 3.98-3.86 3.01z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m-20.52-32.43-5.75 2.6-.44-2.07 6.1-4.76.09 4.23 7.7-3.48-.74 5.51 8.1-1.67L-7-26.3h-7.11l-.52 3.89-5.67-1.17-.06-2.72h6.26l.55-4.09-6.87 1.42-.1-3.46zm0-.01zm-12.97 4.15-1-3.22 1-3.81 2.02 4.45z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m-30.2-28.07 3.93-1.77.42 1.96-3.9.8zm9.58-8.6-.17-7.89h-.01l-6.76 8.67-1.81-8.51h-.01l8.18-18.03.4 17.87 11.05-14.16-2.04 15.16zm24 2.77-8.84 1.82 2.17-8.14-9.52 4.3 1.02-7.64L.1-52.84l-3.37 12.61 10.9-4.93zm-36.87-29.79 4.11 19.29-4.11 9.07-1-8.76zm9.48 44.46zM.51-26.31l2.87-7.59L17-36.71l16.49 10.4zm9.05 8.88L5.15-9.12l-9.51-4.3-2.78 7.36-4.37-3.41-1.86 6.96-3.37-4.32.81-6.08-4.22-3.3.12 5.16-3.08-3.93-.9-4.25 3.86 3.01-.1-4.37 5.05 2.28-.73 5.39h.01l4.41 3.45 1.72-6.41 5.43 2.46 2.41-6.39-6.44-1.32 1.38-5.18H.51l-2.45 6.5zm-35.41-10.45v.01z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m-28.5-24.33 3.76 1.7-.41-1.96 4.83 1 .07 2.99-4.48-2.03.72 3.4-3.37-2.63z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M-29.4-26.31h3.88l-.33-1.56 5.41-1.12.06 2.69h-5.13l.36 1.71-3.82-.79zm4.25 1.72zm-3.49 79.15-4.85 9.13 8.24-21.79z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi231-a"/></defs><clipPath id="fi231-b"><use overflow="visible" xlink:href="#fi231-a"/></clipPath><g clip-path="url(#fi231-b)"><use height="127.37" overflow="visible" transform="matrix(1 0 0 -1 143.487 135.687)" width="67.98" x="-34.49" xlink:href="#fi231-c" y="-63.69"/><use height="127.37" overflow="visible" transform="rotate(180 38.253 67.844)" width="67.98" x="-34.49" xlink:href="#fi231-c" y="-63.69"/></g>'
                    )
                )
            );
    }

    function field_232(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Lens',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><clipPath id="fi232-a"><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="none"/></clipPath><symbol id="fi232-b" viewBox="0 0 50.01 67.3"><path d="M0 5.16a125.66 125.66 0 0 1 13.22 7.98A177.9 177.9 0 0 1 28.46 6.8 50.77 50.77 0 0 0 11.24 0 222.63 222.63 0 0 0 .01 5.16ZM28.47 6.8a112.89 112.89 0 0 1 11.23 9c3.32-1.07 6.77-2.01 10.31-2.83V1.93A87.7 87.7 0 0 0 28.47 6.8ZM11.21 30.15A85.4 85.4 0 0 1 24.43 22a99.6 99.6 0 0 0-11.21-8.86A106.68 106.68 0 0 0 0 20.91a83.4 83.4 0 0 1 11.21 9.24Zm22.41 1.79a86.28 86.28 0 0 1 15.26-6.44 92.48 92.48 0 0 0-9.18-9.7A108.62 108.62 0 0 0 24.44 22a80.77 80.77 0 0 1 9.18 9.94ZM27.51 65.3c0-8.33 4.99-15.95 13.24-21.83a63.58 63.58 0 0 0-7.13-11.53 60.78 60.78 0 0 0-13.24 9.6 44.71 44.71 0 0 1 7.13 23.76Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M0 40.9c5.87 7.38 9.17 15.66 9.17 24.4 0-8.73 4.12-16.87 11.21-23.76a62.82 62.82 0 0 0-9.17-11.39A62.03 62.03 0 0 0 0 40.9Zm45.84 24.4 4.16 2V38.08a53.73 53.73 0 0 0-9.25 5.25 49.27 49.27 0 0 1 5.09 21.97Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol></defs><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi232-a)"><use height="67.3" transform="translate(110 66.84)" width="50.01" xlink:href="#fi232-b"/><use height="67.3" transform="matrix(-1 0 0 1 109.99 66.84)" width="50.01" xlink:href="#fi232-b"/><use height="67.3" transform="matrix(1 0 0 -1 110 197.44)" width="50.01" xlink:href="#fi232-b"/><use height="67.3" transform="rotate(180 55 98.72)" width="50.01" xlink:href="#fi232-b"/></g>'
                    )
                )
            );
    }

    function field_233(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Bender',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 107a50.02 50.02 0 0 1-47.708-35h-2.043a50 50 0 0 0 99.5 0h-2.043A50.019 50.019 0 0 1 110 107Zm0 80a50 50 0 0 1-50-50v10a50 50 0 0 0 100 0v-10a50.001 50.001 0 0 1-50 50Zm0-100a49.837 49.837 0 0 1-35.694-15h-7.6a49.988 49.988 0 0 0 86.589 0h-7.6A49.836 49.836 0 0 1 110 87Zm0 40a50 50 0 0 1-50-50v10a50 50 0 0 0 100 0V77a50.001 50.001 0 0 1-50 50Zm0 40a50 50 0 0 1-50-50v10a50 50 0 0 0 100 0v-10a50.001 50.001 0 0 1-50 50Zm0-20a50 50 0 0 1-50-50v10a50 50 0 0 0 100 0V97a50.001 50.001 0 0 1-50 50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
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