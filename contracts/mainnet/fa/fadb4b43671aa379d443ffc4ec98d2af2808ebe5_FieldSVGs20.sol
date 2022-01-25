// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs20 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_263(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Rising Sun on a Chief',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 72H60v30h100V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M110 102h30l-18.372-3.062 17.349-4.702-18.141 1.745L135.981 87l-16.676 6.329 11.908-12.542-14.073 10.377L125 76.019l-10.512 13.614 3.277-16.611-6.234 15.818L110 72l-1.531 16.84-6.234-15.818 3.276 16.611L95 76.019l7.86 15.145-14.073-10.377 11.908 12.542L84.019 87l15.145 8.981-18.142-1.745 17.349 4.702L80 102h30Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_264(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tierces and Three Quatrefoils',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M107.7 112.3c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2Zm0 30c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2Zm0 30c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M60 147V72h25v118.3c-15.5-8.9-25-25.4-25-43.3Zm100 0V72h-25v118.3c15.5-8.9 25-25.4 25-43.3Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_265(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Three Quatrefoils on a Bend',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m134 72-72.5 87c3.4 13.8 12.6 25.6 25.2 32.2l73.3-88V72h-26Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M132.7 112.3c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2ZM107.7 142.3c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2ZM82.7 172.3c-1.2-.7-1.8-1.6-1.8-2.8 0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7-1.3 0-2.1-.6-2.8-1.8-.5-.8-1-1.8-2.2-2.3 1.2-.5 1.7-1.6 2.2-2.3.7-1.2 1.6-1.8 2.8-1.8 1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4 0-1.3.6-2.1 1.8-2.8.8-.5 1.8-1 2.3-2.2.5 1.2 1.6 1.7 2.3 2.2 1.2.7 1.8 1.6 1.8 2.8 0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7 1.3 0 2.1.6 2.8 1.8.5.8 1 1.8 2.2 2.3-1.2.5-1.7 1.6-2.2 2.3-.7 1.2-1.6 1.8-2.8 1.8-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4 0 1.3-.6 2.1-1.8 2.8-.8.5-1.8 1-2.3 2.2-.5-1.2-1.6-1.7-2.3-2.2Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_266(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Saltire on a Canton',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M109.998 72H60v60.003h49.998V72Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M109.998 72H104.791L84.999 95.753 65.207 72h-5.206l-.001.001v6.248l19.792 23.753L60 125.755v6.248h5.208l19.791-23.752 19.792 23.752h5.207v-6.248l-19.792-23.753 19.792-23.753V72Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_267(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Gyronny Saltire',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M140.475 72 110 108.57 79.525 72H60v23.43L90.475 132l-27.244 32.693a50.152 50.152 0 0 0 19.094 23.948L110 155.431l27.674 33.21a50.14 50.14 0 0 0 19.094-23.949L129.525 132 160 95.431V72h-19.525Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M109.966 132 160 72v23.431L129.525 132h-19.559Zm27.708 56.641a50.256 50.256 0 0 0 11.108-10.091L109.966 132l.034 23.431 27.674 33.21ZM79.46 72H60v.077L109.966 132l-.034-23.431L79.46 72Zm-16.251 92.637a49.946 49.946 0 0 0 7.975 13.871L109.966 132H90.407l-27.198 32.637Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_268(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Eight-pointed Star on a Cross and Saltire Engrailed',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi268-a" viewBox="-5.75 -9.33 13 18.66"><path d="M2.08 8.33c0-5.61-4.31-8.34-7.83-8.34 4.6.01 7.83-3.72 7.83-8.31l5.17-1V9.33l-5.17-1z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi268-b" viewBox="-5.75 -75.96 13 168.59"><use height="18.66" overflow="visible" transform="translate(0 -66.634)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" transform="translate(0 -49.976)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" transform="translate(0 -33.317)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" transform="translate(0 -16.659)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" transform="translate(0 16.659)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" transform="translate(0 33.317)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" transform="translate(0 49.976)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" transform="translate(0 66.634)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/><use height="18.66" overflow="visible" transform="translate(0 83.293)" width="13" x="-5.75" xlink:href="#fi268-a" y="-9.33"/></symbol><symbol id="fi268-e" viewBox="-12 -75.96 24 168.59"><use height="168.59" overflow="visible" transform="translate(-6.25)" width="13" x="-5.75" xlink:href="#fi268-b" y="-75.96"/><use height="168.59" overflow="visible" transform="matrix(-1 0 0 1 6.25 0)" width="13" x="-5.75" xlink:href="#fi268-b" y="-75.96"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi268-c"/></defs><clipPath id="fi268-d"><use overflow="visible" xlink:href="#fi268-c"/></clipPath><g clip-path="url(#fi268-d)"><use height="168.59" overflow="visible" transform="matrix(1 0 0 -1 110 132.01)" width="24" x="-12" xlink:href="#fi268-e" y="-75.96"/><use height="168.59" overflow="visible" transform="matrix(0 -1 -1 0 110 132.01)" width="24" x="-12" xlink:href="#fi268-e" y="-75.96"/><use height="168.59" overflow="visible" transform="rotate(140.282 31.164 85.86)" width="24" x="-12" xlink:href="#fi268-e" y="-75.96"/><use height="168.59" overflow="visible" transform="matrix(.7692 .639 .639 -.7692 110 131.99)" width="24" x="-12" xlink:href="#fi268-e" y="-75.96"/></g><path d="m115.17 134.42 9.27 14.92-12.26-11.3L110 155.8l-2.18-17.76-12.26 11.3 9.27-14.92L85.54 132l19.29-2.43-9.27-14.92 12.26 11.3 2.18-17.76 2.18 17.76 12.26-11.3-9.27 14.92 19.29 2.43-19.29 2.42z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_269(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cross and Saltire II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M160 123.5h-41.5V72h-17v51.5H60v17h41.5V197h17v-56.5H160v-17Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m98.284 132-32.293 38.748a50.186 50.186 0 0 0 11.545 14.263L110 146.057l32.464 38.955a50.22 50.22 0 0 0 11.545-14.263L121.714 132 160 86.06V72h-11.716L110 117.941 71.714 72H60v14.06L98.284 132Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_270(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Saltire Engrailed on a Saltire',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 102.32 84.731 72H60v29.68L85.266 132l-23.5 28.193a50.1 50.1 0 0 0 24.007 30.55L110 161.677l24.222 29.065a50.095 50.095 0 0 0 24.006-30.549l-23.5-28.2L160 101.678V72h-24.733L110 102.32Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M150.7 174.1c-2.8-3.5-2.4-8.6 1-11.5-3.5 3-8.8 2.7-11.8-.8s-2.7-8.7.7-11.7c-3.6 2.6-8.5 1.9-11.3-1.6-2.9-3.5-2.4-8.6 1-11.5-3.5 2.9-8.8 2.4-11.7-1.1-1-1.1-1.5-2.4-1.8-3.7.3-1.4.9-2.7 1.8-3.8 2.9-3.6 8.2-4 11.7-1.1l-.2-.2c-3.5-3-3.9-8.3-.9-11.8s8.3-3.9 11.8-.9c0-.1-.1-.1-.2-.2-3.5-3.1-3.9-8.3-.9-11.8 3.1-3.5 8.3-3.9 11.8-.9-3.5-2.9-4-8.1-1.1-11.6 2.3-2.9 6.1-3.8 9.4-2.5v-1.7c-.9-2.1-1-4.6 0-6.7v-7h-5.2c-2.9 3.3-8 3.6-11.4.8 3.6 2.9 4 8.2 1.1 11.7-2.9 3.6-8.2 4-11.7 1.1 3.3 3 3.8 8 1 11.5s-7.8 4.1-11.3 1.6c3.4 3.1 3.7 8.3.7 11.7-3.1 3.5-8.3 3.8-11.8.8 3.3 2.9 3.8 8 1 11.5-.6.8-1.3 1.4-2.1 1.9-.8-.5-1.5-1.1-2.1-1.9-2.9-3.5-2.4-8.6 1-11.5-3.6 2.9-8.8 2.3-11.7-1.3-2.8-3.5-2.4-8.6 1-11.5-3.6 2.9-8.8 2.3-11.7-1.3-2.8-3.5-2.4-8.6 1-11.5-3.5 2.9-8.8 2.4-11.7-1.1-2.9-3.5-2.4-8.8 1.1-11.7-3.4 2.8-8.5 2.4-11.4-.8H60v6.4c1.3 2.5 1.3 5.5 0 7.9v1.2c3.3-1.4 7.3-.6 9.7 2.4 2.8 3.5 2.4 8.7-1.1 11.6 3.5-3 8.8-2.6 11.8.9s2.6 8.8-.9 11.8c0 0 0 .1-.1.1 3.5-2.9 8.7-2.4 11.7 1 3 3.5 2.6 8.8-.9 11.8l-.2.2c3.5-2.9 8.8-2.4 11.7 1.1 1 1.1 1.5 2.4 1.8 3.7-.3 1.3-.9 2.6-1.8 3.7-2.9 3.6-8.2 4-11.7 1.1 3.6 2.9 4 8.2 1.1 11.7-2.8 3.5-7.8 4-11.3 1.4 3.4 3.1 3.7 8.2.7 11.7-3.1 3.5-8.3 3.8-11.8.8 3.3 3 3.8 8 1 11.5-.3.4-.7.7-1 1 1.7 2.5 3.7 4.9 5.8 7.1.3-1 .9-2 1.6-2.8 3-3.5 8.3-3.9 11.8-.9-3.5-3-4-8.2-1.1-11.7 2.9-3.6 8.1-4.1 11.7-1.2l-.2-.2c-3.5-3-3.9-8.3-.9-11.8s8.3-3.9 11.8-.9c-3.6-2.9-4-8.2-1.1-11.7.6-.7 1.3-1.3 2.1-1.8.8.5 1.5 1.1 2.1 1.8 2.9 3.5 2.4 8.8-1.1 11.7 3.5-3 8.8-2.6 11.8.9s2.6 8.8-.9 11.8l-.2.2c3.5-2.9 8.8-2.4 11.7 1.2 2.9 3.6 2.4 8.8-1.1 11.7 3.5-3 8.8-2.6 11.8.9.7.8 1.1 1.6 1.5 2.5 2.1-2.2 4-4.5 5.7-7-.3-.1-.6-.4-.8-.7Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_271(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Saltire and a Saltire',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M148.787 178.544 110 132l50-60v75a49.787 49.787 0 0 1-11.213 31.544ZM60 147a49.788 49.788 0 0 0 11.213 31.545L110 132 60 72v75Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m98.284 132-32.293 38.748a50.186 50.186 0 0 0 11.545 14.263L110 146.057l32.464 38.955a50.22 50.22 0 0 0 11.545-14.263L121.714 132 160 86.06V72h-11.716L110 117.941 71.714 72H60v14.06L98.284 132Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_272(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly, Perfect and Quarterly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M160 147c0 13.26-5.27 25.98-14.65 35.35A49.969 49.969 0 0 1 110 197a50.001 50.001 0 0 1-50-50V72h100v75z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132V72h50v60h-50zm-50 15a50.001 50.001 0 0 0 50 50v-65H60v15z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M110 72h25v30h-25V72zm25 60h25v-30h-25v30zm-50 0H60v15c0 5.09.78 10.15 2.31 15H85v-30zm25 30H85v28.29c7.6 4.39 16.22 6.71 25 6.71v-35z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_273(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly, Perfect and Check',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 147a50.001 50.001 0 0 0 50 50c13.26 0 25.98-5.27 35.35-14.65A49.969 49.969 0 0 0 160 147V72H60v75z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M85 147H72.5v15H85v-15zm-12.5-15v15H60v-15h12.5zM85 177v13.29a50.307 50.307 0 0 1-12.5-10.24c-.87-.99-1.71-2-2.5-3.06-.79-1.05-1.51-2.12-2.21-3.22-.09-.14-.18-.27-.26-.41-.66-1.07-1.29-2.16-1.87-3.28-.09-.16-.17-.33-.25-.5-.58-1.14-1.12-2.3-1.61-3.48-.04-.1-.08-.21-.12-.32-.51-1.24-.97-2.51-1.38-3.8h10.2v15L85 177zm25 20c-4.22 0-8.42-.53-12.5-1.57V177H110v20zm50-110v15h-12.5V87H160zm-50-15h12.5v15H110V72zm25 0h12.5v15H135V72zm25 45v15h-12.5v-15H160zm-62.5 45v15H85v-15h12.5zm0-15H85v-15h12.5v15zm12.5 0v15H97.5v-15H110zm25-45h12.5v15H135v-15zm-12.5 0V87H135v15h-12.5zM110 117v-15h12.5v15H110zm12.5 0H135v15h-12.5v-15z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M60 72h50v60H60V72zm100 75c0 13.26-5.27 25.98-14.65 35.35A49.969 49.969 0 0 1 110 197v-65h50v15z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_274(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly, Perfect and a Bend Sinister',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132V72h50v60h-50Zm-50 15a49.997 49.997 0 0 0 50 50v-65H60v15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M146.982 72H160v15.621L123.017 132H110v-15.621L146.982 72ZM110 132H96.982L65.5 169.775a49.942 49.942 0 0 0 9.142 12.58 50.003 50.003 0 0 0 3.652 3.309L110 147.627V132Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_275(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly, Perfect and Per Bend Sinister',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 132V72h50v60h-50Zm-50 15a49.997 49.997 0 0 0 50 50v-65H60v15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M71.213 178.545 110 132v65a49.93 49.93 0 0 1-38.788-18.455ZM160 132V72l-50 60h50Z" fill="#',
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