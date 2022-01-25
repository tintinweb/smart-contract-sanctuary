// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../libraries/HexStrings.sol';

/// @dev Generate Field SVG
contract FieldSVGs23 is IFieldSVGs, ICategories {
    using HexStrings for uint24;

    function field_290(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'QuiltX II',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi290-b" viewBox="-8.3 -10 16.7 20"><path d="M2-1.4a1.75 1.75 0 0 0 0 2.8l3.3 2.3 3 6.3-5.2-3.7-1.9-4C1 1.9.5 1.6 0 1.6s-1 .3-1.1.8l-1.9 4-5.3 3.6 3.1-6.3L-2 1.4c.4-.4.7-.9.7-1.4 0-.5-.2-1-.7-1.4l-3.3-2.3-3-6.3L-3-6.3l1.9 4c.1.4.6.7 1.1.7.5 0 1-.3 1.1-.8l1.9-4L8.3-10l-3 6.3L2-1.4z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi290-a" viewBox="-11.4 -13.7 22.8 27.3"><path d="m-3-13.7 3 6.6 3.1-6.6L3-6.1 8.3-10 5.1-3.5l6.3-.2L5.9 0l5.5 3.7-6.3-.2L8.3 10 2.9 6.1l.1 7.6-3-6.6-3 6.6.1-7.6-5.4 3.9 3.2-6.5-6.3.2L-5.9 0l-5.5-3.7 6.3.2-3.2-6.5 5.4 3.9z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi290-c" viewBox="-18.2 -21.8 22.8 83.7"><use height="27.3" overflow="visible" transform="translate(-6.8 -8.17)" width="22.8" x="-11.4" xlink:href="#fi290-a" y="-13.7"/><use height="20" overflow="visible" transform="translate(-6.8 11.83)" width="16.7" x="-8.3" xlink:href="#fi290-b" y="-10"/><use height="27.3" overflow="visible" transform="translate(-6.8 31.83)" width="22.8" x="-11.4" xlink:href="#fi290-a" y="-13.7"/><use height="20" overflow="visible" transform="translate(-6.8 51.83)" width="16.7" x="-8.3" xlink:href="#fi290-b" y="-10"/></symbol><symbol id="fi290-d" viewBox="-11.4 -81.8 22.8 163.7"><use height="83.7" overflow="visible" transform="translate(6.8 -60)" width="22.8" x="-18.2" xlink:href="#fi290-c" y="-21.8"/><use height="83.7" overflow="visible" transform="translate(6.8 20)" width="22.8" x="-18.2" xlink:href="#fi290-c" y="-21.8"/></symbol><symbol id="fi290-g" viewBox="-19.7 -91.8 39.4 183.7"><use height="163.7" overflow="visible" transform="translate(8.33 -10)" width="22.8" x="-11.4" xlink:href="#fi290-d" y="-81.8"/><use height="163.7" overflow="visible" transform="translate(-8.33 10)" width="22.8" x="-11.4" xlink:href="#fi290-d" y="-81.8"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.6 22.4 50 50 50s50-22.4 50-50V72H60z" id="fi290-e"/></defs><clipPath id="fi290-f"><use overflow="visible" xlink:href="#fi290-e"/></clipPath><g clip-path="url(#fi290-f)"><use height="183.7" overflow="visible" transform="matrix(1 0 0 -1 101.67 133.83)" width="39.4" x="-19.7" xlink:href="#fi290-g" y="-91.8"/><use height="183.7" overflow="visible" transform="matrix(1 0 0 -1 135 133.83)" width="39.4" x="-19.7" xlink:href="#fi290-g" y="-91.8"/><use height="183.7" overflow="visible" transform="matrix(1 0 0 -1 168.33 133.83)" width="39.4" x="-19.7" xlink:href="#fi290-g" y="-91.8"/><use height="183.7" overflow="visible" transform="matrix(1 0 0 -1 68.33 133.83)" width="39.4" x="-19.7" xlink:href="#fi290-g" y="-91.8"/></g>'
                    )
                )
            );
    }

    function field_291(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cubey I',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<defs><symbol id="fi291-a" viewBox="0 0 26.42 22.5"><path d="M25 0 11.15 8.31 12.5 22.5l13.92-8.35L25 0z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m0 15 12.5 7.5v-15L0 0v15z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi291-c" viewBox="0 0 126.42 45"><use height="22.5" width="26.42" xlink:href="#fi291-a"/><use height="22.5" transform="translate(25)" width="26.42" xlink:href="#fi291-a"/><use height="22.5" transform="translate(50)" width="26.42" xlink:href="#fi291-a"/><use height="22.5" transform="translate(75)" width="26.42" xlink:href="#fi291-a"/><use height="22.5" transform="translate(100)" width="26.42" xlink:href="#fi291-a"/><use height="22.5" transform="translate(12.5 22.5)" width="26.42" xlink:href="#fi291-a"/><use height="22.5" transform="translate(37.5 22.5)" width="26.42" xlink:href="#fi291-a"/><use height="22.5" transform="translate(62.5 22.5)" width="26.42" xlink:href="#fi291-a"/><use height="22.5" transform="translate(87.5 22.5)" width="26.42" xlink:href="#fi291-a"/></symbol><clipPath id="fi291-b"><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="none"/></clipPath></defs><path d="M60 72v75a50 50 0 0 0 100 0V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi291-b)"><use height="45" transform="translate(47.5 79.5)" width="126.42" xlink:href="#fi291-c"/><use height="45" transform="translate(47.5 34.5)" width="126.42" xlink:href="#fi291-c"/><use height="45" transform="translate(47.5 124.5)" width="126.42" xlink:href="#fi291-c"/><use height="45" transform="translate(47.5 169.5)" width="126.42" xlink:href="#fi291-c"/></g>'
                    )
                )
            );
    }

    function field_292(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Cubey II',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 162 25-15v-30l12.5-7.5v45L110 177v-15Zm0-15 12.5-7.5v-15L110 132v15Zm0 45v5h.047a50.011 50.011 0 0 0 47.135-33.309L110 192Zm0-120-49.953 30.028V147c.008 4.666.67 9.308 1.97 13.79L72.5 154.5v-45L110 87V72Zm0 30-25 15v30l12.5-7.5v-15L110 117v-15ZM60.047 72v14.972L85 72H60.047Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="m110 177-37.5-22.5v-45L85 117v30l25 15v15Zm0-45-12.5-7.5v15L110 147v-15Zm-47.182 31.691A50.012 50.012 0 0 0 109.953 197H110v-5l-47.182-28.309ZM110 87l37.5 22.5v45l10.484 6.29a49.844 49.844 0 0 0 1.969-13.79v-44.972L110 72v15Zm0 30 12.5 7.5v15L135 147v-30l-25-15v15Zm25-45 24.953 14.972V72H135Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_293(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly II',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M110 72v60h50V72h-50Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M60 132h50v65a50 50 0 0 1-50-50v-15Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M160 147a49.997 49.997 0 0 1-50 50v-65h50v15Z" fill="#',
                        colors[3].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_294(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Quarterly, a Cross and a Bar',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="M154.635 169.5h-12.552v15.836a50.02 50.02 0 0 1-14.166 8.328V169.5H110v-15h17.917V132h14.166v22.5h17.349a49.99 49.99 0 0 1-4.797 15ZM77.917 132h14.166v-22.5H110v-15H92.083V72H77.917v22.5H60v15h17.917V132Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M110 132v65a50.002 50.002 0 0 1-50-49.985V132h50Zm50-60h-50v60h50V72Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M60.568 154.5H110v15H65.365a49.993 49.993 0 0 1-4.797-15Zm49.432-45h50v-15h-50v15Z" fill="#',
                        colors[3].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_295(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pall Inverted and a Chief',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><path d="m110 132 38.786 46.544A49.788 49.788 0 0 0 160 147V72h-50v60Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M148.787 178.544 110 132l-38.787 46.545a49.974 49.974 0 0 0 17.31 13.606 49.979 49.979 0 0 0 60.264-13.606v-.001Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M60 72h100v30H60V72Z" fill="#',
                        colors[3].toHexStringNoPrefix(3),
                        '"/>'
                    )
                )
            );
    }

    function field_296(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Per Pall Inverted and Chevronelly',
                FieldCategories.HERALDIC,
                string(
                    abi.encodePacked(
                        '<defs><clipPath id="fi296-a"><path d="M60,72v75a50,50,0,0,0,100,0V72Z" fill="none"/></clipPath></defs><path d="M60,72v75a50,50,0,0,0,100,0V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><g clip-path="url(#fi296-a)"><path d="M110,136.53l51.72,63.59L160,72H110Z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M110,136.53,56.16,202.25l105.56-2.13Z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M110,192l7.49,9h-15Zm-22.44,6.93L94.17,201,110,182l15.83,19,6.61-2.06L110,172Zm-11.45-6.26,5.44,3.47L110,162l28.45,34.14,5.44-3.47L110,152ZM110,132,66.79,183.85l4.4,4.72L110,142l38.81,46.57,4.4-4.72Z" fill="#',
                        colors[3].toHexStringNoPrefix(3),
                        '"/></g>'
                    )
                )
            );
    }

    function field_297(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Check',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi297-a" viewBox="-12.5 -15 25 30"><path d="M12.5-10h-10v-5h10v5zm-10 5h10v5h-10v-5zm-4.95 20V0H2.5v15h-4.95zM-12.5 0h5.05v15h-5.05V0z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M-7.5 0v-5h5v5h-5zm-5-5v-5h5v5h-5zm5-10h5v5h-5v-5zm10 5v5h-5v-5h5z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M-7.5-10h5v5h-5z" fill="#',
                        colors[3].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi297-b" viewBox="-25 -15 50 30"><use height="30" overflow="visible" transform="translate(-12.5)" width="25" x="-12.5" xlink:href="#fi297-a" y="-15"/><use height="30" overflow="visible" transform="translate(12.5)" width="25" x="-12.5" xlink:href="#fi297-a" y="-15"/></symbol><symbol id="fi297-e" viewBox="-62.5 -15 125 30"><use height="30" overflow="visible" transform="translate(-37.5)" width="50" x="-25" xlink:href="#fi297-b" y="-15"/><use height="30" overflow="visible" transform="translate(12.5)" width="50" x="-25" xlink:href="#fi297-b" y="-15"/><use height="30" overflow="visible" transform="translate(50)" width="25" x="-12.5" xlink:href="#fi297-a" y="-15"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60.05 72v75c0 27.61 22.38 50 50 50 27.61 0 50-22.38 50-49.99V72h-100z" id="fi297-c"/></defs><clipPath id="fi297-d"><use overflow="visible" xlink:href="#fi297-c"/></clipPath><g clip-path="url(#fi297-d)"><use height="30" overflow="visible" transform="matrix(1 0 0 -1 115 94.5)" width="125" x="-62.5" xlink:href="#fi297-e" y="-15"/><use height="30" overflow="visible" transform="matrix(1 0 0 -1 115 124.5)" width="125" x="-62.5" xlink:href="#fi297-e" y="-15"/><use height="30" overflow="visible" transform="matrix(1 0 0 -1 115 154.5)" width="125" x="-62.5" xlink:href="#fi297-e" y="-15"/><use height="30" overflow="visible" transform="matrix(1 0 0 -1 115 184.5)" width="125" x="-62.5" xlink:href="#fi297-e" y="-15"/><use height="30" overflow="visible" transform="matrix(1 0 0 -1 115 64.5)" width="125" x="-62.5" xlink:href="#fi297-e" y="-15"/></g>'
                    )
                )
            );
    }

    function field_298(uint24[4] memory colors) public pure returns (FieldData memory) {
        return
            FieldData(
                'Tiles II',
                FieldCategories.MYTHIC,
                string(
                    abi.encodePacked(
                        '<symbol id="fi298-a" viewBox="-14.03 -15 28.05 30"><path d="M14.03-9.51 8.74-6.34l-3.05-5.49L10.97-15zM10.97 8.66 5.69 5.49 8.74 0l5.29 3.17zm-16.66 0h6.1V15h-6.1z" fill="#',
                        colors[1].toHexStringNoPrefix(3),
                        '"/><path d="M8.74 0 5.69 5.49.41 8.66h-6.1l-5.28-3.17L-14.03 0v-6.34l3.06-5.49L-5.69-15h6.1l5.28 3.17 3.05 5.49z" fill="#',
                        colors[2].toHexStringNoPrefix(3),
                        '"/><path d="M-2.64 1.83a5 5 0 0 1-4.62-3.09 5.025 5.025 0 0 1 1.08-5.45A4.989 4.989 0 0 1-.73-7.79a5 5 0 0 1 3.09 4.62C2.36-1.84 1.83-.57.9.37c-.94.93-2.22 1.46-3.54 1.46z" fill="#',
                        colors[3].toHexStringNoPrefix(3),
                        '"/></symbol><symbol id="fi298-b" viewBox="-14.03 -30 28.05 60"><use height="30" overflow="visible" transform="translate(0 15)" width="28.05" x="-14.03" xlink:href="#fi298-a" y="-15"/><use height="30" overflow="visible" transform="translate(0 -15)" width="28.05" x="-14.03" xlink:href="#fi298-a" y="-15"/></symbol><symbol id="fi298-c" viewBox="-14.03 -60 28.05 180"><use height="60" overflow="visible" transform="translate(0 30)" width="28.05" x="-14.03" xlink:href="#fi298-b" y="-30"/><use height="60" overflow="visible" transform="translate(0 90)" width="28.05" x="-14.03" xlink:href="#fi298-b" y="-30"/><use height="60" overflow="visible" transform="translate(0 -30)" width="28.05" x="-14.03" xlink:href="#fi298-b" y="-30"/></symbol><symbol id="fi298-f" viewBox="-26.53 -97.5 53.05 195"><use height="180" overflow="visible" transform="translate(12.5 -37.5)" width="28.05" x="-14.03" xlink:href="#fi298-c" y="-60"/><use height="180" overflow="visible" transform="translate(-12.5 -22.5)" width="28.05" x="-14.03" xlink:href="#fi298-c" y="-60"/></symbol><path d="M60 72v75a50 50 0 0 0 50 50 50 50 0 0 0 50-50V72Z" fill="#',
                        colors[0].toHexStringNoPrefix(3),
                        '"/><defs><path d="M60 72v75c0 27.61 22.38 50 49.99 50h.01c27.61 0 50-22.38 50-49.99V72H60z" id="fi298-d"/></defs><clipPath id="fi298-e"><use overflow="visible" xlink:href="#fi298-d"/></clipPath><g clip-path="url(#fi298-e)"><use height="195" overflow="visible" transform="matrix(1 0 0 -1 100.141 121.33)" width="53.05" x="-26.53" xlink:href="#fi298-f" y="-97.5"/><use height="195" overflow="visible" transform="matrix(1 0 0 -1 150.142 121.33)" width="53.05" x="-26.53" xlink:href="#fi298-f" y="-97.5"/><use height="180" overflow="visible" transform="matrix(1 0 0 -1 62.642 158.83)" width="28.05" x="-14.03" xlink:href="#fi298-c" y="-60"/></g>'
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