// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs9 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_171(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Three Quatrefoils',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M82.7 112.216a3.115 3.115 0 0 1-1.8-2.8c0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7a3.015 3.015 0 0 1-2.8-1.8 4.85 4.85 0 0 0-2.2-2.3 5.331 5.331 0 0 0 2.2-2.3 3.119 3.119 0 0 1 2.8-1.8c1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4a3.017 3.017 0 0 1 1.8-2.8 4.85 4.85 0 0 0 2.3-2.2 5.331 5.331 0 0 0 2.3 2.2 3.119 3.119 0 0 1 1.8 2.8c0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7a3.018 3.018 0 0 1 2.8 1.8 4.85 4.85 0 0 0 2.2 2.3 5.331 5.331 0 0 0-2.2 2.3 3.122 3.122 0 0 1-2.8 1.8c-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4a3.017 3.017 0 0 1-1.8 2.8 4.852 4.852 0 0 0-2.3 2.2 5.333 5.333 0 0 0-2.3-2.2Zm25 60a3.118 3.118 0 0 1-1.8-2.8c0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7a3.016 3.016 0 0 1-2.8-1.8 4.85 4.85 0 0 0-2.2-2.3 5.331 5.331 0 0 0 2.2-2.3 3.119 3.119 0 0 1 2.8-1.8c1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4a3.016 3.016 0 0 1 1.8-2.8 4.852 4.852 0 0 0 2.3-2.2 5.333 5.333 0 0 0 2.3 2.2 3.118 3.118 0 0 1 1.8 2.8c0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7a3.016 3.016 0 0 1 2.8 1.8 4.852 4.852 0 0 0 2.2 2.3 5.333 5.333 0 0 0-2.2 2.3 3.118 3.118 0 0 1-2.8 1.8c-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4a3.016 3.016 0 0 1-1.8 2.8 4.852 4.852 0 0 0-2.3 2.2 5.333 5.333 0 0 0-2.3-2.2Zm25-60a3.118 3.118 0 0 1-1.8-2.8c0-1.5.7-2.2 1.7-3.4.5-.5.2-1.1-.2-1.5-.4-.4-1-.7-1.5-.2-1.2 1.1-1.8 1.7-3.4 1.7a3.016 3.016 0 0 1-2.8-1.8 4.852 4.852 0 0 0-2.2-2.3 5.333 5.333 0 0 0 2.2-2.3 3.115 3.115 0 0 1 2.8-1.8c1.5 0 2.2.7 3.4 1.7.5.5 1.1.2 1.5-.2.4-.4.7-1 .2-1.5-1.1-1.2-1.7-1.8-1.7-3.4a3.015 3.015 0 0 1 1.8-2.8 4.85 4.85 0 0 0 2.3-2.2 5.331 5.331 0 0 0 2.3 2.2 3.122 3.122 0 0 1 1.8 2.8c0 1.5-.7 2.2-1.7 3.4-.5.5-.2 1.1.2 1.5.4.4 1 .7 1.5.2 1.2-1.1 1.8-1.7 3.4-1.7a3.018 3.018 0 0 1 2.8 1.8 4.852 4.852 0 0 0 2.2 2.3 5.333 5.333 0 0 0-2.2 2.3 3.118 3.118 0 0 1-2.8 1.8c-1.5 0-2.2-.7-3.4-1.7-.5-.5-1.1-.2-1.5.2-.4.4-.7 1-.2 1.5 1.1 1.2 1.7 1.8 1.7 3.4a3.016 3.016 0 0 1-1.8 2.8 4.852 4.852 0 0 0-2.3 2.2 5.333 5.333 0 0 0-2.3-2.2Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_172(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Semy of Roundels',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi172-a" viewBox="-17.5 -5 35 10"><circle cx="-12.5" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" r="5"/><circle cx="12.5" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" r="5"/></symbol><symbol id="fi172-c" viewBox="-30 -5 60 10"><circle cx="-25" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" r="5"/><circle fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" r="5"/><circle cx="25" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" r="5"/></symbol><symbol id="fi172-b" viewBox="-42.5 -5 85 10"><use height="10" overflow="visible" transform="translate(-25)" width="35" x="-17.5" xlink:href="#fi172-a" y="-5"/><use height="10" overflow="visible" transform="translate(25)" width="35" x="-17.5" xlink:href="#fi172-a" y="-5"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><use height="10" overflow="visible" transform="matrix(1 0 0 -1 110 87)" width="85" x="-42.5" xlink:href="#fi172-b" y="-5"/><use height="10" overflow="visible" transform="matrix(1 0 0 -1 110 102)" width="60" x="-30" xlink:href="#fi172-c" y="-5"/><use height="10" overflow="visible" transform="matrix(1 0 0 -1 110 117)" width="85" x="-42.5" xlink:href="#fi172-b" y="-5"/><use height="10" overflow="visible" transform="matrix(1 0 0 -1 110 132)" width="60" x="-30" xlink:href="#fi172-c" y="-5"/><use height="10" overflow="visible" transform="matrix(1 0 0 -1 110 147)" width="85" x="-42.5" xlink:href="#fi172-b" y="-5"/><use height="10" overflow="visible" transform="matrix(1 0 0 -1 110 162)" width="60" x="-30" xlink:href="#fi172-c" y="-5"/><use height="10" overflow="visible" transform="matrix(1 0 0 -1 110 177)" width="35" x="-17.5" xlink:href="#fi172-a" y="-5"/>'
                    )
                )
            );
    }

    function field_173(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Biletty',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M87.5 109.5h-5v-15h5v15Zm50-15h-5v15h5v-15Zm-50 30h-5v15h5v-15Zm50 0h-5v15h5v-15Zm-25-30h-5v15h5v-15Zm0 30h-5v15h5v-15Zm-25 30h-5v15h5v-15Zm25 0h-5v15h5v-15Zm-12.5-45h-5v15h5v-15Zm0 30h-5v15h5v-15Zm0 30h-5v15h5v-15Zm-30-45h5v-15h-5v15Zm0 30h5v-15h-5v15Zm80-45h-5v15h5v-15Zm0 30h-5v15h5v-15Zm-30-15h5v-15h-5v15Zm-20-45h-5v15h5v-15Zm-30 15h5v-15h-5v15Zm80-15h-5v15h5v-15Zm-30 15h5v-15h-5v15Zm0 60h5v-15h-5v15Zm0 30h5v-15h-5v15Zm17.5-30h-5v15h5v-15Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_174(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Semy of Quatrefoils',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi174-a" viewBox="-4.9 -4.9 9.8 9.8"><path d="M.9 4c.5-.3.7-.6.7-1.1 0-.6-.3-.9-.7-1.3-.3-.3.3-1.1.7-.7.5.4.7.7 1.3.7.5 0 .9-.2 1.1-.7.2-.3.4-.7.9-.9-.5-.2-.7-.6-.9-.9-.3-.5-.6-.7-1.1-.7-.6 0-.9.3-1.3.7-.3.3-1.1-.3-.7-.7.4-.5.7-.7.7-1.3 0-.5-.2-.9-.7-1.1-.3-.2-.7-.4-.9-.9-.2.5-.6.7-.9.9-.5.3-.7.6-.7 1.1 0 .6.3.9.7 1.3.3.3-.3 1.1-.7.7-.5-.4-.7-.7-1.3-.7-.5 0-.9.2-1.1.7-.2.3-.4.7-.9.9.5.2.7.6.9.9.3.5.6.7 1.1.7.6 0 .9-.3 1.3-.7.3-.3 1.1.3.7.7-.4.5-.7.7-.7 1.3 0 .5.2.9.7 1.1.3.2.7.4.9.9.2-.5.6-.7.9-.9z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi174-b" viewBox="-11.2 -12.4 22.3 24.8"><use height="9.8" overflow="visible" transform="translate(-6.25 7.5)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/><use height="9.8" overflow="visible" transform="translate(6.25 -7.5)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/></symbol><symbol id="fi174-c" viewBox="-17.4 -49.9 34.8 99.8"><use height="24.8" overflow="visible" transform="translate(-6.25 37.5)" width="22.3" x="-11.2" xlink:href="#fi174-b" y="-12.4"/><use height="24.8" overflow="visible" transform="translate(-6.25 7.5)" width="22.3" x="-11.2" xlink:href="#fi174-b" y="-12.4"/><use height="24.8" overflow="visible" transform="translate(-6.25 -22.5)" width="22.3" x="-11.2" xlink:href="#fi174-b" y="-12.4"/><use height="9.8" overflow="visible" transform="translate(12.5 45)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/><use height="9.8" overflow="visible" transform="translate(12.5 15)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/><use height="9.8" overflow="visible" transform="translate(12.5 -15)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/><use height="9.8" overflow="visible" transform="translate(12.5 -45)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><use height="99.8" overflow="visible" transform="matrix(1 0 0 -1 85 131.9)" width="34.8" x="-17.4" xlink:href="#fi174-c" y="-49.9"/><use height="99.8" overflow="visible" transform="rotate(180 67.5 65.95)" width="34.8" x="-17.4" xlink:href="#fi174-c" y="-49.9"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 122.5 86.9)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 110 101.9)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 110 131.9)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/><use height="9.8" overflow="visible" transform="matrix(1 0 0 -1 110 161.9)" width="9.8" x="-4.9" xlink:href="#fi174-a" y="-4.9"/>'
                    )
                )
            );
    }

    function field_175(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Semy-de-Lis',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi175-a" viewBox="-5.7 -7.9 11.3 13.8"><path d="M0 5.9c-.5-1.2-1.7-2.1-1.7-3.6 0-.4.1-.7.2-1.1-1.9 1.3-4.2.2-4.1-1.7 0-1.2.9-2.1 2-2.3-1 .4-1.1 2.4.5 2.4C-.2-.4-.9-4.2-2-5.5l2-2.4 2 2.4C.9-4.2.2-.4 3.1-.4c1.6 0 1.5-2 .5-2.4 1.2.2 2 1.2 2 2.3 0 1.9-2.2 3-4.1 1.7.1.3.2.7.2 1.1C1.7 3.8.5 4.7 0 5.9" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi175-b" viewBox="-11.9 -15.4 23.8 28.8"><use height="13.8" overflow="visible" transform="translate(-6.25 7.5)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/><use height="13.8" overflow="visible" transform="translate(6.25 -7.5)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/></symbol><symbol id="fi175-c" viewBox="-18.2 -52.9 36.3 103.8"><use height="28.8" overflow="visible" transform="translate(-6.25 37.5)" width="23.8" x="-11.9" xlink:href="#fi175-b" y="-15.4"/><use height="28.8" overflow="visible" transform="translate(-6.25 7.5)" width="23.8" x="-11.9" xlink:href="#fi175-b" y="-15.4"/><use height="28.8" overflow="visible" transform="translate(-6.25 -22.5)" width="23.8" x="-11.9" xlink:href="#fi175-b" y="-15.4"/><use height="13.8" overflow="visible" transform="translate(12.5 45)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/><use height="13.8" overflow="visible" transform="translate(12.5 15)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/><use height="13.8" overflow="visible" transform="translate(12.5 -15)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/><use height="13.8" overflow="visible" transform="translate(12.5 -45)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><use height="103.8" overflow="visible" transform="matrix(1 0 0 -1 85 131.9)" width="36.3" x="-18.2" xlink:href="#fi175-c" y="-52.9"/><use height="103.8" overflow="visible" transform="rotate(180 67.5 65.95)" width="36.3" x="-18.2" xlink:href="#fi175-c" y="-52.9"/><use height="13.8" overflow="visible" transform="matrix(1 0 0 -1 110 101.9)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/><use height="13.8" overflow="visible" transform="matrix(1 0 0 -1 110 131.9)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/><use height="13.8" overflow="visible" transform="matrix(1 0 0 -1 110 161.9)" width="11.3" x="-5.7" xlink:href="#fi175-a" y="-7.9"/>'
                    )
                )
            );
    }

    function field_176(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Estencelly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi176-a" viewBox="-1.5 -1.5 3 3"><circle fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" r="1.5"/></symbol><symbol id="fi176-b" viewBox="-4.1 -3.8 8.2 7.5"><use height="3" overflow="visible" transform="translate(.001 2.254)" width="3" x="-1.5" xlink:href="#fi176-a" y="-1.5"/><use height="3" overflow="visible" transform="translate(-2.595 -2.254)" width="3" x="-1.5" xlink:href="#fi176-a" y="-1.5"/><use height="3" overflow="visible" transform="translate(2.595 -2.254)" width="3" x="-1.5" xlink:href="#fi176-a" y="-1.5"/></symbol><symbol id="fi176-c" viewBox="-16.6 -3.8 33.2 7.5"><use height="7.5" overflow="visible" transform="translate(-12.5)" width="8.2" x="-4.1" xlink:href="#fi176-b" y="-3.8"/><use height="7.5" overflow="visible" transform="translate(12.5)" width="8.2" x="-4.1" xlink:href="#fi176-b" y="-3.8"/></symbol><symbol id="fi176-d" viewBox="-41.6 -3.8 83.2 7.5"><use height="7.5" overflow="visible" transform="translate(-25)" width="33.2" x="-16.6" xlink:href="#fi176-c" y="-3.8"/><use height="7.5" overflow="visible" transform="translate(25)" width="33.2" x="-16.6" xlink:href="#fi176-c" y="-3.8"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 109.999 86.254)" width="83.2" x="-41.6" xlink:href="#fi176-d" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 109.999 116.254)" width="83.2" x="-41.6" xlink:href="#fi176-d" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 109.999 146.254)" width="83.2" x="-41.6" xlink:href="#fi176-d" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 110 176.254)" width="33.2" x="-16.6" xlink:href="#fi176-c" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 97.5 101.254)" width="33.2" x="-16.6" xlink:href="#fi176-c" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 97.5 131.254)" width="33.2" x="-16.6" xlink:href="#fi176-c" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 97.5 161.254)" width="33.2" x="-16.6" xlink:href="#fi176-c" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 134.999 101.254)" width="8.2" x="-4.1" xlink:href="#fi176-b" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 134.999 131.254)" width="8.2" x="-4.1" xlink:href="#fi176-b" y="-3.8"/><use height="7.5" overflow="visible" transform="matrix(1 0 0 -1 134.999 161.254)" width="8.2" x="-4.1" xlink:href="#fi176-b" y="-3.8"/>'
                    )
                )
            );
    }

    function field_177(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Mullety',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi177-b" viewBox="-6.48 -6.48 12.96 12.96"><use height="7.23" overflow="visible" transform="translate(0 2.863)" width="4.19" x="-2.1" xlink:href="#fi177-a" y="-3.62"/><use height="7.23" overflow="visible" transform="rotate(90 -1.432 -1.432)" width="4.19" x="-2.1" xlink:href="#fi177-a" y="-3.62"/><use height="7.23" overflow="visible" transform="rotate(180 0 -1.432)" width="4.19" x="-2.1" xlink:href="#fi177-a" y="-3.62"/><use height="7.23" overflow="visible" transform="rotate(-90 1.432 -1.432)" width="4.19" x="-2.1" xlink:href="#fi177-a" y="-3.62"/></symbol><symbol id="fi177-a" viewBox="-2.1 -3.62 4.19 7.23"><path d="m0 3.62-2.1-7.24 4.2.01z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi177-c" viewBox="-18.98 -6.48 37.96 12.96"><use height="12.96" overflow="visible" transform="translate(-12.5)" width="12.96" x="-6.48" xlink:href="#fi177-b" y="-6.48"/><use height="12.96" overflow="visible" transform="translate(12.5)" width="12.96" x="-6.48" xlink:href="#fi177-b" y="-6.48"/></symbol><symbol id="fi177-d" viewBox="-31.48 -6.48 62.96 12.96"><use height="12.96" overflow="visible" transform="translate(-25)" width="12.96" x="-6.48" xlink:href="#fi177-b" y="-6.48"/><use height="12.96" overflow="visible" width="12.96" x="-6.48" xlink:href="#fi177-b" y="-6.48"/><use height="12.96" overflow="visible" transform="translate(25)" width="12.96" x="-6.48" xlink:href="#fi177-b" y="-6.48"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 85 87)" width="37.96" x="-18.98" xlink:href="#fi177-c" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 135 87)" width="37.96" x="-18.98" xlink:href="#fi177-c" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 85 117)" width="37.96" x="-18.98" xlink:href="#fi177-c" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 135 117)" width="37.96" x="-18.98" xlink:href="#fi177-c" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 85 147)" width="37.96" x="-18.98" xlink:href="#fi177-c" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 135 147)" width="37.96" x="-18.98" xlink:href="#fi177-c" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 110 177)" width="37.96" x="-18.98" xlink:href="#fi177-c" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 110 102)" width="62.96" x="-31.48" xlink:href="#fi177-d" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 110 132)" width="62.96" x="-31.48" xlink:href="#fi177-d" y="-6.48"/><use height="12.96" overflow="visible" transform="matrix(1 0 0 -1 110 162)" width="62.96" x="-31.48" xlink:href="#fi177-d" y="-6.48"/>'
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