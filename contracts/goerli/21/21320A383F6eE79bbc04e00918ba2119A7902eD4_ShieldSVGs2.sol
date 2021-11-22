// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../interfaces/IShieldSVGs.sol';
import '../libraries/HexStrings.sol';

/// @dev Generate Shield SVG
contract ShieldSVGs2 is IShieldSVGs {
    using HexStrings for uint24;

    function shield_21(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Semy-de-Lis',
                'Heraldic',
                string(
                    abi.encodePacked(
                        '<symbol id="fi-a" viewbox="-5.7 -7.9 11.3 13.8"><path d="M0 5.9c-.5-1.2-1.7-2.1-1.7-3.6 0-.4.1-.7.2-1.1-1.9 1.3-4.2.2-4.1-1.7 0-1.2.9-2.1 2-2.3-1 .4-1.1 2.4.5 2.4C-.2-.4-.9-4.2-2-5.5l2-2.4 2 2.4C.9-4.2.2-.4 3.1-.4c1.6 0 1.5-2 .5-2.4 1.2.2 2 1.2 2 2.3 0 1.9-2.2 3-4.1 1.7.1.3.2.7.2 1.1C1.7 3.8.5 4.7 0 5.9" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path></symbol><symbol id="fi-b" viewbox="-11.9 -15.4 23.8 28.8"><use height="13.8" overflow="visible" transform="translate(-6.25 7.5)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use><use height="13.8" overflow="visible" transform="translate(6.25 -7.5)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use></symbol><symbol id="fi-c" viewbox="-18.2 -52.9 36.3 103.8"><use height="28.8" overflow="visible" transform="translate(-6.25 37.5)" width="23.8" x="-11.9" xlink:href="#fi-b" y="-15.4"></use><use height="28.8" overflow="visible" transform="translate(-6.25 7.5)" width="23.8" x="-11.9" xlink:href="#fi-b" y="-15.4"></use><use height="28.8" overflow="visible" transform="translate(-6.25 -22.5)" width="23.8" x="-11.9" xlink:href="#fi-b" y="-15.4"></use><use height="13.8" overflow="visible" transform="translate(12.5 45)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use><use height="13.8" overflow="visible" transform="translate(12.5 15)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use><use height="13.8" overflow="visible" transform="translate(12.5 -15)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use><use height="13.8" overflow="visible" transform="translate(12.5 -45)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use></symbol><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"></path><use height="103.8" overflow="visible" transform="matrix(1 0 0 -1 85 131.9)" width="36.3" x="-18.2" xlink:href="#fi-c" y="-52.9"></use><use height="103.8" overflow="visible" transform="rotate(180 67.5 65.95)" width="36.3" x="-18.2" xlink:href="#fi-c" y="-52.9"></use><use height="13.8" overflow="visible" transform="matrix(1 0 0 -1 110 101.9)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use><use height="13.8" overflow="visible" transform="matrix(1 0 0 -1 110 131.9)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use><use height="13.8" overflow="visible" transform="matrix(1 0 0 -1 110 161.9)" width="11.3" x="-5.7" xlink:href="#fi-a" y="-7.9"></use>'
                    )
                )
            );
    }

    function shield_22(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Bloomy',
                'Mythic',
                string(
                    abi.encodePacked(
                        '<symbol id="fi-a" viewBox="-5.297 -10.413 15.626 15"><path d="M4.107-6.785C3.177-7.034.314-2.157-.113-1.42c.425-.737 3.217-5.656 2.536-6.337-.68-.681-5.598 2.111-6.336 2.536l8.992-5.192V-.029c-.001-.849-.041-6.507-.972-6.756z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" stroke="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" stroke-width=".25"/><g fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" stroke="#',
                        colors[1].toHexStringNoPrefix(3),
                        '" stroke-width=".25"><path d="M-.171 4.587c3.789 0 5.25-4.525 5.25-4.525s1.461 4.525 5.25 4.525h-10.5z"/><path d="m-3.581 4.587-1.716-2.972C-3.613 3.638-.218-1.263-.218-1.263s-2.547 5.404.047 5.85h-3.41z"/></g></symbol><symbol id="fi-b" viewBox="-17.32 -15 34.641 30"><use height="15.2" overflow="visible" transform="translate(-5.08 10.413)" width="15.7" x="-5.297" xlink:href="#fi-a" y="-10.413"/><use height="15.2" overflow="visible" transform="rotate(60 -6.478 -9.605)" width="15.7" x="-5.297" xlink:href="#fi-a" y="-10.413"/><use height="15.2" overflow="visible" transform="rotate(120 -.466 -6.673)" width="15.7" x="-5.297" xlink:href="#fi-a" y="-10.413"/><use height="15.2" overflow="visible" transform="rotate(180 2.54 -5.206)" width="15.7" x="-5.297" xlink:href="#fi-a" y="-10.413"/><use height="15.2" overflow="visible" transform="rotate(-120 5.546 -3.74)" width="15.7" x="-5.297" xlink:href="#fi-a" y="-10.413"/><use height="15.2" overflow="visible" transform="rotate(-60 11.558 -.807)" width="15.7" x="-5.297" xlink:href="#fi-a" y="-10.413"/></symbol><symbol id="fi-e" viewBox="-17.32 -75 34.641 150"><use height="30" overflow="visible" width="34.641" x="-17.32" xlink:href="#fi-b" y="-15"/><use height="30" overflow="visible" transform="translate(0 -30)" width="34.641" x="-17.32" xlink:href="#fi-b" y="-15"/><use height="30" overflow="visible" transform="translate(0 -60)" width="34.641" x="-17.32" xlink:href="#fi-b" y="-15"/><use height="30" overflow="visible" transform="translate(0 30)" width="34.641" x="-17.32" xlink:href="#fi-b" y="-15"/><use height="30" overflow="visible" transform="translate(0 60)" width="34.641" x="-17.32" xlink:href="#fi-b" y="-15"/></symbol><path d="M60.047 72v75c-.001 27.613 22.383 49.999 49.996 50h.004c27.613.002 49.998-22.381 50-49.994V72h-100z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M101.008 126.808zM99.5 132h.116-.116zm5.308-8.992zm5.192-1.392v-.116.116z" fill="#FF1A1A"/><defs><path d="M60.047 72v75c-.001 27.613 22.383 49.999 49.996 50h.004c27.613.002 49.998-22.381 50-49.994V72h-100z" id="fi-c"/></defs><clipPath id="fi-d"><use overflow="visible" xlink:href="#fi-c"/></clipPath><g clip-path="url(#fi-d)"><use height="150" overflow="visible" transform="matrix(.9615 0 0 -1 110 132)" width="34.641" x="-17.32" xlink:href="#fi-e" y="-75"/></g><g clip-path="url(#fi-d)"><use height="150" overflow="visible" transform="matrix(.9615 0 0 -1 60 132)" width="34.641" x="-17.32" xlink:href="#fi-e" y="-75"/></g><g clip-path="url(#fi-d)"><use height="150" overflow="visible" transform="matrix(.9615 0 0 -1 85 117)" width="34.641" x="-17.32" xlink:href="#fi-e" y="-75"/></g><g clip-path="url(#fi-d)"><use height="150" overflow="visible" transform="matrix(-.9615 0 0 -1 160 132)" width="34.641" x="-17.32" xlink:href="#fi-e" y="-75"/></g><g clip-path="url(#fi-d)"><use height="150" overflow="visible" transform="matrix(-.9615 0 0 -1 135 117)" width="34.641" x="-17.32" xlink:href="#fi-e" y="-75"/></g><path clip-path="url(#fi-d)" d="M58 118.129h52V132H58z" fill="none"/>'
                    )
                )
            );
    }

    function shield_23(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Rasterlines Barry-X',
                'Mythic_optimized',
                string(
                    abi.encodePacked(
                        '<symbol id="fi-a" viewbox="-5.005 -6 10.009 12"><path d="M5.005 6H1.876L-5.005-6z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path></symbol><symbol id="fi-d" viewbox="-15.951 -6 31.902 12"><use height="12" overflow="visible" transform="translate(10.946)" width="10.009" x="-5.005" xlink:href="#fi-a" y="-6"></use><use height="12" overflow="visible" transform="translate(7.819)" width="10.009" x="-5.005" xlink:href="#fi-a" y="-6"></use><use height="12" overflow="visible" transform="translate(4.691)" width="10.009" x="-5.005" xlink:href="#fi-a" y="-6"></use><use height="12" overflow="visible" transform="translate(1.564)" width="10.009" x="-5.005" xlink:href="#fi-a" y="-6"></use><use height="12" overflow="visible" transform="translate(-1.564)" width="10.009" x="-5.005" xlink:href="#fi-a" y="-6"></use><use height="12" overflow="visible" transform="translate(-4.691)" width="10.009" x="-5.005" xlink:href="#fi-a" y="-6"></use><use height="12" overflow="visible" transform="translate(-7.819)" width="10.009" x="-5.005" xlink:href="#fi-a" y="-6"></use><use height="12" overflow="visible" transform="translate(-10.946)" width="10.009" x="-5.005" xlink:href="#fi-a" y="-6"></use></symbol><symbol id="fi-g" viewbox="-57.542 -45 115.084 90"><defs><path d="M-27.49-45h72v90h-72z" id="fi-b"></path></defs><clippath id="fi-c"><use overflow="visible" xlink:href="#fi-b"></use></clippath><g clip-path="url(#fi-c)"><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 -30.025 -3)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 -40.025 -15)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(-3.432 -3)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 20.025 -3)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(-13.432 -15)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 10.025 -15)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(-33.482 21)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 -10.025 21)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 -20.025 9)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(16.568 21)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 40.025 21)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(6.568 9)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 30.025 9)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(-23.432 -27)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 .025 -27)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(-33.432 -39)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="matrix(-1 0 -.261 -1 -9.975 -39)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(36.618 -15)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(26.618 -27)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use><use height="12" overflow="visible" transform="translate(16.618 -39)" width="31.902" x="-15.951" xlink:href="#fi-d" y="-6"></use></g></symbol><path d="M60.047 72v75c-.001 27.613 22.383 49.999 49.996 50h.004c27.613.002 49.998-22.381 50-49.994V72h-100z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '" id="fi-e"></path><clippath id="fi-f"><use overflow="visible" xlink:href="#fi-e"></use></clippath><g clip-path="url(#fi-f)"><use height="90" overflow="visible" transform="matrix(1 0 0 -1 137.49 87)" width="115.084" x="-57.542" xlink:href="#fi-g" y="-45"></use><use height="90" overflow="visible" transform="rotate(180 41.255 43.5)" width="115.084" x="-57.542" xlink:href="#fi-g" y="-45"></use><use height="90" overflow="visible" transform="matrix(-1 0 0 1 82.51 177)" width="115.084" x="-57.542" xlink:href="#fi-g" y="-45"></use><use height="90" overflow="visible" transform="translate(137.49 177)" width="115.084" x="-57.542" xlink:href="#fi-g" y="-45"></use></g>'
                    )
                )
            );
    }

    function shield_24(uint24[4] memory colors) public pure returns (ShieldData memory) {
        return
            ShieldData(
                'Laserwheels',
                'Mythic_optimized',
                string(
                    abi.encodePacked(
                        '<symbol id="fi-a" viewbox="-1.3 -7.5 2.6 15"><path d="M-1.3 7.27 1.3-7.5v15z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"></path></symbol><symbol id="fi-b" viewbox="-7.51 -14.89 15 29.92"><use height="15" overflow="visible" transform="translate(6.18 7.45) scale(1.0097)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use><use height="15" overflow="visible" transform="rotate(20 -16.53 13.75)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use><use height="15" overflow="visible" transform="rotate(40 -5.74 4.7)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use><use height="15" overflow="visible" transform="rotate(60 -2 1.55)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use><use height="15" overflow="visible" transform="rotate(80 0 -.12)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use><use height="15" overflow="visible" transform="rotate(100 1.3 -1.21)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use><use height="15" overflow="visible" transform="rotate(120 2.27 -2.02)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use><use height="15" overflow="visible" transform="rotate(140 3.05 -2.68)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use><use height="15" overflow="visible" transform="rotate(160 3.75 -3.26)" width="2.6" x="-1.3" xlink:href="#fi-a" y="-7.5"></use></symbol><symbol id="fi-i" viewbox="-100.01 -57.72 200.01 115.44"><path d="M1.32-19.74zm10.29-12.81zm-.69 15.14z"></path><use height="29.92" overflow="visible" transform="matrix(-1 0 0 1 32.5 -12.16)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="matrix(1 0 0 -1 17.51 -12.4)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="translate(-32.49 -12.16)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="rotate(180 -8.75 -6.2)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="rotate(180 1.97 -6.17) scale(.525)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="matrix(.525 0 0 .525 -3.93 -12.22)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="rotate(-90 -31.65 -6.7) scale(.525)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="rotate(-90 -6.64 -31.7) scale(.525)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><defs><path d="M0 57.72v-62.5a7.5 7.5 0 0 0 0-15v-7.5a15 15 0 0 0 15-15h2.5a7.5 7.5 0 0 0 15 0H100v100H0zm25-85a15 15 0 1 0 0 30 15 15 0 0 0 0-30z" id="fi-c"></path></defs><clippath id="fi-d"><use overflow="visible" xlink:href="#fi-c"></use></clippath><g clip-path="url(#fi-d)"><use height="29.92" overflow="visible" transform="matrix(3 0 0 3 2.52 -11.92)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="matrix(-3 0 0 -3 47.49 -12.64)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use></g><defs><path d="M-100 57.72v-100h67.5a7.5 7.5 0 0 0 15 0h2.5a15 15 0 0 0 15 15v7.5a7.5 7.5 0 0 0 0 15v62.5h-100zm60-70a15 15 0 1 0 30 0 15 15 0 0 0-30 0z" id="fi-e"></path></defs><clippath id="fi-f"><use overflow="visible" xlink:href="#fi-e"></use></clippath><g clip-path="url(#fi-f)"><use height="29.92" overflow="visible" transform="matrix(-3 0 0 3 -2.52 -11.92)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use><use height="29.92" overflow="visible" transform="matrix(3 0 0 -3 -47.49 -12.64)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use></g><use height="29.92" overflow="visible" transform="matrix(0 -1.0249 -1.0249 0 -.12 -34.6)" width="15" x="-7.51" xlink:href="#fi-b" y="-14.89"></use></symbol><path d="M60 72v75a50 50 0 1 0 100 0V72H60z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '" id="fi-g"></path><clippath id="fi-h"><use overflow="visible" xlink:href="#fi-g"></use></clippath><g clip-path="url(#fi-h)"><use height="115.44" overflow="visible" transform="matrix(1 0 0 -1 110 89.72)" width="200.01" x="-100.01" xlink:href="#fi-i" y="-57.72"></use></g><g clip-path="url(#fi-h)"><use height="115.44" overflow="visible" transform="matrix(-1 0 0 1 110 174.28)" width="200.01" x="-100.01" xlink:href="#fi-i" y="-57.72"></use></g>'
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev Generate Shield SVG
interface IShieldSVGs {
    struct ShieldData {
        string title;
        string svgType;
        string svgString;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}