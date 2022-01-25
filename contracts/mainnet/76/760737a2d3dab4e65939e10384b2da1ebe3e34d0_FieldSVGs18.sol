// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs18 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_234(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Stretcher',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi234-a" viewBox="-25.7 -5 50.4 10"><path d="M1.6-5zm22.1 0zm0 10c-.4-1.7-1-3.4-1.6-5-.6 1.7-1.4 3.4-2.2 5-.9-1.7-1.8-3.4-2.9-5-1.2 1.7-2.4 3.4-3.8 5-1.5-1.8-3.2-3.4-4.9-5C6.2 1.9 4 3.5 1.6 5c-3.4-2.1-7-3.8-10.7-5 3.8-1.2 7.4-2.9 10.7-5C4-3.5 6.2-1.9 8.3 0c1.8-1.5 3.4-3.2 4.9-5 1.4 1.6 2.6 3.3 3.8 5 1.1-1.6 2-3.3 2.9-5 .8 1.6 1.6 3.3 2.2 5 .6-1.6 1.1-3.3 1.6-5 .4 1.6.8 3.3 1 5-.2 1.7-.6 3.4-1 5zm-48.4-7.5c5.3 0 10.5.8 15.6 2.5-5.1 1.7-10.3 2.5-15.6 2.5l-1-2.5 1-2.5z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi234-d" viewBox="-25.7 -65 50.4 130"><use height="10" overflow="visible" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 -10)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 -20)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 -30)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 -40)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 -50)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 -60)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 10)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 20)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 30)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 40)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 50)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/><use height="10" overflow="visible" transform="translate(0 60)" width="50.4" x="-25.7" xlink:href="#fi234-a" y="-5"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '" id="fi234-b"/><clipPath id="fi234-c"><use overflow="visible" xlink:href="#fi234-b"/></clipPath><g clip-path="url(#fi234-c)"><use height="130" overflow="visible" transform="matrix(1 0 0 -1 134.72 134.5)" width="50.4" x="-25.7" xlink:href="#fi234-d" y="-65"/><use height="130" overflow="visible" transform="rotate(180 42.64 67.25)" width="50.4" x="-25.7" xlink:href="#fi234-d" y="-65"/></g>'
                    )
                )
            );
    }

    function field_235(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Inner Sphere',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '" id="fi235-e"/><clipPath id="fi235-f"><use xlink:href="#fi235-e"/></clipPath><symbol id="fi235-b" viewBox="0 0 51.1 73.2"><path d="m0 0 1 4.6L15.5 0Zm22.3 6 10.9-6-9.1 1L9.9 5.9Zm25.1 13.5 1.8-.4-2-5-3.6.9 2.5 2.7ZM40.6 3.9 51 2.7V0H36.3Zm6.5 10.3 3.9-.3V8.3l-6.7.6ZM9.9 6 0 9.1l1 6.8Zm32 13.6 2.5 1.2 1.4-.8-5.5-3.7-2.7 1.8Zm-17.5-8-4.9 5 9.7-.2 3.9-3.1-8.7-1.7 7.1-4.5 6.7 3.6L44.3 9l-3.7-5-9.1 3.1L22.4 6l-8.9 6.2Zm4.5 8 6.8.4 2-2-8.4-1.7-2.7 3.4Zm6.2-5.7 5.2 2.5 3.2-1.4-5.3-4.4-5.1 2.6Zm-9.8 16.5.7 1.3 7.9-3.7-.4-1.8-8.6 3ZM51 36v-5.1l-1.5-.1-1 5.2Zm0 5.6-3.4-.1-.7 5.6-4-.3-1.1 5.6 4.6.3.6-5.6 4.1.1Zm-6.7-.4 3.3.3.9-5.5-2.4-.3-1.8 5.5-3.3-.6-2.2 5.6 4 .6ZM35 45.4l-1.2 2.8-1.1 2.9-4.4-1 3-5.8 3.7 1.1 2.9-5.6-2.9-1-3.7 5.5-3.6-1.3-3.7 6 4.3 1.2-2.3 6 5 .8 1.7-5.9 4.5.7-1.3 5.7 5 .4.8-5.6-4.5-.5 1.7-5.7Zm.6-25.4-1.3 2.1 8.2.6.8-1Zm10.5 15.7 2-5.1-1.3-.4-3.1 4.9Zm-13.9 1.8-2.5-1.7-5.4 5.4 3.4 1.7 4.5-5.4 2.8 1.3 4.5-5.2-1.9-1.1 6-4.1-.8-.8-6.8 3.6 1.6 1.3Zm12.3-8.3-5 4.4 2.1.9-3.6 5.3 3.1.8 2.7-5.5-2.2-.7 4.1-4.7ZM40 69.3l-.1 2.9 5.5 1v-3.8ZM29 69l.8-6-5.3-.6 1.6-6.2-4.8-1 2.8-6.2-4.1-1.6-3.4 6.5 2.3.7 2.5.6-2 6.5 5.2.7-1 6.3Zm-7.6-29.8 6.2-5.2 2.1 1.9 6.3-4.7-1.3-1.5 7.5-2.9-.3-.9-8 2.2.9 1.7-7.2 4.1-1.6-2.2-7.1 5 2.5 2.5-5.3 6.2 3.8 2 4.4-6.1Zm-3.7 33 5.5 1 .2-4.5-5.4-.4Zm28.7-19.5-.4 5.6h5v-5.5ZM28.8 72.2l5.5 1 .1-4L29 69ZM40.9 58l-.6 5.7-5.3-.3.9-5.8-5-.6-1.2 5.9 5.3.5-.5 5.8 5.5.1.4-5.6 5.3.1.3-5.6ZM15.4 26.1l9.6-3-.5 3.2 9.1-2.1-.1 2 8.4-1.4.2-1-8.4.4.6-2.1-9.3 1 1.5-3.4-9.9 1.8 2.8-5-11.2 3 5.1-7.3L0 16.5l1 6.6 7.2-3.6L6 26l10.5-4.5Zm30.1 43.2H51v-5.5h-5.3Zm-26.3-7.6-5.2-1-1.5 7.1 5.5.5ZM6.1 26 0 29.4l1 6.3 5-4.1Zm10.7 7.7 8-4.6-.4-2.9-8.9 4ZM6.6 72.2l5.5.7.4-5-5.4-.6Zm2.3-12.7L4 57.9l-2.2 8.4 5.3.8ZM3.6 47.3 1 56.7l2.9 1.2L7.6 50l4.3 2.1-3 7.3 5.1 1.2 2.5-6.9-4.6-1.7 4.1-6.8-3.4-2.4 6.2-6.2-2-3-7.2 6.2-2.3-3.7 8.3-5.9-.2-4.1L6 31.6l1.3 4.6L1 42.8v2.1l2.6 2.4 6-7.5 3 3.1-5 7.1Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><g clip-path="url(#fi235-f)"><use height="73.2" transform="matrix(1.0237 0 0 1 58.3 59.8)" width="51.1" xlink:href="#fi235-b"/><use height="73.2" transform="matrix(-1.0237 0 0 1 161.7 59.8)" width="51.1" xlink:href="#fi235-b"/><use height="73.2" transform="matrix(1.0237 0 0 -1 58.3 204.2)" width="51.1" xlink:href="#fi235-b"/><use height="73.2" transform="matrix(-1.0237 0 0 -1 161.7 204.2)" width="51.1" xlink:href="#fi235-b"/></g>'
                    )
                )
            );
    }

    function field_236(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Stepper',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '" id="fi236-a"/><clipPath id="fi236-b"><use overflow="visible" xlink:href="#fi236-a"/></clipPath><path clip-path="url(#fi236-b)" d="M160 139.5v3.75h-5V147h-4.52v3.75h-4.11v3.75h-3.76v3.75h-3.44V162H136v3.75h-2.92v3.75h-2.71v3.75h-2.51V177h-2.34v3.75h-2.18v3.75h-2.04l.01 3.75h-1.92V192h-1.8v5h-3.03v-5h1.7v-3.75h1.82v-3.75H120v-3.75h2.07V177h2.22v-3.75h2.38v-3.75h2.56v-3.75H132V162h3v-3.75h3.26v-3.75h3.56v-3.75h3.9V147H150v-3.75h4.74v-3.75H160zm-83.33 41.25h.57V177h.62v-3.75h.66v-3.75h.71v-3.75H80V162h.83v-3.75h.91v-3.75h.99v-3.75h1.08V147H85v-3.75h1.32v-3.75h1.46v-3.75h1.63V132h1.84v-3.75h2.08v-3.75h2.38v-3.75h2.75V117h3.2v-3.75h3.79v-3.75H110v-3.75h5.56V102h6.94v-3.75h8.93V94.5h11.9v-3.75H160V87h-20v3.75h-13.33v3.75h-9.52v3.75H110V102h-5.56v3.75H100v3.75h-3.64v3.75h-3.03V117h-2.56v3.75h-2.2v3.75h-1.9v3.75H85V132h-1.47v3.75h-1.31v3.75h-1.17v3.75H80V147h-.95v3.75h-.87v3.75h-.79v3.75h-.72V162H76v3.75h-.61v3.75h-.57v3.75h-.53V177h-.49v3.75h-.46V197h3.33v-16.25zm-5.96-7.5h.4v-3.75h.43v-3.75H72V162h.5v-3.75h.54v-3.75h.59v-3.75h.65V147H75v-3.75h.79v-3.75h.88v-3.75h.98V132h1.1v-3.75H80v-3.75h1.43v-3.75h1.65V117H85v-3.75h2.27v-3.75H90v-3.75h3.33V102h4.17v-3.75h5.36V94.5H110v-3.75h10V87h15v-3.75h25V79.5h-33.33v3.75H110V87h-10v3.75h-6.67v3.75h-4.76v3.75H85V102h-2.78v3.75H80v3.75h-1.82v3.75h-1.52V117h-1.28v3.75h-1.1v3.75h-.95v3.75h-.83V132h-.73v3.75h-.65v3.75h-.59v3.75H70V147h-.48v3.75h-.43v3.75h-.39v3.75h-.36V162H68v3.75h-.31v3.75h-.28V197h2.94v-20h.37v-3.75zM155.23 147v3.75h-4.33v3.75h-3.95v3.75h-3.62V162H140v3.75h-3.08v3.75h-2.85v3.75h-2.65V177h-2.46v3.75h-2.3v3.75h-2.15v3.75h-2.01V192h-1.89v5h3.03v-5h1.99v-3.75h2.12v-3.75H130v-3.75h2.41V177H135v-3.75h2.78v-3.75h2.99v-3.75H144V162h3.5v-3.75h3.8v-3.75h4.15v-3.75H160V147h-4.77zm4.77 15h-4v3.75h-3.69v3.75h-3.42v3.75h-3.18V177h-2.95v3.75H140v3.75h-2.58v3.75H135V197h5.65v-12.5h2.41l.28-.24v-3.51h2.87V177h3.08v-3.75h3.27l.04-.06v-3.69h7.4V162zm-4.35-7.5v3.75h-3.98V162H148v3.75h-3.38v3.75h-3.13v3.75h-2.91V177h-2.71v3.75h-2.53v3.75h-2.36v3.75h-2.22V192h-2.08v5h3.03v-5h2.12l.02-.01.04-.02v-3.72h2.32v-3.75h2.47v-3.75h2.64V177h2.83v-3.75h3.04v-3.75h3.28v-3.75H152V162h3.83v-3.75H160v-3.75h-4.35zm-1.53-22.5v3.75h-5.23v3.75h-4.68v3.75H140V147h-3.81v3.75h-3.46v3.75h-3.16v3.75h-2.9V162H124v3.75h-2.46v3.75h-2.28v3.75h-2.12V177h-1.97v3.75h-1.84v3.75h-1.72v3.75H110V192h-1.51v5h3.03v-5h1.61v-3.75h1.71v-3.75h1.83v-3.75h1.95V177h2.09v-3.75h2.25v-3.75h2.42v-3.75H128V162h2.83v-3.75h3.08v-3.75h3.36v-3.75h3.68V147H145v-3.75h4.47v-3.75h4.97v-3.75H160V132h-5.88zm-54.73 60h1.23v-3.75h1.31v-3.75h1.4v-3.75h1.49V177h1.6v-3.75h1.72v-3.75H110v-3.75h2V162h2.17v-3.75h2.36v-3.75h2.57v-3.75h2.81V147H125v-3.75h3.42v-3.75h3.8v-3.75h4.25V132h4.78v-3.75h5.42v-3.75h6.19v-3.75H160V117h-7.69v3.75h-6.59v3.75H140v3.75h-5V132h-4.41v3.75h-3.92v3.75h-3.51v3.75H120V147h-2.86v3.75h-2.6v3.75h-2.37v3.75H110V162h-2v3.75h-1.85v3.75h-1.71v3.75h-1.59V177h-1.48v3.75H100v3.75h-1.29v3.75H97.5V192h-1.14v5h3.03v-5zm6.06 0h1.42v-3.75h1.51v-3.75H110v-3.75h1.72V177h1.85v-3.75h1.98v-3.75h2.14v-3.75H120V162h2.5v-3.75h2.72v-3.75h2.96v-3.75h3.25V147H135v-3.75h3.95v-3.75h4.39v-3.75h4.9V132h5.52v-3.75H160v-3.75h-6.67v3.75h-5.83V132h-5.15v3.75h-4.58v3.75h-4.09v3.75H130V147h-3.33v3.75h-3.03v3.75h-2.77v3.75h-2.54V162H116v3.75h-2.15v3.75h-1.99v3.75H110V177h-1.72v3.75h-1.61v3.75h-1.51v3.75h-1.41V192h-1.33v5h3.03v-5zm-41.6-26.25H64V162h.17v-3.75h.18v-3.75h.2v-3.75h.22V147H65v-3.75h.26v-3.75h.29v-3.75h.33V132h.37v-3.75h.42v-3.75h.48v-3.75h.55V117h.64v-3.75h.76v-3.75h.9v-3.75h1.11V102h1.39v-3.75h1.79V94.5h2.38v-3.75H80V87h5v-3.75h8.33V79.5H110v-3.75h50V72H60v125h3.85v-31.25zm24.27 22.5h.91v-3.75H90v-3.75h1.04V177h1.11v-3.75h1.19v-3.75h1.28v-3.75H96V162h1.5v-3.75h1.63v-3.75h1.78v-3.75h1.95V147H105v-3.75h2.37v-3.75H110v-3.75h2.94V132h3.31v-3.75H120v-3.75h4.29v-3.75h4.95V117H135v-3.75h6.82v-3.75H150v-3.75h10V102h-11.11v3.75H140v3.75h-7.27v3.75h-6.06V117h-5.13v3.75h-4.4v3.75h-3.81v3.75H110V132h-2.94v3.75h-2.61v3.75h-2.34v3.75H100V147h-1.9v3.75h-1.74v3.75h-1.58v3.75h-1.45V162H92v3.75h-1.23v3.75h-1.14v3.75h-1.06V177h-.99v3.75h-.92v3.75h-.86v3.75H85V197h3.12v-8.75zm5.21 3.75h1.04v-3.75h1.11v-3.75h1.18v-3.75h1.26V177h1.35v-3.75h1.46v-3.75h1.57v-3.75h1.7V162h1.83v-3.75h1.99v-3.75H110v-3.75h2.38V147H115v-3.75h2.9v-3.75h3.22v-3.75h3.59V132h4.04v-3.75h4.58v-3.75h5.24v-3.75h6.04V117h7.05v-3.75H160v-3.75h-9.09v3.75h-7.58V117h-6.41v3.75h-5.49v3.75h-4.76v3.75h-4.17V132h-3.68v3.75h-3.27v3.75h-2.92v3.75H110V147h-2.38v3.75h-2.16v3.75h-1.98v3.75h-1.81V162H100v3.75h-1.54v3.75h-1.43v3.75h-1.32V177h-1.23v3.75h-1.15v3.75h-1.08v3.75h-1.01V192h-.94v5h3.03v-5zm-10.75-3.75v-3.75h.75v-3.75h.8V177H85v-3.75h.93v-3.75h1v-3.75H88V162h1.17v-3.75h1.27v-3.75h1.38v-3.75h1.52V147H95v-3.75h1.84v-3.75h2.05v-3.75h2.29V132h2.57v-3.75h2.92v-3.75H110v-3.75h3.85V117h4.49v-3.75h5.3v-3.75H130v-3.75h7.78V102h9.72v-3.75H160V94.5h-14.29v3.75H135V102h-8.33v3.75H120v3.75h-5.45v3.75H110V117h-3.85v3.75h-3.3v3.75H100v3.75h-2.5V132h-2.21v3.75h-1.96v3.75h-1.75v3.75H90V147h-1.43v3.75h-1.3v3.75h-1.18v3.75H85V162h-1v3.75h-.92v3.75h-.85v3.75h-.79V177h-.74v3.75H80v3.75h-.64V197h2.93l.29-8.75z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_237(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Bend Sinister Hand',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M148.895 75.878c-.1.15-.259.37-.382.543-.47.639-.906 1.302-1.307 1.986a78.652 78.652 0 0 1-6.94 10.522 41.154 41.154 0 0 0-6.049 9.776c-.334.779-.65 1.573-.966 2.37a26.252 26.252 0 0 1-2.019 4.362 31.08 31.08 0 0 1-2.546 3.132 85.693 85.693 0 0 0-1.593 1.839 51.649 51.649 0 0 1-5.252 5.516c-1.266 1.128-2.681 2.221-4.18 3.377-1.676 1.294-3.408 2.631-5.122 4.164a64.406 64.406 0 0 0-8.892 10.426c-1.054 1.436-2.048 2.792-3.072 4.071-2.042 2.553-3.888 4.834-5.8 6.9a36.06 36.06 0 0 0-3.032 3.9c-.477.68-.93 1.322-1.342 1.83-1.71 2.1-3.363 4.244-4.962 6.319-2.641 3.427-5.136 6.665-7.823 9.65a60.444 60.444 0 0 1-4.694 4.481c-.764.682-1.528 1.363-2.279 2.056a19.474 19.474 0 0 0-1.928 2.1 49.968 49.968 0 0 0 5.926 7.162 49.999 49.999 0 0 0 85.355-35.355v-75h-9.129a20.18 20.18 0 0 0-1.972 3.873Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_238(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pale Indented Hand',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M117.22 72c-.78.26-1.55.55-2.3.89-.91.41-1.66.62-2.82.87-3.71.34-6.87 3.31-10.02 4.54-5.92 1.4-6.47 8.77.56 10.36 4.57 1.58 8.58 1.5 13.11 2.39-.3.86-1.03 1.04-1.88 1.51-1.19.58-2.63 1.52-3.74 1.86-2.08.61-3.41 1.77-4.89 2.64-3.02.99-4.29 2.88-6.54 4.47l.55 2.96c.8 3.78 4.71 4.66 7.59 5.08 2.66 1.14 5.02 3.28 7.63 4.74-3.26 2.77-8.4 5.35-12.57 7.9-4.22 1.87-3.69 5.47-3.54 6.17.28 1.31 1.48 4.37 6.58 4.37 4.38.13 9.36 1.51 13.9 1.83-4.16 3.31-8.97 5.34-14.15 8.06-4.49 2.93-3.34 8.14 1.41 9.66 4.9 1.14 9.47 2.55 14.07 4.26-5.1 3.07-9.18 6.05-13.95 9.39-2.22 1.65-4.79 3.29-4.19 6.47.62 4.02 4.4 4.45 7.15 4.77a71.5 71.5 0 0 1 9.34 2.55v.97a106.23 106.23 0 0 0-8.71 8.52c-.87.9-3.33 3.32-1.95 6.68.16.38.37.73.61 1.05.52.02 1.03.04 1.55.04 5.13 0 10.17-.8 14.98-2.31l.02.01c1.62-.51 3.2-1.12 4.76-1.79l.2-.08c5.69-2.48 10.93-6 15.4-10.47A50.1 50.1 0 0 0 160 147V72h-42.78z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_239(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Pall Inverted Hand',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M149.94 153.4c-2.72-2.34-5.29-4.55-7.68-6.89-3.45-3.37-7.13-6.03-10.7-8.61-3.28-2.37-6.38-4.61-8.91-7.14-.18-.18-.38-.42-.61-.68-.6-.67-1.56-1.75-2.81-2.84l-.13-1.75-.1-1.34c0-3.15-.13-6.29-.25-9.33-.12-3.07-.24-5.96-.24-8.84 0-7.37-.37-14.72-.74-21.82-.2-4-.4-8.09-.54-12.16H99.24c.14 4.41.35 8.79.57 13.08.35 6.88.71 13.99.71 20.91 0 3.23.13 6.45.25 9.55.12 3.04.23 5.91.23 8.74 0 .6.04 1.23.15 2.58.04.59.13 1.7.19 2.74-.37.57-.67 1.1-.9 1.52l-.18.31c-.61 1.07-1.14 2.12-1.66 3.13-.85 1.68-1.73 3.41-2.53 4.27a231.22 231.22 0 0 0-11.3 13.45 820.2 820.2 0 0 1-3.24 4.05c-3.06 3.77-6.63 7.23-10.41 10.89a379.6 379.6 0 0 0-4.57 4.49 50.12 50.12 0 0 0 11.61 13.84 282.1 282.1 0 0 1 5.47-5.4c4-3.87 8.13-7.87 11.88-12.5 1.11-1.37 2.22-2.76 3.33-4.16a218.5 218.5 0 0 1 10.4-12.41 26.92 26.92 0 0 0 3.56-4.92c2.7 2.34 5.49 4.36 8.22 6.33 3.17 2.29 6.17 4.46 8.66 6.89 2.8 2.73 5.7 5.24 8.51 7.66 3.91 3.37 7.6 6.55 10.72 10.07l.54.57a49.9 49.9 0 0 0 8.61-16.97 193.3 193.3 0 0 0-8.12-7.31z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_240(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Orle Hand',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M108.44 185.56c-44.61 4.19-42.26-50.33-41.19-81.19 1.64-11.03-3.74-27.67 13.08-25.21 10.83.3 20.82-1.41 31.67-1.48 43.81.32 42.34-11.12 43.73 37.8-.78 12.05 1.68 24.71-1.96 36.37-7.24 20.2-22.31 36.39-45.33 33.71zm-28.6-94.4c.1 20.6-8.49 82.91 22.41 82.11 22.39 2.81 31.92-4.74 40.13-25.21 2.74-19.17 1.69-39.67-.24-58.95-20.78-.37-41.55 1.67-62.3 2.05z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_241(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Five Pallets Hand',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 100 0V72H60z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M128.58 84.24c1.25 27.19-5.28 54.31-3.58 81.45-.27 5.02-.31 10.38-.42 15.43.35 4.21-1.57 9.7 1.68 13.16a49.78 49.78 0 0 0 10.18-4.85c.87-18.43-.61-37.01 1.42-55.37.94-10.95 2.08-21.62 2.78-32.54.2-9.05-.54-20.57.27-29.52h-12a84.8 84.8 0 0 0-.33 12.24zM160 72h-9.01c-.14 18.25-2.06 36.28-2.13 54.01-.94 14.34-.75 28.16-.86 42.49-.11 2.57-.44 4.3-.7 6.5-.28.62-.35 2.68-.3 3.5 0 .07 0 1 .61 1.44a50.03 50.03 0 0 0 12.4-32.94L160 72zM90.05 192.23c.01-16.15 2.57-32.27 3.17-48.43.27-5.2.81-10.54 1.33-15.7 2.01-18.67 2.42-37.38 2.95-56.08h-12c-.42 38.01-5.08 75.66-7.35 113.53a49.83 49.83 0 0 0 11.86 7.28l.04-.6zM60 147c0 9.01 2.44 17.85 7.05 25.59.35-33.5 7.34-67.32.96-100.6h-8L60 147zm52.89 49.91c.63-6.43 1.79-12.76 2.7-19.27.54-14.26 1.28-28.47 2.26-42.69.56-20.66-.64-42.35 1.19-62.96h-12c-1.84 20.12-.7 41.6-1.13 61.82-.93 14.17-1.85 28.15-2.22 42.32-.93 6.57-2.18 13.31-2.77 20.02 3.94.74 7.96.99 11.97.76z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_242(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pall',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132v65a50 50 0 0 1-50-50V72l50 60Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M110 132v65a49.997 49.997 0 0 0 50-50V72l-50 60Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_243(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pall Inverted',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 132 38.786 46.544A49.788 49.788 0 0 0 160 147V72h-50v60Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M148.787 178.544 110 132l-38.787 46.545a49.974 49.974 0 0 0 17.31 13.606 49.979 49.979 0 0 0 60.264-13.606v-.001Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
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