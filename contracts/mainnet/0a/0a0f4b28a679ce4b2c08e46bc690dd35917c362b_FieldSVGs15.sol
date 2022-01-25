// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs15 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_218(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Infinigyron',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi218-a" viewBox="-10.22 -15.33 20.47 30.65"><path d="m10.26 14.25-7.9 1.07c-18.9-2.59-15.6-32.68 3.91-30.54C-8.04-8.56-4.3 12 10.26 14.25z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi218-b" viewBox="-29.59 -30.54 59.17 61.08"><use height="30.65" overflow="visible" transform="translate(-6.268 15.22)" width="20.47" x="-10.22" xlink:href="#fi218-a" y="-15.33"/><use height="30.65" overflow="visible" transform="rotate(60 -10.048 -13.038)" width="20.47" x="-10.22" xlink:href="#fi218-a" y="-15.33"/><use height="30.65" overflow="visible" transform="rotate(120 -1.26 -9.42)" width="20.47" x="-10.22" xlink:href="#fi218-a" y="-15.33"/><use height="30.65" overflow="visible" transform="rotate(180 3.134 -7.61)" width="20.47" x="-10.22" xlink:href="#fi218-a" y="-15.33"/><use height="30.65" overflow="visible" transform="rotate(-120 7.528 -5.801)" width="20.47" x="-10.22" xlink:href="#fi218-a" y="-15.33"/><use height="30.65" overflow="visible" transform="rotate(-60 16.316 -2.182)" width="20.47" x="-10.22" xlink:href="#fi218-a" y="-15.33"/></symbol><symbol id="fi218-e" viewBox="-29.59 -90.54 59.17 181.08"><use height="61.08" overflow="visible" width="59.17" x="-29.59" xlink:href="#fi218-b" y="-30.54"/><use height="61.08" overflow="visible" transform="translate(0 -60)" width="59.17" x="-29.59" xlink:href="#fi218-b" y="-30.54"/><use height="61.08" overflow="visible" transform="translate(0 60)" width="59.17" x="-29.59" xlink:href="#fi218-b" y="-30.54"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72h-50l-1.72.57L96.06 72H60z" id="fi218-c"/></defs><clipPath id="fi218-d"><use overflow="visible" xlink:href="#fi218-c"/></clipPath><g clip-path="url(#fi218-d)"><use height="181.08" overflow="visible" transform="matrix(.9615 0 0 -1 110 132)" width="59.17" x="-29.59" xlink:href="#fi218-e" y="-90.54"/><use height="181.08" overflow="visible" transform="matrix(.9615 0 0 -1 60 102)" width="59.17" x="-29.59" xlink:href="#fi218-e" y="-90.54"/><use height="181.08" overflow="visible" transform="matrix(.9615 0 0 -1 160 102)" width="59.17" x="-29.59" xlink:href="#fi218-e" y="-90.54"/></g>'
                    )
                )
            );
    }

    function field_219(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Laser',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M107.166 196.915 110 132l2.834 64.915c-.938.053-1.882.085-2.834.085-.952 0-1.9-.032-2.834-.085Zm16.8-1.907L110 132l8.462 64.273a49.878 49.878 0 0 0 5.506-1.265h-.002Zm10.343-4.317L110 132l19.278 61.143a49.743 49.743 0 0 0 5.033-2.452h-.002Zm9-6.41L110 132l29 55.715a50.436 50.436 0 0 0 4.307-3.434h.002Zm7.236-8.035L110 132l37.168 48.438a50.132 50.132 0 0 0 3.375-4.192h.002Zm-77.711 4.192L110 132l-40.543 44.245a50.066 50.066 0 0 0 3.375 4.193h.002ZM81 187.715 110 132l-33.307 52.281A50.117 50.117 0 0 0 81 187.715Zm9.725 5.428L110 132l-24.311 58.691c1.63.911 3.31 1.73 5.032 2.452h.004Zm69.26-45.384L110 132l49.683 20.579c.176-1.586.275-3.193.298-4.82h.004Zm.015-17.942L110 132l50 2.183v-4.366Zm0-8.9L110 132l50-6.583v-4.5Zm0-9.626L110 132l50-15.765v-4.944Zm0-11.143L110 132l50-26.029v-5.823Zm-1.1 57.308L110 132l47.6 30.323c.516-1.6.95-3.225 1.3-4.869v.002Zm-3.125 9.668L110 132l43.418 39.785a49.516 49.516 0 0 0 2.354-4.663l.003.002ZM160 138.583 110 132l50 11.085v-4.502Zm-93.418 33.2L110 132l-45.772 35.122a49.807 49.807 0 0 0 2.354 4.663v-.002Zm34.956 24.488L110 132l-13.969 63.008c1.81.525 3.649.947 5.507 1.265v-.002ZM96.7 72l13.3 60-7.9-60h-5.4Zm-24.924 0L110 132 78.766 72h-6.99Zm35.6 0L110 132l2.62-60h-5.244Zm-22.229 0L110 132 91.082 72h-5.935Zm32.753 0-7.9 60 13.3-60h-5.4Zm42.1 0h-3.96L110 132l50-54.566V72Zm0 14.183L110 132l50-38.367v-7.45ZM141.234 72 110 132l38.224-60h-6.99Zm-12.316 0L110 132l24.853-60h-5.935ZM60 125.417 110 132l-50-11.085v4.502Zm0 17.668L110 132l-50 6.583v4.502Zm0-8.9L110 132l-50-2.183v4.368ZM60 72v5.435L110 132 63.96 72H60Zm.317 80.579L110 132l-49.981 15.759c.024 1.627.123 3.234.298 4.82Zm2.085 9.744L110 132l-48.9 25.454c.35 1.644.784 3.269 1.3 4.869h.002ZM60 93.634 110 132 60 86.183v7.451Zm0 12.337L110 132l-50-31.853v5.824Zm0 10.264L110 132l-50-20.711v4.946Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_220(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Laser and Boxes Countercharged',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><clipPath id="fi220-a"><path d="M60,72v75a50,50,0,0,0,100,0V72Z" fill="none"/></clipPath><symbol id="fi220-c" viewBox="0 0 66.831 52.04"><path d="M12.511,41.49,0,51.026,12.511,39.67Zm12.5-6.44v-3.1l-12.5,9.55v1.55Zm12.5-18.12L25.011,28.3v3.65l12.5-9.55Zm0,32.74v1.37l29.32,1V48.6Zm29.32-21.71L37.511,38.08v3.09l29.32-7.7ZM37.511,46.92l29.32-3.22V38.69L37.511,44.1Zm0-12.16,29.32-12.72V15.55L37.511,31.12Zm-25,14.9L0,51.026l12.511-.456Zm0-4.05,12.5-5.42V37.77l12.5-6.65V27.05L66.831,8.3V0L37.511,22.4v4.66l-12.5,7.99v2.71l-12.5,6.64V43.05L0,51.026,12.511,44.4Zm0,2.13L0,51.026,12.511,48.72Zm0,0,12.5-3.29V42.39l12.5-4.32V34.75l-12.5,5.42v2.21l-12.5,4.31v-1.1L0,51.026,12.511,46.69Zm25-6.56-12.5,3.28v1.95l12.5-2.31Zm0,8.49V46.92l-12.5,1.37v1.83Zm-12.5-3.26-12.5,2.31v.94l12.5-1.37Zm-12.5,4.62,12.5,1V50.12l-12.5.46Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi220-b" viewBox="0 0 67.841 67.841"><path d="M23.76,41.821l-11.37,12.5h1.13v1.13l12.5-11.37v-2.26Zm14.76-9.11L67.84,6.051V0H62.55L35.13,29.321h3.39Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><use height="52.04" transform="translate(1.01 15.801)" width="66.831" xlink:href="#fi220-c"/><use height="52.04" transform="matrix(0, -1, -1, 0, 52.04, 66.831)" width="66.831" xlink:href="#fi220-c"/></symbol></defs><path d="M60,72v75a50,50,0,0,0,100,0V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi220-a)"><use height="67.841" transform="matrix(1, 0, 0, -1, 108.99, 198.828)" width="67.841" xlink:href="#fi220-b"/><use height="67.841" transform="translate(108.99 65.172)" width="67.841" xlink:href="#fi220-b"/><use height="67.841" transform="translate(111.01 198.828) rotate(180)" width="67.841" xlink:href="#fi220-b"/><use height="67.841" transform="matrix(-1, 0, 0, 1, 111.01, 65.172)" width="67.841" xlink:href="#fi220-b"/></g>'
                    )
                )
            );
    }

    function field_221(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quadrobeams',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi221-b" viewBox="-25 -68.49 50 106.98"><path d="M25 30.69 0-38.49 25 5.12zm-25 7.8v-76.98l13.27 75.81zm-25-7.8L0-38.49l-13.27 75.81zm14.16-99.18L0-38.49l-17.2-30z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M0-68.49v30l-5.25-30zm10.84 0L0-38.49l5.25-30z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><use height="30" overflow="visible" transform="translate(0 -23.49)" width="50" x="-25" xlink:href="#fi221-a" y="-15"/><use height="30" overflow="visible" transform="rotate(180 0 -26.745)" width="50" x="-25" xlink:href="#fi221-a" y="-15"/></symbol><symbol id="fi221-a" viewBox="-25 -15 50 30"><path d="M25-10.56 0-15h25zm0 10.1L0-15l25 9.16zM25 15 0-15 25 6.13zm-50 0L0-15l-17.2 30zm0-15.46L0-15-25 6.13zm0-10.1L0-15l-25 9.17z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi221-e" viewBox="-25 -30 50 106.98"><use height="106.98" overflow="visible" transform="translate(0 38.49)" width="50" x="-25" xlink:href="#fi221-b" y="-68.49"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi221-c"/></defs><clipPath id="fi221-d"><use overflow="visible" xlink:href="#fi221-c"/></clipPath><g clip-path="url(#fi221-d)"><use height="106.98" overflow="visible" transform="matrix(1 0 0 -1 135 102)" width="50" x="-25" xlink:href="#fi221-e" y="-30"/><use height="106.98" overflow="visible" transform="matrix(-1 0 0 1 135 162)" width="50" x="-25" xlink:href="#fi221-e" y="-30"/><use height="106.98" overflow="visible" transform="rotate(180 42.5 51)" width="50" x="-25" xlink:href="#fi221-e" y="-30"/><use height="106.98" overflow="visible" transform="translate(85 162)" width="50" x="-25" xlink:href="#fi221-e" y="-30"/></g>'
                    )
                )
            );
    }

    function field_222(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Laserwheels',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi222-a" viewBox="-1.3 -7.5 2.6 15"><path d="M-1.3 7.27 1.3-7.5v15z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi222-b" viewBox="-7.51 -14.89 15 29.92"><use height="15" overflow="visible" transform="translate(6.18 7.45) scale(1.0097)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/><use height="15" overflow="visible" transform="rotate(20 -16.53 13.75)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/><use height="15" overflow="visible" transform="rotate(40 -5.74 4.7)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/><use height="15" overflow="visible" transform="rotate(60 -2 1.55)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/><use height="15" overflow="visible" transform="rotate(80 0 -.12)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/><use height="15" overflow="visible" transform="rotate(100 1.3 -1.21)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/><use height="15" overflow="visible" transform="rotate(120 2.27 -2.02)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/><use height="15" overflow="visible" transform="rotate(140 3.05 -2.68)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/><use height="15" overflow="visible" transform="rotate(160 3.75 -3.26)" width="2.6" x="-1.3" xlink:href="#fi222-a" y="-7.5"/></symbol><symbol id="fi222-i" viewBox="-100.01 -57.72 200.01 115.44"><path d="M1.32-19.74zm10.29-12.81zm-.69 15.14z"/><use height="29.92" overflow="visible" transform="matrix(-1 0 0 1 32.5 -12.16)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="matrix(1 0 0 -1 17.51 -12.4)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="translate(-32.49 -12.16)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="rotate(180 -8.75 -6.2)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="rotate(180 1.97 -6.17) scale(.525)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="matrix(.525 0 0 .525 -3.93 -12.22)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="rotate(-90 -31.65 -6.7) scale(.525)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="rotate(-90 -6.64 -31.7) scale(.525)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><defs><path d="M0 57.72v-62.5a7.5 7.5 0 0 0 0-15v-7.5a15 15 0 0 0 15-15h2.5a7.5 7.5 0 0 0 15 0H100v100H0zm25-85a15 15 0 1 0 0 30 15 15 0 0 0 0-30z" id="fi222-c"/></defs><clipPath id="fi222-d"><use overflow="visible" xlink:href="#fi222-c"/></clipPath><g clip-path="url(#fi222-d)"><use height="29.92" overflow="visible" transform="matrix(3 0 0 3 2.52 -11.92)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="matrix(-3 0 0 -3 47.49 -12.64)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/></g><defs><path d="M-100 57.72v-100h67.5a7.5 7.5 0 0 0 15 0h2.5a15 15 0 0 0 15 15v7.5a7.5 7.5 0 0 0 0 15v62.5h-100zm60-70a15 15 0 1 0 30 0 15 15 0 0 0-30 0z" id="fi222-e"/></defs><clipPath id="fi222-f"><use overflow="visible" xlink:href="#fi222-e"/></clipPath><g clip-path="url(#fi222-f)"><use height="29.92" overflow="visible" transform="matrix(-3 0 0 3 -2.52 -11.92)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/><use height="29.92" overflow="visible" transform="matrix(3 0 0 -3 -47.49 -12.64)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/></g><use height="29.92" overflow="visible" transform="matrix(0 -1.0249 -1.0249 0 -.12 -34.6)" width="15" x="-7.51" xlink:href="#fi222-b" y="-14.89"/></symbol><path d="M60 72v75a50 50 0 1 0 100 0V72H60z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '" id="fi222-g"/><clipPath id="fi222-h"><use overflow="visible" xlink:href="#fi222-g"/></clipPath><g clip-path="url(#fi222-h)"><use height="115.44" overflow="visible" transform="matrix(1 0 0 -1 110 89.72)" width="200.01" x="-100.01" xlink:href="#fi222-i" y="-57.72"/></g><g clip-path="url(#fi222-h)"><use height="115.44" overflow="visible" transform="matrix(-1 0 0 1 110 174.28)" width="200.01" x="-100.01" xlink:href="#fi222-i" y="-57.72"/></g>'
                    )
                )
            );
    }

    function field_223(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyronny and Orly',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi223-a" viewBox="-25.99 -62.5 50.99 125"><path d="m-9.99 7.32 5 1.61V-3.5c0-.14-.02-.28-.02-.42l-5 1.61c-.06-3.34-1.24-6.56-3.34-9.14l3.88-4.65C-6.66-12.65-5.09-8.36-5-3.91L.01-5.52c0 .18.01.35.01.53v15.54l-5-1.61V26.5l-5-6V7.32zm-5.36 31.18H5.01l5 6h-23.75zm-3.21-12h13.57l5 6h-16.96z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M-14.99-.5c0-.07-.01-.14-.01-.21l-9.99 3.21 7.76-9.31A9.915 9.915 0 0 1-15-.71l4.99-1.61c0 .11.02.21.02.32v9.32l-5-1.61V-.5zm15 11.04 5 1.61V38.5l-5-6zm10 3.22 5 1.6V50.5l-5-6z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m-21.66-9.92 1.66-6.21c-1.6-.57-3.29-.87-4.99-.87l-1-3.77 1-2.73c2.25 0 4.5.39 6.66 1.16L-20-16.13c2.6.92 4.9 2.53 6.64 4.67l-3.88 4.65c-1.16-1.42-2.69-2.5-4.42-3.11L-24.99 2.5l-1-8.68 1-4.32c1.12 0 2.25.19 3.33.58zm-3.33 36.42-1-6h5.82l1.61 6zm15-6h-10.18l-1.61-6h6.79zm-5-6-10-12 10 3.22z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m-25.99 14.5 1-12 3.21 12zm20.4-35.27 3.87-4.65A29.83 29.83 0 0 1 4.99-7.14l-5 1.61a24.916 24.916 0 0 0-5.58-15.24zm-.01 0zm-12.74-1.57 1.67-6.23c4.34 1.53 8.17 4.23 11.07 7.8l-3.88 4.66a19.898 19.898 0 0 0-8.86-6.23zm-6.65-14.16c3.38 0 6.76.57 9.99 1.71l-1.67 6.22C-19.34-29.52-22.16-30-25-30l-1-3.69 1.01-2.81zm11.65-4.5c-3.74-1.32-7.69-2-11.66-2l-1-4.2 1-2.3c4.51 0 9.01.76 13.32 2.28L-13.34-41zm4.98-18.65-1.67 6.21c-4.84-1.7-9.9-2.56-14.96-2.56l-1-3.56 1-2.94c5.62 0 11.25.95 16.63 2.85zm-6.99 98.15h-9.64l-1-6h9.03zM10.01-8v21.76l-5-1.61V-6.5c0-.21-.01-.43-.02-.64l5-1.61c0 .25.02.5.02.75z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M-1.72-25.43A30.034 30.034 0 0 0-15-34.79l1.67-6.21A35.064 35.064 0 0 1 2.16-30.08l3.88-4.65c5.62 6.9 8.77 15.48 8.95 24.38l-5 1.61a34.8 34.8 0 0 0-7.83-21.33l-3.88 4.64zM20.01-11v27.97l-5-1.61V-9.5c0-.29-.02-.57-.02-.85l5-1.61c0 .32.02.64.02.96zm-5 61.5 4.98 5.98V16.97l5 1.61V62.5l-5-6h-30.51l-1.61-6zm-25.53 6 1.6 6h-16.07l-1-6z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M6.04-34.74a40.18 40.18 0 0 0-17.71-12.48l1.67-6.21c7.8 2.76 14.69 7.62 19.92 14.04l3.88-4.65a49.936 49.936 0 0 1 11.18 30.48l-5 1.61A44.86 44.86 0 0 0 9.92-39.38l-3.88 4.64zM-24.99 50.5l-1-6h12.25l1.61 6h-12.86z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><use height="125" overflow="visible" transform="matrix(1.0003 0 0 -1 135 134.5)" width="50.99" x="-25.99" xlink:href="#fi223-a" y="-62.5"/><use height="125" overflow="visible" transform="matrix(-1.0003 0 0 -1 85 134.5)" width="50.99" x="-25.99" xlink:href="#fi223-a" y="-62.5"/>'
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